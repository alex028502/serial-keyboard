#include <lauxlib.h>
#include <linux/uinput.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int call_ioctl(int fd, unsigned long request, ...);

static void check_ioctl(lua_State* L,
                        int result,
                        int error_number,
                        int error_param) {
  if (result < 0) {
    luaL_error(L, "FAILURE - SEARCH CODE FOR: %d - NOT: %d", error_number,
               error_param);
  }
}

// read the following to know what all this means
// https://www.kernel.org/doc/html/v4.12/input/uinput.html

// https://github.com/LuaJIT/LuaJIT/issues/262#issuecomment-269938853
static int l_setup_device(lua_State* L) {
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  int fd = fileno(fp);

  check_ioctl(L, call_ioctl(fd, UI_SET_EVBIT, EV_KEY), 1324, 2);

  for (int keycode = KEY_ESC; keycode <= KEY_MICMUTE; ++keycode) {
    int result = call_ioctl(fd, UI_SET_KEYBIT, keycode);
    // TRY TO REMEMBER THIS - USUALLY YOU SEARCH FOR ERROR CODES
    check_ioctl(L, result, 234892, keycode);
  }

  struct uinput_user_dev uinp;
  memset(&uinp, 0, sizeof(uinp));
  strncpy(uinp.name, "Example device", UINPUT_MAX_NAME_SIZE);
  uinp.id.version = 4;
  uinp.id.bustype = BUS_USB;
  uinp.id.vendor = 0x1234;
  uinp.id.product = 0x5678;

  check_ioctl(L, call_ioctl(fd, UI_DEV_SETUP, &uinp), 1325, 2);

  check_ioctl(L, call_ioctl(fd, UI_DEV_CREATE, 0), 1326, 2);

  return 0;
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
