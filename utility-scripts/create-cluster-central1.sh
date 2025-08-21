#!/bin/bash
set -eux

gcloud container clusters create $SOURCE_CLUSTER \
  --project=$PROJECT_ID \
  --region=$REGION \
  --node-locations=$SOURCE_PD_REPLICA_ZONES \
  --network=$NETWORK_NAME \
  --subnetwork=subnet-us-central1 \
  --enable-ip-alias \
  --enable-private-nodes \
  --cluster-secondary-range-name=pods \
  --services-secondary-range-name=services \
  --machine-type=e2-medium \
  --num-nodes=1 \
  --shielded-secure-boot \
  --shielded-integrity-monitoring \
  --enable-autoscaling \
  --addons=BackupRestore \
  --monitoring=SYSTEM,API_SERVER,SCHEDULER,CONTROLLER_MANAGER

  gcloud container clusters update $SOURCE_CLUSTER \
  --location $REGION \
  --enable-master-authorized-networks \
  --master-authorized-networks "0.0.0.0/0"
