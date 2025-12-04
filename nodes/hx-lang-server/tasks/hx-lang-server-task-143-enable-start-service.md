# Task 143: Enable and Start Systemd Service

**Task ID**: hx-lang-server-task-143
**Phase**: Deployment (Service Activation)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 141 (Systemd Service Unit), Task 142 (Environment File), All Work Stream Prerequisites
**Estimated Effort**: 30 minutes

---

## Objective

Enable hx-lang-server systemd service for automatic startup on boot and start the service, validating that it runs correctly and passes initial health checks.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 141 (Systemd Service Unit) completed
- [ ] Task 142 (Environment File) completed - with valid POSTGRES_PASSWORD
- [ ] Application code installed (Work Stream 10 - FastAPI)
- [ ] All integration work streams completed (PostgreSQL, Redis, Ollama, LightRAG)

---

## Pre-Execution Validation

**CRITICAL**: Verify all prerequisites before enabling service.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check service status
echo "Checking service prerequisites..."

# Check 1: Unit file exists
if [ -f "/etc/systemd/system/hx-lang-server.service" ]; then
    echo "Unit file: EXISTS"
else
    echo "ERROR: Unit file not found - Task 141 incomplete"
    exit 1
fi

# Check 2: Environment file exists and has valid password
if [ -f "/opt/hx-lang-server/.env" ]; then
    if grep -q "PLACEHOLDER_FROM_VAULT" "/opt/hx-lang-server/.env"; then
        echo "ERROR: POSTGRES_PASSWORD still contains placeholder"
        echo "Task 142 incomplete - update password from Ansible Vault"
        exit 1
    else
        echo "Environment file: CONFIGURED"
    fi
else
    echo "ERROR: Environment file not found - Task 142 incomplete"
    exit 1
fi

# Check 3: Virtual environment exists
if [ -f "/opt/hx-lang-server/venv/bin/uvicorn" ]; then
    echo "Virtual environment: EXISTS"
else
    echo "ERROR: Virtual environment incomplete - Task 013 incomplete"
    exit 1
fi

# Check 4: Application code exists (basic check)
if [ -d "/opt/hx-lang-server/src" ] || [ -d "/opt/hx-lang-server/app" ]; then
    echo "Application code: EXISTS"
else
    echo "WARNING: Application code directory not found"
    echo "Work Stream 10 (FastAPI) may not be complete"
fi

# Check current service status
echo ""
echo "Current service status:"
systemctl status hx-lang-server.service --no-pager 2>/dev/null || echo "Service not started"
```

**If Prerequisites Not Met**: Complete missing tasks first
**If All Prerequisites Met**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Final Pre-Start Validation

```bash
# Perform final validation before starting service
echo "Performing final pre-start validation..."

# Test Python dependencies
echo "Testing Python dependencies..."
/opt/hx-lang-server/venv/bin/python -c "
import fastapi
import uvicorn
import structlog
print('Core dependencies: OK')
"

if [ $? -ne 0 ]; then
    echo "ERROR: Python dependency check failed"
    exit 1
fi

# Test environment file loading
echo "Testing environment file loading..."
/opt/hx-lang-server/venv/bin/python -c "
from dotenv import load_dotenv
import os

load_dotenv('/opt/hx-lang-server/.env')

required = ['SERVICE_NAME', 'SERVICE_PORT', 'POSTGRES_HOST', 'REDIS_URL']
missing = [v for v in required if not os.getenv(v)]

if missing:
    print(f'ERROR: Missing variables: {missing}')
    exit(1)
else:
    print('Environment variables: OK')
"

if [ $? -ne 0 ]; then
    echo "ERROR: Environment file validation failed"
    exit 1
fi

echo "Pre-start validation passed"
```

### Step 2: Enable Service for Auto-Start

```bash
# Enable service for automatic startup on boot
echo "Enabling hx-lang-server service for auto-start..."

sudo systemctl enable hx-lang-server.service

if [ $? -eq 0 ]; then
    echo "Service enabled for auto-start"
else
    echo "ERROR: Failed to enable service"
    exit 1
fi

# Verify enabled status
ENABLED_STATE=$(systemctl is-enabled hx-lang-server.service 2>/dev/null)
echo "Service enabled state: $ENABLED_STATE"
```

### Step 3: Start the Service

```bash
# Start the service
echo "Starting hx-lang-server service..."

sudo systemctl start hx-lang-server.service

# Wait for service to stabilize
echo "Waiting for service to stabilize (10 seconds)..."
sleep 10

# Check service status
SERVICE_STATE=$(systemctl is-active hx-lang-server.service 2>/dev/null)
echo "Service state: $SERVICE_STATE"

if [ "$SERVICE_STATE" = "active" ]; then
    echo "Service started successfully"
else
    echo "WARNING: Service may have failed to start"
    echo "Checking logs for errors..."
    sudo journalctl -u hx-lang-server.service -n 50 --no-pager
fi
```

### Step 4: Verify Service is Running

```bash
# Verify service is running correctly
echo "Verifying service status..."

# Get detailed status
sudo systemctl status hx-lang-server.service --no-pager

# Check process is running
PID=$(systemctl show --property=MainPID --value hx-lang-server.service)
if [ "$PID" != "0" ] && [ -n "$PID" ]; then
    echo "Service PID: $PID"
    ps -p "$PID" -o pid,ppid,user,%cpu,%mem,cmd
else
    echo "WARNING: No PID found for service"
fi

# Check port is listening
echo ""
echo "Checking port 8100..."
if ss -tlnp | grep -q ":8100"; then
    echo "Port 8100: LISTENING"
    ss -tlnp | grep ":8100"
else
    echo "WARNING: Port 8100 not listening"
fi
```

### Step 5: Test Health Endpoint

```bash
# Test health endpoint
echo "Testing health endpoint..."

# Wait a moment for endpoint to be ready
sleep 5

# Test health endpoint
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/health 2>/dev/null || echo "000")

if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "Health endpoint: OK (HTTP 200)"
    echo ""
    echo "Health response:"
    curl -s http://localhost:8100/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8100/health
else
    echo "WARNING: Health endpoint returned HTTP $HEALTH_RESPONSE"
    echo "Service may still be starting or endpoint not yet available"
fi
```

### Step 6: Check Service Logs

```bash
# Check service logs for any issues
echo "Checking service logs..."

echo ""
echo "=== Last 20 log lines ==="
sudo journalctl -u hx-lang-server.service -n 20 --no-pager

echo ""
echo "=== Error logs (if any) ==="
sudo journalctl -u hx-lang-server.service -p err -n 10 --no-pager 2>/dev/null || echo "No error logs found"
```

### Step 7: Document Service Activation

```bash
# Document service activation
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/service-activation-record.txt" > /dev/null <<EOF
# Service Activation Record
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-143

## Service Status
Service Name: hx-lang-server.service
Enabled: $(systemctl is-enabled hx-lang-server.service 2>/dev/null)
Active: $(systemctl is-active hx-lang-server.service 2>/dev/null)
Main PID: $(systemctl show --property=MainPID --value hx-lang-server.service)

## Port Status
$(ss -tlnp | grep ":8100" || echo "Port 8100 not found")

## Health Check
$(curl -s http://localhost:8100/health 2>/dev/null || echo "Health check unavailable")

## Service Management Commands
# Check status
sudo systemctl status hx-lang-server.service

# View logs
sudo journalctl -u hx-lang-server.service -f

# Restart service
sudo systemctl restart hx-lang-server.service

# Stop service
sudo systemctl stop hx-lang-server.service

# Disable auto-start
sudo systemctl disable hx-lang-server.service
EOF

echo "Service activation documented: $DOC_DIR/service-activation-record.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Enabled Service | systemd unit | Service enabled for auto-start |
| Running Service | hx-lang-server.service | Service running on port 8100 |
| Documentation | /opt/hx-lang-server/deployment-docs/service-activation-record.txt | Activation record |

---

## Verification

**Validation Commands:**

```bash
echo "=== Service Activation Validation ==="

VALIDATION_PASSED=true

# Check 1: Service enabled
echo "1. Service Enabled:"
ENABLED=$(systemctl is-enabled hx-lang-server.service 2>/dev/null)
if [ "$ENABLED" = "enabled" ]; then
    echo "PASSED: Service is enabled for auto-start"
else
    echo "FAILED: Service not enabled"
    VALIDATION_PASSED=false
fi

# Check 2: Service active
echo ""
echo "2. Service Active:"
ACTIVE=$(systemctl is-active hx-lang-server.service 2>/dev/null)
if [ "$ACTIVE" = "active" ]; then
    echo "PASSED: Service is running"
else
    echo "FAILED: Service is $ACTIVE"
    VALIDATION_PASSED=false
fi

# Check 3: Port listening
echo ""
echo "3. Port 8100 Listening:"
if ss -tlnp | grep -q ":8100"; then
    echo "PASSED: Port 8100 is listening"
else
    echo "FAILED: Port 8100 not listening"
    VALIDATION_PASSED=false
fi

# Check 4: Health endpoint
echo ""
echo "4. Health Endpoint:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "PASSED: Health endpoint returns 200"
else
    echo "FAILED: Health endpoint returns $HTTP_CODE"
    VALIDATION_PASSED=false
fi

# Check 5: No errors in logs
echo ""
echo "5. Log Errors:"
ERROR_COUNT=$(sudo journalctl -u hx-lang-server.service -p err --since "5 minutes ago" 2>/dev/null | grep -c "." || echo "0")
if [ "$ERROR_COUNT" = "0" ]; then
    echo "PASSED: No errors in recent logs"
else
    echo "WARNING: $ERROR_COUNT error entries in logs"
    sudo journalctl -u hx-lang-server.service -p err --since "5 minutes ago" --no-pager
fi

# Check 6: Process running
echo ""
echo "6. Process Status:"
PID=$(systemctl show --property=MainPID --value hx-lang-server.service)
if [ "$PID" != "0" ] && [ -n "$PID" ]; then
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "PASSED: Process $PID is running"
        ps -p "$PID" -o pid,user,%cpu,%mem,cmd --no-headers
    else
        echo "FAILED: Process $PID not found"
        VALIDATION_PASSED=false
    fi
else
    echo "FAILED: No PID found"
    VALIDATION_PASSED=false
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Service is running and healthy"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    echo ""
    echo "Troubleshooting:"
    echo "  View logs: sudo journalctl -u hx-lang-server.service -f"
    echo "  Check status: sudo systemctl status hx-lang-server.service"
    exit 1
fi
```

**Expected Results:**
- Service enabled for auto-start
- Service state is "active"
- Port 8100 is listening
- Health endpoint returns HTTP 200
- No errors in recent logs
- Process running with valid PID

---

## Rollback Procedure

Stop and disable service if needed:

```bash
# Stop and disable service
echo "Stopping and disabling service..."

# Stop service
sudo systemctl stop hx-lang-server.service

# Disable auto-start
sudo systemctl disable hx-lang-server.service

# Verify
echo "Service state: $(systemctl is-active hx-lang-server.service)"
echo "Service enabled: $(systemctl is-enabled hx-lang-server.service)"

echo "Service stopped and disabled"
```

---

## Notes

**Service Startup Order:**
1. systemd loads unit file
2. ExecStartPre validates dependencies
3. ExecStart launches uvicorn
4. Service reaches "active" state
5. Health endpoint becomes available

**Port Binding:**
- Port 8100: Main API endpoint
- Port 8101: Health/metrics (configured in application)

**Auto-Restart Behavior:**
- Service restarts automatically on failure
- Max 3 restarts in 5-minute window
- After limit, service enters "failed" state

**Health Check Timing:**
- Service may take 5-10 seconds to start
- Health endpoint may not be immediately available
- Allow time for initialization before health checks

**Troubleshooting:**
- View logs: `sudo journalctl -u hx-lang-server.service -f`
- Check status: `sudo systemctl status hx-lang-server.service`
- Check port: `ss -tlnp | grep 8100`
- Test health: `curl http://localhost:8100/health`

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: systemd Service Configuration (lines 816-842)
- Section: Service Management (lines 843-857)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 13: Service Deployment (Task Range 141-150)

---

## Risk Assessment

**Risk Level**: Medium

**Risks:**
1. **Service fails to start**: Missing dependencies or configuration errors
   - Mitigation: Pre-start validation checks all requirements
2. **Port already in use**: Another process using port 8100
   - Mitigation: Check port availability before starting
3. **Resource limits exceeded**: OOM killer terminates service
   - Mitigation: 16GB memory limit provides headroom
4. **Auto-restart loop**: Service keeps crashing and restarting
   - Mitigation: StartLimitBurst=3 limits restarts

**Dependencies Blocked:**
- Task 144+ (Service Validation) requires running service
- Testing and validation require operational service
