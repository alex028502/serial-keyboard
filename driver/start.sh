#! /usr/bin/env bash

set -e

dir=$(dirname $0)

echo DEBUG: library - tty - uinput
echo $@

exec lua5.4 $dir/serial_keyboard.lua "$@" $dir/baud
