# Test Case: Filesystem Layout Validation

**Test ID**: tc-docling-mcp-deployment-006
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify complete filesystem structure matches deployment architecture specification.

---

## Test Coverage

**Requirements Covered**:
- DR-005: Filesystem layout correct
- Plan Section: Storage Configuration (lines 390-423)

---

## Test Steps

### Step 1: Verify Application Directory Structure

**Action**:
```bash
# Check all required directories exist
test -d /opt/docling-mcp && echo "PASS: /opt/docling-mcp exists"
test -d /opt/docling-mcp/venv && echo "PASS: venv directory exists"
test -d /opt/docling-mcp/application && echo "PASS: application directory exists"
test -d /opt/docling-mcp/backups && echo "PASS: backups directory exists"

# Check directory tree structure
tree -L 2 /opt/docling-mcp
```

**Expected**:
```
/opt/docling-mcp/
├── venv/
├── application/
│   └── docling_mcp/
├── backups/
└── config/
```

---

### Step 2: Verify Data Directory Structure

**Action**:
```bash
test -d /var/lib/docling-mcp && echo "PASS: /var/lib/docling-mcp exists"
test -d /var/lib/docling-mcp/cache && echo "PASS: cache directory exists"
test -d /var/lib/docling-mcp/workspace && echo "PASS: workspace directory exists"
test -d /var/lib/docling-mcp/lightrag && echo "PASS: lightrag directory exists"
```

**Expected**:
```
/var/lib/docling-mcp/
├── cache/
├── workspace/
└── lightrag/
```

---

### Step 3: Verify Log Directory Structure

**Action**:
```bash
test -d /var/log/docling-mcp && echo "PASS: /var/log/docling-mcp exists"
ls -la /var/log/docling-mcp/
```

**Expected**: `/var/log/docling-mcp/` directory exists

---

### Step 4: Verify Configuration Directory Structure

**Action**:
```bash
test -d /etc/docling-mcp && echo "PASS: /etc/docling-mcp exists"
test -f /etc/docling-mcp/.env && echo "PASS: .env file exists"
test -f /etc/docling-mcp/logging.conf && echo "PASS: logging.conf exists"
```

**Expected**:
```
/etc/docling-mcp/
├── .env
└── logging.conf
```

---

### Step 5: Verify Disk Space Allocation

**Action**:
```bash
# Check disk space usage
df -h /opt/docling-mcp | tail -1 | awk '{print "Application partition: " $4 " available"}'
df -h /var/lib/docling-mcp | tail -1 | awk '{print "Data partition: " $4 " available"}'
df -h /var/log/docling-mcp | tail -1 | awk '{print "Log partition: " $4 " available"}'

# Verify minimum space requirements
[ $(df /opt/docling-mcp | tail -1 | awk '{print $4}') -gt 524288 ] && echo "PASS: Application space ≥500MB"
[ $(df /var/lib/docling-mcp | tail -1 | awk '{print $4}') -gt 5242880 ] && echo "PASS: Data space ≥5GB"
[ $(df /var/log/docling-mcp | tail -1 | awk '{print $4}') -gt 1048576 ] && echo "PASS: Log space ≥1GB"
```

**Expected**:
- /opt/docling-mcp: ≥500MB available
- /var/lib/docling-mcp: ≥5GB available
- /var/log/docling-mcp: ≥1GB available

---

## Pass/Fail Criteria

**PASS**: All directories exist with adequate disk space

**FAIL**: Any directory missing or insufficient disk space

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-006-filesystem-incomplete.md`

---

**Test Case Version**: 1.0
