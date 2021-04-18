#!/usr/bin/env bash

echo "Run new testsuite"

parallel --eta --shuf -j3 --halt soon,fail=1 bash tests/functional/{} ::: $(ls tests/functional)
