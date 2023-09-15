include arduino-cli.mk

CC=gcc
ARDUINO_EXE=bin/arduino-cli
ARDUINO_PLATFORM=arduino:avr
ARDUINO_FQBN=$(ARDUINO_PLATFORM):nano
ARDUINO_PROJECT_NAME=SerialKeyboard
ARDUINO_SKETCH=$(ARDUINO_PROJECT_NAME)/$(ARDUINO_PROJECT_NAME).ino
BAUD_FILE=$(ARDUINO_PROJECT_NAME)/baud.h
ARDUINO_BUILD_DIR=build
ARDUINO_DOWNLOAD_PATH=https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh
export ARDUINO_DIRECTORIES_DATA=.arduino
export ARDUINO_DIRECTORIES_DOWNLOADS=$(ARDUINO_DIRECTORIES_DATA)/downloads
AVR_DUDE_DIR=$(ARDUINO_DIRECTORIES_DATA)/packages/arduino/tools/avrdude/6.3.0-arduino17
AVR_DUDE=$(AVR_DUDE_DIR)/bin/avrdude
AVR_DUDE_CONF=$(AVR_DUDE_DIR)/etc/avrdude.conf

all: $(ARDUINO_BUILD_DIR) baud.txt
baud: baud.c $(BAUD_FILE) $(MAKEFILE_LIST)
	$(CC) $< -o $@
baud.txt: baud
	./$< > $@
$(ARDUINO_BUILD_DIR): $(ARDUINO_SKETCH) $(BAUD_FILE) $(ARDUINO_DIR) $(ARDUINO_DIRECTORIES_DATA) $(ARDUINO_EXE)
	rm -rf $@ $@.tmp
	$(ARDUINO_EXE) compile --output-dir $@.tmp -b $(ARDUINO_FQBN) $(<D)
	mv $@.tmp $@
$(AVR_DUDE_CONF) $(AVR_DUDE): $(ARDUINO_DIRECTORIES_DATA)
$(ARDUINO_DIRECTORIES_DATA): $(ARDUINO_EXE) arduino-cli.mk
	rm -rf $@
	$< core install $(ARDUINO_PLATFORM)@$(ARDUINO_CORE_VERSION)
	ls $(AVR_DUDE)
$(ARDUINO_EXE): arduino-cli.mk
	rm -rf $@
	curl -fsSL $(ARDUINO_DOWNLOAD_PATH) | sh -s $(ARDUINO_CLI_VERSION)
flash: $(ARDUINO_BUILD_DIR) $(AVR_DUDE_CONF) $(AVR_DUDE)
	[ "$(DEVICE_PORT)" != "" ]
	$(AVR_DUDE) "-C$(AVR_DUDE_CONF)" -patmega328p -carduino "-P$(DEVICE_PORT)" -b115200 -D "-Uflash:w:$(ARDUINO_BUILD_DIR)/$(ARDUINO_PROJECT_NAME).ino.hex:i"
