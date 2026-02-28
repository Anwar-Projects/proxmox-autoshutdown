#!/bin/bash
# Proxmox Backup Server (PBS) module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# PBS State Variables
################################################################################

PBS_TABLE_ROWS=""

################################################################################
# PBS Collection
################################################################################

collect_pbs_summary() {
  PBS_TABLE_ROWS=""

  if ! command -v proxmox-backup-manager >/dev/null 2>&1; then
    PBS_TABLE_ROWS="<tr><td colspan=5>PBS not installed</td></tr>"
    log_info "PBS (proxmox-backup-manager) not found"
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    _pbs_collect_with_jq
  else
    _pbs_collect_without_jq
  fi

  log_info "PBS summary collected"
}

_pbs_collect_with_jq() {
  local json
  json="$(proxmox-backup-manager task list --output-format json 2>/dev/null || echo '[]')"

  local -a lines
  mapfile -t lines <<<"$(echo "$json" | jq -r \
    '.[] | "\(.up_id)|\(.type)|\(.starttime)|\(.endtime // "")|\(.state)"' \
    | tail -n 10)"

  if ((${#lines[@]} == 0)); then
    PBS_TABLE_ROWS="<tr><td colspan=5>No PBS tasks found</td></tr>"
    return 0
  fi

  local l up_id type start end state
  for l in "${lines[@]}"; do
    IFS='|' read -r up_id type start end state <<<"$l"
    PBS_TABLE_ROWS+="<tr><td>$up_id</td><td>$type</td><td>$start</td><td>${end:-n/a}</td><td>$state</td></tr>"
  done
}

_pbs_collect_without_jq() {
  PBS_TABLE_ROWS="<tr><td colspan=5><pre>$(proxmox-backup-manager task list 2>/dev/null || echo "n/a")</pre></td></tr>"
}

################################################################################
# PBS Task Waiting
################################################################################

pbs_tasks_running() {
  if ! command -v proxmox-backup-manager >/dev/null 2>&1; then
    return 1
  fi

  if command -v jq >/dev/null 2>&1; then
    _pbs_tasks_running_jq
  else
    _pbs_tasks_running_text
  fi
}

_pbs_tasks_running_jq() {
  proxmox-backup-manager task list --output-format json 2>/dev/null |
    jq -e '.[] | select(.state == "running")' >/dev/null 2>&1
}

_pbs_tasks_running_text() {
  proxmox-backup-manager task list 2>/dev/null | awk 'NR>1' | grep -qi "running"
}

wait_for_pbs_tasks() {
  log_info "Checking for PBS tasks..."
  local stable=0
  local elapsed=0

  while ((elapsed < PROXMOX_AS_PBS_SAFETY_WAIT)); do
    if pbs_tasks_running; then
      stable=0
      log_info "PBS tasks running. Waiting..."
    else
      stable=$((stable + 1))
      log_info "No PBS tasks running (${stable}/${PROXMOX_AS_PBS_STABLE_CHECKS})"
      ((stable >= PROXMOX_AS_PBS_STABLE_CHECKS)) && return 0
    fi
    sleep "$PROXMOX_AS_PBS_INTERVAL"
    elapsed=$((elapsed + PROXMOX_AS_PBS_INTERVAL))
  done

  log_warn "PBS wait timeout exceeded after ${PROXMOX_AS_PBS_SAFETY_WAIT}s"
  return 0
}
