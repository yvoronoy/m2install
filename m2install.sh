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
CURRENT_DIR_NAME=$(basename $(pwd))
HTTP_HOST=http://mage2.dev/
BASE_PATH=${CURRENT_DIR_NAME}
BASE_URL=${HTTP_HOST}${BASE_PATH}/
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=
USE_SAMPLE_DATA=
MAGENTO_EE_PATH=
CONFIG_PATH=~/.m2install.conf

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
    if [ -z "${READVALUE}" ] && [ "${READ_DEFAULT_VALUE}" ]
    then
        READVALUE=${READ_DEFAULT_VALUE}
    fi
}

function generateDBName()
{
    DB_NAME=${DB_USER}_$(echo "$BASE_PATH" | sed "s/\//_/g" | sed "s/[^a-zA-Z0-9_]//g" | tr '[A-Z]' '[a-z]');
}

function printLine()
{
    printf '%50s\n' | tr ' ' -
}

asksure() {
    echo -n "Are you sure (Y/N)? "
    while read -r -n 1 -s answer; do
        if [[ $answer = [YyNn] ]]; then
            [[ $answer = [Yy] ]] && retval=0
            [[ $answer = [Nn] ]] && retval=1
            break
        fi
    done
    echo ""
    return $retval
}

function wizard()
{
    askValue "Enter Server Name of Document Root" ${HTTP_HOST}
    HTTP_HOST=${READVALUE}
    askValue "Enter Base Path" ${BASE_PATH}
    BASE_PATH=${READVALUE}
    BASE_PATH=$(echo ${BASE_PATH} | sed "s/^\///g" | sed "s/\/$//g" );
    askValue "Enter DB Host" ${DB_HOST}
    DB_HOST=${READVALUE}
    askValue "Enter DB User" ${DB_USER}
    DB_USER=${READVALUE}
    askValue "Enter DB Password" ${DB_PASSWORD}
    DB_PASSWORD=${READVALUE}
    askValue "Enter DB Name" ${DB_NAME}
    DB_NAME=${READVALUE}
    askValue "Install Sample Data"
    USE_SAMPLE_DATA=${READVALUE}
    askValue "Enter Absoulute Path to Enterprise Edition"
    MAGENTO_EE_PATH=${READVALUE}

    printLine

    BASE_URL=${HTTP_HOST}${BASE_PATH}/
    echo "BASE URL: ${BASE_URL}"
    echo "DB PARAM: ${DB_USER}@${DB_HOST}"
    echo "DB NAME: ${DB_NAME}"
    if [ "${USE_SAMPLE_DATA}" ]
    then
        echo "Sample Data will be installed"
    fi
    if [ "${MAGENTO_EE_PATH}" ]
    then
        echo "Magento EE will be installed"
        echo "Magento EE Path: ${MAGENTO_EE_PATH}"
    fi
    if asksure;
    then
        printLine
    else
        exit 1;
    fi
}

# Run Command
function runCommand()
{
    if [[ "$VERBOSE" -eq 1 ]]
    then
        echo $CMD;
    fi

    eval $CMD;
}

################################################################################

pwd
if [ -f "$CONFIG_PATH" ]
then
    source ${CONFIG_PATH}
fi
generateDBName
wizard

if [ "${MAGENTO_EE_PATH}" ]
then
    CMD="php ${MAGENTO_EE_PATH}/dev/tools/build-ee.php --ce-source $(pwd) --ee-source=${MAGENTO_EE_PATH}"
    runCommand
    CMD="cp ${MAGENTO_EE_PATH}/composer.json $(pwd)/"
    runCommand
    CMD="rm -rf $(pwd)/composer.lock"
    runCommand
fi

CMD="chmod -R 0777 ./var ./pub/media ./pub/static ./app/etc"
runCommand

CMD="composer install"
runCommand

CMD="cd ./bin"
runCommand

CMD="php ./magento setup:uninstall"
runCommand

CMD="mysqladmin -h${DB_HOST} -u${DB_USER}"
if [ "${DB_PASSWORD}" ]
then
    CMD="${CMD} -p${DB_PASSWORD}"
fi
CMD="${CMD} drop ${DB_NAME}"
runCommand

CMD="mysqladmin -h${DB_HOST} -u${DB_USER}"
if [ "${DB_PASSWORD}" ]
then
    CMD="${CMD} -p${DB_PASSWORD}"
fi
CMD="${CMD} create ${DB_NAME}"
runCommand

CMD="php -d memory_limit=2G ./magento setup:install --base-url=${BASE_URL} \
--db-host=${DB_HOST} --db-name=${DB_NAME} --db-user=${DB_USER}  \
--admin-firstname=Magento --admin-lastname=User --admin-email=mail@magento.com \
--admin-user=admin --admin-password=123123q --language=en_US \
--currency=USD --timezone=America/Chicago --use-rewrites=1"
if [ "${DB_PASSWORD}" ]
then
    CMD="${CMD} --db-password=${DB_PASSWORD}"
fi
runCommand

CMD="cd ../"
runCommand

if [ "${USE_SAMPLE_DATA}" ]
then
    CMD="composer config repositories.magento composer http://packages.magento.com"
    runCommand
    CMD="composer require magento/sample-data:~1.0.0-beta"
    runCommand
    CMD="php bin/magento setup:upgrade"
    runCommand
    CMD="php -dmemory_limit=2G bin/magento sampledata:install admin"
    runCommand
fi
