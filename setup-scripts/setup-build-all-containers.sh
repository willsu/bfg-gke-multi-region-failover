#!/bin/bash
set -eux

pushd .
cd ../jobs/backup
./build-backup-docker-image.sh
cd ../failover
./build-failover-docker-image.sh

cd ../../apps/disk-client
./build-client-docker-image.sh
cd ../disk-writer
./build-writer-docker-image.sh
cd ../job-invoker
./build-job-invoker-docker-image.sh

popd
