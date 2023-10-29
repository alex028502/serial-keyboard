#! /usr/bin/env bash

set -e

function wordcount {
    sed 's/"[^"]*"//g' $2 | sed "s/'[^']*'//g" | sed 's/--.*$//' | grep -o -w $1 | wc -l
}

echo checking $@

e=0
for f in $@
do
    if_count=$(wordcount if $f)
    else_count=$(wordcount else $f)
    if [ "$if_count" = "$else_count" ]
    then
        continue
    fi
    e=1
    echo $f:1:1: if/else mismatch $if_count ifs and $else_count elses
done
exit $e
