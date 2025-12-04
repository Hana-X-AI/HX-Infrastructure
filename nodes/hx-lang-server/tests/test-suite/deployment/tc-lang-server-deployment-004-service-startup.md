# Test Case: Verify Service Startup

**Test ID**: tc-lang-server-deployment-004-service-startup
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: NFR-003 (Service startup time <30 seconds), SC-010 (Health endpoint returns 200)
**Based on Plan**: Work Stream 13 - Service Deployment (Task 143-144)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the hx-lang-server systemd service starts successfully within 30 seconds and reaches a healthy state with the API responding on port 8100.

**Why This Test Is Important:**
Service startup is a critical deployment milestone. The service must start reliably and within the SLA time to ensure operational readiness and rapid recovery from restarts.

---

## Prerequisites

**Service State:**
- [ ] Service installed but may be stopped
- [ ] All dependencies installed (deployment-006 passed)
- [ ] Configuration complete (deployment-007 passed)

**Dependencies:**
- [ ] PostgreSQL accessible
- [ ] Redis accessible
- [ ] Ollama servers accessible (optional for startup)

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local
- [ ] sudo access for service management

**Permissions:**
- [ ] sudo access required

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection to target node
2. Ensure service is stopped before test
3. Prepare to time startup duration

### Test Data
**Required Test Data:**
- Service name: `hx-lang-server`
- Expected port: 8100
- Maximum startup time: 30 seconds
- Health endpoint: `http://localhost:8100/health`

---

## Test Steps

### Step 1: Ensure Service is Stopped
**Action:**
```bash
sudo systemctl stop hx-lang-server 2>/dev/null || true
sleep 2
sudo systemctl status hx-lang-server | grep -E "Active:|inactive"
```

**Expected Behavior:**
Service is stopped or shows inactive state.

**How to Verify:**
Status shows "inactive (dead)" or service does not exist yet.

---

### Step 2: Start Service and Time Startup
**Action:**
```bash
START_TIME=$(date +%s)
sudo systemctl start hx-lang-server
while ! curl -s http://localhost:8100/health > /dev/null 2>&1; do
    sleep 1
    ELAPSED=$(($(date +%s) - START_TIME))
    if [ $ELAPSED -gt 35 ]; then
        echo "Timeout waiting for service"
        break
    fi
done
END_TIME=$(date +%s)
echo "Startup time: $((END_TIME - START_TIME)) seconds"
```

**Expected Behavior:**
Service starts and health endpoint responds within 30 seconds.

**How to Verify:**
Startup time is <= 30 seconds.

---

### Step 3: Verify Service Status
**Action:**
```bash
sudo systemctl status hx-lang-server | head -15
```

**Expected Behavior:**
Service shows "active (running)" status.

**How to Verify:**
Output contains "Active: active (running)".

---

### Step 4: Verify Health Endpoint
**Action:**
```bash
curl -s http://localhost:8100/health | jq .
```

**Expected Behavior:**
Health endpoint returns JSON with status field.

**How to Verify:**
Response contains "status" field with value "healthy" or "degraded".

---

### Step 5: Verify Process Running
**Action:**
```bash
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep
```

**Expected Behavior:**
Uvicorn process is running under hx-lang-server user.

**How to Verify:**
Process visible in output with correct user.

---

### Step 6: Verify No Startup Errors in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "error|exception|fail" | head -10
```

**Expected Behavior:**
No critical errors in startup logs.

**How to Verify:**
No ERROR or EXCEPTION lines in recent logs (or empty output).

---

## Expected Results

### Primary Expected Results
- [ ] Service starts within 30 seconds (NFR-003)
- [ ] Service status is "active (running)"
- [ ] Health endpoint returns 200 OK
- [ ] Process running under correct user
- [ ] No startup errors in logs

### Observable Indicators
**Logs:**
- Journal shows successful startup messages
- No ERROR level entries during startup

**Process Status:**
- Uvicorn process running
- Port 8100 listening

**Network:**
- Port 8100 bound and responding

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Service starts within 30 seconds
2. systemctl status shows "active (running)"
3. Health endpoint returns valid JSON
4. Process is running
5. No critical errors in startup logs

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Service fails to start
2. Startup takes > 30 seconds
3. Health endpoint not responding
4. Critical errors in logs
5. Service crashes after startup

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service unit file not installed
2. Dependencies not installed
3. Configuration files missing

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

**Measured Startup Time**: [X] seconds

---

## Test Cleanup

### Post-Test Actions
1. Leave service running for subsequent tests

### Environment Reset
- [ ] Service left in running state

---

## Notes and Observations

### Dependencies on Other Tests
- Requires deployment-001 through deployment-007 to pass
- Required for all functionality and integration tests

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - NFR-003 (Startup time), systemd Service Configuration

**Related Test Cases:**
- `tc-lang-server-health-001-endpoint.md` - Related health check test
- `tc-lang-server-deployment-009-systemd-service.md` - Service unit verification

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
