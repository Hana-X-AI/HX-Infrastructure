# Test Case: Verify Ollama2 Connection

**Test ID**: tc-lang-server-integration-009-ollama2-connection
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-011 (Route code queries to hx-ollama2-server)
**Integration Point**: hx-ollama2-server.hx.dev.local:11434
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server can connect to Ollama2 (code LLM server).

---

## Prerequisites

- [ ] Ollama2 accessible at hx-ollama2-server.hx.dev.local:11434

---

## Test Steps

### Step 1: Verify Ollama2 Connectivity
**Action:**
```bash
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/version | jq .
```

**Expected Behavior:**
Ollama version returned.

---

### Step 2: Verify Configuration
**Action:**
```bash
grep "OLLAMA_CODE" /opt/hx-lang-server/.env
```

**Expected Behavior:**
URL and model configured.

---

### Step 3: Test Service Health with Ollama2
**Action:**
```bash
curl -s http://localhost:8100/health | jq '.dependencies.ollama_code // .dependencies.ollama2'
```

**Expected Behavior:**
Ollama2 shows healthy status.

---

### Step 4: Verify Code Model Available
**Action:**
```bash
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | jq '.models[].name' | head -5
```

**Expected Behavior:**
Code model listed (qwen3-coder:30b or configured).

---

## Expected Results

- [ ] Ollama2 accessible
- [ ] Configuration correct
- [ ] Health shows healthy
- [ ] Code model available

---

## Pass/Fail Criteria

### PASS Criteria
1. Connection works
2. Model available
3. Health shows healthy

### FAIL Criteria
1. Connection fails
2. Model missing

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
