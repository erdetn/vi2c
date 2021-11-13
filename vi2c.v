module vi2c

#flag -I /usr/include/
#flag -I /usr/include/x86_64-linux-gnu/
#flag -I /usr/include/x86_64-linux-gnu/sys

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <errno.h>
#include <features.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>

fn C.open(&char, u32) int
fn C.write(int, voidptr, usize) int
fn C.read(int, voidptr, usize) int
fn C.close(int)
fn C.ioctl(int, int, voidptr) int
fn C.fcntl(int, int, int) int

struct I2CDevice {
mut:
	fd              int    // -1 (not open) or >0 open port
	name            string // 'ADC Light sensor'
	device_address  byte   // byte(0x48)
	device_filename string // '/dev/i2c-x'
	is_connected    bool
}

pub fn new(filename string, addres byte, name string) I2CDevice {
	return I2CDevice{
		device_filename: filename
		device_address: addres
		name: name
		is_connected: false
		fd: -1
	}
}

pub fn (mut this I2CDevice) connect() bool {
	this.fd = C.open(this.device_filename.str, C.O_RDWR)

	if this.fd < 0 {
		return false
	}

	// set I2C slace address
	// voidptr(&this.device_address)
	slave_address := this.device_address
	rc := C.ioctl(this.fd, C.I2C_SLAVE_FORCE, voidptr(slave_address))
	if rc < 0 {
		C.close(this.fd)
		return false
	}

	this.is_connected = true
	return true
}

pub fn (mut this I2CDevice) read_data(max_length int) (int, []byte) {
	unsafe {
		mut buf := malloc_noscan(max_length + 1)
		nbytes := C.read(this.fd, buf, max_length)
		if nbytes < 0 {
			free(buf)
			return 0, []byte{len: 0}
		}

		if nbytes <= max_length {
			buf[nbytes] = 0
		} else {
			buf[max_length] = 0
		}

		return nbytes, buf.vbytes(nbytes)
	}
}

pub fn (mut this I2CDevice) write_data(data []byte) u32 {
	rc := int(C.write(this.fd, voidptr(&data[0]), usize(data.len)))

	if rc > 0 {
		return u32(rc)
	}

	return 0
}

pub fn (mut this I2CDevice) read_data_from_reg(reg byte, max_length int) (int, []byte) {
	if !this.is_connected {
		return 0, []byte{len: 0}
	}

	mut rc := this.write_data([reg])
	if rc < 0 {
		return 0, []byte{len: 0}
	}

	return this.read_data(max_length)
}

pub fn (mut this I2CDevice) read_reg(reg byte) (int, []byte) {
	return this.read_data_from_reg(reg, 1)
}

pub fn (mut this I2CDevice) write_reg_data(reg byte, data []byte) u32 {
	mut buff := [reg]
	buff << data

	return this.write_data(buff)
}

pub fn (mut this I2CDevice) write_reg(reg byte, value byte) u32 {
	mut buff := [reg, value]

	return this.write_data(buff)
}

pub fn (mut this I2CDevice) disconnect() {
	if !this.is_connected {
		return
	}

	C.close(this.fd)
	this.fd = -1
	this.is_connected = false
}

pub fn (this I2CDevice) str() string {
	mut rstr := '{\n'
	rstr += '\tname:         $this.name,\n'
	rstr += '\taddress:      0x$this.device_address.hex(),\n'
	rstr += '\tfilename:     $this.device_filename,\n'
	rstr += '\tis_connected: $this.is_connected\n'
	rstr += '}'

	return rstr
}
