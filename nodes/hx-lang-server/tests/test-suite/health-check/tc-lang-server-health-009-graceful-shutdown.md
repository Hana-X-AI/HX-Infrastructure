# Test Case: Verify Graceful Shutdown

**Test ID**: tc-lang-server-health-009-graceful-shutdown
**Service**: hx-lang-server
**Test Area**: health-check
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: Operational Requirements (graceful shutdown handling)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the service shuts down gracefully, completing in-flight requests and closing connections properly.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] sudo access for service stop
- [ ] Ability to monitor connections

---

## Test Steps

### Step 1: Check Current Connections Before Shutdown
**Action:**
```bash
ss -tp | grep hx-lang | wc -l
echo "Active connections before shutdown"
```

**Expected Behavior:**
Current connection count displayed.

---

### Step 2: Stop Service Gracefully
**Action:**
```bash
sudo systemctl stop hx-lang-server
echo "Stop command issued"
```

**Expected Behavior:**
Stop command completes.

---

### Step 3: Verify Clean Shutdown in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "2 minutes ago" | grep -iE "shutdown|stopping|terminated|closed" | tail -10
```

**Expected Behavior:**
Graceful shutdown messages logged (connections closed, cleanup performed).

---

### Step 4: Verify No Orphaned Connections
**Action:**
```bash
ss -tp | grep hx-lang | wc -l
echo "Connections after shutdown (should be 0)"
```

**Expected Behavior:**
Zero active connections.

---

### Step 5: Verify No Zombie Processes
**Action:**
```bash
ps aux | grep "[h]x-lang-server"
echo "Should show no processes"
```

**Expected Behavior:**
No hx-lang-server processes running.

---

### Step 6: Restart Service for Cleanup
**Action:**
```bash
sudo systemctl start hx-lang-server
sleep 5
systemctl is-active hx-lang-server
```

**Expected Behavior:**
Service restarts and becomes active.

---

## Expected Results

- [ ] Service stops without errors
- [ ] Shutdown logged gracefully
- [ ] All connections closed
- [ ] No orphaned processes
- [ ] Service can restart

---

## Pass/Fail Criteria

### PASS Criteria
1. Clean shutdown logged
2. All connections closed
3. No orphaned processes
4. Restart succeeds

### FAIL Criteria
1. Forced termination required
2. Orphaned connections
3. Zombie processes left
4. Restart fails

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
