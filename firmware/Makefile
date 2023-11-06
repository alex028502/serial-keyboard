.PHONY: test coverage always

SKETCH = SerialKeyboard/SerialKeyboard.ino

EXE = lua5.4

FRAMEWORK = test/framework

CC = gcc
CFLAGS =
LDFLAGS =

test: test/sut.so
	test/test.sh $(EXE) $<
test/sut.so: test/sketch.o always
	test/framework/compile.sh "$(MAKE)" $< $@ $(CC) "$(LDFLAGS)" "$(CFLAGS)"
test/sketch.o: $(SKETCH)
	$(CC) -c -fPIC -I test/framework -include test/framework/Arduino.h -x c++ $(CFLAGS) $< -o $@
always:
clean:
	find test -name '*.so' -o -name '*.o' -o -name '*.gc*' | xargs rm -f
	find test -name 'luacov.*.out' | xargs rm -f
