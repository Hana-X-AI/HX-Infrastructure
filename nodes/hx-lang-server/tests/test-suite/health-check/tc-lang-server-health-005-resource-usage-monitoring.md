# Test Case: Verify Resource Usage Monitoring

**Test ID**: tc-lang-server-health-005-resource-usage-monitoring
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: NFR-004 (Telemetry and monitoring support)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that resource usage (memory, CPU, connections) is monitored and reported through health/metrics endpoints.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Access to metrics endpoint

---

## Test Steps

### Step 1: Check Process Resource Usage
**Action:**
```bash
# Get hx-lang-server process stats
ps aux | grep "[h]x-lang-server" | awk '{print "CPU:", $3"%", "MEM:", $4"%", "RSS:", $6"KB"}'
```

**Expected Behavior:**
Process resource usage displayed.

---

### Step 2: Query Metrics Endpoint for Resource Data
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "^(process_|python_)"
```

**Expected Behavior:**
Process metrics available (memory, CPU, threads).

---

### Step 3: Verify Memory Metrics
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "memory|resident|heap"
```

**Expected Behavior:**
Memory-related metrics exposed.

---

### Step 4: Verify Connection Pool Metrics
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "pool|connection"
```

**Expected Behavior:**
Connection pool metrics for databases.

---

### Step 5: Verify Health Endpoint Includes Basic Stats
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/health | jq '.stats // .resources // .'
```

**Expected Behavior:**
Basic resource stats in health response.

---

## Expected Results

- [ ] Process metrics available
- [ ] Memory usage tracked
- [ ] Connection pool metrics available
- [ ] Health endpoint provides basic stats

---

## Pass/Fail Criteria

### PASS Criteria
1. Resource metrics exposed
2. Values are reasonable
3. Metrics update over time

### FAIL Criteria
1. No resource metrics
2. Static/stale values
3. Missing connection pool data

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
