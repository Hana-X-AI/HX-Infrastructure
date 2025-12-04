# Test Case: Verify Configuration Files

**Test ID**: tc-lang-server-deployment-007-configuration-files
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Configuration Management section, Environment Variables
**Based on Plan**: Work Stream 10 - FastAPI Application (Task 103), Work Stream 13 (Task 142)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that all required configuration files exist with correct values, including the environment file (.env), Pydantic settings, and any application configuration files.

**Why This Test Is Important:**
Configuration drives service behavior including database connections, external service URLs, and operational parameters. Incorrect configuration will cause service failures or incorrect behavior.

---

## Prerequisites

**Service State:**
- [ ] Directory structure created (deployment-003 passed)
- [ ] Ansible Vault credentials available (for secret verification)

**Dependencies:**
- [ ] Configuration files deployed

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] Read access to config directory

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection to target node
2. Verify config directory exists

### Test Data
**Required Test Data:**
Per specification, required environment variables:
- SERVICE_NAME=hx-lang-server
- SERVICE_PORT=8100
- POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER
- REDIS_URL
- OLLAMA_GENERAL_URL, OLLAMA_CODE_URL
- LIGHTRAG_URL
- FASTMCP_URL
- MAX_RECURSION_DEPTH, SESSION_TTL_SECONDS

---

## Test Steps

### Step 1: Verify Environment File Exists
**Action:**
```bash
ls -la /opt/hx-lang-server/.env
```

**Expected Behavior:**
Environment file exists with restricted permissions.

**How to Verify:**
File exists, permissions are 640 or more restrictive.

---

### Step 2: Verify Required Service Variables
**Action:**
```bash
grep -E "^SERVICE_NAME=|^SERVICE_PORT=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
SERVICE_NAME and SERVICE_PORT defined.

**How to Verify:**
SERVICE_NAME=hx-lang-server, SERVICE_PORT=8100

---

### Step 3: Verify PostgreSQL Configuration
**Action:**
```bash
grep -E "^POSTGRES_HOST=|^POSTGRES_PORT=|^POSTGRES_DB=|^POSTGRES_USER=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
All PostgreSQL variables defined.

**How to Verify:**
All four POSTGRES_* variables present with valid values.

---

### Step 4: Verify Redis Configuration
**Action:**
```bash
grep "^REDIS_URL=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
REDIS_URL defined.

**How to Verify:**
URL format: redis://hx-redis-server.hx.dev.local:6379/0

---

### Step 5: Verify Ollama Configuration
**Action:**
```bash
grep -E "^OLLAMA_GENERAL_URL=|^OLLAMA_CODE_URL=|^OLLAMA_GENERAL_MODEL=|^OLLAMA_CODE_MODEL=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
All Ollama variables defined.

**How to Verify:**
URLs point to correct Ollama servers, models specified.

---

### Step 6: Verify LightRAG Configuration
**Action:**
```bash
grep "^LIGHTRAG_URL=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
LIGHTRAG_URL defined.

**How to Verify:**
URL format: http://hx-literag-server.hx.dev.local:8020

---

### Step 7: Verify FastMCP Configuration
**Action:**
```bash
grep "^FASTMCP_URL=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
FASTMCP_URL defined.

**How to Verify:**
URL format: http://hx-fastmcp-server.hx.dev.local:8000

---

### Step 8: Verify Agent Configuration
**Action:**
```bash
grep -E "^MAX_RECURSION_DEPTH=|^SESSION_TTL_SECONDS=" /opt/hx-lang-server/.env
```

**Expected Behavior:**
Agent configuration parameters defined.

**How to Verify:**
MAX_RECURSION_DEPTH=25, SESSION_TTL_SECONDS=3600

---

### Step 9: Verify Config File Permissions
**Action:**
```bash
stat -c '%a %U:%G' /opt/hx-lang-server/.env
```

**Expected Behavior:**
File owned by hx-lang-server with restricted permissions.

**How to Verify:**
Permissions 640 or less, owner hx-lang-server.

---

### Step 10: Verify No Plaintext Secrets (Spot Check)
**Action:**
```bash
grep -iE "^POSTGRES_PASSWORD=.{8,}" /opt/hx-lang-server/.env | wc -l
```

**Expected Behavior:**
Password should reference vault variable or be set at runtime.

**How to Verify:**
Check that password handling follows security guidelines.

---

## Expected Results

### Primary Expected Results
- [ ] .env file exists
- [ ] SERVICE_NAME and SERVICE_PORT configured
- [ ] PostgreSQL connection parameters configured
- [ ] Redis URL configured
- [ ] Ollama URLs and models configured
- [ ] LightRAG URL configured
- [ ] FastMCP URL configured
- [ ] Agent parameters configured
- [ ] File permissions are restrictive

### Observable Indicators
**Files:**
- `/opt/hx-lang-server/.env` exists
- Permissions 640 or more restrictive

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Environment file exists
2. All required variables defined
3. Variable values are valid (correct hosts, ports)
4. File permissions are restrictive (640 or less)
5. Owned by hx-lang-server

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Environment file missing
2. Required variables not defined
3. Invalid variable values
4. Permissions too permissive
5. Wrong ownership

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Directory structure missing (deployment-003 failed)
2. Cannot access config directory

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

### Security Notes
- Do not expose actual password values in test output
- Verify secrets management follows Ansible Vault pattern

### Dependencies on Other Tests
- Requires deployment-003 to pass
- Required for deployment-004 (Service Startup)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Configuration Management, Environment Variables

**Related Test Cases:**
- `tc-lang-server-deployment-003-directory-structure.md` - Prerequisite
- `tc-lang-server-deployment-010-environment-file.md` - Detailed env file test

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
