FROM --platform=linux/amd64 kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# System packages — kali tools + all build/runtime deps in one layer
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    # Network & recon
    nmap masscan dnsrecon dnsenum fierce amass \
    netcat-openbsd net-tools arp-scan nbtscan whois \
    # Web
    gobuster dirb dirsearch nikto sqlmap wfuzz ffuf whatweb \
    nuclei subfinder httpx-toolkit naabu feroxbuster \
    # Exploitation & post-exploitation
    metasploit-framework impacket-scripts responder \
    # SMB / AD
    enum4linux-ng smbmap smbclient \
    # Password attacks
    hydra john hashcat medusa \
    # Binary & reverse engineering
    radare2 binwalk gdb ltrace strace checksec \
    # Forensics & steganography
    steghide exiftool foremost testdisk \
    # Network analysis
    tshark tcpdump \
    # Wireless
    aircrack-ng \
    # Runtime & build deps
    python3 python3-pip python3-venv python3-dev \
    default-jdk \
    ruby ruby-dev build-essential \
    chromium chromium-driver \
    nginx gettext-base \
    nodejs npm \
    git curl wget unzip tar jq \
    ; dpkg --configure -a --force-all 2>/dev/null || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ruby gems
RUN gem install evil-winrm --no-document

# Go / Rust tools — pre-built binaries
# Use curl redirect trick to resolve latest version without hitting GitHub API rate limits.
# Each download is non-fatal (|| true) so one missing binary never breaks the build.

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/hahwul/dalfox/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/hahwul/dalfox/releases/download/v${VER}/dalfox_${VER}_linux_amd64.tar.gz" \
        | tar xz -C /usr/local/bin dalfox && chmod +x /usr/local/bin/dalfox \
    || echo "WARNING: dalfox not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/projectdiscovery/katana/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/projectdiscovery/katana/releases/download/v${VER}/katana_${VER}_linux_amd64.zip" \
        -o /tmp/katana.zip && \
    unzip -qo /tmp/katana.zip -d /tmp/katana-bin && \
    find /tmp/katana-bin -name 'katana' -exec mv {} /usr/local/bin/katana \; && \
    rm -rf /tmp/katana.zip /tmp/katana-bin && chmod +x /usr/local/bin/katana \
    || echo "WARNING: katana not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/lc/gau/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/lc/gau/releases/download/v${VER}/gau_${VER}_linux_amd64.tar.gz" \
        | tar xz -C /usr/local/bin gau && chmod +x /usr/local/bin/gau \
    || echo "WARNING: gau not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/hakluke/hakrawler/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/hakluke/hakrawler/releases/download/v${VER}/hakrawler_${VER}_linux_amd64.zip" \
        -o /tmp/hakrawler.zip && \
    unzip -qo /tmp/hakrawler.zip -d /tmp/hakrawler-bin && \
    find /tmp/hakrawler-bin -name 'hakrawler' -exec mv {} /usr/local/bin/hakrawler \; && \
    rm -rf /tmp/hakrawler.zip /tmp/hakrawler-bin && chmod +x /usr/local/bin/hakrawler \
    || echo "WARNING: hakrawler not installed"

# RustScan — distributed as .deb via GitHub releases
RUN VTAG=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/RustScan/RustScan/releases/latest | sed 's|.*/tag/||') && \
    VER=$(echo "$VTAG" | sed 's/^v//') && \
    curl -sL "https://github.com/RustScan/RustScan/releases/download/${VTAG}/rustscan_${VER}_amd64.deb" \
        -o /tmp/rustscan.deb && \
    dpkg -i /tmp/rustscan.deb && rm /tmp/rustscan.deb \
    || echo "WARNING: rustscan not installed"

# Binary tools not in apt
RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/aquasecurity/trivy/releases/latest | sed 's|.*/tag/v||') && \
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${VER}/trivy_${VER}_Linux-64bit.tar.gz" \
        | tar xz -C /usr/local/bin trivy \
    || echo "WARNING: trivy not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/aquasecurity/kube-bench/releases/latest | sed 's|.*/tag/v||') && \
    curl -sL "https://github.com/aquasecurity/kube-bench/releases/download/v${VER}/kube-bench_${VER}_linux_amd64.tar.gz" \
        | tar xz -C /usr/local/bin kube-bench \
    || echo "WARNING: kube-bench not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/tenable/terrascan/releases/latest | sed 's|.*/tag/v||') && \
    curl -sL "https://github.com/tenable/terrascan/releases/download/v${VER}/terrascan_${VER}_Linux_x86_64.tar.gz" \
        | tar xz -C /usr/local/bin terrascan \
    || echo "WARNING: terrascan not installed"

# Node.js MCP SSE bridge
RUN npm install -g supergateway

# Clone hexstrike-ai
RUN git clone --depth=1 https://github.com/0x4m4/hexstrike-ai /opt/hexstrike-ai

# Python venv — split into layers to isolate heavy installs
RUN python3 -m venv /opt/hexstrike-env && \
    /opt/hexstrike-env/bin/pip install --upgrade pip setuptools wheel && \
    /opt/hexstrike-env/bin/pip install --no-cache-dir \
        flask requests psutil \
        "fastmcp>=0.2.0,<1.0.0" \
        beautifulsoup4 \
        "selenium>=4.15.0,<5.0.0" \
        "webdriver-manager>=4.0.0,<5.0.0" \
        "aiohttp>=3.8.0,<4.0.0"

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "bcrypt==4.0.1" "pwntools>=4.10.0,<5.0.0"

# angr installs first so its protobuf version wins; mitmproxy is installed last and
# its protobuf pin is relaxed to avoid blocking the install of either package.
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "angr>=9.2.0,<10.0.0" \
    || echo "WARNING: angr not installed (mulpyplexer QEMU crash on arm64 host is expected; Railway amd64 build will succeed)"

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "mitmproxy>=9.0.0,<11.0.0" \
        --ignore-installed protobuf || echo "WARNING: mitmproxy not installed"

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
        autorecon arjun \
        kube-hunter prowler scoutsuite checkov \
        volatility3 theHarvester \
    || echo "WARNING: some security Python tools not installed"

# Re-pin pydantic v2 last — kube-hunter/scoutsuite may downgrade it to v1,
# which breaks fastmcp (TypeAdapter was added in pydantic v2).
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "pydantic>=2.0.0,<3.0.0"

# Ghidra — release filename includes a build date, so we need the GitHub API URL
RUN GHIDRA_URL=$(curl -sf https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
        | grep '"browser_download_url"' | grep '\.zip"' | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/') && \
    [ -n "$GHIDRA_URL" ] && \
    mkdir -p /opt/ghidra && \
    curl -sL "$GHIDRA_URL" -o /tmp/ghidra.zip && \
    unzip -q /tmp/ghidra.zip -d /opt/ghidra && \
    ln -sf /opt/ghidra/ghidra_*/ghidraRun /usr/local/bin/ghidra && \
    rm /tmp/ghidra.zip \
    || echo "WARNING: Ghidra not installed (API may be unavailable at build time)"

COPY start.sh /start.sh
COPY nginx.conf.template /etc/nginx/nginx.conf.template
RUN chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
