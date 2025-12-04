# Test Case: Verify Ollama1 Connection

**Test ID**: tc-lang-server-integration-008-ollama1-connection
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-010 (Route general queries to hx-ollama1-server)
**Integration Point**: hx-ollama1-server.hx.dev.local:11434
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server can connect to Ollama1 (general LLM server).

---

## Prerequisites

- [ ] Ollama1 accessible at hx-ollama1-server.hx.dev.local:11434

---

## Test Steps

### Step 1: Verify Ollama1 Connectivity
**Action:**
```bash
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/version | jq .
```

**Expected Behavior:**
Ollama version returned.

---

### Step 2: Verify Configuration
**Action:**
```bash
grep "OLLAMA_GENERAL" /opt/hx-lang-server/.env
```

**Expected Behavior:**
URL and model configured.

---

### Step 3: Test Service Health with Ollama1
**Action:**
```bash
curl -s http://localhost:8100/health | jq '.dependencies.ollama_general // .dependencies.ollama1'
```

**Expected Behavior:**
Ollama1 shows healthy status.

---

### Step 4: Verify Model Available
**Action:**
```bash
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | jq '.models[].name' | head -5
```

**Expected Behavior:**
Models listed (should include gemma3:27b or configured model).

---

## Expected Results

- [ ] Ollama1 accessible
- [ ] Configuration correct
- [ ] Health check passes
- [ ] Model available

---

## Pass/Fail Criteria

### PASS Criteria
1. Connection works
2. Model available
3. Health shows healthy

### FAIL Criteria
1. Connection fails
2. Model missing
3. Unhealthy status

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
