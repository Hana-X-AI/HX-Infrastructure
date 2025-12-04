# Task 005: Set Directory Permissions

**Assigned To**: frank-lucas
**Estimated Effort**: 0.5 hours
**Dependencies**: Task 004 (ownership configured)
**Status**: Not Started

## Objective

Configure filesystem permissions on all Docling MCP Server directories following security principle of least privilege to restrict access based on operational requirements.

## Context

Filesystem permissions control read, write, and execute access for owner, group, and others. HX-Infrastructure enforces strict permissions to minimize attack surface:

- **Application code**: 755 (dirs), 644 (files) - read-execute for service, read for others (no write in production)
- **Configuration**: 640 (files) - read-only for owner/group, no access for others (protect secrets)
- **Cache directory**: 770 - read-write-execute for owner/group, no access for others (prevent data leakage)
- **Log directory**: 750 - read-write-execute for owner, read-execute for group, no access for others

Permission model enforces:
- Service cannot modify own code in production (defense against code injection)
- Configuration secrets not readable by other users (credential protection)
- Cache and logs isolated from other services (data confidentiality)
- Administrator can read logs for debugging (operational access)

## Pre-Execution Validation

**CRITICAL**: Check if directories already have correct permissions BEFORE changing them.

```bash
# Check permissions of primary directories
opt_perms=$(stat -c '%a' /opt/docling-mcp 2>/dev/null)
var_perms=$(stat -c '%a' /var/lib/docling-mcp 2>/dev/null)
log_perms=$(stat -c '%a' /var/log/docling-mcp 2>/dev/null)
etc_perms=$(stat -c '%a' /etc/docling-mcp 2>/dev/null)

if [ "$opt_perms" = "755" ] && \
   [ "$var_perms" = "770" ] && \
   [ "$log_perms" = "750" ] && \
   [ "$etc_perms" = "750" ]; then
    echo "✅ VALIDATION RESULT: Directory permissions already correct"
    echo "  /opt/docling-mcp: $opt_perms"
    echo "  /var/lib/docling-mcp: $var_perms"
    echo "  /var/log/docling-mcp: $log_perms"
    echo "  /etc/docling-mcp: $etc_perms"
    echo "ACTION: SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION RESULT: Directory permissions need correction"
    echo "ACTION: PROCEED with permission configuration"
fi
```

**If Permissions Correct**: Skip to Validation section

**If Permissions Incorrect**: Continue with Implementation Steps below

---

## Acceptance Criteria

- [ ] `/opt/docling-mcp/` directories set to 755, files to 644
- [ ] `/var/lib/docling-mcp/` directories set to 770 (owner + group only)
- [ ] `/var/log/docling-mcp/` directories set to 750 (owner + group read)
- [ ] `/etc/docling-mcp/` directories set to 750, files to 640 (when created)
- [ ] Permissions verified via `ls -l` and `stat` commands
- [ ] Service account can read application code
- [ ] Service account can write to cache and logs
- [ ] Service account can read configuration
- [ ] Other users cannot access cache, logs, or configuration

## Implementation Steps

### Step 1: SSH to Target Server

```bash
# Connect to hx-docling-mcp-server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!
```

### Step 2: Set Permissions on Application Directory

```bash
# Set directory permissions to 755 (rwxr-xr-x)
# Owner: read-write-execute, Group: read-execute, Others: read-execute
sudo find /opt/docling-mcp -type d -exec chmod 755 {} \;

# Verify directory permissions
ls -ld /opt/docling-mcp
# Expected: drwxr-xr-x (755)

# Verify subdirectory permissions
ls -l /opt/docling-mcp/
# All directories should show: drwxr-xr-x (755)

# Set file permissions to 644 (rw-r--r--) when files exist
# Owner: read-write, Group: read, Others: read
# NOTE: Files will be created in later tasks (Task 007, Task 008)
# This command will be re-run after file creation
sudo find /opt/docling-mcp -type f -exec chmod 644 {} \;
```

### Step 3: Set Permissions on Data Directory (Restricted Access)

```bash
# Set directory permissions to 770 (rwxrwx---)
# Owner: read-write-execute, Group: read-write-execute, Others: no access
sudo chmod -R 770 /var/lib/docling-mcp

# Verify directory permissions
ls -ld /var/lib/docling-mcp
# Expected: drwxrwx--- (770)

# Verify subdirectory permissions (cache, tmp, sessions)
ls -l /var/lib/docling-mcp/
# All directories should show: drwxrwx--- (770)
```

### Step 4: Set Permissions on Log Directory (Owner + Group Read)

```bash
# Set directory permissions to 750 (rwxr-x---)
# Owner: read-write-execute, Group: read-execute, Others: no access
sudo chmod -R 750 /var/log/docling-mcp

# Verify directory permissions
ls -ld /var/log/docling-mcp
# Expected: drwxr-x--- (750)

# Verify subdirectory permissions (application, access, error)
ls -l /var/log/docling-mcp/
# All directories should show: drwxr-x--- (750)
```

### Step 5: Set Permissions on Configuration Directory (Sensitive Data)

```bash
# Set directory permissions to 750 (rwxr-x---)
# Owner (root): read-write-execute, Group (docling-mcp): read-execute, Others: no access
sudo chmod -R 750 /etc/docling-mcp

# Verify directory permissions
ls -ld /etc/docling-mcp
# Expected: drwxr-x--- (750)

# Verify subdirectory permissions (env, vault, ssl)
ls -l /etc/docling-mcp/
# All directories should show: drwxr-x--- (750)

# NOTE: Configuration files (.env, credentials.yml) will be created in later tasks
# When created, they should be set to 640 (rw-r-----)
# Owner (root): read-write, Group (docling-mcp): read, Others: no access
```

### Step 6: Verify Complete Permission Configuration

```bash
# Comprehensive permission check
echo "=== /opt/docling-mcp/ permissions ==="
stat -c '%a %n' /opt/docling-mcp
ls -l /opt/docling-mcp/

echo "=== /var/lib/docling-mcp/ permissions ==="
stat -c '%a %n' /var/lib/docling-mcp
ls -l /var/lib/docling-mcp/

echo "=== /var/log/docling-mcp/ permissions ==="
stat -c '%a %n' /var/log/docling-mcp
ls -l /var/log/docling-mcp/

echo "=== /etc/docling-mcp/ permissions ==="
stat -c '%a %n' /etc/docling-mcp
ls -l /etc/docling-mcp/
```

## Validation

**Validation Commands:**

```bash
# 1. Verify /opt/docling-mcp/ has 755 permissions
stat -c '%a' /opt/docling-mcp | grep -q "755" && echo "PASS: /opt permissions correct (755)" || echo "FAIL: /opt permissions incorrect"

# 2. Verify /var/lib/docling-mcp/ has 770 permissions
stat -c '%a' /var/lib/docling-mcp | grep -q "770" && echo "PASS: /var/lib permissions correct (770)" || echo "FAIL: /var/lib permissions incorrect"

# 3. Verify /var/log/docling-mcp/ has 750 permissions
stat -c '%a' /var/log/docling-mcp | grep -q "750" && echo "PASS: /var/log permissions correct (750)" || echo "FAIL: /var/log permissions incorrect"

# 4. Verify /etc/docling-mcp/ has 750 permissions
stat -c '%a' /etc/docling-mcp | grep -q "750" && echo "PASS: /etc permissions correct (750)" || echo "FAIL: /etc permissions incorrect"

# 5. Test service account can read application directory
sudo -u docling-mcp@hx.dev.local ls /opt/docling-mcp > /dev/null 2>&1 && echo "PASS: Service can read /opt" || echo "FAIL: Service cannot read /opt"

# 6. Test service account can write to cache directory
sudo -u docling-mcp@hx.dev.local touch /var/lib/docling-mcp/cache/permission-test.tmp && \
  sudo -u docling-mcp@hx.dev.local rm /var/lib/docling-mcp/cache/permission-test.tmp && \
  echo "PASS: Service can write to cache" || echo "FAIL: Service cannot write to cache"

# 7. Test service account can write to log directory
sudo -u docling-mcp@hx.dev.local touch /var/log/docling-mcp/permission-test.log && \
  sudo -u docling-mcp@hx.dev.local rm /var/log/docling-mcp/permission-test.log && \
  echo "PASS: Service can write to logs" || echo "FAIL: Service cannot write to logs"

# 8. Test service account can read configuration directory
sudo -u docling-mcp@hx.dev.local ls /etc/docling-mcp > /dev/null 2>&1 && echo "PASS: Service can read /etc" || echo "FAIL: Service cannot read /etc"

# 9. Test other users CANNOT access cache directory (security validation)
if sudo -u agent0 ls /var/lib/docling-mcp/cache > /dev/null 2>&1; then
    echo "FAIL: Other users can access cache (security violation!)"
else
    echo "PASS: Cache protected from other users"
fi

# 10. Test other users CANNOT access log directory (security validation)
if sudo -u agent0 ls /var/log/docling-mcp/application > /dev/null 2>&1; then
    echo "FAIL: Other users can access logs (security violation!)"
else
    echo "PASS: Logs protected from other users"
fi

# 11. Test other users CANNOT access configuration directory (security validation)
if sudo -u agent0 ls /etc/docling-mcp/env > /dev/null 2>&1; then
    echo "FAIL: Other users can access config (security violation!)"
else
    echo "PASS: Config protected from other users"
fi
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Service account has appropriate read/write access
- Other users (like agent0) CANNOT access cache, logs, or configuration
- Permission model enforces security isolation

## Notes

### Permission Octal Notation

**Understanding Permissions**:
- **First digit**: Owner permissions (user: docling-mcp or root)
- **Second digit**: Group permissions (group: docling-mcp@hx.dev.local)
- **Third digit**: Other permissions (all other users)

**Octal Values**:
- **7 (rwx)**: Read + Write + Execute (full access)
- **5 (r-x)**: Read + Execute (no write - read-only with execution)
- **4 (r--)**: Read only (no write or execute)
- **0 (---)**: No access

**Permission Scheme**:
- **755 (rwxr-xr-x)**: Owner full, group/others read-execute only
- **750 (rwxr-x---)**: Owner full, group read-execute, others no access
- **770 (rwxrwx---)**: Owner/group full, others no access
- **644 (rw-r--r--)**: Owner read-write, group/others read-only
- **640 (rw-r-----)**: Owner read-write, group read-only, others no access

### Security Rationale by Directory

**Application Code (`/opt/docling-mcp/`)**: 755 directories, 644 files
- **Why**: Service needs to execute Python code and read source files
- **Write Access**: Service can write (owner), but production deployment would make read-only
- **Group/Others**: Can read code (transparency), cannot modify (security)
- **Execute**: Required for entering directories and executing Python scripts

**Cache Directory (`/var/lib/docling-mcp/`)**: 770
- **Why**: Service needs to cache DoclingDocument JSON, entity extraction results
- **Write Access**: Service must create/delete cache files
- **Group**: Service group has full access (future multi-instance support)
- **Others**: No access (prevents data leakage, cache contains document content)

**Log Directory (`/var/log/docling-mcp/`)**: 750
- **Why**: Service writes logs, administrators read for debugging
- **Write Access**: Service must write application logs, errors
- **Group**: Read-only for administrators (view logs via group membership)
- **Others**: No access (logs may contain sensitive debug information)

**Configuration (`/etc/docling-mcp/`)**: 750 directories, 640 files
- **Why**: Protects secrets (LiteLLM API key, Redis password, database credentials)
- **Write Access**: Only root can modify (prevents credential tampering)
- **Group**: Service can read via group membership (docling-mcp group)
- **Others**: No access (credential protection)

### Execute Permission on Directories

**Why Directories Need Execute Permission**:
- **Without execute (x)**: Cannot `cd` into directory or list contents
- **With execute (x)**: Can enter directory and access files (if file permissions allow)
- **Read + Execute (r-x)**: Can list directory and access files
- **Execute only (--x)**: Can access files if name is known, but cannot list directory

**Application**:
- All directories have execute permission for owner/group
- Enables service to navigate filesystem and access files
- `/var/lib/docling-mcp/`: 770 (owner/group can navigate, others cannot)

### Future File Permissions

**When deploying files** (Task 007 - Install Application Code, Task 008 - Configure Environment Files):

**Python Source Files** (`/opt/docling-mcp/src/*.py`):
```bash
sudo chmod 644 *.py
# Owner: read-write, Group/Others: read-only
```

**Environment Files** (`/etc/docling-mcp/env/.env`):
```bash
sudo chmod 640 /etc/docling-mcp/env/.env
sudo chown root:docling-mcp@hx.dev.local /etc/docling-mcp/env/.env
# Owner (root): read-write, Group (service): read-only, Others: no access
```

**Vault Files** (`/etc/docling-mcp/vault/credentials.yml`):
```bash
sudo chmod 640 /etc/docling-mcp/vault/credentials.yml
sudo chown root:docling-mcp@hx.dev.local /etc/docling-mcp/vault/credentials.yml
# Same as environment files (protect secrets)
```

**Python Virtual Environment** (`/opt/docling-mcp/venv/`):
```bash
# Virtual environment created with standard permissions (755 directories, 644 files)
# No special permission changes required
```

### Umask Considerations

**Default Umask**: 022 (typical Ubuntu default)
- New directories: 755 (777 - 022)
- New files: 644 (666 - 022)

**Service Umask**: Configure systemd service with `UMask=0027`
- New directories created by service: 750 (777 - 027)
- New files created by service: 640 (666 - 027)
- Ensures files created at runtime have restricted permissions

**Configuration** (Task 011 - Systemd Service):
```ini
[Service]
UMask=0027
```

### Permissions vs Ownership

**Distinction**:
- **Ownership** (Task 004): WHO owns files (user:group)
- **Permissions** (This Task): WHAT they can do (read/write/execute)

**Combined Enforcement**:
- Ownership: `docling-mcp:docling-mcp` (service owns cache/logs)
- Permissions: `770` (only owner/group can access)
- Result: Only docling-mcp service can read/write cache

### SELinux / AppArmor Considerations

**Ubuntu Default**: AppArmor enabled (not SELinux)
- AppArmor profiles may provide additional restrictions
- Standard filesystem permissions still apply
- No AppArmor profile needed for Phase 1 (manual procedures, no automation)

**Future**: If AppArmor profile needed (Phase 2):
- Profile would allow service to read `/etc/docling-mcp/`
- Profile would allow service to write `/var/lib/docling-mcp/` and `/var/log/docling-mcp/`
- Profile would deny service from writing `/opt/docling-mcp/` in production

### Troubleshooting

**If service cannot read /etc/docling-mcp**:
```bash
# Check permissions
ls -ld /etc/docling-mcp
# Should be: drwxr-x--- (750) root docling-mcp@hx.dev.local

# Check group membership
id docling-mcp@hx.dev.local | grep docling-mcp
# Service account should be in docling-mcp group

# Test group access explicitly
sudo -u docling-mcp@hx.dev.local -g docling-mcp@hx.dev.local ls /etc/docling-mcp
```

**If service cannot write to cache**:
```bash
# Check permissions
ls -ld /var/lib/docling-mcp/cache
# Should be: drwxrwx--- (770) docling-mcp@hx.dev.local docling-mcp@hx.dev.local

# Check ownership
stat -c '%U:%G' /var/lib/docling-mcp/cache
# Should be: docling-mcp@hx.dev.local:docling-mcp@hx.dev.local

# If incorrect, re-run Task 004 (ownership) first
```

**If other users can access restricted directories**:
```bash
# Security violation - check permissions
ls -ld /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp
# Should all show --- for others (no access)

# Re-apply restrictive permissions
sudo chmod 770 /var/lib/docling-mcp
sudo chmod 750 /var/log/docling-mcp
sudo chmod 750 /etc/docling-mcp
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 3.3.4: Permissions)
- **Security Standards**: `/home/agent0/HX-Infrastructure/standards/security-requirements.md`
- **Deployment Requirements**: `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`

## Risk Assessment

**Risk**: Low
- Permission changes do not affect operational services
- Changes are reversible
- Service not yet running (no service disruption)

**Mitigation**:
- Verify ownership set correctly first (Task 004)
- Test service account access after permission changes
- Validate other users cannot access restricted directories
- Follow principle of least privilege

**Rollback Procedure**:
```bash
# If permissions cause issues, reset to permissive state
sudo chmod -R 755 /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp
# WARNING: This is less secure - only use for troubleshooting
# Re-apply correct permissions after resolving issue
```
