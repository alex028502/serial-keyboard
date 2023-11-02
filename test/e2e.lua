local check_path, sut_path, helper_path, library_path, firmware_lib_path, serial_path, serial_interface_path, uinput_interface_path, baud =
   table.unpack(arg)

print("library path", library_path)
print("fake device path", sut_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
fake_device = package.loadlib(sut_path, "luaopen_sut")()

firmware_library = dofile(firmware_lib_path)
BUTTON_PIN = firmware_library.BUTTON_PIN
DEFAULT_CODE = firmware_library.DEFAULT_CODE

local uinput_interface = io.open(uinput_interface_path, "rb")
local serial_interface = io.open(serial_interface_path, "r+")
local check_next = dofile(check_path)(library, helpers)

print("\nnow the real thing")

LED_PIN = fake_device.led_builtin()

fake_device.serial_init(serial_interface)
fake_device.clear_eeprom()
fake_device.start()
helpers.sleep(0.5)
library.assert_truthy(
   fake_device.digital_read(BUTTON_PIN),
   "high means button not pressed"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)

library.assert_equal(fake_device.serial_baud(), tonumber(baud))

fake_device.digital_write(BUTTON_PIN, 0)
check_next(uinput_interface, DEFAULT_CODE, 1)
library.assert_truthy(
   fake_device.digital_read(LED_PIN),
   "high led matches low button"
)

fake_device.digital_write(BUTTON_PIN, 1)
check_next(uinput_interface, DEFAULT_CODE, 0)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)

local serial = io.open(serial_path, "w")
local new_code = 77
serial:write(tostring(new_code) .. "\n")
serial:flush()
serial:close()
helpers.sleep(0.5)

fake_device.digital_write(BUTTON_PIN, 0)
check_next(uinput_interface, new_code, 1)
library.assert_truthy(
   fake_device.digital_read(LED_PIN),
   "high led matches low button"
)

fake_device.digital_write(BUTTON_PIN, 1)
check_next(uinput_interface, new_code, 0)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)

fake_device.stop()
helpers.sleep(0.5)

print("DONE")
