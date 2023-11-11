extern "C" {
#include <gpio.h>
}

#include <serial.h>

extern "C" void setup() __attribute__((used));
extern "C" void loop() __attribute__((used));

// cheat a bit here I guess
#define abs(x) ((x) < 0 ? -(x) : (x))
