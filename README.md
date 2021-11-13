# vi2c
**vi2c** is a tiny I2C communication library written in V.

`vi2c` provides the constructor function `vi2c.new(...)` which returns a new object of type `I2CDevice`; `connect()` and `disconnect` functions to open and close the i2c connection, and `read_` and `write_` functions as following:
- `read_data(max_length int) (int, []byte)`
- `write_data(data []byte) u32`
- `read_data_from_reg(reg byte, max_length int)(int, []byte)`
- `read_reg(reg byte)(int, []byte)`
- `write_reg_data(reg byte, data []byte) u32`
- `write_reg(reg byte, value byte) u32`

The constructor function - `new(...)` requires: the device filename of the I2C port where the I2C slave device is connected, I2C address of the slave device, and the device - which is more descriptive and doesn't have any implication on the logic.

```
mut ic2_dev := i2c.new('/dev/i2c-9', 0x48, 'Temp sensor')
```

## Demo

Output of `$v run test_i2c_comm.v` command.
```
{
	name:         Temp sensor,
	address:      0x48,
	filename:     /dev/i2c-9,
	is_connected: false
}
data: <182b> temp: 24.16797 *C
data: <182a> temp: 24.16406 *C
data: <182a> temp: 24.16406 *C
data: <182c> temp: 24.17188 *C
data: <1827> temp: 24.15234 *C
data: <1823> temp: 24.13672 *C
data: <1827> temp: 24.15234 *C
data: <1826> temp: 24.14844 *C
```

Waveform of I2C signal:
![](images/image.png)


## Setup
Since that my laptop is not equipped with an I2C external port, I had to use an USB to I2C bridge. This bridge device is using  **CH341A**. You have to use this driver [i2c-ch341-usb](https://github.com/allanbian1017/i2c-ch341-usb).

![](images/setup1.jpg)
![](images/setup3.jpg)