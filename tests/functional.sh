#!/usr/bin/env bash
function assertEqual()
{
  local expected=${1:-}
  local current=${2:-}
  local message=${3:-}
  if [[ "$1" == "$2" ]]
  then
    echo "===> Passed"
    return 0;
  else
    echo "Test [${message}] Failed"
    echo "Expected [${expected}] but current [${current}]"
    exit 1;
  fi
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
SANDBOX_PATH=${ROOT}/sandbox
BIN_M2INSTALL=$(pwd)/m2install.sh;

for file in ${ROOT}/functional/*
do
    rm -rf ${SANDBOX_PATH}
    mkdir ${SANDBOX_PATH}
    cd ${SANDBOX_PATH}
    echo -n "Run: $(basename $file)";
    . $file
done


