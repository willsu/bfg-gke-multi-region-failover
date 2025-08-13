#!/bin/bash
set -eux

# Grant the service account permission to 
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/dns.admin"

gcloud dns managed-zones create $DNS_ZONE_NAME \
  --dns-name "${DNS_NAME}." \
  --description="will tools private zone" \
  --visibility=private \
  --networks $NETWORK_NAME

# The GKE services must be created and have internal IP address assigned

kubectl get services -l service-type=cross-region-async --all-namespaces --output=json | \
  jq -r '.items[] | select(.status.loadBalancer.ingress[0].ip != null) | "\(.spec.selector.app) \(.status.loadBalancer.ingress[0].ip)"' | \
  while read -r APP_NAME IP_ADDR; do
    gcloud dns record-sets create "$APP_NAME.$DNS_NAME." \
    --zone="${DNS_ZONE_NAME}" \
    --type="A" \
    --ttl="5" \
    --rrdatas="$IP_ADDR"
  done