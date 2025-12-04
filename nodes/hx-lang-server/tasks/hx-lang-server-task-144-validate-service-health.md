# Task 144: Validate Service Health and Connectivity

**Task ID**: hx-lang-server-task-144
**Phase**: Deployment (Service Validation)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 143 (Service Enabled and Started)
**Estimated Effort**: 45 minutes

---

## Objective

Perform comprehensive health and connectivity validation for hx-lang-server, verifying the service is operational, responding to health checks, and can connect to all required external dependencies (PostgreSQL, Redis, Ollama servers, LightRAG).

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 143 (Service Enabled and Started) completed
- [ ] Service is running (systemctl is-active = active)

---

## Pre-Execution Validation

**CRITICAL**: Verify service is running before validation.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Check service is running
SERVICE_STATE=$(systemctl is-active hx-lang-server.service 2>/dev/null)

if [ "$SERVICE_STATE" != "active" ]; then
    echo "ERROR: Service is not running (state: $SERVICE_STATE)"
    echo "Complete Task 143 first"
    exit 1
fi

echo "Service is running, proceeding with validation..."
```

---

## Implementation Steps

### Step 1: Validate Service Process

```bash
# Validate service process
echo "=== Service Process Validation ==="

# Get service status
sudo systemctl status hx-lang-server.service --no-pager

# Get process details
PID=$(systemctl show --property=MainPID --value hx-lang-server.service)
echo ""
echo "Main PID: $PID"

if [ "$PID" != "0" ] && [ -n "$PID" ]; then
    # Process details
    echo ""
    echo "Process details:"
    ps -p "$PID" -o pid,ppid,user,%cpu,%mem,rss,vsz,stat,start,cmd --no-headers

    # Memory usage
    echo ""
    echo "Memory usage (from /proc):"
    cat /proc/$PID/status | grep -E "^(VmRSS|VmSize|VmPeak|Threads):"

    # Open file descriptors
    echo ""
    echo "Open file descriptors:"
    ls /proc/$PID/fd 2>/dev/null | wc -l
else
    echo "ERROR: Process not found"
    exit 1
fi
```

### Step 2: Validate Health Endpoint

```bash
# Validate health endpoint
echo ""
echo "=== Health Endpoint Validation ==="

# Test basic health endpoint
echo "Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8100/health)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/health)

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "Health endpoint: PASSED"
else
    echo "Health endpoint: FAILED"
fi

# Test readiness endpoint (if available)
echo ""
echo "Testing /ready endpoint..."
READY_RESPONSE=$(curl -s http://localhost:8100/ready 2>/dev/null)
READY_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/ready 2>/dev/null)

if [ "$READY_CODE" = "200" ]; then
    echo "HTTP Status: $READY_CODE"
    echo "Response:"
    echo "$READY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$READY_RESPONSE"
    echo "Readiness endpoint: PASSED"
elif [ "$READY_CODE" = "404" ]; then
    echo "Readiness endpoint not implemented (optional)"
else
    echo "Readiness endpoint: HTTP $READY_CODE"
fi
```

### Step 3: Validate API Documentation

```bash
# Validate OpenAPI documentation
echo ""
echo "=== API Documentation Validation ==="

# Test /docs endpoint
echo "Testing /docs endpoint..."
DOCS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/docs)

if [ "$DOCS_CODE" = "200" ]; then
    echo "OpenAPI docs (/docs): AVAILABLE (HTTP 200)"
else
    echo "OpenAPI docs (/docs): HTTP $DOCS_CODE"
fi

# Test /openapi.json endpoint
echo ""
echo "Testing /openapi.json endpoint..."
OPENAPI_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/openapi.json)

if [ "$OPENAPI_CODE" = "200" ]; then
    echo "OpenAPI JSON: AVAILABLE (HTTP 200)"
    # Show available endpoints
    echo ""
    echo "Available endpoints:"
    curl -s http://localhost:8100/openapi.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for path, methods in data.get('paths', {}).items():
    for method in methods.keys():
        print(f'  {method.upper()} {path}')
" 2>/dev/null || echo "  (Could not parse OpenAPI spec)"
else
    echo "OpenAPI JSON: HTTP $OPENAPI_CODE"
fi
```

### Step 4: Validate PostgreSQL Connectivity

```bash
# Validate PostgreSQL connectivity
echo ""
echo "=== PostgreSQL Connectivity Validation ==="

# Load environment
source /opt/hx-lang-server/.env 2>/dev/null

# Test DNS resolution
echo "Testing DNS resolution for $POSTGRES_HOST..."
if getent hosts "$POSTGRES_HOST" > /dev/null 2>&1; then
    IP=$(getent hosts "$POSTGRES_HOST" | awk '{print $1}')
    echo "DNS resolution: OK ($POSTGRES_HOST -> $IP)"
else
    echo "DNS resolution: FAILED"
fi

# Test TCP connectivity
echo ""
echo "Testing TCP connectivity to $POSTGRES_HOST:$POSTGRES_PORT..."
if timeout 5 bash -c "echo > /dev/tcp/$POSTGRES_HOST/$POSTGRES_PORT" 2>/dev/null; then
    echo "TCP connectivity: OK"
else
    echo "TCP connectivity: FAILED"
fi

# Test PostgreSQL connection (if psql available)
if command -v psql > /dev/null 2>&1; then
    echo ""
    echo "Testing PostgreSQL authentication..."
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "PostgreSQL authentication: OK"
    else
        echo "PostgreSQL authentication: FAILED"
    fi
else
    echo "psql not installed, skipping authentication test"
fi
```

### Step 5: Validate Redis Connectivity

```bash
# Validate Redis connectivity
echo ""
echo "=== Redis Connectivity Validation ==="

# Parse Redis URL
source /opt/hx-lang-server/.env 2>/dev/null
REDIS_HOST=$(echo "$REDIS_URL" | sed -E 's|redis://([^:/]+).*|\1|')
REDIS_PORT=$(echo "$REDIS_URL" | sed -E 's|redis://[^:]+:([0-9]+).*|\1|')
REDIS_PORT=${REDIS_PORT:-6379}

echo "Redis host: $REDIS_HOST"
echo "Redis port: $REDIS_PORT"

# Test DNS resolution
echo ""
echo "Testing DNS resolution..."
if getent hosts "$REDIS_HOST" > /dev/null 2>&1; then
    IP=$(getent hosts "$REDIS_HOST" | awk '{print $1}')
    echo "DNS resolution: OK ($REDIS_HOST -> $IP)"
else
    echo "DNS resolution: FAILED"
fi

# Test TCP connectivity
echo ""
echo "Testing TCP connectivity..."
if timeout 5 bash -c "echo > /dev/tcp/$REDIS_HOST/$REDIS_PORT" 2>/dev/null; then
    echo "TCP connectivity: OK"
else
    echo "TCP connectivity: FAILED"
fi

# Test Redis PING (if redis-cli available)
if command -v redis-cli > /dev/null 2>&1; then
    echo ""
    echo "Testing Redis PING..."
    PONG=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" PING 2>/dev/null)
    if [ "$PONG" = "PONG" ]; then
        echo "Redis PING: OK"
    else
        echo "Redis PING: FAILED"
    fi
else
    echo "redis-cli not installed, skipping PING test"
fi
```

### Step 6: Validate Ollama Connectivity

```bash
# Validate Ollama connectivity
echo ""
echo "=== Ollama Connectivity Validation ==="

source /opt/hx-lang-server/.env 2>/dev/null

# Test Ollama General (ollama1)
echo "Testing Ollama General: $OLLAMA_GENERAL_URL"
OLLAMA1_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$OLLAMA_GENERAL_URL/api/tags" 2>/dev/null || echo "000")
if [ "$OLLAMA1_CODE" = "200" ]; then
    echo "Ollama General ($OLLAMA_GENERAL_URL): OK"
    echo "Available models:"
    curl -s "$OLLAMA_GENERAL_URL/api/tags" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for model in data.get('models', [])[:5]:
    print(f\"  - {model.get('name')}\")
" 2>/dev/null || echo "  (Could not parse response)"
else
    echo "Ollama General: FAILED (HTTP $OLLAMA1_CODE)"
fi

# Test Ollama Code (ollama2)
echo ""
echo "Testing Ollama Code: $OLLAMA_CODE_URL"
OLLAMA2_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$OLLAMA_CODE_URL/api/tags" 2>/dev/null || echo "000")
if [ "$OLLAMA2_CODE" = "200" ]; then
    echo "Ollama Code ($OLLAMA_CODE_URL): OK"
else
    echo "Ollama Code: FAILED (HTTP $OLLAMA2_CODE)"
fi
```

### Step 7: Validate LightRAG Connectivity

```bash
# Validate LightRAG connectivity
echo ""
echo "=== LightRAG Connectivity Validation ==="

source /opt/hx-lang-server/.env 2>/dev/null

echo "Testing LightRAG: $LIGHTRAG_URL"

# Test health endpoint
LIGHTRAG_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$LIGHTRAG_URL/health" 2>/dev/null || echo "000")
if [ "$LIGHTRAG_CODE" = "200" ]; then
    echo "LightRAG health: OK"
    curl -s "$LIGHTRAG_URL/health" | python3 -m json.tool 2>/dev/null || true
else
    echo "LightRAG health: HTTP $LIGHTRAG_CODE"
fi
```

### Step 8: Validate FastMCP Connectivity

```bash
# Validate FastMCP Gateway connectivity
echo ""
echo "=== FastMCP Gateway Connectivity Validation ==="

source /opt/hx-lang-server/.env 2>/dev/null

echo "Testing FastMCP: $FASTMCP_URL"

# Test root endpoint
FASTMCP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FASTMCP_URL/" 2>/dev/null || echo "000")
if [ "$FASTMCP_CODE" = "200" ] || [ "$FASTMCP_CODE" = "404" ]; then
    echo "FastMCP connectivity: OK (HTTP $FASTMCP_CODE)"
else
    echo "FastMCP connectivity: FAILED (HTTP $FASTMCP_CODE)"
fi
```

### Step 9: Create Validation Report

```bash
# Create comprehensive validation report
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

REPORT_FILE="$DOC_DIR/service-validation-report.txt"

sudo tee "$REPORT_FILE" > /dev/null <<EOF
# Service Validation Report
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-144

## Service Status
Service: hx-lang-server.service
State: $(systemctl is-active hx-lang-server.service)
Enabled: $(systemctl is-enabled hx-lang-server.service)
PID: $(systemctl show --property=MainPID --value hx-lang-server.service)

## Health Check
Health Endpoint: http://localhost:8100/health
Status: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/health)

## Dependency Connectivity Summary

| Dependency | Endpoint | Status |
|------------|----------|--------|
| PostgreSQL | hx-postgres-server.hx.dev.local:5432 | $(timeout 2 bash -c "echo > /dev/tcp/hx-postgres-server.hx.dev.local/5432" 2>/dev/null && echo "OK" || echo "FAILED") |
| Redis | hx-redis-server.hx.dev.local:6379 | $(timeout 2 bash -c "echo > /dev/tcp/hx-redis-server.hx.dev.local/6379" 2>/dev/null && echo "OK" || echo "FAILED") |
| Ollama General | hx-ollama1-server.hx.dev.local:11434 | $(curl -s -o /dev/null -w "%{http_code}" http://hx-ollama1-server.hx.dev.local:11434/api/tags 2>/dev/null || echo "FAILED") |
| Ollama Code | hx-ollama2-server.hx.dev.local:11434 | $(curl -s -o /dev/null -w "%{http_code}" http://hx-ollama2-server.hx.dev.local:11434/api/tags 2>/dev/null || echo "FAILED") |
| LightRAG | hx-literag-server.hx.dev.local:8020 | $(curl -s -o /dev/null -w "%{http_code}" http://hx-literag-server.hx.dev.local:8020/health 2>/dev/null || echo "FAILED") |
| FastMCP | hx-fastmcp-server.hx.dev.local:8000 | $(curl -s -o /dev/null -w "%{http_code}" http://hx-fastmcp-server.hx.dev.local:8000/ 2>/dev/null || echo "FAILED") |

## Resource Usage
Memory: $(ps -p $(systemctl show --property=MainPID --value hx-lang-server.service) -o rss= 2>/dev/null | awk '{printf "%.1f MB", $1/1024}' || echo "N/A")
CPU: $(ps -p $(systemctl show --property=MainPID --value hx-lang-server.service) -o %cpu= 2>/dev/null || echo "N/A")%

## Validation Performed By
Task: hx-lang-server-task-144
Agent: william-chen (Infrastructure Specialist)
EOF

echo "Validation report created: $REPORT_FILE"
cat "$REPORT_FILE"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Validation Report | /opt/hx-lang-server/deployment-docs/service-validation-report.txt | Comprehensive validation results |

---

## Verification

**Validation Commands:**

```bash
echo "=== Service Health Validation Summary ==="

VALIDATION_PASSED=true

# Check 1: Service running
echo "1. Service Status:"
if [ "$(systemctl is-active hx-lang-server.service)" = "active" ]; then
    echo "PASSED: Service is running"
else
    echo "FAILED: Service not running"
    VALIDATION_PASSED=false
fi

# Check 2: Health endpoint
echo ""
echo "2. Health Endpoint:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/health 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "PASSED: Health endpoint returns 200"
else
    echo "FAILED: Health endpoint returns $HTTP_CODE"
    VALIDATION_PASSED=false
fi

# Check 3: PostgreSQL connectivity
echo ""
echo "3. PostgreSQL Connectivity:"
if timeout 2 bash -c "echo > /dev/tcp/hx-postgres-server.hx.dev.local/5432" 2>/dev/null; then
    echo "PASSED: PostgreSQL reachable"
else
    echo "FAILED: PostgreSQL not reachable"
    VALIDATION_PASSED=false
fi

# Check 4: Redis connectivity
echo ""
echo "4. Redis Connectivity:"
if timeout 2 bash -c "echo > /dev/tcp/hx-redis-server.hx.dev.local/6379" 2>/dev/null; then
    echo "PASSED: Redis reachable"
else
    echo "FAILED: Redis not reachable"
    VALIDATION_PASSED=false
fi

# Check 5: Ollama connectivity
echo ""
echo "5. Ollama Connectivity:"
OLLAMA1=$(curl -s -o /dev/null -w "%{http_code}" http://hx-ollama1-server.hx.dev.local:11434/api/tags 2>/dev/null)
if [ "$OLLAMA1" = "200" ]; then
    echo "PASSED: Ollama General reachable"
else
    echo "WARNING: Ollama General returned $OLLAMA1"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL CRITICAL VALIDATIONS PASSED"
    echo "Service is healthy and dependencies are reachable"
else
    echo "SOME VALIDATIONS FAILED"
    echo "Review failures above and troubleshoot"
    exit 1
fi
```

**Expected Results:**
- Service is running (active state)
- Health endpoint returns HTTP 200
- PostgreSQL TCP connection succeeds
- Redis TCP connection succeeds
- Ollama servers are reachable

---

## Rollback Procedure

No rollback needed for validation task. If validation fails, troubleshoot using:

```bash
# Troubleshooting commands
sudo journalctl -u hx-lang-server.service -f
sudo systemctl status hx-lang-server.service
curl -v http://localhost:8100/health
```

---

## Notes

**Health Check Frequency:**
- Service health should be monitored continuously
- Consider adding Prometheus metrics endpoint
- Health checks include dependency status

**Connectivity Requirements:**
- All external dependencies must be reachable
- DNS resolution via hx-dc-server
- Network is internal HX network (192.168.10.0/24)

**Degraded State:**
- Service may run in degraded state if some dependencies unavailable
- Health endpoint should reflect dependency status
- Application should handle dependency failures gracefully

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Monitoring & Observability - Health Checks (lines 738-759)
- Section: Dependencies - External Services (lines 587-598)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 13: Service Deployment (Task Range 141-150)

---

## Risk Assessment

**Risk Level**: Low (validation only)

**Risks:**
1. **False positives**: Validation passes but service has issues
   - Mitigation: Comprehensive checks across all dependencies
2. **False negatives**: Validation fails but service is actually working
   - Mitigation: Multiple validation methods (TCP, HTTP, protocol-specific)

**Dependencies Blocked:**
- Work Stream 14 (Testing & Validation) can proceed after this task
- Julia Santos can begin test execution
