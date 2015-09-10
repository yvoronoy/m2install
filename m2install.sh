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
HOST=http://mage2.dev/${CURRENT_DIR_NAME}/
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=root
DB_NAME=$(echo "$CURRENT_DIR_NAME" | sed "s/[^a-zA-Z0-9_]//g" | tr '[A-Z]' '[a-z]');

# Run Command
function runCommand()
{
    if [[ "$VERBOSE" -eq 1 ]]
    then
        echo $CMD;
    fi

    eval $CMD;
}

CMD="mysqladmin -h${DB_HOST} -u${DB_USER} -p${DB_PASSWORD} create ${DB_NAME}"
runCommand

CMD="chmod -R 0777 ./var ./pub/media ./pub/static ./app/etc"
runCommand

CMD="composer install"
runCommand

CMD="cd ./bin"
runCommand

CMD="php ./magento setup:uninstall"
runCommand

CMD="php ./magento setup:install --base-url=${HOST} \
--db-host=${DB_HOST} --db-name=${DB_NAME} --db-user=${DB_USER} --db-password=${DB_PASSWORD} \
--admin-firstname=Magento --admin-lastname=User --admin-email=mail@magento.com \
--admin-user=admin --admin-password=123123q --language=en_US \
--currency=USD --timezone=America/Chicago --use-rewrites=1"
runCommand

