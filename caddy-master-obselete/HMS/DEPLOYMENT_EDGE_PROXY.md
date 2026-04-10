# HMS Deployment in Dual-PWA VPS Mode

This document explains how HMS runs behind a master edge Caddy on a shared VPS.

## Purpose

HMS is not directly internet-facing in this mode. HMS project Caddy listens on loopback and edge Caddy handles public TLS and routing.

Public URL:

- `https://hms.162.62.230.162.nip.io`

## Files that must stay aligned

- `docker-compose.prod.yml` (this project)
- `ops/Caddyfile.nipio` (this project, if used in production)
- Edge stack files under `/opt/edge-proxy` (`docker-compose.yml`, `Caddyfile`, `README.md`)

## Required HMS production behavior

- HMS `caddy` service must **not** publish host `80/443`.
- HMS `caddy` service must publish loopback only:
  - `127.0.0.1:18080:80`

This avoids port collision with edge Caddy and ensures one ingress point.

## Start order on VPS

1. Start HMS stack.
2. Start ce-ai stack.
3. Start edge Caddy stack.

## Project start command with edge check

Use this wrapper so operators get a warning if edge Caddy is down:

```bash
cd /path/to/HMS
chmod +x ./start-prod-dual.sh
./start-prod-dual.sh
```

The script starts HMS either way, but prints a clear warning when `edge-caddy` is not running.

## Validation checklist

1. On VPS, verify HMS local upstream:
   - `curl -I http://127.0.0.1:18080`
2. Verify external route:
   - `curl -I https://hms.162.62.230.162.nip.io`
3. Verify HMS app routes in browser:
   - `/`
   - `/api/...`
   - `/provider...`
   - `/operator...`

## Rollback

If edge setup must be removed temporarily:

1. Stop edge Caddy.
2. Restore HMS previous public port bindings in `docker-compose.prod.yml` (`80:80`, `443:443`).
3. Restart HMS stack.

## Do not overwrite deployment wiring

Before replacing `docker-compose.prod.yml`, confirm:

1. Loopback binding for HMS Caddy is still present.
2. Comment explaining edge-ingress-only behavior is still present.
3. Corresponding edge Caddy route still points to `127.0.0.1:18080`.
4. Repo docs are updated in the same change.
