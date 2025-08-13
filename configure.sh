# This file is intended to be "sourced" from your shell. 
# Please don't execute directly

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export NETWORK_NAME="vpc-multi-region"
export DNS_ZONE_NAME="will-tools-hotel"
export DNS_NAME="will-tools.hotel"
export DOCKER_REPO_NAME="bfg-demo"
export SOURCE_CLUSTER="cluster-us-central1"
export TARGET_CLUSTER="cluster-us-west1"
export SOURCE_PD_NAME="demo-disk-central"
export SOURCE_PD_REPLICA_ZONES="us-central1-a,us-central1-b"
export TARGET_PD_NAME="demo-disk-west"
export TARGET_PD_REPLICA_ZONES="us-west1-a,us-west1-b"
export PD_SIZE_GB="50"
export PD_SIZE="${PD_SIZE_GB}Gi"
export REGION="us-central1"
export DR_REGION="us-west1"
export CLIENT_REGION="us-east1"
export NAMESPACE="bfg"
export BACKUP_PLAN_NAME="$NAMESPACE-backup"
export BACKUP_NAME=bkp-"$BACKUP_PLAN_NAME"
export RESTORE_PLAN_NAME="$NAMESPACE-restore"
export RESTORE_NAME=rest-"$RESTORE_PLAN_NAME"
export SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
export END_USER_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format="value(account)")"
export PV_STORAGE_BUCKET="gke-pv-backup-storage-$PROJECT_ID"