#!/bin/bash
set -eux

# Create the failover plan
gcloud beta container backup-restore backup-plans create $BACKUP_PLAN_NAME-$REGION \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --cluster=projects/$PROJECT_ID/locations/$REGION/clusters/$SOURCE_CLUSTER \
  --selected-namespaces=$NAMESPACE \
  --include-secrets \
  --backup-retain-days=1 \
  --backup-delete-lock-days=0

gcloud beta container backup-restore restore-plans create $RESTORE_PLAN_NAME-$REGION \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME-$REGION \
  --cluster=projects/$PROJECT_ID/locations/$DR_REGION/clusters/$TARGET_CLUSTER \
  --cluster-resource-conflict-policy=use-existing-version \
  --namespaced-resource-restore-mode=delete-and-restore \
  --selected-namespaces=$NAMESPACE \
  --cluster-resource-scope-selected-group-kinds="storage.k8s.io/StorageClass","scheduling.k8s.io/PriorityClass"

# Create the failback plan
gcloud beta container backup-restore backup-plans create $BACKUP_PLAN_NAME-$DR_REGION \
  --project=$PROJECT_ID \
  --location=$REGION \
  --cluster=projects/$PROJECT_ID/locations/$DR_REGION/clusters/$TARGET_CLUSTER \
  --selected-namespaces=$NAMESPACE \
  --include-secrets \
  --backup-retain-days=1 \
  --backup-delete-lock-days=0

gcloud beta container backup-restore restore-plans create $RESTORE_PLAN_NAME-$DR_REGION \
  --project=$PROJECT_ID \
  --location=$REGION \
  --backup-plan=projects/$PROJECT_ID/locations/$REGION/backupPlans/$BACKUP_PLAN_NAME-$DR_REGION \
  --cluster=projects/$PROJECT_ID/locations/$REGION/clusters/$SOURCE_CLUSTER \
  --cluster-resource-conflict-policy=use-existing-version \
  --namespaced-resource-restore-mode=delete-and-restore \
  --selected-namespaces=$NAMESPACE \
  --cluster-resource-scope-selected-group-kinds="storage.k8s.io/StorageClass","scheduling.k8s.io/PriorityClass"
