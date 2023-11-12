.SUFFIXES:
.PHONY: demo always

CC = gcc
CFLAGS =
LDFLAGS =
# -fno-exceptions https://stackoverflow.com/a/42078101
COMPILE = $(CC) -fPIC -c -fno-exceptions
LUA = lua5.4

HEADERS := $(shell find . -name '*.h')

always:
framework.c.o: framework.c Makefile $(HEADERS) .flags
	$(COMPILE) $(CFLAGS) -I /usr/include/$(LUA) $< -o $@
demo.o: Demo/Demo.ino $(HEADERS) Makefile .flags
	$(COMPILE) $(CFLAGS) -x c++ $< -o $@ -include Arduino.h -I .
%.o: % Makefile $(HEADERS) .flags
	$(COMPILE) $(CFLAGS) $< -o $@
demo.so: demo.o gpio.c.o framework.c.o serial.cpp.o EEPROM.cpp.o
	$(CC) -shared -fPIC $^ $(LDFLAGS) -lpthread -o $@
.flags: always
	echo $(CC) > $@.tmp
	echo $(CFLAGS) >> $@.tmp
	echo $(LDFLAGS) >> $@.tmp
	diff $@.tmp $@ || mv $@.tmp $@
