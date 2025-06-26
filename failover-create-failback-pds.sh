#!/bin/bash
set -eux

# NOTE: REGION, etc should be set to the "failed" source region
# This script is designed to be (attempted to) run during the failover process 

# LATEST_BACKUP_SHORT_NAME must to be set externally by the caller
RAND_4_CHAR="${LATEST_BACKUP_SHORT_NAME##*-}"
PV_JSON_BLOB=$(gcloud storage cat gs://${PV_STORAGE_BUCKET}/${LATEST_BACKUP_SHORT_NAME}-pv-mapping)

# Check if the JSON blob is empty or just an empty object (no matching PVs)
if [[ -z "$PV_JSON_BLOB" || "$PV_JSON_BLOB" == "{}" ]]; then
  echo "No Persistent Volumes found in json blob"
  exit 1
fi

# Parse the JSON blob into the PV_MAP associative array
PV_SOURCE_AND_TARGETS=$(echo "$PV_JSON_BLOB" | jq -r 'to_entries[] | "\(.key) \(.value.sourceVolume) \(.value.targetVolume)"')

# Create new target disks in the source region (if possible)
# and start async replication
while IFS=' ' read -r pv_name source_volume_handle target_volume_handle; do
  SOURCE_VOLUME_SHORT_NAME=$(echo $source_volume_handle | awk -F'/' '{print $NF}')

  TARGET_VOLUME_PD_NAME=$(echo $target_volume_handle | awk -F'/' '{print $NF}')

  # To help with idempotency, ensure that async replication is not already running on the target PD.
  SECONDARY_ASYNC_EXISTS=$(gcloud compute disks describe "$TARGET_VOLUME_PD_NAME" \
    --region=$DR_REGION \
    --project="$PROJECT_ID" \
    --format=json \
    | jq -r '.resourceStatus.asyncPrimaryDisk.state == "RUNNING"')

  if [ "$SECONDARY_ASYNC_EXISTS" == "false" ]; then
    NEW_PD_NAME="${SOURCE_VOLUME_SHORT_NAME}-${RAND_4_CHAR}"
    
    # Start replication from the DR Region back to the Source Region.
    gcloud compute disks create $NEW_PD_NAME \
      --region=$REGION \
      --size=$PD_SIZE_GB \
      --type pd-balanced \
      --primary-disk=$TARGET_VOLUME_PD_NAME \
      --primary-disk-region=$DR_REGION \
      --primary-disk-project=$PROJECT_ID \
      --replica-zones=$SOURCE_PD_REPLICA_ZONES

    gcloud compute disks start-async-replication $TARGET_VOLUME_PD_NAME \
      --region=$DR_REGION \
      --secondary-disk=$NEW_PD_NAME \
      --secondary-disk-region=$REGION \
      --secondary-disk-project=$PROJECT_ID
  fi
done <<< "$PV_SOURCE_AND_TARGETS"

echo "Succesfully created failback disks"
