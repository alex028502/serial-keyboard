.SUFFIXES:

PROJECT = serial_keyboard
PROJECT_LIB = $(PROJECT)_lib

LUA = lua5.4
LUA_SRC = /usr/include/$(LUA)

CC = gcc
CFLAGS =
LDFLAGS =
# TODO: figure out why I don't need -llua5.4
# (and make sure I will always get the right version)

version.txt: Makefile
	echo $(LUA) > $@
$(PROJECT_LIB).%.so: %/ioctl.o $(PROJECT_LIB).o
	$(CC) -shared -o $@ -fPIC $^ $(LDFLAGS)
test/helpers.so: test/helpers.o
	$(CC) -shared -o $@ -fPIC $^ $(LDFLAGS)
bytes: bytes.c main/ioctl.c
	$(CC) -o $@ $^ $(CFLAGS)
%.o: %.c Makefile
	$(CC) -c -o $@ $(CFLAGS) -fPIC $< -I $(LUA_SRC)
test-main: serial_keyboard_lib.test.so test/helpers.so
	test/driver.sh start.sh $^
