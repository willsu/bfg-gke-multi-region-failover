#!/bin/bash
set -eux

SOURCE_ALERT_TOPIC_NAME="alert-topic-gke-apiserver-$REGION"

gcloud pubsub topics create $SOURCE_ALERT_TOPIC_NAME

NOTIFICATION_CHANNEL=$(gcloud alpha monitoring channels create \
  --display-name="GKE Alert Pub/Sub $SOURCE_CLUSTER" \
  --type=pubsub \
  --channel-labels=topic="projects/$PROJECT_ID/topics/$SOURCE_ALERT_TOPIC_NAME" \
  --format="value(name)")

gcloud pubsub topics add-iam-policy-binding $SOURCE_ALERT_TOPIC_NAME \
    --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-monitoring-notification.iam.gserviceaccount.com" \
    --role="roles/pubsub.publisher"

# Setup Template vars 
export TPL_CLUSTER_NAME=$SOURCE_CLUSTER
export TPL_PROJECT_ID=$PROJECT_ID
export TPL_NOTIFICATION_CHANNEL=$NOTIFICATION_CHANNEL
envsubst < gke-control-plane-unreachable.json.tpl > gke-control-plane-unreachable-${SOURCE_CLUSTER}.json

gcloud alpha monitoring policies create \
  --policy-from-file=gke-control-plane-unreachable-${SOURCE_CLUSTER}.json

gcloud eventarc triggers create failover-trigger-$REGION \
    --destination-run-service="$JOB_INVOKER_SERVICE_NAME" \
    --destination-run-region="$DR_REGION" \
    --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
    --transport-topic="projects/$PROJECT_ID/topics/$SOURCE_ALERT_TOPIC_NAME" \
    --location="us-central1" \
    --service-account="$SERVICE_ACCOUNT"

