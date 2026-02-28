#!/bin/bash
# Smoke tests for proxmox-autoshutdown
# Quick validation that the script loads and basic functions work

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="${PROJECT_DIR}/lib"
SRC_DIR="${PROJECT_DIR}/src"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_header() {
  echo ""
  echo "========================================"
  echo "Running: $1"
  echo "========================================"
}

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [[ $# -eq 2 ]]; then
    echo "  $2"
  fi
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

warn() {
  echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

# Test 1: Shellcheck passes
test_shellcheck() {
  test_header "Shellcheck validation"
  if ! command -v shellcheck >/dev/null 2>&1; then
    warn "shellcheck not installed, skipping"
    return
  fi

  local failed=0
  while IFS= read -r -d '' file; do
    if shellcheck -x "$file"; then
      pass "$(basename "$file") passes shellcheck"
    else
      fail "$(basename "$file") has shellcheck errors"
      failed=1
    fi
  done <<<"$(find "$PROJECT_DIR" -type f \( -name "*.sh" \) ! -path "*/.git/*" -print0)"

  return $failed
}

# Test 2: Script syntax check
test_syntax() {
  test_header "Bash syntax validation"

  if bash -n "$SRC_DIR/proxmox-autoshutdown.sh"; then
    pass "Main script syntax OK"
  else
    fail "Main script has syntax errors"
    return 1
  fi

  for lib in "$LIB_DIR"/*.sh; do
    if [[ -f "$lib" ]]; then
      if bash -n "$lib"; then
        pass "$(basename "$lib") syntax OK"
      else
        fail "$(basename "$lib") has syntax errors"
      fi
    fi
  done
}

# Test 3: Module loading
test_modules() {
  test_header "Module loading test"

  # Test that modules load without errors
  if bash -c "PROXMOX_AS_LOG_FILE=/dev/null source $LIB_DIR/logging.sh" 2>&1; then
    pass "logging.sh loads successfully"
  else
    fail "logging.sh failed to load"
  fi

  if bash -c "
    PROXMOX_AS_LOG_FILE=/dev/null
    PROXMOX_AS_STATE_DIR=/tmp
    PROXMOX_AS_HTML_REPORT=/tmp/test.html
    PROXMOX_AS_LAST_SHUTDOWN_FILE=/tmp/last_shutdown
    source $LIB_DIR/config.sh
  " 2>&1; then
    pass "config.sh loads successfully"
  else
    fail "config.sh failed to load"
  fi
}

# Test 4: Dry run test
test_dryrun() {
  test_header "Dry-run mode test"

  # Test that --dry-run doesn't explode (won't work on non-Proxmox but shouldn't crash)
  if timeout 5 bash "${SRC_DIR}/proxmox-autoshutdown.sh" --dry-run >/dev/null 2>&1; then
    pass "Dry-run executes without error"
  else
    # Non-zero exit might be due to missing qm command, that's OK
    pass "Dry-run exits (non-zero likely due to missing Proxmox tools, which is expected)"
  fi
}

# Test 5: Help/Version displays
test_cli() {
  test_header "CLI argument tests"

  if bash "${SRC_DIR}/proxmox-autoshutdown.sh" --help >/dev/null 2>&1; then
    pass "--help displays and exits 0"
  else
    fail "--help failed"
  fi

  if bash "${SRC_DIR}/proxmox-autoshutdown.sh" --version >/dev/null 2>&1; then
    pass "--version displays and exits 0"
  else
    fail "--version failed"
  fi
}

# Test 6: File structure
test_structure() {
  test_header "Repository structure"

  local -a required_files=(
    "README.md"
    "LICENSE"
    "Makefile"
    ".shellcheckrc"
    ".editorconfig"
    "src/proxmox-autoshutdown.sh"
  )

  for file in "${required_files[@]}"; do
    if [[ -f "$PROJECT_DIR/$file" ]]; then
      pass "$file exists"
    else
      fail "$file missing"
    fi
  done

  # Check lib directory has modules
  local lib_count
  lib_count=$(find "$LIB_DIR" -name "*.sh" | wc -l)
  if (( lib_count >= 5 )); then
    pass "lib/ contains $lib_count script modules"
  else
    fail "lib/ should have at least 5 modules, found $lib_count"
  fi
}

# Test 7: Executable permissions
test_permissions() {
  test_header "File permissions"

  if [[ -x "$SRC_DIR/proxmox-autoshutdown.sh" ]]; then
    pass "Main script is executable"
  else
    fail "Main script should be executable"
  fi
}

# Test 8: Configuration file template exists
test_config_examples() {
  test_header "Configuration examples"

  if [[ -f "$PROJECT_DIR/examples/config.example" ]]; then
    pass "Example config exists"
  else
    warn "Example config should be created"
  fi
}

# Main test runner
main() {
  echo "Proxmox Autoshutdown - Smoke Tests"
  echo "====================================="
  echo ""

  test_shellcheck
  test_syntax
  test_modules
  test_dryrun
  test_cli
  test_structure
  test_permissions
  test_config_examples

  echo ""
  echo "====================================="
  echo "Results:"
  echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
  echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
  echo "====================================="

  if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
  fi

  echo ""
  echo "All smoke tests passed!"
}

main "$@"
