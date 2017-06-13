#!/usr/bin/env bash
source tests/functional.sh
bin/magento setup:backup --db
tar --exclude=lib \
  --exclude=index.php \
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
  --exclude=index.php \
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
missingDirectories=$(echo "${OUTPUT}" | grep -o "The following directories are missing: lib");
missingFiles=$(echo "${OUTPUT}" | grep -o "The following files are missing: index.php");
helpMessageHowToFix=$(echo "${OUTPUT}" | grep -o "Download missing files and directories from vanilla magento");
assertTrue "$missingDirectories" "Should be error, because directories are missing";
assertTrue "$missingFiles" "Should be error, because files are missing";
assertTrue "$helpMessageHowToFix" "Should be help message";

########################################
rm -rf setup dev lib index.php pub/index.php
OUTPUT=$(${BIN_M2INSTALL} --code-dump code2.tar.gz --force --quiet 2>&1);
missingDirectories=$(echo "${OUTPUT}" | grep -o "The following directories are missing: dev lib");
missingFiles=$(echo "${OUTPUT}" | grep -o "The following files are missing: index.php pub/index.php");
helpMessageHowToFix=$(echo "${OUTPUT}" | grep -o "Download missing files and directories from vanilla magento");
assertTrue "$missingDirectories" "Should be error, because directories are missing";
assertTrue "$missingFiles" "Should be error, because files are missing";
assertTrue "$helpMessageHowToFix" "Should be help message";