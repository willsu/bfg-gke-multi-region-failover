#!/bin/bash
set -eux

export SOURCE_PD_NAME="will-test-pd-central1"
export TARGET_PD_NAME="will-test-pd-west1"

REGION_BAK=$REGION
export REGION=$DR_REGION
export DR_REGION=$REGION_BAK

SOURCE_PD_REPLICA_ZONES_BAK=$SOURCE_PD_REPLICA_ZONES
SOURCE_PD_REPLICA_ZONES=$TARGET_PD_REPLICA_ZONES
TARGET_PD_REPLICA_ZONES=$SOURCE_PD_REPLICA_ZONES_BAK

../setup-scripts/setup-pds.sh

TMP_DIR=$(mktemp -d)
export TPL_NAMESPACE=$NAMESPACE
export TPL_PV_VOLUME_HANDLE="projects/${PROJECT_ID}/regions/${REGION}/disks/${SOURCE_PD_NAME}"
export TPL_PV_STORAGE_CAPACITY="$PD_SIZE"
export TPL_PV_NAME="will-test-pd"
envsubst < ../pv-base/pv.yaml.tpl > ${TMP_DIR}/${TPL_PV_NAME}.yaml

# Apply PV resources
kubectl apply -f $TMP_DIR
