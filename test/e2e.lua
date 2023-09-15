local sut_path, helper_path, library_path, serial_path, serial_interface_path,
      uinput_interface_path, baud = table.unpack(arg)

print("library path", library_path)
print("fake device path", sut_path)
print("helper path", helper_path)

library = dofile(library_path)

helpers = library.import(helper_path, "luaopen_helpers")
library.assert_truthy(library.BUTTON_PIN, "make sure it's loaded")
local constants = helpers.get_constants()
print("\nthese will come in handy when checking errors")
for k, v in pairs(constants) do
   print(k, v)
end

fake_device = package.loadlib(sut_path, "luaopen_sut")()

local uinput_interface = io.open(uinput_interface_path, "rb")
helpers.set_fd_nonblocking(uinput_interface)

function assert_ioctl(f, ...)
   local line = f:read("*L")
   local expected_line = "IOCTL: "

   for i, v in ipairs({...}) do
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

print("\nmaybe try the driver alone first")
local serial_interface = io.open(serial_interface_path, "r+")
--[[ local serial_interface = io.open(serial_interface_path, "wb")
print("opened " .. serial_interface_path .. " temporarily for wrinting") ]]
serial_interface:write("D22\n")
serial_interface:flush()
helpers.sleep(1)

print("event size is " .. helpers.event_size())

function wait_for_next_event(f)
   for i = 1, 4 do
      local event = f:read(helpers.event_size())
      if event then
         return event
      end
      helpers.sleep(0.2 * i)
   end
end

function check_next(f, code, action)
   local main_event = wait_for_next_event(f)
   local syn_event = wait_for_next_event(f)
   library.assert_truthy(main_event, "something written a least")
   library.assert_truthy(syn_event, "something written a least")
   local main_type, main_code, main_value = helpers.read_key_event(main_event)
   local syn_type, syn_code, syn_value = helpers.read_key_event(syn_event)
   library.assert_equal(main_type, constants.EV_KEY)
   library.assert_equal(main_code, code)
   library.assert_equal(main_value, action)
   library.assert_equal(syn_type, constants.EV_SYN)
   library.assert_equal(syn_code, constants.SYN_REPORT)
   library.assert_equal(syn_value, 0)
end

check_next(uinput_interface, 22, 1)

print("\nnow the real thing")

LED_PIN = fake_device.led_builtin()

fake_device.serial_init(serial_interface)
fake_device.clear_eeprom()
fake_device.start()
helpers.sleep(0.5)
library.assert_truthy(fake_device.digital_read(library.BUTTON_PIN),
                      "high means button not pressed")
library.assert_falsy(fake_device.digital_read(LED_PIN),
                     "low led matches high button")

library.assert_equal(fake_device.serial_baud(), tonumber(baud))

fake_device.digital_write(library.BUTTON_PIN, 0)
helpers.sleep(0.5)
library.assert_falsy(fake_device.digital_read(library.BUTTON_PIN),
                     "push the button")
library.assert_truthy(fake_device.digital_read(LED_PIN),
                      "high led matches low button")
check_next(uinput_interface, library.DEFAULT_CODE, 1)

fake_device.digital_write(library.BUTTON_PIN, 1)
helpers.sleep(0.1)
library.assert_truthy(fake_device.digital_read(library.BUTTON_PIN),
                      "stop pushing")
library.assert_falsy(fake_device.digital_read(LED_PIN),
                     "low led matches high button")
check_next(uinput_interface, library.DEFAULT_CODE, 0)

local serial = io.open(serial_path, "w")
local new_code = 77
serial:write(tostring(new_code) .. "\n")
serial:flush()
serial:close()
helpers.sleep(0.5)

fake_device.digital_write(library.BUTTON_PIN, 0)
helpers.sleep(0.1)
library.assert_falsy(fake_device.digital_read(library.BUTTON_PIN),
                     "push the button")
library.assert_truthy(fake_device.digital_read(LED_PIN),
                      "high led matches low button")
check_next(uinput_interface, new_code, 1)

fake_device.digital_write(library.BUTTON_PIN, 1)
helpers.sleep(0.2)
library.assert_truthy(fake_device.digital_read(library.BUTTON_PIN),
                      "stop pushing")
library.assert_falsy(fake_device.digital_read(LED_PIN),
                     "low led matches high button")
check_next(uinput_interface, new_code, 0)

fake_device.stop()
helpers.sleep(0.5)

print("DONE")
