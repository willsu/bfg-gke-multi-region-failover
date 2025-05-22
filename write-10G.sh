#!/bin/sh
set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="${MOUNT_LOCATION}/null_file_10gb_${TIMESTAMP}"

echo "Creating a 10GB file named '$FILENAME' using dd..."
dd if=/dev/zero of="$FILENAME" bs="1M" count="10240"

FILESIZE=$(du -h $FILENAME)
echo "Size for $FILENAME is now: $FILESIZE"

# sleep forever to keep the pod running
while true
do
  df $MOUNT_LOCATION -h 
  sleep 2
done

