#!/usr/bin/env bash
function assertEqual()
{
  local expected=${1:-}
  local current=${2:-}
  local message=${3:-}
  if [[ "$1" == "$2" ]]
  then
    echo "[${message}] ===> Passed"
    return 0;
  else
    echo "[${message}] ===> Failed"
    echo "Expected [${expected}] but current [${current}]"
    exit 1;
  fi
}
function assertTrue()
{
  local expected=${1:-}
  local message=${2:-}
  if [[ "$expected" ]]
  then
    echo "[${message}] ===> Passed"
    return 0;
  else
    echo "[${message}] ===> Failed"
    echo "Should be true, but current [${expected}]"
    exit 1;
  fi
}


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
SANDBOX_PATH=${ROOT}/sandbox
BIN_M2INSTALL=$(pwd)/m2install.sh;

if [ ! -d "${SANDBOX_PATH}" ]
then
    mkdir ${SANDBOX_PATH}
fi
cd ${SANDBOX_PATH}


