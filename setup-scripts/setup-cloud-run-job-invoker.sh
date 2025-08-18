#!/bin/bash
set -eux

gcloud run deploy $JOB_INVOKER_SERVICE_NAME \
  --image "us-docker.pkg.dev/$PROJECT_ID/$DOCKER_REPO_NAME/job-invoker:v1" \
  --region $DR_REGION \
  --service-account $SERVICE_ACCOUNT \
  --ingress internal \
  --no-allow-unauthenticated \
  --set-env-vars="PROJECT_ID=$PROJECT_ID,JOB_REGION=$DR_REGION,JOB_NAME=$SOURCE_TO_DR_FAILOVER_CLOUD_RUN_JOB_NAME"

gcloud run services add-iam-policy-binding $JOB_INVOKER_SERVICE_NAME \
  --region=$DR_REGION \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"

gcloud run jobs add-iam-policy-binding $SOURCE_TO_DR_FAILOVER_CLOUD_RUN_JOB_NAME \
  --region=$DR_REGION \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"
