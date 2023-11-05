#! /usr/bin/env bash

set -e

dir=$(dirname $0)

baud=$($dir/baud)
stty -echo -F $2 $baud

exec lua5.4 $dir/serial_keyboard.lua "$@"
