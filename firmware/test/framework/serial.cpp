#include "serial.h"
#include <ctype.h>
#include <pty.h>    // for openpty
#include <stdio.h>  // for sprintf
#include <stdlib.h>
#include <sys/ioctl.h>
#include <termios.h>  // for termios structure
#include <unistd.h>   // for write
#include <cstring>    // for strlen

int SerialMock::init() {
  struct termios termios_attr;
  int tty;
  if (openpty(&this->fd, &tty, nullptr, &termios_attr, nullptr) == -1) {
    perror("Failed to create PTY pair");
    exit(EXIT_FAILURE);
  }

  // Modify termios_attr to disable certain flags
  termios_attr.c_iflag &= ~(IGNCR | ICRNL | INLCR);
  termios_attr.c_oflag &= ~OPOST;

  // Apply the modified termios settings
  tcsetattr(this->fd, TCSANOW, &termios_attr);
  tcsetattr(tty, TCSANOW, &termios_attr);

  return tty;
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

extern "C" int Serial_init() {
  return Serial.init();
}

extern "C" unsigned long Serial_baud() {
  return Serial.baud;
}
