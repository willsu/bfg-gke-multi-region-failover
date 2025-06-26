#!/bin/bash
set -eux

# Configure kubectl to point to Source cluster
gcloud container clusters get-credentials $SOURCE_CLUSTER \
  --region $REGION

export TPL_DISK_WRITER_PV_VOLUME_HANDLE="projects/${PROJECT_ID}/regions/${REGION}/disks/${SOURCE_PD_NAME}"
envsubst < kustomize/base/kustomize-config.yaml.tpl > kustomize/base/kustomize-config.yaml
envsubst < kustomize/pv-base/pv-kustomize-config.yaml.tpl > kustomize/pv-base/pv-kustomize-config.yaml

kubectl apply -k kustomize/base
kubectl apply -k kustomize/pv-base

echo "setup finished.. examine the state of the k8s resources in the '$NAMESPACE' namespace"
