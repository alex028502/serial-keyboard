#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int key_sysrq();

static int l_key_sysrq(lua_State* L) {
    lua_pushnumber(L, key_sysrq());
    return 1;
}

static const struct luaL_Reg functions[] = {
    {"key_sysrq", l_key_sysrq},
    {NULL, NULL}};

int luaopen_tools(lua_State* L) __attribute__((used));

int luaopen_tools(lua_State* L) {
    luaL_newlib(L, functions);
    return 1;
}
