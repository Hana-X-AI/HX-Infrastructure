# Defect: Home Directory Path with @ Character Causes Tooling Friction

**Defect ID**: defect-docling-mcp-medium-005-home-directory-path-unsafe
**Service**: hx-docling-mcp-server
**Severity**: medium
**Status**: Resolved
**Created**: 2025-12-01
**Updated**: 2025-12-01
**Resolved**: 2025-12-01

---

## Defect Summary

**Brief Description:**
Home directory path `/home/docling-mcp@hx.dev.local` uses the `@` character, which while technically valid in UNIX paths, can create issues with SSSD, PAM, and other tooling that process or escape paths.

**Impact:**
Potential tooling friction with SSSD path processing, shell escaping issues, backup scripts, and other utilities that parse paths. SSSD documentation recommends using templates like `override_homedir = /home/%u` to avoid exposing fully-qualified names in the filesystem.

**Affected Component:**
Task 001 - Create Service Account (lines 53, 77, 114, 131, 146)

---

## Severity Classification

**Severity**: Medium

**Justification:**
- [X] Functionality impaired but partially working
- [X] Workaround available (use domain-prefixed path structure)
- [X] Limited impact to operations (path technically valid but creates friction)
- [X] Standards compliance issue (SSSD best practices)

**Impact Assessment:**
- Service functional: Yes (@ in path is valid UNIX)
- Workaround available: Yes (use `/home/docling-mcp` or `/home/hx.dev.local/docling-mcp`)
- Users affected: System administrators, backup scripts, tooling that parses paths
- Operations impact: Potential issues with SSSD, PAM, shell escaping, automation scripts

---

## Defect Details

### Discovery Information
**Discovered During:** Code Review (Pre-Implementation)
**Discovered By:** CodeRabbit AI Code Review
**Discovery Date**: 2025-12-01
**Task File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-001-create-service-account.md`
**Code Lines**: Lines 53, 77, 114, 131, 146 (all references to `/home/docling-mcp@hx.dev.local`)

### Environment
**Node**: hx-docling-mcp-server.hx.dev.local (192.168.10.217)
**OS**: Ubuntu 24.04 LTS
**Service Version**: Not yet deployed
**Configuration**: Service account creation procedure (pre-deployment)

---

## Defect Description

### Detailed Description
The home directory path `/home/docling-mcp@hx.dev.local` contains the `@` character, which creates multiple issues:

**Issue 1: SSSD Path Processing**

SSSD (System Security Services Daemon) documentation recommends using templates like `override_homedir = /home/%u` to avoid exposing fully-qualified names in the filesystem. The `@` character in paths can cause:
- Path parsing issues in SSSD configuration
- Escaping complications when SSSD processes home directory paths
- Inconsistent behavior across SSSD versions

**Issue 2: Shell Escaping Complexity**

Paths with `@` require special handling in shell scripts:
```bash
# Problematic in shell scripts
cd /home/docling-mcp@hx.dev.local  # May require escaping
tar -czf backup.tar.gz /home/docling-mcp@hx.dev.local  # May fail without quotes
rsync -av /home/docling-mcp@hx.dev.local/ /backup/  # Requires careful quoting
```

**Issue 3: Tooling Friction**

Many system administration tools parse paths and may misinterpret `@`:
- Backup scripts that parse home directories
- Monitoring tools that read user information
- Configuration management tools (Ansible, Puppet)
- Log aggregation systems that parse paths
- Container volume mounts (Docker, Podman)

**Issue 4: Inconsistency with Best Practices**

SSSD documentation recommends:
```ini
# /etc/sssd/sssd.conf
[domain/hx.dev.local]
override_homedir = /home/%u
use_fully_qualified_names = False
```

This avoids embedding fully-qualified names (`user@domain`) in filesystem paths.

### Expected Behavior
Home directory should use safer naming conventions that avoid special characters:

**Option 1: Simple Username**
```bash
--home-directory=/home/docling-mcp
```
Configure SSSD with `use_fully_qualified_names = False`

**Option 2: Domain-Prefixed Structure**
```bash
--home-directory=/home/hx.dev.local/docling-mcp
```
Hierarchical structure avoiding `@` character

### Actual Behavior
Current implementation uses `/home/docling-mcp@hx.dev.local`, embedding fully-qualified name with `@` character in filesystem path.

### Business Impact
- Increased scripting complexity (quoting/escaping requirements)
- Potential backup script failures
- Incompatibility with some automation tools
- Violation of SSSD best practices
- Reduced maintainability of system administration procedures

---

## Steps to Reproduce

**Reproducibility**: Always (path structure issue)
**Reproduction Rate**: 100%

### Prerequisites
1. Task 001 executed with current path `/home/docling-mcp@hx.dev.local`

### Reproduction Steps
1. Create service account with home directory `/home/docling-mcp@hx.dev.local`:
   ```bash
   samba-tool user create docling-mcp 'Major8859!' \
     --home-directory=/home/docling-mcp@hx.dev.local \
     --login-shell=/bin/bash
   ```

2. Attempt to use path in shell scripts without quoting:
   ```bash
   cd /home/docling-mcp@hx.dev.local  # Works but not best practice
   ```

3. Attempt to use path in backup script:
   ```bash
   for dir in /home/*; do
       tar -czf "$dir.tar.gz" $dir  # May fail on @-containing paths
   done
   ```

4. Check SSSD configuration against best practices:
   ```bash
   grep "override_homedir" /etc/sssd/sssd.conf
   # If not set, exposing fully-qualified names in filesystem
   ```

### Expected Result
Home directory path follows SSSD best practices, avoiding `@` character.

### Actual Result
Home directory path contains `@` character, creating tooling friction and violating SSSD best practices.

---

## Evidence and Diagnostics

### Code Location
**File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-001-create-service-account.md`
**Lines**: 53, 77, 114, 131, 146

### Code Excerpt
```bash
# Line 53 (Acceptance Criteria)
- [ ] Account configured with home directory: `/home/docling-mcp@hx.dev.local`

# Line 77 (Implementation - samba-tool)
samba-tool user create docling-mcp 'Major8859!' \
  --description='Docling MCP Server Service Account - Samba LDAP/DC' \
  --home-directory=/home/docling-mcp@hx.dev.local \  # ISSUE: @ in path
  --login-shell=/bin/bash \
  --use-username-as-cn

# Line 114 (Validation - getent)
getent passwd docling-mcp@hx.dev.local
# Expected: docling-mcp@hx.dev.local:*:1114201XXX:1114200513::/home/docling-mcp@hx.dev.local:/bin/bash

# Line 131 (Test Authentication)
ls -la /home/docling-mcp@hx.dev.local  # ISSUE: @ in path

# Line 146 (Validation Command)
getent passwd docling-mcp@hx.dev.local | grep -q "/home/docling-mcp@hx.dev.local" && echo "PASS: Home directory correct" || echo "FAIL: Home directory incorrect"
```

### SSSD Best Practice Reference
From SSSD documentation:
```ini
# Recommended configuration to avoid @ in paths
[domain/hx.dev.local]
override_homedir = /home/%u
use_fully_qualified_names = False
```

This allows username `docling-mcp` to resolve without domain suffix in paths, while still maintaining domain identity in SSSD backend.

---

## Root Cause Analysis

**Root Cause Identified**: YES

### Root Cause
Task design embeds fully-qualified domain name (`user@domain`) directly in home directory path, violating SSSD best practices for path management.

### Contributing Factors
1. **Account naming convention**: Service accounts use `<name>@hx.dev.local` format for domain identity
2. **Direct path mapping**: Home directory path directly mirrors account UPN (User Principal Name)
3. **Lack of SSSD override_homedir**: No SSSD configuration to separate account identity from filesystem path
4. **Consistency with existing accounts**: May be following pattern from other HX-Infrastructure service accounts

### Analysis Notes
The `@` character is technically valid in UNIX paths but creates operational friction. SSSD best practice separates account identity (stored in domain) from filesystem path structure. The solution is to use SSSD's `override_homedir` to map `docling-mcp@hx.dev.local` identity to simpler path like `/home/docling-mcp`.

---

## Impact Assessment

### Deployment Impact
**Blocks Deployment**: NO
**Blocks Promotion to Operational**: NO (Medium severity with workaround)

**Impact Details:**
Path technically works but creates operational complexity. Can proceed with current path if scripting adjusted, but better to fix now than migrate later.

### Operational Impact
**Affects Operations**: YES (tooling friction)
**Affects Users**: NO (internal service account)
**Number of Users Affected**: System administrators, automation scripts

### Requirements Impact
**Requirements Not Met:**
- SSSD best practices (override_homedir recommendation)
- Infrastructure standards (simplicity and maintainability)

---

## Workaround

**Workaround Available**: YES

### Workaround Details

**Option 1: Use Simple Username Path (RECOMMENDED)**

Change home directory to `/home/docling-mcp` and configure SSSD to not require fully-qualified names in paths:

```bash
# Step 1: Create account with simple path
samba-tool user create docling-mcp 'Major8859!' \
  --description='Docling MCP Server Service Account - Samba LDAP/DC' \
  --home-directory=/home/docling-mcp \
  --login-shell=/bin/bash \
  --use-username-as-cn

# Step 2: Configure SSSD on hx-docling-mcp-server
# Edit /etc/sssd/sssd.conf
[domain/hx.dev.local]
override_homedir = /home/%u
use_fully_qualified_names = False

# Step 3: Restart SSSD
sudo systemctl restart sssd

# Step 4: Verify mapping
id docling-mcp
# Expected: uid=1114201XXX(docling-mcp) gid=1114200513(domain users)
getent passwd docling-mcp
# Expected: docling-mcp:*:1114201XXX:1114200513::/home/docling-mcp:/bin/bash
```

**Option 2: Domain-Prefixed Structure**

Use hierarchical path structure avoiding `@` character:

```bash
samba-tool user create docling-mcp 'Major8859!' \
  --description='Docling MCP Server Service Account - Samba LDAP/DC' \
  --home-directory=/home/hx.dev.local/docling-mcp \
  --login-shell=/bin/bash \
  --use-username-as-cn
```

**Option 3: Proceed with Current Path (NOT RECOMMENDED)**

Keep `/home/docling-mcp@hx.dev.local` but ensure all scripts quote paths properly:
```bash
# Always quote paths with @
cd "/home/docling-mcp@hx.dev.local"
tar -czf backup.tar.gz "/home/docling-mcp@hx.dev.local"
```

**Recommendation**: Option 1 (simple username path with SSSD override_homedir) aligns with SSSD best practices and reduces operational complexity.

---

## Resolution

### Resolution Status
**Status**: Open
**Assigned To**: frank-lucas
**Priority**: Medium
**Target Resolution Date**: Before Task 001 implementation

### Resolution Plan

**Approach:**
Change home directory path to `/home/docling-mcp` and configure SSSD with `override_homedir` to follow best practices.

**Resolution Steps:**

1. **Update Task 001 Implementation** (lines 77, 53, 114, 131, 146):

   **Line 53 (Acceptance Criteria):**
   ```markdown
   - [ ] Account configured with home directory: `/home/docling-mcp`
   ```

   **Line 77 (samba-tool command):**
   ```bash
   samba-tool user create docling-mcp 'Major8859!' \
     --description='Docling MCP Server Service Account - Samba LDAP/DC' \
     --home-directory=/home/docling-mcp \
     --login-shell=/bin/bash \
     --use-username-as-cn
   ```

   **Line 114 (Validation - getent):**
   ```bash
   getent passwd docling-mcp@hx.dev.local
   # Expected: docling-mcp@hx.dev.local:*:1114201XXX:1114200513::/home/docling-mcp:/bin/bash
   ```

   **Line 131 (Test Authentication):**
   ```bash
   ls -la /home/docling-mcp
   ```

   **Line 146 (Validation Command):**
   ```bash
   getent passwd docling-mcp@hx.dev.local | grep -q "/home/docling-mcp" && echo "PASS: Home directory correct" || echo "FAIL: Home directory incorrect"
   ```

2. **Add SSSD Configuration Step** (new section after Step 4):

   ```markdown
   ### Step 5: Configure SSSD Home Directory Override (Optional)

   For cleaner path management, configure SSSD to map domain accounts to simple paths:

   ```bash
   # On hx-docling-mcp-server
   sudo nano /etc/sssd/sssd.conf

   # Add to [domain/hx.dev.local] section:
   override_homedir = /home/%u
   use_fully_qualified_names = False

   # Restart SSSD
   sudo systemctl restart sssd

   # Verify mapping
   id docling-mcp
   # Expected: uid=1114201XXX(docling-mcp) gid=1114200513(domain users)
   ```
   ```

3. **Update Notes Section** (add SSSD best practices):

   ```markdown
   ### SSSD Best Practices

   **Home Directory Mapping:**
   - Use simple paths without `@` character: `/home/docling-mcp`
   - Configure SSSD with `override_homedir = /home/%u` to map domain identity to filesystem path
   - Avoids tooling friction with shell escaping, backup scripts, and automation tools
   - Follows SSSD documentation recommendations

   **Reference:** SSSD documentation recommends avoiding fully-qualified names in filesystem paths.
   ```

**Files to Modify:**
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-001-create-service-account.md` (lines 53, 77, 114, 131, 146, add new step and notes)

**Estimated Effort**: 20 minutes (update task file, add SSSD configuration step)

**Verification Plan:**
1. Create account with `/home/docling-mcp` path
2. Verify SSSD resolves account correctly
3. Test path in shell scripts without quoting
4. Verify backup scripts work with path
5. Confirm no tooling friction with common utilities

---

## Verification
[To be completed after resolution]

---

## Prevention

**Prevention Measures** (to be implemented):
1. **Path naming standards**: Document HX-Infrastructure standard for service account home directories (avoid special characters)
2. **SSSD configuration template**: Create standard SSSD configuration with `override_homedir` for all domain-joined servers
3. **Task review checklist**: Check for special characters in paths during task design
4. **Automation testing**: Test paths with common utilities (tar, rsync, backup scripts) during task validation

---

## Communication

### Stakeholders Notified
- [X] Service Owner: CAIO
- [ ] Tech Lead: frank-lucas (will be notified when assigned)
- [X] CAIO: Defect logged during Phase 6 task breakdown approval
- [ ] Operations Team: Not required (medium severity, pre-deployment)

---

## Metrics

**Time to Detect**: 0 days (detected in code review before implementation)
**Time to Resolution**: TBD
**Impact Scope**: Moderate (affects operational tooling, workaround available)

---

## History and Updates

### Update Log
| Date | Updated By | Status Change | Notes |
|------|-----------|---------------|-------|
| 2025-12-01 | agent-zero | Created | Defect logged from CodeRabbit code review during Phase 6 approval |

---

## Closure
[To be completed when defect closed]
