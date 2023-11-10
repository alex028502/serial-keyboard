.SUFFIXES:
.PHONY: demo always

CC = gcc
CFLAGS =
LDFLAGS =
# -fno-exceptions https://stackoverflow.com/a/42078101
COMPILE = $(CC) -fPIC -c -fno-exceptions
LUA = lua5.4

headers: always
	find . -name '*.h' | xargs cat > $@.tmp
	diff $@.tmp $@ || mv $@.tmp $@
always:
framework.c.o: framework.c Makefile headers
	$(COMPILE) $(CFLAGS) -I /usr/include/$(LUA) $< -o $@
demo.o: Demo/Demo.ino headers Makefile
	$(COMPILE) $(CFLAGS) -x c++ $< -o $@ -include Arduino.h -I .
%.o: % Makefile headers
	$(COMPILE) $(CFLAGS) $< -o $@
demo.so: demo.o gpio.c.o framework.c.o serial.cpp.o EEPROM.cpp.o
	$(CC) -shared -fPIC $^ $(LDFLAGS) -lpthread -o $@
