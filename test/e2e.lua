local check_path, sut_path, helper_path, library_path, serial_path, serial_interface_path, uinput_interface_path, baud =
   table.unpack(arg)

print("library path", library_path)
print("fake device path", sut_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
library.assert_truthy(library.BUTTON_PIN, "make sure it's loaded")
fake_device = package.loadlib(sut_path, "luaopen_sut")()

local uinput_interface = io.open(uinput_interface_path, "rb")
local serial_interface = io.open(serial_interface_path, "r+")
local check_next = dofile(check_path)(library, helpers)

print("\nnow the real thing")

LED_PIN = fake_device.led_builtin()

serial_interface = fake_device.serial_init()
fake_device.clear_eeprom()
fake_device.start()
helpers.sleep(0.5)
library.assert_truthy(
   fake_device.digital_read(library.BUTTON_PIN),
   "high means button not pressed"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)

library.assert_equal(fake_device.serial_baud(), tonumber(baud))

fake_device.digital_write(library.BUTTON_PIN, 0)
helpers.sleep(1)
library.assert_falsy(
   fake_device.digital_read(library.BUTTON_PIN),
   "push the button"
)
library.assert_truthy(
   fake_device.digital_read(LED_PIN),
   "high led matches low button"
)
check_next(uinput_interface, library.DEFAULT_CODE, 1)

fake_device.digital_write(library.BUTTON_PIN, 1)
helpers.sleep(0.1)
library.assert_truthy(
   fake_device.digital_read(library.BUTTON_PIN),
   "stop pushing"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)
check_next(uinput_interface, library.DEFAULT_CODE, 0)

local serial = io.open(serial_path, "w")
local new_code = 77
serial:write(tostring(new_code) .. "\n")
serial:flush()
serial:close()
helpers.sleep(0.5)

fake_device.digital_write(library.BUTTON_PIN, 0)
helpers.sleep(0.1)
library.assert_falsy(
   fake_device.digital_read(library.BUTTON_PIN),
   "push the button"
)
library.assert_truthy(
   fake_device.digital_read(LED_PIN),
   "high led matches low button"
)
check_next(uinput_interface, new_code, 1)

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
check_next(uinput_interface, new_code, 0)

fake_device.stop()
helpers.sleep(0.5)

print("DONE")
