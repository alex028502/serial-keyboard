#! /usr/bin/env bash

set -e

driver_script=$(dirname $0)/driver/start.sh

library=$(dirname $0)/driver/test/library.lua

interpreter=lua5.4

driver_lib=$(realpath $1)
shift
firmware=$(realpath $1)
shift
helper=$(realpath $1)

firmware_test_lua_lib=$(dirname $0)/firmware/test/library.lua

source $(dirname $0)/driver/test/prep.sh

echo ---- OPEN FAKE UINPUT ---
mkfifo $dev/uinput
echo

echo
echo ---- TEST E2E -----------
echo ---- OPEN SERIAL --------
socat -d -d pty,raw,echo=0,link=$dev/serial pty,raw,echo=0,link=$dev/serial.interface &
remember serial $!
sleep 1
echo

# the fifo seems to close better than the socat pty - or I don't know the
# setting for the socat pty that will make it close nicely like the fifo
# but maybe if there is a way, somebody will answer someday
# https://unix.stackexchange.com/questions/760016
# for now I am using socat to test an error here and using a fifo in the
# driver tests to simulate a clean top where the input fd just ends
echo ---- start driver -------
$driver_script $driver_lib $dev/serial $dev/uinput &
driver_id=$!
remember driver2 $driver_id
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
read stty_line < $dev/serial.interface
echo STTY: $stty_line
baud=$(echo $stty_line | xargs -n1 echo | grep -E '^[0-9]+$')
echo BAUD: $baud
# the serial port should not affect anything here but might need to exist
$interpreter $(dirname $0)/driver/test/init.lua $helper $library $dev/uinput $dev/serial.interface
echo ---- test all -----------
$interpreter $(dirname $0)/misc/e2e.lua $(dirname $0)/driver/test/lib.lua $firmware $helper $library $firmware_test_lua_lib $dev/serial $dev/serial.interface $dev/uinput $baud
socat_pid=$(echo $processes | xargs -n2 echo | grep -w serial | awk '{ print $2 }')
kill $socat_pid
# there are really at least three ways of shutting down that ought to be tested
# - ending serial nicely (tested with fifo in driver tests)
# - ending serial not nicely (tested here)
# - SIGINT and/or SIGTERM to the driver program
# the third one is not tested at all but manually I do it all the time when
# trying this out - and it seems to work. one problem is that I haven't managed
# to measure test coverage that way.
timer=""
while kill -0 $driver_id
do
    timer="x$timer"
    c="$(echo $timer | wc -c)"
    # maxium two seconds
    # this took like eleven iterations when socat was connected to a fifo
    # and turning off socat caused the fifo to end nicely - but now that the
    # socat pty is connected directly to the driver, turning off socat causes
    # an almost immediate error - so this only has one iteration but also
    # doesn't seem to be immediate enough that this doesn't run (from coverage)
    # so it is still necessary because cleaning up the driver with kill would
    # mess up coverage
    echo waiting for driver to shut down $c
    [ "$c" != 20 ]
    sleep 0.1
done
echo ---- E2E SUCCESS -----------
