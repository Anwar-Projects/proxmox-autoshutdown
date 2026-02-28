#!/bin/bash
###############################################################################
# Proxmox Autoshutdown
# Gracefully shuts down VMs, performs maintenance, generates a health report
# and optionally powers off the node.
###############################################################################

set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Script directory for loading modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="${PROJECT_DIR}/lib"

###############################################################################
# Module Loading
###############################################################################

# shellcheck source=/dev/null
source "$LIB_DIR/logging.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/config.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/health.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/vm.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/pbs.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/apt.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/report.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/email.sh"

###############################################################################
# Error Handling
###############################################################################

on_error() {
  local rc=$?
  log_error "Script failed with exit code $rc"

  # Best-effort report generation and email
  reset_error_trap
  if generate_html_report 2>/dev/null; then
    send_html_email 2>/dev/null || true
  fi

  exit $rc
}

trap on_error ERR

###############################################################################
# Main Functions
###############################################################################

record_shutdown() {
  if ! ((PROXMOX_AS_DRY_RUN)); then
    date +%s > "$PROXMOX_AS_LAST_SHUTDOWN_FILE"
    log_info "Shutdown timestamp recorded"
  fi
}

poweroff_node() {
  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would power off node"
    return 0
  fi

  if ((PROXMOX_AS_POWER_OFF_NODE != 1)); then
    log_info "POWER_OFF_NODE disabled, skipping poweroff"
    return 0
  fi

  record_shutdown
  log_info "Initiating systemctl poweroff"
  systemctl poweroff
}

show_banner() {
  cat << 'BANNER'
   ____  ____   ____  ____   ___  ____   ___________ _____ _   _ _   _
  |  _ \|  _ \ / ___|| __ ) / _ \| __ ) |_   _|___  / ____| \ | | | | |
  | |_) | |_) | |  _ |  _ \| | | |  _ \   | |    / /| (___ |  \| | | | |
  |  __/|  __/| |_| || |_) | |_| | |_) |  | |   / /  \___ \| . ` | | | |
  |_|   |_|    \____||____/ \___/|____/   |_|  /_____|____/|_|\_||_|_|

BANNER
  log_info "Proxmox Autoshutdown v1.0.0"
  log_info "Mode: $([[ "$PROXMOX_AS_DRY_RUN" == "1" ]] && echo "DRY-RUN" || echo "NORMAL")"
}

main() {
  # Parse command line arguments
  config_parse_args "$@"

  # Load environment config file
  config_load_env_file

  # Re-parse args (ENV overrides file, args override ENV)
  config_parse_args "$@"

  show_banner

  # Validate configuration
  if ! config_validate; then
    log_fatal "Configuration validation failed"
    exit 1
  fi

  # Verify email config (warn only)
  email_verify_config || true

  log_info "Starting Proxmox Autoshutdown"

  # Step 1: Shutdown VMs
  shutdown_vms

  # Step 2: APT maintenance
  apt_maintenance

  # Step 3: Wait for PBS tasks
  wait_for_pbs_tasks

  # Step 4: Generate report
  generate_html_report

  # Step 5: Send email
  send_html_email || log_warn "Email delivery failed"

  # Step 6: Poweroff
  poweroff_node

  log_info "Proxmox Autoshutdown complete"
}

###############################################################################
# Entry Point
###############################################################################

main "$@"
