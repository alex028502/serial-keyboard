#! /usr/bin/env bash

set -e

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
    grep -E "$regex"
