#include <stdarg.h>
#include <sys/ioctl.h>

int call_ioctl(int fd, unsigned long request, ...) {
  va_list args;
  va_start(args, request);
  void* arg = va_arg(args, void*);
  int ret = ioctl(fd, request, arg);
  va_end(args);
  return ret;
}
