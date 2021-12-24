#!/usr/bin/env bash

echo "Run new testsuite"
JOBS="${1:-3}"
parallel --eta --shuf -j$JOBS --halt now,fail=1 bash tests/functional/{} ::: $(ls tests/functional)
