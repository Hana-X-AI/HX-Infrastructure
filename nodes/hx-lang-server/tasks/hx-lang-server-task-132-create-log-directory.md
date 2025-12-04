# Task 132: Create Log Directory Structure

**Task ID**: hx-lang-server-task-132
**Phase**: Configuration (Logging & Monitoring)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 003 (Directory Structure), Task 001 (Service Account)
**Estimated Effort**: 15 minutes

---

## Objective

Create log directory `/var/log/hx-lang-server` with appropriate ownership and permissions for service logging. While primary logs go to systemd journal, this directory provides a location for application-specific log files if needed.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Service account hx-lang-server exists (Task 001)

---

## Pre-Execution Validation

**CRITICAL**: Check if log directory already exists BEFORE creating.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check log directory
LOG_DIR="/var/log/hx-lang-server"

echo "Checking log directory status..."

if [ -d "$LOG_DIR" ]; then
    echo "Log directory exists: $LOG_DIR"
    ls -la "$LOG_DIR"
    echo ""
    echo "Current ownership:"
    stat -c "%U:%G" "$LOG_DIR"
    echo ""
    echo "VALIDATION RESULT: Log directory already exists"
    echo "ACTION: Verify ownership and permissions, skip creation if correct"
else
    echo "VALIDATION RESULT: Log directory does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Exists**: Verify ownership and permissions
**If Not Exists**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Create Log Directory

```bash
# Create log directory
LOG_DIR="/var/log/hx-lang-server"

echo "Creating log directory: $LOG_DIR"

sudo mkdir -p "$LOG_DIR"

if [ $? -eq 0 ]; then
    echo "Log directory created successfully"
else
    echo "ERROR: Failed to create log directory"
    exit 1
fi
```

### Step 2: Set Directory Ownership

```bash
# Set ownership to service account
LOG_DIR="/var/log/hx-lang-server"

echo "Setting log directory ownership..."

# Determine service account
if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
    SERVICE_GROUP="domain users@hx.dev.local"
    echo "Using Samba AD domain account: $SERVICE_USER"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
    SERVICE_GROUP="hx-lang-server"
    echo "Using local system account: $SERVICE_USER"
else
    SERVICE_USER="root"
    SERVICE_GROUP="root"
    echo "WARNING: Service account not found, using root"
fi

# Set ownership
sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"

# Verify ownership
OWNER=$(stat -c "%U" "$LOG_DIR")
echo "Directory owner: $OWNER"
```

### Step 3: Set Directory Permissions

```bash
# Set directory permissions
LOG_DIR="/var/log/hx-lang-server"

echo "Setting log directory permissions..."

# Owner: rwx, Group: rx, Others: none
sudo chmod 750 "$LOG_DIR"

# Verify permissions
ls -la "$(dirname $LOG_DIR)" | grep "hx-lang-server"
echo "Permissions set: 750 (rwxr-x---)"
```

### Step 4: Create Log Subdirectories

```bash
# Create subdirectories for different log types
LOG_DIR="/var/log/hx-lang-server"

echo "Creating log subdirectories..."

# Application logs
sudo mkdir -p "$LOG_DIR/app"

# Audit logs
sudo mkdir -p "$LOG_DIR/audit"

# Debug logs (for development)
sudo mkdir -p "$LOG_DIR/debug"

# Set ownership recursively
sudo chown -R "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"

# Set permissions on subdirectories
sudo chmod 750 "$LOG_DIR/app"
sudo chmod 750 "$LOG_DIR/audit"
sudo chmod 750 "$LOG_DIR/debug"

# List structure
echo "Log directory structure:"
ls -la "$LOG_DIR"
```

### Step 5: Create Placeholder Files

```bash
# Create placeholder README
LOG_DIR="/var/log/hx-lang-server"

echo "Creating placeholder documentation..."

sudo tee "$LOG_DIR/README.txt" > /dev/null <<'EOF'
# hx-lang-server Log Directory

## Primary Logging
Primary logs are written to systemd journal (stdout).
View with: sudo journalctl -u hx-lang-server.service

## Directory Structure
/var/log/hx-lang-server/
  app/    - Application-specific log files (if enabled)
  audit/  - Audit trail logs (if enabled)
  debug/  - Debug logs (development only)

## Log Rotation
See: /etc/logrotate.d/hx-lang-server

## Retention Policy
- Journal logs: 7 days or 500MB
- File logs: 30 days (if enabled)

## Contact
Infrastructure Team: william-chen
EOF

sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR/README.txt"
sudo chmod 644 "$LOG_DIR/README.txt"

echo "Placeholder documentation created"
cat "$LOG_DIR/README.txt"
```

### Step 6: Document Log Directory Configuration

```bash
# Document log directory configuration
DOC_DIR="/opt/hx-lang-server/deployment-docs"
LOG_DIR="/var/log/hx-lang-server"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/log-directory-configuration.txt" > /dev/null <<EOF
# Log Directory Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-132

## Log Directory
Location: $LOG_DIR
Owner: $SERVICE_USER
Group: $SERVICE_GROUP
Permissions: 750 (rwxr-x---)

## Directory Structure
$(ls -la $LOG_DIR)

## Subdirectories
- app/: Application-specific logs
- audit/: Audit trail logs
- debug/: Debug logs (development)

## Primary Logging
Primary logs go to systemd journal (stdout).
This directory is for auxiliary log files only.

## Access Commands
# View directory
ls -la $LOG_DIR

# Check disk usage
du -sh $LOG_DIR

# View recent files
find $LOG_DIR -type f -mtime -1

## Systemd Journal Commands
# Real-time logs
sudo journalctl -u hx-lang-server.service -f

# Last 100 lines
sudo journalctl -u hx-lang-server.service -n 100
EOF

echo "Log directory documented: $DOC_DIR/log-directory-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Log Directory | /var/log/hx-lang-server | Main log directory |
| App Logs | /var/log/hx-lang-server/app | Application logs subdirectory |
| Audit Logs | /var/log/hx-lang-server/audit | Audit logs subdirectory |
| Debug Logs | /var/log/hx-lang-server/debug | Debug logs subdirectory |
| Documentation | /opt/hx-lang-server/deployment-docs/log-directory-configuration.txt | Configuration doc |

---

## Verification

**Validation Commands:**

```bash
echo "=== Log Directory Validation ==="

LOG_DIR="/var/log/hx-lang-server"
VALIDATION_PASSED=true

# Check 1: Directory exists
echo "1. Directory Existence:"
if [ -d "$LOG_DIR" ]; then
    echo "PASSED: Log directory exists"
else
    echo "FAILED: Log directory does not exist"
    VALIDATION_PASSED=false
fi

# Check 2: Subdirectories exist
echo ""
echo "2. Subdirectories:"
for subdir in app audit debug; do
    if [ -d "$LOG_DIR/$subdir" ]; then
        echo "PASSED: $subdir subdirectory exists"
    else
        echo "FAILED: $subdir subdirectory missing"
        VALIDATION_PASSED=false
    fi
done

# Check 3: Ownership
echo ""
echo "3. Ownership:"
OWNER=$(stat -c "%U" "$LOG_DIR")
if [[ "$OWNER" == "hx-lang-server" || "$OWNER" == "hx-lang-server@hx.dev.local" || "$OWNER" == "root" ]]; then
    echo "PASSED: Ownership is $OWNER"
else
    echo "WARNING: Unexpected ownership: $OWNER"
fi

# Check 4: Permissions
echo ""
echo "4. Permissions:"
PERMS=$(stat -c "%a" "$LOG_DIR")
if [ "$PERMS" = "750" ]; then
    echo "PASSED: Permissions are 750"
else
    echo "WARNING: Permissions are $PERMS (expected 750)"
fi

# Check 5: Writable by service account
echo ""
echo "5. Write Test:"
sudo -u hx-lang-server touch "$LOG_DIR/test.tmp" 2>/dev/null && \
    rm -f "$LOG_DIR/test.tmp" && \
    echo "PASSED: Directory writable by service account" || \
    echo "WARNING: Cannot write as service account (may use root)"

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Log directory ready"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- Log directory exists at /var/log/hx-lang-server
- All subdirectories (app, audit, debug) exist
- Ownership set to service account
- Permissions are 750
- Directory is writable by service account

---

## Rollback Procedure

Remove log directory if needed:

```bash
# Remove log directory
LOG_DIR="/var/log/hx-lang-server"

echo "Removing log directory..."

# Ensure no processes are writing to directory
lsof +D "$LOG_DIR" 2>/dev/null && echo "WARNING: Files in use"

# Remove directory
sudo rm -rf "$LOG_DIR"

# Verify removal
if [ ! -d "$LOG_DIR" ]; then
    echo "Log directory removed successfully"
else
    echo "ERROR: Failed to remove log directory"
fi
```

---

## Notes

**Primary vs File Logging:**
- Primary logs go to stdout (systemd journal)
- File-based logging is optional for specific use cases
- Journal provides better integration with systemd

**Directory Permissions:**
- 750: Owner full access, group read/execute, others none
- Service account can write logs
- Root can always access for troubleshooting

**Subdirectory Purpose:**
- app/: Temporary application logs (if file output needed)
- audit/: Security-relevant events (if enabled)
- debug/: Verbose debugging (development only)

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Node Requirements - Storage (line 130)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 12: Logging & Monitoring (Task Range 131-140)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Permission denied**: Cannot create directory in /var/log
   - Mitigation: Use sudo for all operations
2. **Wrong ownership**: Service cannot write logs
   - Mitigation: Verify service account exists before setting ownership
3. **Disk space**: Logs fill disk
   - Mitigation: Log rotation configured in Task 133

**Dependencies Blocked:**
- Task 133 (Log Rotation) configures rotation for this directory
- Application may use this directory for specific log files
