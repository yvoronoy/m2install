#!/usr/bin/env bash
source tests/functional.sh
OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.7 --ee 2>error.log)

php bin/magento config:set system/backup/functionality_enabled 1

bin/magento setup:backup --db
tar --exclude=lib \
  --exclude=pub/index.php \
  --exclude=pub/media/catalog/* \
  --exclude=pub/media/* \
  --exclude=pub/media/backup/* \
  --exclude=pub/media/import/* \
  --exclude=pub/media/tmp/* \
  --exclude=pub/static/* \
  --exclude=var/* \
  --exclude=private \
  --exclude=tests \
  -czf var/backups/code.tar.gz .
  
tar --exclude=lib \
  --exclude=dev \
  --exclude=pub/index.php \
  --exclude=pub/media/catalog/* \
  --exclude=pub/media/* \
  --exclude=pub/media/backup/* \
  --exclude=pub/media/import/* \
  --exclude=pub/media/tmp/* \
  --exclude=pub/static/* \
  --exclude=var/* \
  --exclude=private \
  --exclude=tests \
  -czf var/backups/code2.tar.gz .

ls -A | grep -v var | xargs rm -rf
cp var/backups/* ./
rm -rf var

##################################
OUTPUT=$(${BIN_M2INSTALL} --code-dump code.tar.gz --force --quiet 2>&1);
assertContains "$OUTPUT" "The following directories are missing: lib" "Should be error, because directories are missing";
assertContains "$OUTPUT" "The following files are missing: pub/index.php" "Should be error, because files are missing";
assertContains "$OUTPUT" "Download missing files and directories from vanilla magento" "Should be help message";

########################################
rm -rf setup dev lib pub/index.php
OUTPUT=$(${BIN_M2INSTALL} --code-dump code2.tar.gz --force --quiet 2>&1);
assertContains "$OUTPUT" "The following directories are missing: dev lib" "Should be error, because directories are missing";
assertContains "$OUTPUT" "Download missing files and directories from vanilla magento" "Should be help message";

