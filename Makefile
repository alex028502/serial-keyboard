.PHONY: test always-execute clang-format coverage

GIT_HASH := dev

# the two projects will use the same exe so either will do
EXE = firmware/test/framework/lua
ASSERTION_LIB = firmware/test/framework/library.lua

C_COVERAGE_PATTERN = '*.gcda'
LUA_COVERAGE_PATTERN = 'luacov.*.out'

test-all: luacov lcov check-format
	find . -name $(C_COVERAGE_PATTERN) | xargs rm -vf
	find . -name $(LUA_COVERAGE_PATTERN) | xargs rm -vf
	$(MAKE) assert-clean-coverage
	$(MAKE) -C firmware test
	$(MAKE) test
	$(MAKE) assert-clean-coverage
	$(MAKE) coverage
	$< -r lcov
	! $(MAKE) assert-clean-coverage
	$(MAKE) -C firmware coverage
	cd firmware && $< -r lcov
	sed 's|SF:|SF:firmware/|' firmware/luacov.report.out > firmware.coverage
	lcov --capture --directory . --output-file c.coverage
	lcov -a c.coverage -a luacov.report.out -a firmware.coverage -o coverage.info
	genhtml coverage.info --output-directory coverage
assert-clean-coverage:
	! find . -name $(C_COVERAGE_PATTERN) | grep '.'
	! find . -name $(LUA_COVERAGE_PATTERN) | grep '.'
check-format: lua-format clang-format $(EXE)
	./list.sh c cpp h ino | xargs clang-format --style=Chromium -Werror --dry-run
	./list.sh lua | xargs -n1 lua-format --check
	! ./list.sh | xargs grep -rnH '.*\s$$'
	! ./list.sh | grep -v Makefile | grep -vw mk | xargs grep -nHP '\t'
	./list.sh | xargs -n1 $(EXE) newline.lua
clang-format lua-format luacov lcov:
	which $@
$(EXE):
	make -C $(@D) $(@F)
test: $(EXE) driver/serial_keyboard_lib.main.so firmware/test/sut.so driver/test/helpers.main.so firmware/baud.txt
	test/test.sh driver/serial_keyboard.lua $(ASSERTION_LIB) $^
coverage: driver/serial_keyboard_lib.cov.so firmware/test/sut.cov.so driver/test/helpers.cov.so firmware/baud.txt
	make $(EXE)
	test/test.sh driver/serial_keyboard.lua $(ASSERTION_LIB) "$(EXE) -lluacov" $^
driver/%: always
	$(MAKE) -C driver $*
firmware/test/framework/%: always
	$(MAKE) -C $(D@) $(F@)
firmware/%: always
	$(MAKE) -C firmware $*
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
