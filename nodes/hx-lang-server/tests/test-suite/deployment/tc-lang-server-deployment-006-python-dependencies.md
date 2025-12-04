# Test Case: Verify Python Dependencies

**Test ID**: tc-lang-server-deployment-006-python-dependencies
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Python Dependencies section (LangGraph, LangChain, FastAPI, etc.)
**Based on Plan**: Work Stream 2-3 (Tasks 015-016, 021-026)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that all required Python dependencies are installed in the virtual environment, including LangGraph v0.3.x, LangChain, FastAPI, database connectors, and HTTP clients.

**Why This Test Is Important:**
The service depends on specific package versions for LangGraph orchestration, checkpointing, and integrations. Missing or incorrect versions will cause runtime failures.

---

## Prerequisites

**Service State:**
- [ ] Virtual environment created (deployment-005 passed)

**Dependencies:**
- [ ] pip functional in venv

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] Access to venv

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection to target node
2. Verify venv exists

### Test Data
**Required Test Data:**
Per specification, minimum versions:
- langgraph >= 0.3.0
- langchain >= 0.3.0
- langchain-ollama >= 0.2.0
- langchain-mcp-adapters >= 0.1.0
- langgraph-checkpoint-postgres >= 2.0.0
- psycopg[binary] >= 3.2.0
- redis >= 5.0.0
- fastapi >= 0.115.0
- uvicorn >= 0.32.0
- pydantic >= 2.9.0
- pydantic-settings >= 2.6.0
- httpx >= 0.27.0
- aiohttp >= 3.10.0
- structlog >= 24.0.0

---

## Test Steps

### Step 1: Verify Core LangGraph Package
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show langgraph | grep -E "Name:|Version:"
```

**Expected Behavior:**
LangGraph package installed with version >= 0.3.0.

**How to Verify:**
Version number is 0.3.x or higher.

---

### Step 2: Verify LangChain Packages
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show langchain langchain-ollama langchain-mcp-adapters 2>/dev/null | grep -E "Name:|Version:"
```

**Expected Behavior:**
All LangChain packages installed with correct versions.

**How to Verify:**
langchain >= 0.3.0, langchain-ollama >= 0.2.0, langchain-mcp-adapters >= 0.1.0

---

### Step 3: Verify Checkpoint Package
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show langgraph-checkpoint-postgres | grep -E "Name:|Version:"
```

**Expected Behavior:**
Checkpoint package installed with version >= 2.0.0.

**How to Verify:**
Version number >= 2.0.0.

---

### Step 4: Verify Database Connectors
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show psycopg redis | grep -E "Name:|Version:"
```

**Expected Behavior:**
psycopg >= 3.2.0, redis >= 5.0.0 installed.

**How to Verify:**
Both packages present with correct versions.

---

### Step 5: Verify FastAPI Stack
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show fastapi uvicorn pydantic pydantic-settings | grep -E "Name:|Version:"
```

**Expected Behavior:**
All FastAPI packages installed with correct versions.

**How to Verify:**
fastapi >= 0.115.0, uvicorn >= 0.32.0, pydantic >= 2.9.0, pydantic-settings >= 2.6.0

---

### Step 6: Verify HTTP Clients
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show httpx aiohttp | grep -E "Name:|Version:"
```

**Expected Behavior:**
HTTP client packages installed.

**How to Verify:**
httpx >= 0.27.0, aiohttp >= 3.10.0

---

### Step 7: Verify Logging Package
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show structlog | grep -E "Name:|Version:"
```

**Expected Behavior:**
structlog >= 24.0.0 installed.

**How to Verify:**
Version number >= 24.0.0.

---

### Step 8: Verify Package Import
**Action:**
```bash
/opt/hx-lang-server/venv/bin/python -c "import langgraph; import langchain; import fastapi; import redis; print('All imports successful')"
```

**Expected Behavior:**
All packages import without error.

**How to Verify:**
"All imports successful" printed without errors.

---

## Expected Results

### Primary Expected Results
- [ ] LangGraph >= 0.3.0 installed
- [ ] LangChain >= 0.3.0 installed
- [ ] langchain-ollama >= 0.2.0 installed
- [ ] langchain-mcp-adapters >= 0.1.0 installed
- [ ] langgraph-checkpoint-postgres >= 2.0.0 installed
- [ ] FastAPI stack installed (fastapi, uvicorn, pydantic)
- [ ] Database connectors installed (psycopg, redis)
- [ ] HTTP clients installed (httpx, aiohttp)
- [ ] All packages import successfully

### Observable Indicators
**System State:**
- pip list shows all required packages
- No import errors when loading packages

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. All required packages installed
2. Version requirements met for each package
3. Packages import without errors
4. No conflicting dependencies

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Any required package missing
2. Version below minimum requirement
3. Import fails for any package
4. Dependency conflicts reported

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Virtual environment not created (deployment-005 failed)
2. pip not functional

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
1. No cleanup required for read-only verification

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Requires deployment-005 to pass
- Required for deployment-004 (Service Startup)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Python Dependencies section

**Related Test Cases:**
- `tc-lang-server-deployment-005-virtual-environment.md` - Prerequisite
- `tc-lang-server-deployment-004-service-startup.md` - Depends on this

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
