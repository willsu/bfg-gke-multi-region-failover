#!/bin/bash
set -eux

gcloud compute disks create $SOURCE_PD_NAME \
  --size 50 \
  --type pd-balanced \
  --region $REGION \
  --replica-zones $SOURCE_PD_REPLICA_ZONES

gcloud compute disks create $TARGET_PD_NAME \
  --region=$DR_REGION \
  --size=50 \
  --type pd-balanced \
  --primary-disk=$SOURCE_PD_NAME \
  --primary-disk-region=$REGION \
  --primary-disk-project=$PROJECT_ID \
  --replica-zones=$TARGET_PD_REPLICA_ZONES

gcloud compute disks start-async-replication bfg-demo-disk \
  --region=$REGION \
  --secondary-disk=$TARGET_PD_NAME \
  --secondary-disk-region=$DR_REGION \
  --secondary-disk-project=$PROJECT_ID
