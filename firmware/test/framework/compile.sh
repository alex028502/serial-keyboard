#! /usr/bin/env bash

set -e

source_files="serial.cpp EEPROM.cpp gpio.c framework.c"

echo compiling with params $@

dir=$(dirname $0)

MAKE="$1 -C $dir"
sut_obj_file=$2
so=$3

# modules="$dir/serial.cpp $dir/framework.c $dir/eeprom.c $dir/gpio.c"
l="-lpthread"

l="$l -lgcov"
# if/when this is an external framework, I am not sure if the following is
# necessary or advisable, since the users of the framework will not be
# interested in the coverage of the framework from their tests
# but it might not hurt
ext=".cov.o"

module_names=""
module_paths=""
for f in $source_files
do
    module_names="$module_names $f$ext"
    module_paths="$module_paths $dir/$f$ext"
done

$MAKE $module_names

exec gcc -shared -fPIC $module_paths $sut_obj_file $l -o $so
