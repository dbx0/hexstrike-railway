# =============================================================================
# Stage 1: Go tools builder
# =============================================================================
FROM golang:1.23 AS go-builder

ENV CGO_ENABLED=0 GOFLAGS=-trimpath

RUN go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>&1 && \
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>&1 && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>&1 && \
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest 2>&1 && \
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest 2>&1 && \
    go install -v github.com/hahwul/dalfox/v2@latest 2>&1 && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest 2>&1 && \
    go install -v github.com/tomnomnom/waybackurls@latest 2>&1 && \
    go install -v github.com/hakluke/hakrawler@latest 2>&1 && \
    go install -v github.com/ffuf/ffuf/v2@latest 2>&1


# =============================================================================
# Stage 2: Rust tools builder
# =============================================================================
FROM rust:latest AS rust-builder

RUN cargo install feroxbuster --locked 2>&1
RUN cargo install rustscan --locked 2>&1
RUN cargo install x8 --locked 2>&1


# =============================================================================
# Stage 3: Binary downloads (trivy, kube-bench, terrascan)
# =============================================================================
FROM debian:bookworm-slim AS downloader

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates jq && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /downloads

# trivy
RUN TRIVY_VER=$(curl -sf https://api.github.com/repos/aquasecurity/trivy/releases/latest | jq -r .tag_name | sed 's/^v//') && \
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VER}/trivy_${TRIVY_VER}_Linux-64bit.tar.gz" \
    | tar xz -C /downloads trivy

# kube-bench
RUN curl -sL "$(curl -sf https://api.github.com/repos/aquasecurity/kube-bench/releases/latest \
    | jq -r '.assets[] | select(.name | test("kube-bench_.*_linux_amd64\\.tar\\.gz")) | .browser_download_url')" \
    | tar xz -C /downloads kube-bench

# terrascan
RUN curl -sL "$(curl -sf https://api.github.com/repos/tenable/terrascan/releases/latest \
    | jq -r '.assets[] | select(.name | test("terrascan_.*_Linux_x86_64\\.tar\\.gz")) | .browser_download_url')" \
    | tar xz -C /downloads terrascan

RUN chmod +x /downloads/*


# =============================================================================
# Stage 4: Final Kali image
# =============================================================================
FROM kalilinux/kali-rolling AS final

# Copy compiled/downloaded binaries
COPY --from=go-builder /go/bin/ /usr/local/bin/
COPY --from=rust-builder /usr/local/cargo/bin/feroxbuster \
                         /usr/local/cargo/bin/rustscan \
                         /usr/local/cargo/bin/x8 \
                         /usr/local/bin/
COPY --from=downloader /downloads/ /usr/local/bin/
RUN chmod +x /usr/local/bin/feroxbuster /usr/local/bin/rustscan /usr/local/bin/x8 \
             /usr/local/bin/trivy /usr/local/bin/kube-bench /usr/local/bin/terrascan

# System packages
RUN apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    kali-linux-headless \
    python3 python3-pip python3-venv python3-dev \
    git curl wget unzip tar \
    openjdk-17-jdk \
    ruby ruby-dev build-essential \
    chromium chromium-driver \
    nginx gettext-base \
    nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g supergateway

# Ruby gems
RUN gem install evil-winrm --no-document

# Clone hexstrike-ai
RUN git clone --depth=1 https://github.com/0x4m4/hexstrike-ai /opt/hexstrike-ai

# Python venv — core web/api deps
RUN python3 -m venv /opt/hexstrike-env && \
    /opt/hexstrike-env/bin/pip install --upgrade pip setuptools wheel && \
    /opt/hexstrike-env/bin/pip install --no-cache-dir \
        flask requests psutil \
        "fastmcp>=0.2.0,<1.0.0" \
        beautifulsoup4 \
        "selenium>=4.15.0,<5.0.0" \
        "webdriver-manager>=4.0.0,<5.0.0" \
        "aiohttp>=3.8.0,<4.0.0"

# Python venv — proxy/mitm
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
        "mitmproxy>=9.0.0,<11.0.0"

# Python venv — exploit dev (bcrypt pinned for pwntools compat)
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
        "bcrypt==4.0.1" \
        "pwntools>=4.10.0,<5.0.0"

# Python venv — binary analysis (angr is large, installed separately)
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
        "angr>=9.2.0,<10.0.0"

# Python venv — cloud/recon/web tooling
RUN /opt/hexstrike-env/bin/pip install --no-cache-dir \
        autorecon arjun paramspider \
        kube-hunter prowler scoutsuite checkov

# Download Ghidra
RUN GHIDRA_URL=$(curl -sf https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
        | grep '"browser_download_url"' | grep '\.zip"' | head -1 | sed 's/.*"\(https[^"]*\)".*/\1/') && \
    mkdir -p /opt/ghidra && \
    curl -sL "$GHIDRA_URL" -o /tmp/ghidra.zip && \
    unzip -q /tmp/ghidra.zip -d /opt/ghidra && \
    ln -sf /opt/ghidra/ghidra_*/ghidraRun /usr/local/bin/ghidra && \
    rm /tmp/ghidra.zip

# Copy project files
COPY start.sh /start.sh
COPY nginx.conf.template /etc/nginx/nginx.conf.template
RUN chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
