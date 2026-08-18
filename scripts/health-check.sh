#!/usr/bin/env bash
set -euo pipefail

TARGET_PORT=${1:-3001}
MAX_RETRIES=${2:-10}
SLEEP_INTERVAL=${3:-3}

TARGET_URL="http://127.0.0.1:${TARGET_PORT}/health"
echo "[INFO] Validating container health on ${TARGET_URL}..."

for ((i=1; i<=MAX_RETRIES; i++)); do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${TARGET_URL}" || echo "000")
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "[SUCCESS] Health check passed on attempt $i (HTTP $HTTP_STATUS)."
        exit 0
    fi
    
    echo "[WARN] Attempt $i failed (Status: $HTTP_STATUS). Retrying in ${SLEEP_INTERVAL}s..."
    sleep "$SLEEP_INTERVAL"
done

echo "[ERROR] Health check failed after $MAX_RETRIES attempts."
exit 1