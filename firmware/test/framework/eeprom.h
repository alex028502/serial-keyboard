#ifdef EEPROM_H
#error "EEPROM_H double include?"
#endif
#define EEPROM_H

#include <stdint.h>  // for uint8_t

typedef struct {
  uint8_t (*read)(int);
  void (*write)(int, uint8_t);
  void (*clear)();
} EEPROMStruct;

extern EEPROMStruct EEPROM;

uint8_t EEPROM_Read(int address);
void EEPROM_Write(int address, uint8_t value);
void EEPROM_Clear();
