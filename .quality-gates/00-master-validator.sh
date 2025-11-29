#!/bin/bash
# Quality Gate 0: Master Pre-Response Validator
# Runs all quality gates in sequence before response
# Based on Julia Santos recommendations - Complete validation suite

set -euo pipefail

# Configuration
GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="/home/agent0/HX-Infrastructure"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
CHARTER_PATH=""
CONTENT_FILE=""
RESPONSE_CONTEXT="general"

while [[ $# -gt 0 ]]; do
    case $1 in
        --charter)
            CHARTER_PATH="$2"
            shift 2
            ;;
        --content)
            CONTENT_FILE="$2"
            shift 2
            ;;
        --context)
            RESPONSE_CONTEXT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--charter PATH] [--content FILE] [--context CONTEXT]"
            exit 1
            ;;
    esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}MASTER PRE-RESPONSE VALIDATOR${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Context: $RESPONSE_CONTEXT"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

TOTAL_GATES=0
PASSED_GATES=0
FAILED_GATES=0
SKIPPED_GATES=0

# Gate 1: Charter Review (if charter path provided)
TOTAL_GATES=$((TOTAL_GATES + 1))
echo -e "${BLUE}Running Gate 1/5: Charter Review${NC}"
if [[ -n "$CHARTER_PATH" && -f "$CHARTER_PATH" ]]; then
    if bash "$GATE_DIR/01-charter-review-gate.sh" "$CHARTER_PATH" "$RESPONSE_CONTEXT"; then
        PASSED_GATES=$((PASSED_GATES + 1))
    else
        FAILED_GATES=$((FAILED_GATES + 1))
        echo -e "${RED}Gate 1 FAILED${NC}"
    fi
else
    echo -e "${YELLOW}SKIPPED: No charter path provided${NC}"
    SKIPPED_GATES=$((SKIPPED_GATES + 1))
fi
echo ""

# Gate 2: Infrastructure Philosophy (if content file provided)
TOTAL_GATES=$((TOTAL_GATES + 1))
echo -e "${BLUE}Running Gate 2/5: Infrastructure Philosophy${NC}"
if [[ -n "$CONTENT_FILE" && -f "$CONTENT_FILE" ]]; then
    if bash "$GATE_DIR/02-infrastructure-philosophy-gate.sh" "$CONTENT_FILE"; then
        PASSED_GATES=$((PASSED_GATES + 1))
    else
        FAILED_GATES=$((FAILED_GATES + 1))
        echo -e "${RED}Gate 2 FAILED${NC}"
    fi
else
    echo -e "${YELLOW}SKIPPED: No content file provided${NC}"
    SKIPPED_GATES=$((SKIPPED_GATES + 1))
fi
echo ""

# Gate 3: File Location (if content file provided)
TOTAL_GATES=$((TOTAL_GATES + 1))
echo -e "${BLUE}Running Gate 3/5: File Location & Naming${NC}"
if [[ -n "$CONTENT_FILE" && -f "$CONTENT_FILE" ]]; then
    if bash "$GATE_DIR/03-file-location-validator.sh" "$CONTENT_FILE"; then
        PASSED_GATES=$((PASSED_GATES + 1))
    else
        FAILED_GATES=$((FAILED_GATES + 1))
        echo -e "${RED}Gate 3 FAILED${NC}"
    fi
else
    echo -e "${YELLOW}SKIPPED: No content file provided${NC}"
    SKIPPED_GATES=$((SKIPPED_GATES + 1))
fi
echo ""

# Gate 4: Charter Reference (if both charter and content provided)
TOTAL_GATES=$((TOTAL_GATES + 1))
echo -e "${BLUE}Running Gate 4/5: Charter Reference${NC}"
if [[ -n "$CHARTER_PATH" && -f "$CHARTER_PATH" && -n "$CONTENT_FILE" && -f "$CONTENT_FILE" ]]; then
    if bash "$GATE_DIR/04-charter-reference-validator.sh" "$CONTENT_FILE" "$CHARTER_PATH"; then
        PASSED_GATES=$((PASSED_GATES + 1))
    else
        FAILED_GATES=$((FAILED_GATES + 1))
        echo -e "${RED}Gate 4 FAILED${NC}"
    fi
else
    echo -e "${YELLOW}SKIPPED: Requires both charter and content file${NC}"
    SKIPPED_GATES=$((SKIPPED_GATES + 1))
fi
echo ""

# Gate 5: Status Report Uniqueness (always run)
TOTAL_GATES=$((TOTAL_GATES + 1))
echo -e "${BLUE}Running Gate 5/5: Status Report Uniqueness${NC}"
if bash "$GATE_DIR/05-status-report-uniqueness-validator.sh"; then
    PASSED_GATES=$((PASSED_GATES + 1))
else
    FAILED_GATES=$((FAILED_GATES + 1))
    echo -e "${RED}Gate 5 FAILED${NC}"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}VALIDATION SUMMARY${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Gates: $TOTAL_GATES"
echo -e "Passed: ${GREEN}$PASSED_GATES${NC}"
echo -e "Failed: ${RED}$FAILED_GATES${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED_GATES${NC}"
echo ""

if [[ $FAILED_GATES -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL ACTIVE GATES PASSED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo "Fix violations before proceeding with response"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
