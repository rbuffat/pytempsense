from libc.stdint cimport int8_t, uint8_t

include "bme280_defs.pxd"

cdef extern from "bme280.h":

    int8_t bme280_init(bme280_dev *dev)

    int8_t bme280_set_regs(uint8_t *reg_addr, const uint8_t *reg_data, uint8_t len, const bme280_dev *dev)

    int8_t bme280_get_regs(uint8_t reg_addr, uint8_t *reg_data, uint16_t len, const bme280_dev *dev)

    int8_t bme280_set_sensor_settings(uint8_t desired_settings, const bme280_dev *dev)

    int8_t bme280_get_sensor_settings(bme280_dev *dev)

    int8_t bme280_set_sensor_mode(uint8_t sensor_mode, const bme280_dev *dev)

    int8_t bme280_get_sensor_mode(uint8_t *sensor_mode, const bme280_dev *dev)

    int8_t bme280_soft_reset(const bme280_dev *dev)

    int8_t bme280_get_sensor_data(uint8_t sensor_comp, bme280_data *comp_data, bme280_dev *dev)

    void bme280_parse_sensor_data(const uint8_t *reg_data, bme280_uncomp_data *uncomp_data)

    int8_t bme280_compensate_data(uint8_t sensor_comp, const bme280_uncomp_data *uncomp_data, bme280_data *comp_data, bme280_calib_data *calib_data)