#!/bin/bash
set -eux

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
