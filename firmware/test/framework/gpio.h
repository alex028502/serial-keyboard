#ifdef GPIO_H
#error "GPIO_H double include?"
#endif
#define GPIO_H

#define LED_BUILTIN 13

#include <stdint.h>

enum {
  INPUT_PULLUP,
  OUTPUT,
};

#define HIGH (1 == 1)
#define LOW (1 == 0)

void pinMode(uint8_t pin, uint8_t mode);
uint8_t digitalRead(uint8_t pin);
void digitalWrite(uint8_t pin, uint8_t value);
