# Test Case: Verify Port Binding

**Test ID**: tc-lang-server-deployment-008-port-binding
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-021 (FastAPI on port 8100), Port Allocation table
**Based on Plan**: Work Stream 10 - FastAPI Application, Work Stream 13
**Test Type**: Manual
**Estimated Execution Time**: 3 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the hx-lang-server service is bound to the correct ports: 8100 (FastAPI HTTP API) and 8101 (Health/Metrics endpoint) and is accessible from the network.

**Why This Test Is Important:**
Correct port binding is essential for service accessibility. Other services and clients depend on connecting to the documented ports.

---

## Prerequisites

**Service State:**
- [ ] Service running (deployment-004 passed or in progress)

**Dependencies:**
- [ ] Network accessible

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] Standard user access

---

## Test Setup

### Pre-Test Actions
1. Ensure service is running
2. Prepare network testing tools

### Test Data
**Required Test Data:**
- API Port: 8100
- Health/Metrics Port: 8101
- IP: 192.168.10.226

---

## Test Steps

### Step 1: Verify Port 8100 is Listening
**Action:**
```bash
ss -tlnp | grep :8100
```

**Expected Behavior:**
Port 8100 is listening on 0.0.0.0 or specific IP.

**How to Verify:**
Output shows LISTEN state on port 8100.

---

### Step 2: Verify Port 8101 is Listening
**Action:**
```bash
ss -tlnp | grep :8101
```

**Expected Behavior:**
Port 8101 is listening for health/metrics.

**How to Verify:**
Output shows LISTEN state on port 8101.

---

### Step 3: Verify Process Binding
**Action:**
```bash
sudo lsof -i :8100 -i :8101 | grep LISTEN
```

**Expected Behavior:**
Uvicorn process is bound to both ports.

**How to Verify:**
Output shows uvicorn or python process listening on ports.

---

### Step 4: Test Local API Access
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/health
```

**Expected Behavior:**
Returns HTTP 200 status code.

**How to Verify:**
Output is "200".

---

### Step 5: Test Local Health Port Access
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8101/health
```

**Expected Behavior:**
Returns HTTP 200 status code from health port.

**How to Verify:**
Output is "200".

---

### Step 6: Test Network Access on API Port
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://192.168.10.226:8100/health
```

**Expected Behavior:**
Port accessible via network IP.

**How to Verify:**
Output is "200".

---

### Step 7: Verify No Port Conflicts
**Action:**
```bash
ss -tlnp | grep -E ":8100|:8101" | wc -l
```

**Expected Behavior:**
Exactly 2 listeners (one per port).

**How to Verify:**
Output is "2" (no duplicate bindings).

---

### Step 8: Verify Binding User
**Action:**
```bash
sudo ss -tlnp | grep :8100 | grep -o "users:.*"
```

**Expected Behavior:**
Process is running under hx-lang-server user.

**How to Verify:**
Process visible in output.

---

## Expected Results

### Primary Expected Results
- [ ] Port 8100 is listening (API)
- [ ] Port 8101 is listening (Health/Metrics)
- [ ] Bound to 0.0.0.0 or 192.168.10.226
- [ ] Uvicorn process owns the ports
- [ ] Both ports accessible locally
- [ ] Both ports accessible via network IP
- [ ] No port conflicts

### Observable Indicators
**Network:**
- ss/netstat shows both ports LISTENING
- curl returns 200 on both ports

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Port 8100 is listening
2. Port 8101 is listening
3. Ports accessible locally (localhost)
4. Ports accessible via network IP
5. Correct process owns ports
6. No port conflicts

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Port 8100 not listening
2. Port 8101 not listening
3. Ports not accessible
4. Wrong process binding
5. Port conflicts detected
6. Connection refused on network access

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. Cannot access network

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
1. No cleanup required

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Requires service to be running (deployment-004)
- Related to health check tests

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Port Allocation table, FR-021

**Related Test Cases:**
- `tc-lang-server-deployment-004-service-startup.md` - Prerequisite
- `tc-lang-server-health-001-endpoint.md` - Uses these ports

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
