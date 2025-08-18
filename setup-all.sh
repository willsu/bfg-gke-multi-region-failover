#!/bin/bash
set -eux

pushd .
cd setup-scripts

./setup-enable-apis.sh
./setup-pds.sh
./setup-ar.sh
./setup-build-all-containers.sh
./setup-network.sh
./setup-clusters.sh
../utility-scripts/apply-k8s.sh
./setup-bfg.sh
./setup-cloud-run-scheduled-job.sh
./setup-cloud-run-client.sh
./setup-dns.sh
./setup-create-storage-bucket.sh
./setup-cloud-run-job-invoker.sh
./setup-automated-failover.sh
../jobs/create-backup.sh

popd