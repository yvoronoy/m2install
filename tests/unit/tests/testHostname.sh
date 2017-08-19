#!/usr/bin/env bash

setRequest hostName ''
assert getHostName 'http://127.0.0.1/'

setRequest hostName abc.com
assert getHostName 'http://abc.com/'

setRequest hostName abc/
assert getHostName 'http://abc/'

setRequest hostName http://abc.com/
assert getHostName 'http://abc.com/'

setRequest hostName https://abc.com/
assert getHostName 'https://abc.com/'

