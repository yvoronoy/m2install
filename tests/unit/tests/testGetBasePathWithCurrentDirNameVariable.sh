#!/usr/bin/env bash

setRequest basePath ''
assert getBasePathWithCurrentDirNameVariable '';

setRequest basePath 'a'
assert getBasePathWithCurrentDirNameVariable '$CURRENT_DIR_NAME';

setRequest basePath 'a/b'
assert getBasePathWithCurrentDirNameVariable 'a/$CURRENT_DIR_NAME';

setRequest basePath 'a/b/c/'
assert getBasePathWithCurrentDirNameVariable 'a/b/$CURRENT_DIR_NAME';

setRequest basePath '/'
assert getBasePathWithCurrentDirNameVariable '';

setRequest basePath '//'
assert getBasePathWithCurrentDirNameVariable '';
