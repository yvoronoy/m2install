#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source git -v 2.4.2 --ee --es-host magento2elastic6 --es-port 9206 2>error.log)
assertNotContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is required for version 2.4.x." "No Error ES is required"
assertContains "$OUTPUT" "ElasticSearch is available on magento2elastic6:9206." "ElasticSearch is available magento2elastic6:9206"
assertContains "$(bin/magento config:show catalog/search/engine)" "elasticsearch6" "A search engine must be elasticsearch6"
