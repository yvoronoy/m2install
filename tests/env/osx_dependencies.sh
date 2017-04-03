#!/bin/bash

# update brew and add repositories
brew update
brew tap homebrew/dupes
brew tap homebrew/versions
brew tap homebrew/homebrew-php

# install PHP
brew install php70

# install composer
curl -sS https://getcomposer.org/installer | php

alias composer='/Users/travis/build/yyevgenii/m2install/composer.phar'
