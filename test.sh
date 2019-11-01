#!/bin/sh

set -x
set -e

# Test for link in readme
elixir test_readme.exs

# Test all parsers in lib/
find lib/ -type f -name "*.ex" -print0 | sort -z | xargs -0 -n 1 -t sh -x -e test_parser.sh
