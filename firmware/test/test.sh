#! /usr/bin/env bash

set -e

interpreter="$1"
sut=$(realpath $2)
baud=$(cat $3)

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

echo ---- TEST FIRMWARE ------
$interpreter $test_script $sut $test_lib $baud
echo ---- SUCCESS ------------
echo
