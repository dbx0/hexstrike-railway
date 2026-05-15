#!/bin/bash
set -euo pipefail

PORT="${PORT:-8080}"
HEXSTRIKE_PORT="${HEXSTRIKE_PORT:-8888}"
# Streamable HTTP (Cursor and other MCP clients that use the Streamable HTTP transport)
MCP_STREAM_PORT="${MCP_STREAM_PORT:-9000}"
# Legacy SSE (e.g. Claude Desktop) — separate process so it does not share one MCP Server
# instance across sessions (supergateway stdio→SSE uses a single Server for all SSE tabs).
MCP_SSE_PORT="${MCP_SSE_PORT:-9001}"

export PORT HEXSTRIKE_PORT MCP_STREAM_PORT MCP_SSE_PORT

if [ -z "${AUTH_TOKEN:-}" ]; then
    echo "ERROR: AUTH_TOKEN environment variable is required but not set." >&2
    exit 1
fi

wait_tcp_port() {
    local p="$1" label="$2"
    for i in $(seq 1 60); do
        if nc -z 127.0.0.1 "$p" 2>/dev/null; then
            echo "[hexstrike] ${label} accepting connections on ${p} (${i}s)."
            return 0
        fi
        sleep 1
    done
    echo "[hexstrike] ERROR: ${label} did not open TCP port ${p} within 60s." >&2
    return 1
}

MCP_STDIO_CMD="/opt/hexstrike-env/bin/python3 /opt/hexstrike-ai/hexstrike_mcp.py --server http://localhost:${HEXSTRIKE_PORT}"

echo "[hexstrike] Starting hexstrike_server.py on port ${HEXSTRIKE_PORT}..."
cd /opt/hexstrike-ai
/opt/hexstrike-env/bin/python3 hexstrike_server.py --port "$HEXSTRIKE_PORT" \
    2>&1 | sed 's/^/[hexstrike-server] /' &
SERVER_PID=$!

echo "[hexstrike] Waiting for API server /health (up to 180s)..."
API_READY=0
for i in $(seq 1 180); do
    if curl -sf "http://localhost:${HEXSTRIKE_PORT}/health" > /dev/null 2>&1; then
        echo "[hexstrike] API server ready (${i}s)."
        API_READY=1
        break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[hexstrike] ERROR: hexstrike_server.py exited before /health responded (PID ${SERVER_PID})." >&2
        exit 1
    fi
    sleep 1
done
if [ "$API_READY" -ne 1 ]; then
    echo "[hexstrike] ERROR: API server did not become healthy within 180s. Not starting MCP gateways." >&2
    exit 1
fi

echo "[hexstrike] Starting supergateway (MCP Streamable HTTP) on port ${MCP_STREAM_PORT}..."
supergateway \
    --port "$MCP_STREAM_PORT" \
    --stdio "$MCP_STDIO_CMD" \
    --outputTransport streamableHttp \
    --stateful \
    --streamableHttpPath /mcp \
    2>&1 | sed 's/^/[supergateway-stream] /' &

if ! wait_tcp_port "$MCP_STREAM_PORT" "supergateway (streamable)"; then
    exit 1
fi

echo "[hexstrike] Starting supergateway (MCP SSE) on port ${MCP_SSE_PORT}..."
SSE_GW_ARGS=(
    supergateway
    --port "$MCP_SSE_PORT"
    --stdio "$MCP_STDIO_CMD"
    --outputTransport sse
    --ssePath /sse
    --messagePath /message
)
if [ -n "${MCP_PUBLIC_BASE_URL:-}" ]; then
    SSE_GW_ARGS+=(--baseUrl "${MCP_PUBLIC_BASE_URL}")
fi
"${SSE_GW_ARGS[@]}" 2>&1 | sed 's/^/[supergateway-sse] /' &

if ! wait_tcp_port "$MCP_SSE_PORT" "supergateway (sse)"; then
    exit 1
fi

echo "[hexstrike] Starting nginx on port ${PORT}..."
envsubst '${PORT} ${AUTH_TOKEN} ${MCP_STREAM_PORT} ${MCP_SSE_PORT}' \
    < /etc/nginx/nginx.conf.template \
    > /tmp/nginx.conf

exec nginx -c /tmp/nginx.conf -g 'daemon off;'
