# Test Case: Verify Metrics Endpoint

**Test ID**: tc-lang-server-health-006-metrics-endpoint
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: NFR-004 (Prometheus-compatible metrics)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the Prometheus-compatible metrics endpoint exposes the required operational metrics.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Metrics endpoint on port 8101

---

## Test Steps

### Step 1: Verify Metrics Endpoint Accessibility
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-lang-server.hx.dev.local:8101/metrics
```

**Expected Behavior:**
Returns `200`.

---

### Step 2: Verify Prometheus Format
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | head -20
```

**Expected Behavior:**
Prometheus text format with # HELP and # TYPE annotations.

---

### Step 3: Verify Request Metrics
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "^(http_requests|request_)"
```

**Expected Behavior:**
HTTP request count and latency metrics.

---

### Step 4: Verify Worker Agent Metrics
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "worker|agent|supervisor"
```

**Expected Behavior:**
Metrics for worker agent invocations.

---

### Step 5: Verify Dependency Health Metrics
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "dependency|postgres|redis|ollama|lightrag"
```

**Expected Behavior:**
Dependency connectivity metrics.

---

## Expected Results

- [ ] Metrics endpoint returns 200
- [ ] Prometheus format valid
- [ ] Request metrics present
- [ ] Worker agent metrics present
- [ ] Dependency health metrics present

---

## Pass/Fail Criteria

### PASS Criteria
1. Valid Prometheus format
2. Required metrics present
3. Values update on requests

### FAIL Criteria
1. Invalid format
2. Missing key metrics
3. Static values

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
