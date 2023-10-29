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

  int arg;
  while (1) {
    arg = va_arg(args, int);
    if (arg == 0) {
      break;
    }
    dprintf(fd, " %d", arg);
  }
  dprintf(fd, "\n");

  va_end(args);

  return 0;
}
