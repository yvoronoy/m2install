#!/usr/bin/env bash

touch ~/.m2install.conf
mkdir magento;
cd magento;
../m2install.sh --force --source composer --ee -v 2.1.4


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

php bin/magento setup:backup --code --db
ls -A | grep -v var | rm -rf
mv var/backups/* ./
rm -rf var
../m2install.sh -f

assertEqual $(ls app/etc/env.php.merchant) app/etc/env.php.merchant

INSTALLED_VERSION="$(php bin/magento -V --no-ansi)"
assertEqual "$INSTALLED_VERSION" "Magento CLI version 2.1.4"

