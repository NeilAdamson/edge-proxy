# Edge Caddy (Master Ingress) Runbook

This directory is infrastructure code for the VPS edge proxy. Keep it versioned.

## Purpose

Expose multiple isolated application stacks on one server IP with host-based routing:

- `hms.162.62.230.162.nip.io` -> HMS local upstream `127.0.0.1:18080`
- `ceai.162.62.230.162.nip.io` -> ce-ai local upstream `127.0.0.1:28080`

## Why separate from app repositories

- Prevent accidental overwrite when app teams replace project compose files.
- Keep ingress concerns and TLS lifecycle in one place.
- Make recovery reproducible by versioning this folder.

## Deploy location

Recommended path on VPS:

- `/opt/edge-proxy`

## Prerequisites

- Docker and Docker Compose plugin available on VPS.
- Lighthouse security group allows inbound TCP `80` and `443`.
- HMS and ce-ai stacks running and bound to loopback upstream ports.

## Start

```bash
cd /opt/edge-proxy
docker compose up -d
```

## Check logs

```bash
docker compose logs -f caddy
```

## Stop

```bash
docker compose down
```

## Validation

```bash
curl -I https://hms.162.62.230.162.nip.io
curl -I https://ceai.162.62.230.162.nip.io
```

## Critical policy

- Only edge Caddy publishes `80`/`443`.
- Project stacks must use loopback or internal-only exposure.
- Any ingress change must update this folder and both project deployment docs in the same release.
