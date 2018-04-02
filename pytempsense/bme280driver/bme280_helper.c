#include "bme280.h"
#include <time.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <asm/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include "bme280_helper.h"
#include <stdio.h>

static int bme280fd;

int8_t bme280_i2c_setup(int bus, int slave) {
    char device[128];
    sprintf(device, "/dev/i2c-%d", bus);
    bme280fd = open(device, O_RDWR);
    if (bme280fd < 0) {
        return BME280_E_COMM_FAIL;
    }

    if (ioctl(bme280fd, I2C_SLAVE, slave) < 0) {
        return BME280_E_COMM_FAIL;
    }
    return BME280_OK;
}

// Read function for Bosch driver
int8_t user_i2c_read(uint8_t dev_id, uint8_t reg_addr, uint8_t *data, uint16_t len)
{

    uint8_t tx[1] = {};
    tx[0] = reg_addr;
    int ws = write(bme280fd, tx, 1);

    int rs = read(bme280fd, data, len);

    return ws == 1 && rs == len ? BME280_OK : BME280_E_COMM_FAIL;
}

// Write function for Bosch driver
int8_t user_i2c_write(uint8_t dev_id, uint8_t reg_addr, uint8_t *data, uint16_t len)
{
    uint8_t tx[len+1];
    tx[0] = reg_addr;
    for(uint32_t i = 0; i < len; i++)
    {
        tx[i+1] = data[i];
    }
    int ws = write(bme280fd, tx, len+1);

    return ws == len + 1 ? BME280_OK : BME280_E_COMM_FAIL;

}

// Delay function for Bosch driver
void user_delay_ms(uint32_t period)
{
    struct timespec ts_sleep =
    {
        period / 1000,
                (period % 1000) * 1000000L
    };

    nanosleep(&ts_sleep, NULL);
}

int8_t init(int bus, struct bme280_dev *dev)
{
    if (!bme280_i2c_setup(bus, BME280_I2C_ADDR_PRIM) == BME280_OK)
    {
        if (!bme280_i2c_setup(bus, BME280_I2C_ADDR_SEC) == BME280_OK)
        {
            return BME280_E_COMM_FAIL;
        }
    }

    int8_t rslt = BME280_OK;

    dev->dev_id = BME280_I2C_ADDR_PRIM;
    dev->intf = BME280_I2C_INTF;
    dev->read = user_i2c_read;
    dev->write = user_i2c_write;
    dev->delay_ms = user_delay_ms;

    rslt = bme280_init(dev);

    return rslt;
}

int32_t bme280_close(void)
{
  return close(bme280fd);
}



