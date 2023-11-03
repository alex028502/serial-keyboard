.PHONY: test coverage always

SKETCH = SerialKeyboard/SerialKeyboard.ino

EXE = lua5.4

FRAMEWORK = test/framework

COMPILE = gcc -c -fPIC -I test/framework -include test/framework/Arduino.h -x c++

CC = gcc

coverage: test/sut.cov.so baud.cov
	test/test.sh $(EXE) $< ./baud.cov
baud.cov: baud.c SerialKeyboard/baud.h
	gcc -fprofile-arcs -ftest-coverage $< -o $@
baud: baud.c $(BAUD_FILE) $(MAKEFILE_LIST)
	$(CC) $< -o $@
test/sut%so: test/sketch%o always
	test/framework/compile.sh "$(MAKE)" $< $@
test/sketch.cov.o: $(SKETCH)
	$(COMPILE) -fprofile-arcs -ftest-coverage $< -o $@
always:
clean:
	find test -name '*.so' -o -name '*.o' -o -name '*.gc*' | xargs rm -f
	find test -name 'luacov.*.out' | xargs rm -f
