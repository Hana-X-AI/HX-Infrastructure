# Task 192: Validate Dependency Connectivity

**Assigned To**: william-chen
**Estimated Effort**: 1 hour
**Dependencies**: Task 191 (Health Check Validation)
**Status**: Not Started

## Objective

Validate connectivity and basic functionality of all external dependencies (LiteLLM, Qdrant, Redis, hx-literag-server) from Docling MCP Server to ensure integration points operational before comprehensive testing.

## Pre-Execution Validation

**CRITICAL**: Check if dependency connectivity already validated BEFORE running tests.

```bash
# Validation command to check dependency connectivity
echo "Checking dependency connectivity status..."

DEPS_HEALTHY=true

# Check LiteLLM
if curl -s -f -m 2 http://hx-litellm-server.hx.dev.local:4000/health > /dev/null 2>&1; then
    echo "✅ LiteLLM: Accessible"
else
    echo "❌ LiteLLM: Not accessible"
    DEPS_HEALTHY=false
fi

# Check Qdrant
if curl -s -f -m 2 http://hx-qdrant-server.hx.dev.local:6333/collections > /dev/null 2>&1; then
    echo "✅ Qdrant: Accessible"
else
    echo "❌ Qdrant: Not accessible"
    DEPS_HEALTHY=false
fi

# Check Redis
if redis-cli -h hx-redis-server.hx.dev.local -p 6379 PING 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis: Accessible"
else
    echo "❌ Redis: Not accessible"
    DEPS_HEALTHY=false
fi

# Check hx-literag-server
if curl -s -f -m 2 http://hx-literag-server.hx.dev.local:8000/health > /dev/null 2>&1; then
    echo "✅ hx-literag-server: Accessible"
else
    echo "❌ hx-literag-server: Not accessible"
    DEPS_HEALTHY=false
fi

if [ "$DEPS_HEALTHY" = true ]; then
    echo ""
    echo "✅ VALIDATION RESULT: All dependencies accessible"
    echo "ACTION: SKIP if connectivity comprehensive, or proceed for detailed validation"
    exit 0
else
    echo ""
    echo "❌ VALIDATION RESULT: Some dependencies not accessible"
    echo "ACTION: PROCEED with validation to diagnose connectivity issues"
fi
```

**If Already Complete**: All dependencies accessible, skip if satisfied
**If Not Complete**: Continue with Implementation Steps below

---

## Context

The Docling MCP Server depends on four external services:

1. **hx-litellm-server** (hx-litellm-server.hx.dev.local:4000)
   - **Purpose**: LLM gateway for entity extraction
   - **Protocol**: HTTP/REST (OpenAI-compatible API)
   - **Criticality**: CRITICAL (knowledge graph generation fails without)

2. **hx-qdrant-server** (hx-qdrant-server.hx.dev.local:6333)
   - **Purpose**: Vector database for knowledge graph storage
   - **Protocol**: HTTP/REST (Qdrant API)
   - **Criticality**: CRITICAL (knowledge graph storage fails without)

3. **hx-redis-server** (hx-redis-server.hx.dev.local:6379)
   - **Purpose**: Session management and caching
   - **Protocol**: Redis protocol
   - **Criticality**: HIGH (session features unavailable without)

4. **hx-literag-server** (hx-literag-server.hx.dev.local:8000)
   - **Purpose**: LightRAG knowledge graph generation
   - **Protocol**: HTTP/REST (hx-literag API)
   - **Criticality**: CRITICAL (knowledge graph generation fails without)

This task validates:
- **Network Connectivity**: Can reach dependency hostnames/IPs
- **Service Availability**: Dependency services responding on expected ports
- **Basic Functionality**: Simple operations work (ping, health check, basic query)
- **Latency**: Response times acceptable (<500ms for health checks)

Comprehensive functional testing occurs in Phase 7 (Test Suite Execution coordinated by julia-santos).

## Acceptance Criteria

- [ ] DNS resolution works for all dependency hostnames
- [ ] All dependencies respond to health/ping checks
- [ ] LiteLLM health endpoint returns HTTP 200
- [ ] Qdrant collections endpoint returns HTTP 200
- [ ] Redis PING command returns PONG
- [ ] hx-literag-server health endpoint returns HTTP 200
- [ ] Response latencies documented (baseline for performance monitoring)
- [ ] No network timeouts or connection refused errors
- [ ] Connectivity test results documented for operational reference

## Implementation Steps

### Step 1: Validate LiteLLM Connectivity

```bash
# Test LiteLLM connectivity and basic functionality
echo "=== Step 1: LiteLLM Connectivity Validation ==="

LITELLM_HOST="hx-litellm-server.hx.dev.local"
LITELLM_PORT="4000"
LITELLM_HEALTH_URL="http://${LITELLM_HOST}:${LITELLM_PORT}/health"

# DNS resolution
echo "1. DNS Resolution:"
LITELLM_IP=$(dig +short $LITELLM_HOST | tail -n1)
if [ -n "$LITELLM_IP" ]; then
    echo "✅ DNS resolution successful: $LITELLM_HOST → $LITELLM_IP"
else
    echo "❌ DNS resolution failed for $LITELLM_HOST"
    exit 1
fi

# Port connectivity
echo ""
echo "2. Port Connectivity:"
if nc -zv -w 2 $LITELLM_HOST $LITELLM_PORT 2>&1 | grep -q "succeeded"; then
    echo "✅ Port $LITELLM_PORT accessible"
else
    echo "❌ Port $LITELLM_PORT not accessible"
    exit 1
fi

# Health check endpoint
echo ""
echo "3. Health Check:"
START_TIME=$(date +%s%3N)
HEALTH_RESPONSE=$(curl -s -f -m 2 "$LITELLM_HEALTH_URL" 2>&1)
HEALTH_STATUS=$?
END_TIME=$(date +%s%3N)
LATENCY=$((END_TIME - START_TIME))

if [ $HEALTH_STATUS -eq 0 ]; then
    echo "✅ Health check successful (latency: ${LATENCY}ms)"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed"
    echo "Error: $HEALTH_RESPONSE"
    exit 1
fi

echo ""
echo "✅ LiteLLM connectivity validated"
```

### Step 2: Validate Qdrant Connectivity

```bash
# Test Qdrant connectivity and basic functionality
echo ""
echo "=== Step 2: Qdrant Connectivity Validation ==="

QDRANT_HOST="hx-qdrant-server.hx.dev.local"
QDRANT_PORT="6333"
QDRANT_COLLECTIONS_URL="http://${QDRANT_HOST}:${QDRANT_PORT}/collections"

# DNS resolution
echo "1. DNS Resolution:"
QDRANT_IP=$(dig +short $QDRANT_HOST | tail -n1)
if [ -n "$QDRANT_IP" ]; then
    echo "✅ DNS resolution successful: $QDRANT_HOST → $QDRANT_IP"
else
    echo "❌ DNS resolution failed for $QDRANT_HOST"
    exit 1
fi

# Port connectivity
echo ""
echo "2. Port Connectivity:"
if nc -zv -w 2 $QDRANT_HOST $QDRANT_PORT 2>&1 | grep -q "succeeded"; then
    echo "✅ Port $QDRANT_PORT accessible"
else
    echo "❌ Port $QDRANT_PORT not accessible"
    exit 1
fi

# Collections endpoint
echo ""
echo "3. Collections Endpoint:"
START_TIME=$(date +%s%3N)
COLLECTIONS_RESPONSE=$(curl -s -f -m 2 "$QDRANT_COLLECTIONS_URL" 2>&1)
COLLECTIONS_STATUS=$?
END_TIME=$(date +%s%3N)
LATENCY=$((END_TIME - START_TIME))

if [ $COLLECTIONS_STATUS -eq 0 ]; then
    echo "✅ Collections endpoint accessible (latency: ${LATENCY}ms)"
    COLLECTION_COUNT=$(echo "$COLLECTIONS_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('result', {}).get('collections', [])))" 2>/dev/null || echo "unknown")
    echo "Existing collections: $COLLECTION_COUNT"
else
    echo "❌ Collections endpoint failed"
    echo "Error: $COLLECTIONS_RESPONSE"
    exit 1
fi

echo ""
echo "✅ Qdrant connectivity validated"
```

### Step 3: Validate Redis Connectivity

```bash
# Test Redis connectivity and basic functionality
echo ""
echo "=== Step 3: Redis Connectivity Validation ==="

REDIS_HOST="hx-redis-server.hx.dev.local"
REDIS_PORT="6379"

# DNS resolution
echo "1. DNS Resolution:"
REDIS_IP=$(dig +short $REDIS_HOST | tail -n1)
if [ -n "$REDIS_IP" ]; then
    echo "✅ DNS resolution successful: $REDIS_HOST → $REDIS_IP"
else
    echo "❌ DNS resolution failed for $REDIS_HOST"
    exit 1
fi

# Port connectivity
echo ""
echo "2. Port Connectivity:"
if nc -zv -w 2 $REDIS_HOST $REDIS_PORT 2>&1 | grep -q "succeeded"; then
    echo "✅ Port $REDIS_PORT accessible"
else
    echo "❌ Port $REDIS_PORT not accessible"
    exit 1
fi

# PING command
echo ""
echo "3. PING Command:"
# POSIX-compliant timing: capture seconds and nanoseconds separately
START_SEC=$(date +%s)
if command -v date >/dev/null 2>&1 && date +%N >/dev/null 2>&1; then
    START_NS=$(date +%N)
else
    START_NS=0  # Fallback if nanoseconds not supported
fi

PING_RESPONSE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT PING 2>&1)
PING_STATUS=$?

END_SEC=$(date +%s)
if command -v date >/dev/null 2>&1 && date +%N >/dev/null 2>&1; then
    END_NS=$(date +%N)
else
    END_NS=0
fi

# Calculate latency in milliseconds: ((END_SEC - START_SEC) * 1000 + (END_NS - START_NS) / 1000000)
LATENCY_MS=$(( (END_SEC - START_SEC) * 1000 + (END_NS - START_NS) / 1000000 ))

if [ $PING_STATUS -eq 0 ] && echo "$PING_RESPONSE" | grep -q "PONG"; then
    echo "✅ PING successful (latency: ${LATENCY_MS}ms)"
    echo "Response: $PING_RESPONSE"
else
    echo "❌ PING failed"
    echo "Error: $PING_RESPONSE"
    exit 1
fi

# INFO command (basic functionality test)
echo ""
echo "4. INFO Command (Server Status):"
INFO_RESPONSE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO server 2>&1 | grep "redis_version" | head -n1)
if [ -n "$INFO_RESPONSE" ]; then
    echo "✅ INFO command successful"
    echo "$INFO_RESPONSE"
else
    echo "⚠️  INFO command failed or empty response"
fi

echo ""
echo "✅ Redis connectivity validated"
```

### Step 4: Validate hx-literag-server Connectivity

```bash
# Test hx-literag-server connectivity and basic functionality
echo ""
echo "=== Step 4: hx-literag-server Connectivity Validation ==="

LITERAG_HOST="hx-literag-server.hx.dev.local"
LITERAG_PORT="8000"
LITERAG_HEALTH_URL="http://${LITERAG_HOST}:${LITERAG_PORT}/health"

# DNS resolution
echo "1. DNS Resolution:"
LITERAG_IP=$(dig +short $LITERAG_HOST | tail -n1)
if [ -n "$LITERAG_IP" ]; then
    echo "✅ DNS resolution successful: $LITERAG_HOST → $LITERAG_IP"
else
    echo "❌ DNS resolution failed for $LITERAG_HOST"
    exit 1
fi

# Port connectivity
echo ""
echo "2. Port Connectivity:"
if nc -zv -w 2 $LITERAG_HOST $LITERAG_PORT 2>&1 | grep -q "succeeded"; then
    echo "✅ Port $LITERAG_PORT accessible"
else
    echo "❌ Port $LITERAG_PORT not accessible"
    exit 1
fi

# Health check endpoint
echo ""
echo "3. Health Check:"
START_TIME=$(date +%s%3N)
HEALTH_RESPONSE=$(curl -s -f -m 2 "$LITERAG_HEALTH_URL" 2>&1)
HEALTH_STATUS=$?
END_TIME=$(date +%s%3N)
LATENCY=$((END_TIME - START_TIME))

if [ $HEALTH_STATUS -eq 0 ]; then
    echo "✅ Health check successful (latency: ${LATENCY}ms)"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed"
    echo "Error: $HEALTH_RESPONSE"
    exit 1
fi

echo ""
echo "✅ hx-literag-server connectivity validated"
```

### Step 5: Network Latency Baseline

```bash
# Measure network latency baseline to all dependencies
echo ""
echo "=== Step 5: Network Latency Baseline ==="

DEPENDENCIES=(
    "hx-litellm-server.hx.dev.local"
    "hx-qdrant-server.hx.dev.local"
    "hx-redis-server.hx.dev.local"
    "hx-literag-server.hx.dev.local"
)

echo "Measuring network latency (ICMP ping):"
echo ""

for dep in "${DEPENDENCIES[@]}"; do
    PING_RESULT=$(ping -c 5 -W 2 $dep 2>&1)

    if echo "$PING_RESULT" | grep -q "min/avg/max"; then
        AVG_LATENCY=$(echo "$PING_RESULT" | grep "min/avg/max" | cut -d= -f2 | cut -d/ -f2)
        echo "✅ $dep: ${AVG_LATENCY}ms average latency"
    else
        echo "⚠️  $dep: Ping failed or no response"
    fi
done

echo ""
echo "Latency baseline established"
```

### Step 6: Generate Connectivity Report

```bash
# Generate comprehensive connectivity validation report
DOC_PATH="/opt/docling-mcp/deployment-docs"
mkdir -p "$DOC_PATH"

echo "Pre-computing connectivity checks for stable report generation..."

# Initialize failure tracking
CRITICAL_FAILURES=""

# === LiteLLM Checks ===
LITELLM_DNS=$(dig +short hx-litellm-server.hx.dev.local 2>/dev/null | tail -n1)
[ -z "$LITELLM_DNS" ] && LITELLM_DNS="UNRESOLVED" && CRITICAL_FAILURES="${CRITICAL_FAILURES}LiteLLM DNS resolution failed\n"

if nc -zv -w 2 hx-litellm-server.hx.dev.local 4000 >/dev/null 2>&1; then
    LITELLM_PORT="succeeded"
else
    LITELLM_PORT="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}LiteLLM port 4000 not accessible\n"
fi

if curl -s -f -m 2 http://hx-litellm-server.hx.dev.local:4000/health >/dev/null 2>&1; then
    LITELLM_HEALTH="PASSED"
else
    LITELLM_HEALTH="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}LiteLLM health check failed\n"
fi

LITELLM_PING=$(ping -c 3 -W 2 hx-litellm-server.hx.dev.local 2>/dev/null | grep "min/avg/max" | cut -d= -f2 | cut -d/ -f2)
[ -z "$LITELLM_PING" ] && LITELLM_PING="N/A"
LITELLM_LATENCY="${LITELLM_PING}ms average"

# === Qdrant Checks ===
QDRANT_DNS=$(dig +short hx-qdrant-server.hx.dev.local 2>/dev/null | tail -n1)
[ -z "$QDRANT_DNS" ] && QDRANT_DNS="UNRESOLVED" && CRITICAL_FAILURES="${CRITICAL_FAILURES}Qdrant DNS resolution failed\n"

if nc -zv -w 2 hx-qdrant-server.hx.dev.local 6333 >/dev/null 2>&1; then
    QDRANT_PORT="succeeded"
else
    QDRANT_PORT="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}Qdrant port 6333 not accessible\n"
fi

if curl -s -f -m 2 http://hx-qdrant-server.hx.dev.local:6333/collections >/dev/null 2>&1; then
    QDRANT_API="PASSED"
else
    QDRANT_API="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}Qdrant collections API failed\n"
fi

QDRANT_PING=$(ping -c 3 -W 2 hx-qdrant-server.hx.dev.local 2>/dev/null | grep "min/avg/max" | cut -d= -f2 | cut -d/ -f2)
[ -z "$QDRANT_PING" ] && QDRANT_PING="N/A"
QDRANT_LATENCY="${QDRANT_PING}ms average"

# === Redis Checks ===
REDIS_DNS=$(dig +short hx-redis-server.hx.dev.local 2>/dev/null | tail -n1)
[ -z "$REDIS_DNS" ] && REDIS_DNS="UNRESOLVED" && CRITICAL_FAILURES="${CRITICAL_FAILURES}Redis DNS resolution failed\n"

if nc -zv -w 2 hx-redis-server.hx.dev.local 6379 >/dev/null 2>&1; then
    REDIS_PORT="succeeded"
else
    REDIS_PORT="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}Redis port 6379 not accessible\n"
fi

REDIS_PING_CMD=$(redis-cli -h hx-redis-server.hx.dev.local -p 6379 PING 2>/dev/null)
if echo "$REDIS_PING_CMD" | grep -q "PONG"; then
    REDIS_PING_STATUS="PONG"
else
    REDIS_PING_STATUS="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}Redis PING command failed\n"
fi

REDIS_PING_LATENCY=$(ping -c 3 -W 2 hx-redis-server.hx.dev.local 2>/dev/null | grep "min/avg/max" | cut -d= -f2 | cut -d/ -f2)
[ -z "$REDIS_PING_LATENCY" ] && REDIS_PING_LATENCY="N/A"
REDIS_LATENCY="${REDIS_PING_LATENCY}ms average"

# === LiteRAG Checks ===
LITERAG_DNS=$(dig +short hx-literag-server.hx.dev.local 2>/dev/null | tail -n1)
[ -z "$LITERAG_DNS" ] && LITERAG_DNS="UNRESOLVED" && CRITICAL_FAILURES="${CRITICAL_FAILURES}LiteRAG DNS resolution failed\n"

if nc -zv -w 2 hx-literag-server.hx.dev.local 8000 >/dev/null 2>&1; then
    LITERAG_PORT="succeeded"
else
    LITERAG_PORT="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}LiteRAG port 8000 not accessible\n"
fi

if curl -s -f -m 2 http://hx-literag-server.hx.dev.local:8000/health >/dev/null 2>&1; then
    LITERAG_HEALTH="PASSED"
else
    LITERAG_HEALTH="FAILED"
    CRITICAL_FAILURES="${CRITICAL_FAILURES}LiteRAG health check failed\n"
fi

LITERAG_PING=$(ping -c 3 -W 2 hx-literag-server.hx.dev.local 2>/dev/null | grep "min/avg/max" | cut -d= -f2 | cut -d/ -f2)
[ -z "$LITERAG_PING" ] && LITERAG_PING="N/A"
LITERAG_LATENCY="${LITERAG_PING}ms average"

# Determine overall status
if [ -z "$CRITICAL_FAILURES" ]; then
    VALIDATION_SUMMARY="All dependencies: ACCESSIBLE"
else
    VALIDATION_SUMMARY="CRITICAL FAILURES DETECTED - See details below"
fi

# Generate report with pre-computed variables (stable, no command substitution)
cat > "$DOC_PATH/dependency-connectivity-report.txt" <<EOF
# Dependency Connectivity Validation Report
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-docling-mcp-server.hx.dev.local
# Task: hx-docling-mcp-task-192

## LiteLLM (hx-litellm-server.hx.dev.local:4000)
DNS Resolution: $LITELLM_DNS
Port 4000: $LITELLM_PORT
Health Check: $LITELLM_HEALTH
Latency: $LITELLM_LATENCY

## Qdrant (hx-qdrant-server.hx.dev.local:6333)
DNS Resolution: $QDRANT_DNS
Port 6333: $QDRANT_PORT
Collections API: $QDRANT_API
Latency: $QDRANT_LATENCY

## Redis (hx-redis-server.hx.dev.local:6379)
DNS Resolution: $REDIS_DNS
Port 6379: $REDIS_PORT
PING Command: $REDIS_PING_STATUS
Latency: $REDIS_LATENCY

## hx-literag-server (hx-literag-server.hx.dev.local:8000)
DNS Resolution: $LITERAG_DNS
Port 8000: $LITERAG_PORT
Health Check: $LITERAG_HEALTH
Latency: $LITERAG_LATENCY

## Validation Summary
$VALIDATION_SUMMARY
Baseline latencies: Documented above
Readiness: READY for integration testing (Phase 7)

## Critical Failures (if any)
$CRITICAL_FAILURES

## Next Steps
- Comprehensive integration testing (julia-santos coordination)
- Performance baseline measurement
- Load testing (optional)
- Operational handoff
EOF

echo "✅ Connectivity report generated: $DOC_PATH/dependency-connectivity-report.txt"

# Report critical failures to console
if [ -n "$CRITICAL_FAILURES" ]; then
    echo ""
    echo "=========================================="
    echo "⚠️  CRITICAL FAILURES DETECTED"
    echo "=========================================="
    echo -e "$CRITICAL_FAILURES"
    echo "=========================================="
    echo ""
    echo "❌ Validation FAILED - Review report at: $DOC_PATH/dependency-connectivity-report.txt"
    exit 1
else
    echo "✅ All connectivity checks PASSED"
    echo "📄 Full report: $DOC_PATH/dependency-connectivity-report.txt"
fi
cat "$DOC_PATH/dependency-connectivity-report.txt"
```

## Validation

**Validation Commands:**

```bash
echo "=== Dependency Connectivity Validation Summary ==="

ALL_DEPS_OK=true

# LiteLLM
if curl -s -f -m 2 http://hx-litellm-server.hx.dev.local:4000/health > /dev/null 2>&1; then
    echo "✅ PASSED: LiteLLM accessible"
else
    echo "❌ FAILED: LiteLLM not accessible"
    ALL_DEPS_OK=false
fi

# Qdrant
if curl -s -f -m 2 http://hx-qdrant-server.hx.dev.local:6333/collections > /dev/null 2>&1; then
    echo "✅ PASSED: Qdrant accessible"
else
    echo "❌ FAILED: Qdrant not accessible"
    ALL_DEPS_OK=false
fi

# Redis
if redis-cli -h hx-redis-server.hx.dev.local -p 6379 PING 2>/dev/null | grep -q "PONG"; then
    echo "✅ PASSED: Redis accessible"
else
    echo "❌ FAILED: Redis not accessible"
    ALL_DEPS_OK=false
fi

# hx-literag-server
if curl -s -f -m 2 http://hx-literag-server.hx.dev.local:8000/health > /dev/null 2>&1; then
    echo "✅ PASSED: hx-literag-server accessible"
else
    echo "❌ FAILED: hx-literag-server not accessible"
    ALL_DEPS_OK=false
fi

echo ""
if [ "$ALL_DEPS_OK" = true ]; then
    echo "✅ ALL VALIDATIONS PASSED - Dependencies accessible and operational"
    echo ""
    echo "Deployment validation complete. Ready for:"
    echo "  - Phase 7: Test Suite Execution (julia-santos coordination)"
    echo "  - Integration testing with full test suite"
    echo "  - Operational handoff"
    exit 0
else
    echo "❌ VALIDATION FAILED - Some dependencies not accessible"
    echo "Review connectivity report and troubleshoot failed dependencies"
    exit 1
fi
```

**Expected Results:**
- All 4 dependencies return successful health/ping checks
- No DNS resolution failures
- No port connectivity failures
- Network latencies <50ms (internal network)
- Connectivity report generated with baseline metrics

## Notes

**Dependency Endpoints:**
- **LiteLLM**: `http://hx-litellm-server.hx.dev.local:4000/health`
- **Qdrant**: `http://hx-qdrant-server.hx.dev.local:6333/collections`
- **Redis**: PING command on port 6379
- **hx-literag-server**: `http://hx-literag-server.hx.dev.local:8000/health`

**Network Topology:**
All services on same internal network (hx.dev.local domain), expected latencies <10ms for ICMP ping.

**Troubleshooting:**
- If DNS fails: Check `/etc/resolv.conf` points to hx-dc-server
- If port fails: Check firewall rules (should be disabled per philosophy), verify service running
- If health check fails: Check service operational status on dependency node
- If latency high: Check network congestion, investigate routing

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Dependencies (lines 835-909)
- Section: Integrations - Downstream Services (lines 929-956)

## Risk Assessment

**Risk Level**: Low

**Risks**:
1. **Dependency unavailable**: External service down, deployment blocked
2. **Network issue**: Routing or DNS problem prevents connectivity
3. **Intermittent failures**: Dependency responsive but unstable

**Mitigation**:
- Pre-validation checks dependency status before deployment
- Multiple connectivity tests (DNS, port, health, ping)
- Latency baseline for performance monitoring
- Comprehensive report documents dependency status
- Coordination with dependency owners if issues detected
