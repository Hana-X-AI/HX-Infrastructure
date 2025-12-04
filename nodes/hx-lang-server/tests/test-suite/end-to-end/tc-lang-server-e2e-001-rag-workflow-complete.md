# Test Case: RAG Workflow Complete End-to-End

**Test ID**: tc-lang-server-e2e-001-rag-workflow-complete
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-006 (RAG agent enriches responses with context)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates the complete RAG workflow from query submission through LightRAG context retrieval to response generation.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] LightRAG service running with indexed content
- [ ] Ollama1 service running

---

## Test Steps

### Step 1: Submit RAG-Appropriate Query
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the key components of the HX-Infrastructure system architecture?"
  }' --max-time 120 | jq '.'
```

**Expected Behavior:**
Response returned with RAG-enriched content.

---

### Step 2: Verify Worker Selection
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Search for information about service deployment procedures"
  }' --max-time 120 | jq '.worker_used'
```

**Expected Behavior:**
Worker should be "rag" or "rag_agent".

---

### Step 3: Verify Context Sources Referenced
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Find documentation about infrastructure nodes"
  }' --max-time 120 | jq '.sources // .context_sources // .metadata.sources'
```

**Expected Behavior:**
Sources/context references included in response.

---

### Step 4: Verify LightRAG Interaction in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "lightrag|rag.*query|context.*retriev" | head -10
```

**Expected Behavior:**
LightRAG interactions logged.

---

### Step 5: Verify Response Quality
**Action:**
```bash
# Submit query and check response length/quality
response=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain the purpose of the knowledge vault"}' --max-time 120)
echo "Response length: $(echo $response | jq -r '.response' | wc -c) characters"
echo "First 500 chars: $(echo $response | jq -r '.response[:500]')"
```

**Expected Behavior:**
Substantive response with relevant context.

---

## Expected Results

- [ ] RAG queries processed successfully
- [ ] RAG worker selected for knowledge queries
- [ ] Context sources included
- [ ] LightRAG integration logged
- [ ] Response quality acceptable

---

## Pass/Fail Criteria

### PASS Criteria
1. Complete RAG workflow executes
2. Context enrichment visible
3. Response relevant to query

### FAIL Criteria
1. RAG workflow fails
2. No context retrieved
3. Generic/irrelevant response

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
