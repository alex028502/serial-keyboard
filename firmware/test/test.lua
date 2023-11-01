print("path: " .. package.path)
print("cpath: " .. package.cpath)

-- it was too hard to get everything working at once
-- so I needed to test the arduino program on its own first
-- well not so much the arduino program as the fake framework
-- I mean the sketch worked right away

local sut_path, library_path, serial_path, serial_interface_path, baud =
   table.unpack(arg)

library = dofile(library_path)
print("fake device path", sut_path)
fake_device = library.import(sut_path, "luaopen_sut")
helpers = fake_device -- TODO: inline

function assert_message(f, code, key)
   local message = f:read("L")
   library.assert_truthy(message, "something written")
   library.assert_equal(code .. tostring(key) .. "\n", message)
end

library.assert_truthy(library.BUTTON_PIN, "make sure it's loaded")

LED_PIN = fake_device.led_builtin()
print("led pin is " .. LED_PIN)

local serial = io.open(serial_path, "r+")
local serial_interface = io.open(serial_interface_path, "r+")
library.assert_truthy(serial, "serial port that connects to computer")
library.assert_truthy(serial_interface, "serial port to control simulation")

fake_device.serial_init(serial_interface)
fake_device.clear_eeprom()
library.assert_equal(fake_device.serial_baud(), 0)
fake_device.start()
fake_device.sleep(0.2)
library.assert_truthy(
   fake_device.digital_read(library.BUTTON_PIN),
   "high means button not pressed"
)
library.assert_falsy(
   fake_device.digital_read(LED_PIN),
   "low led matches high button"
)

baud_rate = tonumber(baud)
assert(baud_rate, baud)
assert(baud_rate > 0, baud)
library.assert_equal(fake_device.serial_baud(), baud_rate)

local function try_out(code)
   fake_device.digital_write(library.BUTTON_PIN, 0)
   helpers.sleep(1)
   library.assert_falsy(
      fake_device.digital_read(library.BUTTON_PIN),
      "push the button"
   )
   library.assert_truthy(
      fake_device.digital_read(LED_PIN),
      "high led matches low button"
   )
   assert_message(serial, "D", code)

   fake_device.digital_write(library.BUTTON_PIN, 1)
   helpers.sleep(0.2)
   library.assert_truthy(
      fake_device.digital_read(library.BUTTON_PIN),
      "stop pushing"
   )
   library.assert_falsy(
      fake_device.digital_read(LED_PIN),
      "low led matches high button"
   )
   assert_message(serial, "U", code)
end

try_out(library.DEFAULT_CODE)

local function set_key(setting)
   serial:write(setting)
   serial:flush()
   helpers.sleep(2)
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
helpers.sleep(0.3)

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
helpers.sleep(0.3)
fake_device.start()
fake_device.sleep(0.2)

try_out(library.DEFAULT_CODE)

fake_device.stop()
helpers.sleep(0.3)

print("success")
