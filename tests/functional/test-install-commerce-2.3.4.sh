#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.4 --ee 2>error.log)

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI 2.3.4";

artifactFile=$(mktemp /tmp/ci-artifacts.XXXXXXXXX)
echo "$OUTPUT" > $artifactFile
echo "Artifacts: $artifactFile"

assertEqual "$EXPECTED" "$CURRENT" "Version should match"
assertContains "$OUTPUT" "Response code: 200" "Response Code Must be 200"

