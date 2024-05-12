# vi2c
`vi2c` is a tiny I2C communication library written in V.

# Documentation

```struct I2CDevice```

Represents an I2C device.
Fields:

* `m_fd (int)`: File descriptor (-1 if not open).
* `m_name (string)`: Name of the device.
* `m_device_address (u8)`: I2C device address.
* `m_device_filename (string)`: File path of the I2C device.
* `m_is_connected (bool)`: Indicates if the device is connected.
* `m_is_forced (bool)`: Indicates if the connection was forced.


## Functions

#### Function ```new(filename string, address u8, name string) I2CDevice```

Creates a new I2CDevice instance.

* `filename (string)`: File path of the I2C device.
* `address (u8)`: I2C device address.
* `name (string)`: Name of the device.

____
#### Function ```connect(force_connection bool) bool```

Connects to the I2C device.

* `force_connection (bool)`: Indicates if the connection should be forced. Force (or not) using this slave address, even if it is already in use by a driver.

Returns `true` if the connection is successful, otherwise `false`.
____
#### Function ```read_data(max_length int) (int, []u8)```

Reads data from the I2C device.

* `max_length (int)`: Maximum length of data to read.

Returns the number of bytes read and the data as a byte slice.
____
#### Function ```write_data(data []u8) u32```

Writes data to the I2C device.

* `data ([]u8)`: Data to write.

Returns the number of bytes written.
____
#### Function ```read_data_from_reg(reg u8, max_length int) (int, []u8)```

Reads data from a register of the I2C device.

* `reg (u8)`: Register address to read from.
* `max_length (int)`: Maximum length of data to read.
  
Returns the number of bytes read and the data as a byte slice.
____
#### Function `read_reg(reg u8) (int, []u8)`

Reads a register from the I2C device.
* `reg (u8)`: Register address to read.

Returns the value read from the register as a byte slice.
____
#### Function `write_reg_data(reg u8, data []u8) u32`

Writes data to a register of the I2C device.
* `reg (u8)`: Register address to write to.
* `data ([]u8)`: Data to write.

Returns the number of bytes written.
____
#### Function `write_reg(reg u8, value u8) u32`

Writes a value to a register of the I2C device.
* `reg (u8)`: Register address to write to.
* `value (u8)`: Value to write.

Returns the number of bytes written.
____
#### Function `disconnect()`
Disconnects from the I2C device.
____
#### Function `is_forced() bool`
Checks if the connection to the I2C device was forced.
Returns `true` if the connection was forced, otherwise `false`.
____
#### Functon `is_connected() bool`
Checks if the connection to the I2C device is established.
Returns `true` if connected, otherwise `false`.
____
#### Function `name() string`
Gets the name of the I2C device.
Returns the name of the device.
____
#### Function `filename() string`
Gets the file path of the I2C device.
Returns the file path of the device.
____
#### Function `address() u8`
Gets the address of the I2C device.
Returns the address of the device.
____
#### Function `fd() int`
Gets the file descriptor of the I2C device.
Returns the file descriptor.
____
#### Function `str() string`
Returns a string representation of the I2C device.
Returns a formatted string representing the device.
____

## Example

```v
module main

import time
import vi2c

fn main() {
	mut ic2_dev := vi2c.new('/dev/i2c-9', 0x48, 'Temp sensor')

	println(ic2_dev)

	if !ic2_dev.connect(true) {
		println('Failed to connect')
		return
	}

	println(ic2_dev)

	for _ in 1 .. 100 {
		len, data := ic2_dev.read_data_from_reg(~0, 2)

		if len == 2 {
			val := 0.00390625 * f32(u32(data[0]) << 8 | u32(data[1]))
			println('data: <${data.hex()}> temp: ${val} *C')
		}
		time.sleep(1000000000)
	}

	ic2_dev.disconnect()
}

```

## Compile

```sh
cd ~/.vmodules
cd vi2c/playground/
```

To compile it for Linux host machine (x64/x86-64), make sure to specify the `include` path:
```sh
v -cflags '-I /usr/include/' . -o test_i2c_comm_x64
```

To cross-compile it for **Aarch64**, make sure that `aarch64-linux-gnu-gcc` and corresponding libraries are installed. 
Set `aarch64-linux-gnu-gcc` as `-cc` compiler, disable and add the `include` of **Aarch64** - in this case `/usr/aarch64-linux-gnu/include/`.
```sh
v -cc aarch64-linux-gnu-gcc -gc none -cflags '--static -I /usr/aarch64-linux-gnu/include/' test_i2c_comm.v -o test_i2c_comm_aa64

```

	NOTE: Please note that the library and the example code are tested in my Ubuntu 20.4 and an Aarch64 machine.