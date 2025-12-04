# Test Case: Verify Ollama1 General Routing

**Test ID**: tc-lang-server-functionality-012-ollama1-general-routing
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-010 (Route general queries to hx-ollama1-server)
**Based on Plan**: Work Stream 7 (Ollama Integration)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that general queries (not matching code, rag, or tool patterns) are routed to Ollama1 (hx-ollama1-server.hx.dev.local:11434) using the general model (gemma3:27b).

**Why This Test Is Important:**
Correct routing ensures optimal model selection for different query types.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] Ollama1 accessible

---

## Test Steps

### Step 1: Submit General Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Tell me a joke"}' | jq '{query_type, worker_used, metadata}'
```

**Expected Behavior:**
query_type is "general", routed to general worker.

---

### Step 2: Verify LLM Used in Metadata
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is 2+2?"}' | jq '.metadata.llm_used // .metadata'
```

**Expected Behavior:**
Metadata indicates Ollama1 or general model.

---

### Step 3: Verify Response Quality
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain gravity in simple terms"}' | jq -r '.response' | head -c 300
```

**Expected Behavior:**
Coherent response from general model.

---

## Expected Results

### Primary Expected Results
- [ ] General queries classified correctly
- [ ] Routed to Ollama1/general model
- [ ] Quality responses generated

---

## Pass/Fail Criteria

### PASS Criteria
1. General queries routed correctly
2. Ollama1 used

### FAIL Criteria
1. Wrong routing
2. Ollama connection fails

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-010, Ollama Routing Table

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
