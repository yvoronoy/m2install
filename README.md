#Magento 2 Bash Installer Script
This script is designed to simplify the installation process of Magento 2 and rapid deployment of client dumps created by Magento 2 Support Extension.

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
##How to deploy dumps
In order to deploy the customer dumps you need:
 
 * Put DB dump and code dump to directory
 * Run m2install

##How to install Magento 2
 * Use git to get the source code of magento 2
 * git clone https://github.com/magento/magento2.git
 * cd magento2
 * Run m2install

####How to Install Magento Enterprise
 * Use git to get the source code Magento EE
 * Directory with the magento2ee should be INSIDE the directory with the magento2ce.
 * Run m2install

####How to Install Magento 2 with Sample Data
 * Run m2install
 * Use wizzard to install the sample data. (TODO add a parameter)


