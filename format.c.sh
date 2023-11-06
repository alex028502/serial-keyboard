#! /usr/bin/env bash

set -e

exec clang-format --style=Chromium -Werror "$@"
