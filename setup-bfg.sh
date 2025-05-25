#!/bin/bash
set -eux

gcloud beta container backup-restore backup-plans create $BACKUP_PLAN_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --cluster=projects/$PROJECT_ID/locations/$REGION/clusters/$SOURCE_CLUSTER \
  --selected-namespaces=bfg \
  --include-secrets \
  --cron-schedule="0 3 * * *" \
  --backup-retain-days=7 \
  --backup-delete-lock-days=0

gcloud beta container backup-restore backups create $BACKUP_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=$BACKUP_PLAN_NAME \
  --wait-for-completion

gcloud beta container backup-restore restore-plans create $RESTORE_PLAN_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME \
  --cluster=projects/$PROJECT_ID/locations/$DR_REGION/clusters/$TARGET_CLUSTER \
  --cluster-resource-conflict-policy=use-existing-version \
  --namespaced-resource-restore-mode=delete-and-restore \
  --selected-namespaces=bfg \
  --cluster-resource-scope-selected-group-kinds="storage.k8s.io/StorageClass","scheduling.k8s.io/PriorityClass" \
  --no-volume-data-restoration
