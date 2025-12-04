# Task 141: Create Systemd Service Unit File

**Task ID**: hx-lang-server-task-141
**Phase**: Deployment (Service Configuration)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 013 (Virtual Environment), Task 131 (Logging), Task 101+ (FastAPI Application)
**Estimated Effort**: 1.5 hours

---

## Objective

Create production-grade systemd service unit file for hx-lang-server with automatic restart policies, resource limits (16GB memory per spec), proper service dependencies, and systemd journal integration.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 013 (Virtual Environment) completed - /opt/hx-lang-server/venv exists
- [ ] Service account hx-lang-server exists (Task 001)
- [ ] Application code installed (Work Stream 10 - FastAPI)
- [ ] Environment file created (Task 142 dependency - create minimal .env first)

---

## Pre-Execution Validation

**CRITICAL**: Check if systemd service unit file already exists BEFORE creating.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check systemd unit file status
UNIT_FILE="/etc/systemd/system/hx-lang-server.service"

echo "Checking systemd service unit file status..."

if [ -f "$UNIT_FILE" ]; then
    echo "Systemd unit file exists: $UNIT_FILE"
    echo ""
    echo "Current unit file content:"
    cat "$UNIT_FILE"
    echo ""
    echo "Checking if service is registered with systemd..."
    if systemctl list-unit-files | grep -q "hx-lang-server.service"; then
        echo "Service registered with systemd"
        systemctl status hx-lang-server.service --no-pager || true
    else
        echo "Service file exists but not registered, may need daemon-reload"
    fi
    echo ""
    echo "VALIDATION RESULT: Systemd service unit already configured"
    echo "ACTION: Review existing unit file, skip if correct"
else
    echo "VALIDATION RESULT: Systemd unit file does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Exists**: Review existing unit file, skip if correct
**If Not Exists**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Determine Service Account Type

```bash
# Determine if using domain account or local account
echo "Determining service account configuration..."

if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
    SERVICE_GROUP="domain users@hx.dev.local"
    ACCOUNT_TYPE="domain"
    echo "Using Samba AD domain account: $SERVICE_USER"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
    SERVICE_GROUP="hx-lang-server"
    ACCOUNT_TYPE="local"
    echo "Using local system account: $SERVICE_USER"
else
    echo "ERROR: Service account not found (neither domain nor local)"
    echo "Prerequisite: Task 001 must be complete"
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
if [ ! -f "/opt/hx-lang-server/venv/bin/uvicorn" ]; then
    echo "ERROR: Uvicorn not found in venv - Task 013/015 prerequisite not met"
    echo "Path: /opt/hx-lang-server/venv/bin/uvicorn"
    exit 1
else
    echo "Uvicorn available in venv"
fi

# Check working directory exists
if [ ! -d "/opt/hx-lang-server" ]; then
    echo "ERROR: Working directory not found - Task 003 prerequisite not met"
    exit 1
else
    echo "Working directory exists"
fi

# Check if .env file exists (or will be created in Task 142)
if [ ! -f "/opt/hx-lang-server/.env" ]; then
    echo "WARNING: .env file not found - will be created in Task 142"
    echo "Creating placeholder .env file..."
    sudo touch /opt/hx-lang-server/.env
    sudo chown hx-lang-server /opt/hx-lang-server/.env 2>/dev/null || true
else
    echo "Environment file exists"
fi
```

### Step 3: Create Systemd Unit File

```bash
# Create systemd service unit file
UNIT_FILE="/etc/systemd/system/hx-lang-server.service"

echo "Creating systemd service unit file: $UNIT_FILE"

# Determine User and Group directives based on account type
if [ "$ACCOUNT_TYPE" = "domain" ]; then
    USER_DIRECTIVE="User=hx-lang-server@hx.dev.local"
    GROUP_DIRECTIVE="Group=domain users@hx.dev.local"
else
    USER_DIRECTIVE="User=hx-lang-server"
    GROUP_DIRECTIVE="Group=hx-lang-server"
fi

sudo tee "$UNIT_FILE" > /dev/null <<EOF
[Unit]
Description=HX LangGraph Orchestration Server
Documentation=file:///opt/hx-lang-server/README.md
After=network-online.target postgresql.service redis.service
Wants=network-online.target

[Service]
Type=exec
$USER_DIRECTIVE
$GROUP_DIRECTIVE
WorkingDirectory=/opt/hx-lang-server
Environment="PATH=/opt/hx-lang-server/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EnvironmentFile=/opt/hx-lang-server/.env

# Pre-start validation
ExecStartPre=/opt/hx-lang-server/venv/bin/python -c "import fastapi, uvicorn; print('Core dependencies validated')"

# Main service execution
# Port 8100 for API, 8101 for health/metrics (per spec)
ExecStart=/opt/hx-lang-server/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8100 --log-level info --workers 1

# Graceful shutdown
ExecStop=/bin/kill -TERM \$MAINPID
TimeoutStopSec=30

# Automatic restart policy
Restart=on-failure
RestartSec=10
StartLimitIntervalSec=300
StartLimitBurst=3

# Resource limits - 16GB memory per spec (William Chen infrastructure review)
MemoryMax=16G
MemoryHigh=14G
CPUQuota=400%
TasksMax=2048
LimitNOFILE=65536

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
ReadWritePaths=/opt/hx-lang-server /var/log/hx-lang-server /var/cache/hx-lang-server

# Logging to systemd journal
StandardOutput=journal
StandardError=journal
SyslogIdentifier=hx-lang-server

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd unit file created successfully"
```

### Step 4: Validate Unit File Syntax

```bash
# Validate systemd unit file syntax
UNIT_FILE="/etc/systemd/system/hx-lang-server.service"

echo "Validating systemd unit file syntax..."

# Use systemd-analyze to check for syntax errors
sudo systemd-analyze verify "$UNIT_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "Unit file syntax validation passed"
else
    echo "WARNING: systemd-analyze reported issues, review output above"
    echo "Some warnings may be acceptable depending on systemd version"
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
    echo "Systemd daemon reloaded successfully"
else
    echo "ERROR: Systemd daemon reload failed"
    exit 1
fi

# Verify service is recognized by systemd
if systemctl list-unit-files | grep -q "hx-lang-server.service"; then
    echo "Service registered with systemd"
else
    echo "ERROR: Service not registered, unit file may have errors"
    exit 1
fi
```

### Step 6: Create Cache Directory

```bash
# Create cache directory referenced in unit file
CACHE_DIR="/var/cache/hx-lang-server"

echo "Creating cache directory..."

sudo mkdir -p "$CACHE_DIR"
sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$CACHE_DIR" 2>/dev/null || \
    sudo chown "$SERVICE_USER" "$CACHE_DIR" 2>/dev/null || true
sudo chmod 750 "$CACHE_DIR"

echo "Cache directory created: $CACHE_DIR"
ls -la "$CACHE_DIR"
```

### Step 7: Document Systemd Configuration

```bash
# Document systemd configuration
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/systemd-service-configuration.txt" > /dev/null <<EOF
# Systemd Service Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-141

## Service Unit File
Location: /etc/systemd/system/hx-lang-server.service

## Service Account
User: $SERVICE_USER
Group: $SERVICE_GROUP
Account Type: $ACCOUNT_TYPE

## Ports
API Port: 8100
Health/Metrics Port: 8101 (configured in application)

## Resource Limits
Memory Max: 16GB (per spec - William Chen infrastructure review)
Memory High: 14GB (soft limit, triggers memory pressure)
CPU Quota: 400% (4 cores)
Tasks Max: 2048
File Descriptors: 65536

## Auto-Restart Policy
Restart on: failure
Restart delay: 10 seconds
Restart limit: 3 attempts in 5 minutes

## Security Hardening
- NoNewPrivileges: yes
- ProtectSystem: strict
- ProtectHome: yes
- PrivateTmp: yes
- ReadWritePaths: /opt/hx-lang-server, /var/log/hx-lang-server, /var/cache/hx-lang-server

## Service Management Commands

# Start service
sudo systemctl start hx-lang-server.service

# Stop service
sudo systemctl stop hx-lang-server.service

# Restart service
sudo systemctl restart hx-lang-server.service

# Check service status
sudo systemctl status hx-lang-server.service

# View service logs
sudo journalctl -u hx-lang-server.service -f

# Enable service for auto-start
sudo systemctl enable hx-lang-server.service

# Disable service auto-start
sudo systemctl disable hx-lang-server.service

## Unit File Content
$(cat /etc/systemd/system/hx-lang-server.service)
EOF

echo "Systemd configuration documented: $DOC_DIR/systemd-service-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Service Unit | /etc/systemd/system/hx-lang-server.service | Systemd service definition |
| Cache Directory | /var/cache/hx-lang-server | Service cache directory |
| Documentation | /opt/hx-lang-server/deployment-docs/systemd-service-configuration.txt | Configuration guide |

---

## Verification

**Validation Commands:**

```bash
echo "=== Systemd Service Unit File Validation ==="

UNIT_FILE="/etc/systemd/system/hx-lang-server.service"
VALIDATION_PASSED=true

# Check 1: Unit file exists
echo "1. Unit File Existence:"
if [ -f "$UNIT_FILE" ]; then
    echo "PASSED: Unit file exists at $UNIT_FILE"
else
    echo "FAILED: Unit file not found"
    VALIDATION_PASSED=false
fi

# Check 2: Service registered with systemd
echo ""
echo "2. Systemd Registration:"
if systemctl list-unit-files | grep -q "hx-lang-server.service"; then
    echo "PASSED: Service registered with systemd"
else
    echo "FAILED: Service not registered"
    VALIDATION_PASSED=false
fi

# Check 3: Critical directives present
echo ""
echo "3. Critical Directives:"
REQUIRED_DIRECTIVES=(
    "ExecStart=/opt/hx-lang-server/venv/bin/uvicorn"
    "EnvironmentFile=/opt/hx-lang-server/.env"
    "Restart=on-failure"
    "MemoryMax=16G"
    "StandardOutput=journal"
    "WantedBy=multi-user.target"
)

for directive in "${REQUIRED_DIRECTIVES[@]}"; do
    if grep -q "$directive" "$UNIT_FILE"; then
        echo "PASSED: $directive present"
    else
        echo "FAILED: $directive missing"
        VALIDATION_PASSED=false
    fi
done

# Check 4: Port configuration
echo ""
echo "4. Port Configuration:"
if grep -q "port 8100" "$UNIT_FILE"; then
    echo "PASSED: API port 8100 configured"
else
    echo "FAILED: API port 8100 not found"
    VALIDATION_PASSED=false
fi

# Check 5: Memory limit
echo ""
echo "5. Memory Limit (16GB per spec):"
if grep -q "MemoryMax=16G" "$UNIT_FILE"; then
    echo "PASSED: MemoryMax=16G configured"
else
    echo "FAILED: Memory limit not set to 16G"
    VALIDATION_PASSED=false
fi

# Check 6: Service status (should be inactive)
echo ""
echo "6. Service Status:"
SERVICE_STATE=$(systemctl is-active hx-lang-server.service 2>/dev/null || echo "inactive")
if [ "$SERVICE_STATE" = "inactive" ]; then
    echo "PASSED: Service not started yet (expected)"
elif [ "$SERVICE_STATE" = "active" ]; then
    echo "INFO: Service already running"
else
    echo "INFO: Service state: $SERVICE_STATE"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Systemd service unit ready"
    echo ""
    echo "Next Step: Task 142 - Configure Environment File"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- Unit file exists at /etc/systemd/system/hx-lang-server.service
- Service registered with systemd
- All critical directives present
- Port 8100 configured
- MemoryMax=16G configured (per spec)
- Service state: inactive (not started yet)

---

## Rollback Procedure

Remove systemd service unit if needed:

```bash
# Remove systemd service unit
echo "Removing systemd service unit..."

# Stop service if running
sudo systemctl stop hx-lang-server.service 2>/dev/null || true

# Disable service
sudo systemctl disable hx-lang-server.service 2>/dev/null || true

# Remove unit file
sudo rm -f /etc/systemd/system/hx-lang-server.service

# Reload systemd daemon
sudo systemctl daemon-reload

# Remove cache directory
sudo rm -rf /var/cache/hx-lang-server

echo "Systemd service unit removed"

# Verify removal
if systemctl list-unit-files | grep -q "hx-lang-server.service"; then
    echo "WARNING: Service still registered"
else
    echo "Service successfully removed"
fi
```

---

## Notes

**Service Type:**
- Type=exec: Modern replacement for Type=simple
- Service ready when ExecStart process starts
- Proper exit code handling

**Memory Limits:**
- MemoryMax=16G: Hard limit per specification (William Chen review)
- MemoryHigh=14G: Soft limit triggers memory pressure reclaim
- LangGraph with concurrent sessions requires significant memory

**Port Allocation:**
- Port 8100: FastAPI HTTP API (primary)
- Port 8101: Health/Metrics endpoint (configured in application)

**Auto-Restart Policy:**
- Restart=on-failure: Only restart on unclean exit
- RestartSec=10: 10-second delay between restarts
- StartLimitBurst=3: Max 3 restarts in 5-minute window

**Security Hardening:**
- NoNewPrivileges: Prevents privilege escalation
- ProtectSystem=strict: Filesystem read-only except allowed paths
- PrivateTmp: Isolated /tmp namespace

**Startup Dependencies:**
- network-online.target: Network must be available
- postgresql.service: Database must be available (if local)
- redis.service: Cache must be available (if local)

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: systemd Service Configuration (lines 816-842)
- Section: Node Requirements - Memory (lines 128-129): 16GB minimum

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 13: Service Deployment (Task Range 141-150)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Service fails to start**: Dependencies missing or misconfigured
   - Mitigation: ExecStartPre validates dependencies
2. **Memory limit too restrictive**: OOM kills service under load
   - Mitigation: 16GB limit per spec, MemoryHigh provides warning
3. **Security hardening blocks access**: ProtectSystem prevents writes
   - Mitigation: ReadWritePaths explicitly allows needed directories

**Dependencies Blocked:**
- Task 142 (Environment File) completes service configuration
- Task 143 (Service Enablement) starts and enables service
