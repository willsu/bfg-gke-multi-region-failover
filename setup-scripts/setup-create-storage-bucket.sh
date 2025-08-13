#!/bin/bash
set -e

gcloud storage buckets create gs://${PV_STORAGE_BUCKET}

gcloud storage buckets add-iam-policy-binding "gs://${PV_STORAGE_BUCKET}" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectAdmin"
