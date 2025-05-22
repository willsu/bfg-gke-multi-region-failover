#!/bin/bash
set -eux

# Configure Docker of "us" region
gcloud auth configure-docker us-docker.pkg.dev

gcloud artifacts repositories create $DOCKER_REPO_NAME \
    --repository-format=docker \
    --location=us \
    --description="BFG Docker repository" 

echo "Docker Repo $DOCKER_REPO_NAME created"
