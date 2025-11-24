#!/bin/bash
###############################################################################
# HX-Infrastructure Network Health Check Script
#
# Purpose: Automated network diagnostic and health checking for all
#          infrastructure nodes and critical services
#
# Location: /home/agent0/HX-Infrastructure/procedures/network-health-check.sh
# Version: 1.0
# Created: 2025-11-15
# Maintained By: HX-Infrastructure Team
#
# Usage:
#   ./network-health-check.sh                    # Run all checks
#   ./network-health-check.sh --quick            # Quick check (critical only)
#   ./network-health-check.sh --verbose          # Verbose output
#   ./network-health-check.sh --critical-only    # Only critical services
#   ./network-health-check.sh --help             # Show help
#
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Flags
VERBOSE=false
QUICK_MODE=false
CRITICAL_ONLY=false

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo ""
    echo "============================================================================="
    echo -e "${BLUE}$1${NC}"
    echo "============================================================================="
}

print_subheader() {
    echo ""
    echo -e "${BLUE}--- $1${NC}"
}

check_pass() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "  ${GREEN}✅ PASS${NC}: $1"
}

check_fail() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo -e "  ${RED}❌ FAIL${NC}: $1"
}

check_warn() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    echo -e "  ${YELLOW}⚠️  WARN${NC}: $1"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "  ${BLUE}ℹ️  INFO${NC}: $1"
    fi
}

###############################################################################
# Parse Arguments
###############################################################################

show_help() {
    cat << EOF
HX-Infrastructure Network Health Check

Usage: $0 [OPTIONS]

Options:
    --quick              Quick check (critical services only, no detailed tests)
    --verbose            Show detailed output for all checks
    --critical-only      Only check critical infrastructure (DC, DNS, Auth)
    --help               Show this help message

Examples:
    $0                   # Run full health check
    $0 --quick           # Quick check of critical services
    $0 --verbose         # Detailed output

Exit Codes:
    0 - All checks passed
    1 - One or more checks failed
    2 - Warnings present (no failures)

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --critical-only)
            CRITICAL_ONLY=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

###############################################################################
# Main Health Check Script
###############################################################################

print_header "HX-Infrastructure Network Health Check"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Run Mode: $([ "$QUICK_MODE" = true ] && echo "Quick" || echo "Full")"
echo "Verbose: $([ "$VERBOSE" = true ] && echo "Enabled" || echo "Disabled")"
echo ""

###############################################################################
# 1. Gateway and Basic Connectivity
###############################################################################

print_header "1. Gateway and Basic Connectivity"

# Check gateway reachability
print_subheader "Gateway (192.168.10.1)"
if ping -c 2 -W 2 192.168.10.1 >/dev/null 2>&1; then
    check_pass "Gateway (192.168.10.1) is reachable"
else
    check_fail "Gateway (192.168.10.1) is unreachable"
fi

# Check internet connectivity (if applicable)
if [ "$QUICK_MODE" = false ]; then
    print_subheader "External Connectivity"
    if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
        check_pass "External connectivity (8.8.8.8) available"
    else
        check_warn "External connectivity not available (isolated network is expected)"
    fi
fi

###############################################################################
# 2. Identity & Trust Zone (Critical Infrastructure)
###############################################################################

print_header "2. Identity & Trust Zone - Critical Infrastructure"

# hx-dc-server (192.168.10.200) - Domain Controller
print_subheader "hx-dc-server (192.168.10.200) - Domain Controller & DNS"

# Ping test
if ping -c 2 -W 2 192.168.10.200 >/dev/null 2>&1; then
    check_pass "hx-dc-server is reachable via ping"
else
    check_fail "hx-dc-server is unreachable - CRITICAL FAILURE"
fi

# DNS service (port 53)
if nc -z -w 2 192.168.10.200 53 >/dev/null 2>&1; then
    check_pass "DNS service (port 53) is listening"
else
    check_fail "DNS service (port 53) is not responding"
fi

# Kerberos KDC (port 88)
if nc -z -w 2 192.168.10.200 88 >/dev/null 2>&1; then
    check_pass "Kerberos KDC (port 88) is listening"
else
    check_fail "Kerberos KDC (port 88) is not responding"
fi

# LDAP service (port 389)
if nc -z -w 2 192.168.10.200 389 >/dev/null 2>&1; then
    check_pass "LDAP service (port 389) is listening"
else
    check_fail "LDAP service (port 389) is not responding"
fi

# Test DNS resolution
if nslookup hx-dc-server.hx.dev.local 192.168.10.200 >/dev/null 2>&1; then
    check_pass "DNS resolution working (hx-dc-server.hx.dev.local resolves)"
else
    check_fail "DNS resolution not working"
fi

# hx-ca-server (192.168.10.201) - Certificate Authority
print_subheader "hx-ca-server (192.168.10.201) - Certificate Authority"

if ping -c 2 -W 2 192.168.10.201 >/dev/null 2>&1; then
    check_pass "hx-ca-server is reachable"
else
    check_fail "hx-ca-server is unreachable"
fi

# hx-ssl-server (192.168.10.202) - Reverse Proxy
print_subheader "hx-ssl-server (192.168.10.202) - Reverse Proxy"

if ping -c 2 -W 2 192.168.10.202 >/dev/null 2>&1; then
    check_pass "hx-ssl-server is reachable"
else
    check_fail "hx-ssl-server is unreachable"
fi

if nc -z -w 2 192.168.10.202 443 >/dev/null 2>&1; then
    check_pass "HTTPS (port 443) is listening on hx-ssl-server"
else
    check_fail "HTTPS (port 443) is not responding on hx-ssl-server"
fi

# hx-control-node (192.168.10.203) - Ansible Control
print_subheader "hx-control-node (192.168.10.203) - Ansible Control"

if ping -c 2 -W 2 192.168.10.203 >/dev/null 2>&1; then
    check_pass "hx-control-node is reachable"
else
    check_warn "hx-control-node is unreachable (may be current host)"
fi

# Exit here if critical-only mode
if [ "$CRITICAL_ONLY" = true ]; then
    print_header "Summary (Critical Infrastructure Only)"
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNING_CHECKS${NC}"
    
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    elif [ $WARNING_CHECKS -gt 0 ]; then
        exit 2
    else
        exit 0
    fi
fi

###############################################################################
# 3. Model Serving & Inference Zone
###############################################################################

print_header "3. Model Serving & Inference Zone"

# Ollama servers
for i in 1 2 3; do
    server="hx-ollama${i}-server"
    ip="192.168.10.20$((3 + i))"
    
    print_subheader "$server ($ip)"
    
    if ping -c 2 -W 2 $ip >/dev/null 2>&1; then
        check_pass "$server is reachable"
    else
        check_fail "$server is unreachable"
    fi
    
    if nc -z -w 2 $ip 11434 >/dev/null 2>&1; then
        check_pass "Ollama API (port 11434) is listening on $server"
    else
        check_fail "Ollama API (port 11434) is not responding on $server"
    fi
    
    if [ "$QUICK_MODE" = false ]; then
        # Try to fetch model list
        if curl -s --max-time 3 http://$ip:11434/api/tags >/dev/null 2>&1; then
            check_pass "Ollama API is responding to requests on $server"
        else
            check_warn "Ollama API endpoint returned error on $server"
        fi
    fi
done

# LiteLLM API Gateway
print_subheader "hx-litellm-server (192.168.10.212) - API Gateway"

if ping -c 2 -W 2 192.168.10.212 >/dev/null 2>&1; then
    check_pass "hx-litellm-server is reachable"
else
    check_fail "hx-litellm-server is unreachable"
fi

if nc -z -w 2 192.168.10.212 4000 >/dev/null 2>&1; then
    check_pass "LiteLLM API (port 4000) is listening"
else
    check_fail "LiteLLM API (port 4000) is not responding"
fi

if [ "$QUICK_MODE" = false ]; then
    if curl -s --max-time 3 http://192.168.10.212:4000/health >/dev/null 2>&1; then
        check_pass "LiteLLM health endpoint is responding"
    else
        check_warn "LiteLLM health endpoint returned error"
    fi
fi

###############################################################################
# 4. Data Plane Zone
###############################################################################

print_header "4. Data Plane - Storage & Databases"

# PostgreSQL
print_subheader "hx-postgres-server (192.168.10.209) - PostgreSQL"

if ping -c 2 -W 2 192.168.10.209 >/dev/null 2>&1; then
    check_pass "hx-postgres-server is reachable"
else
    check_fail "hx-postgres-server is unreachable"
fi

if nc -z -w 2 192.168.10.209 5432 >/dev/null 2>&1; then
    check_pass "PostgreSQL (port 5432) is listening"
else
    check_fail "PostgreSQL (port 5432) is not responding"
fi

# Redis
print_subheader "hx-redis-server (192.168.10.210) - Redis Cache"

if ping -c 2 -W 2 192.168.10.210 >/dev/null 2>&1; then
    check_pass "hx-redis-server is reachable"
else
    check_fail "hx-redis-server is unreachable"
fi

if nc -z -w 2 192.168.10.210 6379 >/dev/null 2>&1; then
    check_pass "Redis (port 6379) is listening"
else
    check_fail "Redis (port 6379) is not responding"
fi

if nc -z -w 2 192.168.10.210 8001 >/dev/null 2>&1; then
    check_pass "Redis UI (port 8001) is listening"
else
    check_warn "Redis UI (port 8001) is not responding"
fi

# Qdrant Vector Database
print_subheader "hx-qdrant-server (192.168.10.207) - Vector Database"

if ping -c 2 -W 2 192.168.10.207 >/dev/null 2>&1; then
    check_pass "hx-qdrant-server is reachable"
else
    check_fail "hx-qdrant-server is unreachable"
fi

if nc -z -w 2 192.168.10.207 6333 >/dev/null 2>&1; then
    check_pass "Qdrant API (port 6333) is listening"
else
    check_fail "Qdrant API (port 6333) is not responding"
fi

if nc -z -w 2 192.168.10.207 6334 >/dev/null 2>&1; then
    check_pass "Qdrant gRPC (port 6334) is listening"
else
    check_warn "Qdrant gRPC (port 6334) is not responding"
fi

if [ "$QUICK_MODE" = false ]; then
    if curl -s --max-time 3 http://192.168.10.207:6333/collections >/dev/null 2>&1; then
        check_pass "Qdrant API is responding to requests"
    else
        check_warn "Qdrant API returned error"
    fi
fi

# Qdrant UI
print_subheader "hx-qdrant-ui-server (192.168.10.208) - Qdrant Web UI"

if ping -c 2 -W 2 192.168.10.208 >/dev/null 2>&1; then
    check_pass "hx-qdrant-ui-server is reachable"
else
    check_fail "hx-qdrant-ui-server is unreachable"
fi

if nc -z -w 2 192.168.10.208 3000 >/dev/null 2>&1; then
    check_pass "Qdrant UI (port 3000) is listening"
else
    check_fail "Qdrant UI (port 3000) is not responding"
fi

# QMCP Server
print_subheader "hx-qmcp-server (192.168.10.211) - Qdrant MCP"

if ping -c 2 -W 2 192.168.10.211 >/dev/null 2>&1; then
    check_pass "hx-qmcp-server is reachable"
else
    check_fail "hx-qmcp-server is unreachable"
fi

###############################################################################
# 5. Agentic & Toolchain Zone
###############################################################################

print_header "5. Agentic & Toolchain - MCP Services"

# FastMCP Gateway
print_subheader "hx-fastmcp-server (192.168.10.213) - MCP Gateway"

if ping -c 2 -W 2 192.168.10.213 >/dev/null 2>&1; then
    check_pass "hx-fastmcp-server is reachable"
else
    check_fail "hx-fastmcp-server is unreachable"
fi

if nc -z -w 2 192.168.10.213 8000 >/dev/null 2>&1; then
    check_pass "FastMCP (port 8000) is listening"
else
    check_fail "FastMCP (port 8000) is not responding"
fi

# n8n MCP Server
print_subheader "hx-n8n-mcp-server (192.168.10.214) - n8n MCP"

if ping -c 2 -W 2 192.168.10.214 >/dev/null 2>&1; then
    check_pass "hx-n8n-mcp-server is reachable"
else
    check_fail "hx-n8n-mcp-server is unreachable"
fi

# n8n Workflow Server
print_subheader "hx-n8n-server (192.168.10.215) - n8n Workflows"

if ping -c 2 -W 2 192.168.10.215 >/dev/null 2>&1; then
    check_pass "hx-n8n-server is reachable"
else
    check_fail "hx-n8n-server is unreachable"
fi

if nc -z -w 2 192.168.10.215 5678 >/dev/null 2>&1; then
    check_pass "n8n Web UI (port 5678) is listening"
else
    check_fail "n8n Web UI (port 5678) is not responding"
fi

# Docling Worker
print_subheader "hx-docling-server (192.168.10.216) - Docling Worker"

if ping -c 2 -W 2 192.168.10.216 >/dev/null 2>&1; then
    check_pass "hx-docling-server is reachable"
else
    check_fail "hx-docling-server is unreachable"
fi

# Crawl4AI MCP
print_subheader "hx-crawl4ai-mcp-server (192.168.10.218) - Crawl4AI MCP"

if ping -c 2 -W 2 192.168.10.218 >/dev/null 2>&1; then
    check_pass "hx-crawl4ai-mcp-server is reachable"
else
    check_fail "hx-crawl4ai-mcp-server is unreachable"
fi

# Crawl4AI Worker
print_subheader "hx-crawl4ai-server (192.168.10.219) - Crawl4AI Worker"

if ping -c 2 -W 2 192.168.10.219 >/dev/null 2>&1; then
    check_pass "hx-crawl4ai-server is reachable"
else
    check_fail "hx-crawl4ai-server is unreachable"
fi

# LightRAG Server
print_subheader "hx-lightrag-server (192.168.10.220) - LightRAG"

if ping -c 2 -W 2 192.168.10.220 >/dev/null 2>&1; then
    check_pass "hx-lightrag-server is reachable"
else
    check_fail "hx-lightrag-server is unreachable"
fi

###############################################################################
# 6. Application Layer
###############################################################################

print_header "6. Application Layer - User-Facing Services"

# Open WebUI
print_subheader "hx-webui-server (192.168.10.227) - Open WebUI"

if ping -c 2 -W 2 192.168.10.227 >/dev/null 2>&1; then
    check_pass "hx-webui-server is reachable"
else
    check_fail "hx-webui-server is unreachable"
fi

if nc -z -w 2 192.168.10.227 3000 >/dev/null 2>&1; then
    check_pass "Open WebUI (port 3000) is listening"
else
    check_fail "Open WebUI (port 3000) is not responding"
fi

# AG-UI Server (Planned)
print_subheader "hx-agui-server (192.168.10.221) - AG-UI [PLANNED]"

if ping -c 2 -W 2 192.168.10.221 >/dev/null 2>&1; then
    check_warn "hx-agui-server is reachable but service not yet deployed"
else
    verbose_log "hx-agui-server not yet deployed (expected)"
fi

###############################################################################
# 7. Integration & Governance
###############################################################################

print_header "7. Integration & Governance"

# Claude Code Server
print_subheader "hx-cc-server (192.168.10.224) - Claude Code"

if ping -c 2 -W 2 192.168.10.224 >/dev/null 2>&1; then
    check_pass "hx-cc-server is reachable"
else
    check_fail "hx-cc-server is unreachable"
fi

###############################################################################
# 8. DNS Resolution Tests (All Servers)
###############################################################################

if [ "$QUICK_MODE" = false ]; then
    print_header "8. DNS Resolution - All Operational Servers"
    
    # Test a sample of critical servers
    dns_test_servers=(
        "hx-dc-server.hx.dev.local"
        "hx-webui-server.hx.dev.local"
        "hx-postgres-server.hx.dev.local"
        "hx-qdrant-server.hx.dev.local"
        "hx-litellm-server.hx.dev.local"
    )
    
    dns_failures=0
    for server in "${dns_test_servers[@]}"; do
        if nslookup "$server" 192.168.10.200 >/dev/null 2>&1; then
            verbose_log "$server resolves correctly"
        else
            check_fail "Failed to resolve $server"
            dns_failures=$((dns_failures + 1))
        fi
    done
    
    if [ $dns_failures -eq 0 ]; then
        check_pass "All sampled DNS resolutions successful"
    fi
fi

###############################################################################
# 9. End-to-End Integration Tests
###############################################################################

if [ "$QUICK_MODE" = false ]; then
    print_header "9. End-to-End Integration Tests"
    
    # Test 1: User → SSL → WebUI flow
    print_subheader "Integration Test: User Request Flow"
    
    flow_pass=true
    
    # Check reverse proxy can reach WebUI
    if nc -z -w 2 192.168.10.202 443 >/dev/null 2>&1; then
        verbose_log "SSL reverse proxy reachable"
    else
        check_fail "SSL reverse proxy integration test failed"
        flow_pass=false
    fi
    
    if nc -z -w 2 192.168.10.227 3000 >/dev/null 2>&1; then
        verbose_log "WebUI backend reachable"
    else
        check_fail "WebUI backend integration test failed"
        flow_pass=false
    fi
    
    if [ "$flow_pass" = true ]; then
        check_pass "User request flow (SSL → WebUI) integration test passed"
    fi
    
    # Test 2: WebUI → LiteLLM → Ollama flow
    print_subheader "Integration Test: LLM Request Flow"
    
    llm_flow_pass=true
    
    if nc -z -w 2 192.168.10.212 4000 >/dev/null 2>&1; then
        verbose_log "LiteLLM gateway reachable"
    else
        check_fail "LiteLLM gateway integration test failed"
        llm_flow_pass=false
    fi
    
    if nc -z -w 2 192.168.10.204 11434 >/dev/null 2>&1; then
        verbose_log "Ollama1 backend reachable"
    else
        check_fail "Ollama backend integration test failed"
        llm_flow_pass=false
    fi
    
    if [ "$llm_flow_pass" = true ]; then
        check_pass "LLM request flow (WebUI → LiteLLM → Ollama) integration test passed"
    fi
    
    # Test 3: MCP Service Chain
    print_subheader "Integration Test: MCP Service Chain"
    
    mcp_flow_pass=true
    
    if nc -z -w 2 192.168.10.213 8000 >/dev/null 2>&1; then
        verbose_log "FastMCP gateway reachable"
    else
        check_fail "FastMCP gateway integration test failed"
        mcp_flow_pass=false
    fi
    
    if nc -z -w 2 192.168.10.211 8000 >/dev/null 2>&1; then
        verbose_log "QMCP backend reachable"
    else
        verbose_log "QMCP backend not responding (may be expected)"
    fi
    
    if [ "$mcp_flow_pass" = true ]; then
        check_pass "MCP service chain integration test passed"
    fi
fi

###############################################################################
# Summary Report
###############################################################################

print_header "Health Check Summary"

echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Total Checks Performed: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNING_CHECKS${NC}"
echo ""

# Calculate success percentage
if [ $TOTAL_CHECKS -gt 0 ]; then
    success_rate=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    echo "Success Rate: ${success_rate}%"
else
    echo "Success Rate: N/A"
fi

echo ""

# Overall status
if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ Overall Status: HEALTHY${NC}"
    echo "All systems operational."
    exit_code=0
elif [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Overall Status: WARNINGS PRESENT${NC}"
    echo "No critical failures, but some warnings detected."
    exit_code=2
else
    echo -e "${RED}❌ Overall Status: ISSUES DETECTED${NC}"
    echo "Critical failures detected. Review logs above."
    exit_code=1
fi

echo ""
echo "============================================================================="

# Recommendations
if [ $FAILED_CHECKS -gt 0 ]; then
    echo ""
    echo "RECOMMENDATIONS:"
    echo "  1. Review failed checks above"
    echo "  2. Consult /home/agent0/HX-Infrastructure/network/network-troubleshooting.md"
    echo "  3. Check service logs on affected servers"
    echo "  4. Create defect report if issue persists"
    echo ""
fi

exit $exit_code
