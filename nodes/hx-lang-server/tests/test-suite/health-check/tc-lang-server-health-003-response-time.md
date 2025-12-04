# Test Case: Verify Health Response Time

**Test ID**: tc-lang-server-health-003-response-time
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: NFR-001 (API response under 100ms for health checks)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that health and ready endpoints respond within acceptable time limits (under 100ms).

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] curl with timing support

---

## Test Steps

### Step 1: Measure Health Endpoint Response Time
**Action:**
```bash
for i in {1..10}; do
  curl -s -w "%{time_total}\n" -o /dev/null http://hx-lang-server.hx.dev.local:8101/health
done
```

**Expected Behavior:**
All response times under 100ms (0.100s).

---

### Step 2: Measure Ready Endpoint Response Time
**Action:**
```bash
for i in {1..10}; do
  curl -s -w "%{time_total}\n" -o /dev/null http://hx-lang-server.hx.dev.local:8101/ready
done
```

**Expected Behavior:**
Response times under 500ms (ready may be slower due to dependency checks).

---

### Step 3: Calculate Average Response Time
**Action:**
```bash
# Health endpoint average
times=$(for i in {1..10}; do curl -s -w "%{time_total}\n" -o /dev/null http://hx-lang-server.hx.dev.local:8101/health; done)
echo "$times" | awk '{sum+=$1} END {print "Average:", sum/NR, "seconds"}'
```

**Expected Behavior:**
Average under 100ms for health endpoint.

---

## Expected Results

- [ ] Health endpoint responds under 100ms
- [ ] Ready endpoint responds under 500ms
- [ ] Consistent response times across multiple requests

---

## Pass/Fail Criteria

### PASS Criteria
1. Health: < 100ms average
2. Ready: < 500ms average
3. No timeouts

### FAIL Criteria
1. Responses exceed thresholds
2. Inconsistent timing
3. Timeouts occur

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
