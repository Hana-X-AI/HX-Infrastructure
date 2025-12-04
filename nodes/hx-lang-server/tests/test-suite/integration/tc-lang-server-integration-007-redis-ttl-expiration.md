# Test Case: Verify Redis TTL Expiration

**Test ID**: tc-lang-server-integration-007-redis-ttl-expiration
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: Redis Key Schema (Session TTL: 1 hour, Cache TTL: 5 minutes)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that Redis keys have appropriate TTL values set for automatic expiration.

---

## Prerequisites

- [ ] Session keys exist in Redis

---

## Test Steps

### Step 1: Check Session Key TTL
**Action:**
```bash
SESSION_KEY=$(redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:session:*" | head -1)
redis-cli -h hx-redis-server.hx.dev.local TTL "$SESSION_KEY"
```

**Expected Behavior:**
TTL between 0 and 3600 seconds.

---

### Step 2: Check Cache Key TTL
**Action:**
```bash
CACHE_KEY=$(redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:cache:*" | head -1)
if [ -n "$CACHE_KEY" ]; then
  redis-cli -h hx-redis-server.hx.dev.local TTL "$CACHE_KEY"
else
  echo "No cache keys found (may be normal)"
fi
```

**Expected Behavior:**
TTL between 0 and 300 seconds (if cache exists).

---

### Step 3: Verify No Persistent Keys (without TTL)
**Action:**
```bash
# Count keys without TTL
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*" | while read key; do
  ttl=$(redis-cli -h hx-redis-server.hx.dev.local TTL "$key")
  if [ "$ttl" -eq "-1" ]; then
    echo "No TTL: $key"
  fi
done | wc -l
```

**Expected Behavior:**
0 or very few keys without TTL.

---

## Expected Results

- [ ] Session TTL ~3600s
- [ ] Cache TTL ~300s
- [ ] All keys have expiration

---

## Pass/Fail Criteria

### PASS Criteria
1. TTLs set appropriately
2. Keys will expire

### FAIL Criteria
1. No TTL on keys
2. TTL values incorrect

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
