#include "eeprom.h"
#include <string.h>  // for memset

uint8_t eeprom_data[1024];

uint8_t EEPROM_Read(int address) {
  return eeprom_data[address];
}

void EEPROM_Write(int address, uint8_t value) {
  eeprom_data[address] = value;
}

void EEPROM_Clear() {
  memset(eeprom_data, 255, sizeof(eeprom_data));
}

EEPROMStruct EEPROM = {.read = EEPROM_Read,
                       .write = EEPROM_Write,
                       .clear = EEPROM_Clear};
