local library_path, helper_path = table.unpack(arg)

library = dofile(library_path)
helpers = library.import(helper_path, "luaopen_helpers")

function try_read_key_event(event)
   return pcall(function()
      return helpers.read_key_event(event)
   end)
end

function test_string(n)
   return string.rep(string.char(88), helpers.event_size() + n)
end

-- only checking this to prove the test works at all
library.assert_truthy(try_read_key_event(test_string(0)), "base case")

-- this is what needs to be tested
library.assert_falsy(try_read_key_event(test_string(-1)), "too small")
library.assert_falsy(try_read_key_event(test_string(1)), "too big")
