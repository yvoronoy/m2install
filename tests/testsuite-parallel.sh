#!/usr/bin/env bash

echo "Run new testsuite"
parallel --shuf --halt now,fail=1 bash tests/functional/{} ::: $(ls tests/functional)
