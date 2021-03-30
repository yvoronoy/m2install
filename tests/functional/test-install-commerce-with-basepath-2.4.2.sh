#!/usr/bin/env bash
source tests/functional.sh

CURRENT_DIR_NAME=$(basename "$(pwd)")

mkdir -p dev/joe
cd dev/joe

echo 'BASE_PATH="dev/joe"' > ../.m2install.conf
echo "HTTP_HOST=http://$CURRENT_DIR_NAME.127.0.0.1.xip.io/" >> ../.m2install.conf

OUTPUT="$(${BIN_M2INSTALL} --force -s composer -v 2.4.2 --es-host magento2elastic7 --es-port 9207 2>error.log)"

artifactFile="$(mktemp /tmp/ci-artifacts.XXXXXXXXX)"
echo "$OUTPUT" > $artifactFile
echo "Artifacts: $artifactFile"

assertContains "$(php bin/magento config:show web/unsecure/base_url)" "dev/joe/pub/" "Base URL does NOT contain dev/joe/pub/"
assertEqual "$(php bin/magento config:show web/unsecure/base_url)" "http://${CURRENT_DIR_NAME}.127.0.0.1.xip.io/dev/joe/pub/" "Base URL is not correct"
assertContains "$OUTPUT" "Response code: [0,2]00" "Response Code Must be 200"

