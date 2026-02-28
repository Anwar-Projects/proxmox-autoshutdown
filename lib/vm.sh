#!/bin/bash
# VM management module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# VM State Variables
################################################################################

VM_TABLE_ROWS=""

################################################################################
# VM Collection
################################################################################

collect_vm_info() {
  VM_TABLE_ROWS=""

  # Check if qm is available
  if ! command -v qm >/dev/null 2>&1; then
    VM_TABLE_ROWS="<tr><td colspan=3>qm not available</td></tr>"
    log_warn "qm command not available - VM info collection skipped"
    return 0
  fi

  local qm_out
  qm_out="$(qm list 2>/dev/null || true)"

  if [[ -z "$qm_out" ]]; then
    VM_TABLE_ROWS="<tr><td colspan=3>No VM data available (qm list returned empty or failed)</td></tr>"
    log_warn "qm list returned empty output"
    return 0
  fi

  # Build rows
  local vmid name status qstatus
  while read -r vmid name status rest; do
    [[ "$vmid" == "VMID" ]] && continue
    [[ -z "$vmid" ]] && continue
    [[ ! "$vmid" =~ ^[0-9]+$ ]] && continue

    qstatus="$(qm status "$vmid" 2>/dev/null | awk '{print $2}' || true)"
    [[ -z "$qstatus" ]] && qstatus="${status:-unknown}"

    VM_TABLE_ROWS+="<tr><td>$vmid</td><td>${name:-n/a}</td><td>${qstatus}</td></tr>"
  done <<<"$qm_out"

  [[ -z "$VM_TABLE_ROWS" ]] && VM_TABLE_ROWS="<tr><td colspan=3>No VMs found</td></tr>"

  log_info "VM info collected successfully"
  return 0
}

################################################################################
# VM Shutdown
################################################################################

shutdown_vms() {
  # Check for running VMs
  local -a running_vms=()
  local vmid status

  while read -r vmid; do
    [[ -z "$vmid" || ! "$vmid" =~ ^[0-9]+$ ]] && continue
    status="$(qm status "$vmid" 2>/dev/null | awk '{print $2}' || true)"
    [[ "$status" == "running" ]] && running_vms+=("$vmid")
  done <<<"$(qm list 2>/dev/null | awk 'NR>1 {print $1}' || true)"

  if ((${#running_vms[@]} == 0)); then
    log_info "No running VMs detected."
    return 0
  fi

  log_info "Found running VMs: ${running_vms[*]}"

  # Request shutdown for each VM
  local vm
  for vm in "${running_vms[@]}"; do
    _vm_request_shutdown "$vm"
  done

  # Wait for VMs to stop
  _vm_wait_for_stop "${running_vms[@]}"
}

_vm_request_shutdown() {
  local vmid="$1"
  log_info "Requesting shutdown for VM $vmid"

  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would shut down VM $vmid"
    return 0
  fi

  if ! qm shutdown "$vmid" --timeout "$PROXMOX_AS_VM_SHUTDOWN_TIMEOUT" >>"$PROXMOX_AS_LOG_FILE" 2>&1; then
    log_warn "Failed to request shutdown for VM $vmid"
  fi
}

_vm_wait_for_stop() {
  local -a original_vms=("$@")
  local waited=0

  while ((waited < PROXMOX_AS_VM_GLOBAL_WAIT)); do
    local -a still_running=()
    local vmid status

    for vmid in "${original_vms[@]}"; do
      status="$(qm status "$vmid" 2>/dev/null | awk '{print $2}' || true)"
      [[ "$status" == "running" ]] && still_running+=("$vmid")
    done

    if ((${#still_running[@]} == 0)); then
      log_info "All VMs stopped successfully."
      return 0
    fi

    log_info "Still running: ${still_running[*]} (waited ${waited}/${PROXMOX_AS_VM_GLOBAL_WAIT}s)"
    sleep 10
    waited=$((waited + 10))
  done

  log_warn "Some VMs did not shut down in time: ${still_running[*]}"
  return 0
}
