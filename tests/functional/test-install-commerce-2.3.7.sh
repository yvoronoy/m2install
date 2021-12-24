#!/usr/bin/env bash
source tests/functional.sh
export M2INSTALL_CSV_LOG="$SANDBOX_PATH/m2install.csv"
OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.7 --ee 2>error.log)

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI 2.3.7";

artifactFile=$(mktemp /tmp/ci-artifacts.XXXXXXXXX)
echo "$OUTPUT" > $artifactFile
echo "Artifacts: $artifactFile"

assertEqual "$EXPECTED" "$CURRENT" "Version should match"
assertContains "$OUTPUT" "http://${CURRENT_DIR_NAME}.127.0.0.1.nip.io/admin" "Test Base URL to admin"
assertContains "$OUTPUT" "Response code: [0,2]00" "Response Code Must be 200"

assertNotContains "$OUTPUT" "Magento_TwoFactorAuth is being disabled" "Magento_TwoFactorAuth MUST be empry output"
assertNotContains "$OUTPUT" "MarkShust_DisableTwoFactorAuth is being disabled" "MarkShust_DisableTwoFactorAuth MUST be empty output"

# Test Logging
CURRENT="$(cat $M2INSTALL_CSV_LOG)"
assertContains "$CURRENT" "datetime, mode, home_response_code, home_url, admin_response_code, admin_url, duration, user, dir, script, args" "Csv File header is not match"
assertContains "$CURRENT" "install, [0,2]00, http://${CURRENT_DIR_NAME}.127.0.0.1.nip.io/, [0,2,3]0[0,2], http://${CURRENT_DIR_NAME}.127.0.0.1.nip.io/admin, [0-9]*, $(whoami), $(pwd), $BIN_M2INSTALL, \"--force --source composer -v 2.3.7\"" "CSV File row is not match"

