local check_path, sut_path, helper_path, library_path, firmware_lib_path, serial_path, serial_interface_path, uinput_interface_path, baud =
   table.unpack(arg)

print("library path", library_path)
print("fake device path", sut_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
fake_device = package.loadlib(sut_path, "luaopen_sut")()

firmware_library = dofile(firmware_lib_path)
DEFAULT_CODE = firmware_library.DEFAULT_CODE

local uinput_interface = io.open(uinput_interface_path, "rb")
local serial_interface = io.open(serial_interface_path, "r+")
local check_next = dofile(check_path)(library, helpers)

print("\nnow the real thing")

fake_device.serial_init(serial_interface)
fake_device.clear_eeprom()
fake_device.start()
helpers.sleep(0.5)
library.assert_falsy(firmware_library.get_led(fake_device))

library.assert_equal(fake_device.serial_baud(), tonumber(baud))

firmware_library.push_button(fake_device)
check_next(uinput_interface, DEFAULT_CODE, 1)
library.assert_truthy(firmware_library.get_led(fake_device))

firmware_library.release_button(fake_device)
check_next(uinput_interface, DEFAULT_CODE, 0)
library.assert_falsy(firmware_library.get_led(fake_device))

local serial = io.open(serial_path, "w")
local new_code = 77
serial:write(tostring(new_code) .. "\n")
serial:flush()
serial:close()
helpers.sleep(0.5)

firmware_library.push_button(fake_device)
check_next(uinput_interface, new_code, 1)
library.assert_truthy(firmware_library.get_led(fake_device))

firmware_library.release_button(fake_device)
check_next(uinput_interface, new_code, 0)
library.assert_falsy(firmware_library.get_led(fake_device))

fake_device.stop()
helpers.sleep(0.5)

print("DONE")
