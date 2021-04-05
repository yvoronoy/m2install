#!/usr/bin/env bash
source tests/functional.sh

export M2INSTALL_CSV_LOG="$SANDBOX_PATH/m2install.csv"
OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.5 2>error.log)

CURRENT="$(cat $M2INSTALL_CSV_LOG)"

assertContains "$CURRENT" "datetime, mode, home_response_code, home_url, admin_response_code, admin_url, duration" "Csv File header is not match"
assertContains "$CURRENT" "install, [0,2]00, http://${CURRENT_DIR_NAME}.127.0.0.1.xip.io/, [0,2,3]0[0,2], http://${CURRENT_DIR_NAME}.127.0.0.1.xip.io/admin, [0-9]*" "CSV File row is not match"

