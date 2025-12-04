# Test Case: Verify Health Endpoint Returns 200

**Test ID**: tc-lang-server-health-001-endpoint-returns-200
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-010 (Health endpoint returns 200)
**Test Type**: Manual
**Estimated Execution Time**: 2 minutes

---

## Test Objective

Verifies that the health endpoint returns HTTP 200 status code when the service is running and healthy.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Network access to target host

---

## Test Steps

### Step 1: Query Health Endpoint
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-lang-server.hx.dev.local:8101/health
```

**Expected Behavior:**
Returns `200`.

---

### Step 2: Verify Health Response Body
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/health | jq '.'
```

**Expected Behavior:**
JSON response with status field indicating "healthy" or similar.

---

### Step 3: Verify Response Time
**Action:**
```bash
curl -s -w "\nTime: %{time_total}s\n" http://hx-lang-server.hx.dev.local:8101/health | tail -1
```

**Expected Behavior:**
Response time under 1 second.

---

## Expected Results

- [ ] HTTP 200 returned
- [ ] Valid JSON response body
- [ ] Response time acceptable

---

## Pass/Fail Criteria

### PASS Criteria
1. Health endpoint returns 200
2. Response is valid JSON
3. Response time < 1s

### FAIL Criteria
1. Non-200 status code
2. Invalid response format
3. Response timeout

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
