#! /usr/bin/env bash

set -e

# whatever you do, don't call this file coverage.sh
# I discovered that it gets left out of the coverage report

make check-format
make $@
make bash-tools
echo ----- END OF INSTRUMENTED BASH --------
