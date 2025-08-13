#!/bin/bash
set -eux

# Configure Docker of "us" region
gcloud auth configure-docker us-docker.pkg.dev

gcloud artifacts repositories create $DOCKER_REPO_NAME \
    --repository-format=docker \
    --location=us \
    --description="BFG Docker repository" 

echo "Docker Repo $DOCKER_REPO_NAME created"

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

echo "Access to AR granted to default GKE service account"
