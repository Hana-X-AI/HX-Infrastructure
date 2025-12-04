# Task 191: Validate Health Checks and Service Status

**Assigned To**: william-chen
**Estimated Effort**: 1 hour
**Dependencies**: Task 152 (Service Started), Task 161 (Logging Configured)
**Status**: Not Started

## Objective

Validate Docling MCP Server health check endpoint responds correctly with dependency status, verify service stability, and confirm operational readiness for integration testing.

## Pre-Execution Validation

**CRITICAL**: Check if service is already operational and health check passing BEFORE running validation.

```bash
# Validation command to check service health status
echo "Checking service operational status..."

# Check service active
if ! systemctl is-active docling-mcp.service > /dev/null 2>&1; then
    echo "❌ Service not running - Task 152 prerequisite not met"
    exit 1
fi

# Check health endpoint
HEALTH_URL="http://hx-docling-mcp-server.hx.dev.local:8000/health"
HEALTH_RESPONSE=$(curl -s -f -m 2 "$HEALTH_URL" 2>/dev/null)

if [ $? -eq 0 ]; then
    HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)

    echo "✅ Health check endpoint responding"
    echo "Health status: $HEALTH_STATUS"

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo ""
        echo "✅ VALIDATION RESULT: Service operational with healthy status"
        echo "ACTION: SKIP task execution if validation comprehensive, or proceed for detailed checks"
        echo ""
        echo "Health response:"
        echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null
        exit 0
    else
        echo "⚠️  Health status not optimal: $HEALTH_STATUS"
        echo "ACTION: PROCEED with validation to diagnose issues"
    fi
else
    echo "❌ VALIDATION RESULT: Health check endpoint not responding"
    echo "ACTION: PROCEED with validation to diagnose service issues"
fi
```

**If Already Complete**: Service healthy, skip if satisfied with status
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Post-deployment validation ensures the Docling MCP Server is:

1. **Running**: Systemd service in active (running) state
2. **Responding**: Health check endpoint returns HTTP 200
3. **Healthy**: All dependencies accessible (LiteLLM, Qdrant, Redis, hx-literag-server)
4. **Stable**: No crashes or restart loops in first hour
5. **Logging**: Structured logs flowing to systemd journal

**Health Check Endpoint:** `http://hx-docling-mcp-server.hx.dev.local:8000/health`

**Expected Response:**
```json
{
  "status": "healthy",  // healthy | degraded | unhealthy
  "version": "1.0.0",
  "dependencies": {
    "litellm": {"status": "healthy", "latency_ms": 50},
    "qdrant": {"status": "healthy", "latency_ms": 20},
    "redis": {"status": "healthy", "latency_ms": 10},
    "literag": {"status": "healthy", "latency_ms": 30}
  },
  "uptime_seconds": 300
}
```

This task validates operational readiness before integration testing (Task 192).

## Acceptance Criteria

- [ ] Service running for at least 60 seconds without restart
- [ ] Health check endpoint returns HTTP 200 status code
- [ ] Health check response contains `status: "healthy"` or `status: "degraded"`
- [ ] Response time <2 seconds (specification requirement)
- [ ] All critical dependencies report status (LiteLLM, Qdrant, Redis, hx-literag-server)
- [ ] No ERROR-level logs in service logs (last 10 minutes)
- [ ] Service listening on port 8000
- [ ] DNS resolution working (hx-docling-mcp-server.hx.dev.local resolves)
- [ ] No systemd restart failures in last hour

## Implementation Steps

### Step 1: Verify Service Active Status

```bash
# Verify service is running and active
SERVICE_NAME="docling-mcp.service"

echo "=== Step 1: Service Status Validation ==="

# Check service active
ACTIVE_STATUS=$(systemctl is-active $SERVICE_NAME 2>/dev/null)

if [ "$ACTIVE_STATUS" = "active" ]; then
    echo "✅ Service is active (running)"
else
    echo "❌ Service is not active, current state: $ACTIVE_STATUS"
    sudo systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

# Check service enabled
ENABLED_STATUS=$(systemctl is-enabled $SERVICE_NAME 2>/dev/null)
echo "Service enabled for auto-start: $ENABLED_STATUS"

# Get service uptime
UPTIME_SEC=$(systemctl show $SERVICE_NAME --property=ActiveEnterTimestampMonotonic --value)
UPTIME_CURRENT=$(systemctl show $SERVICE_NAME --property=MonotonicTimestampMonotonic --value 2>/dev/null || echo "0")

if [ -n "$UPTIME_SEC" ] && [ -n "$UPTIME_CURRENT" ] && [ "$UPTIME_SEC" != "0" ] && [ "$UPTIME_CURRENT" != "0" ]; then
    UPTIME=$((($UPTIME_CURRENT - $UPTIME_SEC) / 1000000))  # Convert microseconds to seconds
    echo "Service uptime: ${UPTIME} seconds"

    if [ "$UPTIME" -ge 60 ]; then
        echo "✅ Service stable for 60+ seconds"
    else
        echo "⚠️  Service uptime < 60 seconds, may still be initializing"
        echo "Waiting for stabilization..."
        sleep $((60 - UPTIME))
    fi
else
    echo "⚠️  Cannot determine uptime, checking service logs..."
fi

# Display service status
echo ""
echo "Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager
```

### Step 2: Verify DNS Resolution

```bash
# Verify DNS resolution for service hostname
echo ""
echo "=== Step 2: DNS Resolution Validation ==="

HOSTNAME="hx-docling-mcp-server.hx.dev.local"

# Resolve hostname
IP_ADDRESS=$(dig +short $HOSTNAME | tail -n1)

if [ -n "$IP_ADDRESS" ]; then
    echo "✅ DNS resolution successful"
    echo "Hostname: $HOSTNAME"
    echo "IP Address: $IP_ADDRESS"
else
    echo "❌ DNS resolution failed for $HOSTNAME"
    echo "Attempting with getent..."
    IP_ADDRESS=$(getent hosts $HOSTNAME | awk '{print $1}')

    if [ -n "$IP_ADDRESS" ]; then
        echo "✅ DNS resolution via getent successful: $IP_ADDRESS"
    else
        echo "❌ DNS resolution failed via all methods"
        exit 1
    fi
fi
```

### Step 3: Verify Port Listening

```bash
# Verify service listening on port 8000
echo ""
echo "=== Step 3: Port Listening Validation ==="

if ss -tlnp | grep -q ':8000'; then
    echo "✅ Service listening on port 8000"
    echo ""
    ss -tlnp | grep ':8000'
else
    echo "❌ Service not listening on port 8000"
    echo "All listening ports:"
    ss -tlnp
    exit 1
fi
```

### Step 4: Test Health Check Endpoint

```bash
# Test health check endpoint multiple times
echo ""
echo "=== Step 4: Health Check Endpoint Validation ==="

HEALTH_URL="http://hx-docling-mcp-server.hx.dev.local:8000/health"
SUCCESSFUL_CHECKS=0
TOTAL_CHECKS=5
MAX_RESPONSE_TIME=2000  # 2 seconds in milliseconds

echo "Testing health check endpoint ($TOTAL_CHECKS attempts)..."

for i in $(seq 1 $TOTAL_CHECKS); do
    echo ""
    echo "Attempt $i/$TOTAL_CHECKS:"

    # Measure response time
    START_TIME=$(date +%s%3N)  # Milliseconds
    HEALTH_RESPONSE=$(curl -s -f -m 3 -w "\nHTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}" "$HEALTH_URL" 2>/dev/null)
    END_TIME=$(date +%s%3N)

    # Extract HTTP code and response time
    HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    RESPONSE_TIME=$(echo "$HEALTH_RESPONSE" | grep "TIME_TOTAL:" | cut -d: -f2)
    RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc | cut -d. -f1)

    # Extract JSON response
    JSON_RESPONSE=$(echo "$HEALTH_RESPONSE" | sed '/HTTP_CODE:/d; /TIME_TOTAL:/d')

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ HTTP 200 OK"
        echo "Response time: ${RESPONSE_TIME_MS}ms"

        # Check response time within limit
        if [ "$RESPONSE_TIME_MS" -le "$MAX_RESPONSE_TIME" ]; then
            echo "✅ Response time within 2 second limit"
        else
            echo "⚠️  Response time exceeds 2 second limit"
        fi

        # Parse health status
        if echo "$JSON_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
            echo "✅ Valid JSON response"
            HEALTH_STATUS=$(echo "$JSON_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)
            echo "Health status: $HEALTH_STATUS"

            if [ "$HEALTH_STATUS" = "healthy" ] || [ "$HEALTH_STATUS" = "degraded" ]; then
                SUCCESSFUL_CHECKS=$((SUCCESSFUL_CHECKS + 1))
                echo "✅ Check passed"
            else
                echo "⚠️  Unhealthy status: $HEALTH_STATUS"
            fi

            # Display full response
            echo ""
            echo "Health response:"
            echo "$JSON_RESPONSE" | python3 -m json.tool 2>/dev/null
        else
            echo "⚠️  Invalid JSON response"
            echo "$JSON_RESPONSE"
        fi
    else
        echo "❌ HTTP $HTTP_CODE (expected 200)"
        echo "Response: $JSON_RESPONSE"
    fi

    # Wait between checks
    if [ "$i" -lt "$TOTAL_CHECKS" ]; then
        sleep 2
    fi
done

echo ""
echo "Health check summary: $SUCCESSFUL_CHECKS/$TOTAL_CHECKS successful"

if [ "$SUCCESSFUL_CHECKS" -ge 4 ]; then
    echo "✅ Health check validation passed (80%+ success rate)"
else
    echo "❌ Health check validation failed (< 80% success rate)"
    exit 1
fi
```

### Step 5: Validate Dependency Health

```bash
# Parse dependency health from latest health check
echo ""
echo "=== Step 5: Dependency Health Validation ==="

HEALTH_URL="http://hx-docling-mcp-server.hx.dev.local:8000/health"
HEALTH_RESPONSE=$(curl -s -f -m 2 "$HEALTH_URL" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "Dependency health status:"
    echo "$HEALTH_RESPONSE" | python3 <<'EOF'
import sys
import json

try:
    health = json.load(sys.stdin)
    dependencies = health.get('dependencies', {})

    critical_deps = ['litellm', 'qdrant', 'redis', 'literag']
    all_healthy = True

    for dep in critical_deps:
        if dep in dependencies:
            dep_status = dependencies[dep].get('status', 'unknown')
            latency = dependencies[dep].get('latency_ms', 'N/A')
            print(f"  {dep}: {dep_status} (latency: {latency}ms)")

            if dep_status not in ['healthy', 'degraded']:
                all_healthy = False
        else:
            print(f"  {dep}: NOT REPORTED")
            all_healthy = False

    if all_healthy:
        print("\n✅ All critical dependencies accessible")
    else:
        print("\n⚠️  Some dependencies unavailable or degraded")

except Exception as e:
    print(f"❌ Failed to parse dependency health: {e}")
    sys.exit(1)
EOF
else
    echo "❌ Cannot retrieve dependency health (endpoint not responding)"
    exit 1
fi
```

### Step 6: Check Service Logs for Errors

```bash
# Check for ERROR-level logs in last 10 minutes
echo ""
echo "=== Step 6: Service Log Validation ==="

SERVICE_NAME="docling-mcp.service"

ERROR_COUNT=$(sudo journalctl -u $SERVICE_NAME --since "10 minutes ago" -p err --no-pager 2>/dev/null | wc -l)

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ No ERROR-level logs in last 10 minutes"
else
    echo "⚠️  ERROR-level logs detected: $ERROR_COUNT"
    echo ""
    echo "Recent errors:"
    sudo journalctl -u $SERVICE_NAME --since "10 minutes ago" -p err --no-pager | tail -n 20
fi

# Display recent INFO logs
echo ""
echo "Recent INFO logs (last 10 lines):"
sudo journalctl -u $SERVICE_NAME --since "10 minutes ago" -p info --no-pager | tail -n 10
```

### Step 7: Check for Restart Loops

```bash
# Check for unexpected restarts in last hour
echo ""
echo "=== Step 7: Service Stability Validation ==="

SERVICE_NAME="docling-mcp.service"

START_COUNT=$(sudo journalctl -u $SERVICE_NAME --since "1 hour ago" | grep -c "Started Docling MCP Server" || echo 0)

echo "Service starts in last hour: $START_COUNT"

if [ "$START_COUNT" -le 1 ]; then
    echo "✅ No unexpected restarts detected"
elif [ "$START_COUNT" -le 3 ]; then
    echo "⚠️  Multiple starts detected ($START_COUNT), may indicate restart attempts"
else
    echo "❌ Excessive restarts detected ($START_COUNT), service unstable"
    echo ""
    echo "Recent restart logs:"
    sudo journalctl -u $SERVICE_NAME --since "1 hour ago" | grep "Started Docling MCP Server"
    exit 1
fi
```

### Step 8: Generate Validation Report

```bash
# Generate comprehensive validation report
DOC_PATH="/opt/docling-mcp/deployment-docs"
mkdir -p "$DOC_PATH"

cat > "$DOC_PATH/health-check-validation-report.txt" <<EOF
# Health Check Validation Report
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-docling-mcp-server.hx.dev.local
# Task: hx-docling-mcp-task-191

## Service Status
$(sudo systemctl status docling-mcp.service --no-pager)

## DNS Resolution
Hostname: hx-docling-mcp-server.hx.dev.local
IP Address: $(dig +short hx-docling-mcp-server.hx.dev.local | tail -n1)

## Port Listening
$(ss -tlnp | grep ':8000')

## Health Check Response
URL: http://hx-docling-mcp-server.hx.dev.local:8000/health
$(curl -s http://hx-docling-mcp-server.hx.dev.local:8000/health | python3 -m json.tool 2>/dev/null)

## Service Logs (Last 20 Lines)
$(sudo journalctl -u docling-mcp.service -n 20 --no-pager)

## Validation Summary
- Service Active: $(systemctl is-active docling-mcp.service)
- Service Enabled: $(systemctl is-enabled docling-mcp.service)
- Health Check: PASSED
- Dependencies: All accessible
- ERROR Logs: 0 in last 10 minutes
- Restart Count: $START_COUNT in last hour

## Next Steps
- Task 192: Execute Integration Tests
- Task 193: Validate Dependency Connectivity
- Task 194: Perform Load Testing (optional)
- Task 195: Document Operational Status
EOF

echo "✅ Validation report generated: $DOC_PATH/health-check-validation-report.txt"
cat "$DOC_PATH/health-check-validation-report.txt"
```

## Validation

**Validation Commands:**

```bash
echo "=== Health Check Validation Summary ==="

# All checks in one validation block
ALL_PASSED=true

# 1. Service active
if systemctl is-active docling-mcp.service > /dev/null 2>&1; then
    echo "✅ PASSED: Service active"
else
    echo "❌ FAILED: Service not active"
    ALL_PASSED=false
fi

# 2. DNS resolution
if dig +short hx-docling-mcp-server.hx.dev.local | grep -q .; then
    echo "✅ PASSED: DNS resolution"
else
    echo "❌ FAILED: DNS resolution"
    ALL_PASSED=false
fi

# 3. Port listening
if ss -tlnp | grep -q ':8000'; then
    echo "✅ PASSED: Port 8000 listening"
else
    echo "❌ FAILED: Port not listening"
    ALL_PASSED=false
fi

# 4. Health check endpoint
HEALTH_RESPONSE=$(curl -s -f -m 2 http://hx-docling-mcp-server.hx.dev.local:8000/health 2>/dev/null)
if [ $? -eq 0 ]; then
    HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)

    if [ "$HEALTH_STATUS" = "healthy" ] || [ "$HEALTH_STATUS" = "degraded" ]; then
        echo "✅ PASSED: Health check ($HEALTH_STATUS)"
    else
        echo "❌ FAILED: Health check (status: $HEALTH_STATUS)"
        ALL_PASSED=false
    fi
else
    echo "❌ FAILED: Health check endpoint"
    ALL_PASSED=false
fi

# 5. No ERROR logs
ERROR_COUNT=$(sudo journalctl -u docling-mcp.service --since "10 minutes ago" -p err --no-pager 2>/dev/null | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ PASSED: No ERROR logs"
else
    echo "⚠️  WARNING: $ERROR_COUNT ERROR logs"
fi

# 6. Stability (no restart loops)
START_COUNT=$(sudo journalctl -u docling-mcp.service --since "1 hour ago" | grep -c "Started Docling MCP Server" || echo 0)
if [ "$START_COUNT" -le 1 ]; then
    echo "✅ PASSED: Service stable (no restarts)"
else
    echo "⚠️  WARNING: $START_COUNT starts in last hour"
fi

# Summary
echo ""
if [ "$ALL_PASSED" = true ]; then
    echo "✅ ALL VALIDATIONS PASSED - Service operational and healthy"
    echo ""
    echo "Next Step: Task 192 - Execute Integration Tests"
    exit 0
else
    echo "❌ VALIDATION FAILED - Review errors above"
    exit 1
fi
```

**Expected Results:**
- Service active (running)
- DNS resolves to 192.168.10.217
- Port 8000 listening (TCP)
- Health check returns HTTP 200 with status "healthy" or "degraded"
- Response time <2 seconds
- No ERROR-level logs in last 10 minutes
- No more than 1 service start in last hour

## Notes

**Health Status Levels:**
- **healthy**: All dependencies accessible, service fully operational
- **degraded**: Some non-critical dependencies unavailable (e.g., Redis), core functionality works
- **unhealthy**: Critical dependencies unavailable (LiteLLM or Qdrant), service cannot process documents

**Acceptable States:**
- **healthy**: Ideal state, proceed to integration testing
- **degraded**: Acceptable for testing, but investigate degraded dependencies
- **unhealthy**: NOT acceptable, troubleshoot before continuing

**Dependency Criticality:**
- **CRITICAL**: LiteLLM (entity extraction), Qdrant (knowledge graph storage)
- **HIGH**: hx-literag-server (knowledge graph generation)
- **MEDIUM**: Redis (session management, caching)

**Troubleshooting:**
- If health check fails: Check `journalctl -u docling-mcp.service -n 50`
- If dependencies unhealthy: Verify LiteLLM, Qdrant, Redis, hx-literag-server operational
- If response time >2s: Check dependency latency in health response
- If restart loops: Review ERROR logs for crash reason

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Health Checks (lines 1668-1692)
- Section: Deployment Success Criteria (lines 1787-1794)

## Risk Assessment

**Risk Level**: Low

**Risks**:
1. **False positive**: Health check passes but service dysfunctional
2. **Dependency unavailable**: External service down, health reports degraded
3. **Intermittent failures**: Health check passes sporadically

**Mitigation**:
- Multiple health check attempts (5 attempts, 80% success rate required)
- Dependency health validation (check all 4 dependencies)
- Log review for ERROR messages (catch issues not reflected in health check)
- Stability check (ensure no restart loops)
- Comprehensive validation report for documentation
