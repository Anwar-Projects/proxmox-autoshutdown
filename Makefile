# Proxmox Autoshutdown Makefile
# Provides lint, format, test, and release targets

.PHONY: all lint format test check shellcheck shfmt clean install help test-smoke test-unit

SHELL := /bin/bash
SCRIPT_NAME := proxmox-autoshutdown.sh
SRC_DIR := src
LIB_DIR := lib
TEST_DIR := tests
INSTALL_PREFIX ?= /usr/local
SYSTEMD_DIR ?= /etc/systemd/system
ETC_DEFAULT ?= /etc/default

# Default target
all: lint check test

# Install dependencies for development
deps:
	@echo "Installing development dependencies..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck shfmt bats-core jq || true; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install shellcheck shfmt bats-core jq || true; \
	else \
		echo "Please install: shellcheck, shfmt, bats-core, jq"; \
	fi

# Run all linters
lint: shellcheck

# Run shellcheck on all scripts
shellcheck:
	@echo "Running shellcheck..."
	@find . -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" | while read -r f; do \
		echo "  Checking: $$f"; \
		shellcheck -x "$$f" || exit 1; \
	done
	@echo "Shellcheck passed!"

# Check formatting (requires shfmt)
check:
	@echo "Checking formatting..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -d -i 2 -ci -bn "$(SRC_DIR)" || exit 1; \
	else \
		echo "  shfmt not installed, skipping format check"; \
	fi

# Format all shell scripts (requires shfmt)
format:
	@echo "Formatting shell scripts..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w -i 2 -ci -bn "$(SRC_DIR)" "$(LIB_DIR)" "$(TEST_DIR)"; \
		echo "Formatting complete!"; \
	else \
		echo "shfmt not installed. Install with: go install mvdan.cc/sh/v3/cmd/shfmt@latest"; \
		exit 1; \
	fi

# Run all tests
test: test-smoke test-unit

# Run smoke tests (fast, minimal environment)
test-smoke:
	@echo "Running smoke tests..."
	@$(TEST_DIR)/test-smoke.sh

# Run unit tests (requires bats-core)
test-unit:
	@echo "Running unit tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats "$(TEST_DIR)"/*.bats; \
	else \
		echo "  bats not installed, skipping unit tests"; \
	fi

# Quick validation (dry-run syntax check)
test-syntax:
	@echo "Validating script syntax..."
	@bash -n "$(SRC_DIR)/$(SCRIPT_NAME)"
	@echo "Syntax OK!"

# Clean generated files
clean:
	@echo "Cleaning..."
	@rm -f *.html
	@rm -f /tmp/proxmox_dashboard_report.html
	@echo "Clean complete!"

# Install script to system
install: install-script install-systemd

# Install just the script
install-script:
	@echo "Installing $(SCRIPT_NAME) to $(INSTALL_PREFIX)/sbin..."
	@install -m 0755 "$(SRC_DIR)/$(SCRIPT_NAME)" "$(INSTALL_PREFIX)/sbin/proxmox-autoshutdown"
	@echo "Installed!"

# Install systemd service and timer
install-systemd:
	@echo "Installing systemd service and timer..."
	@install -m 0644 systemd/proxmox-autoshutdown.service "$(SYSTEMD_DIR)/"
	@install -m 0644 systemd/proxmox-autoshutdown.timer "$(SYSTEMD_DIR)/"
	@systemctl daemon-reload 2>/dev/null || true
	@systemctl enable proxmox-autoshutdown.timer 2>/dev/null || true
	@echo "Systemd files installed!"

# Install example configuration
install-config:
	@echo "Installing example configuration..."
	@install -m 0644 examples/config.example "$(ETC_DEFAULT)/proxmox-autoshutdown"
	@echo "Example config installed to $(ETC_DEFAULT)/proxmox-autoshutdown"
	@echo "Edit this file before running the script!"

# Uninstall
uninstall:
	@echo "Uninstalling..."
	@systemctl disable --now proxmox-autoshutdown.timer 2>/dev/null || true
	@rm -f "$(SYSTEMD_DIR)/proxmox-autoshutdown.service"
	@rm -f "$(SYSTEMD_DIR)/proxmox-autoshutdown.timer"
	@rm -f "$(INSTALL_PREFIX)/sbin/proxmox-autoshutdown"
	@systemctl daemon-reload 2>/dev/null || true
	@echo "Uninstalled!"

# Show help
help:
	@echo "Proxmox Autoshutdown - Build Targets"
	@echo ""
	@echo "Development:"
	@echo "  deps         Install development dependencies"
	@echo "  lint         Run all linters (shellcheck)"
	@echo "  shellcheck   Run shellcheck on all scripts"
	@echo "  check        Check formatting (requires shfmt)"
	@echo "  format       Format all shell scripts (requires shfmt)"
	@echo ""
	@echo "Testing:"
	@echo "  test         Run all tests (smoke + unit)"
	@echo "  test-smoke   Run quick smoke tests"
	@echo "  test-unit    Run bats-core unit tests"
	@echo "  test-syntax  Validate bash syntax"
	@echo ""
	@echo "Installation:"
	@echo "  install          Full install (script + systemd)"
	@echo "  install-script   Install only the script"
	@echo "  install-systemd  Install systemd service and timer"
	@echo "  install-config   Install example configuration"
	@echo "  uninstall        Remove installed files"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean        Clean generated files"
	@echo "  help         Show this help message"
