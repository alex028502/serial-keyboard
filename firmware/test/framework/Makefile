.PHONY: demo always

COV = -fprofile-arcs -ftest-coverage
COMPILE = gcc -fPIC -c
LUA = lua5.4

headers: always
	find . -name '*.h' | xargs cat > $@.tmp
	diff $@.tmp $@ || mv $@.tmp $@
always:
lua:
	ln -sf `which $(LUA)` $@
version.txt: Makefile
	echo $(LUA) > $@
%.cov.gcno: %.cov.o
framework.c.cov.o: framework.c Makefile headers
	$(COMPILE) $(COV) -I /usr/include/$(LUA) $< -o $@
%.cov.o: % Makefile headers
	rm -rf $*.cov.gc*
	$(COMPILE) $(COV) $< -o $@
