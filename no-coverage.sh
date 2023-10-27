#! /usr/bin/env bash

for filepath in $@
do
  echo "SF:$filepath"
  num_lines=$(wc -l < "$filepath")
  for i in $(seq $num_lines)
  do
    echo "DA:$i,0"
  done
  echo "LF:$num_lines"
  echo "LH:0"
  echo "end_of_record"
done
