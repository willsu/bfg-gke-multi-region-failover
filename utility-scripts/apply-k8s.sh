#!/bin/bash
set -eux

# Template vars are already exported
envsubst < ../kustomize/base/kustomize-config.yaml.tpl > ../kustomize/base/kustomize-config.yaml

TMP_DIR=$(mktemp -d)
export TPL_NAMESPACE=$NAMESPACE
export TPL_PV_VOLUME_HANDLE="projects/${PROJECT_ID}/regions/${REGION}/disks/${SOURCE_PD_NAME}"
export TPL_PV_STORAGE_CAPACITY="$PD_SIZE"
export TPL_PV_NAME="disk-writer-pv"
envsubst < ../pv-base/namespace.yaml.tpl > ${TMP_DIR}/${TPL_PV_NAME}-ns.yaml
envsubst < ../pv-base/pv.yaml.tpl > ${TMP_DIR}/${TPL_PV_NAME}.yaml

# Apply base resources using kustomize
kubectl apply -k ../kustomize/base
# Apply PV resources
kubectl apply -f $TMP_DIR

echo "setup finished.. examine the state of the k8s resources in the '$NAMESPACE' namespace"
