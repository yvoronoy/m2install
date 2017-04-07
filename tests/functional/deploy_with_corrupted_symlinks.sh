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

NON_EXISTS_FILE=`pwd`/non-exists-file
mkdir deploy-corrupted-symlinks
cd magento
mv pub/.htaccess pub/.htaccess.bak
ln -s "$NON_EXISTS_FILE" pub/.htaccess
ls -la pub/.htaccess

tar cf - ./ \
  --exclude=pub/media/catalog/* \
  --exclude=pub/media/* \
  --exclude=pub/media/backup/* \
  --exclude=pub/media/import/* \
  --exclude=pub/media/tmp/* \
  --exclude=pub/static/* \
  --exclude=var/* \
  --exclude=private \
  --exclude=tests | gzip > ../deploy-corrupted-symlinks/code.tar.gz
rm "$NON_EXISTS_FILE"

cp var/backups/*sql* ../deploy-corrupted-symlinks/
cd ../deploy-corrupted-symlinks
../m2install.sh -f
ls -la pub/.htaccess

INSTALLED_VERSION="$(php bin/magento -V --no-ansi)";
EXPECTED_VERSION="Magento CLI version 2.1.5";
assertEqual "$INSTALLED_VERSION" "$EXPECTED_VERSION"
