#!/bin/bash
# Quality Gate 2: Infrastructure Philosophy Validator
# Scans content for prohibited automation patterns
# Based on Julia Santos recommendations - Round 3 & Round 5 violation prevention

set -euo pipefail

# Configuration
CONTENT_FILE="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUALITY GATE 2: Infrastructure Philosophy Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if content file provided
if [[ -z "$CONTENT_FILE" ]]; then
    echo -e "${RED}❌ FAIL${NC}: No content file provided"
    echo "Usage: $0 <content-file>"
    exit 1
fi

# Check if file exists
if [[ ! -f "$CONTENT_FILE" ]]; then
    echo -e "${RED}❌ FAIL${NC}: Content file not found: $CONTENT_FILE"
    exit 1
fi

VIOLATIONS=0

echo "Scanning for prohibited patterns..."
echo ""

# Prohibited Pattern 1: Ansible playbooks
echo "1. Checking for Ansible playbook references..."
if grep -iE "ansible.*playbook|playbook.*ansible" "$CONTENT_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION${NC}: Ansible playbook references found:"
    grep -inE "ansible.*playbook|playbook.*ansible" "$CONTENT_FILE" | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No Ansible playbook references"
fi

# Prohibited Pattern 2: Deployment scripts
echo ""
echo "2. Checking for deployment script automation..."
if grep -iE "deployment.*script|script.*deploy|automated.*deployment|deployment.*automation" "$CONTENT_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION${NC}: Deployment script/automation references found:"
    grep -inE "deployment.*script|script.*deploy|automated.*deployment|deployment.*automation" "$CONTENT_FILE" | sed 's/^/    /'
    echo -e "  ${YELLOW}NOTE${NC}: 'Manual deployment' = documented manual procedures, NOT scripts"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No deployment script/automation references"
fi

# Prohibited Pattern 3: Firewall configuration
echo ""
echo "3. Checking for firewall configuration tasks..."
if grep -iE "firewall.*config|configure.*firewall|firewall.*script|firewall.*rule" "$CONTENT_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION${NC}: Firewall configuration references found:"
    grep -inE "firewall.*config|configure.*firewall|firewall.*script|firewall.*rule" "$CONTENT_FILE" | sed 's/^/    /'
    echo -e "  ${YELLOW}NOTE${NC}: ALL HX-Infrastructure firewalls are DISABLED"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No firewall configuration references"
fi

# Prohibited Pattern 4: Backup automation
echo ""
echo "4. Checking for backup automation..."
if grep -iE "backup.*automation|automated.*backup|backup.*script|backup.*timer|backup.*cron" "$CONTENT_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION${NC}: Backup automation references found:"
    grep -inE "backup.*automation|automated.*backup|backup.*script|backup.*timer|backup.*cron" "$CONTENT_FILE" | sed 's/^/    /'
    echo -e "  ${YELLOW}NOTE${NC}: Backups should be manual procedures, NOT automated"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No backup automation references"
fi

# Prohibited Pattern 5: General automation
echo ""
echo "5. Checking for general automation patterns..."
if grep -iE "automate|automation|automated" "$CONTENT_FILE" | grep -viE "automation.*excluded|no.*automation" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  WARN${NC}: General automation references found (review required):"
    grep -inE "automate|automation|automated" "$CONTENT_FILE" | grep -viE "automation.*excluded|no.*automation" | head -5 | sed 's/^/    /'
    echo -e "  ${YELLOW}NOTE${NC}: Verify these are documentation/exclusion statements, NOT proposals"
fi

# Prohibited Pattern 6: Docker in production/staging
echo ""
echo "6. Checking for Docker deployment references..."
if grep -iE "docker.*deploy|deploy.*docker|docker.*production|docker.*container" "$CONTENT_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION${NC}: Docker deployment references found:"
    grep -inE "docker.*deploy|deploy.*docker|docker.*production|docker.*container" "$CONTENT_FILE" | sed 's/^/    /'
    echo -e "  ${YELLOW}NOTE${NC}: Docker is dev-only, NOT for production/staging"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No Docker deployment references"
fi

# Prohibited Pattern 7: systemd timers for automation
echo ""
echo "7. Checking for systemd timer automation..."
if grep -iE "systemd.*timer|timer.*automation|\.timer|cron.*job" "$CONTENT_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ VIOLATION${NC}: Systemd timer/cron automation found:"
    grep -inE "systemd.*timer|timer.*automation|\.timer|cron.*job" "$CONTENT_FILE" | sed 's/^/    /'
    echo -e "  ${YELLOW}NOTE${NC}: Use manual procedures, NOT automated timers/cron"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No systemd timer/cron automation references"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Infrastructure philosophy validation passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo -e "${RED}❌ FAIL${NC}: Infrastructure philosophy validation FAILED"
    echo "Total violations: $VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
