#!/bin/bash
set -eux

# Enable required APIs
gcloud services enable compute.googleapis.com container.googleapis.com --project=$PROJECT_ID
gcloud services enable gkebackup.googleapis.com --project=$PROJECT_ID

# Create VPC network
gcloud compute networks create $NETWORK_NAME --project=$PROJECT_ID --subnet-mode=custom

# Create subnets in two regions
gcloud compute networks subnets create subnet-us-central1 \
  --project=$PROJECT_ID \
  --network=$NETWORK_NAME \
  --range=172.16.1.0/24 \
  --secondary-range=pods=10.0.0.0/16,services=192.168.1.0/24 \
  --region=$REGION

gcloud compute networks subnets create subnet-us-west1 \
  --project=$PROJECT_ID \
  --network=$NETWORK_NAME \
  --range=172.16.2.0/24 \
  --secondary-range=pods=10.1.0.0/16,services=192.168.2.0/24 \
  --region=$DR_REGION

echo "VPC network '$NETWORK_NAME' and subnets created successfully in project '$PROJECT_ID'."

# Create GKE clusters in each region
gcloud container clusters create $SOURCE_CLUSTER \
  --project=$PROJECT_ID \
  --region=$REGION \
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
