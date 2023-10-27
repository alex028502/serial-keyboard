print("path: " .. package.path)
print("cpath: " .. package.cpath)

-- it was too hard to get everything working at once
-- so I needed to test the arduino program on its own first
-- well not so much the arduino program as the fake framework
-- I mean the sketch worked right away

local sut_path, library_path, serial_path, serial_interface_path, baud =
   table.unpack(arg)

library = dofile(library_path)
print("fake device path", sut_path)
fake_device = library.import(sut_path, "luaopen_sut")
helpers = fake_device -- TODO: inline

function assert_message(f, code, key)
   local message = f:read("L")
   library.assert_truthy(message, "something written")
   library.assert_equal(code .. tostring(key) .. "\n", message)
end

library.assert_truthy(library.BUTTON_PIN, "make sure it's loaded")

LED_PIN = fake_device.led_builtin()
print("led pin is " .. LED_PIN)

local serial = io.open(serial_path, "r+")
local serial_interface = io.open(serial_interface_path, "r+")
library.assert_truthy(serial, "serial port that connects to computer")
library.assert_truthy(serial_interface, "serial port to control simulation")
-- helpers.set_fd_nonblocking(serial_interface)

fake_device.serial_init(serial_interface)
fake_device.clear_eeprom()
library.assert_equal(fake_device.serial_baud(), 0)
fake_device.start()
fake_device.sleep(0.2)
library.assert_truthy(
   fake_device.digital_read(library.BUTTON_PIN),
   "high means button not pressed"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)

baud_rate = tonumber(baud)
assert(baud_rate, baud)
assert(baud_rate > 0, baud)
library.assert_equal(fake_device.serial_baud(), baud_rate)

fake_device.digital_write(library.BUTTON_PIN, 0)
helpers.sleep(0.2)
library.assert_falsy(
   fake_device.digital_read(library.BUTTON_PIN),
   "push the button"
)
library.assert_truthy(
   fake_device.digital_read(LED_PIN),
   "high led matches low button"
)
assert_message(serial, "D", library.DEFAULT_CODE)

fake_device.digital_write(library.BUTTON_PIN, 1)
helpers.sleep(0.2)
library.assert_truthy(
   fake_device.digital_read(library.BUTTON_PIN),
   "stop pushing"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)
assert_message(serial, "U", library.DEFAULT_CODE)

local new_code = 77
serial:write(tostring(new_code) .. "\n")
serial:flush()
helpers.sleep(0.2)

fake_device.digital_write(library.BUTTON_PIN, 0)
helpers.sleep(0.2)
library.assert_falsy(
   fake_device.digital_read(library.BUTTON_PIN),
   "push the button"
)
library.assert_truthy(
   fake_device.digital_read(LED_PIN),
   "high led matches low button"
)
assert_message(serial, "D", new_code)

fake_device.digital_write(library.BUTTON_PIN, 1)
helpers.sleep(0.2)
library.assert_truthy(
   fake_device.digital_read(library.BUTTON_PIN),
   "stop pushing"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)
assert_message(serial, "U", new_code)

fake_device.stop()
helpers.sleep(0.3)

-- prediction - code coverage will tell me that I need to test the case where
-- I turn it on with the code already set

print("success")
