from libc.stdint cimport *

cdef extern from "bme280_defs.h":

    ctypedef void (*bme280_delay_fptr_t)(uint32_t period)

    cdef struct bme280_calib_data:
        uint16_t dig_T1
        int16_t dig_T2
        int16_t dig_T3
        uint16_t dig_P1
        int16_t dig_P2
        int16_t dig_P3
        int16_t dig_P4
        int16_t dig_P5
        int16_t dig_P6
        int16_t dig_P7
        int16_t dig_P8
        int16_t dig_P9
        uint8_t  dig_H1
        int16_t dig_H2
        uint8_t  dig_H3
        int16_t dig_H4
        int16_t dig_H5
        int8_t  dig_H6
        int32_t t_fine

    cdef struct bme280_data:
        uint32_t pressure
        int32_t temperature
        uint32_t humidity

    cdef struct bme280_uncomp_data:
        uint32_t pressure
        uint32_t temperature
        uint32_t humidity

    cdef struct bme280_settings:
        uint8_t osr_p
        uint8_t osr_t
        uint8_t osr_h
        uint8_t filter
        uint8_t standby_time

    cdef struct bme280_dev:
        uint8_t chip_id
        uint8_t dev_id
#         enum bme280_intf intf
#         bme280_tom_fptr_t read
#         bme280_tom_fptr_t write
        bme280_delay_fptr_t delay_ms
        bme280_calib_data calib_data
        bme280_settings settings

# name API success code
    int8_t BME280_OK

# name API error codes
    int8_t BME280_E_NULL_PTR
    int8_t BME280_E_DEV_NOT_FOUND
    int8_t BME280_E_INVALID_LEN
    int8_t BME280_E_COMM_FAIL
    int8_t BME280_E_SLEEP_MODE_FAIL

# name API warning codes
    int8_t BME280_W_INVALID_OSR_MACRO

# name Macros related to size
    uint8_t BME280_TEMP_PRESS_CALIB_DATA_LEN
    uint8_t BME280_HUMIDITY_CALIB_DATA_LEN
    uint8_t BME280_P_t_H_DATA_LEN

# name Sensor power modes
    uint8_t    BME280_SLEEP_MODE
    uint8_t    BME280_FORCED_MODE
    uint8_t    BME280_NORMAL_MODE


# name Macros for bit masking
    uint8_t BME280_SENSOR_MODE_MSK
    uint8_t BME280_SENSOR_MODE_POS

    uint8_t BME280_TTRL_HUM_MSK
    uint8_t BME280_TTRL_HUM_POS

    uint8_t BME280_TTRL_PRESS_MSK
    uint8_t BME280_TTRL_PRESS_POS

    uint8_t BME280_TTRL_TEMP_MSK
    uint8_t BME280_TTRL_TEMP_POS

    uint8_t BME280_FILTER_MSK
    uint8_t BME280_FILTER_POS

    uint8_t BME280_STANDBY_MSK
    uint8_t BME280_STANDBY_POS

# name Sensor component selection macros
# These values are internal for API implementation. Don't relate this to
# data sheet.*/
    uint8_t BME280_PRESS
    uint8_t BME280_TEMP
    uint8_t BME280_HUM
    uint8_t BME280_ALL

# name Settings selection macros
    uint8_t BME280_OSR_PRESS_SEL
    uint8_t BME280_OSR_TEMP_SEL
    uint8_t BME280_OSR_HUM_SEL
    uint8_t BME280_FILTER_SEL
    uint8_t BME280_STANDBY_SEL
    uint8_t BME280_ALL_SETTINGS_SEL

# name Oversampling macros
    uint8_t BME280_NO_OVERSAMPLING
    uint8_t BME280_OVERSAMPLING_1X
    uint8_t BME280_OVERSAMPLING_2X
    uint8_t BME280_OVERSAMPLING_4X
    uint8_t BME280_OVERSAMPLING_8X
    uint8_t BME280_OVERSAMPLING_16X

# # name Standby duration selection macros
    uint8_t BME280_STANDBY_TIME_1_MS
    uint8_t BME280_STANDBY_TIME_62_5_MS
    uint8_t BME280_STANDBY_TIME_125_MS
    uint8_t BME280_STANDBY_TIME_250_MS
    uint8_t BME280_STANDBY_TIME_500_MS
    uint8_t BME280_STANDBY_TIME_1000_MS
    uint8_t BME280_STANDBY_TIME_10_MS
    uint8_t BME280_STANDBY_TIME_20_MS
#
# # name Filter coefficient selection macros
    uint8_t BME280_FILTER_COEFF_OFF
    uint8_t BME280_FILTER_COEFF_2
    uint8_t BME280_FILTER_COEFF_4
    uint8_t BME280_FILTER_COEFF_8
    uint8_t BME280_FILTER_COEFF_16
