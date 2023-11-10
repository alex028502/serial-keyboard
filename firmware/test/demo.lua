local luassert = require("luassert")
local sut_path, serial_path, serial_interface_path = table.unpack(arg)

fake_device_lib, fake_device_lib_err = package.loadlib(sut_path, "luaopen_sut")
luassert.is.falsy(fake_device_lib_err)
fake_device = fake_device_lib()

BUTTON_PIN = 2
DEFAULT_CODE = "unavailable"

function assert_message(f, number)
   local message = f:read("L")
   luassert.is.truthy(message, "something written")
   luassert.are.equals(tostring(number) .. "\n", message)
end

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

try_out(DEFAULT_CODE)
assert_message(serial, 0)

local function set_key(setting)
   serial:write(setting)
   serial:flush()
   fake_device.sleep(2)
end

local function set_key_and_try_out(setting, new_code)
   -- assert that we are not using this for the special cases:
   luassert.are_not.equals(new_code, DEFAULT_CODE)
   luassert.are_not.equals(new_code, 0)

   set_key(setting)
   try_out(new_code)
   try_out(0) -- always sends a 0 for the \n
   try_out(DEFAULT_CODE) -- now it unavailable
   assert_message(serial, 0)
end

-- these have all been tried out with a real device running this sketch
set_key_and_try_out("88\n", 88)
set_key("2")
try_out(DEFAULT_CODE) -- no return
assert_message(serial, 0)
set_key("20x")
try_out(DEFAULT_CODE) -- no return
assert_message(serial, 0)
set_key_and_try_out("x\n", 220) -- finally sinks in
set_key_and_try_out("x52\n", 52)
set_key_and_try_out("77x\n", 77)
set_key("adsx\n")
try_out(0)
try_out(DEFAULT_CODE)
assert_message(serial, 0)
set_key("11x12\n")
try_out(11)
try_out(12)
try_out(0)
try_out(DEFAULT_CODE)
assert_message(serial, 0)
set_key_and_try_out("-3\n", -3)
set_key("11-12\n")
try_out(11)
try_out(-12)
try_out(0)
try_out(DEFAULT_CODE)
assert_message(serial, 0)
set_key("11-\n")
try_out(11)
try_out(0) -- I guess the '-' on its own is like 0
try_out(0)
try_out(DEFAULT_CODE)
assert_message(serial, 0)
set_key_and_try_out("88\n", 88) -- minus doesn't carry over
set_key_and_try_out("50000\n", -15536)
set_key("44x55x21\n")
set_key("22x34\n")
try_out(44)
try_out(55)
try_out(21)
try_out(22)
try_out(34)
try_out(0)
try_out(DEFAULT_CODE)
assert_message(serial, 0)
try_out(DEFAULT_CODE)
assert_message(serial, 0)

fake_device.stop()
fake_device.sleep(0.3)

print("success")
