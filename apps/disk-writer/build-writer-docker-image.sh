#!/bin/bash
set -eux

CONTAINER_VERION=v1

# Build and push the docker container
IMAGE_ID_FILE=$(mktemp)
docker build . --iidfile $IMAGE_ID_FILE -f Dockerfile.disk-writer --no-cache
IMAGE_ID=$(cat $IMAGE_ID_FILE)
docker tag $IMAGE_ID us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/write-bytes:$CONTAINER_VERION
docker push us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/write-bytes:$CONTAINER_VERION
