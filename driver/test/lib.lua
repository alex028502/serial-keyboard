local luassert = require("luassert")

local function check_next(helpers, f, code, action)
   local constants = helpers.get_constants()
   local main_event = f:read(helpers.event_size())
   local syn_event = f:read(helpers.event_size())
   luassert.is.truthy(main_event, "something written a least")
   luassert.is.truthy(syn_event, "something written a least")
   local main_type, main_code, main_value = helpers.read_key_event(main_event)
   local syn_type, syn_code, syn_value = helpers.read_key_event(syn_event)
   luassert.are.equals(main_type, constants.EV_KEY)
   luassert.are.equals(main_code, code)
   luassert.are.equals(main_value, action)
   luassert.are.equals(syn_type, constants.EV_SYN)
   luassert.are.equals(syn_code, constants.SYN_REPORT)
   luassert.are.equals(syn_value, 0)
end

return function(helpers)
   return function(...)
      local args = { ... }
      return check_next(helpers, table.unpack(args))
   end
end
