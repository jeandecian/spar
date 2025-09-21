#!/bin/bash

AUDIT_LOG_FILE="audit.log"

echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][USER] $@" | tee -a "$AUDIT_LOG_FILE"

CLEAN_CMD_NAME=$(echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
OUTPUT_FILE="output/${CLEAN_CMD_NAME}_$(date '+%Y%m%d_%H%M%S').log"

if "$@" > "$OUTPUT_FILE" 2>&1; then
    echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Command executed successfully." | tee -a "$AUDIT_LOG_FILE"
    echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Saving output to '$OUTPUT_FILE'." | tee -a "$AUDIT_LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][FAIL] Command failed." | tee -a "$AUDIT_LOG_FILE"
    echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][FAIL] Check '$OUTPUT_FILE' or below for details." | tee -a "$AUDIT_LOG_FILE"
    cat "$OUTPUT_FILE" | tee -a "$AUDIT_LOG_FILE"
    exit 1
fi

COMMAND="$1"

if [[ "$COMMAND" == "ip" ]]; then
    if [[ "$2" == "a" || "$2" == "addr" ]]; then
        echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Searching for network addresses in '${OUTPUT_FILE}'." | tee -a "$AUDIT_LOG_FILE"

        NETWORK_ADDRESSES=$(grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}' "$OUTPUT_FILE" | sort -u)

        mapfile -t NETWORK_ADDRESSES_ARRAY <<< "$NETWORK_ADDRESSES"

        NETWORK_ADDRESSES_COUNT=${#NETWORK_ADDRESSES_ARRAY[@]}

        if [[ $NETWORK_ADDRESSES_COUNT -gt 0 ]]; then
            echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][FIND] Found $NETWORK_ADDRESSES_COUNT unique network addresses: ${NETWORK_ADDRESSES_ARRAY[@]}." | tee -a "$AUDIT_LOG_FILE"

            for NETWORK_ADDRESS in "${NETWORK_ADDRESSES_ARRAY[@]}"; do
                if [[ "$NETWORK_ADDRESS" == "127.0.0.1"* ]]; then
                    echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Skipping loopback address '$NETWORK_ADDRESS'." | tee -a "$AUDIT_LOG_FILE"
                    continue
                fi

                echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][NEXT] Suggested next command: 'nmap -sn ${NETWORK_ADDRESS}' to discover active hosts." | tee -a "$AUDIT_LOG_FILE"
            done
        else
            echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] No network addresses found in the output." | tee -a "$AUDIT_LOG_FILE"
        fi
    fi
elif [[ "$COMMAND" == "nmap" ]]; then
    if [[ "$2" == "-A" ]]; then
        echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Searching for open ports in '${OUTPUT_FILE}'." | tee -a "$AUDIT_LOG_FILE"

        OPEN_PORTS=$(grep -Eo '([0-9]{1,5}/tcp|[0-9]{1,5}/udp) +open' "$OUTPUT_FILE" | awk '{print $1}' | sort -u)

        mapfile -t OPEN_PORTS_ARRAY <<< "$OPEN_PORTS"

        OPEN_PORTS_COUNT=${#OPEN_PORTS_ARRAY[@]}

        if [[ $OPEN_PORTS_COUNT -gt 0 ]]; then
            echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][FIND] Found $OPEN_PORTS_COUNT open ports: ${OPEN_PORTS_ARRAY[@]}." | tee -a "$AUDIT_LOG_FILE"

            for OPEN_PORT in "${OPEN_PORTS_ARRAY[@]}"; do
                CLEAN_OPEN_PORT=$(echo "$OPEN_PORT" | awk -F'/' '{print $1}')
                
                mkdir -p "output/$3/${CLEAN_OPEN_PORT}"

                echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Created directory 'output/$3/${CLEAN_OPEN_PORT}' for open port '$OPEN_PORT'." | tee -a "$AUDIT_LOG_FILE"
            done
        else
            echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] No open ports found in the output." | tee -a "$AUDIT_LOG_FILE"
        fi
    elif [[ "$2" == "-sn" ]]; then
        echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Searching for active hosts in '${OUTPUT_FILE}'." | tee -a "$AUDIT_LOG_FILE"

        ACTIVE_HOSTS=$(grep -Eo 'Nmap scan report for ([0-9]{1,3}\.){3}[0-9]{1,3}' "$OUTPUT_FILE" | awk '{print $5}' | sort -u)

        mapfile -t ACTIVE_HOSTS_ARRAY <<< "$ACTIVE_HOSTS"

        ACTIVE_HOSTS_COUNT=${#ACTIVE_HOSTS_ARRAY[@]}

        if [[ $ACTIVE_HOSTS_COUNT -gt 0 ]]; then
            echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][FIND] Found $ACTIVE_HOSTS_COUNT active hosts: ${ACTIVE_HOSTS_ARRAY[@]}." | tee -a "$AUDIT_LOG_FILE"

            for ACTIVE_HOST in "${ACTIVE_HOSTS_ARRAY[@]}"; do
                mkdir -p "output/${ACTIVE_HOST}"

                echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] Created directory 'output/${ACTIVE_HOST}' for active host '$ACTIVE_HOST'." | tee -a "$AUDIT_LOG_FILE"
                echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][NEXT] Suggested next command: 'nmap -A ${ACTIVE_HOST}' for detailed scanning." | tee -a "$AUDIT_LOG_FILE"
            done
        else
            echo "[$(date '+%Y-%m-%d')][$(date '+%H:%M:%S')][INFO] No active hosts found in the output." | tee -a "$AUDIT_LOG_FILE"
        fi
    fi
fi
