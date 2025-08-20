#!/bin/bash
set -eux

CLOUD_RUN_DISK_CLIENT="disk-client-${CLIENT_REGION}"

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
  --set-env-vars="DISK_WRITER_HOST=disk-writer.will-tools.hotel" \
  --ingress=all
