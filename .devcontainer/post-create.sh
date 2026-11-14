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

OPENCODE_CONFIG="$HOME/.config/opencode/opencode.jsonc"
if [ -f "$OPENCODE_CONFIG" ]; then
  log "Keeping existing $OPENCODE_CONFIG"
else
  log "Writing $OPENCODE_CONFIG (auto-approve tools)"
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  cat > "$OPENCODE_CONFIG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "edit": "allow",
    "bash": "allow",
    "task": "allow",
    "skill": "allow",
    "webfetch": "allow",
    "websearch": "allow",
    "todowrite": "allow",
    "external_directory": "allow"
  }
}
EOF
fi

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

log "Installing weclaw keepalive (watchdog + shell autostart)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install -m 0755 "$REPO_DIR/.devcontainer/weclaw-watchdog.sh" "$HOME/.weclaw/watchdog.sh"
install -m 0755 "$REPO_DIR/.devcontainer/weclaw-autostart.sh" "$HOME/.weclaw/autostart.sh"
if ! grep -q 'weclaw keepalive' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'BASHRC'

# weclaw keepalive: auto-start bridge/watchdog on shell start
if [ "${CODESPACES:-}" = "true" ] && [ -x "$HOME/.weclaw/autostart.sh" ]; then
  "$HOME/.weclaw/autostart.sh" >/dev/null 2>&1 || true
fi
BASHRC
fi
"$HOME/.weclaw/autostart.sh" >/dev/null 2>&1 || true

log "Done"
printf '  Start OpenCode: %s\n' "$OPENCODE_BIN"
printf '  Start bridge:   weclaw (kept alive by ~/.weclaw/watchdog.sh)\n'
printf '  Change model:   OPENCODE_MODEL=<provider/model> bash .devcontainer/post-create.sh\n'
