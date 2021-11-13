module main

import time
import vi2c

fn main() {
	mut ic2_dev := vi2c.new('/dev/i2c-9', 0x48, 'Temp sensor')

	println(ic2_dev)

	if !ic2_dev.connect() {
		println('Failed to connect')
		return
	}

	for _ in 1 .. 100 {
		len, data := ic2_dev.read_data_from_reg(~0, 2)

		if len == 2 {
			val := 0.00390625 * f32(u32(data[0]) << 8 | u32(data[1]))
			println('data: <$data.hex()> temp: $val *C')
		}
		time.sleep(1000000000)
	}

	ic2_dev.disconnect()
}
