from bme280driver.bme280_defs cimport *

from bme280driver.bme280 cimport bme280_set_sensor_mode, \
    bme280_get_sensor_mode, bme280_set_sensor_settings, \
    bme280_set_sensor_mode, bme280_get_sensor_data
from bme280driver.bme280_helper cimport init, bme280_close
import time
from libc.stdint cimport int8_t, uint8_t
from libc.math cimport ceil


class NullPointerError(RuntimeError):
    """ Null pointer error"""


class DeviceNotFoundError(RuntimeError):
    """ Device not found error"""


class InvalidLengthError(RuntimeError):
    """ Invalid length error"""


class CommunicationFailedError(IOError):
    """ Communication failed error"""


class SleepModeFailedError(RuntimeError):
    """ Sleep mode failed error """


cdef inline check_error(int8_t error_code, txt):
    if error_code == BME280_E_NULL_PTR:
        raise NullPointerError(txt)
    elif error_code == BME280_E_DEV_NOT_FOUND:
        raise DeviceNotFoundError(txt)
    elif error_code == BME280_E_INVALID_LEN:
        raise InvalidLengthError(txt)
    elif error_code == BME280_E_COMM_FAIL:
        raise CommunicationFailedError(txt)
    elif error_code == BME280_E_SLEEP_MODE_FAIL:
        raise SleepModeFailedError(txt)


class BME280SensorPowerMode:
    SLEEP = 0
    FORCED = 1
    NORMAL = 3


class BME280Oversampling:
    NO = 0
    X1 = 1
    X2 = 2
    X4 = 3
    X8 = 4
    X16 = 5


class BME280StandbyTime:
    TIME_1_MS = 0
    TIME_10_MS = 6
    TIME_20_MS = 7
    TIME_62_5_MS = 1
    TIME_125_MS = 2
    TIME_250_MS = 3
    TIME_500_MS = 4
    TIME_1000_MS = 5


class BME280Filter:
    OFF = 0
    COEFF_2 = 1
    COEFF_4 = 2
    COEFF_8 = 3
    COEFF_16 = 4


cdef class BME280:
    """ Interface to the BME280 sensor over I2C using Bosch Sensortec's
    BME280 sensor API: https://github.com/BoschSensortec/BME280_driver


    standby_time must be set for NORMAL mode and is ignored
    in FORCED mode
    """

    cdef bme280_dev dev
    cdef public uint8_t device_id
    cdef public uint8_t chip_id
    cdef public uint32_t measurement_time

    def __cinit__(self, int i2cbus=1,
                  humidity_oversampling=BME280Oversampling.X1,
                  pressure_oversampling=BME280Oversampling.X1,
                  temperature_oversampling=BME280Oversampling.X1,
                  filter_coeff=BME280Filter.OFF,
                  standby_time=None,
                  sensor_mode=BME280SensorPowerMode.FORCED):
        """
        i2cbus: number of the I2C bus which is used. "i2cdetect -y i2cbus"
                should list sensor (indicated by number 76 or 77)
                For most Raspberry Pi 1 is the correct bus

        Default values for humidity_oversampling, pressure_oversampling,
        temperature_oversampling, filter_coeff, standby_time and
        sensor_mode correspond to recommended mode for weather
        monitoring (see chapter 3.5.1 in BME280 datasheet)

        """

        cdef int8_t rslt = BME280_OK
        rslt = init(i2cbus, &self.dev)

        check_error(rslt, "init")

        self.device_id = self.dev.dev_id
        self.chip_id = self.dev.chip_id

        self.config(humidity_oversampling=humidity_oversampling,
                    pressure_oversampling=pressure_oversampling,
                    temperature_oversampling=temperature_oversampling,
                    filter_coeff=filter_coeff,
                    standby_time=standby_time,
                    sensor_mode=sensor_mode)

    def config(self,
               humidity_oversampling,
               pressure_oversampling,
               temperature_oversampling,
               filter_coeff,
               standby_time,
               sensor_mode):
        """
        Configures oversampling, filter, standby duration and sensor mode

        standby_time must be set for NORMAL mode and is ignored
        in FORCED mode

        """

        cdef int8_t rslt = BME280_OK
        cdef uint8_t settings_sel = 0

        if sensor_mode == BME280_NORMAL_MODE and standby_time is None:
            raise ValueError("standby_time must be set for NORMAL mode")

        sel_settings = []
        if humidity_oversampling is not None:
            self.dev.settings.osr_h = humidity_oversampling
            sel_settings.append(BME280_OSR_HUM_SEL)

        if pressure_oversampling is not None:
            self.dev.settings.osr_p = pressure_oversampling
            sel_settings.append(BME280_OSR_PRESS_SEL)

        if temperature_oversampling is not None:
            self.dev.settings.osr_t = temperature_oversampling
            sel_settings.append(BME280_OSR_TEMP_SEL)

        if filter_coeff is not None:
            self.dev.settings.filter = filter_coeff
            sel_settings.append(BME280_FILTER_SEL)

        if sensor_mode == BME280_NORMAL_MODE:
            self.dev.settings.standby_time = standby_time
            sel_settings.append(BME280_STANDBY_SEL)

        for sel_setting in sel_settings:
            settings_sel |= sel_setting
        rslt = bme280_set_sensor_settings(settings_sel,
                                          &self.dev)
        check_error(rslt, "bme280_set_sensor_settings")

        rslt = bme280_set_sensor_mode(sensor_mode,
                                      &self.dev)
        check_error(rslt, "bme280_set_sensor_mode")

        self._calc_sensor_measurement_time()

        # Wait until we have a first measurement
        self.dev.delay_ms(self.measurement_time)

    def _calc_sensor_measurement_time(self):
        """
        Calculates typical active measurement time

        See 9. Appendix B / 9.1 Measurement time in
        BME280 datasheet
        """

        if not self.dev.settings.osr_t == BME280Oversampling.NO:
            t_temperature = 2.0 * (2 ** (self.dev.settings.osr_t - 1))
        else:
            t_temperature = 0.0

        if not self.dev.settings.osr_h == BME280Oversampling.NO:
            t_humidity = 2.0 * (2 ** (self.dev.settings.osr_h - 1)) + 0.5
        else:
            t_humidity = 0.0

        if not self.dev.settings.osr_p == BME280Oversampling.NO:
            t_pressure = 2.0 * (2 ** (self.dev.settings.osr_p - 1)) + 0.5
        else:
            t_pressure = 0.0

        self.measurement_time = int(ceil(1.0 + t_temperature + t_humidity + t_pressure))

    def read(self):
        """
        Reads values from sensor.

        Returns a dictionary with sensor readings and
        following keys:
        - 'temperature', unit: degree Celsius
        - 'humidity', unit:  percentage relative humidity
        - 'pressure', unit: hectopascal
        - 'timestamp' unit: seconds since the epoch
        """
        cdef int8_t rslt = BME280_OK
        cdef bme280_data comp_data
        cdef uint8_t sensor_mode

        """
        If sensor is in BME280_FORCED_MODE, one measurement is performed
        and sensor goes to BME280_SLEEP_MODE
        We must therefore set BME280_FORCED_MODE again to get a new
        measurement
        """
        rslt = bme280_get_sensor_mode(&sensor_mode, &self.dev)
        check_error(rslt, "bme280_get_sensor_data")
        if sensor_mode == BME280_SLEEP_MODE:
            rslt = bme280_set_sensor_mode(BME280_FORCED_MODE,
                                          &self.dev)

            check_error(rslt, "bme280_set_sensor_mode")

            self.dev.delay_ms(self.measurement_time)

        rslt = bme280_get_sensor_data(BME280_ALL,
                                      &comp_data,
                                      &self.dev)
        check_error(rslt, "bme280_get_sensor_data")

        res = {}
        res['temperature'] = comp_data.temperature / 100.0
        res['humidity'] = comp_data.humidity / 1024.0
        res['pressure'] = comp_data.pressure / 100.0
        res['timestamp'] = time.time()
        return res

    def __del__(self):
        bme280_close()
