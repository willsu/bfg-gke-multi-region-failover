#!/bin/bash
set -eux
CLOUD_RUN_JOB_NAME="bfg-backup-job"
CLOUD_SCHEDULER_JOB_NAME="bfg-backup-scheduler"

export PROJECT_ID=will-gke-multi-region-bfg
export SOURCE_CLUSTER=bfg-cluster-us-central1
export REGION=us-central1
export DR_REGION=us-west1
export NAMESPACE=bfg
export BACKUP_NAME=bkp-bfg-bkp-plan
export BACKUP_PLAN_NAME=bfg-bkp-plan
export PV_STORAGE_BUCKET=gke-pv-backup-storage

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/compute.viewer"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/gkebackup.backupAdmin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectCreator"

gcloud storage buckets add-iam-policy-binding "gs://${PV_STORAGE_BUCKET}" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud run jobs create "$CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/scheduled-backup:v1" \
  --region "$DR_REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud run jobs add-iam-policy-binding "$CLOUD_RUN_JOB_NAME" \
  --region="$DR_REGION" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/run.invoker"

gcloud run jobs create "$CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/scheduled-backup:v1" \
  --region "$DR_REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --set-env-vars="PROJECT_ID=$PROJECT_ID,\
SOURCE_CLUSTER=$SOURCE_CLUSTER,\
REGION=$REGION,\
DR_REGION=$DR_REGION,\
NAMESPACE=$NAMESPACE,\
BACKUP_NAME=$BACKUP_NAME,\
BACKUP_PLAN_NAME=$BACKUP_PLAN_NAME,\
PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET"
