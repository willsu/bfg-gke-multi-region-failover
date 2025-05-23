#!/bin/bash
set -eux

source configure.sh
./setup-pds.sh
./setup-ar.sh
./setup-build-docker-image.sh
./setup-network.sh
./setup-clusters.sh

kubectl create ns bfg
kubectl apply -f pv.yaml,pvc.yaml,deployment.yaml
echo "setup finished.. examine the state of the k8s resources in the 'bfg' namespace"

./setup-bfg.sh
