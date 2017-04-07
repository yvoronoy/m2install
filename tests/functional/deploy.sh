#!/usr/bin/env bash

function assertEqual()
{
  if [[ "$1" == "$2" ]]
  then
    return 0;
  else
    echo $1;
    echo $2;
  fi
  return 1;
}

echo `pwd`;
mkdir dumps
cd magento
php bin/magento setup:backup --code --db
cd ../
cp magento/var/backups/* dumps
cd dumps
../m2install.sh -f

assertEqual $(ls app/etc/env.php.merchant) app/etc/env.php.merchant

