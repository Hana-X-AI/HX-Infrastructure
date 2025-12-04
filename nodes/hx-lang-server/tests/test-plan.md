# Test Plan: hx-lang-server

**Service**: hx-lang-server
**Created**: 2025-12-04
**Status**: APPROVED
**Based on Spec**: `specification/node-spec.md` version 2.1
**Test Lead**: Julia Santos (Testing & Quality Specialist)

---

## Test Plan Overview

### Purpose

This test plan defines the comprehensive testing strategy for the hx-lang-server LangGraph orchestration service. It ensures 100% coverage of all functional requirements, success criteria, and integration points before operational promotion.

### Scope

**In Scope:**
- Deployment validation (infrastructure, dependencies, service startup)
- Core functionality (LangGraph supervisor, worker agents, query routing)
- API endpoints (/invoke, /stream, /health, /ready, sessions)
- Integration testing (PostgreSQL, Redis, Ollama, LightRAG, MCP)
- Health check and monitoring validation
- End-to-end workflow testing
- Performance validation against SLAs

**Out of Scope:**
- n8n integration (Phase 2 - separate test plan)
- Custom n8n node testing
- Production load testing (development environment)
- Security penetration testing

### Test Objectives

1. Verify deployment meets all requirements in `specification/node-spec.md`
2. Validate all 28 functional requirements (FR-001 through FR-028)
3. Validate all 14 success criteria (SC-001 through SC-014)
4. Validate all 5 non-functional requirements (NFR-001 through NFR-005)
5. Ensure service is operational and stable (24-hour stability test)
6. Confirm all integration points function correctly
7. Validate API response times meet SLAs

---

## Test Strategy

### Test Approach

**Test-Driven Deployment:**
- All 78 test cases written BEFORE deployment execution
- Tests must initially FAIL (service not deployed yet)
- Deploy service following `tasks/`
- Run tests - must PASS for operational promotion
- Document results with timestamps and evidence

### Test Levels

#### 1. Deployment Validation Tests (14 tests)

**Purpose**: Verify deployment executed correctly per deployment plan

**Coverage:**
- Service account creation and authentication
- DNS record registration and resolution
- Directory structure and permissions
- Python virtual environment and dependencies
- System dependencies and packages
- Service installation and configuration
- systemd service unit configuration
- Environment file configuration
- Log directory and rotation setup
- Port binding and network accessibility
- Rollback procedure validation

**Test Area Directory**: `tests/test-suite/deployment/`

#### 2. Functionality Tests (25 tests)

**Purpose**: Verify service meets all functional requirements from specification

**Coverage:**
- FR-001: LangGraph supervisor pattern implementation
- FR-002: Worker agent types (RAG, Code, Tool)
- FR-003: Query classification and routing
- FR-004: Human-in-the-loop interrupts
- FR-005: Graph recursion limits
- FR-006: PostgreSQL checkpoint persistence
- FR-007: Redis session caching
- FR-008: Conversation continuation
- FR-009: State schema versioning
- FR-010 to FR-013: Ollama routing and context validation
- FR-014 to FR-016: LightRAG integration
- FR-017 to FR-020a: MCP client integration
- FR-021 to FR-025: API requirements
- Error handling and edge cases

**Test Area Directory**: `tests/test-suite/functionality/`

#### 3. Integration Tests (20 tests)

**Purpose**: Verify service integrates with all external dependencies

**Coverage:**
- PostgreSQL connection and checkpoint operations
- Redis connection and session management
- Ollama1 (general) model connectivity and routing
- Ollama2 (code) model connectivity and routing
- LightRAG HTTP API integration
- LightRAG query modes (local, global, hybrid, mix)
- FastMCP gateway connection
- MCP tool discovery and invocation
- Qdrant vector storage (via LightRAG)
- Circuit breaker and retry logic
- Graceful degradation scenarios

**Test Area Directory**: `tests/test-suite/integration/`

#### 4. Health Check Tests (9 tests)

**Purpose**: Verify ongoing operational health

**Coverage:**
- SC-010: Health endpoint returns 200
- SC-011: Ready endpoint validates all dependencies
- Health endpoint response time
- Dependency status reporting
- Metrics endpoint functionality
- Resource usage monitoring
- Log output validation
- Service restart recovery
- Graceful shutdown behavior

**Test Area Directory**: `tests/test-suite/health-check/`

#### 5. End-to-End Tests (10 tests)

**Purpose**: Verify complete workflow scenarios

**Coverage:**
- SC-002: LangGraph supervisor functional
- SC-003: PostgreSQL checkpointing functional
- SC-004: LightRAG integration functional
- SC-005: Ollama model routing functional
- SC-006: Redis session management functional
- SC-007: 64KB context handling verified
- SC-008: MCP tool invocation functional
- SC-009: Session persistence across restarts
- SC-012: Response latency <2s for simple queries
- SC-013: 10 concurrent sessions supported
- Complete RAG workflow (query -> retrieval -> response)
- Complete code workflow (code query -> code agent -> response)
- Complete tool workflow (tool query -> MCP -> response)
- Multi-turn conversation with checkpointing

**Test Area Directory**: `tests/test-suite/e2e/`

---

## Test Environment

### Target Node

**Node**: hx-lang-server.hx.dev.local
**IP Address**: 192.168.10.226
**OS**: Ubuntu 24.04 LTS
**Resources Available**:
- CPU: 4 cores minimum (8 recommended)
- Memory: 16GB RAM minimum
- Storage: 50GB

### Environment Configuration

**Network**: HX internal network (192.168.10.0/24)
**Ports Required**: 8100 (API), 8101 (Health/Metrics)

**Dependencies Required for Testing:**
| Service | Hostname | Port | Status Required |
|---------|----------|------|-----------------|
| PostgreSQL | hx-postgres-server.hx.dev.local | 5432 | Running |
| Redis | hx-redis-server.hx.dev.local | 6379 | Running |
| Ollama (General) | hx-ollama1-server.hx.dev.local | 11434 | Running |
| Ollama (Code) | hx-ollama2-server.hx.dev.local | 11434 | Running |
| LightRAG | hx-literag-server.hx.dev.local | 8020 | Running |
| FastMCP | hx-fastmcp-server.hx.dev.local | 8000 | Running |
| Qdrant | hx-qdrant-server.hx.dev.local | 6333 | Running |

### Test Data Requirements

- Sample text queries for query classification testing
- Sample code queries for code agent testing
- Sample RAG queries with known document contexts
- Sample tool invocation requests
- Test session IDs and thread IDs
- Test webhook URLs for callback testing

---

## Test Coverage

### Requirements Traceability Matrix

#### Functional Requirements Coverage

| Requirement ID | Description | Test Case ID(s) | Priority |
|---------------|-------------|-----------------|----------|
| FR-001 | LangGraph supervisor pattern | tc-lang-server-functionality-001 | P1 |
| FR-002 | Worker agent types (RAG, Code, Tool) | tc-lang-server-functionality-002, 003, 004 | P1 |
| FR-003 | Query routing | tc-lang-server-functionality-005 | P1 |
| FR-004 | Human-in-the-loop | tc-lang-server-functionality-006 | P2 |
| FR-005 | Recursion limits | tc-lang-server-functionality-007 | P2 |
| FR-006 | PostgreSQL checkpoints | tc-lang-server-functionality-008 | P1 |
| FR-007 | Redis session caching | tc-lang-server-functionality-009 | P1 |
| FR-008 | Conversation continuation | tc-lang-server-functionality-010 | P1 |
| FR-009 | State schema versioning | tc-lang-server-functionality-011 | P2 |
| FR-010 | Ollama1 general routing | tc-lang-server-functionality-012 | P1 |
| FR-011 | Ollama2 code routing | tc-lang-server-functionality-013 | P1 |
| FR-012 | Embedding via LightRAG | tc-lang-server-functionality-014 | P1 |
| FR-013 | 64KB context validation | tc-lang-server-functionality-015 | P1 |
| FR-014 | LightRAG HTTP integration | tc-lang-server-functionality-016 | P1 |
| FR-015 | Adaptive retrieval | tc-lang-server-functionality-017 | P2 |
| FR-016 | LightRAG query modes | tc-lang-server-functionality-018 | P2 |
| FR-017 | MCP client implementation | tc-lang-server-functionality-019 | P1 |
| FR-018 | FastMCP gateway connection | tc-lang-server-functionality-020 | P1 |
| FR-019 | Tool discovery/invocation | tc-lang-server-functionality-021 | P1 |
| FR-020 | Tool namespace handling | tc-lang-server-functionality-022 | P2 |
| FR-020a | MCP v1.1 feature detection | tc-lang-server-functionality-023 | P2 |
| FR-021 | FastAPI on port 8100 | tc-lang-server-deployment-008 | P1 |
| FR-022 | Async endpoints | tc-lang-server-functionality-024 | P1 |
| FR-023 | Webhook callbacks | tc-lang-server-functionality-025 | P2 |
| FR-024 | Health check endpoint | tc-lang-server-health-001 | P1 |
| FR-025 | OpenAPI documentation | tc-lang-server-deployment-012 | P2 |
| FR-026 | n8n HTTP endpoint | Phase 2 - Not in scope | P3 |
| FR-027 | Webhook callback registration | Phase 2 - Not in scope | P3 |
| FR-028 | thread_id for n8n | Phase 2 - Not in scope | P3 |

#### Success Criteria Coverage

| Success Criteria | Description | Test Case ID(s) | Threshold |
|-----------------|-------------|-----------------|-----------|
| SC-001 | System up Ubuntu 24.04 Python 3.11+ | tc-lang-server-deployment-001, 002 | PASS/FAIL |
| SC-002 | LangGraph supervisor functional | tc-lang-server-e2e-001 | PASS/FAIL |
| SC-003 | PostgreSQL checkpointing functional | tc-lang-server-e2e-002 | PASS/FAIL |
| SC-004 | LightRAG integration functional | tc-lang-server-e2e-003 | PASS/FAIL |
| SC-005 | Ollama model routing functional | tc-lang-server-e2e-004 | PASS/FAIL |
| SC-006 | Redis session management functional | tc-lang-server-e2e-005 | PASS/FAIL |
| SC-007 | 64KB context handling verified | tc-lang-server-e2e-006 | PASS/FAIL |
| SC-008 | MCP tool invocation functional | tc-lang-server-e2e-007 | PASS/FAIL |
| SC-009 | Session persistence across restarts | tc-lang-server-e2e-008 | PASS/FAIL |
| SC-010 | Health endpoint returns 200 | tc-lang-server-health-001 | 200 OK |
| SC-011 | Ready endpoint validates deps | tc-lang-server-health-002 | PASS/FAIL |
| SC-012 | Response latency <2s | tc-lang-server-e2e-009 | <2000ms |
| SC-013 | 10 concurrent sessions | tc-lang-server-e2e-010 | 10 sessions |
| SC-014 | systemd service stable 24h | tc-lang-server-deployment-014 | 0 failures |

#### Non-Functional Requirements Coverage

| NFR ID | Description | Test Case ID(s) | Threshold |
|--------|-------------|-----------------|-----------|
| NFR-001 | API response <5s (95th percentile) | tc-lang-server-e2e-009 | <5000ms |
| NFR-002 | Checkpoint latency <100ms | tc-lang-server-integration-001 | <100ms |
| NFR-003 | Startup time <30s | tc-lang-server-deployment-004 | <30s |
| NFR-004 | Memory usage <12GB | tc-lang-server-health-005 | <12GB |
| NFR-005 | 10 concurrent sessions | tc-lang-server-e2e-010 | 10 sessions |

---

## Test Cases Summary

### Deployment Validation Tests (14 tests)

| Test ID | Test Name | Priority |
|---------|-----------|----------|
| tc-lang-server-deployment-001 | Verify Service Account Creation | P1 |
| tc-lang-server-deployment-002 | Verify Python Installation | P1 |
| tc-lang-server-deployment-003 | Verify Directory Structure | P1 |
| tc-lang-server-deployment-004 | Verify Service Startup | P1 |
| tc-lang-server-deployment-005 | Verify Virtual Environment | P1 |
| tc-lang-server-deployment-006 | Verify Python Dependencies | P1 |
| tc-lang-server-deployment-007 | Verify Configuration Files | P1 |
| tc-lang-server-deployment-008 | Verify Port Binding | P1 |
| tc-lang-server-deployment-009 | Verify systemd Service Unit | P1 |
| tc-lang-server-deployment-010 | Verify Environment File | P1 |
| tc-lang-server-deployment-011 | Verify Log Configuration | P1 |
| tc-lang-server-deployment-012 | Verify OpenAPI Documentation | P2 |
| tc-lang-server-deployment-013 | Verify DNS Resolution | P1 |
| tc-lang-server-deployment-014 | Verify 24h Service Stability | P1 |

### Functionality Tests (25 tests)

| Test ID | Test Name | FR Coverage | Priority |
|---------|-----------|-------------|----------|
| tc-lang-server-functionality-001 | Supervisor Pattern | FR-001 | P1 |
| tc-lang-server-functionality-002 | RAG Agent Worker | FR-002 | P1 |
| tc-lang-server-functionality-003 | Code Agent Worker | FR-002 | P1 |
| tc-lang-server-functionality-004 | Tool Agent Worker | FR-002 | P1 |
| tc-lang-server-functionality-005 | Query Classification | FR-003 | P1 |
| tc-lang-server-functionality-006 | Human-in-the-Loop | FR-004 | P2 |
| tc-lang-server-functionality-007 | Recursion Limits | FR-005 | P2 |
| tc-lang-server-functionality-008 | PostgreSQL Checkpoints | FR-006 | P1 |
| tc-lang-server-functionality-009 | Redis Session Caching | FR-007 | P1 |
| tc-lang-server-functionality-010 | Conversation Continuation | FR-008 | P1 |
| tc-lang-server-functionality-011 | State Schema Versioning | FR-009 | P2 |
| tc-lang-server-functionality-012 | Ollama1 General Routing | FR-010 | P1 |
| tc-lang-server-functionality-013 | Ollama2 Code Routing | FR-011 | P1 |
| tc-lang-server-functionality-014 | Embedding via LightRAG | FR-012 | P1 |
| tc-lang-server-functionality-015 | 64KB Context Validation | FR-013 | P1 |
| tc-lang-server-functionality-016 | LightRAG HTTP Integration | FR-014 | P1 |
| tc-lang-server-functionality-017 | Adaptive Retrieval | FR-015 | P2 |
| tc-lang-server-functionality-018 | LightRAG Query Modes | FR-016 | P2 |
| tc-lang-server-functionality-019 | MCP Client Implementation | FR-017 | P1 |
| tc-lang-server-functionality-020 | FastMCP Gateway Connection | FR-018 | P1 |
| tc-lang-server-functionality-021 | Tool Discovery Invocation | FR-019 | P1 |
| tc-lang-server-functionality-022 | Tool Namespace Handling | FR-020 | P2 |
| tc-lang-server-functionality-023 | MCP v1.1 Feature Detection | FR-020a | P2 |
| tc-lang-server-functionality-024 | Async Endpoints | FR-022 | P1 |
| tc-lang-server-functionality-025 | Webhook Callbacks | FR-023 | P2 |

### Integration Tests (20 tests)

| Test ID | Test Name | Integration Point | Priority |
|---------|-----------|-------------------|----------|
| tc-lang-server-integration-001 | PostgreSQL Connection | PostgreSQL | P1 |
| tc-lang-server-integration-002 | PostgreSQL Checkpoint Write | PostgreSQL | P1 |
| tc-lang-server-integration-003 | PostgreSQL Checkpoint Read | PostgreSQL | P1 |
| tc-lang-server-integration-004 | Redis Connection | Redis | P1 |
| tc-lang-server-integration-005 | Redis Session Write | Redis | P1 |
| tc-lang-server-integration-006 | Redis Session Read | Redis | P1 |
| tc-lang-server-integration-007 | Redis TTL Expiration | Redis | P2 |
| tc-lang-server-integration-008 | Ollama1 Connection | Ollama | P1 |
| tc-lang-server-integration-009 | Ollama2 Connection | Ollama | P1 |
| tc-lang-server-integration-010 | Ollama Model Inference | Ollama | P1 |
| tc-lang-server-integration-011 | LightRAG Connection | LightRAG | P1 |
| tc-lang-server-integration-012 | LightRAG Query Execution | LightRAG | P1 |
| tc-lang-server-integration-013 | LightRAG Document Ingestion | LightRAG | P2 |
| tc-lang-server-integration-014 | FastMCP Connection | FastMCP | P1 |
| tc-lang-server-integration-015 | MCP Tool Discovery | FastMCP | P1 |
| tc-lang-server-integration-016 | MCP Tool Invocation | FastMCP | P1 |
| tc-lang-server-integration-017 | Circuit Breaker Activation | All | P2 |
| tc-lang-server-integration-018 | Retry Logic Validation | All | P2 |
| tc-lang-server-integration-019 | Graceful Degradation | All | P2 |
| tc-lang-server-integration-020 | Connection Pool Management | Redis | P2 |

### Health Check Tests (9 tests)

| Test ID | Test Name | SC Coverage | Priority |
|---------|-----------|-------------|----------|
| tc-lang-server-health-001 | Health Endpoint Response | SC-010 | P1 |
| tc-lang-server-health-002 | Ready Endpoint Dependencies | SC-011 | P1 |
| tc-lang-server-health-003 | Health Response Time | SC-010 | P1 |
| tc-lang-server-health-004 | Dependency Status Reporting | SC-011 | P1 |
| tc-lang-server-health-005 | Resource Usage Monitoring | NFR-004 | P1 |
| tc-lang-server-health-006 | Metrics Endpoint | - | P2 |
| tc-lang-server-health-007 | Log Output Validation | - | P1 |
| tc-lang-server-health-008 | Service Restart Recovery | - | P1 |
| tc-lang-server-health-009 | Graceful Shutdown | - | P2 |

### End-to-End Tests (10 tests)

| Test ID | Test Name | SC Coverage | Priority |
|---------|-----------|-------------|----------|
| tc-lang-server-e2e-001 | Supervisor Workflow | SC-002 | P1 |
| tc-lang-server-e2e-002 | PostgreSQL Checkpoint Workflow | SC-003 | P1 |
| tc-lang-server-e2e-003 | LightRAG RAG Workflow | SC-004 | P1 |
| tc-lang-server-e2e-004 | Ollama Routing Workflow | SC-005 | P1 |
| tc-lang-server-e2e-005 | Redis Session Workflow | SC-006 | P1 |
| tc-lang-server-e2e-006 | 64KB Context Workflow | SC-007 | P1 |
| tc-lang-server-e2e-007 | MCP Tool Workflow | SC-008 | P1 |
| tc-lang-server-e2e-008 | Session Persistence Restart | SC-009 | P1 |
| tc-lang-server-e2e-009 | Response Latency Validation | SC-012, NFR-001 | P1 |
| tc-lang-server-e2e-010 | Concurrent Sessions | SC-013, NFR-005 | P1 |

**Total Test Cases**: 14 + 25 + 20 + 9 + 10 = **78 tests**

---

## Test Execution Strategy

### Execution Order

1. **Deployment Validation Tests** - MUST ALL PASS before proceeding
2. **Health Check Tests** - Verify service operational before functional testing
3. **Integration Tests** - Verify external dependencies connected
4. **Functionality Tests** - Core capabilities validation
5. **End-to-End Tests** - Complete workflow validation

### Parallel Execution

- Tests within same test area may run in parallel if independent
- Integration tests should run sequentially to avoid resource contention
- E2E tests must run sequentially (state dependencies)

### Pass/Fail Criteria

**Individual Test**:
- **PASS**: All expected results achieved, no errors
- **FAIL**: Any expected result not achieved OR errors occurred
- **BLOCKED**: Cannot execute due to dependency failure

**Test Suite**:
- **PASS**: ALL tests pass (78/78)
- **FAIL**: ANY test fails
- **BLOCKED**: ANY test blocked

### Promotion Criteria

Service can be promoted from non-operational to operational when:
- [ ] ALL 14 deployment validation tests PASS
- [ ] ALL 25 functionality tests PASS
- [ ] ALL 20 integration tests PASS
- [ ] ALL 9 health check tests PASS
- [ ] ALL 10 end-to-end tests PASS
- [ ] NO critical or high severity defects
- [ ] Test results documented in `tests/test-results/`
- [ ] 24-hour stability test completed (SC-014)

---

## Quality Gates

### Gate 1: Deployment Validation
- All 14 deployment tests pass
- Service starts and responds to health check
- All dependencies installed correctly

### Gate 2: Integration Validation
- All 20 integration tests pass
- All external services connected
- Data flows correctly between services

### Gate 3: Functionality Validation
- All 25 functionality tests pass
- All functional requirements verified
- Error handling works correctly

### Gate 4: Health & Performance
- All 9 health check tests pass
- Response times meet SLAs
- Resource usage within limits

### Gate 5: End-to-End Validation
- All 10 E2E tests pass
- Complete workflows execute correctly
- Session persistence verified

### Gate 6: Operational Readiness
- 24-hour stability test passed
- All documentation complete
- No outstanding critical/high defects

---

## Defect Management

### Defect Tracking

- All defects logged in `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/defects/`
- Naming: `defect-lang-server-[severity]-[seq]-[description].md`
- Use defect template for consistency

### Severity Definitions

**Critical**: Service completely non-functional, data loss, security breach
**High**: Major functionality broken, significant operational impact
**Medium**: Functionality impaired, workaround available
**Low**: Minor issue, cosmetic, enhancement

### Defect Resolution Requirements

- **Critical/High**: MUST be resolved before operational promotion
- **Medium**: Should be resolved, may accept with documented justification
- **Low**: Can be backlogged

---

## Test Deliverables

### Test Artifacts

- [x] Test plan (this document)
- [x] Test cases in `tests/test-suite/[area]/` (78 test cases created)
- [ ] Test results in `tests/test-results/`
- [ ] Defects logged in `defects/`
- [ ] Test summary report
- [x] Test execution tracking document (`tests/test-execution-tracking.md`)

### Documentation Updates

- [ ] Update test-execution-tracking.md with results
- [ ] Update service status after all tests pass
- [ ] Document lessons learned

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| External service unavailable | High | Medium | Mock services for isolated testing; document dependency on service availability |
| LangGraph v0.3.x API changes | High | Low | Pin exact version; test early in deployment |
| Ollama model context limitations | High | Medium | Validate 64KB support before integration testing |
| PostgreSQL connection pool exhaustion | Medium | Low | Monitor connections; implement proper cleanup |
| Redis session expiration during tests | Medium | Medium | Set appropriate TTLs for test environment |
| Test environment resource constraints | Medium | Low | Monitor resource usage; clean up between tests |

---

## Test Metrics

### Metrics to Track

- Total test cases planned: 78
- Test cases created: 78 (100%)
- Test cases executed: [TBD]
- Pass rate (% passed / total executed): [TBD]
- Defects found by severity: [TBD]
- Defects resolved: [TBD]
- Test coverage (requirements covered): 100%
- Time to execute test suite: [TBD]

### Success Metrics

- **Pass Rate**: 100% (all 78 tests must pass)
- **Requirements Coverage**: 100% (all FR, SC, NFR covered)
- **Critical/High Defects**: 0 (none unresolved)

---

## Test Tools and Resources

### Tools Required

- curl - HTTP API testing
- jq - JSON parsing and validation
- psql - PostgreSQL connectivity testing
- redis-cli - Redis connectivity testing
- systemctl - Service management
- journalctl - Log inspection
- netstat/ss - Network connectivity
- time - Command timing

### Personnel

- Test Creator: Julia Santos (Testing & Quality Specialist)
- Test Executor: Julia Santos / Operations Team
- Defect Tracker: Julia Santos
- Approval Authority: Agent Zero (CAIO)

---

## Approval and Sign-off

### Review

- [ ] Test plan reviewed by infrastructure team
- [ ] Test coverage verified against specification
- [ ] Test approach approved

### Approval

**Approved By**: [Pending]
**Date**: [Pending]
**Signature**: [Pending]

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-04 | Julia Santos | Initial test plan with 78 test cases |

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
**Repository**: HX-Infrastructure
