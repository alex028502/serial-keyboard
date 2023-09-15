#! /usr/bin/env bash

set -e

res=/usr/share/serial-keyboard

DEVNAME=$1
echo device $DEVNAME
#echo device info $DEVPATH $DEVNAME $SUBSYSTEM $ID_SERIAL $ID_VENDOR_ID

stty -F $DEVNAME -echo $($res/baud)

exec lua5.4 $res/serial_keyboard.lua $res/serial_keyboard_lib.so $DEVNAME /dev/uinput

