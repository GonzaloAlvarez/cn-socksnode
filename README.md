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
docker compose up -d
docker compose logs -f tailnet-proxy   # opens a browser URL to authenticate via OIDC
```

Verify the tailscale0 interface was created (kernel mode is required for DNS to work):

```sh
docker exec cn-socksnode-tailnet-proxy-1 ip addr show tailscale0
```

## Configuring applications to use the proxy

**curl:**
```sh
curl --socks5 127.0.0.1:1055 https://grafana.lab.gn.al
```

**Browser (Firefox):** Settings → Network Settings → Manual proxy → SOCKS Host `127.0.0.1`, Port `1055`, SOCKS v5, enable "Proxy DNS when using SOCKS v5".

**macOS system proxy:** System Settings → Network → your interface → Proxies → SOCKS Proxy: `127.0.0.1:1055`.
