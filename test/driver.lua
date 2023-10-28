local check_path, helper_path, library_path, serial_interface_path, uinput_interface_path, baud =
   table.unpack(arg)

print("local lib path", check_path)
print("library path", library_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
library.assert_truthy(library.BUTTON_PIN, "make sure it's loaded")
local check_next = dofile(check_path)(library, helpers)

local uinput_interface = io.open(uinput_interface_path, "rb")

print("\nmaybe try the driver alone first")
local serial_interface = io.open(serial_interface_path, "r+")
--[[ local serial_interface = io.open(serial_interface_path, "wb")
print("opened " .. serial_interface_path .. " temporarily for wrinting") ]]
serial_interface:write("D22\n")
serial_interface:flush()
helpers.sleep(1)

print("event size is " .. helpers.event_size())

check_next(uinput_interface, 22, 1)

print("driver alone seems ok")
