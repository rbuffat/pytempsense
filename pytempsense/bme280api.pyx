from bme280driver.bme280_defs cimport *
from bme280driver.bme280 cimport *
from bme280driver.bme280_helper cimport init, bme280_close
import time
from libc.stdint cimport int8_t, uint8_t


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
    SLEEP = "SLEEP_MODE"
    FORCED = "FORCED"
    NORMAL = "NORMAL"


class BME280Oversampling:
    NO = "NO"
    X1 = "X1"
    X2 = "X2"
    X4 = "X4"
    X8 = "X8"
    X16 = "X16"


class BME280StandbyTime:
    TIME_1_MS = "1 MS"
    TIME_10_MS = "10 MS"
    TIME_20_MS = "20 MS"
    TIME_62_5_MS = "62.5 MS"
    TIME_125_MS = "125 MS"
    TIME_250_MS = "250 MS"
    TIME_500_MS = "500 MS"
    TIME_1000_MS = "1000 MS"


class BME280Filter:
    OFF = "OFF"
    COEFF_2 = "COEFF_2"
    COEFF_4 = "COEFF_4"
    COEFF_8 = "COEFF_8"
    COEFF_16 = "COEFF_16"


cdef inline _map_mode(mode):
    if mode == BME280SensorPowerMode.SLEEP:
        return BME280_SLEEP_MODE
    if mode == BME280SensorPowerMode.FORCED:
        return BME280_FORCED_MODE
    if mode == BME280SensorPowerMode.NORMAL:
        return BME280_NORMAL_MODE
    return None

cdef inline _map_oversampling(oversampling):
    if oversampling == BME280Oversampling.NO:
        return BME280_NO_OVERSAMPLING
    if oversampling == BME280Oversampling.X1:
        return BME280_OVERSAMPLING_1X
    if oversampling == BME280Oversampling.X2:
        return BME280_OVERSAMPLING_2X
    if oversampling == BME280Oversampling.X4:
        return BME280_OVERSAMPLING_4X
    if oversampling == BME280Oversampling.X8:
        return BME280_OVERSAMPLING_8X
    if oversampling == BME280Oversampling.X16:
        return BME280_OVERSAMPLING_16X
    return None

cdef inline _map_standby_time(standby_time):
    if standby_time == BME280StandbyTime.TIME_1_MS:
        return BME280_STANDBY_TIME_1_MS
    if standby_time == BME280StandbyTime.TIME_10_MS:
        return BME280_STANDBY_TIME_10_MS
    if standby_time == BME280StandbyTime.TIME_20_MS:
        return BME280_STANDBY_TIME_20_MS
    if standby_time == BME280StandbyTime.TIME_62_5_MS:
        return BME280_STANDBY_TIME_62_5_MS
    if standby_time == BME280StandbyTime.TIME_125_MS:
        return BME280_STANDBY_TIME_125_MS
    if standby_time == BME280StandbyTime.TIME_250_MS:
        return BME280_STANDBY_TIME_250_MS
    if standby_time == BME280StandbyTime.TIME_500_MS:
        return BME280_STANDBY_TIME_500_MS
    if standby_time == BME280StandbyTime.TIME_1000_MS:
        return BME280_STANDBY_TIME_1000_MS
    return None

cdef inline _map_filter(filter_coeff):
    if filter_coeff == BME280Filter.OFF:
        return BME280_FILTER_COEFF_OFF
    if filter_coeff == BME280Filter.COEFF_2:
        return BME280_FILTER_COEFF_2
    if filter_coeff == BME280Filter.COEFF_4:
        return BME280_FILTER_COEFF_4
    if filter_coeff == BME280Filter.COEFF_8:
        return BME280_FILTER_COEFF_8
    if filter_coeff == BME280Filter.COEFF_16:
        return BME280_FILTER_COEFF_16
    return None


cdef class BME280:
    """ Interface to the BME280 sensor over I2C using Bosch Sensortec's
    BME280 sensor API: https://github.com/BoschSensortec/BME280_driver


    standby_time must be set for NORMAL mode and is ignored
    in FORCED mode
    """

    cdef bme280_dev dev
    cdef public uint8_t device_id
    cdef public uint8_t chip_id

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

        _sensor_mode = _map_mode(sensor_mode)
        if _sensor_mode is None:
            raise ValueError("sensor_mode needs to be of type BME280SensorPowerMode")

        if _sensor_mode == BME280_NORMAL_MODE and standby_time is None:
            raise ValueError("standby_time must be set for NORMAL mode")

        sel_settings = []
        if humidity_oversampling is not None:
            _humidity_oversampling = _map_oversampling(humidity_oversampling)
            if _humidity_oversampling is None:
                raise ValueError("humidity_oversampling needs to be of type BME280Oversampling")
            self.dev.settings.osr_h = _humidity_oversampling
            sel_settings.append(BME280_OSR_HUM_SEL)

        if pressure_oversampling is not None:
            _pressure_oversampling = _map_oversampling(pressure_oversampling)
            if _pressure_oversampling is None:
                raise ValueError("pressure_oversampling needs to be of type BME280Oversampling")
            self.dev.settings.osr_p = _pressure_oversampling
            sel_settings.append(BME280_OSR_PRESS_SEL)

        if temperature_oversampling is not None:
            _temperature_oversampling = _map_oversampling(temperature_oversampling)
            if _temperature_oversampling is None:
                raise ValueError("temperature_oversampling needs to be of type BME280Oversampling")
            self.dev.settings.osr_t = _temperature_oversampling
            sel_settings.append(BME280_OSR_TEMP_SEL)

        if filter_coeff is not None:
            _filter_coeff = _map_filter(filter_coeff)
            if _filter_coeff is None:
                raise ValueError("filter_coeff needs to be of type BME280Filter")
            self.dev.settings.filter = _filter_coeff
            sel_settings.append(BME280_FILTER_SEL)

        if _sensor_mode == BME280_NORMAL_MODE:
            _standby_time = _map_standby_time(standby_time)
            if _standby_time is None:
                raise ValueError("standby_time needs to be of type BME280StandbyTime")
            self.dev.settings.standby_time = _standby_time
            sel_settings.append(BME280_STANDBY_SEL)

        for _sel_setting in sel_settings:
            settings_sel |= _sel_setting
        rslt = bme280_set_sensor_settings(settings_sel,
                                          &self.dev)
        check_error(rslt, "bme280_set_sensor_settings")

        rslt = bme280_set_sensor_mode(_sensor_mode,
                                      &self.dev)
        check_error(rslt, "bme280_set_sensor_mode")

    def poll(self):
        """
        Returns a dictionary with sensor readings

        The dictionary contains the following keys:
        -'temperature', unit: degree Celsius
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
