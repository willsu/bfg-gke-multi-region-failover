#!/bin/bash
set -eux

envsubst < k8s_manifests/ns.yaml.tpl | kubectl apply -f -
envsubst < k8s_manifests/pv.yaml.tpl | kubectl apply -f -
envsubst < k8s_manifests/pvc.yaml.tpl | kubectl apply -f -
envsubst < k8s_manifests/deployment.yaml.tpl | kubectl apply -f -

echo "setup finished.. examine the state of the k8s resources in the 'bfg' namespace"
