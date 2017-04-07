#!/usr/bin/env bash

mkdir magento;
cd magento;
../m2install.sh --force --source composer --ee -v 2.1.5


function assertEqual()
{
  if [[ "$1" == "$2" ]]
  then
    exit 0;
  else
    echo $1;
    echo $2;
  fi
  exit 1;
}

INSTALLED_VERSION="$(php bin/magento -V --no-ansi)";
EXPECTED_VERSION="Magento CLI version 2.1.5";
assertEqual "$INSTALLED_VERSION" "$EXPECTED_VERSION"
cd -
