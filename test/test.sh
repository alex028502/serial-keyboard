#! /usr/bin/env bash

set -e

driver_script=$(realpath $1)
library=$(realpath $2)
interpreter="$3"
driver_lib=$(realpath $4)
firmware=$(realpath $5)
helper=$(realpath $6)
# TODO: I don't really know what is getting compared to what with baud anymore
# need to clean it up soon
baud_program=$(realpath $7)
baud=$($baud_program)

# so that it uses fake stty
export PATH="$(dirname $0)/path:$PATH"
stty_path=$(which stty)
echo using $stty_path
[ "$stty_path" == "$(dirname $0)/path/stty" ]

# we could probably just pass in the path to the firmware project but we need
# to change a few thigs about the make file or start moving to bash from make
firmware_test_lib=$(dirname $firmware)/lib.sh

echo ----------------------- UNIT --------------------------
$interpreter $(dirname $0)/keyevent.lua $library $helper
echo unit passed
echo ----------------------- LOOKUP ------------------------
test_code=EV_KEY
actual_value=$($interpreter $(dirname $0)/lookup.lua $library $helper $test_code)
echo got $actual_value for $test_code
[ 1 = "$actual_value" ]
echo
echo ----------------------- E2E PREP ----------------------
source $firmware_test_lib

function cleanup {
    # wrapper so that we can see in the coverage report that it gets run
    _cleanup
}

trap cleanup EXIT
echo ---- OPEN FAKE UINPUT ---
mkfifo $dev/uinput
echo
echo ---- COVERAGE OPTIONS ---
# this one has one more option when in coverage mode
echo using interpreter $i from $interpreter
echo \(in cases where program does not end cleanly\)

echo
echo ---- TEST DRIVER --------
mkfifo $dev/serial
echo ---- start driver -------
SERIAL_KEYBOARD_DEBUG=TRUE $interpreter $driver_script $driver_lib $dev/serial $dev/uinput $baud_program &
driver_id=$!
remember driver $driver_id
sleep 1
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
# the serial port should not affect anything here but might need to exist
$interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $dev/serial $baud
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
# will remain in the process list
# so will try to TERM it again in cleanup

echo
echo ---- TEST E2E -----------
# two way pty is still needed for this test because the fake arduino will open
# the serial path for read and write - and the driver will also want to open
# for read - so a single path won't work
mkfifo $dev/serial_connector
open-serial
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
$interpreter $driver_script $driver_lib $dev/serial_connector $dev/uinput $baud_program &
driver_id=$!
remember driver2 $driver_id
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
# the serial port should not affect anything here but might need to exist
$interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $dev/serial_connector $baud
echo ---- test all -----------
$interpreter $(dirname $0)/e2e.lua $(dirname $0)/lib.lua $firmware $helper $library $dev/serial $dev/serial.interface $dev/uinput $baud
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
echo ----------------------- ERRORS ------------------------
mkfifo $dev/serial
# complete coverage by trying out all the special error handling
function test-error {
    cat < $dev/uinput > /dev/null &
    remember $1-cat-1 $!
    cat < $dev/serial > /dev/null &
    remember $1-cat-2 $!
    set +e
    timeout 1.2 $interpreter $driver_script $driver_lib $dev/serial $dev/uinput $baud_program
    stat=$?
    set -e
    sign=$2
    expectation="$stat $sign 124"
    echo $expectation for $1
    [ $expectation ]
}

for ioctl_code in UI_SET_EVBIT UI_SET_KEYBIT UI_DEV_SETUP UI_DEV_CREATE
do
    ioctl_code_number=$($interpreter $(dirname $0)/lookup.lua $library $helper $ioctl_code)
    echo checking that a failure of $ioctl_code\($ioctl_code_number\) causes failure
    IOCTL_ERROR=$ioctl_code_number test-error $ioctl_code -ne
done

test-error normal-start "="

rm $dev/uinput
mkdir $dev/uinput

test-error bad-uinput -ne
echo ^^^^^ test error ^^^^^^
echo ---- SUCCESS -----------
