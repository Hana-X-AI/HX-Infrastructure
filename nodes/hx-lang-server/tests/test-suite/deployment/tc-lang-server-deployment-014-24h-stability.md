# Test Case: Verify 24h Service Stability

**Test ID**: tc-lang-server-deployment-014-24h-stability
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-014 (systemd service stable 24h)
**Based on Plan**: Work Stream 13 - Service Deployment (Task 144)
**Test Type**: Manual
**Estimated Execution Time**: 24 hours (observation period) + 30 minutes (validation)

---

## Test Objective

**What This Test Validates:**
Verifies that the hx-lang-server systemd service remains stable for 24 hours without crashes, restarts (unless intentional), memory leaks, or degraded performance. This validates long-term operational stability.

**Why This Test Is Important:**
A service that passes short-term tests but fails under sustained operation is not production-ready. This test validates stability under continuous operation.

---

## Prerequisites

**Service State:**
- [ ] Service running (deployment-004 passed)
- [ ] All other deployment tests passed

**Dependencies:**
- [ ] All external dependencies available
- [ ] Monitoring tools available (journalctl, systemctl)

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local
- [ ] 24-hour observation window available

**Permissions:**
- [ ] sudo access for log inspection

---

## Test Setup

### Pre-Test Actions
1. Record service start time
2. Record initial memory usage
3. Set up periodic health checks (optional)
4. Document initial service status

### Test Data
**Required Test Data:**
- Service name: hx-lang-server
- Observation period: 24 hours
- Success criteria: 0 unplanned restarts
- Maximum memory growth: <20% from baseline

---

## Test Steps

### Step 1: Record Baseline (T=0)
**Action:**
```bash
echo "=== BASELINE RECORDED $(date) ==="
echo "Service Status:"
sudo systemctl status hx-lang-server | head -10
echo ""
echo "Memory Usage:"
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep | awk '{print "RSS: " $6 "KB, VSZ: " $5 "KB"}'
echo ""
echo "Uptime:"
sudo systemctl show hx-lang-server --property=ActiveEnterTimestamp
```

**Expected Behavior:**
Baseline metrics recorded.

**How to Verify:**
All baseline values captured and documented.

---

### Step 2: Health Check at T+1 Hour
**Action:**
```bash
echo "=== HEALTH CHECK T+1H $(date) ==="
curl -s http://localhost:8100/health | jq .
sudo systemctl status hx-lang-server | grep "Active:"
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep | awk '{print "RSS: " $6 "KB"}'
```

**Expected Behavior:**
Service healthy, no restarts, memory stable.

**How to Verify:**
Health returns "healthy", Active shows running, memory within 20% of baseline.

---

### Step 3: Health Check at T+6 Hours
**Action:**
```bash
echo "=== HEALTH CHECK T+6H $(date) ==="
curl -s http://localhost:8100/health | jq .
sudo systemctl status hx-lang-server | grep -E "Active:|since"
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep | awk '{print "RSS: " $6 "KB"}'
sudo journalctl -u hx-lang-server --since "6 hours ago" | grep -iE "error|exception|restart|fail" | wc -l
```

**Expected Behavior:**
Service healthy, no restarts, no errors.

**How to Verify:**
Health OK, uptime continuous, error count is 0.

---

### Step 4: Health Check at T+12 Hours
**Action:**
```bash
echo "=== HEALTH CHECK T+12H $(date) ==="
curl -s http://localhost:8100/health | jq .
sudo systemctl status hx-lang-server | grep -E "Active:|since"
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep | awk '{print "RSS: " $6 "KB"}'
sudo journalctl -u hx-lang-server --since "12 hours ago" | grep -iE "error|exception|restart|fail" | wc -l
```

**Expected Behavior:**
Service healthy at midpoint.

**How to Verify:**
All indicators positive.

---

### Step 5: Health Check at T+18 Hours
**Action:**
```bash
echo "=== HEALTH CHECK T+18H $(date) ==="
curl -s http://localhost:8100/health | jq .
sudo systemctl status hx-lang-server | grep -E "Active:|since"
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep | awk '{print "RSS: " $6 "KB"}'
```

**Expected Behavior:**
Service healthy, approaching 24-hour mark.

**How to Verify:**
All indicators positive.

---

### Step 6: Final Validation at T+24 Hours
**Action:**
```bash
echo "=== FINAL VALIDATION T+24H $(date) ==="
echo "Service Status:"
sudo systemctl status hx-lang-server | head -15
echo ""
echo "Final Memory Usage:"
ps aux | grep -E "uvicorn.*hx-lang-server|uvicorn.*app.main" | grep -v grep | awk '{print "RSS: " $6 "KB, VSZ: " $5 "KB"}'
echo ""
echo "Health Endpoint:"
curl -s http://localhost:8100/health | jq .
echo ""
echo "Restart Count:"
sudo journalctl -u hx-lang-server --since "24 hours ago" | grep -i "started\|stopped" | wc -l
echo ""
echo "Error Count:"
sudo journalctl -u hx-lang-server --since "24 hours ago" | grep -iE "error|exception|fail" | wc -l
```

**Expected Behavior:**
Service stable for 24 hours.

**How to Verify:**
- Started/stopped count = 1 (initial start only)
- Error count = 0 or low (non-critical)
- Memory within 20% of baseline
- Health endpoint returns healthy

---

### Step 7: Verify No OOM Kills
**Action:**
```bash
dmesg | grep -i "out of memory\|oom" | tail -5
sudo journalctl --since "24 hours ago" | grep -i "oom\|out of memory" | head -5
```

**Expected Behavior:**
No OOM kills related to hx-lang-server.

**How to Verify:**
No matches or matches unrelated to service.

---

### Step 8: Verify Response Time Stability
**Action:**
```bash
echo "Response Time Check:"
for i in 1 2 3 4 5; do
    time curl -s http://localhost:8100/health > /dev/null
done 2>&1 | grep real
```

**Expected Behavior:**
Response times consistent with initial measurements.

**How to Verify:**
Response times < 2 seconds, no degradation.

---

## Expected Results

### Primary Expected Results
- [ ] Service ran continuously for 24 hours
- [ ] No unplanned restarts (only 1 start event)
- [ ] No ERROR or EXCEPTION entries in logs (or only non-critical)
- [ ] Memory usage stable (within 20% of baseline)
- [ ] No OOM kills
- [ ] Response times consistent
- [ ] Health endpoint returns "healthy" throughout

### Observable Indicators
**Logs:**
- No crash or restart messages
- No error accumulation

**Process Status:**
- Uptime > 24 hours
- Memory stable

**Performance:**
- Response times consistent

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Service uptime >= 24 hours
2. Zero unplanned restarts
3. Zero critical/high errors
4. Memory growth < 20%
5. No OOM kills
6. Response times stable
7. Health endpoint consistently healthy

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Service crashed or restarted
2. Memory growth > 50% (potential leak)
3. OOM kill occurred
4. Response time degradation > 50%
5. Health endpoint returns unhealthy
6. Critical errors in logs

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service failed to start
2. External dependencies unavailable for 24 hours
3. Infrastructure issues prevent observation

---

## Actual Results

**Execution Date Start**: [DATE/TIME]
**Execution Date End**: [DATE/TIME]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Baseline Metrics
- Start Time: [timestamp]
- Initial Memory (RSS): [X] KB
- Initial Memory (VSZ): [X] KB

### Final Metrics
- End Time: [timestamp]
- Final Memory (RSS): [X] KB
- Final Memory (VSZ): [X] KB
- Memory Growth: [X]%
- Restart Count: [X]
- Error Count: [X]

### Actual Observations
[Record detailed observations during 24-hour period]

---

## Test Cleanup

### Post-Test Actions
1. Document final state
2. Archive logs for review

### Environment Reset
- [ ] Logs archived
- [ ] Documentation complete

---

## Notes and Observations

### Dependencies on Other Tests
- All other deployment tests must pass first
- Final gate before operational promotion

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - SC-014 (systemd service stable 24h)

**Related Test Cases:**
- `tc-lang-server-deployment-004-service-startup.md` - Initial startup
- `tc-lang-server-health-005-resource-usage.md` - Resource monitoring

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
