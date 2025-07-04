#!/bin/bash
set -eux

gcloud compute disks create $SOURCE_PD_NAME \
  --size $PD_SIZE_GB \
  --type pd-balanced \
  --region $REGION \
  --replica-zones $SOURCE_PD_REPLICA_ZONES

gcloud compute disks create $TARGET_PD_NAME \
  --region=$DR_REGION \
  --size=$PD_SIZE_GB \
  --type pd-balanced \
  --primary-disk=$SOURCE_PD_NAME \
  --primary-disk-region=$REGION \
  --primary-disk-project=$PROJECT_ID \
  --replica-zones=$TARGET_PD_REPLICA_ZONES

gcloud compute disks start-async-replication $SOURCE_PD_NAME \
  --region=$REGION \
  --secondary-disk=$TARGET_PD_NAME \
  --secondary-disk-region=$DR_REGION \
  --secondary-disk-project=$PROJECT_ID
