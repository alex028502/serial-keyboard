#include "eeprom.h"
#include <string.h>  // for memset

#define EEPROM_SIZE 1024

uint8_t eeprom_data[EEPROM_SIZE];

uint8_t EEPROM_Read(int address) {
  if (address < 0 || address >= EEPROM_SIZE) {
    return 0;
  }
  return eeprom_data[address];
}

void EEPROM_Write(int address, uint8_t value) {
  if (address >= 0 && address < EEPROM_SIZE) {
    eeprom_data[address] = value;
  }
}

void EEPROM_Clear() {
  memset(eeprom_data, 255, sizeof(eeprom_data));
}

EEPROMStruct EEPROM = {.read = EEPROM_Read,
                       .write = EEPROM_Write,
                       .clear = EEPROM_Clear};
