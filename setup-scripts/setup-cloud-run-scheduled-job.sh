#!/bin/bash
set -eux

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

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.developer"

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
  --description='Triggers Cloud Run Job backup-job every 10 minutes for backup.' \
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
  --description='Triggers Cloud Run Job backup-job every 10 minutes for backup.' \
  --headers='User-Agent=Google-Cloud-Scheduler' \
  --attempt-deadline='180s' \
  --min-backoff='5s' \
  --max-backoff='3600s' \
  --max-doublings=5

# Create the Cloud Run Job to failover from the source to DR cluster
gcloud run jobs create "$SOURCE_TO_DR_FAILOVER_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/failover:v1" \
  --region "$DR_REGION" \
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
  DNS_NAME=$DNS_NAME:\
  DNS_ZONE_NAME=$DNS_ZONE_NAME"

# Create the Cloud Run Job to failover from the DR to source cluster
gcloud run jobs create "$DR_TO_SOURCE_FAILOVER_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/failover:v1" \
  --region "$REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="$SERVICE_ACCOUNT" \
  --set-env-vars="^:^PROJECT_ID=$PROJECT_ID:\
  DR_REGION=$REGION:\
  BACKUP_PLAN_NAME=$BACKUP_PLAN_NAME:\
  REGION=$DR_REGION:\
  PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET:\
  NAMESPACE=$NAMESPACE:\
  TARGET_CLUSTER=$SOURCE_CLUSTER:\
  RESTORE_NAME=$RESTORE_NAME:\
  RESTORE_PLAN_NAME=$RESTORE_PLAN_NAME:\
  DNS_NAME=$DNS_NAME:\
  DNS_ZONE_NAME=$DNS_ZONE_NAME"

# Create the Cloud Run Job to create replica PDs in the Source Region
gcloud run jobs create "$SOURCE_CREATE_REPLICA_PDS_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/create-replica-pds:v1" \
  --region "$REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="$SERVICE_ACCOUNT" \
  --set-env-vars="^:^PROJECT_ID=$PROJECT_ID:\
  PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET:\
  REGION=$REGION:\
  DR_REGION=$DR_REGION:\
  PD_SIZE_GB=$PD_SIZE_GB:\
  PD_REPLICA_ZONES=$SOURCE_PD_REPLICA_ZONES"

gcloud run jobs add-iam-policy-binding "$SOURCE_CREATE_REPLICA_PDS_CLOUD_RUN_JOB_NAME" \
  --region="$REGION" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"

# Create the Cloud Run Job to create replica PDs in the DR Region
gcloud run jobs create "$DR_CREATE_REPLICA_PDS_CLOUD_RUN_JOB_NAME" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/create-replica-pds:v1" \
  --region "$DR_REGION" \
  --task-timeout=5m \
  --max-retries=3 \
  --service-account="$SERVICE_ACCOUNT" \
  --set-env-vars="^:^PROJECT_ID=$PROJECT_ID:\
  PV_STORAGE_BUCKET=$PV_STORAGE_BUCKET:\
  REGION=$DR_REGION:\
  DR_REGION=$REGION:\
  PD_SIZE_GB=$PD_SIZE_GB:\
  PD_REPLICA_ZONES=$TARGET_PD_REPLICA_ZONES"

gcloud run jobs add-iam-policy-binding "$DR_CREATE_REPLICA_PDS_CLOUD_RUN_JOB_NAME" \
  --region="$DR_REGION" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"
