#! /usr/bin/env bash

set -e

interpreter="$1"
shift
sut=$(realpath $1)

echo ------------------ FIRMWARE TEST ----------------------
# I predict none of this will work if there are spaces in paths
test_script=$(dirname $0)/test.lua
test_lib=$(dirname $0)/library.lua

dev=dev
rm -rf $dev
mkdir $dev

echo ---- OPEN SERIAL --------
socat -d -d pty,raw,echo=0,link=$dev/serial pty,raw,echo=0,link=$dev/serial.interface &
socat_pid=$!
sleep 1

function cleanup {
    kill $socat_pid || echo no need to turn off socat
    rm -rvf $dev
}

trap cleanup EXIT

echo ---- TEST FIRMWARE ------
$interpreter $test_script $sut $test_lib $dev/serial $dev/serial.interface
echo ---- SUCCESS ------------
echo
