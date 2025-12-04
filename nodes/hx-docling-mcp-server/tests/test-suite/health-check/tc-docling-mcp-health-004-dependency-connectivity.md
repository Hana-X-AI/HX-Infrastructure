# Test Case: Dependency Health Validation

**Test ID**: tc-docling-mcp-health-004
**Test Area**: Health Check Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify all dependency services (LiteLLM, Qdrant, Redis) are reachable and healthy.

---

## Test Coverage

**Requirements Covered**:
- FR-024: Log all integration failures
- NFR-010: Handle dependency failures gracefully

---

## Test Steps

### Step 1: Check LiteLLM Gateway Reachability

**Action**:
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-litellm-server.hx.dev.local:4000/health
```

**Expected**: HTTP 200

---

### Step 2: Check Qdrant Reachability

**Action**:
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-qdrant-server.hx.dev.local:6333/health
```

**Expected**: HTTP 200

---

### Step 3: Check Redis Reachability

**Action**:
```bash
redis-cli -h hx-redis-server.hx.dev.local -p 6379 PING
```

**Expected**: PONG

---

### Step 4: Verify Graceful Degradation on Failure

**Action**:
```bash
# Check health endpoint shows dependency status
curl -s http://hx-docling-mcp-server.hx.dev.local:8000/health | jq '.dependencies'
```

**Expected**: Dependency health status reflected accurately

**Pass Criteria**: Service reports dependency health correctly

---

## Pass/Fail Criteria

**PASS**: All dependencies reachable, health status accurate

**FAIL**: Any dependency unreachable without graceful degradation

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-health-004-dependency-unhealthy.md`

---

**Test Case Version**: 1.0
