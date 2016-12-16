#!/bin/bash

# Magento 2 Bash Install Script
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# @copyright Copyright (c) 2015 by Yaroslav Voronoy (y.voronoy@gmail.com)
# @license   http://www.gnu.org/licenses/

VERBOSE=1
CURRENT_DIR_NAME=$(basename "$(pwd)")
STEPS=()

HTTP_HOST=http://mage2.dev/
BASE_PATH=${CURRENT_DIR_NAME}
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=

MAGENTO_VERSION=2.1

DB_NAME=
USE_SAMPLE_DATA=
MAGENTO_EE_PATH=
CONFIG_NAME=.m2install.conf
USE_WIZARD=1

GIT_CE_REPO=
GIT_EE_REPO=

SOURCE=
FORCE=
MAGE_MODE=dev

BIN_MAGE="php -d memory_limit=2G bin/magento"
BIN_COMPOSER="composer"
BIN_MYSQL="mysql"
BIN_GIT="git"


function printVersion()
{
    printString "1.0.2"
}

function askValue()
{
    MESSAGE=$1
    READ_DEFAULT_VALUE=$2
    READVALUE=
    if [ "${READ_DEFAULT_VALUE}" ]
    then
        MESSAGE="${MESSAGE} (default: ${READ_DEFAULT_VALUE})"
    fi
    MESSAGE="${MESSAGE}: "
    read -r -p "$MESSAGE" READVALUE
    if [[ $READVALUE = [Nn] ]]
    then
        READVALUE=''
        return
    fi
    if [ -z "${READVALUE}" ] && [ "${READ_DEFAULT_VALUE}" ]
    then
        READVALUE=${READ_DEFAULT_VALUE}
    fi
}

function askConfirmation() {
    if [ "$FORCE" ]
    then
        return 0;
    fi
    read -r -p "${1:-Are you sure? [y/N]} " response
    case $response in
        [yY][eE][sS]|[yY])
            retval=0
            ;;
        *)
            retval=1
            ;;
    esac
    return $retval
}

function printString()
{
    if [[ "$VERBOSE" -eq 1 ]]
    then
        echo "$@";
    fi
}

function printError()
{
    >&2 echo "$@";
}

function printLine()
{
    if [[ "$VERBOSE" -eq 1 ]]
    then
        printf '%50s\n' ' ' | tr ' ' -
    fi
}

function runCommand()
{
    local _prefixMessage=$1;
    local _suffixMessage=$2
    if [[ "$VERBOSE" -eq 1 ]]
    then
        echo "${_prefixMessage}${CMD}${_suffixMessage}"
    fi

    # shellcheck disable=SC2086
    eval ${CMD};
}

function extract()
{
     if [ -f "$EXTRACT_FILENAME" ] ; then
         case $EXTRACT_FILENAME in
             *.tar.bz2)   CMD="tar xjf $EXTRACT_FILENAME";;
             *.tar.gz)    CMD="gunzip -c $EXTRACT_FILENAME | gunzip -cf | tar -x" ;;
             *.tgz)       CMD="gunzip -c $EXTRACT_FILENAME | gunzip -cf | tar -x" ;;
             *.gz)        CMD="gunzip $EXTRACT_FILENAME" ;;
             *.tbz2)      CMD="tar xjf $EXTRACT_FILENAME" ;;
             *.zip)       CMD="unzip -qu -x $EXTRACT_FILENAME" ;;
             *)           printError "'$EXTRACT_FILENAME' cannot be extracted"; CMD='' ;;
         esac
        runCommand
     else
         printError "'$EXTRACT_FILENAME' is not a valid file"
     fi
}

function mysqlQuery()
{
    CMD="${BIN_MYSQL} -h${DB_HOST} -u${DB_USER} --password=${DB_PASSWORD} --execute=\"${SQLQUERY}\"";
    runCommand
}

function generateDBName()
{
    prepareBasePath
    if [ "$BASE_PATH" ]
    then
        DB_NAME=${DB_USER}_$(echo "$BASE_PATH" | sed "s/\//_/g" | sed "s/[^a-zA-Z0-9_]//g" | tr '[:upper:]' '[:lower:]');
    else
        DB_NAME=${DB_USER}_$(echo "$CURRENT_DIR_NAME" | sed "s/\//_/g" | sed "s/[^a-zA-Z0-9_]//g" | tr '[:upper:]' '[:lower:]');
    fi
}

function prepareBasePath()
{
    BASE_PATH=$(echo "${BASE_PATH}" | sed "s/^\///g" | sed "s/\/$//g" );
}

function prepareBaseURL()
{
    prepareBasePath
    HTTP_HOST=$(echo ${HTTP_HOST}/ | sed "s/\/\/$/\//g" );
    BASE_URL=${HTTP_HOST}${BASE_PATH}/
    BASE_URL=$(echo "$BASE_URL" | sed "s/\/\/$/\//g" );
}

function initQuietMode()
{
    if [[ "$VERBOSE" -eq 1 ]]
    then
        return;
    fi

    BIN_MAGE="${BIN_MAGE} --quiet"
    BIN_COMPOSER="${BIN_COMPOSER} --quiet"
    BIN_GIT="${BIN_GIT} --quiet"

    FORCE=1
}

function getCodeDumpFilename()
{
    FILENAME_CODE_DUMP=$(find . -maxdepth 1 -name '*.tbz2' -o -name '*.tar.bz2' | head -n1)
    if [ "${FILENAME_CODE_DUMP}" == "" ]
    then
        FILENAME_CODE_DUMP=$(find . -maxdepth 1 -name '*.tar.gz' | grep -v 'logs.tar.gz' | head -n1)
    fi
    if [ ! "$FILENAME_CODE_DUMP" ]
    then
        FILENAME_CODE_DUMP=$(find . -maxdepth 1 -name '*.tgz' | head -n1)
    fi
    if [ ! "$FILENAME_CODE_DUMP" ]
    then
        FILENAME_CODE_DUMP=$(find . -maxdepth 1 -name '*.zip' | head -n1)
    fi
}

function getDbDumpFilename()
{
    FILENAME_DB_DUMP=$(find . -maxdepth 1 -name '*.sql.gz' | head -n1)
    if [ ! "$FILENAME_DB_DUMP" ]
    then
        FILENAME_DB_DUMP=$(find . -maxdepth 1 -name '*_db.gz' | head -n1)
    fi
}

function foundSupportBackupFiles()
{
    if [[ ! "$FILENAME_CODE_DUMP" ]]
    then
        getCodeDumpFilename
    fi
    if [ ! -f "$FILENAME_CODE_DUMP" ]
    then
        return 1;
    fi

    if [[ ! "$FILENAME_DB_DUMP" ]]
    then
        getDbDumpFilename
    fi
    if [ ! -f "$FILENAME_DB_DUMP" ]
    then
        return 1;
    fi

    return 0;
}

function wizard()
{
    askValue "Enter Server Name of Document Root" "${HTTP_HOST}"
    HTTP_HOST=${READVALUE}
    askValue "Enter Base Path" "${BASE_PATH}"
    BASE_PATH=${READVALUE}
    askValue "Enter DB Host" "${DB_HOST}"
    DB_HOST=${READVALUE}
    askValue "Enter DB User" "${DB_USER}"
    DB_USER=${READVALUE}
    askValue "Enter DB Password" "${DB_PASSWORD}"
    DB_PASSWORD=${READVALUE}
    generateDBName
    askValue "Enter DB Name" "${DB_NAME}"
    DB_NAME=${READVALUE}

    if foundSupportBackupFiles
    then
        return;
    fi
    if askConfirmation "Do you want to install Sample Data (y/N)"
    then
        USE_SAMPLE_DATA=1
    fi
}

function printConfirmation()
{
    printComposerConfirmation
    printGitConfirmation
    prepareBaseURL
    printString "BASE URL: ${BASE_URL}"
    printString "DB PARAM: ${DB_USER}@${DB_HOST}"
    printString "DB NAME: ${DB_NAME}"
    if foundSupportBackupFiles
    then
        return;
    fi
    if [ "${USE_SAMPLE_DATA}" ]
    then
        printString "Sample Data will be installed."
    else
        printString "Sample Data will NOT be installed."
    fi
    if [ "${MAGENTO_EE_PATH}" ]
    then
        printString "Magento EE will be installed"
    else
        printString "Magento EE will NOT be installed."
    fi
}

function showWizard()
{
    I=1;
    while [ "$I" -eq 1 ]
    do
        if [ "$USE_WIZARD" -eq 1 ]
        then
            showComposerWizzard
            showWizzardGit
            wizard
        fi
        printLine
        printConfirmation
        if askConfirmation "Confirm That the Entered Data Is Correct? (y/N)"
        then
            I=0
        else
            USE_WIZARD=1
        fi
    done
}

function loadConfigFile()
{
    NEAREST_CONFIG_FILE=$( (find "$(pwd)" -maxdepth 1 -name $CONFIG_NAME ;\
        x=$(pwd);\
        while [ "$x" != "/" ] ;\
        do x=$(dirname "$x");\
            find "$x" -maxdepth 1 -name $CONFIG_NAME;\
        done) | sed '1!G;h;$!d')
    if [ ! "$NEAREST_CONFIG_FILE" ]
    then
        NEAREST_CONFIG_FILE="$HOME/$CONFIG_NAME"
    fi
    if [ "$NEAREST_CONFIG_FILE" ]
    then
        for FILE in $NEAREST_CONFIG_FILE
        do
            # shellcheck source=/dev/null
            source "$FILE"
        done
        USE_WIZARD=0
    fi
    generateDBName
}

function promptSaveConfig()
{
    if [ "$FORCE" ]
    then
        return;
    fi
    _local=$(dirname "$BASE_PATH")
    if [ "$_local" == "." ]
    then
        _local=
    else
        _local=$_local/
    fi
    if [ "$_local" != '/' ]
    then
        _local=${_local}\$CURRENT_DIR_NAME
    fi

    if [ "$NEAREST_CONFIG_FILE" ]
    then
        _configContent=$(cat << EOF
HTTP_HOST=$HTTP_HOST
BASE_PATH=$_local
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
MAGENTO_VERSION=$MAGENTO_VERSION
MAGENTO_EE_PATH=$MAGENTO_EE_PATH
GIT_CE_REPO=$GIT_CE_REPO
GIT_EE_REPO=$GIT_EE_REPO
EOF
)
        _currentConfigContent=$(cat "$NEAREST_CONFIG_FILE")

        if [ "$_configContent" == "$_currentConfigContent" ]
        then
            return;
        fi

    fi

    if askConfirmation "Do you want save/override config to ~/$CONFIG_NAME (y/N)"
    then
        cat << EOF > ~/$CONFIG_NAME
HTTP_HOST=$HTTP_HOST
BASE_PATH=$_local
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
MAGENTO_VERSION=$MAGENTO_VERSION
MAGENTO_EE_PATH=$MAGENTO_EE_PATH
GIT_CE_REPO=$GIT_CE_REPO
GIT_EE_REPO=$GIT_EE_REPO
EOF
            printString "Config file has been created in ~/$CONFIG_NAME";
        fi
    _local=
}

function dropDB()
{
    SQLQUERY="DROP DATABASE IF EXISTS ${DB_NAME}";
    mysqlQuery
}

function createNewDB()
{
    SQLQUERY="CREATE DATABASE IF NOT EXISTS ${DB_NAME}";
    mysqlQuery
}

function restore_db()
{
    dropDB
    createNewDB

    getDbDumpFilename

    CMD="gunzip -cf \"$FILENAME_DB_DUMP\""
    if which pv > /dev/null
    then
        CMD="pv \"${FILENAME_DB_DUMP}\" | gunzip -cf";
    fi

    CMD="${CMD} | gunzip -cf | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/'
        | grep -v 'mysqldump: Couldn.t find table' | grep -v 'Warning: Using a password'
        | ${BIN_MYSQL} -h${DB_HOST} -u${DB_USER} --password=${DB_PASSWORD} --force $DB_NAME";
    runCommand
}

function restore_code()
{
    EXTRACT_FILENAME=$FILENAME_CODE_DUMP
    extract

    CMD="mkdir -p var pub/media pub/static"
    runCommand
}

function configure_files()
{
    updateMagentoEnvFile
    overwriteOriginalFiles
    CMD="find . -type d -exec chmod 775 {} \; && find . -type f -exec chmod 664 {} \; && chmod u+x bin/magento"
    runCommand
}

function configure_db()
{
    updateBaseUrl
    clearBaseLinks
    clearCookieDomain
    clearCustomAdmin
    resetAdminPassword
}

function updateBaseUrl()
{
    SQLQUERY="UPDATE ${DB_NAME}.${TBL_PREFIX}core_config_data AS e SET e.value = '${BASE_URL}' WHERE e.path IN ('web/secure/base_url', 'web/unsecure/base_url')"
    mysqlQuery
}

function clearBaseLinks()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.${TBL_PREFIX}core_config_data WHERE path IN ('web/unsecure/base_link_url', 'web/secure/base_link_url', 'web/unsecure/base_static_url', 'web/unsecure/base_media_url', 'web/secure/base_static_url', 'web/secure/base_media_url')";
    mysqlQuery
}

function clearCookieDomain()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.${TBL_PREFIX}core_config_data WHERE path = 'web/cookie/cookie_domain'"
    mysqlQuery
}

function clearCustomAdmin()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.${TBL_PREFIX}core_config_data WHERE path = 'admin/url/custom'"
    mysqlQuery
    SQLQUERY="UPDATE ${DB_NAME}.${TBL_PREFIX}core_config_data SET ${DB_NAME}.${TBL_PREFIX}core_config_data.value = '0' WHERE path = 'admin/url/use_custom'"
    mysqlQuery
    SQLQUERY="DELETE FROM ${DB_NAME}.${TBL_PREFIX}core_config_data WHERE path = 'admin/url/custom_path'"
    mysqlQuery
    SQLQUERY="UPDATE ${DB_NAME}.${TBL_PREFIX}core_config_data SET ${DB_NAME}.${TBL_PREFIX}core_config_data.value = '0' WHERE path = 'admin/url/use_custom_path'"
    mysqlQuery
}

function resetAdminPassword()
{
    SQLQUERY="UPDATE ${DB_NAME}.${TBL_PREFIX}admin_user SET ${DB_NAME}.${TBL_PREFIX}admin_user.email = 'mail@magento.com' WHERE ${DB_NAME}.${TBL_PREFIX}admin_user.username = 'admin'"
    mysqlQuery
    CMD="${BIN_MAGE} admin:user:create
        --admin-user='admin'
        --admin-password='123123q'
        --admin-email='mail@magento.com'
        --admin-firstname='Magento'
        --admin-lastname='User'"
    runCommand
}

function overwriteOriginalFiles()
{
    if [ ! -f pub/static.php ]
    then
        CMD="curl -s -o pub/static.php https://raw.githubusercontent.com/magento/magento2/2.0/pub/static.php"
        runCommand
    fi

    if [ -f .htaccess ]
    then
        CMD="mv .htaccess .htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o .htaccess https://raw.githubusercontent.com/magento/magento2/2.0/.htaccess"
    runCommand

    if [ -f pub/static/.htaccess ]
    then
        CMD="mv pub/static/.htaccess pub/static/.htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o pub/static/.htaccess https://raw.githubusercontent.com/magento/magento2/2.0/pub/static/.htaccess"
    runCommand

    if [ -f pub/media/.htaccess ]
    then
        CMD="mv pub/media/.htaccess pub/media/.htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o pub/media/.htaccess https://raw.githubusercontent.com/magento/magento2/2.0/pub/media/.htaccess"
    runCommand
}

function updateMagentoEnvFile()
{
    TBL_PREFIX=$(grep 'table_prefix' app/etc/env.php | head -n1 | sed "s/[a-z'_ ]*[=][>][ ]*[']//" | sed "s/['][,]//")

    _key="'key' => 'ec3b1c29111007ac5d9245fb696fb729',"
    _date="'date' => 'Fri, 27 Nov 2015 12:24:54 +0000',"
    _table_prefix="'table_prefix' => '${TBL_PREFIX}',"


    if [ -f app/etc/env.php ]
    then
        CMD="cp app/etc/env.php app/etc/env.php.merchant"
        runCommand

        _key=$(grep key app/etc/env.php.merchant)
        _date=$(grep date app/etc/env.php.merchant)
        _table_prefix=$(grep table_prefix app/etc/env.php.merchant)
    fi
    cat << EOF > app/etc/env.php
<?php
return array (
  'backend' =>
  array (
    'frontName' => 'admin',
  ),
  'queue' =>
  array (
    'amqp' =>
    array (
      'host' => '',
      'port' => '',
      'user' => '',
      'password' => '',
      'virtualhost' => '/',
      'ssl' => '',
    ),
  ),
  'db' =>
  array (
    'connection' =>
    array (
      'indexer' =>
      array (
        'host' => '${DB_HOST}',
        'dbname' => '${DB_NAME}',
        'username' => '${DB_USER}',
        'password' => '${DB_PASSWORD}',
        'model' => 'mysql4',
        'engine' => 'innodb',
        'initStatements' => 'SET NAMES utf8;',
        'active' => '1',
        'persistent' => NULL,
      ),
      'default' =>
      array (
        'host' => '${DB_HOST}',
        'dbname' => '${DB_NAME}',
        'username' => '${DB_USER}',
        'password' => '${DB_PASSWORD}',
        'model' => 'mysql4',
        'engine' => 'innodb',
        'initStatements' => 'SET NAMES utf8;',
        'active' => '1',
      ),
    ),
    ${_table_prefix}
  ),
  'install' =>
  array (
    ${_date}
  ),
  'crypt' =>
  array (
    ${_key}
  ),
  'session' =>
  array (
    'save' => 'files',
  ),
  'resource' =>
  array (
    'default_setup' =>
    array (
      'connection' => 'default',
    ),
  ),
  'x-frame-options' => 'SAMEORIGIN',
  'MAGE_MODE' => 'default',
  'cache_types' =>
  array (
    'config' => 1,
    'layout' => 1,
    'block_html' => 1,
    'collections' => 1,
    'reflection' => 1,
    'db_ddl' => 1,
    'eav' => 1,
    'full_page' => 1,
    'config_integration' => 1,
    'config_integration_api' => 1,
    'target_rule' => 1,
    'translate' => 1,
    'config_webservice' => 1,
  ),
);
EOF

_key=
_date=
_table_prefix=
}

function deployStaticContent()
{
    if [[ "$MAGE_MODE" == "dev" ]]
    then
        return;
    fi

    CMD="${BIN_MAGE} setup:static-content:deploy"
    runCommand
}

function compileDi()
{
    if [[ "$MAGE_MODE" == "dev" ]]
    then
        return;
    fi
    CMD="${BIN_MAGE} setup:di:compile"
    runCommand
}

function installSampleData()
{
    if php bin/magento --version | grep -q beta
    then
        _installSampleDataForBeta;
    else
        _installSampleData;
    fi
}

function _installSampleData()
{
    if ! php bin/magento | grep -q sampledata:deploy
    then
        printString "Your version does not support sample data"
        return;
    fi

    if [ -f "${HOME}/.composer/auth.json" ]
    then
        if [ -d "var/composer_home" ]
        then
            CMD="cp ${HOME}/.composer/auth.json var/composer_home/"
            runCommand
        fi
    fi


    CMD="${BIN_MAGE} sampledata:deploy"
    runCommand
    CMD="${BIN_COMPOSER} update"
    runCommand
    CMD="${BIN_MAGE} setup:upgrade"
    runCommand

    if [ -f "var/composer_home/auth.json" ]
    then
        CMD="rm var/composer_home/auth.json"
        runCommand
    fi
}

function _installSampleDataForBeta()
{
    CMD="${BIN_COMPOSER} config repositories.magento composer http://packages.magento.com"
    runCommand
    CMD="${BIN_COMPOSER} require magento/sample-data:~1.0.0-beta"
    runCommand
    CMD="${BIN_MAGE} setup:upgrade"
    runCommand
    CMD="${BIN_MAGE} sampledata:install admin"
    runCommand
}

function linkEnterpriseEdition()
{
    if [ "${SOURCE}" == 'composer' ]
    then
        return;
    fi
    if [ "${MAGENTO_EE_PATH}" ]
    then
        if [ ! -d "$MAGENTO_EE_PATH" ]
        then
            printError "There is no Enterprise Edition directory ${MAGENTO_EE_PATH}"
            printError "Use absolute or relative path to EE code base or [N] to skip it"
            exit
        fi
        CMD="php ${MAGENTO_EE_PATH}/dev/tools/build-ee.php --ce-source $(pwd) --ee-source ${MAGENTO_EE_PATH}"
        runCommand
        CMD="cp ${MAGENTO_EE_PATH}/composer.json $(pwd)/"
        runCommand
        CMD="cp ${MAGENTO_EE_PATH}/composer.lock $(pwd)/"
        runCommand
    fi
}

function runComposerInstall()
{
    CMD="${BIN_COMPOSER} install"
    runCommand
}

function installMagento()
{
    CMD="rm -rf var/generation/*"
    runCommand

    CMD="${BIN_MAGE} --no-interaction setup:uninstall"
    runCommand

    dropDB
    createNewDB

    CMD="${BIN_MAGE} setup:install --base-url=${BASE_URL} \
    --db-host=${DB_HOST} --db-name=${DB_NAME} --db-user=${DB_USER}  \
    --admin-firstname=Magento --admin-lastname=User --admin-email=mail@magento.com \
    --admin-user=admin --admin-password=123123q --language=en_US \
    --currency=USD --timezone=America/Chicago --use-rewrites=1 --backend-frontname=admin"
    if [ "${DB_PASSWORD}" ]
    then
        CMD="${CMD} --db-password=${DB_PASSWORD}"
    fi
    runCommand
}

function downloadSourceCode()
{
    if [ "$(ls -A ./)" ]; then
        printError "Can't download source code from ${SOURCE} since current directory doesn't empty."
        printError "You can remove all files from current directory using next command:"
        printError "ls -A | xargs rm -rf"
        exit 1;
    fi
    if [ "$SOURCE" == 'composer' ]
    then
        composerInstall
    fi

    if [ "$SOURCE" == 'git' ]
    then
        gitClone
    fi
}

function composerInstall()
{
    if [ "$MAGENTO_EE_PATH" ]
    then
        CMD="${BIN_COMPOSER} create-project --repository-url=https://repo.magento.com/ magento/project-enterprise-edition . ${MAGENTO_VERSION}"
        runCommand
    else
        CMD="${BIN_COMPOSER} create-project --repository-url=https://repo.magento.com/ magento/project-community-edition . $MAGENTO_VERSION"
        runCommand
    fi
}

showComposerWizzard()
{
    if [ "$SOURCE" != 'composer' ]
    then
        return;
    fi
    askValue "Composer Magento version" ${MAGENTO_VERSION}
    MAGENTO_VERSION=${READVALUE}
    if askConfirmation "Do you want to install Enterprise Edition (y/N)"
    then
        MAGENTO_EE_PATH="y"
    else
        MAGENTO_EE_PATH=
    fi

}

printComposerConfirmation()
{
    if [ "$SOURCE" != 'composer' ]
    then
        return;
    fi
    printString "Magento code will be downloaded from composer";
    printString "Composer version: $MAGENTO_VERSION";
}

function showWizzardGit()
{
    if [ "$SOURCE" != 'git' ]
    then
        return
    fi
    askValue "Git CE repository" ${GIT_CE_REPO}
    GIT_CE_REPO=${READVALUE}
    askValue "Git EE repository" ${GIT_EE_REPO}
    GIT_EE_REPO=${READVALUE}
    askValue "Git branch" ${MAGENTO_VERSION}
    MAGENTO_VERSION=${READVALUE}
    if askConfirmation "Do you want to install Enterprise Edition (y/N)"
    then
        askValue "Enter path to the directory with Enterprise Edition" "${MAGENTO_EE_PATH}"
        MAGENTO_EE_PATH=${READVALUE}
    else
        MAGENTO_EE_PATH=
    fi
}

function gitClone()
{
    CMD="${BIN_GIT} clone $GIT_CE_REPO ."
    runCommand
    CMD="${BIN_GIT} checkout $MAGENTO_VERSION"
    runCommand

    if [[ "$GIT_EE_REPO" ]] && [[ "$MAGENTO_EE_PATH" ]]
    then
        CMD="${BIN_GIT} clone $GIT_EE_REPO $MAGENTO_EE_PATH"
        runCommand
        CMD="cd ${MAGENTO_EE_PATH}"
        runCommand
        CMD="${BIN_GIT} checkout $MAGENTO_VERSION"
        runCommand
        CMD="cd .."
        runCommand
    fi
}

function printGitConfirmation()
{
    if [ "$SOURCE" != 'git' ]
    then
        return
    fi
    printString "Magento code will be downloaded from GIT";
    printString "Git CE repository: ${GIT_CE_REPO}"
    printString "Git EE repository: ${GIT_EE_REPO}"
    printString "Git branch: ${MAGENTO_VERSION}"
}

function checkArgumentHasValue()
{
    if [ ! "$2" ]
    then
        printError "ERROR: $1 Argument is empty."
        printLine
        printUsage
        exit
    fi
}

function isInputNegative()
{
    if [[ $1 = [Nn][oO] ]] || [[ $1 = [Nn] ]] || [[ $1 = [0] ]]
    then
        return 0;
    else
        return 1;
    fi
}

function validateStep()
{
    local _step=$1;
    local _steps="restore_db restore_code configure_db configure_files configure"
    if echo "$_steps" | grep -q "$_step"
    then
        if type -t "$_step" &>/dev/null
        then
            return 0;
        fi
    fi
    return 1;
}

function prepareSteps()
{
    local _step;
    local _steps;

    _steps=($(echo "${STEPS[@]}" | tr "," " "))
    STEPS=();

    for _step in "${_steps[@]}"
    do
        if validateStep "$_step"
        then
          addStep "$_step"
        fi
    done
}

function addStep()
{
  local _step=$1
  STEPS+=($_step)
}

function setProductionMode()
{
    CMD="${BIN_MAGE} deploy:mode:set production"
    runCommand
}

function setFilesystemPermission()
{
    CMD="chmod -R 2777 ./var ./pub/media ./pub/static ./app/etc"
    runCommand
}

function printUsage()
{
    cat <<EOF
$(basename "$0") is designed to simplify the installation process of Magento 2
and deployment of client dumps created by Magento 2 Support Extension.

Usage: $(basename "$0") [options]
Options:
    -h, --help                           Get this help.
    -s, --source (git, composer)         Get source code.
    -f, --force                          Install/Restore without any confirmations.
    --sample-data (yes, no)              Install sample data.
    --ee-path (/path/to/ee)              Path to Enterprise Edition.
    -v, --version                        Magento Version - it means: Composer version or GIT Branch
    --mode (dev, prod)                   Magento Mode. Dev mode does not generate static & di content.
    --quiet                              Quiet mode. Suppress output all commands
    --step (restore_code,restore_db      Specify step through comma without spaces.
        configure_db, configure_files)    - Example: $(basename "$0") --step restore_db,configure_db
EOF
}

################################################################################

export LC_CTYPE=C
export LANG=C

loadConfigFile

while [[ $# -gt 0 ]]
do
    case "$1" in
        -s|--source)
            checkArgumentHasValue "$1" "$2"
            SOURCE="$2"
            shift
        ;;
        -d|--sample-data)
            checkArgumentHasValue "$1" "$2"
            if isInputNegative "$2"
            then
                USE_SAMPLE_DATA=
            else
                USE_SAMPLE_DATA="$2"
            fi
            shift
        ;;
        -e|--ee-path)
            checkArgumentHasValue "$1" "$2"
            MAGENTO_EE_PATH="$2"
            shift
        ;;
        -b|--git-branch)
            checkArgumentHasValue "$1" "$2"
            MAGENTO_VERSION="$2"
            shift
        ;;
        -v|--version)
            checkArgumentHasValue "$1" "$2"
            MAGENTO_VERSION="$2"
            shift
        ;;
        --mode)
            checkArgumentHasValue "$1" "$2"
            MAGE_MODE=$2
            shift
        ;;
        -f|--force)
            FORCE=1
        ;;
        --quiet)
            VERBOSE=0
        ;;
        -h|--help)
            printUsage
            exit;
        ;;
        --code-dump)
            checkArgumentHasValue "$1" "$2"
            FILENAME_CODE_DUMP="$2"
            shift
        ;;
        --db-dump)
            checkArgumentHasValue "$1" "$2"
            FILENAME_DB_DUMP="$2"
            shift
        ;;
        --step)
            checkArgumentHasValue "$1" "$2"
            STEPS=($2)
            shift
        ;;
    esac
    shift
done

initQuietMode
printString Current Directory: "$(pwd)"
printString "Configuration loaded from: $NEAREST_CONFIG_FILE"
showWizard
promptSaveConfig

START_TIME=$(date +%s)
if [[ "${STEPS[@]}" ]]
then
    prepareSteps
elif foundSupportBackupFiles
then
    addStep "restore_code"
    addStep "configure_files"
    addStep "restore_db"
    addStep "configure_db"
    if [[ "$MAGE_MODE" == "production" ]]
    then
        addStep "setProductionMode"
    fi
    addStep "setFilesystemPermission"
else
    if [[ "${SOURCE}" ]]
    then
        if askConfirmation "Current directory is not empty. Do you want to clean current Directory (y/N)"
        then
            CMD="ls -A | xargs rm -rf"
            runCommand
        fi
        addStep "downloadSourceCode"
    fi
    addStep "linkEnterpriseEdition"
    addStep "runComposerInstall"
    addStep "installMagento"
    if [[ "${USE_SAMPLE_DATA}" ]]
    then
        addStep "installSampleData"
    fi
    if [[ "$MAGE_MODE" == "production" ]]
    then
        addStep "setProductionMode"
    fi
    addStep "setFilesystemPermission"
fi

for step in "${STEPS[@]}"
do
    CMD="${step}"
    runCommand "=> "
done
END_TIME=$(date +%s)
SUMMARY_TIME=$((((END_TIME - START_TIME)) / 60));
printString "$(basename "$0") takes $SUMMARY_TIME minutes to complete install/deploy process"

printLine

printString "${BASE_URL}"
printString "${BASE_URL}admin"
printString "User: admin"
printString "Pass: 123123q"

