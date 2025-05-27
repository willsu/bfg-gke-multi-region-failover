#!/bin/bash
set -eux

envsubst < kustomize/base/kustomize-config.yaml.tpl > kustomize/base/kustomize-config.yaml
kubectl apply -k kustomize/base

echo "setup finished.. examine the state of the k8s resources in the 'bfg' namespace"
