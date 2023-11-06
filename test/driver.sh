#! /usr/bin/env bash

set -e

driver_script=$(realpath $1)
shift
library=$(realpath $1)
shift
interpreter=lua5.4

driver_lib=$(realpath $1)
shift
firmware=$(realpath $1)
shift
helper=$(realpath $1)
shift

# just to make sure that whatever is configured in the baud program is what gets
# used when configuring the tty with stty
baud_program=$(dirname $driver_script)/baud
baud=$($baud_program)

# so that it uses fake stty
export PATH="$(dirname $0)/path:$PATH"
stty_path=$(which stty)
echo using $stty_path
[ "$stty_path" == "$(dirname $0)/path/stty" ]

# we could probably just pass in the path to the firmware project but we need
# to change a few thigs about the make file or start moving to bash from make
firmware_test_lua_lib=$(dirname $firmware)/library.lua

source $(dirname $0)/prep.sh

echo ---- OPEN FAKE UINPUT ---
mkfifo $dev/uinput
echo

echo
echo ---- TEST DRIVER --------
mkfifo $dev/serial
echo ---- start driver -------
SERIAL_KEYBOARD_DEBUG=TRUE $driver_script $driver_lib $dev/serial $dev/uinput &
driver_id=$!
remember driver $driver_id
sleep 1
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
# the serial port should not affect anything here but might need to exist
timeout 10 $interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $dev/serial $baud
echo ---- test driver --------
$interpreter $(dirname $0)/driver.lua $(dirname $0)/lib.lua $helper $library $dev/serial $dev/uinput $baud
echo ---- clean up ------------
rm $dev/serial
sleep 2
echo check if driver is still running
set +e
kill -0 $driver_id
driver_running_result=$?
set -e
[ "$driver_running_result" = 1 ]

echo ---- SUCCESS -----------
