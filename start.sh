#!/bin/bash
set -euo pipefail

HEXSTRIKE_PORT="${HEXSTRIKE_PORT:-8888}"
export HEXSTRIKE_PORT
export MCP_PORT=9000

if [ -z "${AUTH_TOKEN:-}" ]; then
    echo "ERROR: AUTH_TOKEN environment variable is required but not set." >&2
    exit 1
fi

echo "[hexstrike] Starting hexstrike_server.py on port ${HEXSTRIKE_PORT}..."
cd /opt/hexstrike-ai
/opt/hexstrike-env/bin/python3 hexstrike_server.py --port "$HEXSTRIKE_PORT" &

echo "[hexstrike] Waiting for API server to be ready..."
for i in $(seq 1 60); do
    if curl -sf "http://localhost:${HEXSTRIKE_PORT}/health" > /dev/null 2>&1; then
        echo "[hexstrike] API server ready (${i}s)."
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "[hexstrike] WARNING: API server did not respond in 60s, starting anyway." >&2
    fi
    sleep 1
done

echo "[hexstrike] Starting supergateway (MCP SSE) on port ${MCP_PORT}..."
supergateway \
    --port "$MCP_PORT" \
    --stdio "/opt/hexstrike-env/bin/python3 /opt/hexstrike-ai/hexstrike_mcp.py --server http://localhost:${HEXSTRIKE_PORT}" &

echo "[hexstrike] Starting nginx on port ${PORT:-8080}..."
envsubst '${PORT} ${AUTH_TOKEN} ${HEXSTRIKE_PORT} ${MCP_PORT}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
