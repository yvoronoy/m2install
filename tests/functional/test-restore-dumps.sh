#!/usr/bin/env bash
source tests/functional.sh
${BIN_M2INSTALL} --force --source composer --ee -v 2.1.5 --quiet
bin/magento setup:backup --code --db
ls -A | grep -v var | xargs rm -rf
cp var/backups/* ./
rm -rf var

${BIN_M2INSTALL} -f --quiet

assertEqual $(ls app/etc/env.php.merchant) app/etc/env.php.merchant "Original file env.php.merchant has been created"

CURRENT="$(php bin/magento -V --no-ansi)";
EXPECTED="Magento CLI version 2.1.5";
assertEqual "$EXPECTED" "$CURRENT" "Version should match"

