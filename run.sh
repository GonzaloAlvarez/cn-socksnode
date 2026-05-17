#!/usr/bin/env bash
# Bring up cn-socksnode and choose an exit-node mode.
#
# Modes:
#   ./run.sh                 — default; no tailnet exit-node, --accept-routes ON.
#                              SOCKS5/HTTP-CONNECT reaches tailnet hosts
#                              (*.lab.gn.al) AND home-LAN ranges (10.0.0.0/24,
#                              10.1.0.0/16, 10.120.22.0/24) via subnet routes
#                              advertised by infra-exit. Public internet egress
#                              uses the Mac's local connection.
#   ./run.sh --exit-lan      — set tailnet exit-node = infra-exit. Useful for
#                              an off-LAN Mac that wants its public IP to look
#                              like home, or when the OS-level tailscale client
#                              also wants .lan reachability. Note: tailscale's
#                              built-in SOCKS5 doesn't fully honor exit-node
#                              for every destination; LAN access still relies
#                              on --accept-routes (also enabled).
#   ./run.sh --exit-mullvad  — set tailnet exit-node = infra-mullvad. Routes
#                              all egress through the Mullvad WireGuard tunnel
#                              on infra.lan. Requires cn-infra's wg-mullvad +
#                              ts-mullvad services to be healthy.
#   ./run.sh --status        — print current prefs (exit-node, accept-routes).
set -euo pipefail

cd "$(dirname "$0")"
CONTAINER=cn-socksnode-tailnet-proxy-1

docker compose up -d >/dev/null

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if docker exec "$CONTAINER" tailscale status --self=true >/dev/null 2>&1; then break; fi
  sleep 1
done

case "${1:-}" in
  ""|--default)
    docker exec "$CONTAINER" tailscale set --exit-node= --accept-routes=true
    echo "[cn-socksnode] default — no exit-node, accept-routes ON"
    ;;
  --exit-lan)
    docker exec "$CONTAINER" tailscale set --exit-node=infra-exit --exit-node-allow-lan-access=true --accept-routes=true
    echo "[cn-socksnode] exit-node = infra-exit (LAN egress)"
    ;;
  --exit-mullvad)
    docker exec "$CONTAINER" tailscale set --exit-node=infra-mullvad --accept-routes=true
    echo "[cn-socksnode] exit-node = infra-mullvad (Mullvad egress)"
    ;;
  --status) ;;
  *)
    echo "unknown flag: $1" >&2
    sed -n '3,24p' "$0" >&2
    exit 2
    ;;
esac

docker exec "$CONTAINER" tailscale status --self=true --json 2>/dev/null \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
s = d['Self']
exit_id = (d.get('ExitNodeStatus') or {}).get('ID', '(none)')
print(f\"self={s['HostName']} ip={s['TailscaleIPs'][0]} exit-node={exit_id}\")
"
