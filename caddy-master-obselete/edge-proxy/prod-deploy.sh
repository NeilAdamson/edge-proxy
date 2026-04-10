#!/usr/bin/env sh
# Production deploy for edge Caddy (single public ingress on 80/443).
# Run from this directory or any path: ./prod-deploy.sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

echo "[INFO] Validating compose file: ${COMPOSE_FILE}"
docker compose -f "${COMPOSE_FILE}" config >/dev/null

echo "[INFO] Starting edge Caddy (master ingress)..."
docker compose -f "${COMPOSE_FILE}" up -d

echo "[INFO] Status:"
docker compose -f "${COMPOSE_FILE}" ps

if docker ps --format '{{.Names}}' | grep -Fx 'edge-caddy' >/dev/null 2>&1; then
  echo "[OK] Container 'edge-caddy' is running."
else
  echo "[WARN] Expected container 'edge-caddy' not found in running containers. Check logs: docker compose logs caddy"
fi

echo "[INFO] Public endpoints (after upstream apps are up):"
echo "  https://hms.162.62.230.162.nip.io"
echo "  https://ceai.162.62.230.162.nip.io"
echo "[INFO] Logs: docker compose -f ${COMPOSE_FILE} logs -f caddy"
