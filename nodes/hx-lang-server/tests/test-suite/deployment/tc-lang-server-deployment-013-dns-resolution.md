# Test Case: Verify DNS Resolution

**Test ID**: tc-lang-server-deployment-013-dns-resolution
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Node Requirements - Hostname hx-lang-server.hx.dev.local
**Based on Plan**: Work Stream 1 - Identity & Infrastructure (Task 002)
**Test Type**: Manual
**Estimated Execution Time**: 3 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that DNS resolution is correctly configured for hx-lang-server.hx.dev.local, resolving to the correct IP address (192.168.10.226), and that the server can resolve all dependent service hostnames.

**Why This Test Is Important:**
DNS resolution is critical for service discovery. All inter-service communication relies on hostname resolution. Incorrect DNS will cause connectivity failures to dependencies.

---

## Prerequisites

**Service State:**
- [ ] DNS record registered in Samba AD/DNS

**Dependencies:**
- [ ] hx-dc-server (DNS) accessible

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local or network access

**Permissions:**
- [ ] Standard user access

---

## Test Setup

### Pre-Test Actions
1. Establish access to target node
2. Verify network connectivity

### Test Data
**Required Test Data:**
- Target hostname: hx-lang-server.hx.dev.local
- Expected IP: 192.168.10.226
- Dependent services:
  - hx-postgres-server.hx.dev.local
  - hx-redis-server.hx.dev.local
  - hx-ollama1-server.hx.dev.local
  - hx-ollama2-server.hx.dev.local
  - hx-literag-server.hx.dev.local
  - hx-fastmcp-server.hx.dev.local

---

## Test Steps

### Step 1: Verify Forward DNS Resolution
**Action:**
```bash
nslookup hx-lang-server.hx.dev.local
```

**Expected Behavior:**
Returns IP address 192.168.10.226.

**How to Verify:**
Output contains "Address: 192.168.10.226".

---

### Step 2: Verify Using dig Command
**Action:**
```bash
dig +short hx-lang-server.hx.dev.local
```

**Expected Behavior:**
Returns 192.168.10.226.

**How to Verify:**
Output is exactly "192.168.10.226".

---

### Step 3: Verify Reverse DNS (if configured)
**Action:**
```bash
dig +short -x 192.168.10.226
```

**Expected Behavior:**
Returns hx-lang-server.hx.dev.local or empty (reverse may not be configured).

**How to Verify:**
Either returns hostname or empty (not an error).

---

### Step 4: Verify PostgreSQL Server Resolution
**Action:**
```bash
dig +short hx-postgres-server.hx.dev.local
```

**Expected Behavior:**
Returns valid IP address.

**How to Verify:**
IP address returned (format: 192.168.10.xxx).

---

### Step 5: Verify Redis Server Resolution
**Action:**
```bash
dig +short hx-redis-server.hx.dev.local
```

**Expected Behavior:**
Returns valid IP address.

**How to Verify:**
IP address returned.

---

### Step 6: Verify Ollama1 Server Resolution
**Action:**
```bash
dig +short hx-ollama1-server.hx.dev.local
```

**Expected Behavior:**
Returns valid IP address.

**How to Verify:**
IP address returned.

---

### Step 7: Verify Ollama2 Server Resolution
**Action:**
```bash
dig +short hx-ollama2-server.hx.dev.local
```

**Expected Behavior:**
Returns valid IP address.

**How to Verify:**
IP address returned.

---

### Step 8: Verify LightRAG Server Resolution
**Action:**
```bash
dig +short hx-literag-server.hx.dev.local
```

**Expected Behavior:**
Returns valid IP address.

**How to Verify:**
IP address returned.

---

### Step 9: Verify FastMCP Server Resolution
**Action:**
```bash
dig +short hx-fastmcp-server.hx.dev.local
```

**Expected Behavior:**
Returns valid IP address.

**How to Verify:**
IP address returned.

---

### Step 10: Verify getent Resolution
**Action:**
```bash
getent hosts hx-lang-server.hx.dev.local
```

**Expected Behavior:**
Returns IP and hostname using system resolver.

**How to Verify:**
Output contains 192.168.10.226 and hostname.

---

## Expected Results

### Primary Expected Results
- [ ] hx-lang-server.hx.dev.local resolves to 192.168.10.226
- [ ] hx-postgres-server.hx.dev.local resolves
- [ ] hx-redis-server.hx.dev.local resolves
- [ ] hx-ollama1-server.hx.dev.local resolves
- [ ] hx-ollama2-server.hx.dev.local resolves
- [ ] hx-literag-server.hx.dev.local resolves
- [ ] hx-fastmcp-server.hx.dev.local resolves
- [ ] All resolutions are consistent (nslookup, dig, getent)

### Observable Indicators
**Network:**
- DNS queries return valid responses
- No NXDOMAIN errors

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. hx-lang-server resolves to correct IP
2. All dependent service hostnames resolve
3. Resolution is consistent across tools
4. No DNS errors

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. hx-lang-server does not resolve
2. Wrong IP returned for hx-lang-server
3. Any dependent service does not resolve
4. DNS timeout or NXDOMAIN errors

### BLOCKED Criteria
**Test is BLOCKED if:**
1. DNS server not accessible
2. Network connectivity issues

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

---

## Test Cleanup

### Post-Test Actions
1. No cleanup required

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Required for all integration and E2E tests
- Prerequisite for service connectivity

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Node Requirements, Dependencies

**Related Test Cases:**
- `tc-lang-server-integration-*` - All integration tests depend on DNS

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
