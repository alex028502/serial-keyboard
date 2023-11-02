local function assert_equal(a, b, message)
   m = "assert_equal"
   assert(a == b, m .. "\n" .. tostring(a) .. "vs\n" .. tostring(b))
end

local function assert_in(a, b, message)
   m = "assert_in"
   assert(string.find(b, a) ~= nil, m .. ": " .. a .. " not in\n" .. b)
end

local function is_falsy(a)
   return a == nil or a == false or a == 0 or a == ""
end

local function assert_falsy(a, m)
   if m then
      message = m
   else
      message = "assert falsy"
   end
   assert(is_falsy(a), message .. ": " .. tostring(a) .. " is not falsy")
end

local function assert_truthy(a, message)
   if m then
      message = m
   else
      message = "assert truthy"
   end
   assert(not is_falsy(a), message .. ": " .. tostring(a) .. " is not truthy")
end

local function import(path, fn)
   lib, err = package.loadlib(path, fn)
   assert(not err, err)
   return lib()
end

return {
   assert_equal = assert_equal,
   assert_in = assert_in,
   assert_falsy = assert_falsy,
   assert_truthy = assert_truthy,
   import = import,
}
