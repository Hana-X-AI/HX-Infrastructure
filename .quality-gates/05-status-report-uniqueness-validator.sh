#!/bin/bash
# Quality Gate 5: Status Report Uniqueness Validator
# Ensures only ONE status-report.md exists at program root
# Based on Julia Santos recommendations - Round 4 violation prevention

set -euo pipefail

# Configuration
# Accept PROJECT_ROOT from environment variable, command-line argument, or derive from script location
if [[ $# -gt 0 ]]; then
    PROJECT_ROOT="$1"
else
    : "${PROJECT_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUALITY GATE 5: Status Report Uniqueness Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VIOLATIONS=0

# Check 1: status-report.md exists at program root
echo "1. Checking for status-report.md at program root..."
if [[ -f "$PROJECT_ROOT/status-report.md" ]]; then
    echo -e "${GREEN}✓${NC} Found: $PROJECT_ROOT/status-report.md"
else
    echo -e "${RED}❌ VIOLATION${NC}: status-report.md missing from program root"
    echo "  Expected location: $PROJECT_ROOT/status-report.md"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check 2: No status-report.md files in subdirectories
echo ""
echo "2. Checking for duplicate status-report.md files..."
DUPLICATES=$(find "$PROJECT_ROOT" -name "status-report.md" -type f | wc -l)

if [[ $DUPLICATES -eq 0 ]]; then
    echo -e "${RED}❌ VIOLATION${NC}: No status-report.md found anywhere"
    VIOLATIONS=$((VIOLATIONS + 1))
elif [[ $DUPLICATES -eq 1 ]]; then
    echo -e "${GREEN}✓${NC} Only one status-report.md exists"
else
    echo -e "${RED}❌ VIOLATION${NC}: Multiple status-report.md files found ($DUPLICATES instances)"
    echo "  Locations:"
    find "$PROJECT_ROOT" -name "status-report.md" -type f | sed 's/^/    /'
    echo ""
    echo "  REQUIRED: Only ONE status-report.md at program root"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check 3: No status-reports/ directory
echo ""
echo "3. Checking for prohibited status-reports/ directory..."
if [[ -d "$PROJECT_ROOT/status-reports" ]]; then
    echo -e "${RED}❌ VIOLATION${NC}: status-reports/ directory exists"
    echo "  Location: $PROJECT_ROOT/status-reports/"
    echo "  REQUIRED: Use single status-report.md at program root, NOT directory"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No status-reports/ directory"
fi

# Check 4: Validate status-report.md content (if exists)
if [[ -f "$PROJECT_ROOT/status-report.md" ]]; then
    echo ""
    echo "4. Validating status-report.md content structure..."

    # Check for required sections
    REQUIRED_SECTIONS=(
        "Executive Summary"
        "Current.*Status"
        "Blockers"
        "Next Steps"
    )

    MISSING_SECTIONS=()
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! grep -qiE "^#{1,3}.*$section" "$PROJECT_ROOT/status-report.md"; then
            MISSING_SECTIONS+=("$section")
        fi
    done

    if [[ ${#MISSING_SECTIONS[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} All required sections present"
    else
        echo -e "${YELLOW}⚠️  WARN${NC}: Missing recommended sections:"
        for section in "${MISSING_SECTIONS[@]}"; do
            echo "    - $section"
        done
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Status report uniqueness validation passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo -e "${RED}❌ FAIL${NC}: Status report uniqueness validation FAILED"
    echo "Total violations: $VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
