local luassert = require("luassert")
-- it was too hard to get everything working at once
-- so I needed to test the arduino program on its own first
-- well not so much the arduino program as the fake framework
-- I mean the sketch worked right away

local sut_path, firmware_lib_path, serial_path, serial_interface_path =
   table.unpack(arg)

fake_device_lib, fake_device_lib_err = package.loadlib(sut_path, "luaopen_sut")
luassert.is.falsy(fake_device_lib_err)
fake_device = fake_device_lib()

print("firmware specific testing library", firmware_lib_path)
firmware_test_lib = dofile(firmware_lib_path)
DEFAULT_CODE = firmware_test_lib.DEFAULT_CODE

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

local function try_out(code)
   firmware_test_lib.push_button(fake_device)
   fake_device.sleep(1)
   luassert.is.truthy(firmware_test_lib.get_led(fake_device))
   assert_message(serial, "D", code)

   firmware_test_lib.release_button(fake_device)
   fake_device.sleep(0.2)
   luassert.is.falsy(firmware_test_lib.get_led(fake_device))
   assert_message(serial, "U", code)
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

set_key_and_try_out("88\n", 88)
set_key_and_try_out("2", 88) -- no change

-- The following tests are kind of backwards - or sideways even
-- I created these tests when the branch coverage report showed me that I had a
-- bunch ifs/ands/buts in the fake implementation that were not used, and don't
-- do what the avr implementation does anyhow.
--
-- The sketch itself uses Serial.parseInt() and accepts whatever nuances come
-- along with that.  I tried out all these edge cases on the real device though
-- and wrote the mock function to behave the same way. If I even decided I
-- wanted my device to behave different from the following, I could change a few
-- of these assertions, and change the sketch maybe to match the new assertions,
-- except for two problems:
-- - We would no longer have any tests to make sure that MockSerial behaves like
-- it does on AVR
-- - The MockSerial implementation still still limited to what was visible with
-- my previous implementation, so still might need to be updated
--
-- Ideally, the test framework would be its own project, and it would be
-- verified against a lot of different sketches and use cases. (either with
-- automated tests, or by being used in a lot of projects where different people
-- complain if something isn't right - I don't know who makes sure that the
-- cores behave the same, or even behave at all - but this could be similar)
-- Then this project, the button device would only need enough tests to cover a
-- the cases that we are interested in

set_key_and_try_out("20x", 88) -- no change
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

saved_value = 99 -- sys rq
set_key_and_try_out(tostring(saved_value) .. "\n", saved_value)

fake_device.stop()
fake_device.sleep(0.3)

-- now show that it saves in eeprom
fake_device.start()
fake_device.sleep(0.2)
try_out(saved_value)

-- but look it doesn't check eeprom every time
fake_device.clear_eeprom()
try_out(saved_value)

-- but between clearing above and restarting now
-- it will act like it was reflashed
fake_device.stop()
fake_device.sleep(0.3)
fake_device.start()
fake_device.sleep(0.2)

try_out(DEFAULT_CODE)

fake_device.stop()
fake_device.sleep(0.3)

print("success")
