#!/bin/sh
set -e

MOUNT_LOCATION="${MOUNT_LOCATION:-/var/run/data}"
FILE_PATH="${MOUNT_LOCATION}/disk_usage_file"

handle_post() {
    NUM_BYTES="$1"
    local response=""
    local error_message=""

    /bin/mkdir -p "$(dirname "$FILE_PATH")" || {
        echo "ERROR: Failed to create directory $(dirname "$FILE_PATH")" >&2
        return 1
    }

    if [ "$NUM_BYTES" -le 0 ]; then
        echo "Please specify a value greater than 0"
        return 1
    fi

    if /bin/dd if=/dev/zero of="$FILE_PATH" bs=1 count="$NUM_BYTES" 2>&1; then
        echo "SUCCESS: File created/resized to ${NUM_BYTES} bytes at ${FILE_PATH} and synced to disk."
        return 0
    else
        echo "ERROR: dd command failed for ${NUM_BYTES} bytes. Check logs for dd output." >&2
        return 1
    fi
}

handle_get() {
    FULL_ZONE_PATH=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)
    REGION=$(echo "$FULL_ZONE_PATH" | awk -F'/' '{print $4}')

    # Get the hostname directly
    HOSTNAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/hostname)

    if [ -f "$FILE_PATH" ]; then
        FILE_SIZE=$(wc -c < "$FILE_PATH")
        echo "{\"current_disk_usage_bytes\": ${FILE_SIZE}, \"region\": \"${REGION}\", \"hostname\": \"${HOSTNAME}\"}"
    else
        echo "{\"current_disk_usage_bytes\": 0, \"region\": \"${REGION}\", \"hostname\": \"${HOSTNAME}\"}"
    fi
    printf "\n"
    return 0
}

# --- Script Entry Point ---
case "$1" in
    handle_post)
        handle_post "$2"
        ;;
    handle_get)
        handle_get
        ;;
    *)
        echo "Usage: $0 {handle_post <num_bytes> | handle_get}" >&2
        exit 1
        ;;
esac
