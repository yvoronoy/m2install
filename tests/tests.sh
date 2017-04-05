#!/usr/bin/env bash

testSampleTest() {
  # Load m2install.sh for testing
  . m2install.sh --help

  echo "Executing some asserts..."

}

# Execute shunit2 to run the tests
. shunit2-master/source/2.1/src/shunit2 
