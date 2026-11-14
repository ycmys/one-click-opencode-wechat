#!/usr/bin/env bash
# Keep weclaw alive. Single instance via flock; restarts it if it dies.
set -u

WECLAW="${WECLAW_BIN:-/usr/local/bin/weclaw}"
BASE="${HOME:-/home/vscode}/.weclaw"
LOG="$BASE/watchdog.log"
LOCK="$BASE/watchdog.lock"
WDPIDFILE="$BASE/watchdog.pid"
PIDFILE="$BASE/weclaw.pid"
INTERVAL="${WECLAW_WATCHDOG_INTERVAL:-20}"
MAXLOG="${WECLAW_WATCHDOG_MAXLOG:-1048576}"
BACKUP="${WECLAW_BACKUP_DIR:-}"
if [ -z "$BACKUP" ] && [ -d /workspaces ]; then
  BACKUP="/workspaces/.weclaw-backup"
fi

mkdir -p "$BASE"
log() { printf '%s [watchdog] %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }

sync_accounts() {
  [ -n "$BACKUP" ] || return 0
  [ -d "$BASE/accounts" ] || return 0
  mkdir -p "$BACKUP" 2>/dev/null || return 0
  cp -p "$BASE"/accounts/* "$BACKUP"/ 2>/dev/null || true
}

exec 9>"$LOCK" || exit 1
flock -n 9 || exit 0
echo $$ >"$WDPIDFILE"

rotate() {
  local sz
  sz=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
  if [ "$sz" -gt "$MAXLOG" ]; then
    tail -c 262144 "$LOG" >"$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
  fi
}

is_up() {
  local p
  p=$(cat "$PIDFILE" 2>/dev/null || true)
  [ -n "$p" ] && kill -0 "$p" 2>/dev/null && "$WECLAW" status >/dev/null 2>&1
}

log "started (pid=$$, interval=${INTERVAL}s)"
trap 'rm -f "$WDPIDFILE"; log "stopping (signal)"; exit 0' TERM INT

while true; do
  if ! is_up; then
    log "weclaw down; starting"
    "$WECLAW" start >>"$LOG" 2>&1
    rc=$?
    sleep 3
    if is_up; then
      log "weclaw up again (rc=$rc)"
    else
      log "weclaw still down (rc=$rc); retrying in ${INTERVAL}s"
    fi
  fi
  rotate
  sync_accounts
  sleep "$INTERVAL"
done
