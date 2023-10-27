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

dev=./dev

rm -rf $dev
mkdir $dev

processes=""

function remember {
    processes="$processes $@"
}

function cleanup {
    echo
    echo --------------------- CLEAN UP ------------------------
    echo background process list
    echo $processes | xargs -n2 echo
    ids=$(echo $processes | xargs -n2 echo | awk '{ print $2 }')
    echo kill $ids
    kill $ids || echo nothing to clean-up
    rm -rfv $dev
    echo -------------------------------------------------------
    echo
}

trap cleanup EXIT

echo ---- OPEN SERIAL --------
socat -d -d pty,raw,echo=0,link=$dev/serial pty,raw,echo=0,link=$dev/serial.interface &
remember serial $!
sleep 1
echo
echo ---- TEST FIRMWARE ------
$interpreter $test_script $sut $test_lib $dev/serial $dev/serial.interface $baud
echo ---- SUCCESS ------------
echo
