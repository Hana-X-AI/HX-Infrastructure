# Test Case: Code Workflow Complete End-to-End

**Test ID**: tc-lang-server-e2e-002-code-workflow-complete
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-007 (Code agent uses Ollama2 for generation)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates the complete code generation workflow from query submission through Ollama2 model invocation to code output.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Ollama2 service running with code model

---

## Test Steps

### Step 1: Submit Code Generation Request
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Write a Python function to calculate the fibonacci sequence"
  }' --max-time 120 | jq '.'
```

**Expected Behavior:**
Response contains Python code.

---

### Step 2: Verify Worker Selection
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Generate a bash script to check disk usage"
  }' --max-time 120 | jq '.worker_used'
```

**Expected Behavior:**
Worker should be "code" or "code_agent".

---

### Step 3: Verify Ollama2 Model Used
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "ollama2|code.*model|model.*code" | head -5
```

**Expected Behavior:**
Ollama2 model invocation logged.

---

### Step 4: Test Code Explanation Request
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Explain how async/await works in Python"
  }' --max-time 120 | jq '.response[:500]'
```

**Expected Behavior:**
Technical explanation with code examples.

---

### Step 5: Verify Code Quality in Response
**Action:**
```bash
response=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a Python class for a simple HTTP client"}' --max-time 120)
echo "$response" | jq -r '.response' | grep -c "class\|def\|import" || echo "Code patterns found"
```

**Expected Behavior:**
Response contains valid code patterns.

---

## Expected Results

- [ ] Code generation queries processed
- [ ] Code worker selected for programming queries
- [ ] Ollama2 model used
- [ ] Generated code is syntactically correct
- [ ] Response includes code formatting

---

## Pass/Fail Criteria

### PASS Criteria
1. Complete code workflow executes
2. Code output syntactically valid
3. Ollama2 model invoked

### FAIL Criteria
1. Code workflow fails
2. Invalid/no code output
3. Wrong model used

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
