# Task 174: Execute Health Check Tests

**Assigned To**: julia-santos
**Estimated Effort**: 30 minutes
**Dependencies**: Task 173 (Integration tests PASSED)
**Status**: Not Started

## Objective

Execute all 4 health check test cases (TC-HEALTH-001 through TC-HEALTH-004) to verify the /health endpoint functionality, resource usage validation, error-free operation, and dependency health validation.

## Pre-Execution Validation

**CRITICAL**: Check if health check tests have already been executed and results documented BEFORE proceeding.

```bash
# Check if health check test results already exist
RESULTS_FILE="/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-results/health-check-test-results.md"

if [ -f "$RESULTS_FILE" ]; then
    # Check if all health check tests passed
    if grep -q "Status: ✅ ALL HEALTH CHECK TESTS PASSED" "$RESULTS_FILE" 2>/dev/null; then
        echo "✅ VALIDATION RESULT: Health check tests already executed and PASSED"
        echo "ACTION: SKIP task execution - review existing results"
        exit 0
    else
        echo "⚠️ VALIDATION RESULT: Health check tests executed but FAILED or INCOMPLETE"
        echo "ACTION: RE-EXECUTE health check tests"
    fi
else
    echo "❌ VALIDATION RESULT: Health check tests not yet executed"
    echo "ACTION: PROCEED with test execution"
fi
```

**If Already Complete**: Skip to Validation section and verify existing results
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Health check testing is the FOURTH mandatory phase (Phase 4 of 5) in test-driven deployment. These tests validate operational readiness by verifying the service health endpoint, resource consumption, error-free operation, and dependency health. This phase can only execute after integration testing (Task 173) passes.

**Health Check Areas**:
1. **Health Endpoint Validation** (TC-HEALTH-001) - /health endpoint responds correctly with dependency status
2. **Resource Usage Validation** (TC-HEALTH-002) - CPU, memory, disk within acceptable limits
3. **Error-Free Operation** (TC-HEALTH-003) - No ERROR/CRITICAL logs in journalctl
4. **Dependency Health Validation** (TC-HEALTH-004) - LiteLLM, Qdrant, Redis, LightRAG health status

**Test Location**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/health-check/`
**Test Count**: 4 test cases
**Execution Mode**: SEQUENTIAL (health checks build on each other)

## Acceptance Criteria

- [ ] All 4 health check test cases executed
- [ ] Test results documented in `/tests/test-results/health-check-test-results.md`
- [ ] All tests PASS (100% pass rate required)
- [ ] Health endpoint returns 200 OK with all dependencies "healthy"
- [ ] Resource usage within acceptable limits
- [ ] No ERROR/CRITICAL log entries found
- [ ] Any test failures documented as defects using defect-template.md

## Implementation Steps

### Step 1: Verify Integration Tests Passed

```bash
# Verify prerequisite: integration tests passed
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

if ! grep -q "Status: ✅ ALL INTEGRATION TESTS PASSED" tests/test-results/integration-test-results.md 2>/dev/null; then
    echo "❌ ERROR: Integration tests have not passed"
    echo "Cannot proceed to health check testing until Task 173 completes successfully"
    exit 1
else
    echo "✅ Prerequisite verified: Integration tests passed"
fi
```

### Step 2: Prepare Test Environment

```bash
# Navigate to test directory
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Verify service is running
if ! systemctl is-active --quiet docling-mcp.service; then
    echo "❌ ERROR: docling-mcp.service not running"
    exit 1
else
    echo "✅ Service is running"
fi

# Set execution timestamp
EXEC_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "Health Check Test Execution Started: $EXEC_TIMESTAMP"
```

### Step 3: Execute Health Check Test Suite

```bash
# Execute health check tests sequentially
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Run pytest for health check test suite
pytest tests/test-suite/health-check/ \
    --verbose \
    --tb=short \
    --junitxml=tests/test-results/health-check-results.xml \
    2>&1 | tee tests/test-results/health-check-execution.log

# Capture exit code
HEALTH_CHECK_EXIT_CODE=$?
echo "Health Check Tests Exit Code: $HEALTH_CHECK_EXIT_CODE"
```

### Step 4: Document Test Results

```bash
# Create health check test results document
cat > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-results/health-check-test-results.md << 'EOF'
# Health Check Test Results

**Service**: docling-mcp
**Test Phase**: Health Check Testing (Phase 4 of 5)
**Execution Date**: $(date +"%Y-%m-%d")
**Execution Time**: $(date +"%H:%M:%S")
**Executed By**: julia-santos (Testing & Quality Specialist)

---

## Test Execution Summary

**Test Suite**: Health Check Tests (4 Validation Areas)
**Test Location**: `tests/test-suite/health-check/`
**Execution Mode**: Sequential
**Total Test Cases**: 4
**Test Cases Executed**: [COUNT]
**Tests Passed**: [PASS_COUNT]
**Tests Failed**: [FAIL_COUNT]
**Pass Rate**: [PERCENTAGE]%

**Exit Code**: $HEALTH_CHECK_EXIT_CODE
**Status**: [✅ ALL TESTS PASSED | ❌ TESTS FAILED]

---

## Individual Test Results

### TC-HEALTH-001: Health Check Endpoint

**Status**: [PASS | FAIL]
**Test Objective**: Verify /health endpoint responds with 200 OK and correct dependency status

**Evidence**:
```
# Health endpoint request
$ curl -s http://hx-docling-mcp-server.hx.dev.local:8000/health | jq .

[Paste actual response]
```

**Validation Checks**:
- [ ] HTTP status code: 200 OK
- [ ] Response format: Valid JSON
- [ ] Service status: "healthy"
- [ ] LiteLLM dependency: "healthy"
- [ ] Qdrant dependency: "healthy"
- [ ] Redis dependency: "healthy"
- [ ] LightRAG dependency: "healthy"
- [ ] Response time: < 2 seconds

**Dependency Health Summary**:
| Dependency | Status | Response Time |
|------------|--------|---------------|
| LiteLLM Gateway | [healthy/unhealthy/degraded] | [N ms] |
| Qdrant | [healthy/unhealthy/degraded] | [N ms] |
| Redis | [healthy/unhealthy/degraded] | [N ms] |
| LightRAG | [healthy/unhealthy/degraded] | [N ms] |

**Notes**: [Any observations]

---

### TC-HEALTH-002: Resource Usage Validation

**Status**: [PASS | FAIL]
**Test Objective**: Verify CPU, memory, and disk usage within acceptable limits

**Evidence**:
```
# CPU usage
$ top -b -n 1 -p $(pgrep -f docling-mcp) | grep docling-mcp
[Paste output]

# Memory usage
$ ps aux | grep docling-mcp | grep -v grep
[Paste output]

# Disk usage
$ df -h /opt/docling-mcp /var/lib/docling-mcp /var/log/docling-mcp
[Paste output]
```

**Validation Checks**:
- [ ] CPU usage: < 50% (baseline, no load)
- [ ] Memory usage: < 4GB
- [ ] Disk usage (/opt/docling-mcp): < 80%
- [ ] Disk usage (/var/lib/docling-mcp): < 80%
- [ ] Disk usage (/var/log/docling-mcp): < 80%
- [ ] No swap usage
- [ ] Process count reasonable

**Resource Metrics**:
| Resource | Current | Limit | Status |
|----------|---------|-------|--------|
| CPU | [N%] | 50% | [OK/WARNING] |
| Memory | [N GB] | 4GB | [OK/WARNING] |
| Disk (/opt) | [N%] | 80% | [OK/WARNING] |
| Disk (/var/lib) | [N%] | 80% | [OK/WARNING] |
| Disk (/var/log) | [N%] | 80% | [OK/WARNING] |

**Notes**: [Any observations]

---

### TC-HEALTH-003: Error-Free Operation

**Status**: [PASS | FAIL]
**Test Objective**: Verify no ERROR or CRITICAL log entries in systemd journal

**Evidence**:
```
# Check for ERROR-level logs since service start
$ journalctl -u docling-mcp.service --since "$(systemctl show -p ActiveEnterTimestamp docling-mcp.service | cut -d'=' -f2)" | grep -E "ERROR|CRITICAL"

[Paste output or "No ERROR/CRITICAL logs found"]
```

**Validation Checks**:
- [ ] No ERROR logs found
- [ ] No CRITICAL logs found
- [ ] No exception stack traces
- [ ] No connection failures logged
- [ ] No timeout errors logged
- [ ] Log output structured correctly (JSON format)

**Log Analysis**:
- Total log entries since start: [N]
- DEBUG entries: [N]
- INFO entries: [N]
- WARN entries: [N]
- ERROR entries: [N]
- CRITICAL entries: [N]

**Notes**: [Any observations or warnings requiring attention]

---

### TC-HEALTH-004: Dependency Health Validation

**Status**: [PASS | FAIL]
**Test Objective**: Verify all external dependencies report healthy status

**Evidence**:
```
# LiteLLM Gateway health
$ curl -s http://hx-litellm-server.hx.dev.local:4000/health
[Paste response]

# Qdrant health
$ curl -s http://hx-qdrant-server.hx.dev.local:6333/health
[Paste response]

# Redis health
$ redis-cli -h hx-redis-server.hx.dev.local PING
[Paste response]

# LightRAG health
$ curl -s http://hx-literag-server.hx.dev.local:8000/health
[Paste response]
```

**Validation Checks**:
- [ ] LiteLLM Gateway: responds, status "healthy"
- [ ] Qdrant: responds, status "healthy"
- [ ] Redis: PING returns PONG
- [ ] LightRAG: responds, status "healthy"
- [ ] All dependencies: response time < 5 seconds
- [ ] No connection timeout errors

**Dependency Health Matrix**:
| Dependency | Hostname | Port | Health Status | Response Time | Notes |
|------------|----------|------|---------------|---------------|-------|
| LiteLLM | hx-litellm-server.hx.dev.local | 4000 | [healthy/degraded/down] | [N ms] | |
| Qdrant | hx-qdrant-server.hx.dev.local | 6333 | [healthy/degraded/down] | [N ms] | |
| Redis | hx-redis-server.hx.dev.local | 6379 | [healthy/degraded/down] | [N ms] | |
| LightRAG | hx-literag-server.hx.dev.local | 8000 | [healthy/degraded/down] | [N ms] | |

**Notes**: [Any observations]

---

## Defects Identified

[If any tests failed, create defect tickets using defect-template.md and reference them here]

**Defect Count**: [N]
**Defect References**: [Links to defect tickets]

---

## Quality Gate Status

**Health Check Testing Gate**: [✅ PASS | ❌ FAIL]

**Gate Criteria**:
- [✅/❌] All 4 health check tests executed
- [✅/❌] 100% test pass rate achieved
- [✅/❌] /health endpoint returns 200 OK
- [✅/❌] All dependencies report "healthy"
- [✅/❌] Resource usage within limits
- [✅/❌] No ERROR/CRITICAL logs found
- [✅/❌] No blocking defects identified

**Decision**: [PROCEED to Task 175 (Multimodal Tests) | BLOCK until defects resolved]

---

## Evidence Artifacts

- Pytest XML results: `tests/test-results/health-check-results.xml`
- Execution log: `tests/test-results/health-check-execution.log`
- Health endpoint response: `tests/test-results/health-check-evidence/health-response.json`
- Resource metrics: `tests/test-results/health-check-evidence/resource-metrics.log`
- Journal logs: `tests/test-results/health-check-evidence/journal-logs.log`

---

**Test Execution Complete**: $(date +"%Y-%m-%d %H:%M:%S")
**Next Phase**: Multimodal Validation Testing (Task 175)

EOF

echo "✅ Health check test results documented"
```

### Step 5: Analyze Test Results and Create Defects (If Needed)

```bash
# Parse pytest results for failures
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Check for test failures
if [ $HEALTH_CHECK_EXIT_CODE -ne 0 ]; then
    echo "❌ HEALTH CHECK TESTS FAILED - Creating defect tickets"

    # Extract failed test names from pytest output
    grep -E "FAILED|ERROR" tests/test-results/health-check-execution.log > tests/test-results/failed-health-check-tests.txt

    echo "⚠️ ACTION REQUIRED: Review failed tests and create defect tickets"
    echo "Failed tests logged to: tests/test-results/failed-health-check-tests.txt"

    # Check specific failure patterns
    if grep -q "ERROR" tests/test-results/health-check-execution.log; then
        echo "⚠️ ERROR logs detected - review journal for root cause"
        journalctl -u docling-mcp.service -n 100 --no-pager
    fi

    exit 1
else
    echo "✅ ALL HEALTH CHECK TESTS PASSED"
    echo "Service is operationally healthy"
    echo "Proceeding to quality gate validation"
fi
```

## Validation

**Validation Commands:**

```bash
# Verify test results file exists and is complete
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# 1. Check results file exists
if [ -f "tests/test-results/health-check-test-results.md" ]; then
    echo "✅ Test results file created"
else
    echo "❌ Test results file missing"
    exit 1
fi

# 2. Verify all 4 tests were executed
TEST_COUNT=$(grep -c "^### TC-HEALTH-" tests/test-results/health-check-test-results.md)
if [ "$TEST_COUNT" -eq 4 ]; then
    echo "✅ All 4 health check tests documented"
else
    echo "❌ Only $TEST_COUNT tests documented (expected 4)"
    exit 1
fi

# 3. Verify pytest execution completed
if [ -f "tests/test-results/health-check-results.xml" ]; then
    echo "✅ Pytest XML results generated"
else
    echo "❌ Pytest XML results missing"
    exit 1
fi

# 4. Check pass/fail status
if grep -q "Status: ✅ ALL HEALTH CHECK TESTS PASSED" tests/test-results/health-check-test-results.md; then
    echo "✅ All health check tests PASSED"
    echo "✅ QUALITY GATE: PASS - Proceed to Task 175 (Multimodal Tests)"
    exit 0
else
    echo "❌ Some health check tests FAILED"
    echo "❌ QUALITY GATE: FAIL - BLOCK until defects resolved"
    exit 1
fi
```

**Expected Output:**
```
✅ Test results file created
✅ All 4 health check tests documented
✅ Pytest XML results generated
✅ All health check tests PASSED
✅ QUALITY GATE: PASS - Proceed to Task 175 (Multimodal Tests)
```

## Notes

### Operational Readiness Validation

Health check testing validates operational readiness by confirming:
- Service exposes functional health endpoint for monitoring
- Resource consumption is sustainable
- No runtime errors occurring
- All dependencies are healthy

### Health Endpoint Importance

The /health endpoint is CRITICAL for:
- Kubernetes/systemd monitoring and auto-restart
- Load balancer health checks
- Operational visibility and alerting
- Dependency status aggregation

### Resource Limits Rationale

Resource limits are based on:
- **CPU < 50%**: Baseline with no active document processing
- **Memory < 4GB**: Docling library with moderate document cache
- **Disk < 80%**: Prevents filesystem exhaustion

### Error Log Criticality

TC-HEALTH-003 (Error-Free Operation) is CRITICAL:
- ERROR/CRITICAL logs indicate runtime issues
- Must investigate and resolve before operational promotion
- Common causes: dependency connection failures, configuration errors, library exceptions

### Defect Severity for Health Check Failures

Health check test failures should be classified as:
- **CRITICAL**: /health endpoint non-responsive, ERROR logs present, dependency health failures
- **HIGH**: Resource limits exceeded, intermittent health check failures
- **MEDIUM**: WARNING logs requiring investigation, degraded dependency performance

## References

- Test Plan: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md`
- Test Suite Index: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite-index.md`
- Health Check Test Cases: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/health-check/`
- Defect Template: `/home/agent0/HX-Infrastructure/templates/testing/defect-template.md`

## Risk Assessment

**Risk**: HIGH

**Rationale**: Health check testing is the final validation before operational promotion. Failures here indicate the service is not ready for production use and may experience runtime issues.

**Mitigation Steps**:
1. Execute tests after service has been running for at least 5 minutes (warm-up period)
2. Capture comprehensive evidence for each health check area
3. Investigate and resolve ERROR logs immediately
4. Verify dependency health directly if health endpoint failures occur
5. Re-execute complete suite after any fixes
6. Verify quality gate before proceeding to Task 175
