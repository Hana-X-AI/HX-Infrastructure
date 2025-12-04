# Task 003: Create Base Directory Structure

**Assigned To**: frank-lucas
**Estimated Effort**: 0.5 hours
**Dependencies**: Task 001 (service account must exist)
**Status**: Not Started

## Objective

Create the complete base directory structure for Docling MCP Server on hx-docling-mcp-server (192.168.10.217) following HX-Infrastructure filesystem layout standards.

## Context

HX-Infrastructure services follow standardized directory layout conventions for consistency, security, and operational clarity:

- `/opt/<service>/` - Application code, virtual environment, non-volatile application data
- `/var/lib/<service>/` - Volatile data (cache, temporary files, working directory)
- `/var/log/<service>/` - Service logs (managed by systemd journal or application)
- `/etc/<service>/` - Configuration files (environment variables, secrets)

This structure ensures:
- Clear separation of code, data, configuration, and logs
- Proper permissions and ownership isolation
- Backup strategies can target specific directories
- Security controls aligned with filesystem hierarchy

## Pre-Execution Validation

**CRITICAL**: Check if base directories already exist BEFORE creating them.

```bash
# Check if primary directories exist
if [ -d "/opt/docling-mcp" ] && [ -d "/var/lib/docling-mcp" ] && [ -d "/var/log/docling-mcp" ] && [ -d "/etc/docling-mcp" ]; then
    echo "✅ VALIDATION RESULT: Base directory structure already exists"
    echo "Existing directories:"
    ls -ld /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp
    echo "ACTION: SKIP task execution - verify subdirectory structure instead"
    exit 0
else
    echo "❌ VALIDATION RESULT: Base directories do NOT exist"
    echo "ACTION: PROCEED with directory creation"
fi
```

**If Directories Exist**: Skip to Validation section, verify subdirectory structure

**If Directories Do Not Exist**: Continue with Implementation Steps below

---

## Acceptance Criteria

- [ ] `/opt/docling-mcp/` directory created with subdirectories
- [ ] `/var/lib/docling-mcp/` directory created for volatile data
- [ ] `/var/log/docling-mcp/` directory created for logs
- [ ] `/etc/docling-mcp/` directory created for configuration
- [ ] All directories created with correct ownership (root:root initially - ownership set in Task 004)
- [ ] All directories created with correct permissions (755 initially - refined in Task 005)
- [ ] Directory structure validated with tree command or ls

## Implementation Steps

### Step 1: SSH to Target Server

```bash
# Connect to hx-docling-mcp-server as agent0
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!
```

### Step 2: Create /opt/docling-mcp/ Application Directory

```bash
# Create primary application directory
sudo mkdir -p /opt/docling-mcp

# Create subdirectories for application structure
sudo mkdir -p /opt/docling-mcp/venv        # Python virtual environment
sudo mkdir -p /opt/docling-mcp/src         # Application source code
sudo mkdir -p /opt/docling-mcp/config      # Application config files (if any)
sudo mkdir -p /opt/docling-mcp/scripts     # Utility scripts (startup, maintenance)
sudo mkdir -p /opt/docling-mcp/data        # Non-volatile application data

# Verify creation
ls -la /opt/docling-mcp/
# Expected output:
# drwxr-xr-x  7 root root 4096 <date> .
# drwxr-xr-x  X root root 4096 <date> ..
# drwxr-xr-x  2 root root 4096 <date> config
# drwxr-xr-x  2 root root 4096 <date> data
# drwxr-xr-x  2 root root 4096 <date> scripts
# drwxr-xr-x  2 root root 4096 <date> src
# drwxr-xr-x  2 root root 4096 <date> venv
```

### Step 3: Create /var/lib/docling-mcp/ Data Directory

```bash
# Create data directory for volatile data
sudo mkdir -p /var/lib/docling-mcp

# Create subdirectories for cache and temporary files
sudo mkdir -p /var/lib/docling-mcp/cache       # Document processing cache
sudo mkdir -p /var/lib/docling-mcp/tmp         # Temporary files during processing
sudo mkdir -p /var/lib/docling-mcp/sessions    # Redis session backup (optional)

# Verify creation
ls -la /var/lib/docling-mcp/
# Expected output:
# drwxr-xr-x  5 root root 4096 <date> .
# drwxr-xr-x  X root root 4096 <date> ..
# drwxr-xr-x  2 root root 4096 <date> cache
# drwxr-xr-x  2 root root 4096 <date> sessions
# drwxr-xr-x  2 root root 4096 <date> tmp
```

### Step 4: Create /var/log/docling-mcp/ Log Directory

```bash
# Create log directory
sudo mkdir -p /var/log/docling-mcp

# Create subdirectories for different log types (optional, systemd journal may be primary)
sudo mkdir -p /var/log/docling-mcp/application  # Application logs (if file-based)
sudo mkdir -p /var/log/docling-mcp/access       # HTTP access logs (if applicable)
sudo mkdir -p /var/log/docling-mcp/error        # Error logs

# Verify creation
ls -la /var/log/docling-mcp/
# Expected output:
# drwxr-xr-x  5 root root 4096 <date> .
# drwxr-xr-x  X root root 4096 <date> ..
# drwxr-xr-x  2 root root 4096 <date> access
# drwxr-xr-x  2 root root 4096 <date> application
# drwxr-xr-x  2 root root 4096 <date> error
```

### Step 5: Create /etc/docling-mcp/ Configuration Directory

```bash
# Create configuration directory
sudo mkdir -p /etc/docling-mcp

# Create subdirectories for configuration management
sudo mkdir -p /etc/docling-mcp/env          # Environment files (.env)
sudo mkdir -p /etc/docling-mcp/vault        # Ansible Vault encrypted credentials (Phase 2)
sudo mkdir -p /etc/docling-mcp/ssl          # SSL certificates (Phase 2 if TLS enabled)

# Verify creation
ls -la /etc/docling-mcp/
# Expected output:
# drwxr-xr-x  5 root root 4096 <date> .
# drwxr-xr-x  X root root 4096 <date> ..
# drwxr-xr-x  2 root root 4096 <date> env
# drwxr-xr-x  2 root root 4096 <date> ssl
# drwxr-xr-x  2 root root 4096 <date> vault
```

### Step 6: Verify Complete Directory Structure

```bash
# Use tree command to visualize full structure (if available)
tree -L 2 -d /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp

# Alternative: Use find for hierarchical view
find /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp -type d | sort

# Expected output (sorted):
# /etc/docling-mcp
# /etc/docling-mcp/env
# /etc/docling-mcp/ssl
# /etc/docling-mcp/vault
# /opt/docling-mcp
# /opt/docling-mcp/config
# /opt/docling-mcp/data
# /opt/docling-mcp/scripts
# /opt/docling-mcp/src
# /opt/docling-mcp/venv
# /var/lib/docling-mcp
# /var/lib/docling-mcp/cache
# /var/lib/docling-mcp/sessions
# /var/lib/docling-mcp/tmp
# /var/log/docling-mcp
# /var/log/docling-mcp/access
# /var/log/docling-mcp/application
# /var/log/docling-mcp/error
```

## Validation

**Validation Commands:**

```bash
# 1. Verify all primary directories exist
for dir in /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp; do
  [ -d "$dir" ] && echo "PASS: $dir exists" || echo "FAIL: $dir missing"
done

# 2. Verify /opt/docling-mcp subdirectories
for subdir in venv src config scripts data; do
  [ -d "/opt/docling-mcp/$subdir" ] && echo "PASS: /opt/docling-mcp/$subdir exists" || echo "FAIL: /opt/docling-mcp/$subdir missing"
done

# 3. Verify /var/lib/docling-mcp subdirectories
for subdir in cache tmp sessions; do
  [ -d "/var/lib/docling-mcp/$subdir" ] && echo "PASS: /var/lib/docling-mcp/$subdir exists" || echo "FAIL: /var/lib/docling-mcp/$subdir missing"
done

# 4. Verify /var/log/docling-mcp subdirectories
for subdir in application access error; do
  [ -d "/var/log/docling-mcp/$subdir" ] && echo "PASS: /var/log/docling-mcp/$subdir exists" || echo "FAIL: /var/log/docling-mcp/$subdir missing"
done

# 5. Verify /etc/docling-mcp subdirectories
for subdir in env vault ssl; do
  [ -d "/etc/docling-mcp/$subdir" ] && echo "PASS: /etc/docling-mcp/$subdir exists" || echo "FAIL: /etc/docling-mcp/$subdir missing"
done

# 6. Count total directories created
find /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp -type d | wc -l
# Expected: 18 directories (4 primary + 14 subdirectories)
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Total of 18 directories created
- All directories owned by root:root (initial ownership)
- All directories have 755 permissions (initial permissions)

## Notes

### Directory Purpose Documentation

**Application Directory (`/opt/docling-mcp/`)**:
- `venv/` - Python 3.11 virtual environment (isolated dependency management)
- `src/` - Application source code (MCP server, document processor, LightRAG client)
- `config/` - Application-level config files (not environment variables)
- `scripts/` - Utility scripts (service startup, health checks, maintenance)
- `data/` - Non-volatile application data (persistent across service restarts)

**Data Directory (`/var/lib/docling-mcp/`)**:
- `cache/` - Document processing cache (DoclingDocument JSON, entity extraction results)
- `tmp/` - Temporary files during document processing (deleted on completion)
- `sessions/` - Redis session state backup (optional, for disaster recovery)

**Log Directory (`/var/log/docling-mcp/`)**:
- `application/` - Application logs (if file-based logging used, systemd journal is primary)
- `access/` - HTTP access logs (if MCP HTTP transport logging enabled)
- `error/` - Error logs (critical failures, exceptions)

**Configuration Directory (`/etc/docling-mcp/`)**:
- `env/` - Environment variable files (.env, .env.production)
- `vault/` - Ansible Vault encrypted credentials (Redis password, LiteLLM API key, etc.)
- `ssl/` - SSL/TLS certificates (Phase 2, if HTTPS transport enabled)

### HX-Infrastructure Directory Standards

**Ownership Strategy (Refined in Task 004)**:
- Application code (`/opt/docling-mcp/`): `docling-mcp:docling-mcp` (read-only for service)
- Data directory (`/var/lib/docling-mcp/`): `docling-mcp:docling-mcp` (read-write for cache)
- Log directory (`/var/log/docling-mcp/`): `docling-mcp:docling-mcp` (read-write for logging)
- Configuration (`/etc/docling-mcp/`): `root:docling-mcp` (read-only for service, writable by root only)

**Permissions Strategy (Refined in Task 005)**:
- Source code: 755 (directories), 644 (files) - read-execute for service
- Configuration: 640 (files) - read-only for service, no access for others
- Cache: 770 (read-write-execute for service, no access for others)
- Logs: 750 (read-write-execute for service, read-only for group)

### Filesystem Hierarchy Standard (FHS)

**Compliance**:
- `/opt/` - Add-on application software packages (FHS compliant)
- `/var/lib/` - Variable state information (FHS compliant)
- `/var/log/` - Log files (FHS compliant)
- `/etc/` - Host-specific system configuration (FHS compliant)

**Rationale**:
- Aligns with standard Linux filesystem hierarchy
- Enables standard backup strategies (separate /opt, /var, /etc backups)
- Clear separation of concerns (code vs data vs config vs logs)

### Security Considerations

**Initial Creation (Root Ownership)**:
- Directories created by root initially for security
- Prevents unauthorized directory creation
- Ensures correct permissions set explicitly

**Future Refinement**:
- Task 004 sets correct ownership (docling-mcp service account)
- Task 005 sets correct permissions (principle of least privilege)
- Configuration directory remains root-owned (protect secrets)

### Disk Space Considerations

**Estimated Space Requirements**:
- `/opt/docling-mcp/`: ~2GB (Python venv ~500MB, application code ~100MB, models/dependencies ~1.5GB)
- `/var/lib/docling-mcp/`: ~5-10GB (document cache, depends on usage)
- `/var/log/docling-mcp/`: ~1GB (log rotation recommended)
- `/etc/docling-mcp/`: ~10MB (configuration files, certificates)

**Total Estimate**: ~10-15GB

**Monitoring**:
```bash
# Check available disk space before creation
df -h /opt /var /etc
# Ensure adequate space available
```

### Troubleshooting

**If directory creation fails (permission denied)**:
```bash
# Verify running as root or with sudo
whoami
# Should be root, or use sudo

# Verify parent directory writable
ls -ld /opt /var/lib /var/log /etc
# Should be writable by root
```

**If directory already exists**:
```bash
# Check existing ownership and permissions
ls -ld /opt/docling-mcp
# If wrong ownership, will be corrected in Task 004
# Safe to proceed if directory exists with root ownership
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 3.3: Directory Structure)
- **Deployment Standards**: `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`
- **Filesystem Hierarchy Standard**: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html

## Risk Assessment

**Risk**: Very Low
- Directory creation is non-destructive
- No impact on operational services
- Easily reversible

**Mitigation**:
- Verify disk space before creation
- Use root ownership initially for security
- Validate complete structure before proceeding

**Rollback Procedure**:
```bash
# If directories need to be removed (only if catastrophic error)
sudo rm -rf /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp /etc/docling-mcp
# WARNING: Only use if task needs complete restart
```
