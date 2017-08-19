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

function setHostName()
{
    setRequest hostName "$1"
}

function getHostName()
{
    if [ -z "$(getRequest hostName)" ]
    then
        setHostName ${HTTP_HOST:-127.0.0.1}
    fi
    if ! grep -q "http" <<<$(getRequest hostName);
    then
        setHostName "http://$(getRequest hostName | sed 's/\/*//')"
    fi
    echo $(getRequest hostName) | sed 's/\/*$/\//';

}

function getBaseUrl()
{
    local baseURL="$(getHostName)$(getBasePath)";
    local regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    if [[ ${baseURL} =~ $regex ]] || [[ "${baseURL}" == 'localhost/' ]]
    then
        echo $baseURL;
    else
        printError "BASE URL [$baseURL] is invalid should be in following format http[s]://host-name[/base/path/]";
    fi
}
