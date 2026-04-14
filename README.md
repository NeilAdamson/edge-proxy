# Edge Caddy (Master Ingress) Runbook

This directory is infrastructure code for the VPS edge proxy. Keep it versioned.

## Purpose

Expose multiple isolated application stacks on one server IP with host-based routing:

- `hms.162.62.230.162.nip.io` -> HMS local upstream `127.0.0.1:18080`
- `ceai.162.62.230.162.nip.io` -> ce-ai patient local upstream `127.0.0.1:28080`
- `ceai.operator.162.62.230.162.nip.io` -> ce-ai operator local upstream `127.0.0.1:28081`

## Why separate from app repositories

- Prevent accidental overwrite when app teams replace project compose files.
- Keep ingress concerns and TLS lifecycle in one place.
- Make recovery reproducible by versioning this folder.

## Deploy location

Recommended path on VPS:

- `/opt/edge-proxy`

This stack uses a single **`docker-compose.yml`** (no `docker-compose.prod.yml`). Production and operators run Compose against that file (or set `COMPOSE_FILE` if you fork a variant).

## Prerequisites

- Docker and Docker Compose plugin available on VPS.
- Lighthouse security group allows inbound TCP `80` and `443`.
- HMS and ce-ai stacks running and bound to loopback upstream ports.
- **Linux host**: edge Caddy uses `network_mode: host` (see `docker-compose.yml`) so upstream addresses `127.0.0.1:18080` / `:28080` in the Caddyfile target the **host** where those ports are published. Without host networking, `127.0.0.1` inside the container is wrong and you get **502** with `dial tcp 127.0.0.1:18080: connect: connection refused` in edge logs.

## Start (recommended)

Use the production script (validates compose, brings stack up, prints status):

```bash
cd /opt/edge-proxy
./prod-deploy.sh
```

The executable bit is **stored in git** (`100755`) so `git pull` does not fight with a manual `chmod` on the server. If an old clone still says `Permission denied`, run `sh ./prod-deploy.sh` once or `git checkout -- prod-deploy.sh && git pull` after updating, or `chmod +x ./prod-deploy.sh` only until the next pull that includes the mode fix.

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
curl -I https://ceai.operator.162.62.230.162.nip.io
```

Preflight the edge route wiring on the VPS before restart/reload:

```bash
cd /opt/edge-proxy
chmod +x ./scripts/verify-edge-routing.sh
./scripts/verify-edge-routing.sh
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
docker compose logs --tail 80 caddy
```

With `network_mode: host`, Caddy binds **directly** on the host (no `docker-proxy`); `docker port edge-caddy` is empty. Use `ss` to verify listeners. Without `sudo`, process names are often hidden.

## Troubleshooting

### Let's Encrypt / ACME: `lookup … on 127.0.0.53:53: … connection refused`

If you ever run edge Caddy **without** `network_mode: host` (not recommended here), Caddy may inherit a broken `resolv.conf` (`127.0.0.53`) and ACME DNS fails. This stack uses **host networking**, so Caddy uses the **host’s** resolver and this is normally not an issue.

If you must use bridge mode, set explicit DNS on the service (for example `dns: [1.1.1.1, 8.8.8.8]`) or fix Docker/systemd-resolved integration, then `docker compose up -d --force-recreate`.

### HTTP 502: `dial tcp 127.0.0.1:18080: connect: connection refused`

TLS at the edge works, but the **upstream** TCP connection fails.

1. **Bridge mode** (no `network_mode: host`): `127.0.0.1` in the Caddyfile is the **edge container**, not the host. Fix: use **`network_mode: host`** for edge Caddy, then recreate the container.

2. **Already on host mode** and still `connection refused`: nothing is listening on the **host** at that address/port. That is almost always an **HMS (or ce-ai) deployment** issue, not edge logic: stack stopped, wrong compose file, or **port changed** (e.g. “new port settings” in HMS). You do not need HMS **application** source; you need the **published port** in HMS’s `docker-compose` (or equivalent) for the project Caddy service.

On the VPS, confirm the upstream before debugging edge further:

```bash
sudo ss -tlnp | grep -E ':18080|:28080'
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18080/ || true
cd /opt/hms && docker compose ps
```

HMS `docker-compose.prod.yml` should keep `127.0.0.1:18080:80` on the **project** Caddy service (dual-stack mode). That matches this repo’s `reverse_proxy 127.0.0.1:18080`.

Edge sends `Host: hms.162.62.230.162.nip.io` to the upstream. To mimic that without going through TLS:

```bash
curl -sv -H "Host: hms.162.62.230.162.nip.io" http://127.0.0.1:18080/ 2>&1 | head -30
```

If **`curl http://127.0.0.1:18080/` works on the VPS** but edge logs still show `dial tcp 127.0.0.1:18080: connect: connection refused`, edge is **not** using the host network namespace (it is still behaving like bridge mode). Check the **running** container, not only the file:

```bash
cd /opt/edge-proxy
docker inspect edge-caddy --format '{{.HostConfig.NetworkMode}}'
docker compose config | grep -A1 network_mode
```

You must see **`host`**. If you see **`bridge`** or a network name, fix deployment: **`git pull`** (or copy the current `docker-compose.yml`), remove any **`docker-compose.override.yml`** that drops `network_mode`, then **`docker compose up -d --force-recreate`**. `./prod-deploy.sh` prints `NetworkMode` after deploy and errors if it is not `host`.

If HMS uses a port other than `18080`, update **`Caddyfile`** here (and redeploy edge) so `reverse_proxy` matches **exactly** what HMS publishes on `127.0.0.1`.

`28080` for ce-ai fails the same way until that stack is up or the port is published.

### Browser `ERR_SSL_PROTOCOL_ERROR` on ce-ai operator/patient hostnames

If the public URL fails TLS in the browser while upstream loopback checks work, verify edge is not forcing TLS to loopback upstreams:

- `reverse_proxy https://127.0.0.1:28080` is wrong
- `reverse_proxy https://127.0.0.1:28081` is wrong
- correct format is plain HTTP upstream (no scheme): `reverse_proxy 127.0.0.1:28080` / `reverse_proxy 127.0.0.1:28081`

Run:

```bash
cd /opt/edge-proxy
./scripts/verify-edge-routing.sh
```

The verifier also enforces exact hostname -> upstream mappings:

- `hms.162.62.230.162.nip.io` -> `127.0.0.1:18080`
- `ceai.162.62.230.162.nip.io` -> `127.0.0.1:28080`
- `ceai.operator.162.62.230.162.nip.io` -> `127.0.0.1:28081`

### HMS stack / upstream

HMS project Caddy should show a publish like `127.0.0.1:18080->80/tcp` on the **host**. With host networking for edge, the Caddyfile’s `127.0.0.1:18080` must match that **published host port** byte-for-byte. If the mapping is missing or HMS is stopped, edge returns bad gateway once TLS is healthy.

## Critical policy

- Only edge Caddy publishes `80`/`443`.
- Project stacks must use loopback or internal-only exposure.
- Any ingress change must update this folder and both project deployment docs in the same release.
