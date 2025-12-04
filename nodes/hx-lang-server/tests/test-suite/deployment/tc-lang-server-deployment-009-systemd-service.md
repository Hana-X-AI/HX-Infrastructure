# Test Case: Verify systemd Service Unit

**Test ID**: tc-lang-server-deployment-009-systemd-service
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: systemd Service Configuration section
**Based on Plan**: Work Stream 13 - Service Deployment (Task 141)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the systemd service unit file is correctly configured with proper user, working directory, environment file, restart policy, and resource limits as specified in the node specification.

**Why This Test Is Important:**
The systemd unit file controls how the service starts, runs, and recovers from failures. Incorrect configuration can lead to service instability or security issues.

---

## Prerequisites

**Service State:**
- [ ] Service unit file installed

**Dependencies:**
- [ ] systemd available

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] sudo access for systemctl operations

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection
2. Verify systemd is running

### Test Data
**Required Test Data:**
Per specification:
- User: hx-lang-server
- Group: hx-lang-server
- WorkingDirectory: /opt/hx-lang-server
- EnvironmentFile: /opt/hx-lang-server/.env
- ExecStart: uvicorn command
- Restart: always
- RestartSec: 5
- MemoryMax: 16G
- LimitNOFILE: 65536

---

## Test Steps

### Step 1: Verify Unit File Exists
**Action:**
```bash
ls -l /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
Service unit file exists.

**How to Verify:**
File is present in systemd directory.

---

### Step 2: Verify User Configuration
**Action:**
```bash
grep "^User=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
User is set to hx-lang-server.

**How to Verify:**
Output: User=hx-lang-server

---

### Step 3: Verify Group Configuration
**Action:**
```bash
grep "^Group=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
Group is set to hx-lang-server.

**How to Verify:**
Output: Group=hx-lang-server

---

### Step 4: Verify Working Directory
**Action:**
```bash
grep "^WorkingDirectory=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
WorkingDirectory is /opt/hx-lang-server.

**How to Verify:**
Output: WorkingDirectory=/opt/hx-lang-server

---

### Step 5: Verify Environment File
**Action:**
```bash
grep "^EnvironmentFile=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
EnvironmentFile points to .env file.

**How to Verify:**
Output: EnvironmentFile=/opt/hx-lang-server/.env

---

### Step 6: Verify ExecStart Command
**Action:**
```bash
grep "^ExecStart=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
ExecStart runs uvicorn with correct parameters.

**How to Verify:**
Output contains uvicorn with host 0.0.0.0 and port 8100.

---

### Step 7: Verify Restart Policy
**Action:**
```bash
grep -E "^Restart=|^RestartSec=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
Restart=always, RestartSec=5.

**How to Verify:**
Both values match specification.

---

### Step 8: Verify Memory Limit
**Action:**
```bash
grep "^MemoryMax=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
MemoryMax=16G (matches minimum memory requirement).

**How to Verify:**
Output: MemoryMax=16G

---

### Step 9: Verify File Descriptor Limit
**Action:**
```bash
grep "^LimitNOFILE=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
LimitNOFILE=65536.

**How to Verify:**
Output: LimitNOFILE=65536

---

### Step 10: Verify Unit Dependencies
**Action:**
```bash
grep -E "^After=|^Wants=" /etc/systemd/system/hx-lang-server.service
```

**Expected Behavior:**
Dependencies on network and potentially database services.

**How to Verify:**
After= includes network.target.

---

### Step 11: Verify Unit is Enabled
**Action:**
```bash
sudo systemctl is-enabled hx-lang-server
```

**Expected Behavior:**
Service is enabled to start on boot.

**How to Verify:**
Output: enabled

---

### Step 12: Verify Unit Loads Without Errors
**Action:**
```bash
sudo systemctl status hx-lang-server 2>&1 | head -3
```

**Expected Behavior:**
Unit loads without syntax errors.

**How to Verify:**
No "Failed to load" or syntax error messages.

---

## Expected Results

### Primary Expected Results
- [ ] Unit file exists at /etc/systemd/system/hx-lang-server.service
- [ ] User=hx-lang-server
- [ ] Group=hx-lang-server
- [ ] WorkingDirectory=/opt/hx-lang-server
- [ ] EnvironmentFile=/opt/hx-lang-server/.env
- [ ] ExecStart uses uvicorn
- [ ] Restart=always, RestartSec=5
- [ ] MemoryMax=16G
- [ ] LimitNOFILE=65536
- [ ] Service is enabled
- [ ] Unit loads without errors

### Observable Indicators
**Files:**
- Unit file exists in /etc/systemd/system/

**System State:**
- systemctl is-enabled returns "enabled"
- systemctl status shows no load errors

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Unit file exists
2. All required configuration values correct
3. Service is enabled
4. Unit loads without errors
5. Dependencies configured

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Unit file missing
2. Any required configuration incorrect
3. Service not enabled
4. Unit has load errors
5. Wrong user/group

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Cannot access systemd directory
2. systemd not running

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
1. No cleanup required for read-only verification

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Required for deployment-004 (Service Startup)
- Related to deployment-001 (Service Account)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - systemd Service Configuration section

**Related Test Cases:**
- `tc-lang-server-deployment-001-service-account-creation.md` - Account used in unit
- `tc-lang-server-deployment-004-service-startup.md` - Uses this unit

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
