#!/bin/bash

AUDIT_LOG_FILE="audit.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')][USER] $@" | tee -a "$AUDIT_LOG_FILE"
$@ | tee "output/$(date '+%Y%m%d_%H%M%S').log"
