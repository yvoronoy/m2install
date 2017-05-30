#!/usr/bin/env bash

# Add PHP 7 repository
sudo sh -c "echo 'deb http://ppa.launchpad.net/ondrej/php/ubuntu trusty main' > /etc/apt/sources.list.d/ondrej-php-trusty.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C
sudo apt-get update

PACKAGES=(
    mysql-server-5.6
    mysql-client-5.6
    mysql-client-core-5.6
    php7.0
    php7.0-fpm
    php7.0-common
    php7.0-bcmath
    php7.0-curl
    php7.0-gd
    php7.0-json
    php7.0-intl
    php7.0-mbstring
    php7.0-mcrypt
    php7.0-mysql
    php7.0-soap
    php7.0-xml
    php7.0-zip
)

# Install packages
sudo apt-get install -y "${PACKAGES[@]}"

# Start MySQL service
sudo service mysql start

# Install composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir="/usr/local/bin" --filename="composer"
