# Task 003: Create Directory Structure

**Assigned To**: frank-lucas
**Estimated Effort**: 0.25 hours
**Dependencies**: Task 001 (Service Account Creation)
**Status**: Not Started
**Phase**: Pre-Deployment

## Objective

Create standardized directory structure at `/opt/hx-lang-server` on hx-lang-server.hx.dev.local for the LangGraph Orchestration Server deployment.

## Context

HX-Infrastructure uses `/opt/<service-name>` as the standard installation location for all services. This provides:
- Consistent directory layout across all services
- Clear separation from system files
- Proper ownership and permissions
- Organized structure for application code, configuration, data, and logs

**Directory Structure Standard:**
```
/opt/hx-lang-server/
├── app/                    # Application code (Python modules)
├── config/                 # Configuration files (.env, settings)
├── data/                   # Application data (if needed)
├── logs/                   # Application logs (if not using journald)
├── venv/                   # Python virtual environment
└── vault/                  # Ansible Vault encrypted credentials
```

## Prerequisites

- [ ] Task 001 completed (service account `hx-lang-server@hx.dev.local` exists)
- [ ] SSH access to hx-lang-server.hx.dev.local as agent0
- [ ] Sudo privileges on hx-lang-server.hx.dev.local

## Acceptance Criteria

- [ ] Directory `/opt/hx-lang-server` created on hx-lang-server.hx.dev.local
- [ ] Subdirectories created: `app/`, `config/`, `data/`, `logs/`, `venv/`, `vault/`
- [ ] All directories owned by `hx-lang-server@hx.dev.local:domain users@hx.dev.local`
- [ ] Directory permissions set to `755` (rwxr-xr-x)
- [ ] `vault/` directory permissions set to `700` (rwx------) for security
- [ ] Directory structure verified and accessible by service account

## Implementation Steps

### Step 1: SSH to Target Server

```bash
# Connect to hx-lang-server as agent0
ssh agent0@hx-lang-server.hx.dev.local
# Password: Major8859!
```

### Step 2: Create Base Directory

```bash
# Create base directory with sudo
sudo mkdir -p /opt/hx-lang-server

# Verify base directory created
ls -ld /opt/hx-lang-server
# Expected: drwxr-xr-x 2 root root 4096 ... /opt/hx-lang-server
```

### Step 3: Create Subdirectory Structure

```bash
# Create all required subdirectories
sudo mkdir -p /opt/hx-lang-server/{app,config,data,logs,venv,vault}

# Verify subdirectories created
ls -la /opt/hx-lang-server/
# Expected output:
# drwxr-xr-x  8 root root 4096 ... .
# drwxr-xr-x  X root root 4096 ... ..
# drwxr-xr-x  2 root root 4096 ... app
# drwxr-xr-x  2 root root 4096 ... config
# drwxr-xr-x  2 root root 4096 ... data
# drwxr-xr-x  2 root root 4096 ... logs
# drwxr-xr-x  2 root root 4096 ... venv
# drwxr-xr-x  2 root root 4096 ... vault
```

### Step 4: Set Directory Ownership

```bash
# Change ownership of entire directory tree to service account
sudo chown -R hx-lang-server@hx.dev.local:domain\ users@hx.dev.local /opt/hx-lang-server

# Verify ownership change
ls -la /opt/hx-lang-server/
# Expected: all directories owned by hx-lang-server@hx.dev.local
```

### Step 5: Set Directory Permissions

```bash
# Set standard permissions (755) for all directories
sudo chmod 755 /opt/hx-lang-server
sudo chmod 755 /opt/hx-lang-server/{app,config,data,logs,venv}

# Set restrictive permissions (700) for vault directory
sudo chmod 700 /opt/hx-lang-server/vault

# Verify permissions
ls -la /opt/hx-lang-server/
# Expected:
# drwxr-xr-x ... hx-lang-server@hx.dev.local domain users@hx.dev.local ... app
# drwxr-xr-x ... hx-lang-server@hx.dev.local domain users@hx.dev.local ... config
# drwxr-xr-x ... hx-lang-server@hx.dev.local domain users@hx.dev.local ... data
# drwxr-xr-x ... hx-lang-server@hx.dev.local domain users@hx.dev.local ... logs
# drwxr-xr-x ... hx-lang-server@hx.dev.local domain users@hx.dev.local ... venv
# drwx------ ... hx-lang-server@hx.dev.local domain users@hx.dev.local ... vault
```

### Step 6: Verify Service Account Access

```bash
# Switch to service account
sudo su - hx-lang-server@hx.dev.local

# Test write access to each directory
touch /opt/hx-lang-server/app/test.txt && rm /opt/hx-lang-server/app/test.txt && echo "PASS: app/ writable"
touch /opt/hx-lang-server/config/test.txt && rm /opt/hx-lang-server/config/test.txt && echo "PASS: config/ writable"
touch /opt/hx-lang-server/data/test.txt && rm /opt/hx-lang-server/data/test.txt && echo "PASS: data/ writable"
touch /opt/hx-lang-server/logs/test.txt && rm /opt/hx-lang-server/logs/test.txt && echo "PASS: logs/ writable"
touch /opt/hx-lang-server/venv/test.txt && rm /opt/hx-lang-server/venv/test.txt && echo "PASS: venv/ writable"
touch /opt/hx-lang-server/vault/test.txt && rm /opt/hx-lang-server/vault/test.txt && echo "PASS: vault/ writable"

# Exit back to agent0
exit
```

## Validation

**Validation Commands (Run on hx-lang-server):**

```bash
# 1. Verify base directory exists
test -d /opt/hx-lang-server && echo "PASS: Base directory exists" || echo "FAIL: Base directory missing"

# 2. Verify all subdirectories exist
for dir in app config data logs venv vault; do
    test -d /opt/hx-lang-server/$dir && echo "PASS: $dir/ exists" || echo "FAIL: $dir/ missing"
done

# 3. Verify ownership
stat -c "%U %G" /opt/hx-lang-server | grep -q "hx-lang-server@hx.dev.local domain users@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# 4. Verify standard directory permissions (755)
for dir in app config data logs venv; do
    perm=$(stat -c "%a" /opt/hx-lang-server/$dir)
    [ "$perm" = "755" ] && echo "PASS: $dir/ permissions (755)" || echo "FAIL: $dir/ permissions ($perm, expected 755)"
done

# 5. Verify vault directory permissions (700)
perm=$(stat -c "%a" /opt/hx-lang-server/vault)
[ "$perm" = "700" ] && echo "PASS: vault/ permissions (700)" || echo "FAIL: vault/ permissions ($perm, expected 700)"

# 6. Verify service account can write to directories
sudo su - hx-lang-server@hx.dev.local -c "touch /opt/hx-lang-server/config/test && rm /opt/hx-lang-server/config/test" && echo "PASS: Service account write access" || echo "FAIL: Service account cannot write"
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Directory structure matches specification
- Ownership and permissions correct
- Service account has full read/write access

## Deliverables

1. Complete directory structure created at `/opt/hx-lang-server/`
2. All directories with correct ownership (`hx-lang-server@hx.dev.local`)
3. All directories with correct permissions (755 standard, 700 for vault)
4. Validation output confirming all acceptance criteria met

## Rollback Procedure

**If directory creation fails or needs reversal:**

```bash
# SSH to hx-lang-server
ssh agent0@hx-lang-server.hx.dev.local
# Password: Major8859!

# Remove entire directory tree
sudo rm -rf /opt/hx-lang-server

# Verify deletion
test ! -d /opt/hx-lang-server && echo "Directory removed successfully" || echo "Directory still exists"
```

**WARNING**: Rollback will delete ALL contents of `/opt/hx-lang-server/`. Only use during initial setup before any data exists.

## Notes

### Directory Purpose

| Directory | Purpose | Writable by Service | Backup Required |
|-----------|---------|---------------------|-----------------|
| `/opt/hx-lang-server/` | Base installation directory | Yes | No (recreatable) |
| `app/` | Python application code | Yes | No (version controlled) |
| `config/` | Configuration files (.env, settings.py) | Yes | Yes (contains secrets) |
| `data/` | Application data (if needed) | Yes | Yes (if used) |
| `logs/` | Application logs (if not using journald) | Yes | Optional |
| `venv/` | Python virtual environment | Yes | No (recreatable) |
| `vault/` | Ansible Vault encrypted credentials | Yes | Yes (critical) |

### Permissions Explained

**755 (rwxr-xr-x):**
- Owner (hx-lang-server): read, write, execute
- Group (domain users): read, execute
- Others: read, execute
- Used for: Most directories (app, config, data, logs, venv)

**700 (rwx------):**
- Owner (hx-lang-server): read, write, execute
- Group: no access
- Others: no access
- Used for: vault/ directory (security requirement)

### Why /opt/<service-name>?

HX-Infrastructure uses `/opt/` for third-party/custom applications:
- `/opt/` is standard Linux location for optional software
- Keeps applications separate from system directories
- Easy to backup entire service with single directory
- Consistent across all HX-Infrastructure services
- Avoids conflicts with package manager

### Security Considerations

- Service account has full control over its own directories
- Vault directory (700) ensures credentials only readable by service account
- No world-writable directories (security best practice)
- All directories owned by service account (least privilege)

### Troubleshooting

**Ownership command fails:**
```bash
# Verify service account exists
id hx-lang-server@hx.dev.local

# Verify SSSD running
sudo systemctl status sssd

# Force SSSD cache refresh
sudo sss_cache -E
sudo systemctl restart sssd

# Wait 10 seconds, then retry ownership command
sleep 10
sudo chown -R hx-lang-server@hx.dev.local:domain\ users@hx.dev.local /opt/hx-lang-server
```

**Permissions don't match:**
```bash
# Check actual permissions
stat -c "%a %n" /opt/hx-lang-server/*

# Reset all permissions
sudo chmod 755 /opt/hx-lang-server/{app,config,data,logs,venv}
sudo chmod 700 /opt/hx-lang-server/vault
```

**Service account cannot write:**
```bash
# Check ownership
ls -la /opt/hx-lang-server/

# Check permissions
stat -c "%a" /opt/hx-lang-server/config

# Verify service account identity
sudo su - hx-lang-server@hx.dev.local -c "id"
```

## References

- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/charter/charter.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md` (Section: Node Requirements, Service Account home directory)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- **Standards**: `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`

## Risk Assessment

**Risk**: Low
- Directory creation is non-disruptive
- No impact on operational services
- Easily reversible if issues occur
- No data exists yet to lose

**Mitigation**:
- Verify service account exists before creating directories
- Test service account write access after creation
- Document rollback procedure for easy reversal
