#! /usr/bin/env bash

set -e

export ORIGINAL_LUA_EXE_PATH="$(which lua5.4)"

# get the full path to bin
cd $(dirname $0)
export PATH="$PWD/bin:$PATH"
cd - > /dev/null

coverage_file="$1"
shift

if [ "$coverage_file" = "-" ]
then
    # should be used when it is in a subdirtory
    # or when a failure is expected
    exec "$@"
else
    "$@"
    luacov -r lcov
    mv luacov.report.out "$coverage_file"
fi
