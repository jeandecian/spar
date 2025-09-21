#!/bin/bash

AUDIT_LOG_FILE="audit.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')][USER] $@" | tee -a "$AUDIT_LOG_FILE"

CLEAN_CMD_NAME=$(echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
OUTPUT_FILE="output/${CLEAN_CMD_NAME}_$(date '+%Y%m%d_%H%M%S').log"

if "$@" > "$OUTPUT_FILE" 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][SUCCESS] Command '$@' executed successfully and saved in '$OUTPUT_FILE'." | tee -a "$AUDIT_LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][ERROR] Command '$@' failed. Check '$OUTPUT_FILE' for details." | tee -a "$AUDIT_LOG_FILE"
fi

COMMAND="$1"

if [[ "$COMMAND" == "ip" ]]; then
    if [[ "$2" == "a" || "$2" == "addr" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')][SPAR] '$@' was detected. Searching for network addresses in '${OUTPUT_FILE}'." | tee -a "$AUDIT_LOG_FILE"

        NETWORK_ADDRESSES=$(grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}' "$OUTPUT_FILE" | sort -u)

        mapfile -t NETWORK_ADDRESSES_ARRAY <<< "$NETWORK_ADDRESSES"

        NETWORK_ADDRESSES_COUNT=${#NETWORK_ADDRESSES_ARRAY[@]}

        if [[ $NETWORK_ADDRESSES_COUNT -gt 0 ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')][SPAR] Found $NETWORK_ADDRESSES_COUNT unique network addresses: ${NETWORK_ADDRESSES_ARRAY[@]}." | tee -a "$AUDIT_LOG_FILE"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')][SPAR] No network addresses found in the output." | tee -a "$AUDIT_LOG_FILE"
        fi
    fi
fi
