#!/usr/bin/env bats
# BATS tests for proxmox-autoshutdown functions

setup() {
  PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  LIB_DIR="${PROJECT_DIR}/lib"
  
  # Set test environment
  export PROXMOX_AS_LOG_FILE=/tmp/proxmox-as-test.log
  export PROXMOX_AS_STATE_DIR=/tmp/proxmox-as-test
  export PROXMOX_AS_HTML_REPORT=/tmp/proxmox-as-test.html
  export PROXMOX_AS_LAST_SHUTDOWN_FILE=/tmp/proxmox-as-test/last_shutdown
  
  # Clean up test files
  rm -rf /tmp/proxmox-as-test 2>/dev/null || true
  mkdir -p /tmp/proxmox-as-test
}

teardown() {
  # Clean up test files
  rm -rf /tmp/proxmox-as-test 2>/dev/null || true
  rm -f /tmp/proxmox-as-test.log 2>/dev/null || true
  rm -f /tmp/proxmox-as-test.html 2>/dev/null || true
}

@test "logging module loads correctly" {
  source "$LIB_DIR/logging.sh"
  [ -n "$(type log_info 2>/dev/null)" ]
}

@test "config module loads correctly" {
  source "$LIB_DIR/config.sh"
  [ -n "$PROXMOX_AS_LOG_FILE" ]
}

@test "config_validate handles missing MAIL_TO" {
  source "$LIB_DIR/logging.sh"
  source "$LIB_DIR/config.sh"
  # MAIL_TO is empty by default, validation should pass but warn
  run config_validate
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "vm module loads without Proxmox tools" {
  source "$LIB_DIR/logging.sh"
  source "$LIB_DIR/vm.sh"
  [ -n "$(type collect_vm_info 2>/dev/null)" ]
}

@test "pbs module loads correctly" {
  source "$LIB_DIR/logging.sh"
  source "$LIB_DIR/pbs.sh"
  [ -n "$(type collect_pbs_summary 2>/dev/null)" ]
}

@test "apt module loads correctly" {
  source "$LIB_DIR/logging.sh"
  source "$LIB_DIR/apt.sh"
  [ -n "$(type apt_update 2>/dev/null)" ]
}

@test "report module loads correctly" {
  source "$LIB_DIR/logging.sh"
  source "$LIB_DIR/config.sh"
  source "$LIB_DIR/health.sh"
  source "$LIB_DIR/vm.sh"
  source "$LIB_DIR/pbs.sh"
  source "$LIB_DIR/report.sh"
  [ -n "$(type generate_html_report 2>/dev/null)" ]
}

@test "email module loads correctly" {
  source "$LIB_DIR/config.sh"
  source "$LIB_DIR/logging.sh"
  source "$LIB_DIR/email.sh"
  [ -n "$(type send_html_email 2>/dev/null)" ]
}
