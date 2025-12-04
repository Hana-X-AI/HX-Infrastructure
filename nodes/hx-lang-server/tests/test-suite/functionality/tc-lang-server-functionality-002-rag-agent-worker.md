# Test Case: Verify RAG Agent Worker

**Test ID**: tc-lang-server-functionality-002-rag-agent-worker
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-002 (Worker agent types: RAG Agent), FR-014-016 (LightRAG integration)
**Based on Plan**: Work Stream 6 (Task 054), Work Stream 8 (LightRAG Integration)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the RAG Agent worker correctly handles retrieval-augmented generation queries by integrating with LightRAG to fetch relevant context before generating responses.

**Why This Test Is Important:**
RAG is a core capability for knowledge-enhanced responses. The RAG agent must correctly query LightRAG and incorporate retrieved context into responses.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy
- [ ] RAG agent registered with supervisor

**Dependencies:**
- [ ] LightRAG service accessible (hx-literag-server.hx.dev.local:8020)
- [ ] Ollama1 accessible for response generation
- [ ] Documents ingested in LightRAG (optional, for full test)

**Environment:**
- [ ] Access to API on port 8100

**Permissions:**
- [ ] API access

---

## Test Setup

### Pre-Test Actions
1. Verify service is running
2. Verify LightRAG is accessible
3. Optionally verify documents are indexed

### Test Data
**Required Test Data:**
- RAG trigger queries (containing keywords: search, find, document, knowledge, explain)
- Example: "Search for information about Python programming"

---

## Test Steps

### Step 1: Submit RAG Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for information about Python best practices"}' | jq .
```

**Expected Behavior:**
Query routed to RAG agent, response includes RAG context.

**How to Verify:**
worker_used indicates RAG agent, response generated.

---

### Step 2: Verify RAG Worker Selection
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Find documents about machine learning"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
query_type is "rag", worker_used is rag_agent.

**How to Verify:**
Both fields indicate RAG processing.

---

### Step 3: Verify "Explain" Keyword Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain how neural networks work"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"Explain" keyword triggers RAG routing.

**How to Verify:**
query_type is "rag".

---

### Step 4: Verify "What is" Keyword Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is containerization?"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"What is" phrase triggers RAG routing.

**How to Verify:**
query_type is "rag".

---

### Step 5: Verify RAG Context in Metadata
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for Python documentation patterns"}' | jq '.metadata'
```

**Expected Behavior:**
Metadata may include RAG-related information.

**How to Verify:**
metadata object present with execution details.

---

### Step 6: Verify Response Quality with RAG
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain the concept of dependency injection"}' | jq '.response' | head -c 500
```

**Expected Behavior:**
Response is substantive and contextual.

**How to Verify:**
Response text is relevant to the query.

---

### Step 7: Verify Error Handling When LightRAG Unavailable
**Action:**
```bash
# This test should be run when LightRAG is intentionally unavailable or mocked
# During normal testing, verify graceful degradation is documented
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for something when RAG is down"}' | jq '.metadata.errors // "No errors captured"'
```

**Expected Behavior:**
Graceful degradation or error is reported.

**How to Verify:**
Either fallback behavior or error documented.

---

## Expected Results

### Primary Expected Results
- [ ] RAG queries routed to RAG agent
- [ ] query_type correctly classified as "rag"
- [ ] worker_used shows rag_agent
- [ ] Keyword triggers work (search, find, document, knowledge, explain, what is)
- [ ] Response includes retrieved context (when available)
- [ ] Graceful degradation when LightRAG unavailable

### Observable Indicators
**API Response:**
- query_type: "rag"
- worker_used: "rag_agent" or similar
- Response includes contextual information

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. RAG keywords trigger RAG agent
2. query_type correctly identified as "rag"
3. worker_used indicates RAG agent
4. Valid response generated
5. No server errors

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. RAG queries not routed to RAG agent
2. query_type incorrect
3. Server error on RAG query
4. No response generated
5. Crashes when LightRAG unavailable

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. LightRAG completely inaccessible (for full test)

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
1. No cleanup required

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Requires tc-lang-server-functionality-001 to pass
- Related to integration-011 (LightRAG connection)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-002, FR-014-016

**Related Test Cases:**
- `tc-lang-server-functionality-016-lightrag-http.md`
- `tc-lang-server-integration-011-lightrag-connection.md`
- `tc-lang-server-e2e-003-lightrag-rag-workflow.md`

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
