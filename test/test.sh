#! /usr/bin/env bash

set -e

driver_script=$(realpath $1)
library=$(realpath $2)
interpreter="$3"
driver_lib=$(realpath $4)
firmware=$(realpath $5)
helper=$(realpath $6)
baud=$(cat $7)

# we could probably just pass in the path to the firmware project but we need
# to change a few thigs about the make file or start moving to bash from make
firmware_test_lib=$(dirname $firmware)/lib.sh

echo ----------------------- UNIT --------------------------
$interpreter $(dirname $0)/keyevent.lua $library $helper
echo
echo ----------------------- E2E ---------------------------
if echo $interpreter | grep luacov
then
    i="$interpreter -lluacov.tick"
    echo lua coverage: YES
else
    i="$interpreter"
    echo lua coverage: NO
fi

if nm $firmware | grep __gcov > /dev/null
then
    echo c coverage: YES
else
    echo c coverage: NO
fi

source $firmware_test_lib
open-serial

function cleanup {
    # wrapper so that we can see in the coverage report that it gets run
    _cleanup
}

trap cleanup EXIT
echo ---- OPEN FAKE UINPUT ---
mkfifo $dev/uinput
echo
echo ---- START DRIVER -------
# this one has one more option when in coverage mode
if echo $interpreter | grep luacov
then
    i="$interpreter -lluacov.tick"
else
    i="$interpreter"
fi
echo using interpreter $i from $interpreter

SERIAL_KEYBOARD_DEBUG=TRUE $i $driver_script $driver_lib $dev/serial $dev/uinput &

driver_id=$!
remember driver $driver_id
sleep 1
echo see if it started:
kill -0 $driver_id

echo
echo ---- TEST DRIVER INIT ---
# because the driver is only started once the init is only tested once
# the serial port should not affect anything here but might need to exist
$interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $baud

echo
echo ---- TEST DRIVER --------
$interpreter $(dirname $0)/driver.lua $(dirname $0)/lib.lua $helper $library $dev/serial.interface $dev/uinput $baud

echo
echo ---- TEST ALL -----------
$interpreter $(dirname $0)/e2e.lua $(dirname $0)/lib.lua $firmware $helper $library $dev/serial $dev/serial.interface $dev/uinput $baud
echo sleep 1
echo ---- SUCCESS -----------
