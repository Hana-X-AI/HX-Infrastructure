# Test Case: Full System Integration End-to-End

**Test ID**: tc-lang-server-e2e-010-full-system-integration
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-001 through SC-014 (All success criteria)
**Test Type**: Manual
**Estimated Execution Time**: 20 minutes

---

## Test Objective

Validates complete system integration exercising all components: supervisor, workers, dependencies, persistence, and monitoring.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] All dependencies running (PostgreSQL, Redis, Ollama1, Ollama2, LightRAG, FastMCP)
- [ ] Full system access

---

## Test Steps

### Step 1: Verify All Dependencies Connected
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/ready | jq '.'
```

**Expected Behavior:**
All dependencies show healthy/connected status.

---

### Step 2: Create Persistent Session
**Action:**
```bash
session_id="full-integration-$(date +%s)"
echo "Session: $session_id"

curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Initialize integration test session. I am testing full system integration.\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response[:200]'
```

**Expected Behavior:**
Session created and response received.

---

### Step 3: Exercise RAG Workflow
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Search for infrastructure documentation\",
    \"session_id\": \"$session_id\"
  }" --max-time 120 | jq '{worker: .worker_used, has_response: (.response | length > 0)}'
```

**Expected Behavior:**
RAG workflow completes with context.

---

### Step 4: Exercise Code Workflow
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Write a function based on what we found\",
    \"session_id\": \"$session_id\"
  }" --max-time 120 | jq '{worker: .worker_used, has_response: (.response | length > 0)}'
```

**Expected Behavior:**
Code workflow completes with code output.

---

### Step 5: Verify Session Persistence
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"What have we discussed so far in this session?\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response[:300]'
```

**Expected Behavior:**
Summary includes RAG search and code generation from earlier.

---

### Step 6: Verify Redis Caching
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*" | head -5
```

**Expected Behavior:**
Cache entries present.

---

### Step 7: Verify PostgreSQL Checkpoints
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT COUNT(*) as checkpoint_count FROM checkpoints WHERE created_at > NOW() - INTERVAL '30 minutes';"
```

**Expected Behavior:**
Recent checkpoints exist.

---

### Step 8: Verify Metrics Collection
**Action:**
```bash
curl -s http://hx-lang-server.hx.dev.local:8101/metrics | grep -E "^http_requests" | head -5
```

**Expected Behavior:**
Request metrics updated from test activity.

---

### Step 9: Test Streaming Integration
**Action:**
```bash
curl -N -s -X POST http://hx-lang-server.hx.dev.local:8100/stream \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Summarize our integration test\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | head -10
```

**Expected Behavior:**
Streaming response with session context.

---

### Step 10: Final Health Verification
**Action:**
```bash
echo "=== Final Health Check ==="
curl -s http://hx-lang-server.hx.dev.local:8101/health | jq '.'
echo ""
echo "=== Service Status ==="
systemctl is-active hx-lang-server
echo ""
echo "=== No Errors in Last 10 Minutes ==="
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -c "ERROR" || echo "0 errors"
```

**Expected Behavior:**
Health check passes, service active, minimal/no errors.

---

## Expected Results

- [ ] All dependencies connected
- [ ] Session created and persisted
- [ ] RAG workflow functional
- [ ] Code workflow functional
- [ ] Session context maintained
- [ ] Redis caching active
- [ ] PostgreSQL checkpoints working
- [ ] Metrics collection functional
- [ ] Streaming works with session
- [ ] System healthy after all tests

---

## Pass/Fail Criteria

### PASS Criteria
1. All 10 steps complete successfully
2. All components integrated
3. System remains healthy

### FAIL Criteria
1. Any component fails
2. Integration breaks
3. System unstable after test

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
