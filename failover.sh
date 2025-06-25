#!/bin/bash
set -eux

# Find the lastest backup
LATEST_BACKUP=$(gcloud beta container backup-restore backups list \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=$BACKUP_PLAN_NAME-$REGION \
  --format="json" 2>/dev/null | \
  jq -r '
    map(
      select(
        .state == "SUCCEEDED" and
        (.podCount != null) and  # Ensure podCount is not null
        .podCount >= 1
      )
    ) |
    sort_by(.createTime) |
    last |
    .name
  ')

# Find the associated cloud storage object with the PV mapping data
# See 'create-backup.sh' to see how the JSON objects get created.
LATEST_BACKUP_SHORT_NAME=$(echo $LATEST_BACKUP | awk -F'/' '{print $NF}')
PV_JSON_BLOB=$(gcloud storage cat gs://${PV_STORAGE_BUCKET}/${LATEST_BACKUP_SHORT_NAME}-pv-mapping)

# Check if the JSON blob is empty or just an empty object (no matching PVs)
if [[ -z "$PV_JSON_BLOB" || "$PV_JSON_BLOB" == "{}" ]]; then
  echo "No Persistent Volumes found in json blob"
  exit 1
fi

# Parse the JSON blob into the PV_MAP associative array
JSON_KEYS_VALUES=$(echo "$PV_JSON_BLOB" | jq -r 'to_entries[] | "\(.key) \(.value)"')

# Set the TPL values and stop replication for every Persistent Disk
# referenced in the JSON 
while IFS=' ' read -r pv_name full_volume_handle; do
  SOURCE_VOLUME_SHORT_NAME=$(echo $full_volume_handle | awk -F'/' '{print $NF}')

  # TODO: This command may need to change to query the PDs in the 
  #       DR_REGION and find which one is being replicated to. 
  #       Since we can't depend on communication with the REGION when this script is run
  TARGET_VOLUME_PD_HANDLE=$(gcloud compute disks describe $SOURCE_VOLUME_SHORT_NAME \
    --region=$REGION \
    --format="json" | \
    jq -r '.asyncSecondaryDisks | keys[]')

  TARGET_VOLUME_PD_NAME=$(echo $TARGET_VOLUME_PD_HANDLE| awk -F'/' '{print $NF}')

  # Stop disk replication on the target disk
  # TODO: Handle errors. In the event of a regional outage there will be no reason to stop async replication.
  gcloud compute disks stop-async-replication $SOURCE_VOLUME_SHORT_NAME \
    --region=$REGION

  # Set the template variable used for envsub
  PD_VAR_NAME=$(echo "$pv_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  declare -x "TPL_${PD_VAR_NAME}_VOLUME_HANDLE"="$TARGET_VOLUME_PD_HANDLE"

done <<< "$JSON_KEYS_VALUES"

# Render the envsubst kustomize config template
TPL_NAMESPACE=$NAMESPACE
envsubst < kustomize/pv-base/pv-kustomize-config.yaml.tpl > kustomize/pv-base/pv-kustomize-config.yaml

# Apply the PV yaml to the DR region before the backup is restored
gcloud container clusters get-credentials $TARGET_CLUSTER \
  --region $DR_REGION
kubectl apply -k kustomize/pv-base

RAND_4_CHAR=$(tr -dc '[:lower:]' </dev/urandom | head -c 4)

# Run the backup restoration process
gcloud beta container backup-restore restores create $RESTORE_NAME-$RAND_4_CHAR \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME-$REGION \
  --backup=$LATEST_BACKUP \
  --wait-for-completion

# TODO: Same loop as above.. look for a way to reduce complexity
# Create new target disks in the source region (if possible)
# and start async replication
while IFS=' ' read -r pv_name full_volume_handle; do
  SOURCE_VOLUME_SHORT_NAME=$(echo $full_volume_handle | awk -F'/' '{print $NF}')

  # TODO: This command may need to change to query the PDs in the 
  #       DR_REGION and find which one is being replicated to. 
  #       Since we can't depend on communication with the REGION when this script is run
  TARGET_VOLUME_PD_HANDLE=$(gcloud compute disks describe $SOURCE_VOLUME_SHORT_NAME \
    --region=$REGION \
    --format="json" | \
    jq -r '.asyncSecondaryDisks | keys[]')

  TARGET_VOLUME_PD_NAME=$(echo $TARGET_VOLUME_PD_HANDLE| awk -F'/' '{print $NF}')

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
done <<< "$JSON_KEYS_VALUES"

echo "failover complete!"
