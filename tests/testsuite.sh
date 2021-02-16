#!/usr/bin/env bash

for i in tests/functional/*
do
  echo -n "=======> Run test: $i "
  TEST_OUTPUT="$(bash $i)"
  containsFailed=$(echo "${TEST_OUTPUT}" | grep -o "Failed");
  if [ "$containsFailed" ]
  then
    echo "- Failed"
    echo "$TEST_OUTPUT"
    exit 128
  else
    echo "- Passed"
  fi
done
