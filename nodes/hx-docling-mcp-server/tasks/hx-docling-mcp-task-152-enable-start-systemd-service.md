# Task 152: Enable and Start Systemd Service

**Assigned To**: william-chen
**Estimated Effort**: 0.5 hours
**Dependencies**: Task 151 (Create Systemd Unit), Task 007 (Application Code), Task 008 (Environment Configuration)
**Status**: Not Started

## Objective

Enable Docling MCP Server systemd service for automatic startup on boot and perform initial service start with validation.

## Pre-Execution Validation

**CRITICAL**: Check if service is already enabled and running BEFORE attempting to enable/start.

```bash
# Validation command to check service status
SERVICE_NAME="docling-mcp.service"

echo "Checking systemd service status..."

# Check if service is enabled
ENABLED_STATUS=$(systemctl is-enabled $SERVICE_NAME 2>/dev/null || echo "disabled")
echo "Service enabled status: $ENABLED_STATUS"

# Check if service is active
ACTIVE_STATUS=$(systemctl is-active $SERVICE_NAME 2>/dev/null || echo "inactive")
echo "Service active status: $ACTIVE_STATUS"

if [ "$ENABLED_STATUS" = "enabled" ] && [ "$ACTIVE_STATUS" = "active" ]; then
    echo ""
    echo "✅ VALIDATION RESULT: Service already enabled and running"
    echo "ACTION: SKIP task execution, proceed to validation section"
    echo ""
    echo "Service status:"
    systemctl status $SERVICE_NAME --no-pager
    exit 0
elif [ "$ENABLED_STATUS" = "enabled" ] || [ "$ACTIVE_STATUS" = "active" ]; then
    echo ""
    echo "⚠️  VALIDATION RESULT: Service partially configured (enabled: $ENABLED_STATUS, active: $ACTIVE_STATUS)"
    echo "ACTION: Review current state and proceed with missing steps only"
else
    echo ""
    echo "❌ VALIDATION RESULT: Service not enabled or started"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Partially Complete**: Execute only missing steps (enable OR start)
**If Not Complete**: Continue with Implementation Steps below

---

## Context

After creating the systemd service unit file (Task 151), the service must be:

1. **Enabled**: Configure service to start automatically on system boot
   - Creates symlink in `/etc/systemd/system/multi-user.target.wants/`
   - Service will start when multi-user.target is reached during boot

2. **Started**: Perform initial service startup
   - Executes ExecStartPre validation checks
   - Starts Uvicorn ASGI server with MCP application
   - Validates service reaches active (running) state

This task transitions the service from "unit file created" to "operational service running."

## Acceptance Criteria

- [ ] Service enabled for automatic startup (`systemctl is-enabled` returns "enabled")
- [ ] Service successfully started (`systemctl is-active` returns "active")
- [ ] Service startup logs show no ERROR-level messages
- [ ] ExecStartPre validation checks passed (Python dependencies validated)
- [ ] Uvicorn process running and listening on port 8000
- [ ] Health check endpoint responds within 2 seconds
- [ ] Service status shows "active (running)" state
- [ ] No restart loops detected (service stable for 60 seconds)

## Implementation Steps

### Step 1: Verify Prerequisites

```bash
# Verify all prerequisites before enabling/starting service
echo "Verifying prerequisites for service startup..."

# Check unit file exists
if [ ! -f "/etc/systemd/system/docling-mcp.service" ]; then
    echo "❌ Unit file not found - Task 151 prerequisite not met"
    exit 1
else
    echo "✅ Unit file exists"
fi

# Check application code exists
if [ ! -f "/opt/docling-mcp/src/mcp_server.py" ]; then
    echo "❌ Application code not found - Task 007 prerequisite not met"
    exit 1
else
    echo "✅ Application code exists"
fi

# Check environment configuration exists
if [ ! -f "/etc/docling-mcp/.env.production" ]; then
    echo "❌ Environment configuration not found - Task 008 prerequisite not met"
    exit 1
else
    echo "✅ Environment configuration exists"
fi

# Check Python dependencies
if ! /opt/docling-mcp/venv/bin/python -c "import docling, fastmcp, uvicorn" 2>/dev/null; then
    echo "❌ Python dependencies not installed - Task 022 prerequisite not met"
    exit 1
else
    echo "✅ Python dependencies validated"
fi

echo "All prerequisites met, proceeding with service enablement"
```

### Step 2: Enable Service for Auto-Start

```bash
# Enable service for automatic startup on boot
SERVICE_NAME="docling-mcp.service"

echo "Enabling service for automatic startup..."

sudo systemctl enable $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Service enabled successfully"

    # Verify enabled status
    ENABLED_STATUS=$(systemctl is-enabled $SERVICE_NAME)
    echo "Enabled status: $ENABLED_STATUS"

    # Verify symlink created
    if [ -L "/etc/systemd/system/multi-user.target.wants/$SERVICE_NAME" ]; then
        echo "✅ Symlink created in multi-user.target.wants"
        ls -l "/etc/systemd/system/multi-user.target.wants/$SERVICE_NAME"
    else
        echo "⚠️  WARNING: Symlink not found, service may not auto-start on boot"
    fi
else
    echo "❌ Failed to enable service"
    exit 1
fi
```

### Step 3: Start Service

```bash
# Start service for the first time
SERVICE_NAME="docling-mcp.service"

echo "Starting service..."

sudo systemctl start $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Service start command issued successfully"
else
    echo "❌ Service start command failed"
    echo "Checking service status for error details..."
    sudo systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

# Wait for service to stabilize (5 seconds)
echo "Waiting for service to stabilize (5 seconds)..."
sleep 5
```

### Step 4: Verify Service Active State

```bash
# Verify service reached active (running) state
SERVICE_NAME="docling-mcp.service"

echo "Verifying service active state..."

ACTIVE_STATUS=$(systemctl is-active $SERVICE_NAME)

if [ "$ACTIVE_STATUS" = "active" ]; then
    echo "✅ Service is active (running)"
else
    echo "❌ Service is not active, current state: $ACTIVE_STATUS"
    echo ""
    echo "Service status:"
    sudo systemctl status $SERVICE_NAME --no-pager
    echo ""
    echo "Recent logs:"
    sudo journalctl -u $SERVICE_NAME -n 50 --no-pager
    exit 1
fi

# Display service status
echo ""
echo "Service status:"
sudo systemctl status $SERVICE_NAME --no-pager
```

### Step 5: Validate Service Logs

```bash
# Check service logs for errors
SERVICE_NAME="docling-mcp.service"

echo ""
echo "Checking service logs for errors..."

# Check for ERROR-level log messages
ERROR_COUNT=$(sudo journalctl -u $SERVICE_NAME --since "5 minutes ago" -p err --no-pager | wc -l)

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ No ERROR-level log messages detected"
else
    echo "❌ ERROR-level log messages detected: $ERROR_COUNT"
    echo ""
    echo "Error logs:"
    sudo journalctl -u $SERVICE_NAME --since "5 minutes ago" -p err --no-pager
    exit 1
fi

# Display recent INFO-level logs
echo ""
echo "Recent service logs (last 20 lines):"
sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
```

### Step 6: Verify Service Listening on Port 8000

```bash
# Verify Uvicorn listening on port 8000
echo ""
echo "Verifying service listening on port 8000..."

# Check if port 8000 is listening
if ss -tlnp | grep -q ':8000'; then
    echo "✅ Service listening on port 8000"
    ss -tlnp | grep ':8000'
else
    echo "❌ Service not listening on port 8000"
    echo "Checking all listening ports:"
    ss -tlnp | grep python
    exit 1
fi
```

### Step 7: Test Health Check Endpoint

```bash
# Test health check endpoint
echo ""
echo "Testing health check endpoint..."

HEALTH_URL="http://hx-docling-mcp-server.hx.dev.local:8000/health"

# Wait for service to be fully ready (up to 10 seconds)
MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s -f -m 2 "$HEALTH_URL" > /dev/null 2>&1; then
        echo "✅ Health check endpoint responding"
        break
    else
        ATTEMPT=$((ATTEMPT + 1))
        echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Health check not ready, waiting..."
        sleep 1
    fi
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "❌ Health check endpoint failed to respond after $MAX_ATTEMPTS attempts"
    echo "Service may still be initializing or has errors"
    exit 1
fi

# Get health check response
HEALTH_RESPONSE=$(curl -s -m 2 "$HEALTH_URL")
echo ""
echo "Health check response:"
echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
```

### Step 8: Verify Service Stability

```bash
# Verify service remains stable (no restart loops)
SERVICE_NAME="docling-mcp.service"

echo ""
echo "Verifying service stability (60 seconds)..."

INITIAL_STATE=$(systemctl is-active $SERVICE_NAME)
echo "Initial state: $INITIAL_STATE"

sleep 60

FINAL_STATE=$(systemctl is-active $SERVICE_NAME)
echo "State after 60 seconds: $FINAL_STATE"

if [ "$FINAL_STATE" = "active" ]; then
    echo "✅ Service remained stable for 60 seconds"
else
    echo "❌ Service state changed or failed during stability check"
    echo ""
    echo "Service status:"
    sudo systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

# Check for restarts
RESTART_COUNT=$(sudo journalctl -u $SERVICE_NAME --since "2 minutes ago" | grep -c "Started Docling MCP Server" || echo 0)

if [ "$RESTART_COUNT" -le 1 ]; then
    echo "✅ No unexpected restarts detected"
else
    echo "⚠️  WARNING: Multiple starts detected ($RESTART_COUNT), service may be restarting"
fi
```

## Validation

**Validation Commands:**

```bash
echo "=== Systemd Service Enable/Start Validation ==="

SERVICE_NAME="docling-mcp.service"

# Validate service enabled
echo "1. Service Enabled Status:"
ENABLED_STATUS=$(systemctl is-enabled $SERVICE_NAME 2>/dev/null)

if [ "$ENABLED_STATUS" = "enabled" ]; then
    echo "✅ PASSED: Service enabled for auto-start"
else
    echo "❌ FAILED: Service not enabled (status: $ENABLED_STATUS)"
    exit 1
fi

# Validate service active
echo ""
echo "2. Service Active Status:"
ACTIVE_STATUS=$(systemctl is-active $SERVICE_NAME 2>/dev/null)

if [ "$ACTIVE_STATUS" = "active" ]; then
    echo "✅ PASSED: Service is active (running)"
else
    echo "❌ FAILED: Service not active (status: $ACTIVE_STATUS)"
    exit 1
fi

# Validate service listening on port
echo ""
echo "3. Port Listening:"
if ss -tlnp | grep -q ':8000'; then
    echo "✅ PASSED: Service listening on port 8000"
else
    echo "❌ FAILED: Service not listening on port 8000"
    exit 1
fi

# Validate health check endpoint
echo ""
echo "4. Health Check Endpoint:"
HEALTH_URL="http://hx-docling-mcp-server.hx.dev.local:8000/health"
HEALTH_RESPONSE=$(curl -s -f -m 2 "$HEALTH_URL" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ PASSED: Health check endpoint responding"
    echo "Health status: $(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))")"
else
    echo "❌ FAILED: Health check endpoint not responding"
    exit 1
fi

# Validate no ERROR logs
echo ""
echo "5. Service Logs:"
ERROR_COUNT=$(sudo journalctl -u $SERVICE_NAME --since "5 minutes ago" -p err --no-pager 2>/dev/null | wc -l)

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ PASSED: No ERROR-level log messages"
else
    echo "❌ FAILED: ERROR-level log messages detected: $ERROR_COUNT"
    sudo journalctl -u $SERVICE_NAME --since "5 minutes ago" -p err --no-pager
    exit 1
fi

# Validate service uptime
echo ""
echo "6. Service Uptime:"
UPTIME=$(systemctl show $SERVICE_NAME --property=ActiveEnterTimestamp --value)
echo "Service started: $UPTIME"

if [ -n "$UPTIME" ] && [ "$UPTIME" != "Thu 1970-01-01 00:00:00 UTC" ]; then
    echo "✅ PASSED: Service has valid uptime"
else
    echo "⚠️  WARNING: Service uptime invalid or unknown"
fi

# Display final service status
echo ""
echo "7. Final Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - Service enabled, running, and operational"
echo ""
echo "Next Step: Task 161 - Configure Logging"
```

**Expected Results:**
- Enabled status: "enabled"
- Active status: "active"
- Port 8000 listening (ss shows LISTEN state)
- Health check returns HTTP 200 with status: "healthy"
- No ERROR-level logs in last 5 minutes
- Service uptime shows recent timestamp
- Service status shows "active (running)" with process details

## Notes

**Service Management Commands:**
```bash
# Check service status
sudo systemctl status docling-mcp.service

# View service logs (real-time)
sudo journalctl -u docling-mcp.service -f

# View last 100 log lines
sudo journalctl -u docling-mcp.service -n 100

# Restart service
sudo systemctl restart docling-mcp.service

# Stop service
sudo systemctl stop docling-mcp.service

# Disable auto-start
sudo systemctl disable docling-mcp.service
```

**Auto-Restart Behavior:**
- Service configured with `Restart=on-failure` in unit file
- If service crashes (non-zero exit, signal, timeout), systemd automatically restarts
- Restart limit: 3 attempts in 5 minutes
- After limit exceeded, service enters failed state (manual intervention required)

**Health Check Endpoint:**
- URL: `http://hx-docling-mcp-server.hx.dev.local:8000/health`
- Response includes service status and dependency health
- Should respond within 2 seconds
- Used for external monitoring and validation

**Service Startup Sequence:**
1. Systemd executes ExecStartPre validation (Python dependencies check)
2. Systemd creates cache directories and sets ownership
3. Systemd starts Uvicorn ASGI server with MCP application
4. Uvicorn loads application code and binds to port 8000
5. MCP server initializes (loads tools, configures integrations)
6. Health check endpoint becomes available
7. Service reaches "active (running)" state

**Troubleshooting:**
- If service fails to start: Check `journalctl -u docling-mcp.service -n 50`
- If health check fails: Verify environment variables in .env.production
- If port not listening: Check for port conflicts (`ss -tlnp | grep 8000`)
- If ExecStartPre fails: Verify Python dependencies installed (Task 022)
- If restart loop: Check for application errors in logs

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Deployment Architecture - Phase 5: Service Startup and Validation (lines 5032-5039)
- Section: Health Checks (lines 1668-1692)

**Systemd Documentation**:
- Systemd service control: `man systemctl`
- Service logs: `man journalctl`

## Risk Assessment

**Risk Level**: Medium

**Risks**:
1. **Service fails to start**: Application code errors, dependency failures
2. **Port conflict**: Another service using port 8000
3. **Health check timeout**: Dependencies (LiteLLM, Qdrant, Redis) unavailable
4. **Restart loop**: Service crashes immediately after start

**Mitigation**:
- ExecStartPre validates dependencies before start (fail-fast)
- Pre-execution validation checks prerequisites
- Health check validation ensures service fully operational
- Stability check (60 seconds) detects immediate failures
- Comprehensive logging for troubleshooting
- Auto-restart limited to prevent infinite loops
