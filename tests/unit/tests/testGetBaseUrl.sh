#!/usr/bin/env bash

assert getBaseUrl 'http://127.0.0.1/'

setRequest hostName example.com
setRequest basePath m2/2.1.7
assert getBaseUrl 'http://example.com/m2/2.1.7/'

setRequest hostName /example.com/
setRequest basePath /m2/2.1.7/
assert getBaseUrl 'http://example.com/m2/2.1.7/'

setRequest hostName /example.com/
setRequest basePath ''
assert getBaseUrl 'http://example.com/'

setRequest hostName ''
setRequest basePath 'm2ee'
assert getBaseUrl 'http://127.0.0.1/m2ee/'

setRequest hostName 'https://exam.com//'
setRequest basePath 'm2ee'
assert getBaseUrl 'https://exam.com/m2ee/'
