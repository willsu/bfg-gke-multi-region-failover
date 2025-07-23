#!/bin/bash
set -euxo pipefail

# Assume that the source region/cluster may not be reachable

# Find the lastest backup
# Limit results to successful backups with at least 1 pods
LATEST_BACKUP=$(gcloud beta container backup-restore backups list \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=$BACKUP_PLAN_NAME-$REGION \
  --format="json" | \
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

if [[ -z "$LATEST_BACKUP" ]]; then
  echo "No BfG Backups found with at least 1 pod"
  exit 1
fi

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
PV_SOURCE_AND_TARGETS=$(echo "$PV_JSON_BLOB" | jq -r 'to_entries[] | "\(.key) \(.value.sourceVolume) \(.value.targetVolume)"')

# Set the TPL values and stop replication for every Persistent Disk
# referenced in the JSON 
while IFS=' ' read -r pv_name source_volume_handle target_volume_handle; do
  SOURCE_VOLUME_SHORT_NAME=$(echo $source_volume_handle | awk -F'/' '{print $NF}')

  # Stop disk replication on the target disk
  # TODO: Handle errors. In the event of a regional outage there will be no reason to stop async replication.
  gcloud compute disks stop-async-replication $SOURCE_VOLUME_SHORT_NAME \
    --project=$PROJECT_ID \
    --region=$REGION

  # Set the template variable used for envsub
  PD_VAR_NAME=$(echo "$pv_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  declare -x "TPL_${PD_VAR_NAME}_VOLUME_HANDLE"="$target_volume_handle"

done <<< "$PV_SOURCE_AND_TARGETS"

# Render the envsubst kustomize config template
export TPL_NAMESPACE=$NAMESPACE
envsubst < kustomize/pv-base/pv-kustomize-config.yaml.tpl > kustomize/pv-base/pv-kustomize-config.yaml

# Apply the PV yaml to the DR region before the backup is restored
gcloud container clusters get-credentials $TARGET_CLUSTER \
  --region $DR_REGION
kubectl apply -k kustomize/pv-base

RAND_4_CHAR=$(tr -dc '[:lower:]' </dev/urandom | head -c 4 || true)

# Run the backup restoration process
gcloud beta container backup-restore restores create $RESTORE_NAME-$RAND_4_CHAR \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME-$REGION \
  --backup=$LATEST_BACKUP \
  --wait-for-completion

# Attempt to create the replicate PDs in the source region
export LATEST_BACKUP_SHORT_NAME
./failover-create-failback-pds.sh

echo "failover complete!"
