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


echo ------------------ TEST ERRORS ------------------------
mkfifo $dev/serial
# complete coverage by trying out all the special error handling
function test-error {
    cat < $dev/uinput > /dev/null &
    remember $1-cat-1 $!
    cat < $dev/serial > /dev/null &
    remember $1-cat-2 $!
    set +e
    timeout 1.2 $driver_script $driver_lib $dev/serial $dev/uinput
    stat=$?
    set -e
    sign=$2
    expectation="$stat $sign 124"
    echo $expectation for $1
    [ $expectation ]
}

ioctl_code=UI_SET_KEYBIT
ioctl_code_number=$($interpreter $(dirname $0)/lookup.lua $library $helper $ioctl_code)
echo checking that a failure of $ioctl_code\($ioctl_code_number\) causes failure
IOCTL_ERROR=$ioctl_code_number test-error $ioctl_code -ne

test-error normal-start "="

rm $dev/uinput
mkdir $dev/uinput

test-error bad-uinput -ne
echo ^^^^^ test error ^^^^^^
echo ---- ERRORS SUCCESS -----------
