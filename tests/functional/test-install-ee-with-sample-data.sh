#!/usr/bin/env bash
source tests/functional.sh

${BIN_M2INSTALL} --force --source composer --ee -v 2.1.5 --sample-data yes --quiet

CURRENT_RESULT=$(cat composer.json | grep -o module-cms-sample-data)

assertEqual "module-cms-sample-data" "${CURRENT_RESULT}" "Sample Data dependencies has been added to composer.json"
