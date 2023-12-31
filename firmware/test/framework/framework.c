#include <lauxlib.h>  // for luaL_checkinteger, luaL_newlib, etc.
#include <lua.h>      // for lua_State
#include <lualib.h>   // if needed, for additional lua functionalities
#include <pthread.h>  // for pthread_t, pthread_create
#include <unistd.h>   // usleep
#include "eeprom.h"
#include "gpio.h"

extern void setup();
extern void loop();
extern void Serial_init(int fd);
extern unsigned long Serial_baud();

static char running;

static void* run_loop(void* arg) {
  setup();
  while (running) {
    loop();
  }
  return NULL;
}

static int l_start(lua_State* L) {
  pthread_t thread;
  running = 1;
  pthread_create(&thread, NULL, run_loop, NULL);
  return 0;
}

static int l_stop(lua_State* L) {
  running = 0;
  return 0;
}

static int l_digitalRead(lua_State* L) {
  uint8_t pin = luaL_checkinteger(L, 1);
  lua_pushboolean(L, digitalRead(pin));
  return 1;
}

static int l_digitalWrite(lua_State* L) {
  uint8_t pin = luaL_checkinteger(L, 1);
  uint8_t value = luaL_checkinteger(L, 2);
  digitalWrite(pin, value);
  return 0;
}

static int l_Serial_init(lua_State* L) {
  luaL_Stream* stream = luaL_checkudata(L, 1, LUA_FILEHANDLE);
  FILE* fp = stream->f;
  int fd = fileno(fp);
  Serial_init(fd);
  return 0;
}

static int l_Serial_baud(lua_State* L) {
  unsigned long baud_rate = Serial_baud();
  lua_pushinteger(L, baud_rate);
  return 1;
}

static int l_clear_EEPROM(lua_State* L) {
  EEPROM_Clear();
  return 0;
}

static int l_led_builtin(lua_State* L) {
  lua_pushinteger(L, LED_BUILTIN);
  return 1;
}

static int l_sleep(lua_State* L) {
  float ms = luaL_checknumber(L, 1);
  usleep(ms * 1000);
  return 0;
}

static const struct luaL_Reg framework_functions[] = {
    {"digital_read", l_digitalRead},
    {"digital_write", l_digitalWrite},
    {"serial_init", l_Serial_init},
    {"serial_baud", l_Serial_baud},
    {"start", l_start},
    {"stop", l_stop},
    {"clear_eeprom", l_clear_EEPROM},
    {"led_builtin", l_led_builtin},
    {"sleep", l_sleep},
    {NULL, NULL}};

int luaopen_sut(lua_State* L) __attribute__((used));

int luaopen_sut(lua_State* L) {
  luaL_newlib(L, framework_functions);
  return 1;
}

// this might not be the best place for this
void delay(float t) {
  usleep(t * 1000);
}
