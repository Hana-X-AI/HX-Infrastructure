# Task 151: Create Systemd Service Unit File

**Assigned To**: william-chen
**Estimated Effort**: 2 hours
**Dependencies**: Task 008 (Environment Configuration), Task 022 (Python Dependencies)
**Status**: Not Started

## Objective

Create production-grade systemd service unit file for Docling MCP Server with auto-restart configuration, resource limits, and proper service dependencies.

## Pre-Execution Validation

**CRITICAL**: Check if systemd service unit file already exists BEFORE creating new unit file.

```bash
# Validation command to check if systemd unit file exists
UNIT_FILE="/etc/systemd/system/docling-mcp.service"

echo "Checking systemd service unit file status..."

if [ -f "$UNIT_FILE" ]; then
    echo "✅ Systemd unit file exists: $UNIT_FILE"
    echo ""
    echo "Current unit file content:"
    cat "$UNIT_FILE"
    echo ""
    echo "✅ VALIDATION RESULT: Systemd service unit already configured"
    echo "ACTION: SKIP task execution if configuration is correct, or proceed to update"
    echo ""
    echo "Checking if service is registered with systemd..."
    if systemctl list-unit-files | grep -q "docling-mcp.service"; then
        echo "✅ Service registered with systemd"
        systemctl status docling-mcp.service --no-pager || true
    else
        echo "⚠️  Service file exists but not registered, may need daemon-reload"
    fi
    exit 0
else
    echo "❌ VALIDATION RESULT: Systemd unit file does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Review existing unit file, skip if correct
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Systemd is the service manager for Ubuntu 24.04 LTS, providing:

- **Service Lifecycle Management**: Start, stop, restart, enable/disable
- **Auto-Restart**: Automatic restart on failure (resilience)
- **Resource Limits**: Memory, CPU quotas via cgroups
- **Logging Integration**: Automatic journal logging (no log file management needed)
- **Dependency Management**: Service ordering and dependencies

The Docling MCP Server runs as a systemd service (`docling-mcp.service`) with:
- **User**: docling-mcp service account (from Task 001)
- **ExecStart**: Uvicorn ASGI server running MCP server application
- **Restart Policy**: Auto-restart on failure (3 attempts in 5 minutes)
- **Resource Limits**: 4GB memory, 2 CPU cores

This task creates the systemd unit file. Service activation occurs in Task 152.

## Acceptance Criteria

- [ ] Systemd unit file created at `/etc/systemd/system/docling-mcp.service`
- [ ] Unit file follows specification from node-spec.md (lines 4901-4960)
- [ ] Service user set to docling-mcp account (domain or local account from Task 004)
- [ ] ExecStart command uses venv Python interpreter (`/opt/docling-mcp/venv/bin/uvicorn`)
- [ ] EnvironmentFile directive points to `/etc/docling-mcp/.env.production`
- [ ] Auto-restart policy configured (Restart=on-failure, 3 attempts in 5 minutes)
- [ ] Resource limits configured (4GB memory, 200% CPU quota)
- [ ] Logging configured to systemd journal (StandardOutput=journal, StandardError=journal)
- [ ] Service dependencies configured (After=network-online.target, Wants=network-online.target)
- [ ] No syntax errors in unit file (validated with `systemd-analyze verify`)

## Implementation Steps

### Step 1: Determine Service Account Type

```bash
# Determine if using domain account or local account
# This affects User= and Group= directives in unit file

echo "Determining service account configuration..."

if getent passwd docling-mcp@hx.dev.local > /dev/null 2>&1; then
    SERVICE_USER="docling-mcp@hx.dev.local"
    SERVICE_GROUP="domain users@hx.dev.local"
    ACCOUNT_TYPE="domain"
    echo "✅ Using Samba AD domain account: $SERVICE_USER"
elif getent passwd docling-mcp > /dev/null 2>&1; then
    SERVICE_USER="docling-mcp"
    SERVICE_GROUP="docling-mcp"
    ACCOUNT_TYPE="local"
    echo "✅ Using local system account: $SERVICE_USER"
else
    echo "❌ Service account not found (neither domain nor local)"
    echo "Prerequisite: Task 001 and Task 004 must be complete"
    exit 1
fi

echo "Account type: $ACCOUNT_TYPE"
echo "User: $SERVICE_USER"
echo "Group: $SERVICE_GROUP"
```

### Step 2: Verify Prerequisites

```bash
# Verify prerequisites before creating unit file
echo "Verifying prerequisites..."

# Check virtual environment exists
if [ ! -f "/opt/docling-mcp/venv/bin/uvicorn" ]; then
    echo "❌ Uvicorn not found in venv - Task 022 prerequisite not met"
    exit 1
else
    echo "✅ Uvicorn available in venv"
fi

# Check environment file exists
if [ ! -f "/etc/docling-mcp/.env.production" ]; then
    echo "⚠️  WARNING: .env.production not found - Task 008 may not be complete"
    echo "Continuing, but service may fail to start without environment configuration"
else
    echo "✅ Environment file exists"
fi

# Check application code exists (from Task 007)
if [ ! -d "/opt/docling-mcp/src" ]; then
    echo "⚠️  WARNING: Application code directory not found - Task 007 may not be complete"
    echo "Continuing, but service will fail to start without application code"
else
    echo "✅ Application code directory exists"
fi
```

### Step 3: Create Systemd Unit File

```bash
# Create systemd service unit file
UNIT_FILE="/etc/systemd/system/docling-mcp.service"

echo "Creating systemd service unit file: $UNIT_FILE"

# Determine User and Group directives based on account type
if [ "$ACCOUNT_TYPE" = "domain" ]; then
    USER_DIRECTIVE="User=docling-mcp@hx.dev.local"
    GROUP_DIRECTIVE="Group=domain users@hx.dev.local"
else
    USER_DIRECTIVE="User=docling-mcp"
    GROUP_DIRECTIVE="Group=docling-mcp"
fi

# Create unit file with proper variable expansion
# Use temporary file to ensure variables are expanded before sudo writes
TEMP_UNIT=$(mktemp /tmp/docling-mcp-unit.XXXXXX)

# Write unit file to temporary location with variable expansion
cat > "$TEMP_UNIT" <<EOF
[Unit]
Description=Docling MCP Server - Document Processing and Knowledge Graph Service
Documentation=file:///opt/docling-mcp/README.md
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
${USER_DIRECTIVE}
${GROUP_DIRECTIVE}
WorkingDirectory=/opt/docling-mcp
Environment="PATH=/opt/docling-mcp/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EnvironmentFile=/etc/docling-mcp/.env.production

# Pre-start validation
ExecStartPre=/opt/docling-mcp/venv/bin/python -c "import docling, fastmcp; print('Dependencies validated')"
ExecStartPre=/bin/mkdir -p /var/lib/docling-mcp/cache/uploads /var/lib/docling-mcp/cache/downloads
ExecStartPre=/bin/chown -R ${SERVICE_USER}:${SERVICE_GROUP} /var/lib/docling-mcp /var/log/docling-mcp

# Main service execution
ExecStart=/opt/docling-mcp/venv/bin/uvicorn src.mcp_server:app --host 0.0.0.0 --port 8000 --log-level info --workers 1

# Graceful shutdown
ExecStop=/bin/kill -TERM \$MAINPID
TimeoutStopSec=30

# Automatic restart policy
Restart=on-failure
RestartSec=10s
StartLimitInterval=300s
StartLimitBurst=3

# Resource limits
MemoryLimit=4G
CPUQuota=200%
TasksMax=1024

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=docling-mcp

[Install]
WantedBy=multi-user.target
EOF

# Move temporary file to systemd location with sudo
if sudo cp "$TEMP_UNIT" "$UNIT_FILE"; then
    # Set proper permissions
    sudo chmod 644 "$UNIT_FILE"
    # Clean up temporary file
    rm -f "$TEMP_UNIT"
    echo "✅ Systemd unit file created successfully"
    
    # Verify variable expansion worked
    echo ""
    echo "Verifying User/Group directives in unit file:"
    sudo grep -E "^(User|Group)=" "$UNIT_FILE"
else
    echo "❌ Failed to create systemd unit file"
    rm -f "$TEMP_UNIT"
    exit 1
fi
```

### Step 4: Validate Unit File Syntax

```bash
# Validate systemd unit file syntax
UNIT_FILE="/etc/systemd/system/docling-mcp.service"

echo "Validating systemd unit file syntax..."

# Use systemd-analyze to check for syntax errors
sudo systemd-analyze verify "$UNIT_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Unit file syntax validation passed"
else
    echo "⚠️  WARNING: systemd-analyze reported issues, review output above"
    echo "This may be acceptable depending on systemd version"
fi

# Display created unit file
echo ""
echo "Created unit file content:"
cat "$UNIT_FILE"
```

### Step 5: Reload Systemd Daemon

```bash
# Reload systemd daemon to register new unit file
echo "Reloading systemd daemon to register new service..."

sudo systemctl daemon-reload

if [ $? -eq 0 ]; then
    echo "✅ Systemd daemon reloaded successfully"
else
    echo "❌ Systemd daemon reload failed"
    exit 1
fi

# Verify service is recognized by systemd
if systemctl list-unit-files | grep -q "docling-mcp.service"; then
    echo "✅ Service registered with systemd"
else
    echo "❌ Service not registered, unit file may have errors"
    exit 1
fi
```

### Step 6: Document Systemd Configuration

```bash
# Document systemd configuration for operational reference
DOC_PATH="/opt/docling-mcp/deployment-docs"
mkdir -p "$DOC_PATH"

cat > "$DOC_PATH/systemd-service-configuration.txt" <<EOF
# Systemd Service Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-docling-mcp-server.hx.dev.local
# Task: hx-docling-mcp-task-151

## Service Unit File
Location: /etc/systemd/system/docling-mcp.service

## Service Account
User: $SERVICE_USER
Group: $SERVICE_GROUP
Account Type: $ACCOUNT_TYPE

## Service Management Commands

# Start service
sudo systemctl start docling-mcp.service

# Stop service
sudo systemctl stop docling-mcp.service

# Restart service
sudo systemctl restart docling-mcp.service

# Check service status
sudo systemctl status docling-mcp.service

# View service logs
sudo journalctl -u docling-mcp.service -f

# Enable service for auto-start
sudo systemctl enable docling-mcp.service

# Disable service auto-start
sudo systemctl disable docling-mcp.service

## Resource Limits
Memory Limit: 4GB
CPU Quota: 200% (2 cores)
Tasks Max: 1024

## Auto-Restart Policy
Restart on: failure
Restart delay: 10 seconds
Restart limit: 3 attempts in 5 minutes

## Unit File Content
$(cat /etc/systemd/system/docling-mcp.service)
EOF

echo "✅ Systemd configuration documented: $DOC_PATH/systemd-service-configuration.txt"
```

## Validation

**Validation Commands:**

```bash
echo "=== Systemd Service Unit File Validation ==="

UNIT_FILE="/etc/systemd/system/docling-mcp.service"

# Validate unit file exists
echo "1. Unit File Existence:"
if [ -f "$UNIT_FILE" ]; then
    echo "✅ PASSED: Unit file exists at $UNIT_FILE"
else
    echo "❌ FAILED: Unit file not found"
    exit 1
fi

# Validate unit file registered with systemd
echo ""
echo "2. Systemd Registration:"
if systemctl list-unit-files | grep -q "docling-mcp.service"; then
    echo "✅ PASSED: Service registered with systemd"
else
    echo "❌ FAILED: Service not registered"
    exit 1
fi

# Validate unit file syntax
echo ""
echo "3. Syntax Validation:"
if sudo systemd-analyze verify "$UNIT_FILE" 2>&1 | grep -q "Error"; then
    echo "❌ FAILED: Syntax errors detected"
    sudo systemd-analyze verify "$UNIT_FILE"
    exit 1
else
    echo "✅ PASSED: No fatal syntax errors"
fi

# Validate critical directives present
echo ""
echo "4. Critical Directives:"
REQUIRED_DIRECTIVES=(
    "ExecStart=/opt/docling-mcp/venv/bin/uvicorn"
    "EnvironmentFile=/etc/docling-mcp/.env.production"
    "Restart=on-failure"
    "MemoryLimit=4G"
    "StandardOutput=journal"
    "WantedBy=multi-user.target"
)

ALL_PRESENT=true

for directive in "${REQUIRED_DIRECTIVES[@]}"; do
    if grep -q "$directive" "$UNIT_FILE"; then
        echo "✅ PASSED: $directive present"
    else
        echo "❌ FAILED: $directive missing"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo "❌ Critical directives missing from unit file"
    exit 1
fi

# Validate service status (should be inactive/dead at this point)
echo ""
echo "5. Service Status:"
SERVICE_STATE=$(systemctl is-active docling-mcp.service 2>/dev/null || echo "unknown")
echo "Service state: $SERVICE_STATE"

if [ "$SERVICE_STATE" = "inactive" ] || [ "$SERVICE_STATE" = "unknown" ]; then
    echo "✅ PASSED: Service not started yet (expected)"
elif [ "$SERVICE_STATE" = "active" ]; then
    echo "⚠️  INFO: Service already running"
else
    echo "⚠️  WARNING: Unexpected service state: $SERVICE_STATE"
fi

# Validate service enabled status
echo ""
echo "6. Service Enable Status:"
ENABLED_STATE=$(systemctl is-enabled docling-mcp.service 2>/dev/null || echo "disabled")
echo "Enabled state: $ENABLED_STATE"

if [ "$ENABLED_STATE" = "disabled" ]; then
    echo "✅ PASSED: Service not enabled yet (expected, will be enabled in Task 152)"
elif [ "$ENABLED_STATE" = "enabled" ]; then
    echo "⚠️  INFO: Service already enabled"
else
    echo "⚠️  WARNING: Unexpected enabled state: $ENABLED_STATE"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - Systemd service unit file ready"
echo ""
echo "Next Step: Task 152 - Enable and Start Systemd Service"
```

**Expected Results:**
- Unit file exists at `/etc/systemd/system/docling-mcp.service`
- Service registered with systemd (appears in `systemctl list-unit-files`)
- No fatal syntax errors from `systemd-analyze verify`
- All required directives present in unit file
- Service state: inactive (not started yet)
- Enabled state: disabled (not enabled for auto-start yet)

## Notes

**Service Account Selection:**
- **Domain account** (docling-mcp@hx.dev.local): Preferred if SSSD configured
- **Local account** (docling-mcp): Fallback if SSSD not available
- Unit file adapts based on Task 004 account configuration

**ExecStartPre Validation:**
- Pre-start checks validate dependencies before service starts
- If Python import fails, service will not start (fail-fast)
- Directory creation ensures cache directories exist
- Ownership correction ensures service account can write to directories

**Auto-Restart Policy:**
- **Restart=on-failure**: Restart only on unclean exit (non-zero exit code, signal, timeout)
- **RestartSec=10s**: Wait 10 seconds before restarting
- **StartLimitBurst=3**: Allow 3 restart attempts
- **StartLimitInterval=300s**: Within 5-minute window
- **Behavior**: After 3 failures in 5 minutes, service enters failed state (no more restarts)

**Resource Limits:**
- **MemoryLimit=4G**: Hard limit, OOM killer terminates process if exceeded
- **CPUQuota=200%**: 2 CPU cores worth of CPU time (200% = 2 cores)
- **TasksMax=1024**: Maximum number of threads/processes

**Logging:**
- **StandardOutput=journal**: stdout goes to systemd journal
- **StandardError=journal**: stderr goes to systemd journal
- **SyslogIdentifier=docling-mcp**: Log entries tagged with "docling-mcp"
- **Access logs**: `journalctl -u docling-mcp.service`

**Troubleshooting:**
- If service fails to start: Check `journalctl -u docling-mcp.service -n 50`
- If permission denied: Verify service account and directory ownership (Task 004)
- If ExecStartPre fails: Check Python dependencies (Task 022)
- If environment variables missing: Check .env.production (Task 008)

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Deployment Architecture - Systemd Service Unit File (lines 4901-4960)
- Section: Service Management (lines 4895-4900)

**Systemd Documentation**:
- Systemd service units: `man systemd.service`
- Systemd execution environment: `man systemd.exec`
- Systemd resource control: `man systemd.resource-control`

## Risk Assessment

**Risk Level**: Low

**Risks**:
1. **Service fails to start**: Python dependencies or environment configuration missing
2. **Permission denied**: Service account lacks permissions to directories
3. **Resource limit too restrictive**: 4GB memory insufficient for workload
4. **Auto-restart loop**: Service crashes immediately, exhausts restart limit

**Mitigation**:
- ExecStartPre validates dependencies before start (fail-fast)
- Pre-execution validation checks prerequisites (Task 008, Task 022)
- Resource limits set generously (4GB memory sufficient per specification)
- Start limit prevents infinite restart loops (3 attempts max)
- Comprehensive logging via journal for troubleshooting
