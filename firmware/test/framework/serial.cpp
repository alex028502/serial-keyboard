#include "serial.h"
#include <ctype.h>
#include <stdio.h>  // for sprintf
#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>  // for write
#include <cstring>   // for strlen

void SerialMock::init(int fd) {
  this->fd = fd;
  incoming_number[0] = 0;
  incoming_number_idx = 0;
  outgoing_number = 0;
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
  /*
    This method is implemented to act just like the real method in a few
    limited cases. I considered using Stream.cpp which seems to be the same
    for all the cores I looked at, but I decided to just make it pass a bunch
    of tests that I wrote by looking at how the real device behaved.

    What would be really cool is writing tests that could be run against this
    library, and a real device (or VM) and then _triangulating_ this
    implementation against the real thing. Then people who had their own
    projects could confidently use this mock library knowing that we have done
    the work of comparing it to a real device.
   */
  while (available()) {
    char c;
    ssize_t n = read(fd, &c, 1);

    if (!isdigit(c)) {
      incoming_number_idx = 0;
    }
    if (c == '-') {
      incoming_number_idx--;  // secret code for negative
    }
    if (isdigit(c)) {
      if (incoming_number_idx < 0) {
        incoming_number[0] = '-';
        incoming_number_idx = 1;
      }
      incoming_number[incoming_number_idx++] = c;
      incoming_number[incoming_number_idx] = 0;
    }
    if (c == '\n') {
      outgoing_number = atoi(incoming_number);
    }
  }

  int result = outgoing_number;
  outgoing_number = 0;
  return result;
}

SerialMock Serial;

extern "C" void Serial_init(int fd) {
  Serial.init(fd);
}

extern "C" unsigned long Serial_baud() {
  return Serial.baud;
}
