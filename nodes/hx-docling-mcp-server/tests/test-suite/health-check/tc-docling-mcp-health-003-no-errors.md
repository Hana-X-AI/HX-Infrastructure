# Test Case: Error-Free Operation

**Test ID**: tc-docling-mcp-health-003
**Test Area**: Health Check Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify no error conditions in service logs (ERROR/CRITICAL level).

---

## Test Coverage

**Requirements Covered**:
- FR-028: Write structured logs in JSON format
- NFR-013: Service MUST NOT log sensitive data

---

## Test Steps

### Step 1: Check for ERROR/CRITICAL Logs

**Action**:
```bash
# Check systemd journal for errors
sudo journalctl -u docling-mcp.service --since "1 hour ago" | grep -i "error\|critical" && echo "FAIL: Errors found" || echo "PASS: No errors"

# Check application log file
grep -i "\"level\":\"error\"\|\"level\":\"critical\"" /var/log/docling-mcp/docling-mcp.log && echo "FAIL: Errors in log" || echo "PASS: No errors in log"
```

**Expected**: No ERROR or CRITICAL level logs in past hour

**Pass Criteria**: Zero ERROR/CRITICAL logs

---

### Step 2: Check for Crash Events

**Action**:
```bash
# Check for service restarts
systemctl show docling-mcp.service -p NRestarts
```

**Expected**: NRestarts = 0 (no restarts since deployment)

---

### Step 3: Verify No Sensitive Data in Logs

**Action**:
```bash
# Check logs don't contain sensitive patterns
grep -E "password|api_key|secret|token" /var/log/docling-mcp/docling-mcp.log && echo "FAIL: Sensitive data in logs" || echo "PASS: No sensitive data"
```

**Expected**: No sensitive data patterns in logs

**Pass Criteria**: Log sanitization working

---

## Pass/Fail Criteria

**PASS**: No ERROR/CRITICAL logs, no crashes, no sensitive data leaked

**FAIL**: Errors present, crashes detected, or sensitive data in logs

---

## Defect Logging

**IF FAIL**: Create appropriate defect based on issue type

---

**Test Case Version**: 1.0
