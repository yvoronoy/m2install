#!/usr/bin/env bash
source tests/functional.sh

CURRENT_DIR_NAME=$(basename "$(pwd)")

BP="dev/test-$$"
mkdir -p "$BP"
cd "$BP"
CONFIG_BP_VALUE="BASE_PATH=$BP"
echo "$CONFIG_BP_VALUE" > ../.m2install.conf
echo "HTTP_HOST=http://$CURRENT_DIR_NAME.127.0.0.1.nip.io/" >> ../.m2install.conf

echo 'SEARCH_ENGINE_ELASTICSEARCH7_HOST=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH7_PORT=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH6_HOST=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH6_PORT=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH5_HOST=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH5_PORT=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH2_HOST=' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH2_PORT=' >> ../.m2install.conf

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.4.2 --ee 2>error.log)

assertContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is required for version 2.4.x." "ES is required"
assertContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is not available on localhost:9200." "ES is localhost by default"
assertContains "$([ -f error.log ] && cat error.log)" "Use parameters to specify Elasticsearch --es-host <HOST> --es-port <PORT>" "Show hint for 2.4.x to enable ES"

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.4.2 --ee --es-host es --es-port 9202 2>error.log)
assertContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is not available on es:9202." "Es is not available"

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.4.2 --ee --es-host magento2elastic7 --es-port 9207 2>error.log)
assertNotContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is required for version 2.4.x." "No Error ES is required"
assertContains "$OUTPUT" "ElasticSearch is available on magento2elastic7:9207." "ElasticSearch is available magento2elastic7:9207"
assertContains "$OUTPUT" "Response code: [0,2]00" "Response Code Must be 200"

assertContains "$OUTPUT" "Magento_TwoFactorAuth is being disabled" "Magento_TwoFactorAuth is being disabled"
assertNotContains "$OUTPUT" "MarkShust_DisableTwoFactorAuth is being disabled" "MarkShust_DisableTwoFactorAuth MUST be empty output"

