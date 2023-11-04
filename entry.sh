#! /usr/bin/env bash

set -e

# whatever you do, don't call this file coverage.sh
# I discovered that it gets left out of the coverage report

make check-format

# this one has some C in it but for now it is covered somewhere
# and since there are gonna be changes let's just do this here
# instead of opening an lcov section
make baud-check

make $@
make bash-tools
echo ----- END OF INSTRUMENTED BASH --------
