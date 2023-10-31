#ifdef EEPROM_H
#error "EEPROM_H double include?"
#endif
#define EEPROM_H

#include <stdint.h>  // for uint8_t

class EEPROMClass {
 public:
  uint8_t read(int address);
  void write(int address, uint8_t value);
};

extern EEPROMClass EEPROM;
