local helper_path, library_path, uinput_interface_path, serial_path, baud =
   table.unpack(arg)

print("library path", library_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
library.assert_truthy(library.assert_in, "make sure it's loaded")

local serial_file = io.open(serial_path, "r")
assert(serial_file, serial_path)

local serial_content = serial_file:read("*l")
serial_file:close() -- this is where using fifo to mock serial is gonna get a bit shaky
library.assert_in("-echo", serial_content)
library.assert_in(serial_path, serial_content)
library.assert_in(baud, serial_content)

local constants = helpers.get_constants()
print("\nthese will come in handy when checking errors")
for k, v in pairs(constants) do
   print(k, v)
end

local uinput_interface = io.open(uinput_interface_path, "rb")

function assert_ioctl(f, ...)
   local line = f:read("*L")
   local expected_line = "IOCTL: "

   for i, v in ipairs({ ... }) do
      expected_line = expected_line .. v
      if i < select("#", ...) then
         expected_line = expected_line .. " "
      else
         expected_line = expected_line .. "\n"
      end
   end

   library.assert_equal(expected_line, line)
end

print("\ncheck driver initialization")

-- here we are basically copying the implementation
-- but at least we know it is going to the right fd and stuff
assert_ioctl(uinput_interface, constants.UI_SET_EVBIT, constants.EV_KEY)
for i = constants.KEY_ESC, constants.KEY_MICMUTE do
   assert_ioctl(uinput_interface, constants.UI_SET_KEYBIT, i)
end

local ui_dev_create = uinput_interface:read("*L")
library.assert_in(constants.UI_DEV_SETUP, ui_dev_create)
local size_of_structure = helpers.parse_uinput_user_dev()
local uinput_user_dev_message = uinput_interface:read(size_of_structure)

-- check the handing of this error
library.assert_in("Mismatch", helpers.parse_uinput_user_dev("test"))

local uinput_user_dev = helpers.parse_uinput_user_dev(uinput_user_dev_message)

-- pretty much copied the answers from the implementation
-- mainly just shows that it is sending a valid structure
library.assert_equal(uinput_user_dev.name, "Example device")
library.assert_equal(uinput_user_dev.vendor, 0x1234)
library.assert_equal(uinput_user_dev.version, 4)
library.assert_equal(uinput_user_dev.bustype, 3)
library.assert_equal(uinput_user_dev.product, 0x5678)

assert_ioctl(uinput_interface, constants.UI_DEV_CREATE)

print("\ndriver initialization checks")
