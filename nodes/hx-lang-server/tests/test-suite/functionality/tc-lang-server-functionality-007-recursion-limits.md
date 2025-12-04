# Test Case: Verify Recursion Limits

**Test ID**: tc-lang-server-functionality-007-recursion-limits
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-005 (Graph recursion limits default: 25 iterations)
**Based on Plan**: Work Stream 6 (LangGraph Agent Implementation)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the LangGraph implementation enforces recursion limits (default 25) to prevent infinite loops and runaway agent execution.

**Why This Test Is Important:**
Without recursion limits, agent loops could consume resources indefinitely. This safety mechanism is critical for operational stability.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] None specific

**Environment:**
- [ ] Access to API on port 8100

---

## Test Steps

### Step 1: Verify Iteration Count in Response
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Simple question that should complete quickly"}' | jq '.iteration_count'
```

**Expected Behavior:**
iteration_count is a small number (typically 1-3 for simple queries).

**How to Verify:**
iteration_count is present and less than 25.

---

### Step 2: Verify MAX_RECURSION_DEPTH in Environment
**Action:**
```bash
grep "MAX_RECURSION_DEPTH" /opt/hx-lang-server/.env
```

**Expected Behavior:**
MAX_RECURSION_DEPTH=25 or similar value configured.

**How to Verify:**
Value is set (default 25).

---

### Step 3: Verify Graceful Handling at Limit
**Action:**
```bash
# This test may need a specially crafted query that causes more iterations
# For now, verify the system handles complex queries gracefully
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Perform a complex multi-step analysis that may require multiple agent iterations"}' | jq '{iteration_count, response: .response[:100]}'
```

**Expected Behavior:**
Response completes within iteration limit.

**How to Verify:**
iteration_count <= MAX_RECURSION_DEPTH, response present.

---

### Step 4: Verify Config Override for Recursion Limit
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test query", "config": {"recursion_limit": 5}}' | jq '.iteration_count'
```

**Expected Behavior:**
Custom recursion limit is respected if configurable.

**How to Verify:**
No errors; iteration_count tracked.

---

## Expected Results

### Primary Expected Results
- [ ] iteration_count is tracked in responses
- [ ] MAX_RECURSION_DEPTH configured (default 25)
- [ ] Complex queries complete within limit
- [ ] No infinite loops

---

## Pass/Fail Criteria

### PASS Criteria
1. iteration_count present in responses
2. Recursion limit enforced
3. No infinite loops

### FAIL Criteria
1. iteration_count missing
2. Queries exceed limit without termination
3. Infinite loops possible

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-005

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
