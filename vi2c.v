module vi2c

#include "fcntl.h"
#include "stdio.h"
#include "stddef.h"
#include "sys/types.h"
#include "stdint.h"
#include "features.h"
#include "linux/i2c-dev.h"
#include "sys/ioctl.h"

fn C.open(&char, u32) int
fn C.write(int, voidptr, usize) int
fn C.read(int, voidptr, usize) int
fn C.close(int)
fn C.ioctl(int, int, voidptr) int
fn C.fcntl(int, int, int) int

const version = '1.2'

struct I2CDevice {
mut:
	m_fd              int
	m_name            string
	m_device_address  u8
	m_device_filename string
	m_is_connected    bool
	m_is_forced       bool
	m_is_10bit        bool
}

// Function `new(filename string, address u8, name string, is_10bit bool) I2CDevice`
// Creates a new I2CDevice instance.
// * `filename (string)`: File path of the I2C device.
// * `address (u8)`: I2C device address.
// * `name (string)`: Name of the device.
// * `is_10bit (bool)`: `true` if 10 bit address, 
// otherwise 7 bit address.
pub fn new(filename string, addres u8, name string, is_10bit bool) I2CDevice {
	return I2CDevice{
		m_device_filename: filename
		m_device_address: addres
		m_name: name
		m_is_connected: false
		m_is_forced: false
		m_is_10bit: is_10bit
		m_fd: -1
	}
}

// Function `connect(force_connection bool) bool`
// Connects to the I2C device.
// * `force_connection (bool)`: Indicates if the connection 
//   should be forced. Force (or not) using this slave address, even if it is already in use by a driver.
// Returns `true` if the connection is successful, 
// otherwise `false`.
pub fn (mut d I2CDevice) connect(force_connection bool) bool {
	d.m_fd = C.open(d.m_device_filename.str, C.O_RDWR)

	if d.m_fd < 0 {
		return false
	}

	slave_address := d.m_device_address

	mut attr := C.I2C_SLAVE
	if force_connection {
		// C.I2C_SLAVE_FORCE
		d.m_is_forced = true
		attr = C.I2C_SLAVE_FORCE
	}

	mut rc := C.ioctl(d.m_fd, attr, voidptr(slave_address))
	if rc < 0 {
		C.close(d.m_fd)
		return false
	}

	if d.m_is_10bit {
		rc = C.ioctl(d.m_fd, C.I2C_TENBIT, 1)
		if rc < 0 {
			d.m_is_10bit = false
		}
	}

	d.m_is_connected = true
	return true
}

// Function `read_data(max_length int) (int, []u8)`
// Reads data from the I2C device.
// * `max_length (int)`: Maximum length of data to read.
// Returns the number of bytes read and the data as a byte slice.
pub fn (mut d I2CDevice) read_data(max_length int) (int, []u8) {
	unsafe {
		mut buf := malloc_noscan(max_length + 1)
		nu8s := C.read(d.m_fd, buf, max_length)
		if nu8s < 0 {
			free(buf)
			return 0, []u8{len: 0}
		}

		if nu8s <= max_length {
			buf[nu8s] = 0
		} else {
			buf[max_length] = 0
		}

		return nu8s, buf.vbytes(nu8s)
	}
}

// Function `write_data(data []u8) u32`
// Writes data to the I2C device.
// * `data ([]u8)`: Data to write.
// Returns the number of bytes written.
pub fn (mut d I2CDevice) write_data(data []u8) u32 {
	rc := int(C.write(d.m_fd, voidptr(&data[0]), usize(data.len)))

	if rc > 0 {
		return u32(rc)
	}

	return 0
}

// Function `read_data_from_reg(reg u8, max_length int) (int, []u8)`
// Reads data from a register of the I2C device.
// * `reg (u8)`: Register address to read from.
// * `max_length (int)`: Maximum length of data to read.
// Returns the number of bytes read and the data as a byte slice.
pub fn (mut d I2CDevice) read_data_from_reg(reg u8, max_length int) (int, []u8) {
	if !d.m_is_connected {
		return 0, []u8{len: 0}
	}

	mut rc := d.write_data([reg])
	if rc < 0 {
		return 0, []u8{len: 0}
	}

	return d.read_data(max_length)
}

// Function `read_reg(reg u8) (int, []u8)`
// Reads a register from the I2C device.
// * `reg (u8)`: Register address to read.
// Returns the value read from the register as a byte slice.
pub fn (mut d I2CDevice) read_reg(reg u8) (int, []u8) {
	return d.read_data_from_reg(reg, 1)
}

// Function `write_reg_data(reg u8, data []u8) u32`
// Writes data to a register of the I2C device.
// * `reg (u8)`: Register address to write to.
// * `data ([]u8)`: Data to write.
// Returns the number of bytes written.
pub fn (mut d I2CDevice) write_reg_data(reg u8, data []u8) u32 {
	mut buff := [reg]
	buff << data

	return d.write_data(buff)
}

// Function `write_reg(reg u8, value u8) u32`
// Writes a value to a register of the I2C device.
// * `reg (u8)`: Register address to write to.
// * `value (u8)`: Value to write.
// Returns the number of bytes written.
pub fn (mut d I2CDevice) write_reg(reg u8, value u8) u32 {
	mut buff := [reg, value]

	return d.write_data(buff)
}

// Function `disconnect()`
// Disconnects from the I2C device.
pub fn (mut d I2CDevice) disconnect() {
	if !d.m_is_connected {
		return
	}

	C.close(d.m_fd)
	d.m_fd = -1
	d.m_is_connected = false
}

// Function `is_forced() bool`
// Checks if the connection to the I2C device was forced.
// Returns `true` if the connection was forced, otherwise `false`.
pub fn (d I2CDevice) is_forced() bool {
	return d.m_is_forced
}

// Functon `is_connected() bool`
// Checks if the connection to the I2C device is established.
// Returns `true` if connected, otherwise `false`.
pub fn (d I2CDevice) is_connected() bool {
	return d.m_is_connected
}

// Function `name() string`
// Gets the name of the I2C device.
// Returns the name of the device.
pub fn (d I2CDevice) name() string {
	return d.m_name
}

// Function `filename() string`
// Gets the file path of the I2C device.
// Returns the file path of the device.
pub fn (d I2CDevice) filename() string {
	return d.m_device_filename
}

// Function `address() u8`
// Gets the address of the I2C device.
// Returns the address of the device.
pub fn (d I2CDevice) address() u8 {
	return d.m_device_address
}

// Function `fd() int`
// Gets the file descriptor of the I2C device.
// Returns the file descriptor.
pub fn (d I2CDevice) fd() int {
	return d.m_fd
}

// Function `set_retries(retries int) bool`
// Sets the number of retries for I2C communication.
// * `retries (int)`: The number of retries to set.
// Returns `(bool)`: true if the retries were successfully set, 
// otherwise `false`.
pub fn (d I2CDevice) set_retries(retries int) bool {
	rc := C.ioctl(d.m_fd, C.I2C_RETRIES, retries)
	if rc < 0 {
		return false
	}
	return true
}

// Function `set_timeout(timeout_ms int) bool`
// Sets the timeout for I2C communication.
// * `timeout_ms (int)`: Timeout value in milliseconds.
// Returns `(bool)`: `true` if the timeout was successfully set, 
// otherwise `false`.
pub fn (d I2CDevice) set_timeout(timeout_ms int) bool {
	timeout_10ms := int(timeout_ms / 10)
	rc := C.ioctl(d.m_fd, C.I2C_TIMEOUT, timeout_10ms)
	if rc < 0 {
		return false
	}
	return true
}

// Function `is_10bit() bool`
// Checks if the I2C device address is 10-bit.
// Returns `(bool)`: true if the I2C device address is 10-bit, 
// otherwise `false`.
pub fn (d I2CDevice) is_10bit() bool {
	return d.m_is_10bit
}

// Returns a formatted string representing the I2C device.
pub fn (d I2CDevice) str() string {
	mut rstr := 'I2C Device {\n'
	rstr += "\t\"name\":         ${d.m_name},\n"
	rstr += "\t\"address\":      0x${d.m_device_address.hex()},\n"
	rstr += "\t\"filename\":     ${d.m_device_filename},\n"
	rstr += "\t\"is_connected\": ${d.m_is_connected}\n"
	rstr += "\t\"is_forced\":    ${d.m_is_forced}\n"
	rstr += '}'

	return rstr
}
