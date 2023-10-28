#include "serial.h"
#include <ctype.h>
#include <stdio.h>  // for sprintf
#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>  // for write
#include <cstring>   // for strlen

void SerialMock::init(int fd) {
  this->fd = fd;
}

void SerialMock::begin(unsigned long baud) {
  this->baud = baud;
}

void SerialMock::print(const char* message) {
  ::write(fd, message, std::strlen(message));
}

void SerialMock::print(int value) {
  char buffer[32];
  sprintf(buffer, "%d", value);
  ::write(fd, buffer, std::strlen(buffer));
}

void SerialMock::write(char value) {
  ::write(fd, &value, 1);
}

int SerialMock::available() {
  int bytes_available;
  ioctl(fd, FIONREAD, &bytes_available);
  return bytes_available;
}

int SerialMock::parseInt() {
  char buffer[32] = {0};
  char c;
  int index = 0;

  while (index < sizeof(buffer) - 1) {
    ssize_t n = read(fd, &c, 1);
    if (n <= 0 || !isdigit(c)) {
      break;
    }
    buffer[index++] = c;
  }

  return atoi(buffer);
}

SerialMock Serial;

extern "C" void Serial_init(int fd) {
  Serial.init(fd);
}

extern "C" unsigned long Serial_baud() {
  return Serial.baud;
}
