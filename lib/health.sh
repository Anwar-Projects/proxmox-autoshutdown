#!/bin/bash
# Health collection module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# State Variables
################################################################################

HOSTNAME=""
NOW_HUMAN=""
UPTIME_HUMAN=""
BOOT_TIME_HUMAN=""
DOWNTIME_HUMAN=""
LOAD_AVG=""
MEM_INFO=""
DISK_ROOT=""
SMART_INFO=""
NET_INFO=""

################################################################################
# System Information
################################################################################

_get_boot_time_epoch() {
  local bt
  bt="$(who -b | awk '{print $3" "$4}')"
  date -d "$bt" +%s 2>/dev/null || echo 0
}

_format_duration() {
  local seconds="$1"
  if ((seconds <= 0)); then
    echo "n/a"
    return
  fi
  local days=$((seconds / 86400))
  local hours=$(((seconds % 86400) / 3600))
  local mins=$(((seconds % 3600) / 60))
  local secs=$((seconds % 60))
  local out=""
  ((days > 0)) && out+="${days}d "
  ((hours > 0)) && out+="${hours}h "
  ((mins > 0)) && out+="${mins}m "
  ((secs > 0)) && out+="${secs}s"
  echo "${out:-0s}"
}

_compute_downtime_info() {
  local boot_epoch last_shutdown_epoch downtime
  boot_epoch="$(_get_boot_time_epoch)"

  if [[ -f "${PROXMOX_AS_LAST_SHUTDOWN_FILE:-}" ]]; then
    last_shutdown_epoch="$(cat "$PROXMOX_AS_LAST_SHUTDOWN_FILE" 2>/dev/null || echo 0)"
  else
    last_shutdown_epoch=0
  fi

  if ((last_shutdown_epoch > 0 && boot_epoch > last_shutdown_epoch)); then
    downtime=$((boot_epoch - last_shutdown_epoch))
  else
    downtime=0
  fi
  DOWNTIME_HUMAN="$(_format_duration "$downtime")"
}

collect_system_health() {
  HOSTNAME="$(hostname)"
  NOW_HUMAN="$(date)"
  LOAD_AVG="$(cat /proc/loadavg 2>/dev/null || echo "n/a")"
  MEM_INFO="$(free -h 2>/dev/null || echo "n/a")"
  DISK_ROOT="$(df -h / 2>/dev/null || echo "n/a")"
  BOOT_TIME_HUMAN="$(who -b | awk '{$1=$1; print substr($0,index($0,$3))}')"
  UPTIME_HUMAN="$(uptime -p 2>/dev/null || uptime)"

  _compute_downtime_info

  # Collect SMART info
  if command -v smartctl >/dev/null 2>&1; then
    local disks d
    SMART_INFO=""
    disks="$(ls /dev/sd? /dev/nvme?n? 2>/dev/null || true)"
    for d in $disks; do
      [[ -b "$d" ]] || continue
      SMART_INFO+="<h4>$d</h4><pre>$(smartctl -H "$d" 2>&1)</pre>"
    done
    [[ -z "$SMART_INFO" ]] && SMART_INFO="<p>No SMART-capable disks found.</p>"
  else
    SMART_INFO="<p>smartctl not installed.</p>"
  fi

  # Collect network info
  NET_INFO="<pre>$(ip -brief addr 2>/dev/null || ip addr 2>/dev/null)</pre>"
  NET_INFO+="<pre>$(ss -tuna 2>/dev/null || netstat -tuna 2>/dev/null)</pre>"

  log_info "System health collected for host: $HOSTNAME"
}
