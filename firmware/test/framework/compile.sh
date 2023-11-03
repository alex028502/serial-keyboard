#! /usr/bin/env bash

set -e

source_files="serial.cpp EEPROM.cpp gpio.c framework.c"

echo compiling with params $@

dir=$(dirname $0)

MAKE="$1 -C $dir"
sut_obj_file=$2
so=$3
CC=$4
LDFLAGS=$5
CFLAGS=$6

# modules="$dir/serial.cpp $dir/framework.c $dir/eeprom.c $dir/gpio.c"
l="-lpthread"

l="$l $LDFLAGS"

ext=".o"

module_names=""
module_paths=""
for f in $source_files
do
    module_names="$module_names $f$ext"
    module_paths="$module_paths $dir/$f$ext"
done

$MAKE $module_names CC=$CC COV="$CFLAGS"

exec $CC -shared -fPIC $module_paths $sut_obj_file $l -o $so
