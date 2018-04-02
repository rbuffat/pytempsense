#ifndef BME280_API_H_
#define BME280_API_H_

#include "bme280_defs.h"
#include <stdint.h>
#include <stddef.h>

int8_t init(int bus, struct bme280_dev *dev);

int32_t bme280_close(void);

#endif /* BME280_DEFS_H_ */
