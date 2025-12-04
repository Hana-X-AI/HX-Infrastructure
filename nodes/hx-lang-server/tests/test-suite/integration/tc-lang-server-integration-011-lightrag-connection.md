# Test Case: Verify LightRAG Connection

**Test ID**: tc-lang-server-integration-011-lightrag-connection
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-014 (LightRAG HTTP integration)
**Integration Point**: hx-literag-server.hx.dev.local:8020
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server can connect to LightRAG for RAG operations.

---

## Prerequisites

- [ ] LightRAG accessible at hx-literag-server.hx.dev.local:8020

---

## Test Steps

### Step 1: Verify LightRAG Connectivity
**Action:**
```bash
curl -s http://hx-literag-server.hx.dev.local:8020/health || echo "Check LightRAG endpoint"
```

**Expected Behavior:**
Health endpoint responds.

---

### Step 2: Verify Configuration
**Action:**
```bash
grep "LIGHTRAG" /opt/hx-lang-server/.env
```

**Expected Behavior:**
LIGHTRAG_URL configured.

---

### Step 3: Test Service Health with LightRAG
**Action:**
```bash
curl -s http://localhost:8100/health | jq '.dependencies.lightrag // .dependencies.literag'
```

**Expected Behavior:**
LightRAG shows healthy status.

---

## Expected Results

- [ ] LightRAG accessible
- [ ] Configuration correct
- [ ] Health shows healthy

---

## Pass/Fail Criteria

### PASS Criteria
1. Connection works
2. Health shows healthy

### FAIL Criteria
1. Connection fails
2. Unhealthy status

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
