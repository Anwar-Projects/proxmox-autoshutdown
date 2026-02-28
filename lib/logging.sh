#!/bin/bash
# Logging module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# Log Levels
################################################################################

readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"

################################################################################
# Internal Functions
################################################################################

_log() {
  local level_name="$1"
  local level_value="$2"
  shift 2
  local msg="$*"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  # Only log if level is >= current level
  if [[ $level_value -ge $LOG_LEVEL ]]; then
    # Log to file if configured
    if [[ -n "${PROXMOX_AS_LOG_FILE:-}" ]]; then
      # Ensure directory exists
      local log_dir
      log_dir="$(dirname "$PROXMOX_AS_LOG_FILE")"
      if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || true
      fi
      echo "[$ts] [$level_name] $msg" >> "$PROXMOX_AS_LOG_FILE" 2>/dev/null || true
    fi
    echo "[$ts] [$level_name] $msg" >&2
  fi
}

################################################################################
# Public API
################################################################################

log_debug() { _log "DEBUG" "$LOG_LEVEL_DEBUG" "$@"; }
log_info() { _log "INFO" "$LOG_LEVEL_INFO" "$@"; }
log_warn() { _log "WARN" "$LOG_LEVEL_WARN" "$@"; }
log_error() { _log "ERROR" "$LOG_LEVEL_ERROR" "$@"; }
log_fatal() { _log "FATAL" "$LOG_LEVEL_FATAL" "$@"; }

# Fatal error handler
fatal_error() {
  local rc=$?
  local msg="${1:-Fatal error occurred}"
  log_fatal "$msg (exit code: $rc)"
  exit $rc
}

# Trap setup for error handling
setup_error_trap() {
  # shellcheck disable=SC2064
  trap "$1" ERR
}

# Reset error trap
reset_error_trap() {
  set +e
}

# Set log level from string
set_log_level() {
  local level="$1"
  case "${level,,}" in
    debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    info) LOG_LEVEL=$LOG_LEVEL_INFO ;;
    warn) LOG_LEVEL=$LOG_LEVEL_WARN ;;
    error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    *) LOG_LEVEL=$LOG_LEVEL_INFO ;;
  esac
}
