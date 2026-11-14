#!/usr/bin/env bash
# Idempotently ensure the weclaw watchdog is running.
# The watchdog owns starting/restarting weclaw (see weclaw-watchdog.sh).
# Safe to call from shell init / Codespaces postStartCommand.
set -u

WECLAW="${WECLAW_BIN:-/usr/local/bin/weclaw}"
WD="${HOME:-/home/vscode}/.weclaw/watchdog.sh"
WDPID="${HOME:-/home/vscode}/.weclaw/watchdog.pid"

[ -x "$WECLAW" ] || exit 0
[ -x "$WD" ] || exit 0

# Watchdog already running? Trust its pid file (avoids pgrep self-matches).
if [ -f "$WDPID" ]; then
  p=$(cat "$WDPID" 2>/dev/null || true)
  if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then
    exit 0
  fi
fi

# The watchdog's first loop iteration starts weclaw immediately.
setsid "$WD" >/dev/null 2>&1 </dev/null &
