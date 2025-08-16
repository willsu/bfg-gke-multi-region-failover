#!/bin/bash
set -eux

CONTAINER_VERION=v1

# Build and push the docker container
docker build . -f Dockerfile.job-invoker --no-cache
LATEST_IMAGE_ID=$(docker images --format '{{.CreatedAt}}\t{{.ID}}' | sort -r | head -n 1 | awk '{print $5}')
docker tag $LATEST_IMAGE_ID us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/job-invoker:$CONTAINER_VERION
docker push us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/job-invoker:$CONTAINER_VERION
