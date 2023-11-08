#! /usr/bin/env bash

set -e

interpreter=lua5.4
lib=$(dirname $0)/library.lua
$interpreter $(dirname $0)/meta.lua $lib $@
