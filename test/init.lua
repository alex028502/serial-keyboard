local helper_path, library_path, uinput_interface_path, baud = table.unpack(arg)

print("library path", library_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
library.assert_truthy(library.BUTTON_PIN, "make sure it's loaded")
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
      end
   end
   expected_line = expected_line .. "\n"

   library.assert_equal(expected_line, line)
end

print("\ncheck driver initialization")

-- here we are basically copying the implementation
-- but at least we know it is going to the right fd and stuff
assert_ioctl(uinput_interface, constants.UI_SET_EVBIT, constants.EV_KEY)
for i = constants.KEY_ESC, constants.KEY_MICMUTE do
   assert_ioctl(uinput_interface, constants.UI_SET_KEYBIT, i)
end

-- would be cool to look up the pointer that is passed in
-- and assert the data structure inside
library.assert_in(constants.UI_DEV_SETUP, uinput_interface:read("*L"))
assert_ioctl(uinput_interface, constants.UI_DEV_CREATE)

print("\ndriver initialization checks")
