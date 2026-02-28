# Proxmox Autoshutdown - Advanced Features

This document describes the advanced features added in v2.0.0.

## Features Overview

### 1. Async/Concurrency Architecture

- **Parallel VM Shutdown**: VMs are shutdown concurrently with configurable semaphore control
- **Async Health Checks**: Non-blocking health monitoring using aiohttp
- **Async PBS Monitoring**: Concurrent task monitoring for Proxmox Backup Server
- **Concurrent Notifications**: Non-blocking email/Slack/Discord generation

**Configuration** (`config-advanced.yaml`):
```yaml
vm:
  parallel_shutdown: true
  max_concurrent: 5
```

### 2. Advanced Configuration Management

- **YAML Configuration**: Structured config with validation at `/etc/proxmox-autoshutdown/config.yaml`
- **Environment-Specific Configs**: Separate configs for dev/staging/prod
- **Hot-Reload**: Configuration changes without restart
- **Encrypted Secrets**: SOPS/Mozilla sops support for sensitive values

**Example**:
```yaml
environment: production
environments:
  development:
    dry_run: true
    power_off_node: false
```

### 3. Enhanced Monitoring & Observability

- **Prometheus Metrics**: Endpoint at `:9100/metrics`
- **Grafana Dashboard**: Pre-configured dashboard JSON
- **Structured JSON Logging**: Severity levels and log shipping
- **OpenTelemetry Tracing**: Distributed request tracing

**Endpoints**:
- `/metrics` - Prometheus metrics
- `/health` - Health check endpoint

**Metrics Available**:
- `proxmox_autoshutdown_health_status` - Node health status
- `proxmox_autoshutdown_vms_shutdown_total` - VMs shutdown count  
- `proxmox_autoshutdown_pbs_tasks_running` - Active PBS tasks
- `proxmox_autoshutdown_operation_duration_seconds` - Operation timing

### 4. State Machine & Workflow Engine

- **Formal State Machine**: Defined shutdown phases with validation
- **Workflow DAG**: Complex dependency management
- **Checkpoint/Resume**: Save/resume capability for long operations
- **Rollback on Failure**: Automatic rollback actions

**States**:
```
IDLE → INITIALIZING → HEALTH_CHECK → PRE_SHUTDOWN → VM_SHUTDOWN → 
PBS_WAIT → APT_MAINTENANCE → REPORT_GENERATION → NOTIFICATION → 
POWEROFF → COMPLETED
```

### 5. Notification System

**Channels**:
- **Email**: SMTP or sendmail-based
- **Slack**: Webhook notifications with rich formatting
- **Discord**: Webhook with embed support
- **PagerDuty**: Event API integration

**Features**:
- Templated notifications with Jinja2
- Escalation policies
- Deduplication (configurable window)

**Configuration**:
```yaml
notifications:
  email:
    enabled: true
    to: ["admin@example.com"]
  slack:
    enabled: true
    webhook_url: "https://hooks.slack.com/..."
```

### 6. Testing Enhancements

- **Integration Tests**: Proxmox API mocks
- **Performance Benchmarks**: Timing and resource usage
- **Chaos Engineering**: Random failure injection
- **Coverage Reporting**: Target 80%+

**Test Commands**:
```bash
make test-integration    # Integration tests
make test-smoke          # Smoke tests
make test-benchmark      # Performance tests
make test-chaos          # Chaos tests
```

### 7. CI/CD & Distribution

- **GitHub Actions**: Automated test, build, release
- **Debian Package**: `.deb` build
- **Container Image**: Docker with health checks
- **Ansible Role**: Automated deployment

**GitHub Actions Workflow**:
- Multi-Python testing (3.9-3.12)
- Shellcheck validation
- Docker build and test
- Automatic release on tags

## Installation

### Via Debian Package
```bash
wget https://github.com/Anwar-Projects/proxmox-autoshutdown/releases/latest/download/proxmox-autoshutdown_2.0.0_amd64.deb
sudo dpkg -i proxmox-autoshutdown_2.0.0_amd64.deb
sudo apt-get install -f
```

### Via Docker
```bash
docker run -d \
  -v /etc/proxmox-autoshutdown:/etc/proxmox-autoshutdown \
  -p 9100:9100 \
  ghcr.io/anwar-projects/proxmox-autoshutdown:latest
```

### Via Ansible
```bash
ansible-playbook -i inventory ansible/playbook.yml
```

## Verification Commands

### Test Async VM Shutdown
```bash
python3 -m proxmox_autoshutdown --dry-run
```

### Verify Prometheus Metrics
```bash
curl http://localhost:9100/metrics
```

### Check State Machine Status
```bash
cat /var/lib/proxmox-autoshutdown/checkpoint.json
```

### Test Notifications
```bash
proxmox-autoshutdown --test-notifications
```

### Health Check
```bash
curl http://localhost:9100/health
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Entry Point                           │
│            (proxmox-autoshutdown.sh / __main__.py)      │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Python     │  │   Bash       │  │  State       │
│   Async      │  │   Legacy     │  │  Machine     │
│   Engine     │  │   Fallback   │  │  (JSON)      │
└──────┬───────┘  └──────────────┘  └──────────────┘
       │
┌──────▼──────────────────────────────────────────┐
│              Async Components                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │  VM      │ │  PBS     │ │  Notifications   │  │
│  │ Manager  │ │ Client   │ │  Manager         │  │
│  │(semaphore│ │(aiohttp) │ │  (async)         │  │
│  │ control) │ │          │ │                  │  │
│  └──────────┘ └──────────┘ └──────────────────┘  │
└──────────────────────────────────────────────────┘
```

## Migration from v1.x

v2.0.0 is backward compatible. The bash implementation is still available:

```bash
# Use existing bash implementation (unchanged)
proxmox-autoshutdown --legacy

# Use new Python async implementation
proxmox-autoshutdown --async

# Auto-detect based on config
proxmox-autoshutdown
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:
- Setting up development environment
- Running tests
- Submitting pull requests
