local luassert = require("luassert")
-- it was too hard to get everything working at once
-- so I needed to test the arduino program on its own first
-- well not so much the arduino program as the fake framework
-- I mean the sketch worked right away

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
set_key_and_try_out("7", 88)
set_key_and_try_out("7x\n", 77)
set_key_and_try_out("adsx\n", 77) -- no change

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
