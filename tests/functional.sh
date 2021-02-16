#!/usr/bin/env bash
function assertEqual()
{
  local expected=${1:-}
  local current=${2:-}
  local message=${3:-}
  if [[ "$1" == "$2" ]]
  then
    printPassedMsg "$message"
    return 0;
  else
    printFailedMsg "$message" "$expected" "$current"
    exit 1;
  fi
}
function assertTrue()
{
  local expected=${1:-}
  local message=${2:-}
  if [[ "$expected" ]]
  then
    printPassedMsg "$message"
    return 0;
  else
    echo "[${message}] ===> Failed"
    echo "Should be true, but current [${expected}]"
    printFailedMsg "$message" "$expected" "FALSE"
    exit 1;
  fi
}

function assertContains()
{
  local text="${1:-}"
  local findText="${2:-}"
  local message="${3:-}"
  missingDirectories=$(echo "${text}" | grep -o "$findText");
  if [ "$missingDirectories" ] 
  then
    printPassedMsg "$message"
  else 
    printFailedMsg "$message" "$findText" ""
    exit 1;
  fi
}

function assertNotContains()
{
  local text="${1:-}"
  local findText="${2:-}"
  local message="${3:-}"
  missingDirectories=$(echo "${text}" | grep -o "$findText");
  if [ "$missingDirectories" ] 
  then
    printFailedMsg "$message" "$findText" ""
    exit 1;
  else 
    printPassedMsg "$message"
  fi
}

function printPassedMsg()
{
  local message="$@"
  echo "[${message}] ===> Passed"
}

function printFailedMsg()
{
  local message=$1
  local expected=$2
  local actual=$3
  echo "[${message}] ===> Failed"
  echo "Expected [${expected}] but current [${actual}]"
  exit 1;
}


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
SANDBOX_PATH="/var/www/html/ci-build-$$"
BIN_M2INSTALL=$(pwd)/m2install.sh;

if [ ! -d "${SANDBOX_PATH}" ]
then
    echo "Creating tmp directory ${SANDBOX_PATH}"
    mkdir ${SANDBOX_PATH}
fi
cd ${SANDBOX_PATH}

trap '$BIN_M2INSTALL -f --quiet --uninstall; rm -rf -- "$SANDBOX_PATH"; echo "$SANDBOX_PATH" is deleted.' EXIT

