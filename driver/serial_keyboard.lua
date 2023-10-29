local lib_path = arg[1]
local input_device_path = arg[2]
local uinput_device_path = arg[3]

local lib_table, lib_error =
   package.loadlib(lib_path, "luaopen_serial_keyboard_lib")
assert(not lib_error, lib_error)
lib = lib_table()

local syn_byte_str = lib.get_syn_event()

lib.make_ctrl_c_work() -- first things first

local function pass()
   -- do nothing
end

local function send_event(f, action, code)
   local byte_str = lib.get_key_event(code, action)
   f:write(byte_str)
   f:write(syn_byte_str)
   f:flush()
end

function debug_message(message)
   if os.getenv("SERIAL_KEYBOARD_DEBUG") then
      print(message)
   else
      pass()
   end
end

-- /usr/include/linux/input.h

print("will listen for events from" .. input_device_path)
print("and pass them on to " .. uinput_device_path)

print("driver will open" .. uinput_device_path .. " for writing")
local uinput_file = io.open(uinput_device_path, "wb")
print("driver has opened " .. uinput_device_path .. " for writing")

if uinput_file == nil then
   error("Failed to open /dev/uinput.")
else
   pass()
end

local device_setup_result = lib.setup_device(uinput_file)
if device_setup_result ~= 0 then
   error("Failed to set up uinput device. " .. device_setup_result)
else
   pass()
end

print("driver has set up uinput device")

if lib.exit_trap(uinput_file) ~= 0 then
   error("Failed to set up exit trap")
else
   pass()
end

print("driver has set up exit trap")

local file = io.open(input_device_path, "rb")

print("driver has opened " .. input_device_path .. " for reading")

for line in file:lines() do
   if line then
      debug_message("sending " .. line)
      local action_str, code_str = string.match(line, "(%a)(%d+)")
      local action = (action_str == "D") and 1 or 0
      local keycode = tonumber(code_str)
      if keycode then
         send_event(uinput_file, action, keycode)
      else
         print("error")
      end
   else
      pass()
   end
end

print("cleaning up")
lib.destroy(file)
uinput_file:close()
print("cleaned up")

lib.sleep(1000)
