# Test Case: Verify Embedding via LightRAG

**Test ID**: tc-lang-server-functionality-014-embedding-via-lightrag
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-012 (Route embedding requests through LightRAG, NOT direct to ollama3)
**Based on Plan**: Work Stream 8 (LightRAG Integration)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that embedding requests go through LightRAG service rather than directly to Ollama3, ensuring consistent embedding handling.

**Why This Test Is Important:**
Centralized embedding through LightRAG ensures consistent vector representations and proper integration with the knowledge graph.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] LightRAG accessible

---

## Test Steps

### Step 1: Submit RAG Query Requiring Embeddings
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for information about Python programming"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
RAG agent handles query via LightRAG.

---

### Step 2: Check Logs for LightRAG Call
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -i "lightrag\|literag" | head -5
```

**Expected Behavior:**
Logs show LightRAG integration activity.

---

### Step 3: Verify No Direct Ollama3 Embedding Calls
**Action:**
```bash
# Check that service doesn't call Ollama3 directly for embeddings
# This is verified by configuration and logs
grep "OLLAMA.*EMBED\|ollama3" /opt/hx-lang-server/.env | wc -l
```

**Expected Behavior:**
No direct embedding endpoint configured.

---

## Expected Results

### Primary Expected Results
- [ ] Embeddings handled via LightRAG
- [ ] No direct Ollama3 embedding calls
- [ ] RAG queries use LightRAG service

---

## Pass/Fail Criteria

### PASS Criteria
1. Embeddings via LightRAG
2. No direct Ollama3 for embeddings

### FAIL Criteria
1. Direct embedding calls to Ollama
2. Bypass of LightRAG

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-012

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
