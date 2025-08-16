#!/bin/bash
set -eux

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/container.defaultNodeServiceAccount"
e
# Create GKE clusters in each region
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
  --monitoring=SYSTEM,API_SERVER,SCHEDULER,CONTROLLER_MANAGER \
   &

gcloud container clusters create $TARGET_CLUSTER \
  --project=$PROJECT_ID \
  --region=$DR_REGION \
  --node-locations=$TARGET_PD_REPLICA_ZONES \
  --network=$NETWORK_NAME \
  --subnetwork=subnet-us-west1 \
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
  --monitoring=SYSTEM,API_SERVER,SCHEDULER,CONTROLLER_MANAGER \
  &

wait
echo "GKE clusters '$SOURCE_CLUSTER' and '$TARGET_CLUSTER' created successfully."

gcloud container clusters update $SOURCE_CLUSTER \
  --location $REGION \
  --enable-master-authorized-networks \
  --master-authorized-networks "0.0.0.0/0"

gcloud container clusters update $TARGET_CLUSTER \
  --location $DR_REGION \
  --enable-master-authorized-networks \
  --master-authorized-networks "0.0.0.0/0"

gcloud container clusters get-credentials $SOURCE_CLUSTER \
  --region=$REGION \
  --project=$PROJECT_ID

echo "kubectl pointed to cluster: $SOURCE_CLUSTER"
