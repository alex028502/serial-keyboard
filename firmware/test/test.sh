#! /usr/bin/env bash

set -e

interpreter="$1"
sut=$(realpath $2)
baud=$(cat $3)

source $(dirname $0)/lib.sh

echo ------------------ FIRMWARE TEST ----------------------
test_script=$(dirname $0)/test.lua
test_lib=$(dirname $0)/framework/library.lua
firmware_test_lib=$(dirname $0)/library.lua
test_lib="$test_lib $firmware_test_lib"

function cleanup {
    # wrapper so that we can see in the coverage report that it gets run
    _cleanup
}

trap cleanup EXIT

open-serial
echo ---- TEST FIRMWARE ------
$interpreter $test_script $sut $test_lib $dev/serial $dev/serial.interface $baud
echo ---- SUCCESS ------------
echo
