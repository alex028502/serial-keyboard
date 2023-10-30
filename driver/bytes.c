#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>

extern int call_ioctl(int fd, unsigned long request, ...);

int main(int argc, char* argv[]) {
  int fd = open(argv[1], O_RDONLY);
  int bytes_available;

  call_ioctl(fd, FIONREAD, &bytes_available);

  printf("%d\n", bytes_available);

  return 0;
}
