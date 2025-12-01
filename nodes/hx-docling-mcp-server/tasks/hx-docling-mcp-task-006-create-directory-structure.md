# Task 006: Create Directory Structure

**Task ID**: hx-docling-mcp-task-006
**Category**: Installation / Directory Setup
**Assigned To**: william-chen (Infrastructure Specialist)
**Status**: PENDING
**Priority**: HIGH (Blocker for deployment)
**Created**: 2025-11-27
**Estimated Effort**: 20 minutes

---

## Task Description

Create complete directory structure for Docling MCP Server deployment on hx-docling-mcp-server (192.168.10.217). This includes application directories (`/opt/docling-mcp`), configuration directories (`/etc/docling-mcp`), data directories (`/var/lib/docling-mcp`), and log directories (`/var/log/docling-mcp`) with proper ownership and permissions.

---

## Configuration Variables

**Vault Path Configuration**: Set this variable to match your deployment's vault location before executing Step 8:

```bash
# Default vault path (adjust for your environment)
export VAULT_TARGET_PATH="/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault"

# Alternative examples for different deployment scenarios:
# export VAULT_TARGET_PATH="/opt/hx-infrastructure/vault/docling-mcp"
# export VAULT_TARGET_PATH="/var/lib/ansible/vault/docling-mcp"
# export VAULT_TARGET_PATH="/mnt/shared/credentials/docling-mcp"
```

**NOTE**: The vault directory must exist and contain the credential files created in Task 004 before creating the symlink.

---

## Prerequisites

- [ ] Task 004 complete (Samba AD service account `docling-mcp@hx.dev.local` created)
- [ ] Task 005 complete (System dependencies installed)
- [ ] Node hx-docling-mcp-server (192.168.10.217) accessible via SSH
- [ ] SSSD configured (OR local account fallback available)
- [ ] Sufficient disk space (>10GB available on root filesystem)
- [ ] Vault directory exists at target path (default: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault`)
  - **Note**: Vault location may differ by deployment; verify path before Step 8
  - Created by Task 004 with encrypted credentials
  - Must be readable by service account

---

## Acceptance Criteria

- [ ] Application directory `/opt/docling-mcp` created with subdirectories
- [ ] Configuration directory `/etc/docling-mcp` created
- [ ] Data directory `/var/lib/docling-mcp` created with subdirectories
- [ ] Log directory `/var/log/docling-mcp` created
- [ ] All directories owned by `docling-mcp@hx.dev.local:domain users@hx.dev.local`
- [ ] Permissions set correctly (755 for directories, 750 for config)
- [ ] Vault symlink created to centralized credentials directory
- [ ] Directory structure validated via verification script

---

## Detailed Procedure

### Step 1: Verify Service Account Resolution

**Verify SSSD configured and service account resolvable**:

```bash
# Connect to node
ssh administrator@192.168.10.217

# Test service account resolution
id docling-mcp@hx.dev.local

# Expected output:
# uid=123456(docling-mcp@hx.dev.local) gid=10513(domain users@hx.dev.local) groups=10513(domain users@hx.dev.local)

# If SSSD not configured, use local account fallback:
# sudo useradd -r -s /bin/bash -d /opt/docling-mcp -m docling-mcp-local
```

**NOTE**: If using local account fallback, replace all `docling-mcp@hx.dev.local` references below with `docling-mcp-local`.

### Step 2: Create Application Directory Structure

**Create /opt/docling-mcp with subdirectories**:

```bash
# Create main application directory
sudo mkdir -p /opt/docling-mcp

# Create application subdirectories
sudo mkdir -p /opt/docling-mcp/application
sudo mkdir -p /opt/docling-mcp/application/docling_mcp
sudo mkdir -p /opt/docling-mcp/application/docling_mcp/tools
sudo mkdir -p /opt/docling-mcp/application/docling_mcp/processors
sudo mkdir -p /opt/docling-mcp/application/docling_mcp/clients
sudo mkdir -p /opt/docling-mcp/application/docling_mcp/utils
sudo mkdir -p /opt/docling-mcp/application/docling_mcp/models

# Create backup directory
sudo mkdir -p /opt/docling-mcp/backups
sudo mkdir -p /opt/docling-mcp/backups/config

# Create documentation directory
sudo mkdir -p /opt/docling-mcp/documentation

# Verify structure
tree -L 3 /opt/docling-mcp
```

**Expected Output**:
```
/opt/docling-mcp
├── application
│   └── docling_mcp
│       ├── clients
│       ├── models
│       ├── processors
│       ├── tools
│       └── utils
├── backups
│   └── config
└── documentation
```

### Step 3: Create Configuration Directory Structure

**Create /etc/docling-mcp**:

```bash
# Create main configuration directory
sudo mkdir -p /etc/docling-mcp

# Create certificate directory (for TLS in Phase 2)
sudo mkdir -p /etc/docling-mcp/certs

# Verify structure
ls -la /etc/docling-mcp
```

**Expected Output**:
```
total 12
drwxr-xr-x  3 root root 4096 Nov 27 12:00 .
drwxr-xr-x 95 root root 4096 Nov 27 12:00 ..
drwxr-xr-x  2 root root 4096 Nov 27 12:00 certs
```

### Step 4: Create Data Directory Structure

**Create /var/lib/docling-mcp**:

```bash
# Create main data directory
sudo mkdir -p /var/lib/docling-mcp

# Create cache directory (Docling cache)
sudo mkdir -p /var/lib/docling-mcp/cache

# Create workspace directory (document processing)
sudo mkdir -p /var/lib/docling-mcp/workspace

# Create LightRAG working directory
sudo mkdir -p /var/lib/docling-mcp/lightrag
sudo mkdir -p /var/lib/docling-mcp/lightrag/entities
sudo mkdir -p /var/lib/docling-mcp/lightrag/relations
sudo mkdir -p /var/lib/docling-mcp/lightrag/indices

# Verify structure
tree -L 2 /var/lib/docling-mcp
```

**Expected Output**:
```
/var/lib/docling-mcp
├── cache
├── lightrag
│   ├── entities
│   ├── relations
│   └── indices
└── workspace
```

### Step 5: Create Log Directory Structure

**Create /var/log/docling-mcp**:

```bash
# Create main log directory
sudo mkdir -p /var/log/docling-mcp

# Create archived log directory (rotated logs)
sudo mkdir -p /var/log/docling-mcp/archived

# Verify structure
ls -la /var/log/docling-mcp
```

**Expected Output**:
```
total 12
drwxr-xr-x  3 root root 4096 Nov 27 12:00 .
drwxrwxr-x 14 root syslog 4096 Nov 27 12:00 ..
drwxr-xr-x  2 root root 4096 Nov 27 12:00 archived
```

### Step 6: Set Directory Ownership

**Set ownership to service account**:

```bash
# Application directory (service account owns)
sudo chown -R 'docling-mcp@hx.dev.local:domain users@hx.dev.local' /opt/docling-mcp

# Verify ownership
ls -la /opt/docling-mcp
# Expected: docling-mcp@hx.dev.local domain users@hx.dev.local

# Configuration directory (root owns, service account group reads)
sudo chown -R root:docling-mcp@hx.dev.local /etc/docling-mcp

# Verify ownership
ls -la /etc/docling-mcp
# Expected: root docling-mcp@hx.dev.local

# Data directory (service account owns)
sudo chown -R 'docling-mcp@hx.dev.local:domain users@hx.dev.local' /var/lib/docling-mcp

# Verify ownership
ls -la /var/lib/docling-mcp
# Expected: docling-mcp@hx.dev.local domain users@hx.dev.local

# Log directory (service account owns)
sudo chown -R 'docling-mcp@hx.dev.local:domain users@hx.dev.local' /var/log/docling-mcp

# Verify ownership
ls -la /var/log/docling-mcp
# Expected: docling-mcp@hx.dev.local domain users@hx.dev.local
```

### Step 7: Set Directory Permissions

**Set permissions according to security requirements**:

```bash
# Application directory (755 - rwxr-xr-x)
sudo chmod 755 /opt/docling-mcp
sudo chmod 755 /opt/docling-mcp/application
sudo chmod 755 /opt/docling-mcp/backups
sudo chmod 755 /opt/docling-mcp/documentation

# Configuration directory (750 - rwxr-x---)
sudo chmod 750 /etc/docling-mcp
sudo chmod 700 /etc/docling-mcp/certs  # Restricted (certificates)

# Data directory (755 - rwxr-xr-x)
sudo chmod 755 /var/lib/docling-mcp
sudo chmod 755 /var/lib/docling-mcp/cache
sudo chmod 755 /var/lib/docling-mcp/workspace
sudo chmod 755 /var/lib/docling-mcp/lightrag

# Log directory (755 - rwxr-xr-x)
sudo chmod 755 /var/log/docling-mcp
sudo chmod 755 /var/log/docling-mcp/archived

# Verify permissions
stat -c "%a %n" /opt/docling-mcp /etc/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp
```

**Expected Output**:
```
755 /opt/docling-mcp
750 /etc/docling-mcp
755 /var/lib/docling-mcp
755 /var/log/docling-mcp
```

### Step 8: Create Vault Symlink

**Verify vault directory exists and create symlink to centralized credentials**:

```bash
# Set vault target path (use variable from Configuration section above)
# Default: export VAULT_TARGET_PATH="/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault"
# Ensure this variable is set before proceeding

# Prerequisite check: Verify vault directory exists
if [ ! -d "${VAULT_TARGET_PATH}" ]; then
    echo "ERROR: Vault directory not found at ${VAULT_TARGET_PATH}"
    echo "Please verify:"
    echo "  1. Task 004 completed (vault directory created)"
    echo "  2. VAULT_TARGET_PATH variable set correctly"
    echo "  3. Path is accessible from current shell"
    exit 1
fi

echo "✓ Vault directory found at ${VAULT_TARGET_PATH}"

# Verify vault contains expected credential files
if [ ! -f "${VAULT_TARGET_PATH}/vault_password.txt" ]; then
    echo "WARNING: vault_password.txt not found in ${VAULT_TARGET_PATH}"
    echo "This may indicate incomplete Task 004 execution"
fi

# Create vault symlink (points to centralized credentials)
sudo ln -s "${VAULT_TARGET_PATH}" /opt/docling-mcp/vault

# Verify symlink creation
ls -la /opt/docling-mcp/vault
# Expected: vault -> ${VAULT_TARGET_PATH}

# Verify symlink target is accessible
if [ -d /opt/docling-mcp/vault ]; then
    echo "✓ Vault symlink created successfully"
    ls -la /opt/docling-mcp/vault/
else
    echo "ERROR: Vault symlink broken or inaccessible"
    exit 1
fi
```

**Expected Output**:
```
✓ Vault directory found at /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault
✓ Vault symlink created successfully
lrwxrwxrwx 1 root root 71 Nov 30 12:00 /opt/docling-mcp/vault -> /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault
```

### Step 9: Create Directory Structure Documentation

**Document complete directory tree**:

```bash
# Create directory structure documentation
cat > /tmp/directory-structure-final.txt <<EOF
Directory Structure: Docling MCP Server
Generated: $(date)
Node: hx-docling-mcp-server (192.168.10.217)

Application Directory (/opt/docling-mcp):
/opt/docling-mcp/
├── venv/                           # Python virtual environment (created in Task 006)
├── application/                    # Application code
│   ├── docling_mcp/
│   │   ├── __init__.py
│   │   ├── server.py
│   │   ├── tools/                  # MCP tool implementations
│   │   ├── processors/             # Document processors
│   │   ├── clients/                # External service clients
│   │   ├── utils/                  # Utility modules
│   │   └── models/                 # Data models
│   ├── config.py
│   └── requirements.txt
├── backups/                        # Manual backups
│   └── config/                     # Configuration backups
├── documentation/                  # Deployment documentation
└── vault/                          # Symlink to Ansible Vault

Configuration Directory (/etc/docling-mcp):
/etc/docling-mcp/
├── .env                            # Environment variables (created in Task 010)
├── .env.template                   # Template (no secrets)
├── logging.conf                    # Logging configuration
└── certs/                          # SSL/TLS certificates (optional)

Data Directory (/var/lib/docling-mcp):
/var/lib/docling-mcp/
├── cache/                          # Docling cache (5GB)
├── workspace/                      # Document processing (2GB)
└── lightrag/                       # LightRAG working directory
    ├── entities/                   # Entity storage
    ├── relations/                  # Relationship storage
    └── indices/                    # Index files

Log Directory (/var/log/docling-mcp):
/var/log/docling-mcp/
├── docling-mcp.log                 # Main application log
├── error.log                       # Error-level logs
├── access.log                      # MCP request/response log
└── archived/                       # Rotated logs (gzip compressed)

Ownership:
- /opt/docling-mcp: docling-mcp@hx.dev.local:domain users@hx.dev.local
- /etc/docling-mcp: root:docling-mcp@hx.dev.local
- /var/lib/docling-mcp: docling-mcp@hx.dev.local:domain users@hx.dev.local
- /var/log/docling-mcp: docling-mcp@hx.dev.local:domain users@hx.dev.local

Permissions:
- /opt/docling-mcp: 755 (rwxr-xr-x)
- /etc/docling-mcp: 750 (rwxr-x---)
- /var/lib/docling-mcp: 755 (rwxr-xr-x)
- /var/log/docling-mcp: 755 (rwxr-xr-x)

Disk Space Allocation:
- /opt/docling-mcp: 500MB (application + venv)
- /var/lib/docling-mcp: 10GB (5GB cache + 2GB workspace + 3GB LightRAG)
- /var/log/docling-mcp: 3GB (100MB × 30 rotated logs)
- Total: ~13.5GB

Created: $(date)
Created By: $(whoami)
EOF

cat /tmp/directory-structure-final.txt

# Copy to documentation
sudo cp /tmp/directory-structure-final.txt /opt/docling-mcp/documentation/directory-structure.txt
sudo chown 'docling-mcp@hx.dev.local:domain users@hx.dev.local' /opt/docling-mcp/documentation/directory-structure.txt
```

---

## Validation

### Validation Script

```bash
# Create directory validation script
cat > /tmp/validate-directories.sh <<'EOF'
#!/bin/bash
# Directory Structure Validation Script

echo "===== Directory Structure Validation ====="
echo ""

# Function to check directory
check_dir() {
    local dir=$1
    local expected_owner=$2
    local expected_perms=$3

    echo -n "Checking $dir... "
    if [ -d "$dir" ]; then
        echo "✓ EXISTS"

        # Check ownership
        actual_owner=$(stat -c "%U:%G" "$dir")
        echo "  Ownership: $actual_owner (expected: $expected_owner)"

        # Check permissions
        actual_perms=$(stat -c "%a" "$dir")
        echo "  Permissions: $actual_perms (expected: $expected_perms)"

        if [ "$actual_owner" != "$expected_owner" ]; then
            echo "  ✗ OWNERSHIP MISMATCH"
            return 1
        fi

        if [ "$actual_perms" != "$expected_perms" ]; then
            echo "  ✗ PERMISSIONS MISMATCH"
            return 1
        fi

        echo "  ✓ VALID"
    else
        echo "✗ NOT FOUND"
        return 1
    fi
    echo ""
}

# Check application directories
check_dir "/opt/docling-mcp" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"
check_dir "/opt/docling-mcp/application" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"
check_dir "/opt/docling-mcp/backups" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"

# Check configuration directories
check_dir "/etc/docling-mcp" "root:docling-mcp@hx.dev.local" "750"
check_dir "/etc/docling-mcp/certs" "root:docling-mcp@hx.dev.local" "700"

# Check data directories
check_dir "/var/lib/docling-mcp" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"
check_dir "/var/lib/docling-mcp/cache" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"
check_dir "/var/lib/docling-mcp/workspace" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"
check_dir "/var/lib/docling-mcp/lightrag" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"

# Check log directories
check_dir "/var/log/docling-mcp" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"
check_dir "/var/log/docling-mcp/archived" "docling-mcp@hx.dev.local:domain users@hx.dev.local" "755"

# Check vault symlink
echo -n "Checking /opt/docling-mcp/vault... "
if [ -L "/opt/docling-mcp/vault" ]; then
    target=$(readlink "/opt/docling-mcp/vault")
    echo "✓ SYMLINK EXISTS"
    echo "  Target: $target"
    if [ -d "$target" ]; then
        echo "  ✓ TARGET EXISTS"
    else
        echo "  ✗ TARGET NOT FOUND"
    fi
else
    echo "✗ SYMLINK NOT FOUND"
fi

echo ""
echo "===== Validation Complete ====="
EOF

chmod +x /tmp/validate-directories.sh
/tmp/validate-directories.sh
```

### Success Criteria

- ✅ All directories exist
- ✅ Ownership correct (service account for /opt, /var/lib, /var/log)
- ✅ Permissions correct (755 for application/data/log, 750 for config)
- ✅ Vault symlink created and pointing to correct location
- ✅ Disk space sufficient (>10GB available)
- ✅ Directory structure documentation created

---

## Rollback Procedure

**If directory creation fails or needs removal**:

```bash
# Remove all created directories
sudo rm -rf /opt/docling-mcp
sudo rm -rf /etc/docling-mcp
sudo rm -rf /var/lib/docling-mcp
sudo rm -rf /var/log/docling-mcp

# Verify removal
test ! -d /opt/docling-mcp && echo "Application directory removed"
test ! -d /etc/docling-mcp && echo "Configuration directory removed"
test ! -d /var/lib/docling-mcp && echo "Data directory removed"
test ! -d /var/log/docling-mcp && echo "Log directory removed"
```

---

## Dependencies

**Blocks**:
- Task 006: Create Python virtual environment (requires /opt/docling-mcp)
- Task 010: Configure environment files (requires /etc/docling-mcp)
- Task 011: Configure logging (requires /var/log/docling-mcp)

**Depends On**:
- Task 004: Create Samba AD service account (ownership requirements)
- Task 005: Install system dependencies (node ready)
- Disk space available (>10GB)

---

## Notes

### Directory Ownership Rationale

| Directory | Owner | Group | Rationale |
|-----------|-------|-------|-----------|
| `/opt/docling-mcp` | docling-mcp@hx.dev.local | domain users@hx.dev.local | Service needs read/write/execute |
| `/etc/docling-mcp` | root | docling-mcp@hx.dev.local | Admin writes, service reads only |
| `/var/lib/docling-mcp` | docling-mcp@hx.dev.local | domain users@hx.dev.local | Service needs read/write for data |
| `/var/log/docling-mcp` | docling-mcp@hx.dev.local | domain users@hx.dev.local | Service needs write for logs |

### Permission Matrix Rationale

| Path | Permissions | Rationale |
|------|------------|-----------|
| Application directories | 755 (rwxr-xr-x) | Service execute, others read |
| Configuration directory | 750 (rwxr-x---) | Admin write, service read, no world access |
| Certificate directory | 700 (rwx------) | Highly restricted (private keys) |
| Data directories | 755 (rwxr-xr-x) | Service read/write, others read |
| Log directories | 755 (rwxr-xr-x) | Service write, others read logs |

### HX-Infrastructure Standards Compliance

- ✅ **Samba AD Integration**: Service account ownership
- ✅ **Security Hardening**: Restricted permissions on configuration
- ✅ **Manual Procedures**: All commands documented for human execution
- ✅ **No Automation**: No directory creation scripts, manual execution only

---

## References

- **Configuration Spec**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/configuration-spec.md` (Section 4: Directory Structure)
- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 003)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
