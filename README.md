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

## Start (recommended)

Use the production script (validates compose, brings stack up, prints status):

```bash
cd /opt/edge-proxy
chmod +x ./prod-deploy.sh
./prod-deploy.sh
```

## Start (manual)

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

From your **laptop or any host on the internet** (this is the definitive check):

```bash
curl -I https://hms.162.62.230.162.nip.io
curl -I https://ceai.162.62.230.162.nip.io
```

From the **VPS shell**, a plain `curl` to the public hostname often fails with “connection refused” or timeout even when edge Caddy is healthy. Many providers do not route traffic from an instance back to its own public IP (no hairpin / NAT loopback), so the request never reaches the Docker-published ports on `127.0.0.1`.

To test ingress **on the server without hairpin**, force the hostname to resolve to localhost so the packet stays on-box:

```bash
curl -I --resolve hms.162.62.230.162.nip.io:443:127.0.0.1 https://hms.162.62.230.162.nip.io
curl -I --resolve ceai.162.62.230.162.nip.io:443:127.0.0.1 https://ceai.162.62.230.162.nip.io
```

If those still fail, confirm something is listening and Caddy started cleanly:

```bash
docker compose ps
sudo ss -tlnp | grep -E ':80|:443'
docker port edge-caddy
docker compose logs --tail 80 caddy
```

(`ss` may show `docker-proxy` bound on `0.0.0.0:80` / `:443`; without `sudo`, process names are often hidden.)

## Troubleshooting

### Let's Encrypt / ACME: `lookup … on 127.0.0.53:53: … connection refused`

Caddy must resolve public hostnames (for example `acme-v02.api.letsencrypt.org`) to obtain certificates. On Ubuntu, Docker sometimes copies a `resolv.conf` that points at **systemd-resolved’s stub** (`127.0.0.53`). **Inside a container**, that loopback address is not the host’s resolver, so DNS fails and TLS issuance retries forever.

This stack sets **explicit DNS servers** on the `caddy` service in `docker-compose.yml` so ACME works regardless of host `resolv.conf`. After changing DNS, recreate the container:

```bash
cd /opt/edge-proxy
docker compose up -d --force-recreate
docker compose logs -f caddy
```

If you prefer a host-wide fix instead, configure Docker’s default DNS in `/etc/docker/daemon.json` (then restart Docker).

### HMS stack / upstream

HMS project Caddy should show a publish like `127.0.0.1:18080->80/tcp` on the **host**. Edge Caddy then proxies to `127.0.0.1:18080` on the **host network** (see Caddyfile). If that mapping is missing, edge will return bad gateway once TLS is healthy.

## Critical policy

- Only edge Caddy publishes `80`/`443`.
- Project stacks must use loopback or internal-only exposure.
- Any ingress change must update this folder and both project deployment docs in the same release.
