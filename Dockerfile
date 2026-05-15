FROM --platform=linux/amd64 kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
# Expose venv tools to PATH so hexstrike's `which` checks find them
ENV PATH="/opt/hexstrike-env/bin:/usr/local/bin:$PATH"

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
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && chmod u-s /usr/lib/nmap/nmap 2>/dev/null || true \
    && setcap -r /usr/lib/nmap/nmap 2>/dev/null || true \
    && printf '#!/bin/sh\nexec /usr/lib/nmap/nmap --unprivileged "$@"\n' > /usr/bin/nmap \
    && chmod +x /usr/bin/nmap \
    && ln -sf /usr/bin/httpx-toolkit /usr/local/bin/httpx

# Additional Kali tools not in the main layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Network / AD
    netexec enum4linux \
    # Web security
    dotdotpwn xsser wafw00f \
    # Password
    patator hash-identifier \
    # Forensics
    scalpel bulk-extractor sleuthkit \
    # OSINT
    recon-ng \
    # API / utility
    httpie \
    # Port scanner
    rustscan \
    # Exploit DB / searchsploit
    exploitdb \
    # Hex editor
    xxd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ruby gems — evil-winrm, wpscan, one_gadget (binary exploit helper), zsteg (steg)
RUN gem install evil-winrm wpscan one_gadget zsteg --no-document || true

# Go / Rust tools — pre-built binaries
# Use curl redirect trick to resolve latest version without hitting GitHub API rate limits.
# Each download is non-fatal (|| true) so one missing binary never breaks the build.

RUN URL=$(curl -sf https://api.github.com/repos/hahwul/dalfox/releases/latest \
        | grep '"browser_download_url"' | grep 'linux_amd64.tar.gz' | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/') && \
    [ -n "$URL" ] && curl -sL "$URL" | tar xz -C /usr/local/bin dalfox && chmod +x /usr/local/bin/dalfox \
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

RUN URL=$(curl -sf https://api.github.com/repos/hakluke/hakrawler/releases/latest \
        | grep '"browser_download_url"' | grep 'linux_amd64' | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/') && \
    [ -n "$URL" ] && \
    curl -sL "$URL" -o /tmp/hakrawler.zip && \
    unzip -qo /tmp/hakrawler.zip -d /tmp/hakrawler-bin && \
    find /tmp/hakrawler-bin -name 'hakrawler' -exec mv {} /usr/local/bin/hakrawler \; && \
    rm -rf /tmp/hakrawler.zip /tmp/hakrawler-bin && chmod +x /usr/local/bin/hakrawler \
    || echo "WARNING: hakrawler not installed"

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

# tomnomnom Go tools — waybackurls, anew, qsreplace
RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/tomnomnom/waybackurls/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/tomnomnom/waybackurls/releases/download/v${VER}/waybackurls-linux-amd64-${VER}.tgz" \
        | tar xz -C /usr/local/bin waybackurls && chmod +x /usr/local/bin/waybackurls \
    || echo "WARNING: waybackurls not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/tomnomnom/anew/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/tomnomnom/anew/releases/download/v${VER}/anew-linux-amd64-${VER}.tgz" \
        | tar xz -C /usr/local/bin anew && chmod +x /usr/local/bin/anew \
    || echo "WARNING: anew not installed"

RUN VER=$(curl -sfL -o /dev/null -w "%{url_effective}" \
        https://github.com/tomnomnom/qsreplace/releases/latest | sed 's|.*/tag/||; s/^v//') && \
    curl -sL "https://github.com/tomnomnom/qsreplace/releases/download/v${VER}/qsreplace-linux-amd64-${VER}.tgz" \
        | tar xz -C /usr/local/bin qsreplace && chmod +x /usr/local/bin/qsreplace \
    || echo "WARNING: qsreplace not installed"

RUN URL=$(curl -sf https://api.github.com/repos/Sh1yo/x8/releases/latest \
        | grep '"browser_download_url"' | grep 'linux_x86_64' | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/') && \
    [ -n "$URL" ] && curl -sL "$URL" | tar xz -C /usr/local/bin x8 && chmod +x /usr/local/bin/x8 \
    || echo "WARNING: x8 not installed"

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

# Additional pip security tools
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
    ROPgadget ropper \
    shodan censys \
    uro \
    sherlock-project \
    || echo "WARNING: some pip security tools not installed"

# paramspider — not on PyPI, install from GitHub
RUN git clone --depth=1 https://github.com/0xKayala/ParamSpider /opt/paramspider && \
    /opt/hexstrike-env/bin/pip install --no-cache-dir -e /opt/paramspider \
    || echo "WARNING: paramspider not installed"

# Symlinks so hexstrike's `which` checks match installed binary names
RUN ln -sf /opt/hexstrike-env/bin/vol       /usr/local/bin/vol          2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/vol       /usr/local/bin/volatility3  2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/ROPgadget /usr/local/bin/ropgadget    2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/pwn       /usr/local/bin/pwntools     2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/sherlock  /usr/local/bin/sherlock     2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/checkov   /usr/local/bin/checkov      2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/prowler   /usr/local/bin/prowler      2>/dev/null || true && \
    ln -sf /opt/hexstrike-env/bin/scout-suite /usr/local/bin/scout-suite 2>/dev/null || true && \
    ln -sf /usr/bin/netexec                 /usr/local/bin/nxc          2>/dev/null || true && \
    ln -sf /usr/bin/msfvenom                /usr/local/bin/msfvenom     2>/dev/null || true && \
    ln -sf /usr/local/bin/one_gadget        /usr/local/bin/one-gadget   2>/dev/null || true && \
    ln -sf /usr/bin/theHarvester            /usr/local/bin/theharvester 2>/dev/null || true

# Re-pin pydantic v2 last — kube-hunter/scoutsuite may downgrade it to v1,
# which breaks fastmcp (TypeAdapter was added in pydantic v2).
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "pydantic>=2.0.0,<3.0.0"

# Re-pin urllib3 v2 last — some packages (e.g. kube-hunter) downgrade to 1.x,
# which removes urllib3.BaseHTTPResponse that selenium 4.x requires.
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir "urllib3>=2.0.0,<3.0.0"

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
