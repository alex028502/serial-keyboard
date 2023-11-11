local luassert = require("luassert")
-- it was too hard to get everything working at once
-- so I needed to test the arduino program on its own first
-- well not so much the arduino program as the fake framework
-- I mean the sketch worked right away

REASONABLE_DELAY = 40

local sut_path, firmware_lib_path, serial_path, serial_interface_path =
   table.unpack(arg)

local function open_lib(path, name)
   local lib, err = package.loadlib(path, name)
   luassert.is.falsy(err)
   return lib()
end

fake_device = open_lib(sut_path, "luaopen_sut")

test_tools = open_lib(sut_path, "luaopen_tools")

print("firmware specific testing library", firmware_lib_path)
firmware_test_lib = dofile(firmware_lib_path)
DEFAULT_CODE = test_tools.key_sysrq()
SECOND_CODE = test_tools.key_insert() -- really second default code

function assert_message(f, code, key)
   local message = f:read("L")
   luassert.is.truthy(message, "something written")
   luassert.are.equals(code .. tostring(key) .. "\n", message)
end

luassert.is.truthy(DEFAULT_CODE, "make sure it's loaded")

LED_PIN = fake_device.led_builtin()
print("led pin is " .. LED_PIN)

local serial = io.open(serial_path, "r+")
local serial_interface = io.open(serial_interface_path, "r+")
luassert.is.truthy(serial, "serial port that connects to computer")
luassert.is.truthy(serial_interface, "serial port to control simulation")

fake_device.serial_init(serial_interface)
fake_device.clear_eeprom()
luassert.are.equals(fake_device.serial_baud(), 0)
fake_device.start()
fake_device.sleep(0.2)
luassert.is.falsy(firmware_test_lib.get_led(fake_device))
local baud_rate = fake_device.serial_baud()
assert(baud_rate > 0, baud_rate) -- the e2e tests make sure this matches

local function try_out(code, secondary)
   firmware_test_lib.push_button(fake_device, secondary)
   fake_device.sleep(1)
   luassert.is.truthy(firmware_test_lib.get_led(fake_device))
   assert_message(serial, "D", code)
   fake_device.sleep(REASONABLE_DELAY) -- just longer than the debounce amount

   firmware_test_lib.release_button(fake_device, secondary)
   fake_device.sleep(0.2)
   luassert.is.falsy(firmware_test_lib.get_led(fake_device))
   assert_message(serial, "U", code)
   fake_device.sleep(REASONABLE_DELAY)
end

print("~default test~")

-- now again using the shortcut
try_out(DEFAULT_CODE)

-- now the other button
try_out(SECOND_CODE, true)

local function set_key(setting)
   serial:write(setting)
   serial:flush()
   fake_device.sleep(2)
end

local function set_key_and_try_out(setting, new_code)
   set_key(setting)
   try_out(new_code)
end

print("~setting test~")

set_key_and_try_out("88\n", 88)
set_key_and_try_out("7", 88)
set_key_and_try_out("7x\n", 77)
set_key_and_try_out("adsx\n", 77) -- no change

saved_value = 99 -- sys rq
set_key_and_try_out(tostring(saved_value) .. "\n", saved_value)

-- use negative to set the second button
-- (this won't really scale to more buttons)
-- (maybe to four buttons with complex numbers)
local new_second_code = 27
set_key(tostring(-new_second_code) .. "\n")
-- let's first make sure the device is still running
try_out(saved_value)
-- ok now let's see if our new code is set:
try_out(new_second_code, true)

print("~save setting test~")

fake_device.stop()
fake_device.sleep(0.3)

-- now show that it saves in eeprom
fake_device.start()
fake_device.sleep(0.2)
try_out(saved_value)

try_out(new_second_code, true)

-- but look it doesn't check eeprom every time
fake_device.clear_eeprom()
try_out(saved_value)

print("~clear setting test~")

-- but between clearing above and restarting now
-- it will act like it was reflashed
fake_device.stop()
fake_device.sleep(0.3)
fake_device.start()
fake_device.sleep(0.2)

try_out(DEFAULT_CODE)
try_out(SECOND_CODE, true)

print("~same time test~")
-- ok now test one more thing
-- this won't be that common but need to make sure
firmware_test_lib.push_button(fake_device)
fake_device.sleep(1)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
assert_message(serial, "D", DEFAULT_CODE)
fake_device.sleep(REASONABLE_DELAY)

firmware_test_lib.push_button(fake_device, true)
fake_device.sleep(1)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
assert_message(serial, "D", SECOND_CODE)
fake_device.sleep(REASONABLE_DELAY)

firmware_test_lib.release_button(fake_device)
fake_device.sleep(0.2)
-- LED stays on as long as one button is pressed
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
assert_message(serial, "U", DEFAULT_CODE)
fake_device.sleep(REASONABLE_DELAY)

firmware_test_lib.release_button(fake_device, true)
fake_device.sleep(0.2)
luassert.is.falsy(firmware_test_lib.get_led(fake_device))
assert_message(serial, "U", SECOND_CODE)
fake_device.sleep(REASONABLE_DELAY)

print("~bounce test~")
-- now test debouncing
-- the main problems seems to be with the big button model on the way down
-- the solution should work for down and up but I'll just test down
local function bounce_down(secondary)
   firmware_test_lib.push_button(fake_device, secondary)
   fake_device.sleep(1)
   firmware_test_lib.release_button(fake_device, secondary)
   fake_device.sleep(1)
   firmware_test_lib.push_button(fake_device, secondary)
   fake_device.sleep(1)
end

bounce_down()
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
fake_device.sleep(REASONABLE_DELAY)
firmware_test_lib.release_button(fake_device)
fake_device.sleep(REASONABLE_DELAY)
luassert.is.falsy(firmware_test_lib.get_led(fake_device))

bounce_down(true)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
fake_device.sleep(REASONABLE_DELAY)
firmware_test_lib.release_button(fake_device, true)
fake_device.sleep(REASONABLE_DELAY)
luassert.is.falsy(firmware_test_lib.get_led(fake_device))

assert_message(serial, "D", DEFAULT_CODE)
assert_message(serial, "U", DEFAULT_CODE)
assert_message(serial, "D", SECOND_CODE)
assert_message(serial, "U", SECOND_CODE)

print("~quick same time test~")
-- we shouold still hold the buttons down for the whole delay
-- or it might not register the second one
-- I don't actually have any plans to use this feature so I might never know
-- if it actually works well enough
-- like if I made one key shift and the other a letter I could try it out
-- actually I just tried it with shift and a letter and it's good enough
firmware_test_lib.push_button(fake_device)
fake_device.sleep(1)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
-- other button at pretty much the same time:
firmware_test_lib.push_button(fake_device, true)
fake_device.sleep(1)
-- hold them down for a sec:
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
fake_device.sleep(REASONABLE_DELAY)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
-- release them both:
firmware_test_lib.release_button(fake_device)
fake_device.sleep(0.2)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
firmware_test_lib.release_button(fake_device, true)
fake_device.sleep(0.2)
luassert.is.truthy(firmware_test_lib.get_led(fake_device))
luassert.is.truthy(firmware_test_lib.get_led(fake_device)) -- don't mind
fake_device.sleep(REASONABLE_DELAY)
luassert.is.falsy(firmware_test_lib.get_led(fake_device))

assert_message(serial, "D", DEFAULT_CODE)
assert_message(serial, "D", SECOND_CODE)
assert_message(serial, "U", DEFAULT_CODE)
assert_message(serial, "U", SECOND_CODE)

-- loop is still stuck from the last action
fake_device.sleep(REASONABLE_DELAY)

print("~check for end~")
-- this pattern should make sure that that the reading and writing sides of
-- the test are in sync
try_out(DEFAULT_CODE)
try_out(SECOND_CODE, true)
try_out(SECOND_CODE, true)
try_out(SECOND_CODE, true)
try_out(DEFAULT_CODE)

print("~shut down~")
fake_device.stop()
fake_device.sleep(0.3)

print("success")
