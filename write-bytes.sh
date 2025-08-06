#!/bin/sh
set -e

MOUNT_LOCATION="${MOUNT_LOCATION:-/mnt/data}"
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

    if [ -f "$FILE_PATH" ]; then
        if ! /bin/rm -f "$FILE_PATH"; then
            echo "ERROR: Could not remove existing file $FILE_PATH before dd." >&2
            return 1
        fi
    fi

    local DD_CMD=""
    if [ "$NUM_BYTES" -ge 1048576 ]; then
        BLOCK_SIZE="1M"
        COUNT=$((NUM_BYTES / 1048576))
        REMAINING_BYTES=$((NUM_BYTES % 1048576))

        DD_CMD="/bin/dd if=/dev/zero of=\"$FILE_PATH\" bs=\"$BLOCK_SIZE\" count=\"$COUNT\""
        if [ "$REMAINING_BYTES" -gt 0 ]; then
            DD_CMD="$DD_CMD conv=notrunc && /bin/dd if=/dev/zero of=\"$FILE_PATH\" bs=1 count=\"$REMAINING_BYTES\" seek=\"$((COUNT * 1048576))\" conv=notrunc"
        fi
    else
        DD_CMD="/bin/dd if=/dev/zero of=\"$FILE_PATH\" bs=1 count=\"$NUM_BYTES\""
    fi

    if eval "$DD_CMD" 2>&1; then
        echo "SUCCESS: File created/resized to ${NUM_BYTES} bytes at ${FILE_PATH} using dd."
        return 0
    else
        echo "ERROR: dd command failed for ${NUM_BYTES} bytes. Check logs for dd output." >&2
        return 1
    fi
}

handle_get() {
    if [ -f "$FILE_PATH" ]; then
        FILE_SIZE=$(/usr/bin/stat -c %s "$FILE_PATH")
        echo "{\"current_disk_usage_bytes\": ${FILE_SIZE}}"
    else
        echo "{\"current_disk_usage_bytes\": 0}"
    fi
    # Ensure a newline and flush for NGINX Lua to capture the full output
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
