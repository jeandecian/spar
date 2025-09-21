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
