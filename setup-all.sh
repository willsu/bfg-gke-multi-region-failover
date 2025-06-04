#!/bin/bash
set -eux

source configure.sh
./setup-pds.sh
./setup-ar.sh
./setup-build-docker-image.sh
./setup-network.sh
./setup-clusters.sh
./setup-add-console-ip.sh
./setup-apply-k8s.sh
./setup-bfg.sh
