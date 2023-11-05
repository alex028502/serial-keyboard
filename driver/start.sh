#! /usr/bin/env bash

set -e

dir=$(dirname $0)

exec lua5.4 $dir/serial_keyboard.lua "$@" $dir/baud
