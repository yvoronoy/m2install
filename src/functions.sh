#!/usr/bin/env bash

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

function getBasePath()
{
    local basePath=$(echo "$(getRequest basePath)");

    case "$basePath" in
        "." | '/' | './' | '')
            basePath=
            ;;
    esac
    echo ${basePath} | sed 's/\/*$/\//' | sed 's/^[.]*\/*//';
}

function getBasePathWithCurrentDirNameVariable()
{
    local basePath=$(getBasePath);
    if [ "$(getBasePath)" ]
    then
        basePath='$CURRENT_DIR_NAME'
        if [[ "$(dirname $(getBasePath))" != "." ]]
        then
            basePath=$(dirname $(getBasePath))/\$CURRENT_DIR_NAME
        fi
    fi
    echo ${basePath};
}

function getDbName()
{
    local dbName=$(getRequest dbName);
    if [ -z "${dbName}" ]
    then
        dbName=$(getDbUser)_${CURRENT_DIR_NAME}
        if [ "$(getBasePath)" ]
        then
            dbName=$(getDbUser)_$(getBasePath)
        fi
        dbName=$(echo ${dbName} | sed 's/\/*$//' | sed 's/^_//');
    fi
    echo $(sed -e "s/\//_/g; s/[^a-zA-Z0-9_]//g;" <(php -r "print strtolower('$dbName');"));
}

function getDbUser()
{
    if [ -z "$(getRequest dbUser)" ]
    then
        setRequest dbUser ${DB_USER}
    fi

    echo $(getRequest dbUser);
}
