.PHONY: test coverage always

SKETCH = SerialKeyboard/SerialKeyboard.ino

EXE = lua5.4

FRAMEWORK = test/framework

CC = gcc
CFLAGS =
LDFLAGS =

TEST_MODULES = $(FRAMEWORK)/serial.cpp.o $(FRAMEWORK)/EEPROM.cpp.o $(FRAMEWORK)/gpio.c.o $(FRAMEWORK)/framework.c.o

test: test/sut.so
	test/test.sh $(EXE) $<
test/sut.so: test/sketch.o $(TEST_MODULES)
	$(CC) -shared -fPIC $(TEST_MODULES) $< $(LDFLAGS) -lpthread -o $@
$(FRAMEWORK)/%.o: always
	$(MAKE) -C $(FRAMEWORK) $*.o COV="$(CFLAGS)" CC=$(CC)
$(FRAMEWORK)/headers: always
	$(MAKE) -C $(@D) $(@F)
test/sketch.o: $(SKETCH) $(FRAMEWORK)/headers
	$(CC) -c -fPIC -I test/framework -include test/framework/Arduino.h -x c++ $(CFLAGS) $< -o $@
always:
clean:
	find test -name '*.so' -o -name '*.o' -o -name '*.gc*' | xargs rm -f
	find test -name 'luacov.*.out' | xargs rm -f
