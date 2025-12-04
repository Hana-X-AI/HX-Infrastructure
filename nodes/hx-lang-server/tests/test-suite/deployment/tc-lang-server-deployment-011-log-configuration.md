# Test Case: Verify Log Configuration

**Test ID**: tc-lang-server-deployment-011-log-configuration
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Monitoring & Observability - Logging section
**Based on Plan**: Work Stream 12 - Logging & Monitoring (Tasks 131-133)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that logging is correctly configured with structlog for structured logging, logs are written to the correct directory, and log rotation is configured to prevent disk exhaustion.

**Why This Test Is Important:**
Proper logging is essential for debugging, monitoring, and operational visibility. Without rotation, logs can fill the disk and cause service failures.

---

## Prerequisites

**Service State:**
- [ ] Service running (deployment-004 passed)
- [ ] Directory structure created (deployment-003 passed)

**Dependencies:**
- [ ] journald running for systemd logs

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] sudo access for journalctl

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection
2. Verify service is running

### Test Data
**Required Test Data:**
- Log directory: /opt/hx-lang-server/logs
- Expected log format: JSON (structured)
- Log rotation: configured

---

## Test Steps

### Step 1: Verify Log Directory Exists
**Action:**
```bash
ls -ld /opt/hx-lang-server/logs
```

**Expected Behavior:**
Log directory exists with correct ownership.

**How to Verify:**
Directory exists, owned by hx-lang-server.

---

### Step 2: Verify Log Directory Writable
**Action:**
```bash
sudo -u hx-lang-server touch /opt/hx-lang-server/logs/test-write.tmp && rm /opt/hx-lang-server/logs/test-write.tmp && echo "Writable"
```

**Expected Behavior:**
Service user can write to log directory.

**How to Verify:**
"Writable" message displayed.

---

### Step 3: Check journald Logs Available
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" | head -5
```

**Expected Behavior:**
Journal contains recent service logs.

**How to Verify:**
Log entries are visible (or service just started).

---

### Step 4: Verify Structured Log Format
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" -o cat | head -10 | grep -E "^\{|level|event|timestamp"
```

**Expected Behavior:**
Logs appear in JSON/structured format.

**How to Verify:**
Output contains structured log entries or JSON.

---

### Step 5: Verify Log Levels Present
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "1 hour ago" | grep -iE "info|debug|warning|error" | head -5
```

**Expected Behavior:**
Log entries contain level information.

**How to Verify:**
Log entries show level indicators.

---

### Step 6: Check Log Rotation Configuration
**Action:**
```bash
ls -la /etc/logrotate.d/ | grep -E "hx-lang-server|hx-lang" || echo "Using journald rotation"
```

**Expected Behavior:**
Either logrotate config exists or using journald.

**How to Verify:**
Config file present or using journald (which has built-in rotation).

---

### Step 7: Verify journald Retention
**Action:**
```bash
grep -E "^SystemMaxUse=|^MaxRetentionSec=" /etc/systemd/journald.conf 2>/dev/null || echo "Using defaults"
```

**Expected Behavior:**
journald has reasonable retention settings.

**How to Verify:**
Either explicit settings or defaults (acceptable).

---

### Step 8: Check Application Log Files (if any)
**Action:**
```bash
ls -la /opt/hx-lang-server/logs/*.log 2>/dev/null || echo "No application log files (using journald)"
```

**Expected Behavior:**
Either log files exist or using journald exclusively.

**How to Verify:**
Files present or journald being used.

---

### Step 9: Verify No Log Errors on Startup
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "30 minutes ago" | grep -i "log.*error\|logging.*fail" | head -5
```

**Expected Behavior:**
No logging configuration errors.

**How to Verify:**
No matches (empty output) or non-critical warnings only.

---

### Step 10: Verify Log Contains Request Information
**Action:**
```bash
# Generate a request then check logs
curl -s http://localhost:8100/health > /dev/null
sleep 1
sudo journalctl -u hx-lang-server --since "1 minute ago" | grep -i "health\|request" | head -3
```

**Expected Behavior:**
Health check request appears in logs.

**How to Verify:**
Request logged with relevant details.

---

## Expected Results

### Primary Expected Results
- [ ] Log directory exists and is writable
- [ ] journald captures service logs
- [ ] Logs are in structured format (JSON)
- [ ] Log levels are properly recorded
- [ ] Log rotation is configured (logrotate or journald)
- [ ] No logging configuration errors
- [ ] Request information is logged

### Observable Indicators
**Logs:**
- Structured log entries visible in journald
- Log level information present

**Files:**
- Log directory accessible
- Rotation configured

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Log directory exists and is writable
2. journald logs available
3. Logs appear structured
4. Log rotation configured
5. No logging errors
6. Request logging functional

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Log directory missing or not writable
2. No logs being captured
3. Logging configuration errors
4. No rotation configured (disk fill risk)
5. Request information not logged

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. journald not running

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

---

## Test Cleanup

### Post-Test Actions
1. Remove any test files created

### Environment Reset
- [ ] Test files removed

---

## Notes and Observations

### Dependencies on Other Tests
- Requires deployment-003 (Directory Structure)
- Requires deployment-004 (Service Startup)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Monitoring & Observability - Logging section

**Related Test Cases:**
- `tc-lang-server-deployment-003-directory-structure.md` - Creates log directory
- `tc-lang-server-health-007-log-output.md` - Related log validation

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
