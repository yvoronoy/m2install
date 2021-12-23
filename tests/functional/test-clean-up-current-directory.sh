#!/usr/bin/env bash
source tests/functional.sh

cd ~
pwd="$(pwd)"
OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.7 --ee 2>error.log)

assertContains "$([ -f error.log ] && cat error.log)" "Current Directory is home" "We should never delete home directory"
cd -

