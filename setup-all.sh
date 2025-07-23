#!/bin/bash
set -eux

./setup-pds.sh
./setup-ar.sh
./setup-build-backup-docker-image.sh
./setup-build-writer-docker-image.sh
./setup-network.sh
./setup-clusters.sh
./setup-add-console-ip.sh
./setup-apply-k8s.sh
./setup-bfg.sh
./setup-cloud-run-scheduled-job.sh
./setup-create-storage-bucket.sh
./create-backup.sh
