#!/bin/bash
set -eux

CLOUD_RUN_DISK_CLIENT="disk-client-${REGION}"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:service-$PROJECT_NUMBER@serverless-robot-prod.iam.gserviceaccount.com" \
  --role "roles/compute.networkUser"

# TODO: DISK_WRITE_HOST will use the disk-write service DNS name when it is all wired up
gcloud run deploy "$CLOUD_RUN_DISK_CLIENT" \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/disk-client:v1" \
  --region "$CLIENT_REGION" \
  --network "$NETWORK_NAME" \
  --subnet "subnet-$CLIENT_REGION" \
  --vpc-egress "all-traffic" \
  --service-account="$SERVICE_ACCOUNT" \
  --allow-unauthenticated \
  --set-env-vars="DISK_WRITER_HOST=172.16.1.24"

# Note: currently setting access to allUsers. If we need to restrict access,
# set the member to "user:$END_USER_ACCOUNT"
gcloud run services add-iam-policy-binding "$CLOUD_RUN_DISK_CLIENT" \
  --region="$CLIENT_REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"
