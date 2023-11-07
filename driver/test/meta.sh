#! /usr/bin/env bash

set -e

interpreter=lua5.4
lib=$(dirname $0)/library.lua

test_code=EV_KEY
actual_value=$($interpreter $(dirname $0)/lookup.lua $lib $@ $test_code)
echo got $actual_value for $test_code
[ 1 = "$actual_value" ]

$interpreter $(dirname $0)/meta.lua $lib $@
