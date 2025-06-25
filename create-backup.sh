set -eux

RAND_4_CHAR=$(tr -dc '[:lower:]' </dev/urandom | head -c 4)

# Configure kubectl to point to Source cluster
gcloud container clusters get-credentials $SOURCE_CLUSTER \
  --region $REGION

# Get all the current Persistent Volume names and hangles
# JSON structure as follows: {metadata.name: spec.csi.volumeHandle}
PV_JSON_BLOB=$(kubectl get pv -n $NAMESPACE -l pd-type=cross-region-async -o json \
  | jq '.items | reduce .[] as $item ({}; if $item.spec.csi.volumeHandle then .[$item.metadata.name] = $item.spec.csi.volumeHandle else . end)')

# Manually create the backup
gcloud beta container backup-restore backups create $BACKUP_NAME-$REGION-$RAND_4_CHAR \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=$BACKUP_PLAN_NAME-$REGION \
  --wait-for-completion

# Write the persistent disk information to Cloud Storage
TEMP_FILE=$(mktemp)
echo "$PV_JSON_BLOB" > "$TEMP_FILE"
gcloud storage cp "$TEMP_FILE" "gs://${PV_STORAGE_BUCKET}/$BACKUP_NAME-$REGION-$RAND_4_CHAR-pv-mapping"
