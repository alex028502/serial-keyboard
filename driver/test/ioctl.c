#include <linux/uinput.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>  // For getenv
#include <unistd.h>  // For write()

int call_ioctl(int fd, unsigned long request, ...) {
  char* env_value = getenv("IOCTL_ERROR");

  if (env_value != NULL && request == strtoul(env_value, NULL, 0)) {
    return -1;
  }

  dprintf(fd, "IOCTL: %lu", request);

  va_list args;
  va_start(args, request);

  int arg;
  if (request == UI_SET_KEYBIT || request == UI_SET_EVBIT) {
    arg = va_arg(args, int);
    dprintf(fd, " %d", arg);
  }
  dprintf(fd, "\n");

  if (request == UI_DEV_SETUP) {
    struct uinput_user_dev* setup = va_arg(args, struct uinput_user_dev*);
    write(fd, setup, sizeof(struct uinput_user_dev));
  }

  va_end(args);

  return 0;
}
