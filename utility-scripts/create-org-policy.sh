#!/bin/bash
set -eux

export TPL_PROJECT_ID=$PROJECT_ID
envsubst < gce-policy.yaml.tpl > gce-policy.yaml
gcloud org-policies set-policy gce-policy.yaml --project $PROJECT_ID
