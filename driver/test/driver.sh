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
sleep 0.2
echo see if it started:
kill -0 $driver_id
echo ---- test driver init ---
# the serial port should not affect anything here but might need to exist
timeout 10 $interpreter $(dirname $0)/init.lua $helper $library $dev/uinput $dev/serial $baud
echo ---- test driver --------
$interpreter $(dirname $0)/driver.lua $(dirname $0)/lib.lua $helper $library $dev/serial $dev/uinput $baud
echo ---- clean up ------------
rm $dev/serial
timer=""
while kill -0 $driver_id
do
    timer="x$timer"
    c="$(echo $timer | wc -c)"
    # maximum two seconds
    # because the program actually sleeps 1 second after the tty is closed
    echo waiting for driver to shut down nicely $c
    [ "$c" != 20 ]
    sleep 0.1
done
echo ---- SUCCESS -----------
