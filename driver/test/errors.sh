#! /usr/bin/env bash

set -e

interpreter=$1
shift

driver_script=$(realpath $1)
shift
library=$(dirname $0)/library.lua

real_driver_lib=$(realpath $1)
shift

driver_lib=$(realpath $1)
shift

helper=$(realpath $1)

# so that it uses fake stty
export PATH="$(dirname $0)/path:$PATH"
stty_path=$(which stty)
echo using $stty_path
[ "$stty_path" == "$(dirname $0)/path/stty" ]

source $(dirname $0)/prep.sh

echo ---- OPEN FAKE UINPUT ---
mkfifo $dev/uinput
echo


echo ------------------ TEST ERRORS ------------------------
mkfifo $dev/serial
# complete coverage by trying out all the special error handling
function test-error {
    if [ "$3" = "" ]
    then
        _driver_lib=$driver_lib
    else
        _driver_lib=$3
    fi

    cat < $dev/uinput > /dev/null &
    remember $1-cat-1 $!
    cat < $dev/serial > /dev/null &
    remember $1-cat-2 $!
    set +e
    timeout 1.2 $driver_script $_driver_lib $dev/serial $dev/uinput
    stat=$?
    set -e
    sign=$2
    expectation="$stat $sign 124"
    echo $expectation for $1
    [ $expectation ]
}

test-error real-lib -ne $real_driver_lib
echo ^^^^^ test error ^^^^^^

test-error normal-start "="

rm $dev/uinput
mkdir $dev/uinput

test-error bad-uinput -ne
echo ^^^^^ test error ^^^^^^
echo ---- ERRORS SUCCESS -----------
