#include <lauxlib.h>
#include <linux/uinput.h>
#include <lua.h>
#include <lualib.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

int call_ioctl(int fd, unsigned long request, ...);

int l_is_device_connected(lua_State* L) {
  int status;
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  int fd = fileno(fp);
  lua_pushinteger(L, ioctl(fd, TIOCMGET, &status) >= 0);
  return 1;
}

// read the following to know what all this means
// https://www.kernel.org/doc/html/v4.12/input/uinput.html

static void cleanup() {
  // actually just let use know when the program exited
  printf("ALL DONE\n");
}

static int l_exit_trap(lua_State* L) {
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  // exit_fd = fileno(fp);
  atexit(cleanup);
  lua_pushinteger(L, 0);
  return 1;
}

void handle_sigint(int sig) {
  printf("Caught signal %d, converting to SIGTERM\n", sig);
  kill(getpid(), SIGTERM);
}

static int l_make_ctrl_c_work(lua_State* L) {
  // cleanup will be skipped
  // only unplugging the device makes it end nicely
  // but that's what will usually happen
  signal(SIGINT, handle_sigint);
  lua_pushinteger(L, 0);
  return 1;
}

// https://github.com/LuaJIT/LuaJIT/issues/262#issuecomment-269938853
static int l_setup_device(lua_State* L) {
  printf("WATCH THIS\n");
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  int fd = fileno(fp);

  if (call_ioctl(fd, UI_SET_EVBIT, EV_KEY, 0) < 0) {
    lua_pushinteger(L, -2);
    return 1;
  }

  for (int keycode = KEY_ESC; keycode <= KEY_MICMUTE; ++keycode) {
    if (call_ioctl(fd, UI_SET_KEYBIT, keycode, 0) < 0) {
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

  if (call_ioctl(fd, UI_DEV_SETUP, &uinp, 0) < 0) {
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
  call_ioctl(fd, UI_DEV_DESTROY, 0);
}

static const luaL_Reg lib_functions[] = {
    {"is_device_connected", l_is_device_connected},
    {"make_ctrl_c_work", l_make_ctrl_c_work},
    {"destroy", l_destroy},
    {"sleep", l_sleep},
    {"exit_trap", l_exit_trap},
    {"get_key_event", l_get_key_event},
    {"get_syn_event", l_get_syn_event},
    {"setup_device", l_setup_device},
    {NULL, NULL}};

int luaopen_serial_keyboard_lib(lua_State* L) {
  luaL_newlib(L, lib_functions);
  return 1;
}
