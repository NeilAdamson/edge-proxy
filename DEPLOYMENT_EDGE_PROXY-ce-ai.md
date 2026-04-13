# ce-ai Deployment in Dual-PWA VPS Mode

This document explains how ce-ai runs behind a master edge Caddy on a shared VPS.

## Purpose

Both ce-ai web apps (`patient-pwa` and `operator-portal`) are exposed through **loopback-only** port publishing on the VPS host. Edge Caddy terminates public HTTPS and routes each hostname to the correct upstream.

Public URLs (current pilot hostnames):

| App | HTTPS URL | Loopback upstream (host) |
|-----|-----------|---------------------------|
| Patient | `https://ceai.162.62.230.162.nip.io` | `127.0.0.1:28080` → container `3000` |
| Operator | `https://ceai.operator.162.62.230.162.nip.io` | `127.0.0.1:28081` → container `3000` |

Infrastructure (`db`, `minio`, `backend-api`) stays on the Docker network only — **no** host port bindings in production.

## Files that must stay aligned

- `docker-compose.prod.yml` (this project)
- `.env` production values used by this stack
- Edge stack files under `/opt/edge-proxy` (`docker-compose.yml`, `Caddyfile`, `README.md`)

Note: `docker-compose.prod.yml` uses Compose `!reset` / `!override` semantics on `ports` so the production override removes inherited public bindings from `docker-compose.yml` while keeping only the **two** PWA loopback bindings.

## Required ce-ai production behavior

- `db`, `minio`, `backend-api` must not publish host ports.
- `patient-pwa` publishes loopback only: `127.0.0.1:28080:3000`.
- `operator-portal` publishes loopback only: `127.0.0.1:28081:3000`.
- Auth URLs must match public hostnames:
  - `PATIENT_NEXTAUTH_URL=https://ceai.162.62.230.162.nip.io`
  - `OPERATOR_NEXTAUTH_URL=https://ceai.operator.162.62.230.162.nip.io`
  - `OPERATOR_INTERNAL_ONLY=false` for end-to-end pilot testing with both apps on the internet.
  - `CORS_ALLOWED_ORIGINS` must include **both** HTTPS origins (comma-separated).
- `AUTH_URL` / `NEXTAUTH_URL` per app are set from those values in Compose overrides.
- `AUTH_TRUST_HOST=true` in reverse proxy mode.

## Edge proxy repository: checklist for the edge-proxy team

Apply these steps in the **edge-proxy** (Caddy) project on the same VPS. This repo does not contain that stack; keep it in sync with the table above.

### 1. DNS / nip.io

- Ensure both hostnames resolve to the VPS public IPv4 `162.62.230.162`:
  - `ceai.162.62.230.162.nip.io`
  - `ceai.operator.162.62.230.162.nip.io`  
  (nip.io embeds the IP in the name; no separate DNS panel is required if you use these exact names.)

### 2. Caddyfile — add or update site blocks

Each public hostname needs a `reverse_proxy` to the **loopback** port the ce-ai stack publishes:

- Patient → `127.0.0.1:28080`
- Operator → `127.0.0.1:28081`

Example (adjust to match your edge repo’s style, TLS, and logging):

```caddyfile
ceai.162.62.230.162.nip.io {
	reverse_proxy 127.0.0.1:28080
}

ceai.operator.162.62.230.162.nip.io {
	reverse_proxy 127.0.0.1:28081
}
```

Caddy should obtain certificates for both names (automatic HTTPS). Reload Caddy after editing.

### 3. Do not proxy these from the edge host

- Do **not** expose PostgreSQL, MinIO, or the backend API on `0.0.0.0`. Those services must remain reachable only inside the ce-ai Compose network unless you add a separate, authenticated internal route by design.

### 4. Firewall (if applicable)

- Allow inbound **443** (and **80** if you rely on HTTP→HTTPS redirects) to the edge container/host.
- Do **not** open `28080` / `28081` to the public internet; they are bound to `127.0.0.1` for Caddy only.

### 5. Verification on the VPS

After ce-ai is up and edge Caddy is reloaded:

1. `curl -fsSI https://ceai.162.62.230.162.nip.io` — should return a response from the patient app.
2. `curl -fsSI https://ceai.operator.162.62.230.162.nip.io` — should return a response from the operator app.
3. From the ce-ai repo: `./scripts/verify-dual-ingress.sh` (optional env overrides if you use non-default hostnames).

## Start order on VPS

1. Start the ce-ai stack (patient and operator listeners on loopback).
2. Confirm local endpoints respond (`127.0.0.1:28080`, `127.0.0.1:28081`).
3. Start or reload the edge Caddy stack.

## Project deploy command

Use the production deploy script so operators get the production preflight plus an edge-proxy status warning:

```bash
cd /path/to/ce-ai
chmod +x ./scripts/prod-deploy.sh
./scripts/prod-deploy.sh
```

The script deploys ce-ai either way, but prints a clear warning when `edge-caddy` is not running.

The legacy wrapper remains available if someone still calls it:

```bash
./scripts/start-prod-dual.sh
```

It now forwards directly to `./scripts/prod-deploy.sh`.

After deploy, run the one-shot ingress verification:

```bash
cd /path/to/ce-ai
chmod +x ./scripts/verify-dual-ingress.sh
./scripts/verify-dual-ingress.sh
```

Or combine both steps:

```bash
./scripts/prod-deploy.sh --verify
```

On Windows (from repo root, with Docker available):

```powershell
.\scripts\prod-deploy.ps1
```

Then run `verify-dual-ingress.sh` from Git Bash or WSL if you use those tools on the server.

## Validation checklist

1. Run `./scripts/verify-dual-ingress.sh`.
2. Verify auth flows in a browser:
   - patient: login, callback redirect, session persistence at the patient hostname
   - operator: login, callback redirect, session persistence at the operator hostname
3. Verify PWA install/service worker behavior at the patient hostname (operator is typically browser-only).

## Rollback

If dual-ingress mode must be disabled:

1. Stop edge Caddy.
2. Revert `docker-compose.prod.yml` to the previous exposure model.
3. Revert auth URL/env values as needed.
4. Restart the ce-ai stack.

## Do not overwrite deployment wiring

Before replacing `docker-compose.prod.yml`, confirm:

1. Internal services keep their production `ports` cleared with Compose reset semantics.
2. `patient-pwa` loopback binding remains `127.0.0.1:28080:3000`.
3. `operator-portal` loopback binding remains `127.0.0.1:28081:3000`.
4. Auth URL variables still target the public ce-ai hostnames.
5. Repo docs and edge routes are updated together.
