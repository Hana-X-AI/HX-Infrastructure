# Test Case: Verify Log Output Validation

**Test ID**: tc-lang-server-health-007-log-output-validation
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: NFR-003 (Structured JSON logging)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the service produces properly formatted structured JSON logs with required fields.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Access to journald logs

---

## Test Steps

### Step 1: Retrieve Recent Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" -n 20 --no-pager
```

**Expected Behavior:**
Log entries displayed.

---

### Step 2: Verify JSON Format
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" -n 5 -o cat | head -1 | jq '.' 2>/dev/null && echo "JSON: Valid" || echo "JSON: Invalid or not JSON"
```

**Expected Behavior:**
Logs are valid JSON (or structured format).

---

### Step 3: Verify Required Log Fields
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" -n 1 -o cat | jq 'keys' 2>/dev/null || echo "Check log fields manually"
```

**Expected Behavior:**
Logs contain timestamp, level, message, and context fields.

---

### Step 4: Verify Log Levels Present
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "1 hour ago" -o cat | grep -oE '"level":"[^"]+"' | sort | uniq -c
```

**Expected Behavior:**
Multiple log levels present (INFO, DEBUG, WARN, ERROR).

---

### Step 5: Verify No Unhandled Exceptions in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "1 hour ago" | grep -iE "traceback|exception|error.*unhandled" | head -5 || echo "No unhandled exceptions found"
```

**Expected Behavior:**
No unhandled exceptions or tracebacks.

---

## Expected Results

- [ ] Logs are being generated
- [ ] JSON/structured format used
- [ ] Required fields present
- [ ] Multiple log levels used
- [ ] No unhandled exceptions

---

## Pass/Fail Criteria

### PASS Criteria
1. Structured log format
2. Required fields present
3. No unhandled exceptions

### FAIL Criteria
1. Plain text logs only
2. Missing required fields
3. Unhandled exceptions present

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
