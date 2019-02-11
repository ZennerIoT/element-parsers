#!/bin/sh

set -x
set -e

# Test all parsers in lib/
find lib/ -type f -print0 | xargs -0 -n 1 -t sh -x -e test_parser.sh
