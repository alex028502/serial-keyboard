#! /usr/bin/env bash

set -e

pid=$1
shift
while kill -0 $pid
do
    echo "$@"
    sleep 0.1
done
