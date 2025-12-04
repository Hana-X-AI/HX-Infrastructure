# Test Case: Redis Cache Connection

**Test ID**: tc-docling-mcp-integration-003
**Test Area**: Integration Testing
**Priority**: MEDIUM
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify Redis cache connection and session management functionality.

---

## Test Coverage

**Requirements Covered**:
- FR-023: Integrate with Redis (hx-redis-server:6379)
- FR-018: Support session-based workflows via Redis
- FR-019: Implement configurable session TTL

---

## Test Steps

### Step 1: Verify Redis Connection

**Action**:
```bash
redis-cli -h hx-redis-server.hx.dev.local -p 6379 PING
```

**Expected**: Returns "PONG"

---

### Step 2: Test Key-Value Operations

**Action**:
```bash
redis-cli -h hx-redis-server.hx.dev.local -p 6379 SET test-session-001 "test data" EX 60
redis-cli -h hx-redis-server.hx.dev.local -p 6379 GET test-session-001
redis-cli -h hx-redis-server.hx.dev.local -p 6379 DEL test-session-001
```

**Expected**: SET/GET/DEL operations successful

---

### Step 3: Verify TTL Configuration

**Action**:
```bash
# Check session TTL configuration
grep "REDIS_SESSION_TTL" /etc/docling-mcp/.env
```

**Expected**: Session TTL configured (default 3600 seconds)

---

## Pass/Fail Criteria

**PASS**: Redis reachable, key-value operations work, TTL configured

**FAIL**: Cannot connect to Redis or operations fail

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-medium-int-003-redis-unavailable.md`

---

**Test Case Version**: 1.0
