local library_path, helper_path, name = table.unpack(arg)

library = dofile(library_path)
helpers = library.import(helper_path, "luaopen_helpers")

print(helpers.get_constants()[name])
