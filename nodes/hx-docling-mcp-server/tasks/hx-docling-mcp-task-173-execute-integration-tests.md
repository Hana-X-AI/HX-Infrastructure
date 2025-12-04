# Task 173: Execute Integration Tests

**Assigned To**: julia-santos
**Estimated Effort**: 1 hour
**Dependencies**: Task 172 (Functionality tests PASSED)
**Status**: Not Started

## Objective

Execute all 5 integration test cases (TC-INT-001 through TC-INT-005) to verify connectivity and integration with LiteLLM Gateway, Qdrant vector database, Redis cache, LightRAG knowledge graph engine, and MCP protocol compliance.

## Pre-Execution Validation

**CRITICAL**: Check if integration tests have already been executed and results documented BEFORE proceeding.

```bash
# Check if integration test results already exist
RESULTS_FILE="/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-results/integration-test-results.md"

if [ -f "$RESULTS_FILE" ]; then
    # Check if all integration tests passed
    if grep -q "Status: ✅ ALL INTEGRATION TESTS PASSED" "$RESULTS_FILE" 2>/dev/null; then
        echo "✅ VALIDATION RESULT: Integration tests already executed and PASSED"
        echo "ACTION: SKIP task execution - review existing results"
        exit 0
    else
        echo "⚠️ VALIDATION RESULT: Integration tests executed but FAILED or INCOMPLETE"
        echo "ACTION: RE-EXECUTE integration tests"
    fi
else
    echo "❌ VALIDATION RESULT: Integration tests not yet executed"
    echo "ACTION: PROCEED with test execution"
fi
```

**If Already Complete**: Skip to Validation section and verify existing results
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Integration testing is the THIRD mandatory phase (Phase 3 of 5) in test-driven deployment. These tests validate that the docling-mcp service successfully integrates with all external dependencies. This phase can only execute after functionality testing (Task 172) passes.

**Integration Points Tested**:
1. **LiteLLM Gateway** (hx-litellm-server.hx.dev.local:4000) - LLM routing for entity extraction
2. **Qdrant Vector Database** (hx-qdrant-server.hx.dev.local:6333) - Knowledge graph storage
3. **Redis Cache** (hx-redis-server.hx.dev.local:6379) - Session management and caching
4. **LightRAG Knowledge Graph Engine** (hx-literag-server.hx.dev.local:8000) - Entity/relationship extraction
5. **MCP Protocol Compliance** - HTTP/SSE/stdio transports

**Test Location**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/integration/`
**Test Count**: 5 test cases
**Execution Mode**: SEQUENTIAL (dependencies must be checked in order)

## Acceptance Criteria

- [ ] All 5 integration test cases executed
- [ ] Test results documented in `/tests/test-results/integration-test-results.md`
- [ ] All tests PASS (100% pass rate required)
- [ ] Integration point connectivity validated for all services
- [ ] Any test failures documented as defects using defect-template.md
- [ ] Test execution evidence captured (logs, timestamps, connectivity checks)

## Implementation Steps

### Step 1: Verify Functionality Tests Passed

```bash
# Verify prerequisite: functionality tests passed
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

if ! grep -q "Status: ✅ ALL FUNCTIONALITY TESTS PASSED" tests/test-results/functionality-test-results.md 2>/dev/null; then
    echo "❌ ERROR: Functionality tests have not passed"
    echo "Cannot proceed to integration testing until Task 172 completes successfully"
    exit 1
else
    echo "✅ Prerequisite verified: Functionality tests passed"
fi
```

### Step 2: Prepare Test Environment

```bash
# Navigate to test directory
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Verify service is running
systemctl is-active docling-mcp.service || {
    echo "❌ ERROR: docling-mcp.service not running"
    exit 1
}

# Verify external dependencies are reachable
echo "Checking external dependencies connectivity..."

# Check LiteLLM Gateway
if curl -s -f http://hx-litellm-server.hx.dev.local:4000/health >/dev/null 2>&1; then
    echo "✅ LiteLLM Gateway reachable"
else
    echo "⚠️ WARNING: LiteLLM Gateway not reachable - tests may fail"
fi

# Check Qdrant
if curl -s -f http://hx-qdrant-server.hx.dev.local:6333/collections >/dev/null 2>&1; then
    echo "✅ Qdrant reachable"
else
    echo "⚠️ WARNING: Qdrant not reachable - tests may fail"
fi

# Check Redis
if redis-cli -h hx-redis-server.hx.dev.local -p 6379 ping >/dev/null 2>&1; then
    echo "✅ Redis reachable"
else
    echo "⚠️ WARNING: Redis not reachable - tests may fail"
fi

# Check LightRAG
if curl -s -f http://hx-literag-server.hx.dev.local:8000/health >/dev/null 2>&1; then
    echo "✅ LightRAG reachable"
else
    echo "⚠️ WARNING: LightRAG not reachable - tests may fail"
fi

# Set execution timestamp
EXEC_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "Integration Test Execution Started: $EXEC_TIMESTAMP"
```

### Step 3: Execute Integration Test Suite

```bash
# Execute integration tests sequentially (MUST be sequential per testing standards)
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Run pytest for integration test suite
pytest tests/test-suite/integration/ \
    --verbose \
    --tb=short \
    --junitxml=tests/test-results/integration-results.xml \
    2>&1 | tee tests/test-results/integration-execution.log

# Capture exit code
INTEGRATION_EXIT_CODE=$?
echo "Integration Tests Exit Code: $INTEGRATION_EXIT_CODE"
```

### Step 4: Document Test Results

```bash
# Create integration test results document
cat > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-results/integration-test-results.md << 'EOF'
# Integration Test Results

**Service**: docling-mcp
**Test Phase**: Integration Testing (Phase 3 of 5)
**Execution Date**: $(date +"%Y-%m-%d")
**Execution Time**: $(date +"%H:%M:%S")
**Executed By**: julia-santos (Testing & Quality Specialist)

---

## Test Execution Summary

**Test Suite**: Integration Tests (5 Integration Points)
**Test Location**: `tests/test-suite/integration/`
**Execution Mode**: Sequential (dependency validation order)
**Total Test Cases**: 5
**Test Cases Executed**: [COUNT]
**Tests Passed**: [PASS_COUNT]
**Tests Failed**: [FAIL_COUNT]
**Pass Rate**: [PERCENTAGE]%

**Exit Code**: $INTEGRATION_EXIT_CODE
**Status**: [✅ ALL TESTS PASSED | ❌ TESTS FAILED]

---

## Individual Test Results

### TC-INT-001: LiteLLM Gateway Connection

**Status**: [PASS | FAIL]
**Integration Point**: hx-litellm-server.hx.dev.local:4000
**Test Objective**: Validate connectivity and model routing to LiteLLM Gateway

**Evidence**:
```
[Command output from connectivity test]
[Health check response]
[Model routing validation]
```

**Validation Checks**:
- [ ] HTTP connection successful
- [ ] Health endpoint responds
- [ ] Model routing configured correctly (gemma3:27b via Ollama)
- [ ] API authentication working (if applicable)
- [ ] Response time acceptable (<5 seconds)

**Notes**: [Any observations or issues]

---

### TC-INT-002: Qdrant Vector Database Connection

**Status**: [PASS | FAIL]
**Integration Point**: hx-qdrant-server.hx.dev.local:6333
**Test Objective**: Validate connectivity and collection access to Qdrant

**Evidence**:
```
[Command output from connectivity test]
[Collection list response]
[Collection initialization validation]
```

**Validation Checks**:
- [ ] HTTP connection successful
- [ ] Collections endpoint responds
- [ ] Required collections exist (hx_docling_mcp_entities, hx_docling_mcp_relationships)
- [ ] Collection schema matches specification
- [ ] Vector operations functional (insert, search)

**Notes**: [Any observations or issues]

---

### TC-INT-003: Redis Cache Connection

**Status**: [PASS | FAIL]
**Integration Point**: hx-redis-server.hx.dev.local:6379
**Test Objective**: Validate connectivity and caching operations with Redis

**Evidence**:
```
[Command output from connectivity test]
[PING/PONG response]
[Cache operations validation]
```

**Validation Checks**:
- [ ] TCP connection successful
- [ ] PING responds with PONG
- [ ] SET/GET operations functional
- [ ] Key expiration (TTL) working
- [ ] Connection pooling operational

**Notes**: [Any observations or issues]

---

### TC-INT-004: LightRAG Knowledge Graph Engine Integration

**Status**: [PASS | FAIL]
**Integration Point**: hx-literag-server.hx.dev.local:8000
**Test Objective**: Validate entity/relationship extraction via LightRAG HTTP API

**Evidence**:
```
[Command output from connectivity test]
[Entity extraction API response]
[Relationship extraction API response]
```

**Validation Checks**:
- [ ] HTTP connection successful
- [ ] Health endpoint responds
- [ ] Entity extraction endpoint functional
- [ ] Relationship extraction endpoint functional
- [ ] JSON response parsing successful
- [ ] Qdrant integration for storage working

**Notes**: [Any observations or issues]

---

### TC-INT-005: MCP Protocol Compliance

**Status**: [PASS | FAIL]
**Integration Point**: MCP protocol transports (HTTP/SSE/stdio)
**Test Objective**: Validate MCP protocol compliance across all transport modes

**Evidence**:
```
[HTTP transport validation]
[SSE transport validation]
[stdio transport validation]
[Tool discovery validation]
```

**Validation Checks**:
- [ ] HTTP transport operational (port 8000)
- [ ] SSE transport operational (long-lived connections)
- [ ] stdio transport operational (stdin/stdout)
- [ ] Tool discovery returns all 19 tools
- [ ] Tool invocation follows MCP protocol schema
- [ ] Error handling complies with MCP spec

**Notes**: [Any observations or issues]

---

## Dependency Health Summary

| Dependency | Hostname | Port | Status | Response Time |
|------------|----------|------|--------|---------------|
| LiteLLM Gateway | hx-litellm-server.hx.dev.local | 4000 | [UP/DOWN] | [N ms] |
| Qdrant | hx-qdrant-server.hx.dev.local | 6333 | [UP/DOWN] | [N ms] |
| Redis | hx-redis-server.hx.dev.local | 6379 | [UP/DOWN] | [N ms] |
| LightRAG | hx-literag-server.hx.dev.local | 8000 | [UP/DOWN] | [N ms] |

---

## Defects Identified

[If any tests failed, create defect tickets using defect-template.md and reference them here]

**Defect Count**: [N]
**Defect References**: [Links to defect tickets]

---

## Quality Gate Status

**Integration Testing Gate**: [✅ PASS | ❌ FAIL]

**Gate Criteria**:
- [✅/❌] All 5 integration tests executed
- [✅/❌] 100% test pass rate achieved
- [✅/❌] LiteLLM connectivity validated
- [✅/❌] Qdrant connectivity validated
- [✅/❌] Redis connectivity validated
- [✅/❌] LightRAG connectivity validated
- [✅/❌] MCP protocol compliance validated
- [✅/❌] No blocking defects identified

**Decision**: [PROCEED to Task 174 (Health Check Tests) | BLOCK until defects resolved]

---

## Evidence Artifacts

- Pytest XML results: `tests/test-results/integration-results.xml`
- Execution log: `tests/test-results/integration-execution.log`
- Connectivity test logs: `tests/test-results/integration-evidence/`

---

**Test Execution Complete**: $(date +"%Y-%m-%d %H:%M:%S")
**Next Phase**: Health Check Testing (Task 174)

EOF

echo "✅ Integration test results documented"
```

### Step 5: Analyze Test Results and Create Defects (If Needed)

```bash
# Parse pytest results for failures
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Check for test failures
if [ $INTEGRATION_EXIT_CODE -ne 0 ]; then
    echo "❌ INTEGRATION TESTS FAILED - Creating defect tickets"

    # Extract failed test names from pytest output
    grep -E "FAILED|ERROR" tests/test-results/integration-execution.log > tests/test-results/failed-integration-tests.txt

    echo "⚠️ ACTION REQUIRED: Review failed tests and create defect tickets"
    echo "Failed tests logged to: tests/test-results/failed-integration-tests.txt"
    echo "Use defect-template.md to create defect tickets for each failure"

    # Check which dependencies are down
    echo "Checking dependency health..."
    for dep in "hx-litellm-server.hx.dev.local:4000" "hx-qdrant-server.hx.dev.local:6333" "hx-literag-server.hx.dev.local:8000"; do
        if ! curl -s -f "http://$dep/health" >/dev/null 2>&1; then
            echo "❌ $dep is NOT responding"
        fi
    done

    exit 1
else
    echo "✅ ALL INTEGRATION TESTS PASSED"
    echo "Proceeding to quality gate validation"
fi
```

## Validation

**Validation Commands:**

```bash
# Verify test results file exists and is complete
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# 1. Check results file exists
if [ -f "tests/test-results/integration-test-results.md" ]; then
    echo "✅ Test results file created"
else
    echo "❌ Test results file missing"
    exit 1
fi

# 2. Verify all 5 tests were executed
TEST_COUNT=$(grep -c "^### TC-INT-" tests/test-results/integration-test-results.md)
if [ "$TEST_COUNT" -eq 5 ]; then
    echo "✅ All 5 integration tests documented"
else
    echo "❌ Only $TEST_COUNT tests documented (expected 5)"
    exit 1
fi

# 3. Verify pytest execution completed
if [ -f "tests/test-results/integration-results.xml" ]; then
    echo "✅ Pytest XML results generated"
else
    echo "❌ Pytest XML results missing"
    exit 1
fi

# 4. Check pass/fail status
if grep -q "Status: ✅ ALL INTEGRATION TESTS PASSED" tests/test-results/integration-test-results.md; then
    echo "✅ All integration tests PASSED"
    echo "✅ QUALITY GATE: PASS - Proceed to Task 174 (Health Check Tests)"
    exit 0
else
    echo "❌ Some integration tests FAILED"
    echo "❌ QUALITY GATE: FAIL - BLOCK until defects resolved"
    exit 1
fi
```

**Expected Output:**
```
✅ Test results file created
✅ All 5 integration tests documented
✅ Pytest XML results generated
✅ All integration tests PASSED
✅ QUALITY GATE: PASS - Proceed to Task 174 (Health Check Tests)
```

## Notes

### Sequential Execution Requirement

Integration tests MUST run sequentially because:
- Dependency validation should occur in logical order
- Some tests may establish state needed by later tests
- Network connectivity issues are easier to diagnose sequentially
- Test execution time is short (~15-20 minutes), parallelization not needed

### External Dependency Failures

If integration tests fail due to external dependency issues:
1. **NOT a service defect** - Document as infrastructure issue
2. **Coordinate with infrastructure team** (william-chen) to resolve
3. **Re-run tests** after dependency restored
4. **Do NOT proceed** to Task 174 until all dependencies healthy

### MCP Protocol Compliance Critical

TC-INT-005 (MCP Protocol Compliance) is CRITICAL:
- Validates service exposes 19 tools correctly
- Confirms protocol adherence (tool discovery, invocation, error handling)
- Failure here blocks all downstream AI agent integration use cases

### Defect Severity for Integration Failures

Integration test failures should be classified as:
- **CRITICAL**: Core dependencies unreachable (LiteLLM, Qdrant, Redis) or MCP protocol non-compliant
- **HIGH**: Intermittent connectivity issues or degraded performance
- **MEDIUM**: Edge case failures or timeout issues

## References

- Test Plan: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md`
- Test Suite Index: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite-index.md`
- Integration Test Cases: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/integration/`
- Defect Template: `/home/agent0/HX-Infrastructure/templates/testing/defect-template.md`
- Architecture: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/deployment-architecture.md`

## Risk Assessment

**Risk**: CRITICAL

**Rationale**: Integration testing validates connectivity with ALL external dependencies. Failures here indicate the service cannot fulfill its core mission of knowledge graph generation and document processing.

**Mitigation Steps**:
1. Pre-flight connectivity checks before test execution
2. Capture comprehensive evidence for each integration point
3. Document failures with full network diagnostics
4. Coordinate with infrastructure team for dependency issues
5. Re-execute complete suite after any fixes
6. Verify quality gate before proceeding to Task 174
