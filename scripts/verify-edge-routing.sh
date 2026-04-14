#!/usr/bin/env sh
# Validate edge Caddyfile host->loopback upstream wiring.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"

CADDYFILE="${CADDYFILE:-${REPO_ROOT}/Caddyfile}"

if [ ! -f "${CADDYFILE}" ]; then
  echo "[ERROR] Caddyfile not found: ${CADDYFILE}"
  exit 1
fi

echo "[INFO] Verifying edge Caddyfile: ${CADDYFILE}"

# Fail fast if someone forces TLS to loopback upstreams that are HTTP listeners.
if grep -Eq 'reverse_proxy[[:space:]]+https://127\.0\.0\.1:(28080|28081)\b' "${CADDYFILE}"; then
  echo "[ERROR] Invalid upstream scheme found in Caddyfile."
  echo "[ERROR] ce-ai loopback upstreams on 127.0.0.1:28080 and :28081 are plain HTTP."
  echo "[ERROR] Use: reverse_proxy 127.0.0.1:28080 and reverse_proxy 127.0.0.1:28081 (no https://)."
  exit 1
fi

assert_exact_route() {
  host="$1"
  upstream="$2"
  # Require a host block that contains a reverse_proxy to the exact upstream.
  awk -v host="${host}" -v upstream="${upstream}" '
    $0 ~ "^[[:space:]]*" host "[[:space:]]*\\{" { in_block=1; next }
    in_block && $0 ~ "^[[:space:]]*\\}" { in_block=0 }
    in_block && $0 ~ ("reverse_proxy[[:space:]]+" upstream "([[:space:]]|$)") { found=1 }
    END { exit(found ? 0 : 1) }
  ' "${CADDYFILE}" || {
    echo "[ERROR] Missing or incorrect route: ${host} -> ${upstream}"
    exit 1
  }
}

assert_exact_route 'hms.162.62.230.162.nip.io' '127.0.0.1:18080'
assert_exact_route 'ceai.162.62.230.162.nip.io' '127.0.0.1:28080'
assert_exact_route 'ceai.operator.162.62.230.162.nip.io' '127.0.0.1:28081'

echo "[OK] Edge route wiring is valid."
echo "[OK] hms.162.62.230.162.nip.io -> 127.0.0.1:18080"
echo "[OK] ceai.162.62.230.162.nip.io -> 127.0.0.1:28080"
echo "[OK] ceai.operator.162.62.230.162.nip.io -> 127.0.0.1:28081"
