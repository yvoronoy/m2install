#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.6 2>error.log)

php bin/magento config:set system/backup/functionality_enabled 1

php bin/magento setup:backup --code --db


mkdir dumps
cp var/backups/* dumps/
php bin/magento --no-interaction setup:uninstall
ls -A | grep -v dumps | xargs rm -rf
cp dumps/* ./
rm -rf dumps

RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f 2>error.log)

assertEqual $(ls app/etc/env.php.merchant) app/etc/env.php.merchant "Original file env.php.merchant has been created"

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI 2.3.6";
assertEqual "$EXPECTED" "$CURRENT" "Version should match"

assertContains "$RESTORE_OUTPUT" "Warning: A Search Engine has been switched from elasticsearch to mysql"
assertContains "$RESTORE_OUTPUT" "http://${CURRENT_DIR_NAME}.127.0.0.1.xip.io/admin" "Test Base URL to admin"

