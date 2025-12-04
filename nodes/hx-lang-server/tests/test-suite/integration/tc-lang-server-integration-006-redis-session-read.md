# Test Case: Verify Redis Session Read

**Test ID**: tc-lang-server-integration-006-redis-session-read
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-007 (Redis session caching)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that session data can be read from Redis for fast access.

---

## Prerequisites

- [ ] Session keys exist in Redis

---

## Test Steps

### Step 1: Create Session and Get Thread
**Action:**
```bash
THREAD=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Remember this: blue sky"}' | jq -r '.thread_id')
echo "Thread: $THREAD"
```

---

### Step 2: Verify Session Readable
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"What did I say?\", \"thread_id\": \"$THREAD\"}" | jq -r '.response[:100]'
```

**Expected Behavior:**
Response references previous context (session read).

---

### Step 3: Verify Cache Keys Used
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:cache:*" | head -5
```

**Expected Behavior:**
Cache keys may exist for performance.

---

## Expected Results

- [ ] Session data readable
- [ ] Context maintained
- [ ] Cache functioning

---

## Pass/Fail Criteria

### PASS Criteria
1. Session read works
2. Context retrieved

### FAIL Criteria
1. Read fails
2. Context lost

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
