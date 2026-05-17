# cn-socksnode

A Tailscale node that exposes a SOCKS5 proxy and an HTTP CONNECT proxy on localhost, allowing local applications to route traffic through the tailnet.

## What it does

| Port | Protocol | Use |
|---|---|---|
| `127.0.0.1:1055` | SOCKS5 | Browser proxy, curl, etc. |
| `127.0.0.1:1056` | HTTP CONNECT | Applications that prefer HTTP proxy |

Once configured, any application pointed at these proxies can reach tailnet hostnames (e.g. `grafana.lab.gn.al`, `passwords.lab.gn.al`) and MagicDNS names as if the machine were directly on the tailnet.

Runs in kernel mode (`tailscale0` TUN device) so that DNS is properly configured — without this, MagicDNS and split DNS names fail to resolve.

## Setup

### 1. Create `.env`

```sh
cp .env.example .env
# fill in HEADSCALE_DOMAIN and TAILNET_AUTHKEY
```

| Variable | Description |
|---|---|
| `HEADSCALE_DOMAIN` | Public hostname of your Headscale server (e.g. `hs.example.com`) |

### 2. Start

```sh
./run.sh                  # default — no exit-node, --accept-routes ON
./run.sh --exit-lan       # tailnet exit-node = infra-exit (LAN egress)
./run.sh --exit-mullvad   # tailnet exit-node = infra-mullvad (Mullvad egress)
./run.sh --status         # show current prefs
```

First run will print a Headscale auth URL — visit it once to authorize the node.

Verify the tailscale0 interface was created (kernel mode is required for DNS to work):

```sh
docker exec cn-socksnode-tailnet-proxy-1 ip addr show tailscale0
```

### What each mode does

| Mode | What changes | When to use |
|---|---|---|
| default | no tailnet exit-node; `--accept-routes` enabled | every-day SOCKS5/HTTP-CONNECT into the tailnet, *and* into the home LAN supernets advertised by `infra-exit` (10.0.0.0/24, 10.1.0.0/16, 10.120.22.0/24). Public internet uses the Mac's local egress. |
| `--exit-lan` | `tailscale set --exit-node=infra-exit --exit-node-allow-lan-access` | when you want this node's *non-tailnet* traffic to leave through the home WAN (e.g. the Mac is on hotel Wi-Fi and you want geo-locating to think you're home). Tailscale's built-in SOCKS5 doesn't fully reroute through exit nodes — for that case, set the exit node on the OS-level tailscale client instead. |
| `--exit-mullvad` | `tailscale set --exit-node=infra-mullvad` | when you want egress via Mullvad. Same exit-node-routing caveat applies to the built-in SOCKS5. |

## Configuring applications to use the proxy

**curl:**
```sh
curl --socks5 127.0.0.1:1055 https://grafana.lab.gn.al
```

**Browser (Firefox):** Settings → Network Settings → Manual proxy → SOCKS Host `127.0.0.1`, Port `1055`, SOCKS v5, enable "Proxy DNS when using SOCKS v5".

**macOS system proxy:** System Settings → Network → your interface → Proxies → SOCKS Proxy: `127.0.0.1:1055`.
