#! /usr/bin/env bash

set -e

interpreter=$1
shift

test_code=EV_KEY
actual_value=$($interpreter $(dirname $0)/lookup.lua $@ $test_code)
echo got $actual_value for $test_code
[ 1 = "$actual_value" ]
