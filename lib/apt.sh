#!/bin/bash
# APT maintenance module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# APT Operations
################################################################################

apt_update() {
  if ((PROXMOX_AS_APT_UPDATE == 0)); then
    log_info "APT update skipped (disabled in config)"
    return 0
  fi

  log_info "Running apt update..."

  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would run apt update"
    return 0
  fi

  if ! apt-get update >>"$PROXMOX_AS_LOG_FILE" 2>&1; then
    log_warn "apt update returned non-zero exit"
    return 1
  fi

  log_info "apt update completed"
}

apt_upgrade() {
  if ((PROXMOX_AS_APT_UPGRADE == 0)); then
    log_info "APT upgrade skipped (disabled in config)"
    return 0
  fi

  log_info "Running apt dist-upgrade..."

  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would run apt dist-upgrade"
    return 0
  fi

  if ! DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y >>"$PROXMOX_AS_LOG_FILE" 2>&1; then
    log_warn "apt dist-upgrade returned non-zero exit"
    return 1
  fi

  log_info "apt dist-upgrade completed"
}

apt_autoremove() {
  if ((PROXMOX_AS_APT_AUTOREMOVE == 0)); then
    log_info "APT autoremove skipped (disabled in config)"
    return 0
  fi

  log_info "Running apt autoremove..."

  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would run apt autoremove"
    return 0
  fi

  if ! DEBIAN_FRONTEND=noninteractive apt-get autoremove -y >>"$PROXMOX_AS_LOG_FILE" 2>&1; then
    log_warn "apt autoremove returned non-zero exit"
    return 1
  fi

  log_info "apt autoremove completed"
}

apt_clean() {
  if ((PROXMOX_AS_APT_CLEAN == 0)); then
    log_info "APT clean skipped (disabled in config)"
    return 0
  fi

  log_info "Running apt clean..."

  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would run apt clean"
    return 0
  fi

  if ! apt-get clean >>"$PROXMOX_AS_LOG_FILE" 2>&1; then
    log_warn "apt clean returned non-zero exit"
    return 1
  fi

  log_info "apt clean completed"
}

# Run full maintenance sequence
apt_maintenance() {
  log_info "Starting APT maintenance..."
  apt_update
  apt_upgrade
  apt_autoremove
  apt_clean
  log_info "APT maintenance complete"
}
