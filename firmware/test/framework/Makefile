.PHONY: demo always

COV = -fprofile-arcs -ftest-coverage
# -fno-exceptions https://stackoverflow.com/a/42078101
COMPILE = gcc -fPIC -c -fno-exceptions
LUA = lua5.4

headers: always
	find . -name '*.h' | xargs cat > $@.tmp
	diff $@.tmp $@ || mv $@.tmp $@
always:
%.cov.gcno: %.cov.o
framework.c.cov.o: framework.c Makefile headers
	$(COMPILE) $(COV) -I /usr/include/$(LUA) $< -o $@
%.cov.o: % Makefile headers
	rm -rf $*.cov.gc*
	$(COMPILE) $(COV) $< -o $@
