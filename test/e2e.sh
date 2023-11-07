#! /usr/bin/env bash

set -e

driver_script=$(realpath $1)
shift
library=$(dirname $0)/library.lua

interpreter=lua5.4

driver_lib=$(realpath $1)
shift
firmware=$(realpath $1)
shift
helper=$(realpath $1)

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
echo ---- TEST E2E -----------
# two way pty is still needed for this test because the fake arduino will open
# the serial path for read and write - and the driver will also want to open
# for read - so a single path won't work
mkfifo $dev/serial_connector
echo ---- OPEN SERIAL --------
socat -d -d pty,raw,echo=0,link=$dev/serial pty,raw,echo=0,link=$dev/serial.interface &
remember serial $!
sleep 1
echo

# the fifo seems to close better than the socat pty - or I don't know the
# setting for the socat pty that will make it close nicely like the fifo
# but maybe if there is a way, somebody will answer someday
# https://unix.stackexchange.com/questions/760016
sleep 1
cat > $dev/serial_connector < $dev/serial &
cat_pid=$!
remember cat $cat_pid
sleep .1
kill -0 $cat_pid
echo ---- start driver -------
$driver_script $driver_lib $dev/serial_connector $dev/uinput &
driver_id=$!
remember driver2 $driver_id
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
read stty_line < $dev/serial_connector
echo STTY: $stty_line
baud=$(echo $stty_line | xargs -n1 echo | grep -E '^[0-9]+$')
echo BAUD: $baud
# the serial port should not affect anything here but might need to exist
$interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $dev/serial_connector
echo ---- test all -----------
$interpreter $(dirname $0)/e2e.lua $(dirname $0)/lib.lua $firmware $helper $library $firmware_test_lua_lib $dev/serial $dev/serial.interface $dev/uinput $baud
kill -0 $driver_id
# we didn't save the id in a variable so we can look it up in the process list
socat_pid=$(echo $processes | xargs -n2 echo | grep -w serial | awk '{ print $2 }')
kill -0 $socat_pid
kill $socat_pid
sleep 2
set +e
kill -0 $driver_id
driver_running_result=$?
set -e
[ "$driver_running_result" = 1 ]
echo ---- E2E SUCCESS -----------
