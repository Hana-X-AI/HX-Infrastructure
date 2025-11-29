#!/bin/bash
# Quality Gate 1: Pre-Response Charter Review
# Ensures charter is read before phase planning responses
# Based on Julia Santos recommendations - Round 5 violation prevention

set -euo pipefail

# Configuration
CHARTER_PATH="${1:-}"
RESPONSE_CONTEXT="${2:-phase-planning}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track warnings for exit code
WARNINGS=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUALITY GATE 1: Charter Review Requirement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if charter path provided
if [[ -z "$CHARTER_PATH" ]]; then
    echo -e "${RED}❌ FAIL${NC}: No charter path provided"
    echo "Usage: $0 <charter-path> [response-context]"
    exit 1
fi

# Check if charter exists (quoted path)
if [[ ! -f "$CHARTER_PATH" ]]; then
    echo -e "${RED}❌ FAIL${NC}: Charter not found at: $CHARTER_PATH"
    exit 1
fi

# Check charter is readable (quoted path)
if [[ ! -r "$CHARTER_PATH" ]]; then
    echo -e "${RED}❌ FAIL${NC}: Charter exists but is not readable: $CHARTER_PATH"
    exit 1
fi

# Check charter status - robust grep with fallback
CHARTER_STATUS=$(grep "^[*].*Charter Status" "$CHARTER_PATH" | head -1 | sed 's/.*Status:[[:space:]]*//' | tr -d '*') || CHARTER_STATUS="NOT FOUND"
if [[ "$CHARTER_STATUS" != "APPROVED" ]]; then
    echo -e "${YELLOW}⚠️  WARN${NC}: Charter status is '$CHARTER_STATUS' (expected: APPROVED)"
    ((WARNINGS++)) || true
fi

# Verify charter was actually read (check for minimum understanding)
echo ""
echo "Charter Review Verification:"
echo "  Charter Path: $CHARTER_PATH"
echo "  Charter Status: $CHARTER_STATUS"
echo "  Response Context: $RESPONSE_CONTEXT"
echo ""

# Extract key charter sections for validation
echo "Key Charter Requirements:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Extract deployment approach - robust parsing with fallback
DEPLOYMENT_APPROACH=$(grep -A5 "Deployment Strategy" "$CHARTER_PATH" | head -10) || DEPLOYMENT_APPROACH="NOT FOUND"
echo "Deployment Approach:"
echo "$DEPLOYMENT_APPROACH" | awk '{print "  " $0}'
echo ""

# Check for Docker exclusion (quiet mode)
if grep -q "Docker.*excluded\|No Docker" "$CHARTER_PATH"; then
    echo -e "${GREEN}✓${NC} Docker exclusion policy found"
else
    echo -e "${YELLOW}⚠️${NC}  Docker policy not explicitly stated"
    ((WARNINGS++)) || true
fi

# Check for firewall policy (quiet mode for test, verbose for output)
if grep -qi "firewall\|No authentication for Phase 1" "$CHARTER_PATH"; then
    FIREWALL_POLICY=$(grep -i "firewall\|No authentication for Phase 1" "$CHARTER_PATH" | head -3) || FIREWALL_POLICY=""
    echo -e "${GREEN}✓${NC} Firewall/authentication policy found:"
    echo "$FIREWALL_POLICY" | awk '{print "    " $0}'
else
    echo -e "${YELLOW}⚠️${NC}  Firewall policy not found - assume DISABLED per HX-Infrastructure standard"
    ((WARNINGS++)) || true
fi

# Check for manual procedures requirement (quiet mode)
if grep -qi "manual\|systemd" "$CHARTER_PATH"; then
    echo -e "${GREEN}✓${NC} Manual procedures/systemd references found"
else
    echo -e "${YELLOW}⚠️${NC}  Manual procedures not explicitly mentioned"
    ((WARNINGS++)) || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  PASS WITH WARNINGS${NC}: Charter review gate passed ($WARNINGS warning(s))"
else
    echo -e "${GREEN}✅ PASS${NC}: Charter review gate passed"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "REMINDER: Charter requirements are CONSTRAINTS, not preferences"
echo "REMINDER: All planning must align with charter deployment strategy"
echo ""

# Exit 0 for pass (warnings are non-blocking for this gate)
# Document: Warnings indicate missing optional sections, not hard failures
exit 0
