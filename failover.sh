#!/bin/bash
set -eux

# Configure kubectl to point to DR cluster
gcloud container clusters get-credentials $TARGET_CLUSTER \
  --region $DR_REGION

# Stop disk replication on the target disk
gcloud compute disks stop-async-replication $SOURCE_PD_NAME \
  --region=$REGION

# Find the replication disks name in the DR region
export PD_NAME=$(gcloud compute disks describe $SOURCE_PD_NAME \
  --region=$REGION \
  --format="json" | \
  jq -r '.asyncSecondaryDisks | keys[]' | \
  awk -F'/' '{print $NF}')

# Apply the PV yaml to the DR region before the backup is restored
REGION_BAK=$REGION
export REGION=$DR_REGION
envsubst < kustomize/pv-base/pv-kustomize-config.yaml.tpl > kustomize/pv-base/pv-kustomize-config.yaml
kubectl apply -k kustomize/pv-base
# TODO: change names of vars in the template to stop this variable jugglins
export REGION=$REGION_BAK

RAND_4_CHAR=$(tr -dc '[:lower:]' </dev/urandom | head -c 4)
export NEW_PD_NAME="${SOURCE_PD_NAME}-${RAND_4_CHAR}"

# Find the lastest backup
LATEST_BACKUP=$(gcloud beta container backup-restore backups list \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=$BACKUP_PLAN_NAME-$REGION \
  --format="json" |  jq -r 'sort_by(.createTime) | last | .name')

# Run the backup restoration process
gcloud beta container backup-restore restores create $RESTORE_NAME-$RAND_4_CHAR \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME-$REGION \
  --backup=$LATEST_BACKUP \
  --wait-for-completion

# To help with idempotency, ensure that async replication is not already running on the target PD.
SECONDARY_ASYNC_EXISTS=$(gcloud compute disks describe "$TARGET_PD_NAME" \
    --region=$DR_REGION \
    --project="$PROJECT_ID" \
    --format=json \
    | jq -r '.resourceStatus.asyncPrimaryDisk.state == "RUNNING"')

if [ "$SECONDARY_ASYNC_EXISTS" == "false" ]; then
  # Start replication from the DR Region back to the Source Region.
  gcloud compute disks create $NEW_PD_NAME \
    --region=$REGION \
    --size=$PD_SIZE_GB \
    --type pd-balanced \
    --primary-disk=$TARGET_PD_NAME \
    --primary-disk-region=$DR_REGION \
    --primary-disk-project=$PROJECT_ID \
    --replica-zones=$SOURCE_PD_REPLICA_ZONES

  gcloud compute disks start-async-replication $TARGET_PD_NAME \
    --region=$DR_REGION \
    --secondary-disk=$NEW_PD_NAME \
    --secondary-disk-region=$REGION \
    --secondary-disk-project=$PROJECT_ID
fi

# Configure kubectl to source to DR cluster
gcloud container clusters get-credentials $TARGET_CLUSTER \
  --region $DR_REGION
