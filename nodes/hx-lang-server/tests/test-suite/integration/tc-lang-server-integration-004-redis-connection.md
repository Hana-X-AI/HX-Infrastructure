# Test Case: Verify Redis Connection

**Test ID**: tc-lang-server-integration-004-redis-connection
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Redis Integration section
**Integration Point**: hx-redis-server.hx.dev.local:6379
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server can establish connection to Redis for session caching.

---

## Prerequisites

- [ ] Redis accessible at hx-redis-server.hx.dev.local:6379

---

## Test Steps

### Step 1: Verify Redis Connectivity
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local PING
```

**Expected Behavior:**
Returns PONG.

---

### Step 2: Verify Redis Configuration
**Action:**
```bash
grep "REDIS_URL" /opt/hx-lang-server/.env
```

**Expected Behavior:**
REDIS_URL configured correctly.

---

### Step 3: Test Service Health with Redis
**Action:**
```bash
curl -s http://localhost:8100/health | jq '.dependencies.redis'
```

**Expected Behavior:**
Redis shows healthy status.

---

### Step 4: Verify Connection Pool
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local CLIENT LIST | grep -c "hx-lang-server" || echo "Client name may not be set"
```

**Expected Behavior:**
Connections visible from service.

---

## Expected Results

- [ ] Redis connection works
- [ ] Configuration correct
- [ ] Health shows healthy
- [ ] Connections established

---

## Pass/Fail Criteria

### PASS Criteria
1. PING returns PONG
2. Config correct
3. Health shows healthy

### FAIL Criteria
1. Connection fails
2. Wrong config
3. Unhealthy status

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - Redis Integration

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
