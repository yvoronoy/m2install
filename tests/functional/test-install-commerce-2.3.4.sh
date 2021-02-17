#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.4 --ee 2>error.log)

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI 2.3.4";

artifactFile=$(mktemp /tmp/ci-artifacts.XXXXXXXXX)
echo "$OUTPUT" > $artifactFile
echo "Artifacts: $artifactFile"

assertEqual "$EXPECTED" "$CURRENT" "Version should match"
assertEqual "$(php bin/magento config:show web/unsecure/base_url)" "http://${CURRENT_DIR_NAME}.127.0.0.1.xip.io/"
assertContains "$OUTPUT" "Response code: 200" "Response Code Must be 200"

assertNotContains "$OUTPUT" "Magento_TwoFactorAuth is being disabled" "Magento_TwoFactorAuth MUST be empry output"
assertNotContains "$OUTPUT" "MarkShust_DisableTwoFactorAuth is being disabled" "MarkShust_DisableTwoFactorAuth MUST be empty output"

