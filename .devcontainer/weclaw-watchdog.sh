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
  [ -n "$p" ] || return 1
  kill -0 "$p" 2>/dev/null || return 1
  # Guard against pid reuse after a container restart.
  [ -r "/proc/$p/cmdline" ] || return 1
  tr '\0' ' ' <"/proc/$p/cmdline" | grep -q 'weclaw' || return 1
  return 0
}

# Start weclaw directly in foreground and detach it ourselves.
# Do NOT use `weclaw start` (background mode): runDaemon() -> stopAllWeclaw()
# runs `pkill -f "<resolved-exe> start"`. When weclaw is invoked via an
# absolute path, that pattern also matches the invoking `weclaw start`
# process itself, so the starter is SIGTERMed (exit 143) before the daemon is
# spawned and weclaw never comes up. Running `start -f` skips that path.
start_weclaw() {
  # Clear any orphaned instances not tracked by the pid file.
  pkill -f "$WECLAW start" 2>/dev/null || true
  sleep 1
  rm -f "$PIDFILE"
  "$WECLAW" start -f >>"$LOG" 2>&1 </dev/null &
  printf '%s' "$!" >"$PIDFILE"
}

log "started (pid=$$, interval=${INTERVAL}s)"
trap 'rm -f "$WDPIDFILE"; log "stopping (signal)"; exit 0' TERM INT

while true; do
  if ! is_up; then
    log "weclaw down; starting"
    start_weclaw
    sleep 3
    if is_up; then
      log "weclaw up again (pid=$(cat "$PIDFILE" 2>/dev/null))"
    else
      log "weclaw still down; retrying in ${INTERVAL}s"
    fi
  fi
  rotate
  sync_accounts
  sleep "$INTERVAL"
done
