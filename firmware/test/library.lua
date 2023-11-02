local BUTTON_PIN = 2

local function set_button_state(fake_device, state)
   fake_device.digital_write(BUTTON_PIN, state)
end

local function push_button(fake_device)
   set_button_state(fake_device, 0)
end

local function release_button(fake_device)
   set_button_state(fake_device, 1)
end

local function get_led(fake_device)
   return fake_device.digital_read(fake_device.led_builtin())
end

return {
   push_button = push_button,
   release_button = release_button,
   get_led = get_led,
   BUTTON_PIN = BUTTON_PIN,
   DEFAULT_CODE = 53,
}
