FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV GOPATH=/opt/go
ENV PATH="/opt/go/bin:${PATH}"

# System packages — kali tools + all build/runtime deps in one layer
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    kali-linux-headless \
    feroxbuster rustscan \
    nuclei subfinder httpx-toolkit katana naabu \
    python3 python3-pip python3-venv python3-dev \
    golang \
    default-jdk \
    ruby ruby-dev build-essential \
    chromium chromium-driver \
    nginx gettext-base \
    nodejs npm \
    git curl wget unzip tar jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ruby gems
RUN gem install evil-winrm --no-document

# Go tools not in Kali apt
RUN go install github.com/hahwul/dalfox/v2@latest && \
    go install github.com/lc/gau/v2/cmd/gau@latest && \
    go install github.com/tomnomnom/waybackurls@latest && \
    go install github.com/hakluke/hakrawler@latest

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
        kube-hunter prowler scoutsuite checkov

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
