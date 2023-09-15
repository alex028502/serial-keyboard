assert(#arg == 1, "one argument")

local filename = arg[1]
local file = io.open(filename, "rb")
assert(file, "trying to open " .. filename)
local content = file:read("*all")
file:close()

if content:sub(-1) ~= "\n" then
   line_no = 0
   for i = 1, #content do
      local c = content:sub(i, i)
      if c == "\n" then
         line_no = line_no + 1
      end
   end
   print(filename .. ":" .. line_no .. ":1 does not end with a newline.")
   os.exit(1)
end
