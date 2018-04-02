from libc.stdint cimport int8_t, int32_t

include "bme280_defs.pxd"

cdef extern from "bme280_helper.h":

    int8_t init(int bus, bme280_dev *dev)

    int32_t bme280_close()
