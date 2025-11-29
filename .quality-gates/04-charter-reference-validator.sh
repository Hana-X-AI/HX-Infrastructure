#!/bin/bash
# Quality Gate 4: Charter Reference Requirement
# Ensures planning documents reference charter decisions
# Based on Julia Santos recommendations - Round 5 violation prevention

set -euo pipefail

# Configuration
DOCUMENT="${1:-}"
CHARTER_PATH="${2:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUALITY GATE 4: Charter Reference Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if document provided
if [[ -z "$DOCUMENT" ]]; then
    echo -e "${RED}❌ FAIL${NC}: No document provided"
    echo "Usage: $0 <document> <charter-path>"
    exit 1
fi

# Check if charter path provided
if [[ -z "$CHARTER_PATH" ]]; then
    echo -e "${RED}❌ FAIL${NC}: No charter path provided"
    exit 1
fi

# Check if files exist
if [[ ! -f "$DOCUMENT" ]]; then
    echo -e "${RED}❌ FAIL${NC}: Document not found: $DOCUMENT"
    exit 1
fi

if [[ ! -f "$CHARTER_PATH" ]]; then
    echo -e "${RED}❌ FAIL${NC}: Charter not found: $CHARTER_PATH"
    exit 1
fi

VIOLATIONS=0

echo "Document: $DOCUMENT"
echo "Charter: $CHARTER_PATH"
echo ""

# Check 1: Charter is referenced in document
echo "1. Checking for charter references..."
if grep -qi "charter" "$DOCUMENT"; then
    CHARTER_REFS=$(grep -ic "charter" "$DOCUMENT")
    echo -e "${GREEN}✓${NC} Charter referenced $CHARTER_REFS time(s)"
else
    echo -e "${RED}❌ VIOLATION${NC}: No charter references found"
    echo "  Planning documents MUST reference charter decisions"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check 2: Charter path is mentioned
echo ""
echo "2. Checking for explicit charter path reference..."
CHARTER_FILENAME=$(basename "$CHARTER_PATH")
if grep -q "$CHARTER_FILENAME" "$DOCUMENT"; then
    echo -e "${GREEN}✓${NC} Charter path/filename referenced"
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Charter path/filename not explicitly mentioned"
    echo "  Consider adding explicit reference for traceability"
fi

# Check 3: Key charter decisions referenced
echo ""
echo "3. Checking for key charter decision references..."

REQUIRED_TOPICS=0
FOUND_TOPICS=0

# Check for deployment strategy reference
if grep -qiE "bare.metal|systemd|manual.*deploy" "$DOCUMENT"; then
    echo -e "${GREEN}✓${NC} Deployment strategy referenced"
    FOUND_TOPICS=$((FOUND_TOPICS + 1))
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Deployment strategy not explicitly referenced"
fi
REQUIRED_TOPICS=$((REQUIRED_TOPICS + 1))

# Check for Docker exclusion
if grep -qiE "no.*docker|docker.*excluded|docker.*dev.only" "$DOCUMENT"; then
    echo -e "${GREEN}✓${NC} Docker exclusion policy referenced"
    FOUND_TOPICS=$((FOUND_TOPICS + 1))
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Docker policy not explicitly referenced"
fi
REQUIRED_TOPICS=$((REQUIRED_TOPICS + 1))

# Check for service account/identity
if grep -qiE "samba|service.*account|domain.*account|identity" "$DOCUMENT"; then
    echo -e "${GREEN}✓${NC} Identity/service account referenced"
    FOUND_TOPICS=$((FOUND_TOPICS + 1))
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Identity/service account not referenced"
fi
REQUIRED_TOPICS=$((REQUIRED_TOPICS + 1))

# Calculate coverage
if [[ $REQUIRED_TOPICS -gt 0 ]]; then
    COVERAGE=$((FOUND_TOPICS * 100 / REQUIRED_TOPICS))
    echo ""
    echo "Charter decision coverage: $FOUND_TOPICS/$REQUIRED_TOPICS ($COVERAGE%)"

    if [[ $COVERAGE -lt 50 ]]; then
        echo -e "${RED}❌ VIOLATION${NC}: Low charter decision coverage (<50%)"
        VIOLATIONS=$((VIOLATIONS + 1))
    elif [[ $COVERAGE -lt 75 ]]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: Moderate charter decision coverage (50-75%)"
    else
        echo -e "${GREEN}✓${NC} Good charter decision coverage (≥75%)"
    fi
fi

# Check 4: Charter status acknowledged
echo ""
echo "4. Checking for charter approval status acknowledgment..."
if grep -qiE "approved.*charter|charter.*approved" "$DOCUMENT"; then
    echo -e "${GREEN}✓${NC} Charter approval status acknowledged"
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Charter approval status not explicitly acknowledged"
    echo "  Consider adding: 'Based on approved charter dated YYYY-MM-DD'"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Charter reference validation passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo -e "${RED}❌ FAIL${NC}: Charter reference validation FAILED"
    echo "Total violations: $VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
