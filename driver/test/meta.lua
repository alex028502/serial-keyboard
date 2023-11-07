local library_path, helper_path = table.unpack(arg)

library = dofile(library_path)
helpers = library.import(helper_path, "luaopen_helpers")

function test_string(n)
   return string.rep(string.char(88), helpers.event_size() + n)
end

library.assert_in("Mismatch", helpers.read_key_event(test_string(2)))
library.assert_in("Mismatch", helpers.parse_uinput_user_dev("test"))
