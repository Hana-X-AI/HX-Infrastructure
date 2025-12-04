# Test Case: Verify OpenAPI Documentation

**Test ID**: tc-lang-server-deployment-012-openapi-documentation
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-025 (OpenAPI documentation at /docs)
**Based on Plan**: Work Stream 10 - FastAPI Application (Task 112)
**Test Type**: Manual
**Estimated Execution Time**: 3 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that FastAPI's automatic OpenAPI documentation is available at /docs (Swagger UI) and /redoc (ReDoc), and that the OpenAPI schema at /openapi.json is valid and complete.

**Why This Test Is Important:**
OpenAPI documentation is essential for API consumers (n8n, external clients) to understand available endpoints, request/response formats, and integration patterns.

---

## Prerequisites

**Service State:**
- [ ] Service running (deployment-004 passed)

**Dependencies:**
- [ ] Port 8100 accessible

**Environment:**
- [ ] SSH access or network access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] Standard user access

---

## Test Setup

### Pre-Test Actions
1. Verify service is running
2. Ensure port 8100 is accessible

### Test Data
**Required Test Data:**
- API URL: http://hx-lang-server.hx.dev.local:8100
- Docs endpoint: /docs
- ReDoc endpoint: /redoc
- OpenAPI JSON: /openapi.json

---

## Test Steps

### Step 1: Verify /docs Endpoint Available
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/docs
```

**Expected Behavior:**
Swagger UI page returns 200.

**How to Verify:**
HTTP status code is 200.

---

### Step 2: Verify /docs Returns HTML
**Action:**
```bash
curl -s http://localhost:8100/docs | head -5 | grep -i "<!DOCTYPE html\|swagger"
```

**Expected Behavior:**
Response is HTML with Swagger UI.

**How to Verify:**
Output contains HTML doctype or swagger reference.

---

### Step 3: Verify /redoc Endpoint Available
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/redoc
```

**Expected Behavior:**
ReDoc page returns 200.

**How to Verify:**
HTTP status code is 200.

---

### Step 4: Verify OpenAPI JSON Available
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/openapi.json
```

**Expected Behavior:**
OpenAPI schema returns 200.

**How to Verify:**
HTTP status code is 200.

---

### Step 5: Verify OpenAPI JSON Is Valid
**Action:**
```bash
curl -s http://localhost:8100/openapi.json | jq -e '.openapi' > /dev/null && echo "Valid JSON"
```

**Expected Behavior:**
Response is valid JSON with openapi field.

**How to Verify:**
"Valid JSON" printed (jq parses successfully).

---

### Step 6: Verify API Title in OpenAPI
**Action:**
```bash
curl -s http://localhost:8100/openapi.json | jq -r '.info.title'
```

**Expected Behavior:**
Returns service title (hx-lang-server or similar).

**How to Verify:**
Output contains service name.

---

### Step 7: Verify Key Endpoints Documented
**Action:**
```bash
curl -s http://localhost:8100/openapi.json | jq -r '.paths | keys[]' | grep -E "/invoke|/stream|/health|/ready"
```

**Expected Behavior:**
Key endpoints appear in paths.

**How to Verify:**
Output includes invoke, stream, health, ready endpoints.

---

### Step 8: Verify Request/Response Schemas Defined
**Action:**
```bash
curl -s http://localhost:8100/openapi.json | jq '.components.schemas | keys | length'
```

**Expected Behavior:**
Multiple schemas defined for request/response models.

**How to Verify:**
Count > 0 (schemas are defined).

---

### Step 9: Verify API Version in OpenAPI
**Action:**
```bash
curl -s http://localhost:8100/openapi.json | jq -r '.info.version'
```

**Expected Behavior:**
API version is documented.

**How to Verify:**
Version string returned (e.g., "1.0.0").

---

## Expected Results

### Primary Expected Results
- [ ] /docs returns 200 with Swagger UI
- [ ] /redoc returns 200 with ReDoc
- [ ] /openapi.json returns valid JSON
- [ ] OpenAPI spec contains openapi version
- [ ] API title documented
- [ ] Key endpoints documented (/invoke, /stream, /health, /ready)
- [ ] Request/response schemas defined
- [ ] API version documented

### Observable Indicators
**Network:**
- All documentation endpoints accessible
- Valid JSON returned from /openapi.json

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. /docs returns 200
2. /redoc returns 200
3. /openapi.json is valid JSON
4. Key endpoints documented
5. Schemas defined

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. /docs not accessible
2. /openapi.json invalid or missing
3. Key endpoints not documented
4. No schemas defined
5. Server errors on documentation endpoints

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. Port 8100 not accessible

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

---

## Test Cleanup

### Post-Test Actions
1. No cleanup required

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Requires deployment-004 (Service Startup)
- Related to functionality tests for API endpoints

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-025 (OpenAPI documentation)

**Related Test Cases:**
- `tc-lang-server-deployment-004-service-startup.md` - Prerequisite
- `tc-lang-server-functionality-024-async-endpoints.md` - API tests

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
