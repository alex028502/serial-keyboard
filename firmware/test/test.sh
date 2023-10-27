#! /usr/bin/env bash

set -e

interpreter="$1"
sut=$(realpath $2)
baud=$(cat $3)

source $(dirname $0)/lib.sh

echo ------------------ FIRMWARE TEST ----------------------
if echo $interpreter | grep luacov
then
    echo lua coverage: YES
else
    echo lua coverage: NO
fi

if nm $sut | grep __gcov > /dev/null
then
    echo c coverage: YES
else
    echo c coverage: NO
fi

test_script=$(dirname $0)/test.lua
test_lib=$(dirname $0)/framework/library.lua

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
