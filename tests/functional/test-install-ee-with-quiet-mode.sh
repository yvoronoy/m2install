#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.7 --ee --quiet)

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI 2.3.7";
assertEqual "$EXPECTED" "$CURRENT" "Version should match"

assertEqual "" "${OUTPUT}" "Should be without any output in quiet mode"
assertContains "$CURRENT" "2.3.7" "Current Version MUST be 2.3.7"
