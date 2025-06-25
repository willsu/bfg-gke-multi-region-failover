#!/bin/bash
set -e

gcloud storage buckets create gs://${PV_STORAGE_BUCKET}
