#!/usr/bin/env bash

setRequest abc
assert "getRequest abc"

setRequest abc 1
assert "getRequest abc" 1

setRequest myVariable Value
assert "getRequest myVariable" Value
