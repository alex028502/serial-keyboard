#include "gpio.h"
#include <stdint.h>  // for uint8_t

#define NUMBER_OF_PRETEND_PINS 30

static uint8_t pins[NUMBER_OF_PRETEND_PINS];

void pinMode(uint8_t pin, uint8_t mode) {
  // just set the initial value
  // not using this to enforce any rules
  if (mode == INPUT_PULLUP) {
    pins[pin] = HIGH;  // until somebody pushes the button
  }
  if (mode == OUTPUT) {
    pins[pin] = LOW;  // until somebody sets it
  }
}

uint8_t digitalRead(uint8_t pin) {
  // printf("\npin %d <- %d\n", pin, pins[pin]);
  return pins[pin];
}

void digitalWrite(uint8_t pin, uint8_t value) {
  pins[pin] = value;
  // printf("\npin %d -> %d\n", pin, pins[pin]);
}
