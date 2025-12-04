# Test Case: Verify Ollama Model Inference

**Test ID**: tc-lang-server-integration-010-ollama-model-inference
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: LLM Integration requirements
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that actual inference works through both Ollama servers.

---

## Prerequisites

- [ ] Both Ollama servers accessible
- [ ] Models loaded and ready

---

## Test Steps

### Step 1: Test General Inference via Service
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is 5+3?"}' | jq -r '.response[:100]'
```

**Expected Behavior:**
Valid response with answer.

---

### Step 2: Test Code Inference via Service
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a Python hello world"}' | jq -r '.response[:200]'
```

**Expected Behavior:**
Code response generated.

---

### Step 3: Measure Inference Time
**Action:**
```bash
time curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Brief answer: what color is the sky?"}' > /dev/null
```

**Expected Behavior:**
Response within 5 seconds (NFR-001).

---

## Expected Results

- [ ] General inference works
- [ ] Code inference works
- [ ] Response times acceptable

---

## Pass/Fail Criteria

### PASS Criteria
1. Both inference types work
2. Response times <5s

### FAIL Criteria
1. Inference fails
2. Timeouts

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
