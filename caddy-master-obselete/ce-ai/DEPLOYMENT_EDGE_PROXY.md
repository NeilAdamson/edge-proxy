# ce-ai Deployment in Dual-PWA VPS Mode

This document explains how ce-ai runs behind a master edge Caddy on a shared VPS.

## Purpose

ce-ai `patient-pwa` is exposed through loopback-only port publishing, and edge Caddy provides public HTTPS hostname routing.

Public URL:

- `https://ceai.162.62.230.162.nip.io`

## Files that must stay aligned

- `docker-compose.prod.yml` (this project)
- `.env` production values used by this stack
- Edge stack files under `/opt/edge-proxy` (`docker-compose.yml`, `Caddyfile`, `README.md`)

## Required ce-ai production behavior

- `db`, `minio`, `backend-api`, `operator-portal` must not be publicly published.
- `patient-pwa` publishes loopback only:
  - `127.0.0.1:28080:3000`
- Auth URLs must match public hostname:
  - `PATIENT_NEXTAUTH_URL=https://ceai.162.62.230.162.nip.io`
  - `AUTH_URL` and `NEXTAUTH_URL` should resolve to the same value.
- `AUTH_TRUST_HOST=true` in reverse proxy mode.

## Start order on VPS

1. Start ce-ai stack.
2. Confirm patient app local endpoint is healthy.
3. Start edge Caddy stack.

## Project start command with edge check

Use this wrapper so operators get a warning if edge Caddy is down:

```bash
cd /path/to/ce-ai
chmod +x ./start-prod-dual.sh
./start-prod-dual.sh
```

The script starts ce-ai either way, but prints a clear warning when `edge-caddy` is not running.

## Validation checklist

1. On VPS, verify local upstream:
   - `curl -I http://127.0.0.1:28080`
2. Verify external route:
   - `curl -I https://ceai.162.62.230.162.nip.io`
3. Verify auth flow in browser:
   - login
   - callback redirect
   - session persistence
4. Verify PWA install/service worker behavior at ce-ai hostname.

## Rollback

If dual-ingress mode must be disabled:

1. Stop edge Caddy.
2. Revert `docker-compose.prod.yml` to previous exposure model.
3. Revert auth URL/env values as needed.
4. Restart ce-ai stack.

## Do not overwrite deployment wiring

Before replacing `docker-compose.prod.yml`, confirm:

1. Internal services keep `ports: []` in production override.
2. `patient-pwa` loopback binding remains `127.0.0.1:28080:3000`.
3. Auth URL variables still target public ce-ai hostname.
4. Repo docs and edge route are updated together.
