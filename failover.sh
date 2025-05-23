#!/bin/bash
set -eux

source configure.sh

# Stop disk replication on the target disk
gcloud compute disks stop-async-replication bfg-demo-disk \
  --region=$REGION \
  --secondary-disk=$TARGET_PD_NAME

# Run the backup restoration process
gcloud beta container backup-restore restores create $RESTORE_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME \
  --backup=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME/backups/$BACKUP_NAME \
  --volume-data-restore-policy-overrides-file=volume-policy-overrides.yaml \
  --wait-for-completion

# TODO: create a new secondary PD in the "source" region and start replication 
