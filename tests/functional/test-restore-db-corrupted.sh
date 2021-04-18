#!/usr/bin/env bash
source tests/functional.sh

touch php72.code.tar.gz
touch php72.db.sql.gz

RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f 2>error.log)
ERROR_OUTPUT="$(cat error.log)"

assertContains "$ERROR_OUTPUT" "MySQL DB Dump is corrupt. For on-prem, please request a new MySQL Dump from the merchant and ensure it is created using the mysqldump utility and not bin/magento support:db:backup. For Magento-Cloud, please regenerate a new MySQL Dump by using the ZD Dump Widget / cloud-teleport." "Empty DB Dump returns error"

# Test DB Dumps is not empty
rm php72.db.sql.gz
rm php72.code.tar.gz
[ -f error.log ] && rm error.log

touch php72.code.tar.gz
echo "123456" > php72.db.sql
gzip php72.db.sql

RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f 2>error.log)
ERROR_OUTPUT="$(cat error.log)"

assertContains "$ERROR_OUTPUT" "Code Dump is corrupt. For on-prem, please request a new Code Dump from the merchant. For Magento-Cloud, please regenerate a new MySQL Dump by using the ZD Dump Widget / cloud-teleport." "Empty Code Dump returns error"

# Test Code Dumps is not empty
rm php72.db.sql.gz
rm php72.code.tar.gz
[ -f error.log ] && rm error.log

mkdir app
echo "Test Application" > app/bootstrap.php

tar czf php72.code.tar.gz app
echo "123456" > php72.db.sql
gzip php72.db.sql

RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f 2>error.log)
ERROR_OUTPUT="$(cat error.log)"

assertNotContains "$ERROR_OUTPUT" "Code Dump is corrupt. For on-prem, please request a new Code Dump from the merchant. For Magento-Cloud, please regenerate a new MySQL Dump by using the ZD Dump Widget / cloud-teleport." "Empty Code Dump returns error"


