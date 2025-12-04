# Test Case: Verify Connection Pool Management

**Test ID**: tc-lang-server-integration-020-connection-pool-management
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: Redis Integration (50 max connections per Sri Patel review)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that connection pools are properly managed for Redis and PostgreSQL.

---

## Prerequisites

- [ ] Service running
- [ ] Access to database connection monitoring

---

## Test Steps

### Step 1: Check Redis Connection Count
**Action:**
```bash
redis-cli -h hx-redis-server.hx.dev.local CLIENT LIST | wc -l
echo "Active Redis connections above"
```

**Expected Behavior:**
Reasonable number of connections (<50 per service).

---

### Step 2: Check PostgreSQL Connection Count
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT COUNT(*) FROM pg_stat_activity WHERE usename = 'hx_lang_server';"
```

**Expected Behavior:**
Reasonable number of connections.

---

### Step 3: Submit Multiple Concurrent Requests
**Action:**
```bash
for i in {1..10}; do
  curl -s -X POST http://localhost:8100/invoke \
    -H "Content-Type: application/json" \
    -d '{"query": "Quick test"}' &
done
wait
echo "Concurrent requests completed"
```

**Expected Behavior:**
All requests complete without connection exhaustion.

---

### Step 4: Verify Pool Cleanup
**Action:**
```bash
sleep 5
redis-cli -h hx-redis-server.hx.dev.local CLIENT LIST | wc -l
echo "Connections after idle period"
```

**Expected Behavior:**
Connection count stable (pool reused, not growing).

---

## Expected Results

- [ ] Connection pools configured
- [ ] No connection leaks
- [ ] Pool limits respected

---

## Pass/Fail Criteria

### PASS Criteria
1. Pools configured correctly
2. No exhaustion on load
3. Connections cleaned up

### FAIL Criteria
1. Connection exhaustion
2. Connection leaks
3. Pool not configured

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
