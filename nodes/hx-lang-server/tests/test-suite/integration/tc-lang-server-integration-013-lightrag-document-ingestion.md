# Test Case: Verify LightRAG Document Ingestion

**Test ID**: tc-lang-server-integration-013-lightrag-document-ingestion
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: LightRAG integration for RAG
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that document ingestion works through LightRAG integration.

---

## Prerequisites

- [ ] LightRAG connection working

---

## Test Steps

### Step 1: Check LightRAG Document API
**Action:**
```bash
curl -s http://hx-literag-server.hx.dev.local:8020/documents 2>/dev/null | head -c 200 || echo "Check document endpoint"
```

**Expected Behavior:**
Document API accessible.

---

### Step 2: Verify Ingestion via Service (if supported)
**Action:**
```bash
# This depends on service implementation
curl -s http://localhost:8100/openapi.json | jq '.paths | keys' | grep -i "document\|ingest"
```

**Expected Behavior:**
Document/ingestion endpoint may exist.

---

### Step 3: Test RAG with Indexed Content
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What documents are available?"}' | jq -r '.response[:200]'
```

**Expected Behavior:**
Response reflects indexed content.

---

## Expected Results

- [ ] Document API accessible
- [ ] Ingestion pathway exists
- [ ] RAG reflects content

---

## Pass/Fail Criteria

### PASS Criteria
1. Integration pathway works
2. No ingestion errors

### FAIL Criteria
1. Ingestion fails
2. Documents not searchable

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
