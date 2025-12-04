# Test Case: Verify Redis Session Write

**Test ID**: tc-lang-server-integration-005-redis-session-write
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-007 (Redis session caching)
**Integration Point**: Redis session keys
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that session data is correctly written to Redis with proper namespace.

---

## Prerequisites

- [ ] Service running
- [ ] Redis connection working (integration-004 passed)

---

## Test Steps

### Step 1: Submit Query to Create Session
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test session write"}' > /dev/null
```

**Expected Behavior:**
Query processed, session created.

---

### Step 2: Check for Session Keys
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:session:*" | head -5
```

**Expected Behavior:**
Session keys with proper namespace exist.

---

### Step 3: Verify Key Content
**Action:**
```bash
KEY=$(redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:session:*" | head -1)
redis-cli -h hx-redis-server.hx.dev.local GET "$KEY" | head -c 300
```

**Expected Behavior:**
Session data (JSON) stored.

---

### Step 4: Verify Namespace Prefix
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*" | wc -l
```

**Expected Behavior:**
All keys use proper prefix.

---

## Expected Results

- [ ] Sessions written to Redis
- [ ] Correct namespace used
- [ ] Data format valid

---

## Pass/Fail Criteria

### PASS Criteria
1. Session keys created
2. Namespace correct
3. Valid data

### FAIL Criteria
1. No session keys
2. Wrong namespace
3. Invalid data

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-007, Redis Key Schema

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
