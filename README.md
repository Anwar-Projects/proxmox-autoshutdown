# proxmox-autoshutdown
roxmox VE node maintenance workflow with a pre-shutdown HTML health report emailed to you
# Proxmox Maintenance + Health Report (Email Before Shutdown)

A Bash script for Proxmox VE nodes that:
- Gracefully shuts down running VMs
- Runs APT maintenance (update/dist-upgrade/autoremove/clean)
- Waits for Proxmox Backup Server (PBS) tasks to finish
- Generates an HTML health report (black background, lime text, Calibri)
- Emails the HTML report via local `sendmail` interface (msmtp-mta or postfix)
- Optionally powers off the node

## Features
- DRY-RUN mode (`--dry-run` or `DRY_RUN=1`)
- Hardened report generation (best-effort email on error via trap)
- PBS task polling with stability checks
- SMART health summary (if `smartctl` is installed)
- VM inventory/status table

## Requirements
- Proxmox VE node (Debian-based)
- `bash`, `apt`
- `sendmail` (via `msmtp-mta` or `postfix`)
- Proxmox CLI tools (`qm`)
Optional:
- `proxmox-backup-manager` and `jq` for PBS task summary
- `smartmontools` for SMART data

## Installation
```bash
git clone https://github.com/Anwar-Projects/proxmox-autoshutdown/tree/Projects
cd proxmox-maintenance-report
chmod +x proxmox-maintenance.sh
