.PHONY: test coverage always

SKETCH = SerialKeyboard/SerialKeyboard.ino

EXE = test/framework/lua

FRAMEWORK = test/framework

COMPILE = gcc -c -fPIC -I test/framework -include test/framework/Arduino.h -x c++

test: $(EXE) test/sut.so baud.txt
	test/test.sh $^
coverage: test/sut.cov.so baud.txt $(EXE)
	test/test.sh "$(EXE) -lluacov" $< baud.txt
	$(MAKE) -f $(MAKEFILE_LIST) baud-coverage
baud-coverage: baud.txt baud.cov
	./baud.cov | diff - $<
baud.cov: baud.c SerialKeyboard/baud.h
	gcc -fprofile-arcs -ftest-coverage $< -o $@
baud.txt: always
	$(MAKE) $@
test/sut%so: test/sketch%o always
	test/framework/compile.sh "$(MAKE)" $< $@
test/sketch.o: $(SKETCH)
	$(COMPILE) $< -o $@
test/sketch.cov.o: $(SKETCH)
	$(COMPILE) -fprofile-arcs -ftest-coverage $< -o $@
always:
test/framework/%: always
	$(MAKE) -C $(@D) $(@F)
clean:
	find test -name '*.so' -o -name '*.o' -o -name '*.gc*' | xargs rm -f
	find test -name 'luacov.*.out' | xargs rm -f
