#!/usr/bin/env bash
source tests/functional.sh

CURRENT_DIR_NAME=$(basename "$(pwd)")

mkdir -p dev/joe
cd dev/joe

echo 'BASE_PATH="dev/joe"' > ../.m2install.conf
echo "HTTP_HOST=http://$CURRENT_DIR_NAME.127.0.0.1.xip.io/" >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH7_HOST="magento2elastic7"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH7_PORT="9207"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH6_HOST="magento2elastic6"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH6_PORT="9206"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH5_HOST="magento2elastic5"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH5_PORT="9205"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH2_HOST="magento2elastic"' >> ../.m2install.conf
echo 'SEARCH_ENGINE_ELASTICSEARCH2_PORT="9200"' >> ../.m2install.conf

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.4.2 --ee --es-host non-existing-host --es-port 92111 2>error.log)
assertContains "$([ -f error.log ] && cat error.log)" "ElasticSearch is not available on non-existing-host:92111." "Es is not available"

OUTPUT="$(${BIN_M2INSTALL} --force -s composer -v 2.4.2 2>error.log)"

artifactFile="$(mktemp /tmp/ci-artifacts.XXXXXXXXX)"
echo "$OUTPUT" > $artifactFile
echo "Artifacts: $artifactFile"

searchEngine="$(php bin/magento config:show catalog/search/engine)"
searchHost="$(php bin/magento config:show catalog/search/elasticsearch7_server_hostname)"
searchPort="$(php bin/magento config:show catalog/search/elasticsearch7_server_port)"
searchPrefix="$(php bin/magento config:show catalog/search/elasticsearch7_index_prefix)"
assertEqual "$searchEngine" "elasticsearch7"
assertEqual "$searchHost" "magento2elastic7"
assertEqual "$searchPort" "9207"
assertEqual "$searchPrefix" "root_joe"

# UPDATE ES CONFIG
php bin/magento config:set catalog/search/engine elasticsearch6
php bin/magento config:set catalog/search/elasticsearch6_server_hostname testhost
php bin/magento config:set catalog/search/elasticsearch6_server_port 8888
php bin/magento config:set catalog/search/elasticsearch6_index_prefix root_joe
searchEngine="$(php bin/magento config:show catalog/search/engine)"
searchHost="$(php bin/magento config:show catalog/search/elasticsearch6_server_hostname)"
searchPort="$(php bin/magento config:show catalog/search/elasticsearch6_server_port)"
searchPrefix="$(php bin/magento config:show catalog/search/elasticsearch6_index_prefix)"
assertEqual "$searchEngine" "elasticsearch6"
assertEqual "$searchHost" "testhost"
assertEqual "$searchPort" "8888"
assertEqual "$searchPrefix" "root_joe"

# Restore Dumps
php bin/magento config:set system/backup/functionality_enabled 1
php bin/magento setup:backup --code --db
mkdir dumps
cp var/backups/* dumps/
php bin/magento --no-interaction setup:uninstall
ls -A | grep -v dumps | xargs rm -rf
cp dumps/* ./
rm -rf dumps
RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f --quiet 2>error.log)

assertNotContains "$RESTORE_OUTPUT" "Warning: A Search Engine has been switched from elasticsearch to mysql" "Magento 2.4.x should not switch search engine from ES to MySQL"
searchEngine="$(php bin/magento config:show catalog/search/engine)"
searchHost="$(php bin/magento config:show catalog/search/elasticsearch6_server_hostname)"
searchPort="$(php bin/magento config:show catalog/search/elasticsearch6_server_port)"
searchPrefix="$(php bin/magento config:show catalog/search/elasticsearch6_index_prefix)"
assertEqual "$searchEngine" "elasticsearch6"
assertEqual "$searchHost" "magento2elastic6"
assertEqual "$searchPort" "9206"
assertEqual "$searchPrefix" "root_joe"
