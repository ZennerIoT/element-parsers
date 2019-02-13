#!/bin/sh

cd parser_sdk || exit 255 # Exit code for xargs

mix run ../test_parser.exs "../$@" || exit 255 # Exit code for xargs

