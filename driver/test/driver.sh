#! /usr/bin/env bash

set -e

driver_script=$(realpath $1)
shift
library=$(dirname $0)/library.lua

interpreter=lua5.4

driver_lib=$(realpath $1)
shift

helper=$(realpath $1)
shift

# just to make sure that whatever is configured in the baud program is what gets
# used when configuring the tty with stty
baud_file=$(dirname $driver_script)/baud.txt
baud=$(cat $baud_file)

# so that it uses fake stty
export PATH="$(dirname $0)/path:$PATH"
stty_path=$(which stty)
echo using $stty_path
[ "$stty_path" == "$(dirname $0)/path/stty" ]

source $(dirname $0)/prep.sh

echo
echo ---- TEST DRIVER --------
echo ---- setup --------------
mkfifo $dev/uinput
mkfifo $dev/serial
echo ---- start driver -------
SERIAL_KEYBOARD_DEBUG=TRUE $driver_script $driver_lib $dev/serial $dev/uinput &
driver_id=$!
remember driver $driver_id
sleep 0.2
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
# the serial port should not affect anything here but might need to exist
timeout 10 $interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $dev/serial $baud
echo ---- test driver --------
$interpreter $(dirname $0)/driver.lua $(dirname $0)/lib.lua $helper $library $dev/serial $dev/uinput $baud $driver_id
echo ---- SUCCESS -----------
