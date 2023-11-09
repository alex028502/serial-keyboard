local luassert = require("luassert")
local check_path, helper_path, library_path, serial_interface_path, uinput_interface_path, baud, driver_pid =
   table.unpack(arg)

print("local lib path", check_path)
print("library path", library_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
local check_next = dofile(check_path)(helpers)

local uinput_interface = io.open(uinput_interface_path, "rb")

print("\nmaybe try the driver alone first")
local serial_interface = io.open(serial_interface_path, "r+")
--[[ local serial_interface = io.open(serial_interface_path, "wb")
print("opened " .. serial_interface_path .. " temporarily for wrinting") ]]
serial_interface:write("D22\n")
serial_interface:flush()

print("event size is " .. helpers.event_size())

check_next(uinput_interface, 22, 1)

-- send some garbage to prove it can handle it
-- and then another message

serial_interface:write("test\n")
serial_interface:write("\n")
serial_interface:write("U22\n")
serial_interface:flush()

check_next(uinput_interface, 22, 0)

-- because of how the fifo works just closing our fd should be enough to shut
-- the driver down
serial_interface:close()

local expected_last_line = "IOCTL: " .. helpers.get_constants().UI_DEV_DESTROY
local last_line = uinput_interface:read("*l")
luassert.are.equals(expected_last_line, last_line)

print("driver alone seems ok")
while os.execute("kill -0 " .. driver_pid) do
   -- if it ever shuts down too fast and we don't get a single sleep
   -- coverage will let us know
   print("waiting for driver to shut down nicely")
   helpers.sleep(100)
end
