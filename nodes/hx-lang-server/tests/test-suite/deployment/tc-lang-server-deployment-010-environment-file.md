# Test Case: Verify Environment File

**Test ID**: tc-lang-server-deployment-010-environment-file
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Configuration Management, Environment Variables section
**Based on Plan**: Work Stream 13 - Service Deployment (Task 142)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the environment file (.env) contains all required variables with valid formats and that secrets are properly managed (not exposed in plaintext logs or accessible to unauthorized users).

**Why This Test Is Important:**
The environment file drives runtime configuration. Invalid or missing variables will cause service failures. Improper security can expose sensitive credentials.

---

## Prerequisites

**Service State:**
- [ ] Configuration files deployed (deployment-007 passed)

**Dependencies:**
- [ ] Ansible Vault credentials deployed

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] sudo access for permission verification

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection
2. Verify directory structure exists

### Test Data
**Required Test Data:**
All required environment variables per specification.

---

## Test Steps

### Step 1: Verify File Exists and Permissions
**Action:**
```bash
stat -c '%a %U:%G %n' /opt/hx-lang-server/.env
```

**Expected Behavior:**
File exists with restrictive permissions.

**How to Verify:**
Permissions 640 or less, owner hx-lang-server.

---

### Step 2: Count Required Variables
**Action:**
```bash
grep -c "^[A-Z]" /opt/hx-lang-server/.env
```

**Expected Behavior:**
At least 15 required variables defined.

**How to Verify:**
Count >= 15 (all required variables).

---

### Step 3: Validate URL Formats
**Action:**
```bash
grep "_URL=" /opt/hx-lang-server/.env | while read line; do
    url=$(echo "$line" | cut -d= -f2)
    if [[ $url =~ ^(http|https|redis):// ]]; then
        echo "VALID: $line"
    else
        echo "INVALID: $line"
    fi
done
```

**Expected Behavior:**
All URL variables have valid format.

**How to Verify:**
All lines show "VALID".

---

### Step 4: Validate Port Values
**Action:**
```bash
grep "_PORT=" /opt/hx-lang-server/.env | while read line; do
    port=$(echo "$line" | cut -d= -f2)
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -gt 0 ] && [ $port -lt 65536 ]; then
        echo "VALID: $line"
    else
        echo "INVALID: $line"
    fi
done
```

**Expected Behavior:**
All port values are valid numbers.

**How to Verify:**
All lines show "VALID".

---

### Step 5: Validate Hostname Formats
**Action:**
```bash
grep "_HOST=" /opt/hx-lang-server/.env | grep -E "hx-.*\.hx\.dev\.local" | wc -l
```

**Expected Behavior:**
All hostnames follow HX naming convention.

**How to Verify:**
Count matches number of HOST variables.

---

### Step 6: Verify No Exposed Secrets in World-Readable
**Action:**
```bash
# Check file is not world-readable
stat -c '%a' /opt/hx-lang-server/.env | grep -v "..4\|..5\|..6\|..7"
```

**Expected Behavior:**
File has no world-read permissions.

**How to Verify:**
Last digit of permissions is 0 (not 4, 5, 6, or 7).

---

### Step 7: Verify LOG_LEVEL Valid
**Action:**
```bash
grep "^LOG_LEVEL=" /opt/hx-lang-server/.env | grep -E "(DEBUG|INFO|WARNING|ERROR|CRITICAL)"
```

**Expected Behavior:**
LOG_LEVEL is a valid Python logging level.

**How to Verify:**
Match found (typically INFO for production).

---

### Step 8: Verify Integer Parameters
**Action:**
```bash
grep -E "^MAX_RECURSION_DEPTH=|^SESSION_TTL_SECONDS=" /opt/hx-lang-server/.env | while read line; do
    val=$(echo "$line" | cut -d= -f2)
    if [[ $val =~ ^[0-9]+$ ]]; then
        echo "VALID: $line"
    else
        echo "INVALID: $line"
    fi
done
```

**Expected Behavior:**
Numeric parameters are valid integers.

**How to Verify:**
All show "VALID".

---

### Step 9: Verify Model Names
**Action:**
```bash
grep "_MODEL=" /opt/hx-lang-server/.env | grep -E "gemma|qwen|llama"
```

**Expected Behavior:**
Model names match expected Ollama models.

**How to Verify:**
Model names match specification (gemma3:27b, qwen3-coder:30b).

---

### Step 10: Verify Password Variable Present
**Action:**
```bash
grep "^POSTGRES_PASSWORD=" /opt/hx-lang-server/.env | wc -l
```

**Expected Behavior:**
Password variable is defined.

**How to Verify:**
Count is 1 (password is set, but we don't expose its value).

---

## Expected Results

### Primary Expected Results
- [ ] .env file exists with correct permissions (640)
- [ ] Owned by hx-lang-server:hx-lang-server
- [ ] All required variables present (>=15)
- [ ] All URL formats valid
- [ ] All port numbers valid
- [ ] All hostnames follow naming convention
- [ ] LOG_LEVEL is valid
- [ ] Numeric parameters are integers
- [ ] Model names are correct
- [ ] Password variable present (not exposed)

### Observable Indicators
**Files:**
- File exists at /opt/hx-lang-server/.env
- Permissions are restrictive

**Security:**
- No world-readable permissions
- Password not exposed in test output

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. File exists with correct permissions
2. Correct ownership
3. All required variables present
4. All variable formats valid
5. No exposed secrets

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. File missing
2. Wrong permissions (world-readable)
3. Wrong ownership
4. Required variables missing
5. Invalid variable formats

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Directory structure missing
2. Cannot access file

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

### Security Notes
- Never expose password values in test output
- Verify Ansible Vault integration for secrets

### Dependencies on Other Tests
- Related to deployment-007 (Configuration Files)
- Required for deployment-004 (Service Startup)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Environment Variables section

**Related Test Cases:**
- `tc-lang-server-deployment-007-configuration-files.md` - Related test
- `tc-lang-server-deployment-009-systemd-service.md` - Uses EnvironmentFile

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
