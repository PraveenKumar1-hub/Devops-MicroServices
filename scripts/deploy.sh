#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${IMAGE_NAME:-"your-dockerhub-username/devops-microservice"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

NGINX_CONF="/etc/nginx/conf.d/app.conf"

echo "[INFO] Starting deployment for image: ${FULL_IMAGE}"

# Step 1: Pull the latest target image
docker pull "${FULL_IMAGE}"

# Step 2: Determine active/inactive color slots
if docker ps --format '{{.Names}}' | grep -q "app_blue"; then
    ACTIVE_COLOR="blue"
    TARGET_COLOR="green"
    TARGET_PORT=3002
    OLD_PORT=3001
else
    ACTIVE_COLOR="green"
    TARGET_COLOR="blue"
    TARGET_PORT=3001
    OLD_PORT=3002
fi

echo "[INFO] Active container: app_${ACTIVE_COLOR}. Deploying target: app_${TARGET_COLOR} on port ${TARGET_PORT}"

# Step 3: Stop any dead target container and launch new release
docker rm -f "app_${TARGET_COLOR}" 2>/dev/null || true

docker run -d \
    --name "app_${TARGET_COLOR}" \
    --restart unless-stopped \
    -p "${TARGET_PORT}:3000" \
    -e NODE_ENV=production \
    -e PORT=3000 \
    "${FULL_IMAGE}"

# Step 4: Execute health check verification
if bash "$(dirname "$0")/health-check.sh" "${TARGET_PORT}" 10 3; then
    echo "[INFO] Target container is healthy. Switching traffic in NGINX..."
    
    # Update NGINX upstream proxy configuration dynamically
    sudo sed -i "s/proxy_pass http:\/\/127.0.0.1:${OLD_PORT};/proxy_pass http:\/\/127.0.0.1:${TARGET_PORT};/g" "${NGINX_CONF}"
    sudo nginx -t && sudo nginx -s reload
    
    echo "[INFO] Traffic cutover successful. Decommissioning app_${ACTIVE_COLOR}..."
    docker stop "app_${ACTIVE_COLOR}" 2>/dev/null || true
    docker rm "app_${ACTIVE_COLOR}" 2>/dev/null || true
    
    echo "[SUCCESS] Zero-downtime deployment finished successfully!"
else
    echo "[CRITICAL] Target container failed health checks. Triggering automatic rollback..."
    docker stop "app_${TARGET_COLOR}" 2>/dev/null || true
    docker rm "app_${TARGET_COLOR}" 2>/dev/null || true
    echo "[CRITICAL] Deployment aborted. Live traffic remains uninterrupted on app_${ACTIVE_COLOR}."
    exit 1
fi