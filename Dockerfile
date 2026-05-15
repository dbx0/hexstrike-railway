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

# Go tools — pre-built binaries (avoids Go compiler under QEMU)
RUN \
    DALFOX=$(curl -sf https://api.github.com/repos/hahwul/dalfox/releases/latest \
        | jq -r '.assets[] | select(.name | test("dalfox_linux_amd64\\.tar\\.gz")) | .browser_download_url') && \
    curl -sL "$DALFOX" | tar xz -C /usr/local/bin dalfox && \
    \
    KATANA=$(curl -sf https://api.github.com/repos/projectdiscovery/katana/releases/latest \
        | jq -r '.assets[] | select(.name | test("katana_.*_linux_amd64\\.zip")) | .browser_download_url') && \
    curl -sL "$KATANA" -o /tmp/katana.zip && unzip -qo /tmp/katana.zip katana -d /usr/local/bin && rm /tmp/katana.zip && \
    \
    GAU=$(curl -sf https://api.github.com/repos/lc/gau/releases/latest \
        | jq -r '.assets[] | select(.name | test("gau_.*_linux_amd64\\.tar\\.gz")) | .browser_download_url') && \
    curl -sL "$GAU" | tar xz -C /usr/local/bin gau && \
    \
    HAKRAWLER=$(curl -sf https://api.github.com/repos/hakluke/hakrawler/releases/latest \
        | jq -r '.assets[] | select(.name | test("hakrawler_linux_amd64\\.zip")) | .browser_download_url') && \
    curl -sL "$HAKRAWLER" -o /tmp/hakrawler.zip && unzip -qo /tmp/hakrawler.zip -d /usr/local/bin && rm /tmp/hakrawler.zip && \
    \
    chmod +x /usr/local/bin/dalfox /usr/local/bin/katana /usr/local/bin/gau /usr/local/bin/hakrawler

# RustScan — distributed as .deb via GitHub releases
RUN DEB_URL=$(curl -sf https://api.github.com/repos/RustScan/RustScan/releases/latest \
    | jq -r '.assets[] | select(.name | test("rustscan.*amd64\\.deb")) | .browser_download_url') && \
    curl -sL "$DEB_URL" -o /tmp/rustscan.deb && \
    dpkg -i /tmp/rustscan.deb && \
    rm /tmp/rustscan.deb

# Binary tools not in apt
RUN TRIVY_VER=$(curl -sf https://api.github.com/repos/aquasecurity/trivy/releases/latest | jq -r .tag_name | sed 's/^v//') && \
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VER}/trivy_${TRIVY_VER}_Linux-64bit.tar.gz" \
    | tar xz -C /usr/local/bin trivy

RUN curl -sL "$(curl -sf https://api.github.com/repos/aquasecurity/kube-bench/releases/latest \
    | jq -r '.assets[] | select(.name | test("kube-bench_.*_linux_amd64\\.tar\\.gz")) | .browser_download_url')" \
    | tar xz -C /usr/local/bin kube-bench

RUN curl -sL "$(curl -sf https://api.github.com/repos/tenable/terrascan/releases/latest \
    | jq -r '.assets[] | select(.name | test("terrascan_.*_Linux_x86_64\\.tar\\.gz")) | .browser_download_url')" \
    | tar xz -C /usr/local/bin terrascan

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

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "mitmproxy>=9.0.0,<11.0.0"

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "bcrypt==4.0.1" "pwntools>=4.10.0,<5.0.0"

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "angr>=9.2.0,<10.0.0"

RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
        autorecon arjun paramspider \
        kube-hunter prowler scoutsuite checkov \
        volatility3 netexec theHarvester

# Ghidra
RUN GHIDRA_URL=$(curl -sf https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
        | grep '"browser_download_url"' | grep '\.zip"' | head -1 | sed 's/.*"\(https[^"]*\)".*/\1/') && \
    mkdir -p /opt/ghidra && \
    curl -sL "$GHIDRA_URL" -o /tmp/ghidra.zip && \
    unzip -q /tmp/ghidra.zip -d /opt/ghidra && \
    ln -sf /opt/ghidra/ghidra_*/ghidraRun /usr/local/bin/ghidra && \
    rm /tmp/ghidra.zip

COPY start.sh /start.sh
COPY nginx.conf.template /etc/nginx/nginx.conf.template
RUN chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
