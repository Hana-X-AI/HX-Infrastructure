# Test Case: Error Recovery End-to-End

**Test ID**: tc-lang-server-e2e-008-error-recovery
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Operational Requirements (graceful error handling)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates that the service handles errors gracefully and recovers without manual intervention.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Access to logs

---

## Test Steps

### Step 1: Submit Malformed Request
**Action:**
```bash
# Invalid JSON
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d 'not valid json' | jq '.'
```

**Expected Behavior:**
Error response with appropriate status code, no crash.

---

### Step 2: Verify Service Still Running After Error
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-lang-server.hx.dev.local:8101/health
```

**Expected Behavior:**
Returns 200 (service still healthy).

---

### Step 3: Submit Valid Request After Error
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Valid request after error"}' --max-time 60 | jq '.response[:100]'
```

**Expected Behavior:**
Valid request processes successfully.

---

### Step 4: Test Empty Query Handling
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": ""}' | jq '.'
```

**Expected Behavior:**
Graceful error or prompt for input.

---

### Step 5: Test Extremely Long Query
**Action:**
```bash
# Generate very long query
long_query=$(python3 -c "print('x' * 100000)")
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$long_query\"}" --max-time 30 | jq '.error // .response[:50]'
```

**Expected Behavior:**
Handled gracefully (error or truncation).

---

### Step 6: Verify Error Logging
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "error|exception|failed" | head -10
```

**Expected Behavior:**
Errors logged appropriately (no stack traces for handled errors).

---

## Expected Results

- [ ] Malformed requests handled gracefully
- [ ] Service remains running after errors
- [ ] Subsequent valid requests work
- [ ] Edge cases handled
- [ ] Errors logged appropriately

---

## Pass/Fail Criteria

### PASS Criteria
1. Graceful error handling
2. No service crashes
3. Recovery without intervention

### FAIL Criteria
1. Service crashes on error
2. Unhandled exceptions
3. Manual restart required

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
