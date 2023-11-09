#! /usr/bin/env bash

set -e

# dependencies that require compilation are passed in to force us to mention
# them in the makefile
driver_lib=$(realpath $1)
shift
firmware=$(realpath $1)
shift
helper=$(realpath $1)

# scripts that don't require compilation are just relative paths
# lua scripts can't really have relative paths inside them but with .sh scripts
# I need to try to make sure those don't hard code compiled dependencies
# so that I don't run the tests with old dependencies by accident
driver_script=$(dirname $0)/driver/start.sh
library=$(dirname $0)/driver/test/library.lua
firmware_test_lua_lib=$(dirname $0)/firmware/test/library.lua

interpreter=lua5.4

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
sleep 0.2
set +e
kill -0 $driver_id
driver_status=$?
set -e
echo driver running status $driver_status
[ "$driver_status" = 1 ]
echo ^^^^^ test error ^^^^^^
echo ---- E2E SUCCESS -----------
