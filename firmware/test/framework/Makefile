.SUFFIXES:
.PHONY: demo always

CC = gcc
CFLAGS =
# -fno-exceptions https://stackoverflow.com/a/42078101
COMPILE = $(CC) -fPIC -c -fno-exceptions
LUA = lua5.4

headers: always
	find . -name '*.h' | xargs cat > $@.tmp
	diff $@.tmp $@ || mv $@.tmp $@
always:
framework.c.o: framework.c Makefile headers
	$(COMPILE) $(CFLAGS) -I /usr/include/$(LUA) $< -o $@
%.o: % Makefile headers
	$(COMPILE) $(CFLAGS) $< -o $@
