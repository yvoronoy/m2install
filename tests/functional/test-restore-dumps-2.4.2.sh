#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.4.2 --es-host magento2elastic7 --es-port 9207 2>error.log)

php bin/magento config:set system/backup/functionality_enabled 1

php bin/magento setup:backup --code --db

mkdir dumps
cp var/backups/* dumps/
php bin/magento --no-interaction setup:uninstall
ls -A | grep -v dumps | xargs rm -rf
cp dumps/* ./
rm -rf dumps

RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f --quiet 2>error.log)

assertEqual $(ls app/etc/env.php.merchant) app/etc/env.php.merchant "Original file env.php.merchant has been created"

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI 2.4.2";
assertEqual "$EXPECTED" "$CURRENT" "Version should match"

assertNotContains "$RESTORE_OUTPUT" "Warning: A Search Engine has been switched from elasticsearch to mysql" "Magento 2.4.x should not switch search engine from ES to MySQL"

assertEqual "$(php bin/magento config:show web/unsecure/base_url)" "http://${CURRENT_DIR_NAME}.127.0.0.1.xip.io/pub/" "Base URL for 2.4.2 and higher must include /pub/"

