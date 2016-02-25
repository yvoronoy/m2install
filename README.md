#Magento 2 Bash Installer Script
This script is designed to simplify the installation process of Magento 2 and rapid deployment of client dumps created by Magento 2 Support Extension.

If you have any issues please report it to https://github.com/yvoronoy/m2install/issues

##How to install Magento 2 using GIT
To install Magento 2 from git repository run m2install with --source git param
 * ```m2install --source git``` or
 * ```m2install -s git```

##How to install Magento 2 using Composer
To install Magento 2 from git repository run m2install with --source git param
 * ```m2install --source composer``` or
 * ```m2install -s composer```

##How to deploy dumps
In order to deploy the customer dumps you need:
 
 * Put DB dump and code dump to directory
 * Run m2install

####How to Install Magento 2 with Sample Data
 * Run m2install
 * Use wizzard to install the sample data.

##How to use configuration files
The config file allows you to store params for DB and URL.
Example of config file
```
HTTP_HOST=http://your-mage-host.com/
BASE_PATH=your/base/path/${CURRENT_DIR_NAME}
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=dbpassword
```

When you first run m2install script, it will show wizzard which prompt to save the config file in your home directory.

m2install using fallback mechanism to find config files recursive from home directory to current directory.
For example if you want install magento to directory 
~/www/m2/ga/magento2ee

you can override config file which placed in your home directory.
```
~/.m2install.conf
~/www/.m2install.conf
~/www/m2/.m2install.conf
~/www/m2/ga/.m2install.conf
~/www/m2/ga/magento2ee/.m2install.conf
```


