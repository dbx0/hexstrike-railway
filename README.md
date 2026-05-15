# hexstrike-railway

Deploy [HexStrike AI MCP v6.0](https://github.com/0x4m4/hexstrike-ai) on [Railway](https://railway.com) — a full Kali Linux environment with 150+ security tools, served as a remote MCP server. Connect Claude Desktop, Cursor, or any MCP client directly to your Railway URL. No local setup required.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hexstrike-mcp?referralCode=Qs5clj&utm_medium=integration&utm_source=template&utm_campaign=generic)

---

## What’s included

- **HexStrike AI v6.0** — Flask API server orchestrating 150+ security tools
- **Kali Linux rolling** — full Kali apt toolset
- **supergateway** — two listeners: **Streamable HTTP** at `/mcp` (Cursor’s default transport) and **SSE** at `/sse` + `/message` (e.g. Claude Desktop)
- **nginx reverse proxy** — Bearer token auth on the public endpoint

---

## Tools

### Network & Recon
| Tool | Source | Description |
|------|--------|-------------|
| nmap | apt | Network scanner (unprivileged mode) |
| masscan | apt | High-speed port scanner |
| rustscan | apt | Fast port scanner |
| naabu | apt | Port scanner by ProjectDiscovery |
| dnsrecon | apt | DNS enumeration |
| dnsenum | apt | DNS brute-force |
| fierce | apt | DNS recon |
| amass | apt | Subdomain enumeration |
| subfinder | apt | Subdomain discovery |
| netcat | apt | TCP/UDP utility |
| net-tools | apt | ifconfig, netstat, etc. |
| arp-scan | apt | ARP host discovery |
| nbtscan | apt | NetBIOS scanner |
| whois | apt | WHOIS lookup |

### Web Security
| Tool | Source | Description |
|------|--------|-------------|
| gobuster | apt | Directory/DNS brute-forcer |
| dirb | apt | Web directory scanner |
| dirsearch | apt | Web path scanner |
| ffuf | apt | Fast web fuzzer |
| wfuzz | apt | Web fuzzer |
| nikto | apt | Web server vulnerability scanner |
| sqlmap | apt | SQL injection automation |
| whatweb | apt | Web fingerprinting |
| httpx | apt (httpx-toolkit) | HTTP probing toolkit |
| nuclei | apt | Template-based vuln scanner |
| feroxbuster | apt | Fast content discovery |
| katana | GitHub binary | Web crawler |
| hakrawler | GitHub binary | Web crawler |
| gau | GitHub binary | Fetch known URLs from AlienVault, Wayback |
| waybackurls | GitHub binary | Fetch URLs from Wayback Machine |
| dalfox | GitHub binary | XSS scanner |
| wafw00f | apt | WAF detection |
| dotdotpwn | apt | Path traversal fuzzer |
| xsser | apt | XSS scanner |
| x8 | GitHub binary | HTTP parameter discovery |
| anew | GitHub binary | Append new lines to files |
| qsreplace | GitHub binary | Replace query string values |
| uro | pip | URL deduplication |
| arjun | pip | HTTP parameter discovery |
| paramspider | git | Parameter extraction from URLs |

### Vulnerability Scanning
| Tool | Source | Description |
|------|--------|-------------|
| trivy | GitHub binary | Container/filesystem vuln scanner |
| nikto | apt | Web server scanner |
| autorecon | pip | Multi-threaded enumeration |

### Password Attacks
| Tool | Source | Description |
|------|--------|-------------|
| hydra | apt | Online password cracker |
| john | apt | John the Ripper password cracker |
| hashcat | apt | GPU-accelerated password cracker |
| medusa | apt | Parallel login brute-forcer |
| patator | apt | Multi-purpose brute-forcer |
| hash-identifier | apt | Hash type identifier |

### Exploitation & Post-Exploitation
| Tool | Source | Description |
|------|--------|-------------|
| metasploit-framework | apt | Exploitation framework (msfconsole, msfvenom) |
| impacket | apt | Python SMB/AD attack suite |
| responder | apt | LLMNR/NBT-NS/mDNS poisoner |
| evil-winrm | gem | WinRM shell for pentesting |

### SMB / Active Directory
| Tool | Source | Description |
|------|--------|-------------|
| netexec (nxc) | apt | Swiss-army knife for network services |
| enum4linux-ng | apt | SMB/Samba enumeration |
| enum4linux | apt | SMB enumeration (legacy) |
| smbmap | apt | SMB share mapper |
| smbclient | apt | SMB client |

### Binary Analysis & Reverse Engineering
| Tool | Source | Description |
|------|--------|-------------|
| radare2 | apt | Reverse engineering framework |
| gdb | apt | GNU debugger |
| ltrace | apt | Library call tracer |
| strace | apt | System call tracer |
| binwalk | apt | Firmware analysis |
| checksec | apt | Binary security checker |
| ghidra | GitHub binary | NSA reverse engineering suite |
| angr | pip | Binary analysis framework |
| pwntools | pip | CTF exploit development |
| ROPgadget (ropgadget) | pip | ROP gadget finder |
| ropper | pip | ROP chain builder |
| one_gadget (one-gadget) | gem | One-gadget RCE finder |
| xxd | apt | Hex editor/viewer |

### Forensics & Steganography
| Tool | Source | Description |
|------|--------|-------------|
| steghide | apt | Steganography tool |
| exiftool | apt | Metadata reader/writer |
| foremost | apt | File carver |
| testdisk | apt | Partition recovery |
| scalpel | apt | File carver |
| bulk-extractor | apt | Forensic feature extractor |
| sleuthkit (mmls) | apt | Disk forensics toolkit |
| volatility3 (vol) | pip | Memory forensics |
| zsteg | gem | PNG/BMP steganography detector |

### Cloud Security
| Tool | Source | Description |
|------|--------|-------------|
| trivy | GitHub binary | Cloud/container scanner |
| kube-bench | GitHub binary | Kubernetes CIS benchmark |
| terrascan | GitHub binary | IaC security scanner |
| checkov | pip | IaC static analysis |
| kube-hunter | pip | Kubernetes penetration testing |
| prowler | pip | AWS/Azure/GCP security auditor |
| scoutsuite | pip | Multi-cloud security auditing |

### OSINT
| Tool | Source | Description |
|------|--------|-------------|
| recon-ng | apt | Web reconnaissance framework |
| theHarvester (theharvester) | pip | Email/domain/host harvester |
| shodan | pip | Shodan API client |
| censys | pip | Censys API client |
| sherlock | pip | Username hunt across social networks |

### Network Analysis
| Tool | Source | Description |
|------|--------|-------------|
| tshark | apt | Command-line Wireshark |
| tcpdump | apt | Packet capture |
| mitmproxy | pip | Interactive HTTPS proxy |

### Wireless
| Tool | Source | Description |
|------|--------|-------------|
| aircrack-ng | apt | Wireless auditing suite |

### Web Proxy & API
| Tool | Source | Description |
|------|--------|-------------|
| mitmproxy | pip | Interactive HTTPS proxy |
| httpie | apt | User-friendly HTTP client |

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
