# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-28

### Added

- Initial release with modular architecture
- Graceful VM shutdown with configurable timeout
- APT maintenance (update, upgrade, autoremove, clean)
- PBS task waiting with stability checks
- HTML health report generation with matrix theme
- Email delivery via sendmail interface
- Dry-run mode for testing
- Comprehensive configuration options
- systemd service and timer for automation
- Shellcheck validation with `.shellcheckrc`
- Makefile with lint, format, test targets
- BATS-based unit tests
- Smoke tests for quick validation
- Example configurations for msmtp
- Professional documentation

### Security

- Secrets handled via external files, not in config
- Proper permissions guidance for credential files
- Error trap ensures email on failure
