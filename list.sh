#! /usr/bin/env bash

set -e

if [ "$1" == "-all" ]
then
    binfilter=cat
    shift
else
    binfilter="grep -vw jpg"
fi

if [ "$1" == "" ]
then
    regex="\."
else
    regex="(^|/|\\.)($(echo $@ | sed 's/ /\|/g'))$"
fi

# if it has a space it's not a source file
find . -type f |
    grep -v '.git' |
    sed 's/ /SPACE/' |
    grep -v SPACE |
    xargs git check-ignore -vn |
    grep '::' |
    cut -c4- |
    $binfilter |
    grep -E "$regex"
