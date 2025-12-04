# Test Case: Verify LightRAG Query Execution

**Test ID**: tc-lang-server-integration-012-lightrag-query-execution
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-014-016 (LightRAG integration)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that RAG queries are executed through LightRAG.

---

## Prerequisites

- [ ] LightRAG connection working
- [ ] Documents indexed (optional for full test)

---

## Test Steps

### Step 1: Submit RAG Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for documentation about Python"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
Query routed to RAG agent.

---

### Step 2: Verify LightRAG Activity
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -i "lightrag\|literag\|rag.*query" | head -5
```

**Expected Behavior:**
LightRAG calls logged.

---

### Step 3: Verify Response Quality
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain what Python is used for"}' | jq -r '.response[:300]'
```

**Expected Behavior:**
Substantive response with context.

---

## Expected Results

- [ ] RAG queries work
- [ ] LightRAG invoked
- [ ] Quality responses

---

## Pass/Fail Criteria

### PASS Criteria
1. RAG queries succeed
2. LightRAG used

### FAIL Criteria
1. RAG queries fail
2. No LightRAG activity

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
