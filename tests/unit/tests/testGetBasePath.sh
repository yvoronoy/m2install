#!/usr/bin/env bash

setRequest basePath ''
assert getBasePath ''

setRequest basePath '/'
assert getBasePath ''

setRequest basePath '/ee'
assert getBasePath 'ee/'

setRequest basePath '/ee/abc/'
assert getBasePath 'ee/abc/'

setRequest basePath 'ee/abc//'
assert getBasePath 'ee/abc/'
