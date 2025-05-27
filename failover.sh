#!/bin/bash
set -eux

source configure.sh

RAND_4_CHAR=$(tr -dc '[:lower:]' </dev/urandom | head -c 4)
export NEW_PD_NAME="${SOURCE_PD_NAME}-${RAND_4_CHAR}"

# Stop disk replication on the target disk
gcloud compute disks stop-async-replication bfg-demo-disk \
  --region=$REGION \

# Configure kubectl to point to DR cluster
gcloud container clusters get-credentials $TARGET_CLUSTER \
  --region $DR_REGION

# Create the PV in the DR Region
export SOURCE_PD_NAME=$TARGET_PD_NAME
envsubst < k8s_manifests/pv.yaml.tpl | kubectl apply -f -

# Run the backup restoration process
gcloud beta container backup-restore restores create $RESTORE_NAME-$RAND_4_CHAR \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME \
  --backup=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME/backups/$BACKUP_NAME \
  --wait-for-completion

# Start replication from the DR Region back to the Source Region.
gcloud compute disks create $NEW_PD_NAME \
  --region=$REGION \
  --size=$PD_SIZE_GB \
  --type pd-balanced \
  --primary-disk=$TARGET_PD_NAME \
  --primary-disk-region=$DR_REGION \
  --primary-disk-project=$PROJECT_ID \
  --replica-zones=$SOURCE_PD_REPLICA_ZONES

gcloud compute disks start-async-replication bfg-demo-disk \
  --region=$DR_REGION \
  --secondary-disk=$NEW_PD_NAME \
  --secondary-disk-region=$REGION \
  --secondary-disk-project=$PROJECT_ID

