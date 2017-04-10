#!/usr/bin/env bash

${BIN_M2INSTALL} --force --source composer --ee -v 2.1.5 --quiet
assertEqual "Magento_SampleData" $(bin/magento module:status --no-ansi | grep Magento_SampleData) "Should be with Sample Data"
