# Proxmox Autoshutdown

Graceful Proxmox VE node maintenance with email health reports.

[![Lint](https://img.shields.io/badge/lint-shellcheck-brightgreen)](https://www.shellcheck.net/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- **Graceful VM Shutdown**: Sends shutdown signals to running VMs and waits for completion
- **APT Maintenance**: Automated update, upgrade, autoremove, and clean operations
- **PBS Integration**: Waits for Proxmox Backup Server tasks to complete
- **Health Reports**: Generates stylish HTML reports (matrix/terminal theme)
- **Email Delivery**: Sends reports via local `sendmail` interface (msmtp/postfix)
- **Completely Configurable**: Environment variables and config files
- **Dry-Run Mode**: Test without making changes
- **Error Recovery**: Error trap ensures report is sent even if script fails

## Quick Start

```bash
# Clone the repository
git clone https://github.com/Anwar-Projects/proxmox-autoshutdown.git
cd proxmox-autoshutdown

# Run smoke tests
make test-smoke

# Test in dry-run mode first
./src/proxmox-autoshutdown.sh --dry-run

# Install
sudo make install

# Configure email
cp examples/config.example /etc/default/proxmox-autoshutdown
edit /etc/default/proxmox-autoshutdown  # Set MAIL_TO

# Install and configure mail transport (choose one)
# Option 1: msmtp (lightweight)
sudo apt install msmtp-mta
cp examples/msmtprc.example /etc/msmtprc
# Edit /etc/msmtprc with your SMTP settings

# Enable scheduled runs
sudo systemctl enable --now proxmox-autoshutdown.timer
```

## Installation

### System Requirements

- Proxmox VE 7.x or 8.x (Debian 11+/12+)
- `bash` 4.2+
- `sendmail` compatible MTA (msmtp-mta or postfix)
- `jq` (optional, for JSON PBS output)

### Install from Source

```bash
# Install to /usr/local/sbin and set up systemd
sudo make install

# Or install just the script
sudo make install-script
```

### Manual Install

```bash
# Install script
sudo install -m 0755 src/proxmox-autoshutdown.sh /usr/local/sbin/proxmox-autoshutdown

# Install systemd files
sudo install -m 0644 systemd/proxmox-autoshutdown.service /etc/systemd/system/
sudo install -m 0644 systemd/proxmox-autoshutdown.timer /etc/systemd/system/
sudo systemctl daemon-reload

# Install config
sudo install -m 0644 examples/config.example /etc/default/proxmox-autoshutdown
```

## Configuration

### Environment Variables

All settings can be configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `MAIL_TO` | *(none)* | Email recipient (**required** for email) |
| `MAIL_FROM` | `proxmox@hostname` | Email sender address |
| `POWER_OFF_NODE` | `1` | Set to `0` to disable node poweroff |
| `DRY_RUN` | `0` | Set to `1` for dry-run mode |
| `LOG_FILE` | `/var/log/proxmox_autoshutdown.log` | Log file path |
| `STATE_DIR` | `/var/lib/proxmox_autoshutdown` | State directory |

### Configuration File

Create `/etc/default/proxmox-autoshutdown`:

```bash
MAIL_TO="admin@example.com"
POWER_OFF_NODE=1
VM_SHUTDOWN_TIMEOUT=60
DRY_RUN=0
```

See `examples/config.example` for all options.

## Usage

### Command Line

```bash
# Dry run (recommended first test)
./proxmox-autoshutdown.sh --dry-run

# Run without powering off
MAIL_TO="you@example.com" POWER_OFF_NODE=0 ./proxmox-autoshutdown.sh

# Typical unattended run (powers off by default)
MAIL_TO="you@example.com" ./proxmox-autoshutdown.sh

# Show help
./proxmox-autoshutdown.sh --help
```

### Scheduled Runs (systemd)

```bash
# Enable weekly automatic runs (Sundays at 3 AM)
sudo systemctl enable --now proxmox-autoshutdown.timer

# Check timer status
sudo systemctl status proxmox-autoshutdown.timer
```

## Development

### Testing

```bash
# Run all tests
make test

# Run smoke tests only (quick validation)
make test-smoke

# Run unit tests (requires bats-core)
make test-unit

# Check syntax
make test-syntax
```

### Linting and Formatting

```bash
# Run shellcheck
make lint
# or
make shellcheck

# Check formatting
make check

# Auto-format code (requires shfmt)
make format
```

### Project Structure

```
proxmox-autoshutdown/
├── src/
│   └── proxmox-autoshutdown.sh   # Main entry point
├── lib/
│   ├── config.sh                  # Configuration management
│   ├── logging.sh                 # Logging functions
│   ├── health.sh                  # System health collection
│   ├── vm.sh                      # VM operations
│   ├── pbs.sh                     # PBS integration
│   ├── apt.sh                     # APT maintenance
│   ├── report.sh                  # HTML report generation
│   └── email.sh                   # Email delivery
├── systemd/                        # systemd service and timer
├── examples/                       # Configuration examples
├── tests/                          # Test suite
├── README.md
├── LICENSE
└── Makefile
```

## Safety Notes

⚠️ **Important:**

- **Default behavior powers off the node.** Set `POWER_OFF_NODE=0` if you want to test without shutdown.
- `apt dist-upgrade` can install new kernels requiring reboot. Plan maintenance windows accordingly.
- The emailed report includes the last 200 lines of logs; treat it as potentially sensitive.
- VM shutdown is graceful (`qm shutdown`), but if VMs hang past `VM_GLOBAL_WAIT`, the script continues and may power off.

## Troubleshooting

### Email not sending

1. Verify `MAIL_TO` is set in `/etc/default/proxmox-autoshutdown`
2. Check that `sendmail` is installed: `which sendmail`
3. Test with msmtp: `echo "Test" | sendmail you@example.com`
4. Check logs: `tail -f /var/log/proxmox_autoshutdown.log`

### Script fails to start

1. Run with `--dry-run` to test without making changes
2. Check syntax: `make test-syntax`
3. Check for shellcheck issues: `make lint`
4. Verify qm is available: `which qm`

### PBS tasks not detected

1. Ensure `proxmox-backup-manager` is installed
2. Install `jq` for better JSON parsing: `apt install jq`

## License

MIT License - See [LICENSE](LICENSE)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
