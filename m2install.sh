#!/usr/bin/env bash

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
# @copyright Copyright (c) 2015-2017 by Yaroslav Voronoy (y.voronoy@gmail.com)
# @license   http://www.gnu.org/licenses/

VERBOSE=1
CURRENT_DIR_NAME=$(basename "$(pwd)")
STEPS=

HTTP_HOST=http://mage2.dev/
BASE_PATH=${CURRENT_DIR_NAME}
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=

MAGENTO_VERSION=2.2

DB_NAME=
USE_SAMPLE_DATA=
EE_PATH=magento2ee
INSTALL_EE=
INSTALL_B2B=
CONFIG_NAME=.m2install.conf
USE_WIZARD=1

GIT_CE_REPO="git@github.com:magento/magento2.git"
GIT_CE_SD_REPO="git@github.com:magento/magento2-sample-data.git"
GIT_EE_REPO=
GIT_EE_SD_REPO=
GIT_CE_SD_PATH=magento2-sample-data
GIT_EE_SD_PATH=magento2-sample-data-ee

SOURCE=
FORCE=
MAGE_MODE=dev

BIN_PHP=php
BIN_MAGE="-d memory_limit=2G bin/magento"
BIN_COMPOSER=$(command -v composer)
BIN_MYSQL="mysql"
BIN_GIT="git"

BACKEND_FRONTNAME="admin"
ADMIN_NAME="admin"
ADMIN_PASSWORD="123123q"
ADMIN_FIRSTNAME="Admin"
ADMIN_LASTNAME="Test"
ADMIN_EMAIL="admin@test.com"
TIMEZONE="America/Chicago"
LANGUAGE="en_US"
CURRENCY="USD"

BUNDLED_EXTENSION=(
    amzn/amazon-pay-and-login-magento-2-module
    dotmailer/dotmailer-magento2-extension
    klarna/module-core
    klarna/module-kp
    klarna/module-ordermanagement
    temando/module-shipping-m2
    vertex/module-tax
)

function printVersion()
{
    printString "1.0.2"
}

function getScriptDirectory()
{
    echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
    return 0;
}

function checkDependencies()
{
    DEPENDENCIES=(
      php
      composer
      mysql
      mysqladmin
      git
      cat
      basename
      tar
      gunzip
      sed
      grep
      mkdir
      cp
      mv
      rm
      find
      chmod
      date
    )

    for util in "${DEPENDENCIES[@]}"
    do
        hash "${util}" &>/dev/null || printError "'${util}' is not found on this system" || exit 1
    done;

}

function askValue()
{
    MESSAGE="$1"
    READ_DEFAULT_VALUE="$2"
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
    >&2 echo "ERROR: $@";
    return 1;
}

function printLine()
{
    if [[ "$VERBOSE" -eq 1 ]]
    then
        echo "--------------------------------------------------"
    fi
}

function setRequest()
{
    local _key=$1
    local _value=$2

    local expression="REQUEST_${_key}=${_value}"
    eval "${expression}";
}

function getRequest()
{
    local _key=$1
    local _variableName="REQUEST_${_key}";
    if [[ "${!_variableName:-}" ]]
    then
        echo "${!_variableName}"
        return 0;
    fi
    echo "";
    return 1;
}

function runCommand()
{
    local _prefixMessage=${1:-};
    local _suffixMessage=${2:-}
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
             *.tar.*|*.t*z*)
                CMD="tar $(getStripComponentsValue ${EXTRACT_FILENAME}) -xf ${EXTRACT_FILENAME}"
             ;;
             *.gz)              CMD="gunzip $EXTRACT_FILENAME" ;;
             *.zip)             CMD="unzip -qu -x $EXTRACT_FILENAME" ;;
             *)                 printError "'$EXTRACT_FILENAME' cannot be extracted"; exit 1; CMD='' ;;
         esac
        runCommand
     else
         printError "'$EXTRACT_FILENAME' is not a valid file"
     fi
}

function getStripComponentsValue()
{
    local stripComponents=
    local slashCount=
    slashCount=$(tar -tf "$1" | grep -v vendor | fgrep pub/index.php | sed 's/pub[/]index[.]php//' | sort | head -1 | tr -cd '/' | wc -m | tr -d ' ')

    if [[ "$slashCount" -gt 0 ]]
    then
        stripComponents="--strip-components=$slashCount"
    fi

    echo "$stripComponents";
}

function mysqlQuery()
{
    CMD="${BIN_MYSQL} -h${DB_HOST} -u${DB_USER} --password=\"${DB_PASSWORD}\" --execute=\"${SQLQUERY}\"";
    runCommand
}

function generateDBName()
{
    if [ -z "$DB_NAME" ]
    then
        prepareBasePath
        if [ "$BASE_PATH" ]
        then
            DB_NAME=${DB_USER}_${BASE_PATH}
        else
            DB_NAME=${DB_USER}_${CURRENT_DIR_NAME}
        fi
    fi

    DB_NAME=$(sed -e "s/\//_/g; s/[^a-zA-Z0-9_]//g" <(php -r "print strtolower('$DB_NAME');"));
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

    BIN_MAGE="${BIN_PHP} ${BIN_MAGE} --quiet"
    BIN_COMPOSER="${BIN_PHP} ${BIN_COMPOSER} --quiet"
    BIN_GIT="${BIN_GIT} --quiet"

    FORCE=1
}

function getCodeDumpFilename()
{
    local codeDumpFilename="";
    if [[ -f "$(getRequest codedump)" ]]
    then
        codeDumpFilename="$(getRequest codedump)";
        echo "$codeDumpFilename";
        return 0;
    fi
    codeDumpFilename=$(find . -maxdepth 1 -name '*.tbz2' -o -name '*.tar.bz2' | head -n1)
    if [ "${codeDumpFilename}" == "" ]
    then
        codeDumpFilename=$(find . -maxdepth 1 -name '*.tar.gz' | grep -v 'logs.tar.gz' | head -n1)
    fi
    if [ ! "$codeDumpFilename" ]
    then
        codeDumpFilename=$(find . -maxdepth 1 -name '*.tgz' | head -n1)
    fi
    if [ ! "$codeDumpFilename" ]
    then
        codeDumpFilename=$(find . -maxdepth 1 -name '*.zip' | head -n1)
    fi

    echo "$codeDumpFilename";
    return 0;
}

function getDbDumpFilename()
{
    local dbDumpFilename="";
    if [[ -f "$(getRequest dbdump)" ]]
    then
        dbDumpFilename="$(getRequest dbdump)";
        echo "$dbDumpFilename";
        return 0;
    fi
    dbdumpFilename=$(find . -maxdepth 1 -name '*.sql.gz' | head -n1)
    if [ ! "$dbdumpFilename" ]
    then
        dbdumpFilename=$(find . -maxdepth 1 -name '*_db.gz' | head -n1)
    fi
    if [ ! "$dbdumpFilename" ]
    then
        dbdumpFilename=$(find . -maxdepth 1 -name '*.sql' | head -n1)
    fi
    echo "$dbdumpFilename";
    return 0;
}

function foundSupportBackupFiles()
{
    if [ -z getCodeDumpFilename ]
    then
        return 1;
    fi

    if [ -z getDbDumpFilename ]
    then
        return 1;
    fi

    if [ ! -f "$(getCodeDumpFilename)" ] || [ ! -f "$(getDbDumpFilename)" ]
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

function noSourceWizard()
{
    if [[ "$SOURCE" ]]
    then
        return;
    fi
    if [[ ! "$SOURCE" ]] && askConfirmation "Do you want install Enterprise Edition (y/N)"
    then
        INSTALL_EE=1
    fi
    if [[ "$INSTALL_EE" ]] && askConfirmation "Do you want install B2B Extension (y/N)"
    then
         INSTALL_B2B=1
    fi
}

function printConfirmation()
{
    printComposerConfirmation
    printGitConfirmation
    prepareBaseURL
    printString "BASE URL: ${BASE_URL}"
    printString "BASE PATH: ${BASE_PATH}"
    printString "DB PARAM: ${DB_USER}@${DB_HOST}"
    printString "DB NAME: ${DB_NAME}"
    printString "DB PASSWORD: ${DB_PASSWORD}"
    printString "MAGE MODE: ${MAGE_MODE}"
    printString "BACKEND FRONTNAME: ${BACKEND_FRONTNAME}"
    printString "ADMIN NAME: ${ADMIN_NAME}"
    printString "ADMIN PASSWORD: ${ADMIN_PASSWORD}"
    printString "ADMIN FIRSTNAME: ${ADMIN_FIRSTNAME}"
    printString "ADMIN LASTNAME: ${ADMIN_LASTNAME}"
    printString "ADMIN EMAIL: ${ADMIN_EMAIL}"
    printString "TIMEZONE: ${TIMEZONE}"
    printString "LANGUAGE: ${LANGUAGE}"
    printString "CURRENCY: ${CURRENCY}"
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
    if [ "${INSTALL_EE}" ]
    then
        printString "Magento EE will be installed"
    else
        printString "Magento EE will NOT be installed."
    fi
    if [ "${INSTALL_B2B}" ]
    then
        printString "Magento B2B will be installed"
    else
        printString "Magento B2B will NOT be installed."
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
            noSourceWizard
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

function getConfigFiles()
{
    local configPaths[0]="$HOME/$CONFIG_NAME"
    configPaths[1]="$HOME/${CONFIG_NAME}.override"
    local recursiveconfigs=$( (find "$(pwd)" -maxdepth 1 -name "${CONFIG_NAME}" ;\
        x=$(pwd);\
        while [ "$x" != "/" ] ;\
        do x=$(dirname "$x");\
            find "$x" -maxdepth 1 -name "${CONFIG_NAME}";\
        done) | sed '1!G;h;$!d')
    configPaths=("${configPaths[@]}" "${recursiveconfigs[@]}" "./$(basename ${CONFIG_NAME})");
    echo "${configPaths[@]}"
    return 0;
}

function loadConfigFile()
{
    local filePath=
    local configPaths=("$@");
    for filePath in "${configPaths[@]}"
    do
        if [ -f "${filePath}" ]
        then
            source "$filePath"
            USE_WIZARD=0
        fi
    done
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

    _configContent=$(cat << EOF
HTTP_HOST=$HTTP_HOST
BASE_PATH=$_local
DB_HOST=$DB_HOST
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
MAGENTO_VERSION=$MAGENTO_VERSION
INSTALL_EE=$INSTALL_EE
INSTALL_B2B=$INSTALL_B2B
GIT_CE_REPO=$GIT_CE_REPO
GIT_EE_REPO=$GIT_EE_REPO
MAGE_MODE=$MAGE_MODE
BACKEND_FRONTNAME=$BACKEND_FRONTNAME
ADMIN_NAME=$ADMIN_NAME
ADMIN_PASSWORD=$ADMIN_PASSWORD
ADMIN_FIRSTNAME=$ADMIN_FIRSTNAME
ADMIN_LASTNAME=$ADMIN_LASTNAME
ADMIN_EMAIL=$ADMIN_EMAIL
TIMEZONE=$TIMEZONE
LANGUAGE=$LANGUAGE
CURRENCY=$CURRENCY
EOF
)

    if [ "$(getConfigFiles)" ]
    then
        _currentConfigContent=$(cat "$HOME/$CONFIG_NAME")

        if [ "$_configContent" == "$_currentConfigContent" ]
        then
            return;
        fi

    fi

    configSavePath="$HOME/$CONFIG_NAME"
    if [ -f "${configSavePath}" ]
    then
        configSavePath="./$CONFIG_NAME"
    fi
    if askConfirmation "Do you want save config to ${configSavePath} (y/N)"
    then
        cat << EOF > ${configSavePath}
$_configContent
EOF
            printString "Config file has been created in ${configSavePath}";
        fi
    _local=
    configSavePath=
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

    CMD="gunzip -cf \"$(getDbDumpFilename)\""
    if which pv > /dev/null
    then
        CMD="pv \"$(getDbDumpFilename)\" | gunzip -cf";
    fi

    # Don't be confused by double gunzip in following command. Some poorly
    # configured web servers can gzip everything including gzip files
    CMD="${CMD} | gunzip -cf | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/'
        | sed -e 's/TRIGGER[ ][\`][A-Za-z0-9_]*[\`][.]/TRIGGER /'
        | sed -e 's/AFTER[ ]\(INSERT\)\{0,1\}\(UPDATE\)\{0,1\}\(DELETE\)\{0,1\}[ ]ON[ ][\`][A-Za-z0-9_]*[\`][.]/AFTER \1\2\3 ON /'
        | grep -v 'mysqldump: Couldn.t find table' | grep -v 'Warning: Using a password'
        | ${BIN_MYSQL} -h${DB_HOST} -u${DB_USER} --password=\"${DB_PASSWORD}\" --force $DB_NAME";
    runCommand
}

function restore_code()
{
    EXTRACT_FILENAME="$(getCodeDumpFilename)"
    extract

    CMD="mkdir -p var pub/media pub/static"
    runCommand
}

function configure_files()
{
    CMD="find -L ./pub -type l -delete"
    runCommand
    updateMagentoEnvFile
    overwriteOriginalFiles
    CMD="find . -type d -exec chmod 775 {} \; && find . -type f -exec chmod 664 {} \;"
    runCommand
}

function appConfigImport()
{
    if ${BIN_PHP} bin/magento | grep -q app:config:import
    then
        CMD="${BIN_PHP} bin/magento app:config:import -n"
        runCommand
    fi
}

function configure_db()
{
    updateBaseUrl
    clearBaseLinks
    clearCookieDomain
    clearSslFlag
    clearCustomAdmin
    replaceFastlyKey
    enableBuiltinCache
    resetImagePlaceholders
    resetAdminPassword
}

function validateDeploymentFromDumps()
{
    local files=(
      'composer.json'
      'composer.lock'
      'index.php'
      'pub/index.php'
      'pub/static.php'
    );
    local directories=("app" "bin" "dev" "lib" "pub/errors" "setup" "vendor");
    missingDirectories=();
    for dir in "${directories[@]}"
    do
        if [ ! -d "$dir" ]; then
            missingDirectories+=("$dir");
        fi
    done
    if [[ "${missingDirectories[@]-}" ]]
    then
        echo "The following directories are missing: ${missingDirectories[@]}";
    fi

    missingFiles=()
    for file in "${files[@]}"
    do
        if [ ! -f "$file" ]; then
            missingFiles+=("$file");
        fi
    done
    if [[ "${missingFiles[@]-}" ]]
    then
        echo "The following files are missing: ${missingFiles[@]}";
    fi
    if [[ "${missingDirectories[@]-}" || "${missingFiles[@]-}" ]]
    then
        printError "Download missing files and directories from vanilla magento"
    fi
}

function updateBaseUrl()
{
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)core_config_data AS e SET e.value = '${BASE_URL}' WHERE e.path IN ('web/secure/base_url', 'web/unsecure/base_url')"
    mysqlQuery
}

function clearBaseLinks()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.$(getTablePrefix)core_config_data WHERE path IN ('web/unsecure/base_link_url', 'web/secure/base_link_url', 'web/unsecure/base_static_url', 'web/unsecure/base_media_url', 'web/secure/base_static_url', 'web/secure/base_media_url')";
    mysqlQuery
}

function clearCookieDomain()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.$(getTablePrefix)core_config_data WHERE path = 'web/cookie/cookie_domain'"
    mysqlQuery
}

function clearSslFlag()
{
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)core_config_data AS e SET e.value = 0 WHERE e.path IN ('web/secure/use_in_adminhtm', 'web/secure/use_in_frontend')"
    mysqlQuery
}

function clearCustomAdmin()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.$(getTablePrefix)core_config_data WHERE path = 'admin/url/custom'"
    mysqlQuery
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)core_config_data SET ${DB_NAME}.$(getTablePrefix)core_config_data.value = '0' WHERE path = 'admin/url/use_custom'"
    mysqlQuery
    SQLQUERY="DELETE FROM ${DB_NAME}.$(getTablePrefix)core_config_data WHERE path = 'admin/url/custom_path'"
    mysqlQuery
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)core_config_data SET ${DB_NAME}.$(getTablePrefix)core_config_data.value = '0' WHERE path = 'admin/url/use_custom_path'"
    mysqlQuery
}

function replaceFastlyKey()
{
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)core_config_data AS e SET e.value = 'replaced_by_m2install' WHERE e.path = 'system/full_page_cache/fastly/fastly_api_key'"
    mysqlQuery
}

function enableBuiltinCache()
{
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)core_config_data AS e SET e.value = 1 WHERE e.path = 'system/full_page_cache/caching_application'"
    mysqlQuery
}

function resetAdminPassword()
{
    SQLQUERY="UPDATE ${DB_NAME}.$(getTablePrefix)admin_user SET ${DB_NAME}.$(getTablePrefix)admin_user.email = '${ADMIN_EMAIL}' WHERE ${DB_NAME}.$(getTablePrefix)admin_user.username = '${ADMIN_NAME}'"
    mysqlQuery
    CMD="${BIN_PHP} ${BIN_MAGE} admin:user:create
        --admin-user='${ADMIN_NAME}'
        --admin-password='${ADMIN_PASSWORD}'
        --admin-email='${ADMIN_EMAIL}'
        --admin-firstname='${ADMIN_FIRSTNAME}'
        --admin-lastname='${ADMIN_LASTNAME}'"
    runCommand
}

function resetImagePlaceholders()
{
    SQLQUERY="DELETE FROM ${DB_NAME}.$(getTablePrefix)core_config_data WHERE path LIKE 'catalog/placeholder/%'"
    mysqlQuery
}

function overwriteOriginalFiles()
{
    if [ -f app/etc/config.local.php ]
    then
        CMD="mv app/etc/config.local.php app/etc/config.local.php.merchant"
        runCommand
    fi

    if [ ! -f pub/static.php ]
    then
        CMD="curl -s -o pub/static.php https://raw.githubusercontent.com/magento/magento2/${MAGENTO_VERSION}/pub/static.php"
        runCommand
    fi

    if [ -f .htaccess ] && [ ! -f .htaccess.merchant ]
    then
        CMD="mv .htaccess .htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o .htaccess https://raw.githubusercontent.com/magento/magento2/${MAGENTO_VERSION}/.htaccess"
    runCommand

    if [ -f pub/.htaccess ] && [ ! -f pub/.htaccess.merchant ]
    then
        CMD="mv pub/.htaccess pub/.htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o pub/.htaccess https://raw.githubusercontent.com/magento/magento2/${MAGENTO_VERSION}/pub/.htaccess"
    runCommand

    if [ -f pub/static/.htaccess ] && [ ! -f pub/static/.htaccess.merchant ]
    then
        CMD="mv pub/static/.htaccess pub/static/.htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o pub/static/.htaccess https://raw.githubusercontent.com/magento/magento2/${MAGENTO_VERSION}/pub/static/.htaccess"
    runCommand

    if [ -f pub/media/.htaccess ] && [ ! -f pub/media/.htaccess.merchant ]
    then
        CMD="mv pub/media/.htaccess pub/media/.htaccess.merchant"
        runCommand
    fi
    CMD="curl -s -o pub/media/.htaccess https://raw.githubusercontent.com/magento/magento2/${MAGENTO_VERSION}/pub/media/.htaccess"
    runCommand
}
function getTablePrefix()
{
    echo $(grep 'table_prefix' app/etc/env.php | head -n1 | sed "s/[a-z'_ ]*[=][>][ ]*[']//" | sed "s/['][,]*//")
    return 0;
}

function updateMagentoEnvFile()
{
    if [ -f app/etc/env.php ] && [ ! -f app/etc/env.php.merchant ]
    then
        CMD="cp app/etc/env.php app/etc/env.php.merchant"
        runCommand
    fi
    local deployConfigurator=$(cat << EOF
<?php

\$dbHost = '${DB_HOST}';
\$dbName = '${DB_NAME}';
\$dbUser = '${DB_USER}';
\$dbPassword = '${DB_PASSWORD}';
\$frontName = '${BACKEND_FRONTNAME}';

EOF
);
    deployConfigurator+=$(cat << 'EOF'

function updateMode($envConfig, $mode)
{
    $envConfig['MAGE_MODE'] = $mode;
    return $envConfig;
}

function updateBackendFrontName($envConfig, $frontName)
{
    $envConfig['backend'] = array('frontName' => $frontName);
    return $envConfig;
}

function updateDbConnection($envConfig, $connectionDetails)
{
    if (empty($envConfig['db'])) {
        return $envConfig;
    }
    foreach ($envConfig['db'] as $key => $connections) {
        if ($key != 'connection') {
            continue;
        }
        foreach ($connections as $connectionName => $connectionParams) {
            $envConfig['db'][$key][$connectionName] = $connectionDetails;
        }
    }

    return $envConfig;
}

function updateSessionConfiguration($envConfig, $value)
{
    $envConfig['session'] = array('save' => $value);
    return $envConfig;
}

function removeNonDefaultConfiguration($envConfig)
{
    $allowedConfigPaths = array(
        'backend',
        'crypt',
        'db',
        'resource',
        'x-frame-options',
        'MAGE_MODE',
        'session',
        'cache_types',
        'install'
    );
    foreach ($envConfig as $path => $value) {
      if (!in_array($path, $allowedConfigPaths)) {
          unset($envConfig[$path]);
      }
    }

    return $envConfig;
}
ob_start();
require 'vendor/autoload.php';
ob_end_clean();
$formatter = new Magento\Framework\App\DeploymentConfig\Writer\PhpFormatter();
$envConfig = require 'app/etc/env.php';
$envConfig = removeNonDefaultConfiguration($envConfig);
$envConfig = updateSessionConfiguration($envConfig, 'files');
$envConfig = updateDbConnection($envConfig, array(
    'host' => "$dbHost",
    'dbname' => "$dbName",
    'username' => "$dbUser",
    'password' => "$dbPassword",
    'model' => 'mysql4',
    'engine' => 'innodb',
    'initStatements' => 'SET NAMES utf8;',
    'active' => '1'
));
$envConfig = updateBackendFrontName($envConfig, $frontName);
$envConfig = updateMode($envConfig, 'default');
$data = $formatter->format($envConfig);
echo $data;
EOF
);

 echo "$deployConfigurator" | php > app/etc/env.php.generated
 mv app/etc/env.php.generated app/etc/env.php
}

function deployStaticContent()
{
    if [[ "$MAGE_MODE" == "dev" ]]
    then
        return;
    fi

    CMD="${BIN_PHP} ${BIN_MAGE} setup:static-content:deploy"
    runCommand
}

function compileDi()
{
    if [[ "$MAGE_MODE" == "dev" ]]
    then
        return;
    fi
    CMD="${BIN_PHP} ${BIN_MAGE} setup:di:compile"
    runCommand
}

function installSampleData()
{
    if ${BIN_PHP} bin/magento --version | grep -q beta
    then
        _installSampleDataForBeta;
    elif [ "$SOURCE" == 'git' ]
    then
        _installGitSampleData;
    else
        _installSampleData;
    fi
}

function _installSampleData()
{
    if ! ${BIN_PHP} bin/magento | grep -q sampledata:deploy
    then
        printString "Your version does not support sample data"
        return;
    fi

    if [ -f "${HOME}/.config/composer/auth.json" ]
    then
        if [ -d "var/composer_home" ]
        then
            CMD="cp ${HOME}/.config/composer/auth.json var/composer_home/"
            runCommand
        fi
    fi

    if [ -f "${HOME}/.composer/auth.json" ]
    then
        if [ -d "var/composer_home" ]
        then
            CMD="cp ${HOME}/.composer/auth.json var/composer_home/"
            runCommand
        fi
    fi
    if ! grep -q 'https://repo.magento.com' composer.json;
    then
        CMD="${BIN_PHP} ${BIN_COMPOSER} config repositories.magento composer https://repo.magento.com"
	runCommand
    fi

    CMD="${BIN_PHP} ${BIN_MAGE} sampledata:deploy"
    runCommand
    CMD="${BIN_PHP} ${BIN_MAGE} setup:upgrade"
    runCommand

    if [ -f "var/composer_home/auth.json" ]
    then
        CMD="rm var/composer_home/auth.json"
        runCommand
    fi
}

function _installSampleDataForBeta()
{
    CMD="${BIN_PHP} ${BIN_COMPOSER} config repositories.magento composer http://packages.magento.com"
    runCommand
    CMD="${BIN_PHP} ${BIN_COMPOSER} require magento/sample-data:~1.0.0-beta"
    runCommand
    CMD="${BIN_PHP} ${BIN_MAGE} setup:upgrade"
    runCommand
    CMD="${BIN_PHP} ${BIN_MAGE} sampledata:install admin"
    runCommand
}

function _installGitSampleData()
{
    CMD="${BIN_GIT} clone --branch $MAGENTO_VERSION $GIT_CE_SD_REPO $GIT_CE_SD_PATH"
    runCommand
    CMD="${BIN_PHP} -f $GIT_CE_SD_PATH/dev/tools/build-sample-data.php -- --ce-source=."
    runCommand

    if [[ "$GIT_EE_SD_REPO" ]] && [[ "$INSTALL_EE" ]]
    then
        CMD="${BIN_GIT} clone --branch $MAGENTO_VERSION $GIT_EE_SD_REPO $GIT_EE_SD_PATH"
        runCommand
        CMD="${BIN_PHP} -f $GIT_EE_SD_PATH/dev/tools/build-sample-data.php -- --ce-source=. --ee-source=$MAGENTO_EE_PATH"
        runCommand
    fi

    CMD="${BIN_PHP} ${BIN_MAGE} setup:upgrade"
    runCommand
}

function installB2B()
{
    if [ "${SOURCE}" == 'git' ]
    then
        CMD="${BIN_PHP} ${BIN_COMPOSER} config repositories.magento composer https://repo.magento.com/"
        runCommand
    fi
    CMD="${BIN_PHP} ${BIN_COMPOSER} require magento/extension-b2b"
    runCommand
    CMD="${BIN_PHP} ${BIN_MAGE} setup:upgrade"
    runCommand
}

function linkEnterpriseEdition()
{
    if [ "${SOURCE}" == 'composer' ]
    then
        return;
    fi
    if [ "${EE_PATH}" ] && [ "$INSTALL_EE" ]
    then
        if [ ! -d "$EE_PATH" ]
        then
            printError "There is no Enterprise Edition directory ${EE_PATH}"
            printString "Use absolute or relative path to EE code base or [N] to skip it"
            exit 1
        fi
        CMD="${BIN_PHP} ${EE_PATH}/dev/tools/build-ee.php --ce-source $(pwd) --ee-source ${EE_PATH}"
        runCommand
        CMD="cp ${EE_PATH}/composer.json $(pwd)/"
        runCommand
        CMD="cp ${EE_PATH}/composer.lock $(pwd)/"
        runCommand
    fi
}

function runComposerInstall()
{
    CMD="${BIN_PHP} ${BIN_COMPOSER} install"
    runCommand
}

function installMagento()
{
    if [ "${SOURCE}" == 'git' ]
    then
        CMD="${BIN_PHP} ${BIN_COMPOSER} config repositories.magento composer https://repo.magento.com/"
        runCommand
        # Install Bundled Extensions for version 2.2.+
        if [[ $MAGENTO_VERSION =~ ^2\.[^01]\..* ]]
        then
            for be in "${BUNDLED_EXTENSION[@]}" 
            do
                CMD="composer require --quiet ${be}"
                runCommand
            done
        fi
    fi

    CMD="rm -rf var/generation/*"
    runCommand

    CMD="${BIN_PHP} ${BIN_MAGE} --no-interaction setup:uninstall"
    runCommand

    dropDB
    createNewDB

    CMD="${BIN_PHP} ${BIN_MAGE} setup:install \
    --base-url=${BASE_URL} \
    --db-host=${DB_HOST} \
    --db-name=${DB_NAME} \
    --db-user=${DB_USER} \
    --admin-firstname=${ADMIN_FIRSTNAME} \
    --admin-lastname=${ADMIN_LASTNAME} \
    --admin-email=${ADMIN_EMAIL} \
    --admin-user=${ADMIN_NAME} \
    --admin-password=${ADMIN_PASSWORD} \
    --language=${LANGUAGE} \
    --currency=${CURRENCY} \
    --timezone=${TIMEZONE} \
    --use-rewrites=1 \
    --backend-frontname=${BACKEND_FRONTNAME}"
    if [ "${DB_PASSWORD}" ]; then
        CMD="${CMD} --db-password=${DB_PASSWORD}"
    fi
    runCommand
}

function downloadSourceCode()
{
    if [ "$(ls -A ./)" ]; then
        printError "Can't download source code from ${SOURCE} since current directory doesn't empty."
        printString "You can remove all files from current directory using next command:"
        printString "ls -A | xargs rm -rf"
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
    if [ "$INSTALL_EE" ]
    then
        CMD="${BIN_PHP} ${BIN_COMPOSER} create-project --repository-url=https://repo.magento.com/ magento/project-enterprise-edition . ${MAGENTO_VERSION}"
        runCommand
    else
        CMD="${BIN_PHP} ${BIN_COMPOSER} create-project --repository-url=https://repo.magento.com/ magento/project-community-edition . ${MAGENTO_VERSION}"
        runCommand
    fi
}

showComposerWizzard()
{
    if [ "$SOURCE" != 'composer' ]
    then
        return;
    fi
    askValue "Composer Magento version" "${MAGENTO_VERSION}"
    MAGENTO_VERSION=${READVALUE}
    if askConfirmation "Do you want to install Enterprise Edition (y/N)"
    then
        INSTALL_EE=1
    fi
    if [[ "$INSTALL_EE" ]] && askConfirmation "Do you want install B2B Extension (y/N)"
    then
        INSTALL_B2B=1
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
        INSTALL_EE=1
    fi
    if [[ "$INSTALL_EE" ]] && askConfirmation "Do you want install B2B Extension (y/N)"
    then
        INSTALL_B2B=1
    fi
}

function gitClone()
{
    validateGitRepository "${GIT_CE_REPO}" "${MAGENTO_VERSION}"
    validateGitRepository "${GIT_EE_REPO}" "${MAGENTO_VERSION}"

    CMD="${BIN_GIT} clone --branch $MAGENTO_VERSION $GIT_CE_REPO ."
    runCommand

    if [[ "$GIT_EE_REPO" ]] && [[ "$INSTALL_EE" ]]
    then
        CMD="${BIN_GIT} clone --branch $MAGENTO_VERSION $GIT_EE_REPO $EE_PATH"
        runCommand
    fi
}

function validateGitRepository()
{
    local repoName=$1
    local versionName=$2

    local isBranchExists=$(${BIN_GIT} ls-remote ${repoName} | grep -F ${versionName})
    if [ ! "$isBranchExists" ]
    then
        printError "Requested tag or branch ${versionName} does not exists in ${repoName}"
        exit 1;
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
        printError "$1 Argument is empty."
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
    local _steps="restore_db restore_code configure_db configure_files configure installB2B"
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

    _steps=(${STEPS[@]//,/ })
    STEPS=
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
    CMD="${BIN_PHP} ${BIN_MAGE} deploy:mode:set production"
    runCommand
}

function setFilesystemPermission()
{
    CMD="chmod u+x ./bin/magento"
    runCommand
    local _writeableDirectories="./var ./pub/media ./pub/static ./app/etc"
    if [ -d './generated' ]
    then
        _writeableDirectories="$_writeableDirectories ./generated"
    fi
    CMD="chmod -R 2777 ${_writeableDirectories}"
    runCommand
}

function executePostDeployScript()
{
    if [ ! "$(getRequest skipPostDeploy)" ] && [ -f "$1" ]
    then
        printString "==> Run the post deploy $1"
        source "$1";
        printString "==> Post deploy script has been finished"
    fi
    return 0;
}

function afterInstall()
{
    if [[ "$MAGE_MODE" == "production" ]]
    then
        setProductionMode
    fi
    executePostDeployScript "$(getScriptDirectory)/post-deploy"
    executePostDeployScript "$HOME/post-deploy"
    setFilesystemPermission
}

function executeSteps()
{
    local _steps=("$@")
    for step in "${_steps[@]}"
    do
        if [ "${step}" ]
        then
            CMD="${step}"
            runCommand "=> "
        fi
    done
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
    --ee                                 Install Enterprise Edition.
    --b2b                                Install B2B Extension.
    -v, --version                        Magento Version - it means: Composer version or GIT Branch
    --mode (dev, prod)                   Magento Mode. Dev mode does not generate static & di content.
    --quiet                              Quiet mode. Suppress output all commands
    --skip-post-deploy                   Skip the post deploy script if it is exist
    --step (restore_code,restore_db      Specify step through comma without spaces.
        configure_db,configure_files     - Example: $(basename "$0") --step restore_db,configure_db
        installB2B --b2b)                - Example: $(basename "$0") --step installB2B --b2b
    --restore-table                      Restore only the specific table from DB dumps
    --debug                              Enable debug mode
    --php                                Specify path to PHP CLI (php71 or /usr/bin/php71)
    _________________________________________________________________________________________________
    --ee-path (/path/to/ee)              (DEPRECATED use --ee flag) Path to Enterprise Edition.
EOF
}

function processOptions()
{
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
                # @DEPRECATED. Use --ee instead.
                checkArgumentHasValue "$1" "$2"
                EE_PATH="$2"
                INSTALL_EE=1
                shift
            ;;
            --ee)
                INSTALL_EE=1
            ;;
            --b2b)
                INSTALL_B2B=1
            ;;
            -b|--git-branch)
                # @DEPRECATED. Use -v or --version instead
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
                USE_WIZARD=0
            ;;
            --quiet)
                VERBOSE=0
            ;;
            --skip-post-deploy)
                setRequest skipPostDeploy 1
            ;;
            -h|--help)
                printUsage
                exit;
            ;;
            --code-dump)
                checkArgumentHasValue "$1" "$2"
                setRequest codedump "$2"
                shift
            ;;
            --db-dump)
                checkArgumentHasValue "$1" "$2"
                setRequest dbdump "$2"
                shift
            ;;
            --restore-table)
                checkArgumentHasValue "$1" "$2"
                setRequest restoreTableName "$2"
                shift
            ;;
            --step)
                checkArgumentHasValue "$1" "$2"
                STEPS=($2)
                shift
                ;;
            --debug)
              set -o xtrace;
            ;;
            --php)
                checkArgumentHasValue "$1" "$2"
                BIN_PHP=$2
                shift
            ;;
        esac
        shift
    done
}
################################################################################
# Action Controllers
################################################################################
function magentoInstallAction()
{
    if [[ "${SOURCE}" ]]
    then
        if [ "$(ls -A)" ] && askConfirmation "Current directory is not empty. Do you want to clean current Directory (y/N)"
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
    if [[ "$INSTALL_EE" ]] && [[ "$INSTALL_B2B" ]]
    then
        addStep "installB2B"
    fi
}

function magentoDeployDumpsAction()
{
    addStep "restore_code"
    addStep "configure_files"
    addStep "restore_db"
    addStep "configure_db"
    addStep "validateDeploymentFromDumps"
    addStep "appConfigImport"
}

function restoreTableAction()
{

    CMD="{ echo 'SET FOREIGN_KEY_CHECKS=0;';
       echo 'TRUNCATE ${DB_NAME}.$(getTablePrefix)$(getRequest restoreTableName);';
       zgrep 'INSERT INTO \`$(getRequest restoreTableName)\`' $(getDbDumpFilename); }
       | ${BIN_MYSQL} -h${DB_HOST} -u${DB_USER} --password=\"${DB_PASSWORD}\" --force $DB_NAME";
    runCommand
}

function magentoCustomStepsAction()
{
    prepareSteps
}

################################################################################
# Main
################################################################################

export LC_CTYPE=C
export LANG=C

function main()
{
    loadConfigFile $(getConfigFiles)
    processOptions "$@"
    initQuietMode
    printString Current Directory: "$(pwd)"
    printString "Configuration loaded from: $(getConfigFiles)"
    checkDependencies
    showWizard

    START_TIME=$(date +%s)
    if [[ "${STEPS[@]}" ]]
    then
        magentoCustomStepsAction;
    elif foundSupportBackupFiles
    then
        if getRequest restoreTableName
        then
            restoreTableAction
        else
            magentoDeployDumpsAction;
        fi
    else
        magentoInstallAction;
    fi
    addStep "afterInstall"
    executeSteps "${STEPS[@]}"

    END_TIME=$(date +%s)
    SUMMARY_TIME=$((((END_TIME - START_TIME)) / 60));
    printString "$(basename "$0") took $SUMMARY_TIME minutes to complete install/deploy process"

    printLine
    printString "${BASE_URL}"
    printString "${BASE_URL}${BACKEND_FRONTNAME}"
    printString "User: ${ADMIN_NAME}"
    printString "Pass: ${ADMIN_PASSWORD}"
    promptSaveConfig
}
main "${@}"
