#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

int key_sysrq();
int key_insert();

static int l_key_sysrq(lua_State* L) {
  lua_pushinteger(L, key_sysrq());
  return 1;
}

static int l_key_insert(lua_State* L) {
  lua_pushinteger(L, key_insert());
  return 1;
}

static const struct luaL_Reg functions[] = {{"key_sysrq", l_key_sysrq},
                                            {"key_insert", l_key_insert},
                                            {NULL, NULL}};

int luaopen_tools(lua_State* L) __attribute__((used));

int luaopen_tools(lua_State* L) {
  luaL_newlib(L, functions);
  return 1;
}
