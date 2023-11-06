#include <lauxlib.h>
#include <linux/uinput.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int call_ioctl(int fd, unsigned long request, ...);

// read the following to know what all this means
// https://www.kernel.org/doc/html/v4.12/input/uinput.html

// https://github.com/LuaJIT/LuaJIT/issues/262#issuecomment-269938853
static int l_setup_device(lua_State* L) {
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  int fd = fileno(fp);

  if (call_ioctl(fd, UI_SET_EVBIT, EV_KEY) < 0) {
    lua_pushinteger(L, -2);
    return 1;
  }

  for (int keycode = KEY_ESC; keycode <= KEY_MICMUTE; ++keycode) {
    if (call_ioctl(fd, UI_SET_KEYBIT, keycode) < 0) {
      lua_pushinteger(L, -3);
      return 1;
    }
  }

  struct uinput_user_dev uinp;
  memset(&uinp, 0, sizeof(uinp));
  strncpy(uinp.name, "Example device", UINPUT_MAX_NAME_SIZE);
  uinp.id.version = 4;
  uinp.id.bustype = BUS_USB;
  uinp.id.vendor = 0x1234;
  uinp.id.product = 0x5678;

  if (call_ioctl(fd, UI_DEV_SETUP, &uinp) < 0) {
    lua_pushinteger(L, -4);
    return 1;
  }

  if (call_ioctl(fd, UI_DEV_CREATE, 0) < 0) {
    lua_pushinteger(L, -25);
    return 1;
  }

  lua_pushinteger(L, 0);
  return 1;
}

static int l_get_key_event(lua_State* L) {
  struct input_event ev;
  memset(&ev, 0, sizeof(ev));
  ev.type = EV_KEY;
  ev.code = luaL_checkinteger(L, 1);
  ev.value = luaL_checkinteger(L, 2);
  ev.time.tv_sec = 0;
  ev.time.tv_usec = 0;
  lua_pushlstring(L, (char*)&ev, sizeof(ev));
  return 1;
}

static int l_get_syn_event(lua_State* L) {
  struct input_event ev;
  memset(&ev, 0, sizeof(ev));
  ev.type = EV_SYN;
  ev.code = SYN_REPORT;
  ev.value = 0;
  ev.time.tv_sec = 0;
  ev.time.tv_usec = 0;
  lua_pushlstring(L, (char*)&ev, sizeof(ev));
  return 1;
}

static int l_sleep(lua_State* L) {
  int msec = luaL_checkinteger(L, 1);
  usleep(msec * 1000);
  return 0;
}

static int l_destroy(lua_State* L) {
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  int fd = fileno(fp);
  call_ioctl(fd, UI_DEV_DESTROY);
}

static const luaL_Reg lib_functions[] = {{"destroy", l_destroy},
                                         {"sleep", l_sleep},
                                         {"get_key_event", l_get_key_event},
                                         {"get_syn_event", l_get_syn_event},
                                         {"setup_device", l_setup_device},
                                         {NULL, NULL}};

int luaopen_serial_keyboard_lib(lua_State* L) {
  luaL_newlib(L, lib_functions);
  return 1;
}
