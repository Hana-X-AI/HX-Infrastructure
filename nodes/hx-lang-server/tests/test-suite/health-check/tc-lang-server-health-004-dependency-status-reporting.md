# Test Case: Verify Dependency Status Reporting

**Test ID**: tc-lang-server-health-004-dependency-status-reporting
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-011 (Ready validates all dependencies)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that dependency status reporting accurately reflects the actual state of each dependency.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Access to dependency monitoring

---

## Test Steps

### Step 1: Get Full Dependency Status Report
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies'
```

**Expected Behavior:**
Complete list of all dependencies with status.

---

### Step 2: Verify PostgreSQL Status Accuracy
**Action:**
```bash
# Check PostgreSQL actual status
pg_isready -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server
echo "---"
# Compare with reported status
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies.postgresql'
```

**Expected Behavior:**
Reported status matches actual PostgreSQL state.

---

### Step 3: Verify Redis Status Accuracy
**Action:**
```bash
# Check Redis actual status
redis-cli -h hx-redis-server.hx.dev.local PING
echo "---"
# Compare with reported status
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies.redis'
```

**Expected Behavior:**
Reported status matches actual Redis state.

---

### Step 4: Verify Ollama Status Accuracy
**Action:**
```bash
# Check Ollama1 actual status
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags > /dev/null && echo "Ollama1: UP" || echo "Ollama1: DOWN"
# Check Ollama2 actual status
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags > /dev/null && echo "Ollama2: UP" || echo "Ollama2: DOWN"
echo "---"
# Compare with reported status
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies | {ollama1, ollama2}'
```

**Expected Behavior:**
Reported status matches actual Ollama states.

---

### Step 5: Verify LightRAG Status Accuracy
**Action:**
```bash
# Check LightRAG actual status
curl -s http://hx-lightrag-server.hx.dev.local:9621/health > /dev/null && echo "LightRAG: UP" || echo "LightRAG: DOWN"
echo "---"
# Compare with reported status
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.dependencies.lightrag'
```

**Expected Behavior:**
Reported status matches actual LightRAG state.

---

## Expected Results

- [ ] All dependencies listed in status report
- [ ] PostgreSQL status accurate
- [ ] Redis status accurate
- [ ] Ollama1/Ollama2 status accurate
- [ ] LightRAG status accurate

---

## Pass/Fail Criteria

### PASS Criteria
1. All dependencies included
2. All statuses accurate
3. Status updates reflect changes

### FAIL Criteria
1. Missing dependencies
2. Inaccurate status
3. Stale status data

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
