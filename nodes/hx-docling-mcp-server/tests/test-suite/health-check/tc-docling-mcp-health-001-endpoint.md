# Test Case: Health Check Endpoint

**Test ID**: tc-docling-mcp-health-001
**Test Area**: Health Check Testing
**Priority**: CRITICAL
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify /health endpoint responds correctly with status information.

---

## Test Coverage

**Requirements Covered**:
- FR-025: Expose health check endpoint returning status
- NFR-004: Health check endpoint MUST respond within 2 seconds

---

## Test Steps

### Step 1: Verify Health Endpoint Accessible

**Action**:
```bash
curl -s -w "\nResponse time: %{time_total}s\n" http://hx-docling-mcp-server.hx.dev.local:8000/health
```

**Expected**:
```json
{
  "status": "healthy",
  "service": "docling-mcp",
  "version": "1.0.0",
  "dependencies": {
    "litellm": "healthy",
    "qdrant": "healthy",
    "redis": "healthy"
  }
}
```

**Pass Criteria**: 
- HTTP 200 status
- Response time < 2 seconds
- Status field = "healthy"

---

### Step 2: Verify Dependency Health Status

**Action**:
```bash
curl -s http://hx-docling-mcp-server.hx.dev.local:8000/health | jq '.dependencies'
```

**Expected**: All dependencies showing "healthy"

---

## Pass/Fail Criteria

**PASS**: Health endpoint responds < 2s, status=healthy, dependencies healthy

**FAIL**: Endpoint unreachable, timeout >2s, or status != healthy

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-critical-health-001-endpoint-failed.md`

---

**Test Case Version**: 1.0
