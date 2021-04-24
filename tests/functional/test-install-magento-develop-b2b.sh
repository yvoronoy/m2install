#!/usr/bin/env bash
source tests/functional.sh

CURRENT_DIR_NAME=$(basename "$(pwd)")

OUTPUT=$(${BIN_M2INSTALL} --force --source git -v 2.4-develop --ee --b2b --es-host magento2elastic7 --es-port 9207 2>error.log)
assertNotContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is required for version 2.4.x." "No Error ES is required"
assertContains "$OUTPUT" "ElasticSearch is available on magento2elastic7:9207." "ElasticSearch is available magento2elastic7:9207"
assertContains "$OUTPUT" "Response code: [0,2]00" "Response Code Must be 200"
assertContains "$(php bin/magento module:status Magento_SharedCatalog)" "Module is enabled" "B2B Module is enabled"

OUTPUT=$(${BIN_M2INSTALL} --force --ee --b2b --es-host magento2elastic7 --es-port 9207 2>error.log)
assertNotContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is required for version 2.4.x." "No Error ES is required"
assertContains "$OUTPUT" "ElasticSearch is available on magento2elastic7:9207." "ElasticSearch is available magento2elastic7:9207"
assertContains "$OUTPUT" "Response code: [0,2]00" "Response Code Must be 200"
assertContains "$(php bin/magento module:status Magento_SharedCatalog)" "Module is enabled" "B2B Module is enabled"
