#!/usr/bin/env sh
set -eu

EDGE_CONTAINER_NAME="${EDGE_CONTAINER_NAME:-edge-caddy}"

if docker ps --format '{{.Names}}' | rg -x "${EDGE_CONTAINER_NAME}" >/dev/null 2>&1; then
  echo "[OK] Edge proxy container '${EDGE_CONTAINER_NAME}' is running."
else
  echo "[WARN] Edge proxy container '${EDGE_CONTAINER_NAME}' is NOT running."
  echo "[WARN] HMS services may start successfully but will not be publicly reachable via nip.io until edge proxy is up."
  echo "[WARN] Start edge proxy with: cd /opt/edge-proxy && docker compose up -d"
fi

echo "[INFO] Starting HMS production stack..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

