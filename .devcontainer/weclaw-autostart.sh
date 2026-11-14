#!/usr/bin/env bash
# Idempotently ensure weclaw and its watchdog are running.
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

# Bring weclaw up first for a fast recovery, then start the watchdog.
if ! "$WECLAW" status >/dev/null 2>&1; then
  "$WECLAW" start >/dev/null 2>&1 || true
fi

setsid "$WD" >/dev/null 2>&1 </dev/null &
