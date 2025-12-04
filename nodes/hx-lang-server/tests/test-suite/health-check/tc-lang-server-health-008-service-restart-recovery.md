# Test Case: Verify Service Restart Recovery

**Test ID**: tc-lang-server-health-008-service-restart-recovery
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-002 (Service starts without errors), Operational stability
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the service recovers properly after a restart, reconnecting to all dependencies and resuming normal operation.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] sudo access for service restart
- [ ] All dependencies running

---

## Test Steps

### Step 1: Verify Service Running Before Restart
**Action:**
```bash
systemctl is-active hx-lang-server
curl -s -o /dev/null -w "%{http_code}" http://hx-lang-server.hx.dev.local:8101/health
```

**Expected Behavior:**
Service active, health returns 200.

---

### Step 2: Restart Service
**Action:**
```bash
sudo systemctl restart hx-lang-server
echo "Waiting 10 seconds for startup..."
sleep 10
```

**Expected Behavior:**
Restart command completes.

---

### Step 3: Verify Service Active After Restart
**Action:**
```bash
systemctl is-active hx-lang-server
```

**Expected Behavior:**
Returns `active`.

---

### Step 4: Verify Health After Restart
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-lang-server.hx.dev.local:8101/health
```

**Expected Behavior:**
Returns `200`.

---

### Step 5: Verify Dependencies Reconnected
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies'
```

**Expected Behavior:**
All dependencies show connected/healthy status.

---

### Step 6: Verify Functional After Restart
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello after restart"}' --max-time 60 | jq '.response[:100]'
```

**Expected Behavior:**
Query processed successfully.

---

## Expected Results

- [ ] Service restarts cleanly
- [ ] Health endpoint returns 200
- [ ] All dependencies reconnected
- [ ] Queries processed after restart

---

## Pass/Fail Criteria

### PASS Criteria
1. Service restarts successfully
2. Health returns 200 within 30s
3. Dependencies reconnected
4. Queries work after restart

### FAIL Criteria
1. Service fails to restart
2. Health check fails
3. Dependencies not reconnected
4. Queries fail after restart

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
