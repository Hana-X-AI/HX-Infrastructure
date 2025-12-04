# Test Case: Verify Ready Endpoint Validates Dependencies

**Test ID**: tc-lang-server-health-002-ready-endpoint-validation
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-011 (Ready endpoint validates dependencies)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the ready endpoint validates all service dependencies (PostgreSQL, Redis, Ollama1, Ollama2, LightRAG) and reports their status accurately.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] All dependencies configured

---

## Test Steps

### Step 1: Query Ready Endpoint
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.'
```

**Expected Behavior:**
JSON response with overall status and individual dependency statuses.

---

### Step 2: Verify PostgreSQL Dependency Status
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies.postgresql // .postgres // .database'
```

**Expected Behavior:**
PostgreSQL status reported (healthy/connected).

---

### Step 3: Verify Redis Dependency Status
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies.redis // .redis'
```

**Expected Behavior:**
Redis status reported (healthy/connected).

---

### Step 4: Verify Ollama Dependencies Status
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies | {ollama1, ollama2}'
```

**Expected Behavior:**
Both Ollama instances status reported.

---

### Step 5: Verify LightRAG Dependency Status
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies.lightrag // .rag'
```

**Expected Behavior:**
LightRAG status reported.

---

## Expected Results

- [ ] Ready endpoint returns dependency statuses
- [ ] PostgreSQL status validated
- [ ] Redis status validated
- [ ] Ollama1 and Ollama2 status validated
- [ ] LightRAG status validated

---

## Pass/Fail Criteria

### PASS Criteria
1. All dependencies reported
2. Status reflects actual connectivity
3. Response is valid JSON

### FAIL Criteria
1. Missing dependency status
2. Incorrect status reported
3. Endpoint unavailable

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
