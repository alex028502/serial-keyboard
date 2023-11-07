.PHONY: test always-execute clang-format _coverage coverage clean-coverage

C_COVERAGE_PATTERN = '*.gcda'
LUA_COVERAGE_PATTERN = 'luacov.*.out'

ALL_FILES := $(shell ./list.sh)
ALL_FIRMWARE_FILES := $(shell ./list.sh | grep -w firmware)

COVERAGE_FILES = firmware.labeled.info test-e2e.labeled.info driver.labeled.info newline.labeled.info

BRANCH = --rc lcov_branch_coverage=1

all: lcov clean report ascii-report version
version: driver/version.txt
	echo lua5.4 | diff - $<
ascii-report: coverage.info
	lcov $(BRANCH) --list $<
	lcov $(BRANCH) --summary $<
coverage-check: coverage-100 missed-files
coverage-100: coverage.info
	lcov $(BRANCH) --summary $< | grep lines | grep 100
	lcov $(BRANCH) --summary $< | grep branch | grep 100
report: coverage.info tests.desc
	rm -rf $@
	genhtml $< --output-directory $@ --description-file tests.desc --show-details --branch-coverage
bash-tools:
	! misc/if-else.sh misc/if-else.txt
tests.desc: coverage.info
	cat $< | grep TN | sed 's|TN:|TD: |' | xargs -I {} echo {} {} | sed 's/TD/TN/' | sort | uniq | xargs -n2 echo > $@
coverage/main: coverage.info tests.desc
	rm -rf $@
coverage.info: tmp2.coverage.info
	lcov $(BRANCH) --remove $< '*/lua/5.4/*' -o $@
tmp2.coverage.info: tmp.coverage.info
	cat $< | sed 's|SF:/|ABC|' | sed "s|SF:|SF:$(PWD)/|" | sed 's|ABC|SF:/|' > $@
tmp.coverage.info: $(ALL_FILES)
	bashcov ./entry.sh $(COVERAGE_FILES)
	cat .bashcov/lcov/serial-keyboard.lcov | sed 's|SF:\./|TN:\nSF:|' > bash.coverage.info
	$(MAKE) bash.labeled.info
	echo $(COVERAGE_FILES) bash.labeled.info | xargs -n1 echo -a | xargs lcov $(BRANCH) -o $@
missed-files: coverage.info
	mkdir -p tmp
	cat $^ | grep SF | cut -c4- | xargs -I {} realpath --relative-to="$(PWD)" "{}" | sort | uniq > tmp/checked-files.txt
	./list.sh lua c cpp ino sh stty 4 baud | xargs -I {} realpath --relative-to="$(PWD)" "{}" | sort > tmp/all-files.txt
	diff tmp/all-files.txt tmp/checked-files.txt
%.labeled.info: %.coverage.info
	sed "s|TN:|TN:$*|" $< > $@
firmware.coverage.info: $(ALL_FIRMWARE_FILES) Makefile
	$(MAKE) clean-coverage
	./with-lua.sh - $(MAKE) -C firmware test CFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-lgcov" CC=gcc
	cd firmware && luacov -r lcov
	sed "s|SF:|SF:$(PWD)/firmware/|" firmware/luacov.report.out > lua.$@
	lcov $(BRANCH) --capture --directory . --output-file c.$@
	lcov $(BRANCH) -a lua.$@ -a c.$@ -o $@
test-%.coverage.info: $(ALL_FILES)
	$(MAKE) clean-coverage
	./with-lua.sh lua.$@ $(MAKE) test-$* CFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-lgcov" CC=gcc
	! $(MAKE) assert-clean-coverage
	lcov $(BRANCH) --capture --directory . -o c.$@
	lcov $(BRANCH) -a lua.$@ -a c.$@ -o $@
driver.coverage.info: $(ALL_FILES)
	$(MAKE) clean-coverage
	./with-lua.sh - $(MAKE) -C driver test CFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-lgcov" CC=gcc
	cd driver && luacov -r lcov
	cat driver/luacov.report.out | sed "s|SF:/|SFS|" | sed "s|SF:|SF:$(PWD)/driver/|" | sed "s|SFS|SF:/|"  > lua.$@
	lcov $(BRANCH) --capture --directory . -o c.$@
	lcov $(BRANCH) -a lua.$@ -a c.$@ -o $@
newline.coverage.info: $(ALL_FILES)
	$(MAKE) clean-coverage
	./with-lua.sh $@ $(MAKE) newline
	! $(MAKE) assert-clean-coverage
newline: tmp/nonewline.txt $(ALL_FILES)
	! lua5.4 misc/newline.lua $<
	lua5.4 misc/newline.lua Makefile
tmp/nonewline.txt: Makefile
	mkdir -p $(@D)
	echo hello > $@
	echo -n world >> $@
clean-coverage:
	find . -name $(C_COVERAGE_PATTERN) | xargs rm -vf
	find . -name $(LUA_COVERAGE_PATTERN) | xargs rm -vf
	$(MAKE) assert-clean-coverage
assert-clean-coverage:
	! find . -name $(C_COVERAGE_PATTERN) | grep '.'
	! find . -name $(LUA_COVERAGE_PATTERN) | grep '.'
check-format: stylua clang-format
	! ./list.sh | sed 's/ /SPACE/' | grep SPACE # no spaces in paths
	./list.sh c cpp h ino | xargs misc/format.c.sh --dry-run
	./list.sh lua | xargs $< --check
	! ./list.sh | xargs grep -rnH '.*\s$$'
	! ./list.sh | grep -v Makefile | grep -vw mk | xargs grep -nHP '\t'
	./list.sh | xargs -n1 lua5.4 misc/newline.lua
	./list.sh lua | xargs ./misc/if-else.sh
	! grep -nHw g'++' $(ALL_FILES)
clang-format stylua luacov lcov:
	which $@
test-e2e: driver/serial_keyboard_lib.test.so firmware/test/sut.so driver/test/helpers.so
	./e2e.sh driver/start.sh $^
firmware/%.so driver/%.so driver/%ytes driver/%.txt firmware/bau%: always
	$(MAKE) -C $$(echo $@ | sed 's|/| |') CFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-lgcov" CC=gcc
always:
clean:
	find -type f | git check-ignore --stdin | grep -v '.git' | xargs rm -f
