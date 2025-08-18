#!/bin/bash

set -eux

# List of required env vars
# PROJECT_ID
# SOURCE_CLUSTER
# REGION
# DR_REGION
# NAMESPACE
# BACKUP_NAME
# BACKUP_PLAN_NAME
# PV_STORAGE_BUCKET

RAND_4_CHAR=$(tr -dc '[:lower:]' </dev/urandom | head -c 4)

gcloud config set project $PROJECT_ID

# Configure kubectl to point to Source cluster
gcloud container clusters get-credentials $SOURCE_CLUSTER \
  --region $REGION

# Get all the current Persistent Volume names and hangles
# JSON structure as follows: {metadata.name: sourceVolume: {spec.csi.volumeHandle}, targetVolume: {FROM_GCLOUD}}
PV_JSON_BLOB=$(kubectl get pv -n $NAMESPACE -l pd-type=cross-region-async -o json \
  | jq '.items | reduce .[] as $item ({}; if $item.spec.csi.volumeHandle then .[$item.metadata.name] = {"sourceVolume": $item.spec.csi.volumeHandle} else . end)')

# Find the targetVolume for every source volume
JSON_KEYS_VALUES=$(echo "$PV_JSON_BLOB" | jq -r 'to_entries[] | "\(.key) \(.value.sourceVolume)"')

if [ -n "$JSON_KEYS_VALUES" ]; then
  echo "Found Persistent Volumes to process..."
  TEMP_JSON_STREAM_FILE=$(mktemp)
  while IFS=' ' read -r pv_name full_volume_handle; do

    SOURCE_VOLUME_SHORT_NAME=$(echo $full_volume_handle | awk -F'/' '{print $NF}')

    TARGET_VOLUME_PD_HANDLE=$(gcloud compute disks describe $SOURCE_VOLUME_SHORT_NAME \
      --region=$REGION \
      --format="json" | \
      jq -r '(.asyncSecondaryDisks // {}) | keys[]')

    if [ -z "$TARGET_VOLUME_PD_HANDLE" ]; then
      echo "Error: The source volume: ${SOURCE_VOLUME_SHORT_NAME} has no replica disks. The backup is unsuccessful and must exit"
      exit 1
    fi

    jq -n --arg pv_name "$pv_name" \
          --arg source_handle "$full_volume_handle" \
          --arg target_handle "$TARGET_VOLUME_PD_HANDLE" \
    '{ ( $pv_name ): {sourceVolume: $source_handle, targetVolume : $target_handle}}' >> "$TEMP_JSON_STREAM_FILE"
  done <<< "$JSON_KEYS_VALUES"

  # Merge all the individual JSON docs written to the temp file together
  PV_FINAL_JSON_BLOB=$(jq -s 'add' "$TEMP_JSON_STREAM_FILE")
else
  echo "No Persistent Volumes to process..."
  PV_FINAL_JSON_BLOB="{}"
fi

# Manually create the backup
gcloud beta container backup-restore backups create $BACKUP_NAME-$REGION-$RAND_4_CHAR \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=$BACKUP_PLAN_NAME-$REGION \
  --wait-for-completion

# Write the persistent disk information to Cloud Storage
TEMP_FILE=$(mktemp)
echo "$PV_FINAL_JSON_BLOB" > "$TEMP_FILE"
gcloud storage cp "$TEMP_FILE" "gs://${PV_STORAGE_BUCKET}/$BACKUP_NAME-$REGION-$RAND_4_CHAR-pv-mapping"
