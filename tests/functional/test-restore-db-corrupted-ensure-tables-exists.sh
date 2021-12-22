#!/usr/bin/env bash
source tests/functional.sh

OUTPUT=$(${BIN_M2INSTALL} --force --source composer -v 2.3.7 2>error.log)
export DB_NAME=$(grep [\']db[\'] -A 20 app/etc/env.php | grep dbname | head -n1 | sed "s/.*[=][>][ ]*[']//" | sed "s/['][,]//");
export MYSQL_HOST=$(grep [\']db[\'] -A 20 app/etc/env.php | grep host | head -n1 | sed "s/.*[=][>][ ]*[']//" | sed "s/['][,]//");
export DB_USER=$(grep [\']db[\'] -A 20 app/etc/env.php | grep username | head -n1 | sed "s/.*[=][>][ ]*[']//" | sed "s/['][,]//");
export MYSQL_PWD=$(grep [\']db[\'] -A 20 app/etc/env.php | grep password | head -n1 | sed "s/.*[=][>][ ]*[']//" | sed "s/['][,]//");
mysql -h $MYSQL_HOST -u $DB_USER --password=$MYSQL_PWD $DB_NAME -e "DELETE FROM store"
mysql -h $MYSQL_HOST -u $DB_USER --password=$MYSQL_PWD $DB_NAME -e "DELETE FROM store_website"

(mysqldump --no_data --routines --force --single-transaction --create-options --extended-insert --set-charset --quick --add-drop-table -h $MYSQL_HOST -u $DB_USER --password=$MYSQL_PWD $DB_NAME | sed -e 's/DEFINER[ ]*=[ ]*[Backup dumps without backup.sh script^*]*\*/\*/' && \
mysqldump --force --skip-add-drop-table --no-create-info --single-transaction --extended-insert --quick \
 --ignore-table=$DB_NAME.cache_tag \
 --ignore-table=$DB_NAME.sales_bestsellers_aggregated_daily \
 --ignore-table=$DB_NAME.core_cache \
 --ignore-table=$DB_NAME.magento_logging_event \
 --ignore-table=$DB_NAME.magento_logging_event_changes \
 --ignore-table=$DB_NAME.customer_log \
 --ignore-table=$DB_NAME.report_event \
 --ignore-table=$DB_NAME.report_viewed_product_index \
 --ignore-table=$DB_NAME.search_query \
 --ignore-table=$DB_NAME.catalog_product_index_price_final_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_bundle_opt_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_bundle_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_downlod_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_cfg_opt_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_opt_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_cfg_opt_agr_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_opt_agr_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_bundle_sel_idx \
 --ignore-table=$DB_NAME.catalog_product_index_eav_decimal_idx \
 --ignore-table=$DB_NAME.cataloginventory_stock_status_idx \
 --ignore-table=$DB_NAME.catalog_product_index_eav_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_idx \
 --ignore-table=$DB_NAME.catalog_product_index_price_downlod_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_cfg_opt_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_eav_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_opt_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_cfg_opt_agr_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_eav_decimal_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_opt_agr_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_bundle_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_bundle_sel_tmp \
 --ignore-table=$DB_NAME.cataloginventory_stock_status_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_final_tmp \
 --ignore-table=$DB_NAME.catalog_product_index_price_bundle_opt_tmp \
 --ignore-table=$DB_NAME.magento_catalogpermissions_index_tmp \
 --ignore-table=$DB_NAME.magento_catalogpermissions_index_product_tmp \
 --ignore-table=$DB_NAME.catalog_category_product_index_tmp \
 --ignore-table=$DB_NAME.catalog_category_product_index_replica \
 --ignore-table=$DB_NAME.catalog_product_index_price_replica \
 -h $MYSQL_HOST -u $DB_USER --password=$MYSQL_PWD $DB_NAME &) | gzip > db.sql.gz

tar -czf php73.code.tar.gz . \
  --exclude=pub/media/catalog/* \
  --exclude=pub/media/* \
  --exclude=pub/media/backup/* \
  --exclude=pub/media/import/* \
  --exclude=pub/media/tmp/* \
  --exclude=pub/static/* \
  --exclude=var/* \
  --exclude=private \
  --exclude=tests

mkdir dumps
mv *.gz dumps/
php bin/magento --no-interaction setup:uninstall
ls -A | grep -v dumps | xargs rm -rf
mv dumps/* ./
rm -rf dumps

RESTORE_OUTPUT=$(${BIN_M2INSTALL} -f 2>error.log)
assertNotContains "$RESTORE_OUTPUT" "Updating Database Configuration" "Script do not run configure DB on corrupted DB Dump"
ERROR_OUTPUT="$(cat error.log)"
assertContains "$ERROR_OUTPUT" "The store table missing data" "Empty DB Dump returns error"
assertContains "$ERROR_OUTPUT" "The store_website table missing data" "Empty DB Dump returns error"
assertContains "$ERROR_OUTPUT" "MySQL DB Dump is corrupt. For on-prem, please request a new MySQL Dump from the merchant and ensure it is created using the mysqldump utility and not bin/magento support:db:backup. For Magento-Cloud, please regenerate a new MySQL Dump by using the ZD Dump Widget / cloud-teleport." "Missing data DB Dump"
