# Test Case: Log Rotation Configuration

**Test ID**: tc-docling-mcp-deployment-010
**Test Area**: Deployment Validation
**Priority**: MEDIUM
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify log rotation is configured for daily rotation with 30-day retention.

---

## Test Steps

### Step 1: Verify Log Rotation Configuration

**Action**:
```bash
test -f /etc/logrotate.d/docling-mcp && echo "PASS: logrotate config exists"
cat /etc/logrotate.d/docling-mcp
```

**Expected**: Configuration file exists

---

### Step 2: Verify Rotation Policy

**Action**:
```bash
grep -q "daily" /etc/logrotate.d/docling-mcp && echo "PASS: daily rotation"
grep -q "rotate 30" /etc/logrotate.d/docling-mcp && echo "PASS: 30-day retention"
grep -q "compress" /etc/logrotate.d/docling-mcp && echo "PASS: compression enabled"
```

**Expected**: Daily rotation, 30-day retention, compression enabled

---

## Pass/Fail Criteria

**PASS**: Log rotation configured correctly

**FAIL**: Configuration missing or incorrect

---

**Test Case Version**: 1.0
