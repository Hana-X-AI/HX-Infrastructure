# Test Case: Integration Point Connectivity

**Test ID**: tc-docling-mcp-deployment-013
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify service can connect to all required integration points (LiteLLM, Qdrant, Redis).

---

## Test Steps

### Step 1: Verify LiteLLM Gateway Connectivity

**Action**:
```bash
curl -s http://192.168.10.212:4000/health
curl -s http://192.168.10.212:4000/v1/models | jq '.data[] | select(.id | contains("gemma3"))'
```

**Expected**: LiteLLM responds, gemma3:27b model available

---

### Step 2: Verify Qdrant Connectivity

**Action**:
```bash
curl -s http://192.168.10.207:6333/health
curl -s http://192.168.10.207:6333/collections
```

**Expected**: Qdrant responds with healthy status

---

### Step 3: Verify Redis Connectivity

**Action**:
```bash
redis-cli -h 192.168.10.210 -p 6379 PING
```

**Expected**: Returns "PONG"

---

## Pass/Fail Criteria

**PASS**: All 3 integration points reachable and responding

**FAIL**: Any integration point unreachable

---

**Test Case Version**: 1.0
