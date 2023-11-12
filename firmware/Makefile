.PHONY: test coverage always

SKETCH = SerialKeyboard/SerialKeyboard.ino

EXE = lua5.4

FRAMEWORK = test/framework

CC = gcc
CFLAGS =
LDFLAGS =

TEST_MODULES = $(FRAMEWORK)/serial.cpp.o $(FRAMEWORK)/EEPROM.cpp.o $(FRAMEWORK)/gpio.c.o $(FRAMEWORK)/framework.c.o

test: test-main test-framework
test-main: test/sut.so
	test/test.sh $(EXE) $<
test-framework: $(FRAMEWORK)/demo.so
	$(FRAMEWORK)/test.sh $(EXE) $<
test/sut.so: test/sketch.o $(TEST_MODULES) test/tools.o test/keys.o
	$(CC) -shared -fPIC $^ $(LDFLAGS) -lpthread -o $@
$(FRAMEWORK)/%.o: always
	$(MAKE) -C $(FRAMEWORK) $*.o
$(FRAMEWORK)/headers $(FRAMEWORK)/demo.so: always
	$(MAKE) -C $(@D) $(@F)
test/sketch.o: test/framework/Arduino.h $(SKETCH) .flags
	$(CC) -fPIC -c -fno-exceptions -I test/framework -include $< -x c++ $(CFLAGS) $(SKETCH) -o $@
test/tools.o: test/tools.c .flags
	$(CC) -fPIC -c -fno-exceptions $(CFLAGS) -I /usr/include/$(EXE) $< -o $@
test/keys.o: test/keys.c .flags
	$(CC) -fPIC -c -fno-exceptions $(CFLAGS) -I /usr/include/linux $< -o $@
always:
.flags: always
	echo $(CC) > $@.tmp
	echo $(CFLAGS) >> $@.tmp
	echo $(LDFLAGS) >> $@.tmp
	diff $@.tmp $@ || mv $@.tmp $@
clean:
	find test -name '*.so' -o -name '*.o' -o -name '*.gc*' | xargs rm -f
	find test -name 'luacov.*.out' | xargs rm -f
