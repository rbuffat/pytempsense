from libc.stdint cimport *

include "bme280_defs.pxd"

cdef extern from "bme280_helper.h":

    int8_t init(int bus, bme280_dev *dev)

    int32_t bme280_close()
