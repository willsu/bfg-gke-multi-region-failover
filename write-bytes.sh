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
        if [ -f "$FILE_PATH" ]; then
            if /bin/rm -f "$FILE_PATH"; then
                echo "File removed successfully for 0 or negative bytes."
                return 0
            else
                echo "ERROR: Failed to remove file $FILE_PATH for 0 or negative bytes." >&2
                return 1
            fi
        else
            echo "File already does not exist for 0 or negative bytes."
            return 0
        fi
    fi

    # Use a single dd command with a block size of 1 to guarantee a non-sparse file
    local DD_CMD="/bin/dd if=/dev/zero of=\"$FILE_PATH\" bs=1 count=\"$NUM_BYTES\" status=none conv=fsync"

    if eval "$DD_CMD" 2>&1; then
        # Force all buffered data to be written to the physical disk.
        /bin/sync
        echo "SUCCESS: File created/resized to ${NUM_BYTES} bytes at ${FILE_PATH} and synced to disk."
        return 0
    else
        echo "ERROR: dd command failed for ${NUM_BYTES} bytes. Check logs for dd output." >&2
        return 1
    fi
}

handle_get() {
    if [ -f "$FILE_PATH" ]; then
        FILE_SIZE=$(wc -c < "$FILE_PATH")
        echo "{\"current_disk_usage_bytes\": ${FILE_SIZE}}"
    else
        echo "{\"current_disk_usage_bytes\": 0}"
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
