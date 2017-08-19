#!/usr/bin/env bash

set -e

function loadAssertFramework()
{
    if [ ! -f assert.sh ]
    then
        wget https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
        mv assert.sh $(getUnitTestDirectory)/assert.sh
    fi

    source assert.sh
}

function getUnitTestDirectory()
{
    echo $(getProjectRootDirectory)/tests/unit;
}

function getProjectRootDirectory()
{
    echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../..";
    return 0;
}

####################################

loadAssertFramework;
source $(getProjectRootDirectory)/src/functions.sh
for file in $(getUnitTestDirectory)/tests/test*.sh
do
    source ${file}
done

assert_end regression





