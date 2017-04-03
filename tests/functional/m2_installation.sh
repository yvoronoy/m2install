#!/usr/bin/env bash

touch ~/.m2install.conf
mkdir magento;
cd magento;
../m2install.sh --force --source composer --ee -v 2.1.5

[[ "$(php bin/magento -V --no-ansi)" != "Magento CLI version 2.1.5" ]] && return 1
