#!/bin/bash
# Report generation module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# Report Templates
################################################################################

_read_template() {
  cat << 'TEMPLATE'
<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<title>Proxmox Maintenance Report</title>
<style>
  body {
    background: #000000 !important;
    color: #00ff00 !important;
    font-family: Calibri, "Segoe UI", Arial, sans-serif !important;
    padding: 20px;
  }
  .container {
    max-width: 1000px;
    margin: auto;
    background: #000000 !important;
    padding: 20px;
    border: 1px solid #00ff00;
  }
  .section {
    background: #000000 !important;
    padding: 15px;
    margin-bottom: 20px;
    border: 1px solid #00ff00;
  }
  h1, h2, h3, h4, p, b, span, div {
    color: #00ff00 !important;
    margin-top: 0;
  }
  a { color: #00ff00 !important; }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
  }
  table, thead, tbody, tr, th, td {
    color: #00ff00 !important;
    background: #000000 !important;
    border: 1px solid #00ff00 !important;
  }
  table * { color: #00ff00 !important; }
  th, td { padding: 6px; text-align: left; }
  pre {
    background: #000000 !important;
    color: #00ff00 !important;
    border: 1px solid #00ff00;
    padding: 10px;
    overflow-x: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
  }
</style>
</head>
<body>
<div class='container'>
<h1>Proxmox Health + Shutdown Report</h1>
<p><b>Node:</b> {{HOSTNAME}}<br>
<b>Generated:</b> {{NOW_HUMAN}}<br>
<b>Mode:</b> {{MODE}}</p>

<div class='section'>
<h2>Node Overview</h2>
<p><b>Uptime:</b> {{UPTIME_HUMAN}}<br>
<b>Last Boot:</b> {{BOOT_TIME_HUMAN}}<br>
<b>Previous Downtime:</b> {{DOWNTIME_HUMAN}}<br>
<b>Load Average:</b> {{LOAD_AVG}}</p>
</div>

<div class='section'>
<h2>System Resources</h2>
<h3>Disk Usage (/)</h3>
<pre>{{DISK_ROOT}}</pre>
<h3>Memory Usage</h3>
<pre>{{MEM_INFO}}</pre>
</div>

<div class='section'>
<h2>VMs</h2>
<table>
<tr><th>VMID</th><th>Name</th><th>Status</th></tr>
{{VM_TABLE_ROWS}}
</table>
</div>

<div class='section'>
<h2>PBS Backup Summary</h2>
<table>
<tr><th>Task ID</th><th>Type</th><th>Start</th><th>End</th><th>State</th></tr>
{{PBS_TABLE_ROWS}}
</table>
</div>

<div class='section'>
<h2>SMART Disk Health</h2>
{{SMART_INFO}}
</div>

<div class='section'>
<h2>Network</h2>
{{NET_INFO}}
</div>

<div class='section'>
<h2>Maintenance Log (last 200 lines)</h2>
<pre>{{LOG_SNIPPET}}</pre>
</div>

</div>
</body>
</html>
TEMPLATE
}

################################################################################
# Report Generation
################################################################################

generate_html_report() {
  log_info "Generating HTML report..."

  # Collect all data first
  collect_system_health
  collect_vm_info
  collect_pbs_summary

  local log_snippet
  log_snippet="$(tail -n 200 "$PROXMOX_AS_LOG_FILE" 2>/dev/null || echo "No log data available.")"

  local mode="Normal"
  ((PROXMOX_AS_DRY_RUN)) && mode="DRY-RUN"

  # Generate template and substitute variables
  _read_template > "$PROXMOX_AS_HTML_REPORT"

  # Substitute variables safely
  sed -i "s|{{HOSTNAME}}|$(echo "$HOSTNAME" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{NOW_HUMAN}}|$(echo "$NOW_HUMAN" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{MODE}}|$mode|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{UPTIME_HUMAN}}|$(echo "$UPTIME_HUMAN" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{BOOT_TIME_HUMAN}}|$(echo "$BOOT_TIME_HUMAN" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{DOWNTIME_HUMAN}}|$(echo "$DOWNTIME_HUMAN" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{LOAD_AVG}}|$(echo "$LOAD_AVG" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{DISK_ROOT}}|$(echo "$DISK_ROOT" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{MEM_INFO}}|$(echo "$MEM_INFO" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{SMART_INFO}}|$SMART_INFO|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{NET_INFO}}|$NET_INFO|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{VM_TABLE_ROWS}}|$VM_TABLE_ROWS|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{PBS_TABLE_ROWS}}|$PBS_TABLE_ROWS|g" "$PROXMOX_AS_HTML_REPORT"
  sed -i "s|{{LOG_SNIPPET}}|$(echo "$log_snippet" | sed 's/[\\/&]/\\&/g')|g" "$PROXMOX_AS_HTML_REPORT"

  local sz
  sz="$(wc -c <"$PROXMOX_AS_HTML_REPORT" 2>/dev/null || echo "unknown")"
  log_info "HTML report generated at $PROXMOX_AS_HTML_REPORT (${sz} bytes)"
}
