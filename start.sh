#!/bin/sh
set -e

# OpenShell assigns the UID at runtime — HOME may not be set or may point
# to a non-existent directory. Force it to /sandbox which OpenShell chowns
# to the runtime UID before the process starts.
export HOME=/sandbox

TOKEN_FILE=/tmp/codex-ws-token

# Write WebSocket capability token (for Codex CLI: codex --remote ws://localhost:8888)
if [ -n "$CODEX_WS_TOKEN" ]; then
    printf '%s' "$CODEX_WS_TOKEN" > "$TOKEN_FILE"
else
    head -c 32 /dev/urandom | base64 | tr -d '\n' > "$TOKEN_FILE"
fi
echo "App Server token: $(cat $TOKEN_FILE)"

# Codex reads OPENAI_API_KEY or CODEX_ACCESS_TOKEN from env before auth.json.
# OpenShell injects these via the codex provider as openshell:resolve:env:
# placeholders — real credential stays in the gateway, proxy resolves on wire.
echo "Auth: CODEX_ACCESS_TOKEN set=$([ -n "$CODEX_ACCESS_TOKEN" ] && echo yes || echo no)"
echo "Auth: OPENAI_API_KEY set=$([ -n "$OPENAI_API_KEY" ] && echo yes || echo no)"

# App Server for Codex CLI (WebSocket transport).
# Codex Desktop uses a separate path: openshell ssh-proxy → gateway exec →
# codex-ssh-shell login shell → App Server on stdio. No sshd needed.
exec codex app-server \
    --listen ws://0.0.0.0:8888 \
    --ws-auth capability-token \
    --ws-token-file "$TOKEN_FILE"
