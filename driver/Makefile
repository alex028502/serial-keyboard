.SUFFIXES:

PROJECT = serial_keyboard
PROJECT_LIB = $(PROJECT)_lib

LUA = lua5.4
LUA_SRC = /usr/include/$(LUA)

COV = -fprofile-arcs -ftest-coverage

version.txt: Makefile
	echo $(LUA) > $@
$(PROJECT_LIB).so: lib/ioctl.main.o $(PROJECT_LIB).main.o
	gcc -shared -o $@ -fPIC -l$(LUA) $^
$(PROJECT_LIB).%.so: test/ioctl.%.o $(PROJECT_LIB).%.o
	gcc -shared -o $@ -fPIC -l$(LUA) $^ $(if $(filter cov,$*),-lgcov,)
test/helpers.%.so: test/helpers.%.o
	gcc -shared -o $@ -fPIC -l$(LUA) $^ $(if $(filter cov,$*),-lgcov,)
%.cov.o: %.c Makefile
	rm -f $@.gcno
	gcc -c -o $@ $(COV) -fPIC $< -I $(LUA_SRC)
%.main.o: %.c Makefile
	gcc -c -o $@ -fPIC $< -I $(LUA_SRC)
