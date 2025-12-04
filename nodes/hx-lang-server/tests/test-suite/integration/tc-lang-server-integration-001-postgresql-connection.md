# Test Case: Verify PostgreSQL Connection

**Test ID**: tc-lang-server-integration-001-postgresql-connection
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: PostgreSQL Checkpoint Configuration section
**Integration Point**: hx-postgres-server.hx.dev.local:5432
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server can establish and maintain a connection to the PostgreSQL database for checkpoint storage.

---

## Prerequisites

- [ ] PostgreSQL accessible at hx-postgres-server.hx.dev.local:5432
- [ ] Database hx_lang_server created
- [ ] User hx_lang_server with correct credentials

---

## Test Steps

### Step 1: Verify PostgreSQL Connectivity from Service
**Action:**
```bash
# Test connectivity using service credentials
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c "SELECT 1 as connection_test;"
```

**Expected Behavior:**
Query returns 1, connection successful.

---

### Step 2: Verify Connection Configuration
**Action:**
```bash
grep -E "POSTGRES_HOST|POSTGRES_PORT|POSTGRES_DB|POSTGRES_USER" /opt/hx-lang-server/.env
```

**Expected Behavior:**
All PostgreSQL configuration present.

---

### Step 3: Verify Checkpoint Tables Exist
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c "\dt langgraph.*"
```

**Expected Behavior:**
Checkpoint tables listed.

---

### Step 4: Test Service Health with PostgreSQL
**Action:**
```bash
curl -s http://localhost:8100/health | jq '.dependencies.postgres // .dependencies.postgresql'
```

**Expected Behavior:**
PostgreSQL shows healthy status.

---

## Expected Results

- [ ] Connection successful
- [ ] Configuration correct
- [ ] Checkpoint tables exist
- [ ] Health check shows PostgreSQL healthy

---

## Pass/Fail Criteria

### PASS Criteria
1. Connection works
2. Tables exist
3. Health shows healthy

### FAIL Criteria
1. Connection fails
2. Authentication error
3. Missing tables

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - PostgreSQL Checkpoint Configuration

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
