#! /usr/bin/env bash

library_path=$1
shift

library_dir=$(dirname $library_path)
library_name=$(basename $library_path | sed 's/\.so//')

script_name=
