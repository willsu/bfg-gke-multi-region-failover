#!/bin/bash
set -eux

pushd .
cd ../jobs
./build-backup-docker-image.sh
./build-failover-docker-image.sh

cd ../apps
./build-client-docker-image.sh
./build-writer-docker-image.sh

popd
