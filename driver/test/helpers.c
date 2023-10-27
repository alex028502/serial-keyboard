#include <lauxlib.h>
#include <linux/uinput.h>
#include <lua.h>
#include <lualib.h>
#include <string.h>
#include <unistd.h>

static int l_read_key_event(lua_State* L) {
  size_t len;
  const char* data = luaL_checklstring(L, 1, &len);

  if (len < sizeof(struct input_event)) {
    return luaL_error(L, "Insufficient data");
  }

  struct input_event* ev = (struct input_event*)data;

  lua_pushinteger(L, ev->type);
  lua_pushinteger(L, ev->code);
  lua_pushinteger(L, ev->value);

  return 3;
}

static int l_event_size(lua_State* L) {
  lua_pushinteger(L, sizeof(struct input_event));
  return 1;
}

static int l_split_events(lua_State* L) {
  size_t len;
  const char* data = luaL_checklstring(L, 1, &len);
  int event_count = len / sizeof(struct input_event);
  int i;

  for (i = 0; i < event_count; ++i) {
    const char* event_data = data + i * sizeof(struct input_event);
    lua_pushlstring(L, event_data, sizeof(struct input_event));
  }

  return event_count;
}

static int l_sleep(lua_State* L) {
  float ms = luaL_checknumber(L, 1);
  usleep(ms * 1000);
  return 0;
}

static int l_get_constants(lua_State* L) {
  lua_newtable(L);

  lua_pushstring(L, "UI_SET_EVBIT");
  lua_pushinteger(L, UI_SET_EVBIT);
  lua_settable(L, -3);

  lua_pushstring(L, "EV_KEY");
  lua_pushinteger(L, EV_KEY);
  lua_settable(L, -3);

  lua_pushstring(L, "KEY_ESC");
  lua_pushinteger(L, KEY_ESC);
  lua_settable(L, -3);

  lua_pushstring(L, "KEY_MICMUTE");
  lua_pushinteger(L, KEY_MICMUTE);
  lua_settable(L, -3);

  lua_pushstring(L, "UI_SET_KEYBIT");
  lua_pushinteger(L, UI_SET_KEYBIT);
  lua_settable(L, -3);

  lua_pushstring(L, "UI_DEV_CREATE");
  lua_pushinteger(L, UI_DEV_CREATE);
  lua_settable(L, -3);

  lua_pushstring(L, "UI_DEV_SETUP");
  lua_pushinteger(L, UI_DEV_SETUP);
  lua_settable(L, -3);

  lua_pushstring(L, "UI_DEV_DESTROY");
  lua_pushinteger(L, UI_DEV_DESTROY);
  lua_settable(L, -3);

  lua_pushstring(L, "EV_SYN");
  lua_pushinteger(L, EV_SYN);
  lua_settable(L, -3);

  lua_pushstring(L, "SYN_REPORT");
  lua_pushinteger(L, SYN_REPORT);
  lua_settable(L, -3);

  return 1;
}

static const luaL_Reg helperlib[] = {
    {"read_key_event", l_read_key_event}, {"split_events", l_split_events},
    {"get_constants", l_get_constants},   {"sleep", l_sleep},
    {"event_size", l_event_size},         {NULL, NULL}};

int luaopen_helpers(lua_State* L) {
  luaL_newlib(L, helperlib);
  return 1;
}
