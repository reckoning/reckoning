#!/usr/bin/env bash

set -eu

pg_restore --verbose --clean --no-acl --no-owner -h localhost -d reckoning_dev ./dumps/latest.dump
