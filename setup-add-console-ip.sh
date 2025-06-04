set -eux

CURRENT_IP=$(curl -s "https://ifconfig.me/ip")
CURRENT_IP_CIDR="$CURRENT_IP/32"

gcloud container clusters update $SOURCE_CLUSTER \
  --location $REGION \
  --enable-master-authorized-networks \
  --master-authorized-networks "$CURRENT_IP_CIDR" \
  &

gcloud container clusters update $TARGET_CLUSTER \
  --location $DR_REGION \
  --enable-master-authorized-networks \
  --master-authorized-networks "$CURRENT_IP_CIDR" \
  &

wait

