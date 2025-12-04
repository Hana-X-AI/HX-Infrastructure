# Test Case: Verify Async Endpoints

**Test ID**: tc-lang-server-functionality-024-async-endpoints
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-022 (Implement async endpoints using async def with ainvoke())
**Based on Plan**: Work Stream 10 (FastAPI Application)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that API endpoints are implemented as async functions enabling concurrent request handling.

---

## Prerequisites

- [ ] Service running and healthy

---

## Test Steps

### Step 1: Submit Concurrent Requests
**Action:**
```bash
# Submit multiple requests concurrently
for i in 1 2 3 4 5; do
  curl -s -X POST http://localhost:8100/invoke \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"Quick test $i\"}" &
done
wait
echo "All requests completed"
```

**Expected Behavior:**
All requests handled concurrently.

---

### Step 2: Verify No Blocking
**Action:**
```bash
# Time concurrent vs sequential
time (
  for i in 1 2 3; do
    curl -s http://localhost:8100/health > /dev/null &
  done
  wait
)
echo "Concurrent time above"
```

**Expected Behavior:**
Concurrent execution faster than 3x single request.

---

### Step 3: Test /stream Endpoint
**Action:**
```bash
curl -s -N -X POST http://localhost:8100/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "Tell me a short story"}' | head -c 500
```

**Expected Behavior:**
Streaming response (SSE format or chunked).

---

### Step 4: Verify Async in Application
**Action:**
```bash
# Check for async patterns in code (if accessible)
grep -r "async def\|ainvoke\|await" /opt/hx-lang-server/app/*.py 2>/dev/null | head -10 || echo "Code inspection not available"
```

**Expected Behavior:**
Async patterns in application code.

---

## Expected Results

- [ ] Concurrent requests handled
- [ ] No blocking on requests
- [ ] /stream endpoint works (if implemented)
- [ ] Async patterns in code

---

## Pass/Fail Criteria

### PASS Criteria
1. Concurrent handling works
2. No request blocking
3. Async implementation

### FAIL Criteria
1. Requests block each other
2. Sequential processing only
3. Sync implementation

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-022

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
