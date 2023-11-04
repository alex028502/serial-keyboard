.SUFFIXES:

PROJECT = serial_keyboard
PROJECT_LIB = $(PROJECT)_lib

LUA = lua5.4
LUA_SRC = /usr/include/$(LUA)

COV = -fprofile-arcs -ftest-coverage

# TODO: figure out why I don't need -llua5.4
# (and make sure I will always get the right version)

version.txt: Makefile
	echo $(LUA) > $@
$(PROJECT_LIB).so: lib/ioctl.main.o $(PROJECT_LIB).main.o
	gcc -shared -o $@ -fPIC $^
$(PROJECT_LIB).%.so: test/ioctl.%.o $(PROJECT_LIB).%.o
	gcc -shared -o $@ -fPIC $^ $(if $(filter cov,$*),-lgcov,)
test/helpers.%.so: test/helpers.%.o
	gcc -shared -o $@ -fPIC $^ $(if $(filter cov,$*),-lgcov,)
bytes.cov: bytes.c lib/ioctl.c
	gcc -o $@ $^ $(COV)
%.cov.o: %.c Makefile
	rm -f $@.gcno
	gcc -c -o $@ $(COV) -fPIC $< -I $(LUA_SRC)
%.main.o: %.c Makefile
	gcc -c -o $@ -fPIC $< -I $(LUA_SRC)
