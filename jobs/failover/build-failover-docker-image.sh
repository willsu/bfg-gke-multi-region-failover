#!/bin/bash
set -eux
CONTAINER_VERION=v1

# Copy required kustomize files into the build root
cp -r ../../pv-base .

# Build and push the docker container
IMAGE_ID_FILE=$(mktemp)
docker build --iidfile $IMAGE_ID_FILE -f Dockerfile.failover .
IMAGE_ID=$(cat $IMAGE_ID_FILE)

# Remove kustomize files from build root
rm -rf pv-base

docker tag $IMAGE_ID us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/failover:$CONTAINER_VERION
docker push us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/failover:$CONTAINER_VERION
