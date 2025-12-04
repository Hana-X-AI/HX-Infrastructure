# Test Case: Verify LightRAG HTTP Integration

**Test ID**: tc-lang-server-functionality-016-lightrag-http-integration
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-014 (Integrate with hx-literag-server via HTTP API)
**Based on Plan**: Work Stream 8 (LightRAG Integration)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that hx-lang-server correctly integrates with LightRAG via HTTP API for retrieval-augmented generation.

---

## Prerequisites

**Service State:**
- [ ] Service running
- [ ] LightRAG accessible at hx-literag-server.hx.dev.local:8020

---

## Test Steps

### Step 1: Verify LightRAG URL Configuration
**Action:**
```bash
grep "LIGHTRAG_URL" /opt/hx-lang-server/.env
```

**Expected Behavior:**
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:8020

---

### Step 2: Submit RAG Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Find documentation about API design patterns"}' | jq .
```

**Expected Behavior:**
RAG agent processes query using LightRAG.

---

### Step 3: Verify LightRAG Activity in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -i "lightrag\|literag\|rag" | head -5
```

**Expected Behavior:**
LightRAG calls logged.

---

## Expected Results

- [ ] LightRAG URL configured correctly
- [ ] RAG queries invoke LightRAG
- [ ] Successful integration

---

## Pass/Fail Criteria

### PASS Criteria
1. LightRAG configured
2. RAG queries work

### FAIL Criteria
1. LightRAG not configured
2. RAG queries fail

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-014

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
