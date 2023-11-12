.SUFFIXES:

# thanks https://unix.stackexchange.com/questions/517190/what-causes-make-to-delete-intermediate-files
.PRECIOUS: %.o

PROJECT = serial_keyboard
PROJECT_LIB = $(PROJECT)_lib

include constants.mk

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
bytes: bytes.o main/ioctl.o
	$(CC) -o $@ $^ $(LDFLAGS) -fPIC
%.o: %.c Makefile
	$(CC) -c -o $@ $(CFLAGS) -fPIC $< -I $(LUA_SRC)
test: test-main test-error test-ioctl test-meta test-version
test-version: start.sh
	@echo make sure $(LUA) is the version used by $<
	grep $(LUA) start.sh
test-main: $(PROJECT_LIB).test.so test/helpers.so
	test/driver.sh $(LUA) start.sh $^
test-error: $(PROJECT_LIB).main.so $(PROJECT_LIB).test.so test/helpers.so
	test/errors.sh $(LUA) start.sh $^
test-ioctl: bytes
	test/ioctl.sh $<
test-meta: test/helpers.so
	$(LUA) test/meta.lua test/library.lua $<
