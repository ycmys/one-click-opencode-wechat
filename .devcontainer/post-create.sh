#!/usr/bin/env bash
set -euo pipefail

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

log "Installing OpenCode CLI"
curl -fsSL https://opencode.ai/install | bash

log "Installing weclaw"
curl -fsSL https://raw.githubusercontent.com/fastclaw-ai/weclaw/main/install.sh | sh

OPENCODE_BIN="${OPENCODE_BIN:-$HOME/.opencode/bin/opencode}"
if [ ! -x "$OPENCODE_BIN" ]; then
  OPENCODE_BIN="$(command -v opencode || true)"
fi
if [ -z "$OPENCODE_BIN" ]; then
  echo "OpenCode install failed: executable not found" >&2
  exit 1
fi

MODEL="${OPENCODE_MODEL:-opencode/minimax-m2.5-free}"

log "Writing ~/.weclaw/config.json (model=$MODEL)"
mkdir -p "$HOME/.weclaw/workspace"

cat > "$HOME/.weclaw/config.json" <<EOF
{
  "default_agent": "opencode",
  "agents": {
    "opencode": {
      "type": "acp",
      "command": "$OPENCODE_BIN",
      "args": ["acp"],
      "model": "$MODEL"
    }
  }
}
EOF

log "Done"
printf '  Start OpenCode: %s\n' "$OPENCODE_BIN"
printf '  Start bridge:   weclaw\n'
printf '  Change model:   OPENCODE_MODEL=<provider/model> bash .devcontainer/post-create.sh\n'
