# Magento 2 Bash Install/Restore Script 
[![Build Status](https://travis-ci.org/yvoronoy/m2install.svg?branch=master)](https://travis-ci.org/yvoronoy/m2install) [![Code Climate](https://codeclimate.com/github/yvoronoy/m2install/badges/gpa.svg)](https://codeclimate.com/github/yvoronoy/m2install) [![Packagist](https://img.shields.io/packagist/v/yvoronoy/m2install.svg?maxAge=2592000)](https://packagist.org/packages/yvoronoy/m2install) [![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed/yvoronoy/m2install.svg?maxAge=2592000)](https://github.com/yvoronoy/m2install/pulls?q=is%3Apr+is%3Aclosed) [![GitHub closed issues](https://img.shields.io/github/issues-closed/yvoronoy/m2install.svg?maxAge=2592000)](https://github.com/yvoronoy/m2install/issues?q=is%3Aissue+is%3Aclosed)

This script is designed to simplify the installation process of Magento 2 and rapid deployment of merchant code and DB dumps.

m2install can be a helpful tool for support teams and teams who often need to install or deploy merchant backups or dumps.

The main purpose of this script is run m2install, wait a bit and get a working magento instance.
Don't waste time on routine operations.

If you have any issues please report them to https://github.com/yvoronoy/m2install/issues

## What can m2install exactly do?
 - Can automatically restore backup files created by 
  - `php bin/magento setup:backup --code --db`
 - Can automatically restore support dumps created by Enterpsie Support Tool 
  - `php bin/magento support:backup:code (db)`
 - Script can automatically install vanilla magento

## Installation
Download latest version by curl
```
curl -o m2install.sh https://raw.githubusercontent.com/yvoronoy/m2install/master/m2install.sh
```

You can install by composer
```
composer require yvoronoy/m2install
```

In case you are using `bash completion` you can download completion for this script.
```
#For Linux User
curl -o /etc/bash_completion.d/m2install-bash-completion https://raw.githubusercontent.com/yvoronoy/m2install/master/m2install-bash-completion

#For OSX User with brew
curl -o /usr/local/etc/bash_completion.d/m2install-bash-completion https://raw.githubusercontent.com/yvoronoy/m2install/master/m2install-bash-completion
```

## Usage
```
$ m2install.sh --help
m2install.sh is designed to simplify the installation process of Magento 2
and deployment of client dumps created by Magento 2 Support Extension.

Usage: m2install.sh [options]
Options:
    -h, --help                           Get this help.
    -s, --source (git, composer)         Get source code.
    -f, --force                          Install/Restore without any confirmations.
    --sample-data (yes, no)              Install sample data.
    --ee-path (/path/to/ee)              Path to Enterprise Edition.
    --git-branch (branch name)           Specify Git Branch.
    --mode (dev, prod)                   Magento Mode. Dev mode does not generate static & di content.
    --quiet                              Quiet mode. Suppress output all commands
```

## How to deploy backup/support dumps
In order to deploy the customer dumps you need:
 
 * Put DB and code dumps to new directory
 * Go to directory and run m2install

## How to install Magento 2 using GIT
To install Magento 2 from git repository run m2install with --source git param
 * ```m2install --source git``` or
 * ```m2install -s git```

## How to install Magento 2 using Composer
To install Magento 2 from composer run m2install with --source composer param
 * ```m2install --source composer``` or
 * ```m2install -s composer```


#### How to Install Magento 2 with Sample Data
 * Run m2install
 * Use wizard to install the sample data.
 
 
#### How to Install Magento 2 with B2B extension
With wizard
 * Run m2install
 * Use wizard to install the B2B
 
With CLI flags
 * ```m2install --ee --b2b``` or
 * ```m2install --step installB2B --b2b``` if you already have Magento EE
 
Remember that you have to install Enterprise Edition to be able to install B2B extension 

## Wizard
m2install shows you wizard on first run and prompts to save entered values to config file.
```
$ m2install.sh 
Current Directory: /Users/yvoronoy/Sites/m2/ee202
Configuration loaded from:
Enter Server Name of Document Root (default: http://mage2.dev/): 
Enter Base Path (default: ee202): 
Enter DB Host (default: localhost): 
Enter DB User (default: root): 
Enter DB Password: 
Enter DB Name (default: root_ee202): 
Do you want to install Sample Data (y/N) n
Enter Path to EE or [nN] to skip EE installation: n
--------------------------------------------------
BASE URL: http://mage2.dev/ee202/
DB PARAM: root@localhost
DB NAME: root_ee202
Sample Data will NOT be installed.
Magento EE will NOT be installed.
In order to generate static/di content, add mode param: m2install.sh --mode prod
Are you sure? [y/N] 
```

## How to use configuration files
The config file allows you to store params for DB and URL.
Example of config file
```
HTTP_HOST=http://your-mage-host.com/
BASE_PATH=your/base/path/${CURRENT_DIR_NAME}
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=dbpassword
```

When you first run m2install script, it shows wizard which prompts to save the config file to your home directory.

m2install uses fallback mechanism to find config files recursively from home directory to current directory.
For example if you want to install magento to directory 
~/www/m2/ga/magento2ee

you can override config file which is placed in your home directory.
```
~/.m2install.conf
~/www/.m2install.conf
~/www/m2/.m2install.conf
~/www/m2/ga/.m2install.conf
~/www/m2/ga/magento2ee/.m2install.conf
```


