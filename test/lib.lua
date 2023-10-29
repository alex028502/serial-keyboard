local function check_next(library, helpers, f, code, action)
   local constants = helpers.get_constants()
   local main_event = f:read(helpers.event_size())
   local syn_event = f:read(helpers.event_size())
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

return function(library, helpers)
   return function(...)
      local args = { ... }
      return check_next(library, helpers, table.unpack(args))
   end
end
