#!/usr/bin/env bash

touch ~/.m2install.conf
mkdir magento;
cd magento;
../m2install.sh --force --source composer --ee -v 2.1.5


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

INSTALLED_VERSION="$(php bin/magento -V --no-ansi)"
echo "Installed Magento version: $INSTALLED_VERSION"

assertEqual "$INSTALLED_VERSION" "Magento CLI version 2.1.5"
