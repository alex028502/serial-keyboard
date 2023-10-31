#include "EEPROM.h"
#include <string.h>  // for memset

uint8_t eeprom_data[1024];

uint8_t EEPROMClass::read(int address) {
  // TODO: fail if address out of range
  return eeprom_data[address];
}

void EEPROMClass::write(int address, uint8_t value) {
  // TODO: fail if address is out of range
  eeprom_data[address] = value;
}

extern "C" void EEPROM_Clear() {
  memset(eeprom_data, 255, sizeof(eeprom_data));
}

EEPROMClass EEPROM;
