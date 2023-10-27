.PHONY: test always-execute clang-format _coverage coverage clean-coverage

GIT_HASH := dev

# the two projects will use the same exe so either will do
EXE = firmware/test/framework/lua
ASSERTION_LIB = firmware/test/framework/library.lua

C_COVERAGE_PATTERN = '*.gcda'
LUA_COVERAGE_PATTERN = 'luacov.*.out'

ALL_FILES := $(shell ./list.sh)
ALL_FIRMWARE_FILES := $(shell ./list.sh | grep -w firmware)

COVERAGE_FILES = firmware.labeled.info e2e.labeled.info tools.labeled.info failure.labeled.info

all: coverage/bash
coverage/bash: always
	rm -rf $@
	bashcov entry.sh
main-test: check-format clean-coverage
	$(MAKE) assert-clean-coverage
	$(MAKE) -C firmware test
	$(MAKE) assert-clean-coverage
	$(MAKE) test
	$(MAKE) assert-clean-coverage
	$(MAKE) coverage/main
coverage/main: coverage.info luacov lcov tests.desc
	rm -rf $@
	genhtml $< --output-directory $@ --description-file tests.desc --show-details
tests.desc: coverage.info
	cat $< | grep TN | sed 's|TN:|TD: |' | xargs -I {} echo {} {} | sed 's/TD/TN/' | sort | uniq | xargs -n2 echo > $@
coverage.info: $(COVERAGE_FILES) empty.labeled.info
	echo $^ | xargs -n1 echo -a | xargs lcov -o $@
empty.coverage.info: empty.raw.info
	lcov -a $< -t empty -o $@
empty.raw.info: $(COVERAGE_FILES)
	mkdir -p tmp
	cat $^ | grep SF | cut -c4- | xargs -I {} realpath --relative-to="$(PWD)" "{}" | sort | uniq > tmp/checked-files.txt
	./list.sh lua c cpp ino | xargs -I {} realpath --relative-to="$(PWD)" "{}" | sort > tmp/all-files.txt
	comm -3 tmp/all-files.txt tmp/checked-files.txt | xargs ./no-coverage.sh > $@
%.labeled.info: %.coverage.info
	sed "s|TN:|TN:$*|" $< > $@
firmware.coverage.info: $(ALL_FIRMWARE_FILES) Makefile
	$(MAKE) clean-coverage
	$(MAKE) assert-clean-coverage
	$(MAKE) -C firmware coverage
	! $(MAKE) assert-clean-coverage
	cd firmware && luacov -r lcov
	sed 's|SF:|SF:firmware/|' firmware/luacov.report.out > firmware.lua.info
	lcov --capture --directory . --output-file firmware.c.info
	lcov -a firmware.lua.info -a firmware.c.info -o $@
e2e.coverage.info: $(ALL_FILES)
	$(MAKE) clean-coverage
	$(MAKE) assert-clean-coverage
	$(MAKE) _coverage
	! $(MAKE) assert-clean-coverage
	luacov -r lcov
	lcov --capture --directory . -o e2e.c.info
	lcov -a luacov.report.out -a e2e.c.info -o $@
tools.coverage.info: $(ALL_FILES)
	$(MAKE) clean-coverage
	$(MAKE) assert-clean-coverage
	./list.sh | xargs -n1 $(EXE) -lluacov newline.lua
	! $(MAKE) assert-clean-coverage
	luacov -r lcov
	lcov -a luacov.report.out -o $@
failure.coverage.info: tmp/nonewline.txt $(ALL_FILES)
	$(MAKE) clean-coverage
	$(MAKE) assert-clean-coverage
	! $(EXE) -lluacov newline.lua $<
	! $(MAKE) assert-clean-coverage
	luacov -r lcov
	lcov -a luacov.report.out -o $@
tmp/nonewline.txt: Makefile
	mkdir -p $(@D)
	echo hello > $@
	echo -n world >> $@
clean-coverage:
	find . -name $(C_COVERAGE_PATTERN) | xargs rm -vf
	find . -name $(LUA_COVERAGE_PATTERN) | xargs rm -vf
assert-clean-coverage:
	! find . -name $(C_COVERAGE_PATTERN) | grep '.'
	! find . -name $(LUA_COVERAGE_PATTERN) | grep '.'
check-format: stylua clang-format $(EXE)
	! ./list.sh | sed 's/ /SPACE/' | grep SPACE # no spaces in paths
	./list.sh c cpp h ino | xargs clang-format --style=Chromium -Werror --dry-run
	./list.sh lua | xargs $< --check
	! ./list.sh | xargs grep -rnH '.*\s$$'
	! ./list.sh | grep -v Makefile | grep -vw mk | xargs grep -nHP '\t'
	./list.sh | xargs -n1 $(EXE) newline.lua
clang-format stylua luacov lcov:
	which $@
test: $(EXE) driver/serial_keyboard_lib.main.so firmware/test/sut.so driver/test/helpers.main.so firmware/baud.txt
	test/test.sh driver/serial_keyboard.lua $(ASSERTION_LIB) $^
_coverage: driver/serial_keyboard_lib.cov.so firmware/test/sut.cov.so driver/test/helpers.cov.so firmware/baud.txt
	make $(EXE)
	test/test.sh driver/serial_keyboard.lua $(ASSERTION_LIB) "$(EXE) -lluacov" $^
driver/%.so: always
	$(MAKE) -C driver $*.so
$(EXE):
	make -C $(@D) $(@F)
firmware/%.so: always
	$(MAKE) -C firmware $*.so
always:
serial-keyboard.deb: package
	dpkg-deb --build $< $@
package: always
	rm -rf $@
	mkdir -p $@/etc/udev/rules.d $@/etc/serial-keyboard
	mkdir -p $@/DEBIAN $@/etc/systemd/system
	cp resources/postinst $@/DEBIAN/postinst
	cp resources/99-serial-keyboard.rules $@/etc/udev/rules.d
	echo /etc/udev/rules.d/99-serial-keyboard.rules > $@/DEBIAN/conffiles
	cp resources/postinst $@/DEBIAN
	cp resources/serial-keyboard@.service $@/etc/systemd/system
	$(MAKE) $@/usr/share/serial-keyboard
	$(MAKE) $@/DEBIAN/control
package/DEBIAN/control: resources/control
	sed "s/{ VERSION }/$(shell date +"%Y%m%d%H%M%S").$(GIT_HASH)/" $< > $@
package/usr/share/serial-keyboard: firmware/baud driver/serial_keyboard.lua driver/serial_keyboard_lib.so
	mkdir -p $@
	cp resources/start.sh $^ $@
