local luassert = require("luassert")
local sut_path, serial_path, serial_interface_path = table.unpack(arg)

fake_device_lib, fake_device_lib_err = package.loadlib(sut_path, "luaopen_sut")
luassert.is.falsy(fake_device_lib_err)
fake_device = fake_device_lib()

DEFAULT_CODE = 53
BUTTON_PIN = 2

function assert_message(f, number)
   local message = f:read("L")
   luassert.is.truthy(message, "something written")
   luassert.are.equals(tostring(number) .. "\n", message)
end

luassert.is.truthy(DEFAULT_CODE, "make sure it's loaded")

LED_PIN = fake_device.led_builtin()
print("led pin is " .. LED_PIN)

local serial = io.open(serial_path, "r+")
local serial_interface = io.open(serial_interface_path, "r+")
luassert.is.truthy(serial, "serial port that connects to computer")
luassert.is.truthy(serial_interface, "serial port to control simulation")

fake_device.serial_init(serial_interface)
luassert.are.equals(fake_device.serial_baud(), 0)
fake_device.start()
fake_device.sleep(0.2)
local baud_rate = fake_device.serial_baud()
assert(baud_rate == 9600, baud_rate) -- this is what is in the demo sketch

local function try_out(number)
   fake_device.digital_write(BUTTON_PIN, 0)
   fake_device.sleep(1)
   fake_device.digital_write(BUTTON_PIN, 1)
   fake_device.sleep(3)
   assert_message(serial, number)
end

-- now again using the shortcut
try_out(DEFAULT_CODE)

local function set_key(setting)
   serial:write(setting)
   serial:flush()
   fake_device.sleep(2)
end

local function set_key_and_try_out(setting, new_code)
   set_key(setting)
   try_out(new_code)
end

-- TODO: confirm with real device
-- these tests were created trying out the real sketch - and then used to
-- sort out the mock library - but then a new test sketch was created, and
-- these tests were created by trying the new sketch with the mock library
-- but now they need to be fixed by trying the new demo sketch with a real
-- device
set_key_and_try_out("88\n", 88)
set_key_and_try_out("2", 0) -- TODO: confirm with real device!
set_key_and_try_out("20x", 0) -- no change
set_key_and_try_out("x\n", 220)
set_key_and_try_out("x52\n", 52)
set_key_and_try_out("77x\n", 77)
set_key_and_try_out("adsx\n", 77) -- no change
set_key_and_try_out("11x12\n", 12)
set_key_and_try_out("-3\n", -3)
set_key_and_try_out("11-12\n", -12)
set_key_and_try_out("11-\n", 11)
set_key_and_try_out("88\n", 88) -- minus doesn't carry over
set_key_and_try_out("50000\n", -15536)

fake_device.stop()
fake_device.sleep(0.3)

print("success")
