#! /usr/bin/env bash

set -e

fname=tmp/$(date | md5sum | cut -c-10)

echo xxx > $fname

bytes=$($1 $fname)

echo $bytes bytes waiting
[ "$bytes" = "$(wc -c $fname | awk '{ print $1}')" ]
