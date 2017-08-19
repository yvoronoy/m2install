#!/usr/bin/env bash

DB_USER=root;
assert getDbUser 'root'
unset DB_USER;

assert getDbUser '';

setRequest dbUser 'user'
assert getDbUser 'user'

