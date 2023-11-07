#! /usr/bin/env bash

set -e

fname=/tmp/$(date | md5sum | cut -c-10)

echo xxx > $fname
exe=$(readlink -f $1) # to get a ./ if needed
bytes=$($exe $fname)

echo $bytes bytes waiting
[ "$bytes" = "$(wc -c $fname | awk '{ print $1}')" ]
