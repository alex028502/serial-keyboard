assert(#arg == 1, "one argument")

local filename = arg[1]
local file = io.open(filename, "rb")
assert(file, "trying to open " .. filename)
local content = file:read("*all")
file:close()

if content:sub(-1) ~= "\n" then
   line_no = 0
   local line_no_inc = 0
   for i = 1, #content do
      local c = content:sub(i, i)
      -- this is only because of an if/else rule that I had to add because the
      -- luacov doesn't check if every if has gone both ways
      if c == "\n" then
         line_no_inc = 1
      else
         line_no_inc = 0
      end
      line_no = line_no + line_no_inc
   end
   print(filename .. ":" .. line_no .. ":1 does not end with a newline.")
   os.exit(1)
else
   os.exit(0)
end
