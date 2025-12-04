# Test Case: Session Persistence End-to-End

**Test ID**: tc-lang-server-e2e-004-session-persistence
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-004 (Sessions persist through service restarts via PostgreSQL)
**Test Type**: Manual
**Estimated Execution Time**: 15 minutes

---

## Test Objective

Validates that conversation sessions persist through service restarts using PostgreSQL checkpoints.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] PostgreSQL running with checkpoint tables
- [ ] sudo access for service restart

---

## Test Steps

### Step 1: Create New Session with Context
**Action:**
```bash
# Create session with initial context
response=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "My name is TestUser and I am testing session persistence. Remember this.",
    "session_id": "e2e-persistence-test-001"
  }' --max-time 60)
echo "Session created: $(echo $response | jq '.session_id')"
echo "Response: $(echo $response | jq '.response[:200]')"
```

**Expected Behavior:**
Session created with acknowledgment.

---

### Step 2: Add More Context to Session
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "I work on infrastructure deployment. Remember this too.",
    "session_id": "e2e-persistence-test-001"
  }' --max-time 60 | jq '.response[:200]'
```

**Expected Behavior:**
Context added to session.

---

### Step 3: Verify Session in PostgreSQL
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT thread_id, created_at FROM checkpoints WHERE thread_id LIKE '%e2e-persistence%' LIMIT 5;"
```

**Expected Behavior:**
Session checkpoint exists in database.

---

### Step 4: Restart Service
**Action:**
```bash
sudo systemctl restart hx-lang-server
echo "Waiting 15 seconds for restart..."
sleep 15
curl -s -o /dev/null -w "%{http_code}" http://hx-lang-server.hx.dev.local:8101/health
```

**Expected Behavior:**
Service restarts and health returns 200.

---

### Step 5: Verify Session Context Retained
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is my name and what do I work on?",
    "session_id": "e2e-persistence-test-001"
  }' --max-time 60 | jq '.response'
```

**Expected Behavior:**
Response includes "TestUser" and "infrastructure deployment" from previous context.

---

## Expected Results

- [ ] Session created successfully
- [ ] Context stored in session
- [ ] Checkpoint saved to PostgreSQL
- [ ] Service restart completes
- [ ] Session context retained after restart

---

## Pass/Fail Criteria

### PASS Criteria
1. Session persists through restart
2. Context accurately retained
3. PostgreSQL checkpoint functional

### FAIL Criteria
1. Session lost after restart
2. Context not remembered
3. Checkpoint not created

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
