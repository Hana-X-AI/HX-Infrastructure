# Task 004: Configure Directory Ownership

**Assigned To**: frank-lucas
**Estimated Effort**: 0.25 hours
**Dependencies**: Task 001 (service account), Task 003 (directories created)
**Status**: Not Started

## Objective

Set correct ownership on all Docling MCP Server directories to enforce security principle of least privilege and enable service account to read/write only necessary directories.

## Context

Directory ownership controls which user account can read, write, and execute files within each directory. HX-Infrastructure follows principle of least privilege:

- **Application code** (`/opt/docling-mcp/`): `docling-mcp:docling-mcp` - Service account owns code (can read/execute, cannot write in production)
- **Data directory** (`/var/lib/docling-mcp/`): `docling-mcp:docling-mcp` - Service account owns data (can read/write cache)
- **Log directory** (`/var/log/docling-mcp/`): `docling-mcp:docling-mcp` - Service account owns logs (can write logs)
- **Configuration** (`/etc/docling-mcp/`): `root:docling-mcp` - Root owns, service account can read only (protects secrets)

This ownership model:
- Prevents service account from modifying own code (defense against compromise)
- Enables service account to manage cache and logs
- Protects configuration secrets (only root can modify)
- Aligns with security best practices for service accounts

## Pre-Execution Validation

**CRITICAL**: Check if directories already have correct ownership BEFORE changing them.

```bash
# Check ownership of primary directories
opt_owner=$(stat -c '%U:%G' /opt/docling-mcp 2>/dev/null)
var_owner=$(stat -c '%U:%G' /var/lib/docling-mcp 2>/dev/null)
log_owner=$(stat -c '%U:%G' /var/log/docling-mcp 2>/dev/null)
etc_owner=$(stat -c '%U:%G' /etc/docling-mcp 2>/dev/null)

if [ "$opt_owner" = "docling-mcp:docling-mcp" ] && \
   [ "$var_owner" = "docling-mcp:docling-mcp" ] && \
   [ "$log_owner" = "docling-mcp:docling-mcp" ] && \
   [ "$etc_owner" = "root:docling-mcp" ]; then
    echo "✅ VALIDATION RESULT: Directory ownership already correct"
    echo "  /opt/docling-mcp: $opt_owner"
    echo "  /var/lib/docling-mcp: $var_owner"
    echo "  /var/log/docling-mcp: $log_owner"
    echo "  /etc/docling-mcp: $etc_owner"
    echo "ACTION: SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION RESULT: Directory ownership needs correction"
    echo "ACTION: PROCEED with ownership configuration"
fi
```

**If Ownership Correct**: Skip to Validation section

**If Ownership Incorrect**: Continue with Implementation Steps below

---

## Acceptance Criteria

- [ ] `/opt/docling-mcp/` owned by `docling-mcp:docling-mcp` (recursive)
- [ ] `/var/lib/docling-mcp/` owned by `docling-mcp:docling-mcp` (recursive)
- [ ] `/var/log/docling-mcp/` owned by `docling-mcp:docling-mcp` (recursive)
- [ ] `/etc/docling-mcp/` owned by `root:docling-mcp` (recursive)
- [ ] Ownership verified via `ls -l` commands
- [ ] Service account can read all directories
- [ ] Service account cannot write to `/etc/docling-mcp/` (read-only)

## Implementation Steps

### Step 1: Verify Service Account Exists

```bash
# SSH to hx-docling-mcp-server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Verify docling-mcp service account exists (from Task 001)
id docling-mcp@hx.dev.local
# Expected output: uid=1114201XXX(docling-mcp@hx.dev.local) gid=1114200513(domain users@hx.dev.local)

# If account not found, Task 001 must be completed first
```

### Step 2: Set Ownership on Application Directory

```bash
# Set ownership on /opt/docling-mcp/ (service account owns application code)
sudo chown -R docling-mcp@hx.dev.local:docling-mcp@hx.dev.local /opt/docling-mcp

# Verify ownership
ls -ld /opt/docling-mcp
# Expected: drwxr-xr-x X docling-mcp@hx.dev.local docling-mcp@hx.dev.local

# Verify subdirectories also owned correctly
ls -l /opt/docling-mcp/
# All entries should show: docling-mcp@hx.dev.local docling-mcp@hx.dev.local
```

### Step 3: Set Ownership on Data Directory

```bash
# Set ownership on /var/lib/docling-mcp/ (service account owns cache/data)
sudo chown -R docling-mcp@hx.dev.local:docling-mcp@hx.dev.local /var/lib/docling-mcp

# Verify ownership
ls -ld /var/lib/docling-mcp
# Expected: drwxr-xr-x X docling-mcp@hx.dev.local docling-mcp@hx.dev.local

# Verify subdirectories (cache, tmp, sessions)
ls -l /var/lib/docling-mcp/
# All entries should show: docling-mcp@hx.dev.local docling-mcp@hx.dev.local
```

### Step 4: Set Ownership on Log Directory

```bash
# Set ownership on /var/log/docling-mcp/ (service account owns logs)
sudo chown -R docling-mcp@hx.dev.local:docling-mcp@hx.dev.local /var/log/docling-mcp

# Verify ownership
ls -ld /var/log/docling-mcp
# Expected: drwxr-xr-x X docling-mcp@hx.dev.local docling-mcp@hx.dev.local

# Verify subdirectories (application, access, error)
ls -l /var/log/docling-mcp/
# All entries should show: docling-mcp@hx.dev.local docling-mcp@hx.dev.local
```

### Step 5: Set Ownership on Configuration Directory (Root-Owned, Group-Readable)

```bash
# Set ownership on /etc/docling-mcp/ (root owns, docling-mcp group can read)
sudo chown -R root:docling-mcp@hx.dev.local /etc/docling-mcp

# Verify ownership
ls -ld /etc/docling-mcp
# Expected: drwxr-xr-x X root docling-mcp@hx.dev.local

# Verify subdirectories (env, vault, ssl)
ls -l /etc/docling-mcp/
# All entries should show: root docling-mcp@hx.dev.local
```

### Step 6: Verify Complete Ownership Configuration

```bash
# Comprehensive ownership check
echo "=== /opt/docling-mcp/ ownership ==="
ls -ld /opt/docling-mcp
ls -l /opt/docling-mcp/

echo "=== /var/lib/docling-mcp/ ownership ==="
ls -ld /var/lib/docling-mcp
ls -l /var/lib/docling-mcp/

echo "=== /var/log/docling-mcp/ ownership ==="
ls -ld /var/log/docling-mcp
ls -l /var/log/docling-mcp/

echo "=== /etc/docling-mcp/ ownership ==="
ls -ld /etc/docling-mcp
ls -l /etc/docling-mcp/

# All directories should show correct ownership as specified above
```

## Validation

**Validation Commands:**

```bash
# 1. Verify /opt/docling-mcp/ owned by docling-mcp
stat -c '%U:%G' /opt/docling-mcp | grep -q "docling-mcp@hx.dev.local:docling-mcp@hx.dev.local" && echo "PASS: /opt ownership correct" || echo "FAIL: /opt ownership incorrect"

# 2. Verify /var/lib/docling-mcp/ owned by docling-mcp
stat -c '%U:%G' /var/lib/docling-mcp | grep -q "docling-mcp@hx.dev.local:docling-mcp@hx.dev.local" && echo "PASS: /var/lib ownership correct" || echo "FAIL: /var/lib ownership incorrect"

# 3. Verify /var/log/docling-mcp/ owned by docling-mcp
stat -c '%U:%G' /var/log/docling-mcp | grep -q "docling-mcp@hx.dev.local:docling-mcp@hx.dev.local" && echo "PASS: /var/log ownership correct" || echo "FAIL: /var/log ownership incorrect"

# 4. Verify /etc/docling-mcp/ owned by root:docling-mcp
stat -c '%U:%G' /etc/docling-mcp | grep -q "root:docling-mcp@hx.dev.local" && echo "PASS: /etc ownership correct" || echo "FAIL: /etc ownership incorrect"

# 5. Test service account can read all directories
sudo -u docling-mcp@hx.dev.local ls /opt/docling-mcp > /dev/null 2>&1 && echo "PASS: Service can read /opt" || echo "FAIL: Service cannot read /opt"
sudo -u docling-mcp@hx.dev.local ls /var/lib/docling-mcp > /dev/null 2>&1 && echo "PASS: Service can read /var/lib" || echo "FAIL: Service cannot read /var/lib"
sudo -u docling-mcp@hx.dev.local ls /var/log/docling-mcp > /dev/null 2>&1 && echo "PASS: Service can read /var/log" || echo "FAIL: Service cannot read /var/log"
sudo -u docling-mcp@hx.dev.local ls /etc/docling-mcp > /dev/null 2>&1 && echo "PASS: Service can read /etc" || echo "FAIL: Service cannot read /etc"

# 6. Test service account can write to cache directory
sudo -u docling-mcp@hx.dev.local touch /var/lib/docling-mcp/cache/test.tmp && \
  sudo -u docling-mcp@hx.dev.local rm /var/lib/docling-mcp/cache/test.tmp && \
  echo "PASS: Service can write to cache" || echo "FAIL: Service cannot write to cache"

# 7. Test service account CANNOT write to /etc/docling-mcp (should fail - this is expected)
sudo -u docling-mcp@hx.dev.local touch /etc/docling-mcp/test.tmp > /dev/null 2>&1 && echo "FAIL: Service can write to /etc (security violation!)" || echo "PASS: Service cannot write to /etc (correct)"
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Service account can read all four primary directories
- Service account can write to `/var/lib/docling-mcp/` and `/var/log/docling-mcp/`
- Service account CANNOT write to `/etc/docling-mcp/` (security enforcement)

## Notes

### Ownership Security Model

**Application Code (`/opt/docling-mcp/`)**: `docling-mcp:docling-mcp`
- **Owner**: Service account (docling-mcp)
- **Group**: Service account group
- **Rationale**: Service needs to read/execute code, but should not modify in production
- **Write Access**: Permitted initially for deployment, can be made read-only via permissions (Task 005)

**Data Directory (`/var/lib/docling-mcp/`)**: `docling-mcp:docling-mcp`
- **Owner**: Service account (docling-mcp)
- **Group**: Service account group
- **Rationale**: Service must write cache files, temporary processing data
- **Write Access**: Required for normal operation

**Log Directory (`/var/log/docling-mcp/`)**: `docling-mcp:docling-mcp`
- **Owner**: Service account (docling-mcp)
- **Group**: Service account group
- **Rationale**: Service must write application logs
- **Write Access**: Required for logging

**Configuration (`/etc/docling-mcp/`)**: `root:docling-mcp`
- **Owner**: root (administrator only)
- **Group**: Service account group (docling-mcp can read via group membership)
- **Rationale**: Protects secrets and configuration from modification by compromised service
- **Write Access**: Only root can modify, service can read only

### Domain Account Ownership Syntax

**Full UPN Required**: `docling-mcp@hx.dev.local`
- Domain accounts use full User Principal Name (UPN)
- Format: `username@domain.suffix`
- NOT just `docling-mcp` (that would reference local account)

**Verification**: Use `id` command to see full username:
```bash
id docling-mcp@hx.dev.local
# Shows: uid=1114201XXX(docling-mcp@hx.dev.local)
```

### Why Root Owns Configuration

**Security Principle**: Defense in Depth
1. **If service compromised**: Attacker cannot modify configuration to escalate privileges
2. **If credentials leaked**: Attacker cannot replace credentials with their own
3. **If code execution**: Attacker cannot inject malicious environment variables

**Configuration Management**:
- Only root (or sudo) can deploy new configuration files
- Service account can only read configuration
- Ansible playbooks run as root (can deploy configs)
- Manual config changes require sudo (intentional friction for security)

### Recursive Ownership (-R Flag)

**Behavior**: `chown -R` applies ownership to directory and ALL contents recursively
- Affects all files and subdirectories
- Existing files inherit new ownership
- Future files created by service will have service account ownership

**Verification**:
```bash
# Check recursively applied ownership
find /opt/docling-mcp -exec stat -c '%U:%G %n' {} \; | head -20
# All entries should show: docling-mcp@hx.dev.local:docling-mcp@hx.dev.local
```

### Group Membership Implications

**Service Account Group**: `docling-mcp@hx.dev.local` (implicitly, same as username)
- Primary group for service account
- All files created by service will have this group ownership
- Group membership enables read access to `/etc/docling-mcp/`

**Domain Users Group**: `domain users@hx.dev.local` (GID 1114200513)
- Service account is also member of domain users group
- Not used for file ownership in this deployment
- Enables potential future group-based access control

### Future Configuration Files

**When deploying configuration files** (Task 008 - Configure Environment Files):
- Deploy to `/etc/docling-mcp/env/.env` as root
- Set ownership: `root:docling-mcp@hx.dev.local`
- Set permissions: `640` (owner read-write, group read-only, no world access)
- Service can read via group membership

**Ansible Vault Credentials** (Phase 2):
- Deploy to `/etc/docling-mcp/vault/credentials.yml`
- Ownership: `root:docling-mcp@hx.dev.local`
- Permissions: `640` (group-readable by service account)

### Troubleshooting

**If chown fails with "invalid user" error**:
```bash
# Verify service account exists
id docling-mcp@hx.dev.local
# If fails, Task 001 not completed - create service account first

# Check SSSD is running (for domain account resolution)
sudo systemctl status sssd
# Should be active (running)
```

**If ownership shows UID numbers instead of usernames**:
```bash
# Example: drwxr-xr-x X 1114201140 1114200513 instead of docling-mcp@hx.dev.local
# This indicates SSSD name resolution issue

# Restart SSSD to fix
sudo systemctl restart sssd
sleep 5

# Verify name resolution works
getent passwd docling-mcp@hx.dev.local
# Should return full account info

# Re-run ls to see usernames
ls -ld /opt/docling-mcp
# Should now show: docling-mcp@hx.dev.local docling-mcp@hx.dev.local
```

**If service account cannot read /etc/docling-mcp**:
```bash
# Verify group ownership
ls -ld /etc/docling-mcp
# Should show: root docling-mcp@hx.dev.local

# Verify service account is member of docling-mcp group
id docling-mcp@hx.dev.local | grep docling-mcp
# Should show docling-mcp in groups

# Verify permissions allow group read (Task 005)
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 3.3.3: File Ownership)
- **Security Standards**: `/home/agent0/HX-Infrastructure/standards/security-requirements.md`
- **Deployment Requirements**: `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`

## Risk Assessment

**Risk**: Low
- Ownership changes do not affect operational services
- Changes are reversible
- Service not yet running (no service disruption)

**Mitigation**:
- Verify service account exists before changing ownership
- Use recursive flag to ensure complete ownership application
- Test service account read/write access before deployment
- Keep root ownership on configuration for security

**Rollback Procedure**:
```bash
# If ownership needs to be reset to root (emergency only)
sudo chown -R root:root /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp
# WARNING: Only use if ownership changes cause issues
```
