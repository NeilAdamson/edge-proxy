# Retrofit Procedure: VPS Copies Back to Source Repositories

Use this process after validating runtime changes on VPS copies, so deployment wiring is not lost.

## Scope

This applies to:

- HMS repository
- ce-ai repository
- edge-proxy infrastructure folder (`/opt/edge-proxy`)

## Canonical changed files from this implementation

- `HMS/docker-compose.prod.yml`
- `HMS/DEPLOYMENT_EDGE_PROXY.md`
- `HMS/start-prod-dual.sh`
- `ce-ai/docker-compose.prod.yml`
- `ce-ai/DEPLOYMENT_EDGE_PROXY.md`
- `ce-ai/start-prod-dual.sh`
- `edge-proxy/docker-compose.yml`
- `edge-proxy/Caddyfile`
- `edge-proxy/prod-deploy.sh`
- `edge-proxy/README.md`

## Mandatory sync sequence

1. Freeze VPS copies
   - No ad-hoc edits after successful validation.
2. Sync docs first
   - Copy deployment markdown updates into each source repo before config files.
3. Sync compose/config second
   - Copy commented compose changes exactly as validated.
4. Re-run smoke tests from each source repo context.
5. Commit each repo separately with deployment-focused messages.
6. Version edge-proxy folder separately (preferred: dedicated git repo).

## HMS repository retrofit

1. Copy `docker-compose.prod.yml` into HMS repo root.
2. Copy `DEPLOYMENT_EDGE_PROXY.md` into HMS repo root (or project deployment docs folder if policy requires).
3. Verify HMS comment block on caddy port mapping still exists.
4. Run project deployment smoke test.
5. Commit in HMS repo.

Suggested commit message:

- `docs+deploy: run HMS behind edge Caddy on loopback upstream`

## ce-ai repository retrofit

1. Copy `docker-compose.prod.yml` into ce-ai repo root.
2. Copy `DEPLOYMENT_EDGE_PROXY.md` into ce-ai repo root (or project deployment docs folder if policy requires).
3. Verify production override still contains:
   - `db/minio/backend-api/operator-portal` with `ports: []`
   - `patient-pwa` loopback binding `127.0.0.1:28080:3000`
   - auth URL/env values for ce-ai nip.io hostname
4. Run project deployment smoke test.
5. Commit in ce-ai repo.

Suggested commit message:

- `docs+deploy: configure ce-ai for edge Caddy host-based ingress`

## Edge-proxy deployment ownership

Recommended:

1. Create repo such as `infra-edge-proxy` (private).
2. Track:
   - `docker-compose.yml`
   - `Caddyfile`
   - `README.md`
3. Deploy repo contents to `/opt/edge-proxy` on VPS.
4. Update this repo whenever routes/ports/domains change.

If you cannot use git for edge-proxy:

- Keep a versioned backup archive with dated snapshots and a changelog.

## Anti-overwrite policy

Before any future compose replacement in either app repo, required checks:

1. Is edge Caddy still single ingress on `80/443`?
2. Are app stack published ports loopback/internal as documented?
3. Do project docs match actual runtime config?
4. Are auth URLs still aligned with public hostname?

If any answer is no, stop and update docs+config in one change cycle.
