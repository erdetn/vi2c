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

struct I2CDevice {
mut:
	m_fd              int
	m_name            string
	m_device_address  u8
	m_device_filename string
	m_is_connected    bool
	m_is_forced       bool
}

pub fn new(filename string, addres u8, name string) I2CDevice {
	return I2CDevice{
		m_device_filename: filename
		m_device_address: addres
		m_name: name
		m_is_connected: false
		m_is_forced: false
		m_fd: -1
	}
}

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
	rc := C.ioctl(d.m_fd, attr, voidptr(slave_address))
	if rc < 0 {
		C.close(d.m_fd)
		return false
	}

	d.m_is_connected = true
	return true
}

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

pub fn (mut d I2CDevice) write_data(data []u8) u32 {
	rc := int(C.write(d.m_fd, voidptr(&data[0]), usize(data.len)))

	if rc > 0 {
		return u32(rc)
	}

	return 0
}

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

pub fn (mut d I2CDevice) read_reg(reg u8) (int, []u8) {
	return d.read_data_from_reg(reg, 1)
}

pub fn (mut d I2CDevice) write_reg_data(reg u8, data []u8) u32 {
	mut buff := [reg]
	buff << data

	return d.write_data(buff)
}

pub fn (mut d I2CDevice) write_reg(reg u8, value u8) u32 {
	mut buff := [reg, value]

	return d.write_data(buff)
}

pub fn (mut d I2CDevice) disconnect() {
	if !d.m_is_connected {
		return
	}

	C.close(d.m_fd)
	d.m_fd = -1
	d.m_is_connected = false
}

pub fn (d I2CDevice) is_forced() bool {
	return d.m_is_forced
}

pub fn (d I2CDevice) is_connected() bool {
	return d.m_is_connected
}

pub fn (d I2CDevice) name() string {
	return d.m_name
}

pub fn (d I2CDevice) filename() string {
	return d.m_device_filename
}

pub fn (d I2CDevice) address() u8 {
	return d.m_device_address
}

pub fn (d I2CDevice) fd() int {
	return d.m_fd
}

pub fn (d I2CDevice) str() string {
	mut rstr := 'I2C Device {\n'
	rstr += '\t\"name\":         ${d.m_name},\n'
	rstr += '\t\"address\":      0x${d.m_device_address.hex()},\n'
	rstr += '\t\"filename\":     ${d.m_device_filename},\n'
	rstr += '\t\"is_connected\": ${d.m_is_connected}\n'
	rstr += '\t\"is_forced\":    ${d.m_is_forced}\n'
	rstr += '}'

	return rstr
}
