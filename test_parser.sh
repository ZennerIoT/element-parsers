#!/bin/sh

elixir --warnings-as-errors test_parser.exs "$@" || exit 255 # Exit code for xargs
