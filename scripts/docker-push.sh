#!/usr/bin/env bash

set -eu

pushd docker

echo
echo "Build Container..."
echo

docker build -t reckoning/app:3.2.2 .

echo
echo "Push Container..."
echo

docker push reckoning/app:3.2.2

echo
echo "...Done"
echo

popd
