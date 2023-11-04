.PHONY: always

GIT_HASH := dev

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
	sed 's|INST|/usr/share/serial-keyboard|g' resources/serial-keyboard@.service > $@/etc/systemd/system/serial-keyboard@.service
	$(MAKE) -f $(MAKEFILE_LIST) $@/usr/share/serial-keyboard
	$(MAKE) -f $(MAKEFILE_LIST) $@/DEBIAN/control
package/DEBIAN/control: resources/control
	sed "s/{ VERSION }/$(shell date +"%Y%m%d%H%M%S").$(GIT_HASH)/" $< > $@
package/usr/share/serial-keyboard: firmware/baud driver/serial_keyboard.lua driver/serial_keyboard_lib.so
	mkdir -p $@
	cp $^ $@
firmware/% driver/%: always
	$(MAKE) $@
always:
