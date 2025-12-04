# Test Case: Worker Handoff End-to-End

**Test ID**: tc-lang-server-e2e-009-worker-handoff
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-004 (Supervisor orchestrates worker selection)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates that the supervisor correctly hands off queries to appropriate workers and synthesizes results.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] All workers functional (RAG, Code, Tool)

---

## Test Steps

### Step 1: Verify RAG Worker Handoff
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Search the knowledge base for information about deployment procedures"
  }' --max-time 120 | jq '{worker: .worker_used, response_preview: .response[:150]}'
```

**Expected Behavior:**
RAG worker selected for knowledge-seeking query.

---

### Step 2: Verify Code Worker Handoff
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Write a Python script to process JSON files"
  }' --max-time 120 | jq '{worker: .worker_used, response_preview: .response[:150]}'
```

**Expected Behavior:**
Code worker selected for code generation query.

---

### Step 3: Verify Tool Worker Handoff
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Fetch and analyze the content from a website"
  }' --max-time 120 | jq '{worker: .worker_used, response_preview: .response[:150]}'
```

**Expected Behavior:**
Tool worker selected for external tool query.

---

### Step 4: Verify General Query Handling
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the weather like today?"
  }' --max-time 60 | jq '{worker: .worker_used, response_preview: .response[:150]}'
```

**Expected Behavior:**
Appropriate worker selected (or general response).

---

### Step 5: Verify Worker Selection Logged
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -iE "worker.*select|handoff|dispatch|route.*agent" | head -10
```

**Expected Behavior:**
Worker selection decisions logged.

---

### Step 6: Test Mixed Query Handling
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Search for Python best practices and write an example function following them"
  }' --max-time 120 | jq '{worker: .worker_used, response_preview: .response[:200]}'
```

**Expected Behavior:**
Response combines RAG context with code generation.

---

## Expected Results

- [ ] RAG worker handles knowledge queries
- [ ] Code worker handles programming queries
- [ ] Tool worker handles external tool queries
- [ ] General queries handled appropriately
- [ ] Worker selection logged
- [ ] Mixed queries handled

---

## Pass/Fail Criteria

### PASS Criteria
1. Correct worker selection
2. Appropriate responses
3. Handoff logged

### FAIL Criteria
1. Wrong worker selected
2. Handoff fails
3. No response generated

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
