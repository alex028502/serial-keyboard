local function assert_in(a, b, message)
   m = "assert_in"
   assert(string.find(b, a, 0, true) ~= nil, m .. ": " .. a .. " not in\n" .. b)
end

local function import(path, fn)
   lib, err = package.loadlib(path, fn)
   assert(not err, err)
   return lib()
end

return {
   assert_in = assert_in,
   import = import,
}
