# Test Case: Verify Service Account Creation

**Test ID**: tc-lang-server-deployment-001-service-account-creation
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-001, Service Account requirements
**Based on Plan**: Work Stream 1 - Identity & Infrastructure (Task 001)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the hx-lang-server service account has been created in Samba AD with correct properties: username `hx-lang-server`, domain `hx-lang-server@hx.dev.local`, home directory `/opt/hx-lang-server`, and shell `/bin/bash`.

**Why This Test Is Important:**
The service account is required for the systemd service to run under the correct security context, access the application directory, and authenticate against AD for any domain-joined resources.

---

## Prerequisites

**Service State:**
- [ ] Samba AD domain controller (hx-dc-server) accessible
- [ ] Administrative credentials available for account lookup

**Dependencies:**
- [ ] hx-dc-server.hx.dev.local reachable on network
- [ ] DNS resolution working for hx.dev.local domain

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local
- [ ] Administrative privileges for testing

**Permissions:**
- [ ] sudo access on target node

---

## Test Setup

### Pre-Test Actions
1. Ensure SSH connectivity to hx-lang-server.hx.dev.local
2. Verify network connectivity to hx-dc-server.hx.dev.local
3. Prepare to capture command outputs

### Test Data
**Required Test Data:**
- Expected username: `hx-lang-server`
- Expected home directory: `/opt/hx-lang-server`
- Expected shell: `/bin/bash`
- Expected domain: `hx.dev.local`

---

## Test Steps

### Step 1: Verify User Exists in Local System
**Action:**
```bash
id hx-lang-server
```

**Expected Behavior:**
Command returns user ID, group ID, and group memberships for hx-lang-server user.

**How to Verify:**
Output should contain `uid=` and `gid=` values for the hx-lang-server user.

---

### Step 2: Verify Home Directory Configuration
**Action:**
```bash
getent passwd hx-lang-server | cut -d: -f6
```

**Expected Behavior:**
Command returns `/opt/hx-lang-server` as the home directory.

**How to Verify:**
Output should exactly match `/opt/hx-lang-server`.

---

### Step 3: Verify Shell Configuration
**Action:**
```bash
getent passwd hx-lang-server | cut -d: -f7
```

**Expected Behavior:**
Command returns `/bin/bash` as the login shell.

**How to Verify:**
Output should exactly match `/bin/bash`.

---

### Step 4: Verify Home Directory Exists
**Action:**
```bash
ls -ld /opt/hx-lang-server
```

**Expected Behavior:**
Directory exists and is owned by hx-lang-server user.

**How to Verify:**
Output shows directory with owner `hx-lang-server` and appropriate permissions.

---

### Step 5: Verify AD Authentication (if applicable)
**Action:**
```bash
wbinfo -u | grep hx-lang-server
```

**Expected Behavior:**
If using AD authentication, user appears in Samba user list.

**How to Verify:**
Output contains `hx-lang-server` or `HX\hx-lang-server`.

---

## Expected Results

### Primary Expected Results
- [ ] User `hx-lang-server` exists with valid uid/gid
- [ ] Home directory is set to `/opt/hx-lang-server`
- [ ] Shell is set to `/bin/bash`
- [ ] Home directory exists on filesystem
- [ ] User can be authenticated via Samba/AD (if configured)

### Observable Indicators
**Logs:**
- No specific log entries expected

**Files:**
- `/opt/hx-lang-server` directory exists
- Directory permissions allow hx-lang-server user access

**System State:**
- User entry in `/etc/passwd` or NSS subsystem

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. `id hx-lang-server` returns valid uid/gid
2. Home directory is `/opt/hx-lang-server`
3. Shell is `/bin/bash`
4. Home directory exists and is accessible
5. No errors during verification

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. User does not exist (id command fails)
2. Home directory is incorrect
3. Shell is not `/bin/bash`
4. Home directory does not exist
5. Permissions prevent access

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Cannot SSH to target node
2. DNS resolution fails for domain
3. Samba AD is unavailable for verification

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
1. No cleanup required for read-only verification test

### Environment Reset
- [ ] No changes made to environment

---

## Notes and Observations

### Dependencies on Other Tests
- This test must pass before deployment-003 (Directory Structure)
- This test must pass before deployment-004 (Service Startup)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Service Account section

**Related Test Cases:**
- `tc-lang-server-deployment-003-directory-structure.md` - Depends on this test
- `tc-lang-server-deployment-009-systemd-service.md` - Uses this account

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
