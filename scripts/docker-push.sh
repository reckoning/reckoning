#!/usr/bin/env bash

set -eu

pushd docker

echo
echo "Build Container..."
echo

docker build -t reckoning/app:2.5.1 .

echo
echo "Push Container..."
echo

docker push reckoning/app:2.5.1

echo
echo "...Done"
echo

popd
