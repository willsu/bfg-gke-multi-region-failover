#!/bin/bash
set -eux

# Enable required APIs
gcloud services enable compute.googleapis.com container.googleapis.com --project=$PROJECT_ID
gcloud services enable gkebackup.googleapis.com --project=$PROJECT_ID

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
  &

wait
echo "GKE clusters '$SOURCE_CLUSTER' and '$TARGET_CLUSTER' created successfully."

CURRENT_IP=$(curl -s "https://ifconfig.me/ip")
CURRENT_IP_CIDR="$CURRENT_IP/32"

gcloud container clusters update $SOURCE_CLUSTER \
  --location $REGION \
  --enable-master-authorized-networks \
  --master-authorized-networks "$CURRENT_IP_CIDR"

gcloud container clusters get-credentials $SOURCE_CLUSTER \
  --region=$REGION \
  --project=$PROJECT_ID

echo "kubectl pointed to cluster: $SOURCE_CLUSTER"
