# hexstrike-railway

Deploy [HexStrike AI MCP v6.0](https://github.com/0x4m4/hexstrike-ai) on [Railway](https://railway.com) — a full Kali Linux environment with 150+ security tools, served as a remote MCP server. Connect Claude Desktop, Cursor, or any MCP client directly to your Railway URL. No local setup required.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hexstrike-mcp?referralCode=Qs5clj&utm_medium=integration&utm_source=template&utm_campaign=generic)

---

## What's included

- **HexStrike AI v6.0** — Flask API server orchestrating 150+ security tools
- **Kali Linux rolling** — full `kali-linux-headless` metapackage
- **supergateway** — two listeners: **Streamable HTTP** at `/mcp` (Cursor’s default transport) and **SSE** at `/sse` + `/message` (e.g. Claude Desktop)
- **nginx reverse proxy** — Bearer token auth on the public endpoint
- **Go tools** — nuclei, subfinder, httpx, katana, naabu, dalfox, gau, ffuf, waybackurls, hakrawler
- **Rust tools** — feroxbuster, rustscan, x8
- **Binary tools** — trivy, kube-bench, terrascan
- **Ruby gems** — evil-winrm
- **Python tools** — pwntools, angr, mitmproxy, autorecon, arjun, prowler, scoutsuite, checkov, and more
- **Java tools** — Ghidra (latest release)

---

## Environment variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `AUTH_TOKEN` | **Yes** | Auto-generated | API key required on every request. |
| `PORT` | Auto | — | Set automatically by Railway. |
| `HEXSTRIKE_PORT` | No | `8888` | Internal port for the hexstrike Flask server. |
| `MCP_STREAM_PORT` | No | `9000` | Internal port for supergateway (Streamable HTTP → stdio). |
| `MCP_SSE_PORT` | No | `9001` | Internal port for supergateway (SSE → stdio). |
| `MCP_PUBLIC_BASE_URL` | No | *(unset)* | Public origin for SSE clients, e.g. `https://YOUR_SERVICE.up.railway.app`. Set only if Claude (SSE) cannot POST to `/message` behind your hostname. |

`AUTH_TOKEN` is automatically generated on deploy. Find it in the Railway **Variables** tab.

---

## Connecting your MCP client

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (Linux: `~/.config/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "hexstrike": {
      "url": "https://YOUR_RAILWAY_URL/sse",
      "headers": {
        "Authorization": "Bearer YOUR_AUTH_TOKEN"
      }
    }
  }
}
```

### Cursor / VS Code (Streamable HTTP)

Cursor defaults to the **Streamable HTTP** MCP transport. Use the `/mcp` path (not `/sse`):

```
URL:    https://YOUR_RAILWAY_URL/mcp
Header: Authorization: Bearer YOUR_AUTH_TOKEN
```

In Cursor’s MCP UI, pick **Streamable HTTP** if the transport is selectable. If you force **SSE** instead, use `https://YOUR_RAILWAY_URL/sse` and the same `Authorization` header (only one active SSE session is reliable with supergateway’s stdio bridge).

### Roo Code / other SSE-only clients

Use the SSE URL and the same bearer header:

```
URL:    https://YOUR_RAILWAY_URL/sse
Header: Authorization: Bearer YOUR_AUTH_TOKEN
```

No local processes or extra tools are required on your machine.

---

## Architecture

```
Claude Desktop / Cursor / VS Code
         ↓  HTTPS  (Authorization: Bearer token)
nginx  ($PORT)  — validates token; routes /mcp vs /sse + /message
         ↓  HTTP (localhost)
supergateway  (:9000 Streamable HTTP, :9001 SSE)  — HTTP/SSE ↔ stdio
         ↓  stdio
hexstrike_mcp.py  (upstream, unmodified)
         ↓  HTTP (localhost)
hexstrike_server.py  (:8888)
         ↓  subprocess
150+ Kali tools
```

---

## Security

> **For authorized security testing only.** Only use against systems you own or have explicit written permission to test.

`AUTH_TOKEN` is auto-generated on deploy and required on every request. The hexstrike API is never directly exposed — all traffic goes through nginx.

---

## Credits

- [HexStrike AI](https://github.com/0x4m4/hexstrike-ai) by 0x4m4
- [supergateway](https://github.com/supercorp-ai/supergateway) — stdio MCP → SSE / Streamable HTTP bridge
- [Kali Linux](https://www.kali.org) by Offensive Security
