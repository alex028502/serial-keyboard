local function fmt(a)
   return tostring(a).gsub(a, "\r", "^M")
end

local function assert_equal(a, b, message)
   if message == nil then
      m = "assert_equal"
   else
      m = message
   end
   assert(a == b, m .. "\n" .. fmt(a) .. "vs\n" .. fmt(b))
end

local function assert_in(a, b, message)
   if message == nil then
      m = "assert_in"
   else
      m = message
   end
   assert(string.find(b, a) ~= nil, m .. ": " .. a .. " not in\n" .. b)
end

local function is_falsy(a)
   return a == nil or a == false or a == 0 or a == ""
end

local function assert_falsy(a, message)
   assert(is_falsy(a), message .. ": " .. tostring(a) .. " is not falsy")
end

local function assert_truthy(a, message)
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
   BUTTON_PIN = 2,
   DEFAULT_CODE = 53,
}
