#include <linux/uinput.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>  // For getenv

int call_ioctl(int fd, unsigned long request, ...) {
  char* env_value = getenv("IOCTL_ERROR");

  if (env_value != NULL && request == strtoul(env_value, NULL, 0)) {
    return -1;
  }

  dprintf(fd, "IOCTL: %lu", request);

  va_list args;
  va_start(args, request);

  if (request == UI_DEV_SETUP) {
    dprintf(fd, " [DATA]");
  }

  int arg;
  if (request == UI_SET_KEYBIT || request == UI_SET_EVBIT) {
    arg = va_arg(args, int);
    dprintf(fd, " %d", arg);
  }
  dprintf(fd, "\n");

  va_end(args);

  return 0;
}
