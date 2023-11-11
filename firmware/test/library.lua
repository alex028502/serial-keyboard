local function set_button_state(fake_device, state, secondary)
   if secondary then
      BUTTON_PIN = 5
   else
      BUTTON_PIN = 2
   end
   fake_device.digital_write(BUTTON_PIN, state)
end

local function push_button(fake_device, secondary)
   set_button_state(fake_device, 0, secondary)
end

local function release_button(fake_device, secondary)
   set_button_state(fake_device, 1, secondary)
end

local function get_led(fake_device)
   return fake_device.digital_read(fake_device.led_builtin())
end

return {
   push_button = push_button,
   release_button = release_button,
   get_led = get_led,
}
