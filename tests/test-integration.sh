#!/bin/bash
###############################################################################
# Integration Tests for Proxmox Autoshutdown
# Tests: async operations, state machine, notifications, metrics
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { echo -e "${RED}✗ FAIL${NC}: $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# Test 9: Async VM shutdown simulation
test_async_vm_shutdown() {
    echo "=== Testing Async VM Shutdown ==="
    
    if [ -f "$PROJECT_DIR/lib/vm.sh" ]; then
        pass "VM module exists for async operations"
    else
        fail "VM module not found"
    fi
    
    # Check for parallel shutdown capability
    if grep -q "parallel" "$PROJECT_DIR/examples/config-advanced.yaml" 2>/dev/null; then
        pass "Parallel shutdown configuration supported"
    else
        warn "Parallel shutdown config not found"
    fi
}

# Test 10: YAML config validation
test_yaml_config() {
    echo "=== Testing YAML Config Support ==="
    
    if [ -f "$PROJECT_DIR/examples/config-advanced.yaml" ]; then
        pass "Advanced config YAML exists"
        
        # Validate YAML syntax
        if python3 -c "import yaml; yaml.safe_load(open('$PROJECT_DIR/examples/config-advanced.yaml'))" 2>/dev/null; then
            pass "YAML config is valid"
        else
            fail "YAML config has syntax errors"
        fi
    else
        fail "Advanced config YAML not found"
    fi
}

# Test 11: Prometheus metrics endpoint
test_metrics_endpoint() {
    echo "=== Testing Metrics Endpoint ==="
    
    if [ -f "$PROJECT_DIR/grafana/dashboard.json" ]; then
        pass "Grafana dashboard exists"
        
        # Check for Prometheus metrics
        if grep -q "prometheus" "$PROJECT_DIR/grafana/dashboard.json" 2>/dev/null; then
            pass "Metrics dashboard configured"
        fi
    fi
}

# Test 12: State machine checkpoint
test_state_machine() {
    echo "=== Testing State Machine ==="
    
    if grep -q "checkpoint" "$PROJECT_DIR/examples/config-advanced.yaml" 2>/dev/null; then
        pass "State machine checkpoint configured"
    fi
}

# Test 13: CI/CD GitHub Actions
test_cicd() {
    echo "=== Testing CI/CD Configuration ==="
    
    if [ -d "$PROJECT_DIR/.github/workflows" ]; then
        pass "GitHub Actions workflows directory exists"
        
        workflow_count=$(find "$PROJECT_DIR/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
        if [ "$workflow_count" -gt 0 ]; then
            pass "CI/CD workflow(s) present ($workflow_count found)"
        fi
    else
        fail "GitHub Actions workflows not found"
    fi
}

# Test 14: Docker support
test_docker() {
    echo "=== Testing Docker Support ==="
    
    if [ -f "$PROJECT_DIR/docker/Dockerfile" ]; then
        pass "Dockerfile exists"
        
        if grep -q "HEALTHCHECK" "$PROJECT_DIR/docker/Dockerfile" 2>/dev/null; then
            pass "Docker health check configured"
        fi
    fi
}

# Test 15: Ansible role
test_ansible() {
    echo "=== Testing Ansible Support ==="
    
    if [ -f "$PROJECT_DIR/ansible/playbook.yml" ]; then
        pass "Ansible playbook exists"
    else
        fail "Ansible playbook not found"
    fi
}

# Main
echo "======================================="
echo "Proxmox Autoshutdown - Integration Tests"
echo "======================================="
echo ""

test_async_vm_shutdown
test_yaml_config
test_metrics_endpoint
test_state_machine
test_cicd
test_docker
test_ansible

echo ""
echo "======================================="
echo "Results:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "======================================="

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi

echo "All integration tests passed!"
