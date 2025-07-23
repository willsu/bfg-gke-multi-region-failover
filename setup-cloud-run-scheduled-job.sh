#!/bin/bash
set -eux

SOURCE_CLOUD_RUN_JOB_NAME="bfg-backup-job-${REGION}"
SOURCE_CLOUD_SCHEDULER_JOB_NAME="bfg-backup-scheduler-${REGION}"
DR_CLOUD_RUN_JOB_NAME="bfg-backup-job-${DR_REGION}"
DR_CLOUD_SCHEDULER_JOB_NAME="bfg-backup-scheduler-${DR_REGION}"
FAILOVER_CLOUD_RUN_JOB_NAME="bfg-failover-job"

SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/compute.viewer"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/gkebackup.backupAdmin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectCreator"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/compute.storageAdmin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/gkebackup.restoreAdmin"

gcloud storage buckets add-iam-policy-binding "gs://${PV_STORAGE_BUCKET}" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectAdmin"

# Create the job to backup the SOURCE_CLUSTER
gcloud run jobs create "$SOURCE_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/scheduled-backup:v1" \
  --region "$REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="$SERVICE_ACCOUNT" \
  --set-env-vars="PROJECT_ID=$PROJECT_ID,\
SOURCE_CLUSTER=$SOURCE_CLUSTER,\
REGION=$REGION,\
DR_REGION=$DR_REGION,\
NAMESPACE=$NAMESPACE,\
BACKUP_NAME=$BACKUP_NAME,\
BACKUP_PLAN_NAME=$BACKUP_PLAN_NAME,\
PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET"

gcloud run jobs add-iam-policy-binding "$SOURCE_CLOUD_RUN_JOB_NAME" \
  --region="$REGION" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"

# Create the job to backup the TARGET_CLUSTER
gcloud run jobs create "$DR_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/scheduled-backup:v1" \
  --region "$DR_REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="$SERVICE_ACCOUNT" \
  --set-env-vars="PROJECT_ID=$PROJECT_ID,\
SOURCE_CLUSTER=$TARGET_CLUSTER,\
REGION=$DR_REGION,\
DR_REGION=$REGION,\
NAMESPACE=$NAMESPACE,\
BACKUP_NAME=$BACKUP_NAME,\
BACKUP_PLAN_NAME=$BACKUP_PLAN_NAME,\
PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET"

gcloud run jobs add-iam-policy-binding "$DR_CLOUD_RUN_JOB_NAME" \
  --region="$DR_REGION" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"

gcloud scheduler jobs create http $SOURCE_CLOUD_SCHEDULER_JOB_NAME \
  --location=us-west1 \
  --schedule='*/10 * * * *' \
  --uri="https://run.googleapis.com/v2/projects/$PROJECT_ID/locations/${REGION}/jobs/${SOURCE_CLOUD_RUN_JOB_NAME}:run" \
  --http-method=POST \
  --oauth-service-account-email="$SERVICE_ACCOUNT" \
  --oauth-token-scope='https://www.googleapis.com/auth/cloud-platform' \
  --description='Triggers Cloud Run Job bfg-backup-job every 10 minutes for backup.' \
  --headers='User-Agent=Google-Cloud-Scheduler' \
  --attempt-deadline='180s' \
  --min-backoff='5s' \
  --max-backoff='3600s' \
  --max-doublings=5

gcloud scheduler jobs create http $DR_CLOUD_SCHEDULER_JOB_NAME \
  --location=us-west1 \
  --schedule='*/10 * * * *' \
  --uri="https://run.googleapis.com/v2/projects/$PROJECT_ID/locations/${DR_REGION}/jobs/${DR_CLOUD_RUN_JOB_NAME}:run" \
  --http-method=POST \
  --oauth-service-account-email="$SERVICE_ACCOUNT" \
  --oauth-token-scope='https://www.googleapis.com/auth/cloud-platform' \
  --description='Triggers Cloud Run Job bfg-backup-job every 10 minutes for backup.' \
  --headers='User-Agent=Google-Cloud-Scheduler' \
  --attempt-deadline='180s' \
  --min-backoff='5s' \
  --max-backoff='3600s' \
  --max-doublings=5

# Create the Cloud Run Job to failover between clusters
gcloud run jobs create "$FAILOVER_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/failover:v1" \
  --region "$REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="$SERVICE_ACCOUNT" \
  --set-env-vars="^:^PROJECT_ID=$PROJECT_ID:\
  DR_REGION=$DR_REGION:\
  BACKUP_PLAN_NAME=$BACKUP_PLAN_NAME:\
  REGION=$REGION:\
  PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET:\
  NAMESPACE=$NAMESPACE:\
  TARGET_CLUSTER=$TARGET_CLUSTER:\
  RESTORE_NAME=$RESTORE_NAME:\
  RESTORE_PLAN_NAME=$RESTORE_PLAN_NAME:\
  PD_SIZE_GB=$PD_SIZE_GB:\
  SOURCE_PD_REPLICA_ZONES=$SOURCE_PD_REPLICA_ZONES"
