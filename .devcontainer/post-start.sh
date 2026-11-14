#!/usr/bin/env bash
# Codespaces runs this on every container start (resume/rebuild) and attach.
# Ensures the weclaw bridge (re)starts and its watchdog is running.
set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="$HOME/.weclaw"
mkdir -p "$BASE"
printf '%s [post-start] invoked (pid=%s)\n' "$(date '+%F %T')" "$$" >>"$BASE/autostart.log"

# Always refresh the installed helpers so repo edits take effect.
if [ -f "$REPO_DIR/.devcontainer/weclaw-watchdog.sh" ]; then
  install -m 0755 "$REPO_DIR/.devcontainer/weclaw-watchdog.sh" "$BASE/watchdog.sh"
fi
if [ -f "$REPO_DIR/.devcontainer/weclaw-autostart.sh" ]; then
  install -m 0755 "$REPO_DIR/.devcontainer/weclaw-autostart.sh" "$BASE/autostart.sh"
fi

# Restore the WeChat account token from the persistent workspace if the
# container was rebuilt and ~/.weclaw was wiped. Only fill in missing files
# so a newer login is never overwritten.
BACKUP="${WECLAW_BACKUP_DIR:-}"
if [ -z "$BACKUP" ] && [ -d /workspaces ]; then
  BACKUP="/workspaces/.weclaw-backup"
fi
if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
  mkdir -p "$BASE/accounts"
  for f in "$BACKUP"/*; do
    [ -e "$f" ] || continue
    dst="$BASE/accounts/$(basename "$f")"
    [ -e "$dst" ] || cp -p "$f" "$dst" 2>/dev/null || true
  done
fi

if [ -x "$BASE/autostart.sh" ]; then
  "$BASE/autostart.sh" || true
fi
