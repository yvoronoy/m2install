#!/usr/bin/env bash

echo "Run new testsuite"

parallel --bar -j4 --halt soon,fail=1 bash tests/functional/{} ::: $(ls tests/functional)
