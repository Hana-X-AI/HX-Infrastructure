#!/bin/bash
# Quality Gate 3: File Location and Naming Validator
# Ensures files are created in correct locations with correct names
# Based on Julia Santos recommendations - Round 1, 2, 4 violation prevention

set -euo pipefail

# Configuration
FILE_PATH="${1:-}"
EXPECTED_LOCATION="${2:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUALITY GATE 3: File Location & Naming Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if file path provided
if [[ -z "$FILE_PATH" ]]; then
    echo -e "${RED}❌ FAIL${NC}: No file path provided"
    echo "Usage: $0 <file-path> [expected-location]"
    exit 1
fi

VIOLATIONS=0

echo "Validating: $FILE_PATH"
echo ""

# Extract components
FILENAME=$(basename "$FILE_PATH")
DIRNAME=$(dirname "$FILE_PATH")
EXTENSION="${FILENAME##*.}"

# Check 1: File exists
echo "1. Checking file existence..."
if [[ -f "$FILE_PATH" ]]; then
    echo -e "${GREEN}✓${NC} File exists: $FILE_PATH"
else
    echo -e "${RED}❌ FAIL${NC}: File does not exist: $FILE_PATH"
    exit 1
fi

# Check 2: Location validation (if expected location provided)
echo ""
echo "2. Checking file location..."
if [[ -n "$EXPECTED_LOCATION" ]]; then
    if [[ "$DIRNAME" == "$EXPECTED_LOCATION" || "$FILE_PATH" == "$EXPECTED_LOCATION"* ]]; then
        echo -e "${GREEN}✓${NC} File in correct location: $DIRNAME"
    else
        echo -e "${RED}❌ VIOLATION${NC}: File in wrong location"
        echo "  Expected: $EXPECTED_LOCATION"
        echo "  Actual: $DIRNAME"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIP${NC}: No expected location specified"
fi

# Check 3: Naming convention
echo ""
echo "3. Checking naming conventions..."

# Check for uppercase in filename (except acronyms)
# First check for two-or-more consecutive uppercase (acronym case)
if echo "$FILENAME" | grep -qE '[A-Z]{2,}'; then
    echo -e "${YELLOW}⚠️  WARN${NC}: Filename contains uppercase acronym: $FILENAME"
# Then check for any remaining single uppercase letters (violation)
elif echo "$FILENAME" | grep -qE '[A-Z]'; then
    echo -e "${RED}❌ VIOLATION${NC}: Filename contains uppercase: $FILENAME"
    echo "  Should use lowercase with hyphens"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} Filename uses lowercase"
fi

# Check for underscores (should use hyphens instead)
if echo "$FILENAME" | grep -q '_'; then
    # Define explicit underscore exceptions (patterns that are allowed)
    UNDERSCORE_EXCEPTIONS=(
        "vault_password"       # Ansible vault password files
        "vault-password"       # Alternative vault password pattern
        ".vault_password"      # Hidden vault password files
        "__pycache__"          # Python cache directories
        "__init__"             # Python package initialization
    )
    
    # Check if filename matches any exception pattern
    IS_EXCEPTION=false
    for exception in "${UNDERSCORE_EXCEPTIONS[@]}"; do
        if [[ "$FILENAME" == *"$exception"* ]]; then
            IS_EXCEPTION=true
            break
        fi
    done
    
    if [[ "$IS_EXCEPTION" == true ]]; then
        echo -e "${GREEN}✓${NC} Underscore allowed (matches exception pattern)"
    else
        echo -e "${RED}❌ VIOLATION${NC}: Filename uses underscores: $FILENAME"
        echo "  Should use hyphens instead"
        echo "  Exceptions: ${UNDERSCORE_EXCEPTIONS[*]}"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
else
    echo -e "${GREEN}✓${NC} No underscores in filename"
fi

# Check 4: Prohibited locations
echo ""
echo "4. Checking for prohibited locations..."

# Dynamically resolve project root for portability
# Try git first (works in CI, containers, any working directory)
if PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    : # PROJECT_ROOT successfully set via git
else
    # Fallback: compute from script location (script is in .quality-gates/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
fi

# Check if file is in project root when it shouldn't be
if [[ "$DIRNAME" == "$PROJECT_ROOT" && "$EXTENSION" == "md" ]]; then
    # Allowed root files
    ALLOWED_ROOT_FILES=(
        "README.md"
        "CLAUDE.md"
        "constitution.md"
        "status-report.md"
        "lessons-learned.md"
        "backlog.md"
        "raidd-log.md"
        "defect-log.md"
    )

    IS_ALLOWED=false
    for allowed in "${ALLOWED_ROOT_FILES[@]}"; do
        if [[ "$FILENAME" == "$allowed" ]]; then
            IS_ALLOWED=true
            break
        fi
    done

    if [[ "$IS_ALLOWED" == "false" ]]; then
        echo -e "${RED}❌ VIOLATION${NC}: Markdown file in project root (should be in subdirectory)"
        echo "  File: $FILENAME"
        echo "  Allowed root files: ${ALLOWED_ROOT_FILES[*]}"
        VIOLATIONS=$((VIOLATIONS + 1))
    else
        echo -e "${GREEN}✓${NC} File allowed in project root"
    fi
else
    echo -e "${GREEN}✓${NC} File location appropriate"
fi

# Check 5: Duplicate files
echo ""
echo "5. Checking for duplicate filenames..."

# Define exclude paths to prevent false positives from build/vendor/archive dirs
EXCLUDE_PATHS=(
    ".git"
    "node_modules"
    ".venv"
    "venv"
    "build"
    "dist"
    "__pycache__"
    ".pytest_cache"
    "x-archive"
    "x-claude"
    "x-files"
    ".quality-gates"
)

# Build find exclusion arguments
FIND_EXCLUDE_ARGS=()
for exclude_path in "${EXCLUDE_PATHS[@]}"; do
    FIND_EXCLUDE_ARGS+=(-not -path "*/$exclude_path/*")
done

# Count duplicates excluding common directories
DUPLICATES=$(find "$PROJECT_ROOT" -name "$FILENAME" -type f "${FIND_EXCLUDE_ARGS[@]}" | wc -l)
if [[ $DUPLICATES -gt 1 ]]; then
    echo -e "${RED}❌ VIOLATION${NC}: Multiple files with same name found ($DUPLICATES instances)"
    echo "  Duplicate locations:"
    find "$PROJECT_ROOT" -name "$FILENAME" -type f "${FIND_EXCLUDE_ARGS[@]}" | sed 's/^/    /'
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}✓${NC} No duplicate filenames"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✅ PASS${NC}: File location and naming validation passed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo -e "${RED}❌ FAIL${NC}: File location and naming validation FAILED"
    echo "Total violations: $VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
