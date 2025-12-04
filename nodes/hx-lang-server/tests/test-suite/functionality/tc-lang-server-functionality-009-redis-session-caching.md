# Test Case: Verify Redis Session Caching

**Test ID**: tc-lang-server-functionality-009-redis-session-caching
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-007 (Cache session data in Redis with configurable TTL)
**Based on Plan**: Work Stream 5 (Redis Integration)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that session data is correctly cached in Redis with the configured TTL (1 hour for sessions), using the proper key namespace (hx-lang-server:).

**Why This Test Is Important:**
Redis caching provides fast session access. Proper namespacing prevents key collisions with other services.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] Redis accessible (hx-redis-server.hx.dev.local:6379)

**Environment:**
- [ ] Access to API and Redis CLI

---

## Test Steps

### Step 1: Submit Query and Get Session
**Action:**
```bash
RESPONSE=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test for Redis session"}')
SESSION_ID=$(echo $RESPONSE | jq -r '.metadata.session_id // .session_id // "unknown"')
THREAD_ID=$(echo $RESPONSE | jq -r '.thread_id')
echo "Session: $SESSION_ID, Thread: $THREAD_ID"
```

**Expected Behavior:**
Session or thread ID returned.

**How to Verify:**
ID values are non-empty.

---

### Step 2: Verify Redis Key Namespace
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*" | head -10
```

**Expected Behavior:**
Keys exist with hx-lang-server: prefix.

**How to Verify:**
Keys listed with correct namespace.

---

### Step 3: Verify Session Key Exists
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:session:*" | head -5
```

**Expected Behavior:**
Session keys exist.

**How to Verify:**
At least one session key found.

---

### Step 4: Verify TTL on Session Key
**Action:**
```bash
# Get a session key and check its TTL
SESSION_KEY=$(redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:session:*" | head -1)
redis-cli -h hx-redis-server.hx.dev.local TTL "$SESSION_KEY"
```

**Expected Behavior:**
TTL is approximately 3600 seconds (1 hour) or less.

**How to Verify:**
TTL is between 0 and 3600.

---

### Step 5: Verify Cache Key Structure
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:cache:*" | head -5
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:thread:*" | head -5
```

**Expected Behavior:**
Cache and thread keys follow naming convention.

**How to Verify:**
Keys match expected patterns.

---

### Step 6: Verify Session Data Content
**Action:**
```bash
SESSION_KEY=$(redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:session:*" | head -1)
redis-cli -h hx-redis-server.hx.dev.local GET "$SESSION_KEY" | head -c 200
```

**Expected Behavior:**
Session data is JSON-formatted.

**How to Verify:**
Data appears to be valid JSON.

---

## Expected Results

### Primary Expected Results
- [ ] Redis keys use hx-lang-server: namespace
- [ ] Session keys created for conversations
- [ ] TTL set to approximately 1 hour
- [ ] Session data is valid JSON
- [ ] Cache keys follow naming convention

---

## Pass/Fail Criteria

### PASS Criteria
1. Namespace prefix used correctly
2. Session keys created
3. TTL configured appropriately
4. Data readable and valid

### FAIL Criteria
1. Wrong or no namespace
2. No session keys
3. No TTL set (keys don't expire)
4. Invalid data format

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-007, Redis Key Schema

**Related Test Cases:**
- `tc-lang-server-integration-004-007` - Redis integration tests

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
