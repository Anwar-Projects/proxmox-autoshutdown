#!/bin/bash
# shellcheck disable=SC2034
# Configuration module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# Default Configuration
################################################################################

# Paths
readonly PROXMOX_AS_LOG_FILE="${PROXMOX_AS_LOG_FILE:-/var/log/proxmox_autoshutdown.log}"
readonly PROXMOX_AS_STATE_DIR="${PROXMOX_AS_STATE_DIR:-/var/lib/proxmox_autoshutdown}"
readonly PROXMOX_AS_LAST_SHUTDOWN_FILE="$PROXMOX_AS_STATE_DIR/last_shutdown_timestamp"
readonly PROXMOX_AS_HTML_REPORT="${PROXMOX_AS_HTML_REPORT:-/tmp/proxmox_autoshutdown_report.html}"

# Email Configuration
readonly PROXMOX_AS_MAIL_TO="${PROXMOX_AS_MAIL_TO:-}"
readonly PROXMOX_AS_MAIL_FROM="${PROXMOX_AS_MAIL_FROM:-proxmox@$(hostname -f 2>/dev/null || hostname)}"
readonly PROXMOX_AS_MAIL_SUBJECT_PREFIX="${PROXMOX_AS_MAIL_SUBJECT_PREFIX:-Proxmox Health + Shutdown Report}"

# Behavior
readonly PROXMOX_AS_POWER_OFF_NODE="${PROXMOX_AS_POWER_OFF_NODE:-1}"
readonly PROXMOX_AS_VM_SHUTDOWN_TIMEOUT="${PROXMOX_AS_VM_SHUTDOWN_TIMEOUT:-60}"
readonly PROXMOX_AS_VM_GLOBAL_WAIT="${PROXMOX_AS_VM_GLOBAL_WAIT:-600}"

# PBS Settings
readonly PROXMOX_AS_PBS_SAFETY_WAIT="${PROXMOX_AS_PBS_SAFETY_WAIT:-900}"
readonly PROXMOX_AS_PBS_STABLE_CHECKS="${PROXMOX_AS_PBS_STABLE_CHECKS:-10}"
readonly PROXMOX_AS_PBS_INTERVAL="${PROXMOX_AS_PBS_INTERVAL:-5}"

# APT Settings
readonly PROXMOX_AS_APT_UPDATE="${PROXMOX_AS_APT_UPDATE:-1}"
readonly PROXMOX_AS_APT_UPGRADE="${PROXMOX_AS_APT_UPGRADE:-1}"
readonly PROXMOX_AS_APT_AUTOREMOVE="${PROXMOX_AS_APT_AUTOREMOVE:-1}"
readonly PROXMOX_AS_APT_CLEAN="${PROXMOX_AS_APT_CLEAN:-1}"

# Dry run mode (set via command line --dry-run or DRY_RUN=1 in env)
PROXMOX_AS_DRY_RUN="${PROXMOX_AS_DRY_RUN:-0}"

################################################################################
# Configuration Loading
################################################################################

config_load_env_file() {
  local env_file="${1:-/etc/default/proxmox-autoshutdown}"
  if [[ -f "$env_file" ]]; then
    # shellcheck source=/dev/null
    source "$env_file"
    log_info "Loaded configuration from $env_file"
  fi
}

config_validate() {
  local errors=0

  # Validate required settings
  if [[ -z "$PROXMOX_AS_MAIL_TO" ]]; then
    log_warn "MAIL_TO not set - email will not be sent"
  fi

  # Validate numeric values
  if ! [[ "$PROXMOX_AS_POWER_OFF_NODE" =~ ^[01]$ ]]; then
    log_error "POWER_OFF_NODE must be 0 or 1, got: $PROXMOX_AS_POWER_OFF_NODE"
    errors=$((errors + 1))
  fi

  if ! [[ "$PROXMOX_AS_DRY_RUN" =~ ^[01]$ ]]; then
    log_error "DRY_RUN must be 0 or 1, got: $PROXMOX_AS_DRY_RUN"
    errors=$((errors + 1))
  fi

  # Ensure state directory exists
  if ! mkdir -p "$PROXMOX_AS_STATE_DIR" 2>/dev/null; then
    log_error "Cannot create state directory: $PROXMOX_AS_STATE_DIR"
    errors=$((errors + 1))
  fi

  # Ensure log file is writable
  if [[ -e "$PROXMOX_AS_LOG_FILE" ]] && [[ ! -w "$PROXMOX_AS_LOG_FILE" ]]; then
    log_error "Log file not writable: $PROXMOX_AS_LOG_FILE"
    errors=$((errors + 1))
  fi

  return $errors
}

config_parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run | -n)
      PROXMOX_AS_DRY_RUN=1
      shift
      ;;
    --help | -h)
      show_usage
      exit 0
      ;;
    --version | -v)
      show_version
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_usage
      exit 1
      ;;
    esac
  done
}

show_usage() {
  cat << 'USAGE'
Usage: proxmox-autoshutdown [OPTIONS]

Options:
  --dry-run, -n    Run in dry-run mode (no actual shutdown or changes)
  --help, -h       Show this help message
  --version, -v    Show version information

Environment Variables:
  MAIL_TO          Email recipient (required for email reports)
  MAIL_FROM        Email sender address
  POWER_OFF_NODE   Set to 0 to disable node poweroff (default: 1)
  DRY_RUN          Set to 1 for dry-run mode (default: 0)
  
  See /etc/default/proxmox-autoshutdown for all configuration options.

Report bugs at: https://github.com/Anwar-Projects/proxmox-autoshutdown/issues
USAGE
}

show_version() {
  echo "proxmox-autoshutdown v1.0.0"
}

################################################################################
# Export configuration
################################################################################

export PROXMOX_AS_LOG_FILE PROXMOX_AS_STATE_DIR PROXMOX_AS_LAST_SHUTDOWN_FILE
export PROXMOX_AS_HTML_REPORT PROXMOX_AS_MAIL_TO PROXMOX_AS_MAIL_FROM
export PROXMOX_AS_MAIL_SUBJECT_PREFIX PROXMOX_AS_POWER_OFF_NODE
export PROXMOX_AS_VM_SHUTDOWN_TIMEOUT PROXMOX_AS_VM_GLOBAL_WAIT
export PROXMOX_AS_PBS_SAFETY_WAIT PROXMOX_AS_PBS_STABLE_CHECKS
export PROXMOX_AS_PBS_INTERVAL PROXMOX_AS_APT_UPDATE
export PROXMOX_AS_APT_UPGRADE PROXMOX_AS_APT_AUTOREMOVE PROXMOX_AS_APT_CLEAN
export PROXMOX_AS_DRY_RUN
