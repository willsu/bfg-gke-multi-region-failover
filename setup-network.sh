#!/bin/bash
set -eux

# Create VPC network
gcloud compute networks create $NETWORK_NAME --project=$PROJECT_ID --subnet-mode=custom

# Create subnets in two regions for the clusters
gcloud compute networks subnets create subnet-$REGION \
  --project=$PROJECT_ID \
  --network=$NETWORK_NAME \
  --range=172.16.1.0/24 \
  --secondary-range=pods=10.0.0.0/16,services=192.168.1.0/24 \
  --region=$REGION

gcloud compute networks subnets create subnet-$DR_REGION \
  --project=$PROJECT_ID \
  --network=$NETWORK_NAME \
  --range=172.16.2.0/24 \
  --secondary-range=pods=10.1.0.0/16,services=192.168.2.0/24 \
  --region=$DR_REGION

# Create a subnet in a third region for the client
gcloud compute networks subnets create subnet-$CLIENT_REGION \
  --project=$PROJECT_ID \
  --network=$NETWORK_NAME \
  --range=172.16.3.0/24 \
  --region=$CLIENT_REGION

echo "VPC network '$NETWORK_NAME' and subnets created successfully in project '$PROJECT_ID'."
