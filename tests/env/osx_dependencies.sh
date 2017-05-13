#!/bin/bash

# enable ccache
brew install ccache
PATH=$PATH:/usr/local/opt/ccache/libexec

# update brew and add repositories
brew update
brew tap homebrew/dupes
brew tap homebrew/versions
brew tap homebrew/homebrew-php

# install PHP
brew install php70

# Install php extensions from source because of some bug described here:
# https://github.com/Homebrew/homebrew-php/issues/2440
brew install -fs php70-intl php70-mcrypt

# Install MySQL
brew install mysql

# Start MySQL service
brew services start mysql

# Wait 10 seconds until MySQL service start
sleep 10

# install composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir="/usr/local/bin" --filename="composer"
