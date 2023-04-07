#!/usr/bin/env bash

set -eu

PGPASSWORD=password pg_restore --verbose --clean --no-acl --no-owner -h localhost -U root -p 8241 -d reckoning_dev ./dumps/latest.dump
