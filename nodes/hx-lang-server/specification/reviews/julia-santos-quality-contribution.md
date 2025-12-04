# Specification Contribution: Julia Santos (Testing & Quality Specialist)

**Contribution Date:** 2025-12-01
**Specification Version:** 1.0
**Contributor Role:** Testing & Quality Specialist (Core Team SME)
**Focus Areas:** Multi-Agent Testing Strategy, Quality Gates, Test Coverage, Success Criteria Testability

---

## Executive Summary

This contribution provides comprehensive testing and quality assurance specifications for hx-lang-server, addressing the unique challenges of multi-agent orchestration testing identified in my charter review. The specification draft (v1.0) includes a Testing Strategy section (lines 844-885) but lacks the depth required for supervisor-worker pattern validation, deterministic multi-agent testing, and complete quality gate definitions.

This contribution delivers:
1. **Multi-Agent Test Strategy** - Comprehensive patterns for testing LangGraph supervisor-worker architectures
2. **Test Coverage Matrix** - 100% requirements coverage mapping with 78+ test cases
3. **Quality Gates** - Explicit phase transition criteria with metrics and evidence requirements
4. **Success Criteria Testability** - Detailed validation specifications for each SC-xxx
5. **Test Case Specifications** - Complete test case templates for critical test scenarios
6. **Specification Corrections** - Testing-related gaps and corrections to node-spec.md

---

## 1. Multi-Agent Test Strategy

### 1.1 Multi-Agent Test Architecture

The LangGraph supervisor-worker pattern requires a **layered testing approach** that validates behavior at each abstraction level:

```
                    TEST PYRAMID FOR MULTI-AGENT SYSTEMS

                              /\
                             /  \
                            / E2E \           <- Full workflow tests (8 tests)
                           /  Tests \            - Complete user journeys
                          /----------\           - Cross-agent state consistency
                         /  Workflow   \      <- Multi-agent interaction tests (12 tests)
                        /    Tests      \        - Supervisor routing validation
                       /                  \      - Worker handoff sequences
                      /--------------------\
                     /   Integration Tests   \ <- External service tests (16 tests)
                    /    (Service Boundary)   \   - Ollama connectivity
                   /                            \  - PostgreSQL checkpoints
                  /------------------------------\ - LightRAG integration
                 /      Agent Unit Tests           \
                /        (Node Functions)           \ <- Individual agent tests (20 tests)
               /                                      \  - Query classifier
              /----------------------------------------\  - Worker agent logic
             /           State Unit Tests               \ <- State management tests (12 tests)
            /            (Reducers, Schema)              \  - State schema validation
           /                                              \  - Reducer functions
          /------------------------------------------------\
         /               Infrastructure Tests                \ <- Base deployment tests (10 tests)
        /                 (systemd, bare metal)               \
       /----------------------------------------------------\
```

### 1.2 Multi-Agent Testing Patterns

#### Pattern 1: Deterministic Agent Execution

**Challenge:** LLM responses are non-deterministic, making test assertions difficult.

**Solution:** Implement a **mock LLM provider** for unit and integration tests:

```python
# tests/conftest.py - Pytest fixtures for deterministic testing

import pytest
from unittest.mock import AsyncMock, MagicMock
from typing import AsyncIterator

class DeterministicLLMProvider:
    """Mock LLM provider with deterministic responses for testing."""

    def __init__(self, response_map: dict[str, str]):
        self.response_map = response_map
        self.call_history: list[dict] = []

    async def ainvoke(self, prompt: str, **kwargs) -> str:
        """Return deterministic response based on keyword matching."""
        self.call_history.append({"prompt": prompt, **kwargs})

        for keyword, response in self.response_map.items():
            if keyword.lower() in prompt.lower():
                return response

        return self.response_map.get("default", "Mock response")

@pytest.fixture
def deterministic_llm():
    """Fixture providing deterministic LLM for agent tests."""
    return DeterministicLLMProvider({
        "code": "Here is the Python code: def example(): pass",
        "search": "Based on the retrieved documents...",
        "crawl": "I will use the crawl tool to fetch...",
        "default": "I understand your query."
    })

@pytest.fixture
def mock_ollama_client(deterministic_llm):
    """Fixture providing mock Ollama client."""
    client = AsyncMock()
    client.ainvoke = deterministic_llm.ainvoke
    return client
```

#### Pattern 2: State Transition Testing

**Challenge:** Validating state transitions across supervisor-worker handoffs.

**Solution:** Implement **state snapshots** at each graph node:

```python
# tests/utils/state_inspector.py

from typing import Any, Callable
from langgraph.graph import StateGraph

class StateInspector:
    """Captures and validates state at each node in the graph."""

    def __init__(self):
        self.state_snapshots: list[dict] = []
        self.node_sequence: list[str] = []

    def capture_state(self, node_name: str, state: dict) -> dict:
        """Capture state snapshot after node execution."""
        snapshot = {
            "node": node_name,
            "timestamp": time.time(),
            "state": copy.deepcopy(state)
        }
        self.state_snapshots.append(snapshot)
        self.node_sequence.append(node_name)
        return state

    def wrap_node(self, node_name: str, node_func: Callable) -> Callable:
        """Wrap node function to capture state."""
        async def wrapped(state: dict) -> dict:
            result = await node_func(state)
            self.capture_state(node_name, result)
            return result
        return wrapped

    def assert_node_sequence(self, expected: list[str]):
        """Assert nodes executed in expected order."""
        assert self.node_sequence == expected, \
            f"Expected sequence {expected}, got {self.node_sequence}"

    def assert_state_at_node(self, node_name: str, assertions: dict):
        """Assert state values at specific node."""
        for snapshot in self.state_snapshots:
            if snapshot["node"] == node_name:
                for key, expected in assertions.items():
                    actual = snapshot["state"].get(key)
                    assert actual == expected, \
                        f"At node {node_name}: {key}={actual}, expected {expected}"
                return
        raise AssertionError(f"Node {node_name} not found in sequence")
```

#### Pattern 3: Supervisor Routing Validation

**Challenge:** Ensuring supervisor correctly routes queries to appropriate workers.

**Solution:** **Routing Decision Tests** with explicit classification verification:

```python
# tests/unit/test_query_classifier.py

import pytest
from app.agents.classifier import QueryClassifier

class TestQueryClassifier:
    """Unit tests for query classification logic."""

    @pytest.fixture
    def classifier(self):
        return QueryClassifier()

    @pytest.mark.parametrize("query,expected_type", [
        # Code queries -> Ollama2
        ("Write a Python function to sort a list", "code"),
        ("Debug this JavaScript error", "code"),
        ("Implement a REST API endpoint", "code"),
        ("Fix the SQL query syntax", "code"),

        # RAG queries -> LightRAG
        ("What is the company policy on PTO?", "rag"),
        ("Search for documentation about deployment", "rag"),
        ("Find information about security protocols", "rag"),
        ("Explain how the authentication system works", "rag"),

        # Tool queries -> MCP
        ("Crawl this website for documentation", "tool"),
        ("Fetch the content from this URL", "tool"),
        ("Scrape the product page", "tool"),

        # General queries -> Ollama1
        ("Hello, how are you?", "general"),
        ("Tell me a joke", "general"),
        ("What is the weather like?", "general"),
    ])
    def test_query_classification(self, classifier, query, expected_type):
        """Verify query classification routing."""
        result = classifier.classify(query)
        assert result == expected_type, \
            f"Query '{query}' classified as '{result}', expected '{expected_type}'"

    @pytest.mark.parametrize("query,expected_server", [
        ("Write a Python sort function", "hx-ollama2-server.hx.dev.local"),
        ("What is company policy?", "hx-ollama1-server.hx.dev.local"),
        ("Hello there", "hx-ollama1-server.hx.dev.local"),
    ])
    def test_ollama_routing(self, classifier, query, expected_server):
        """Verify Ollama server routing based on classification."""
        query_type = classifier.classify(query)
        server = classifier.get_ollama_server(query_type)
        assert server == expected_server
```

#### Pattern 4: Checkpoint Persistence Testing

**Challenge:** Validating state survives service restart.

**Solution:** **Service Restart Simulation** with checkpoint verification:

```python
# tests/integration/test_checkpoint_persistence.py

import pytest
import asyncio
from app.persistence.checkpoint import get_checkpointer
from app.agents.supervisor import create_supervisor_graph

class TestCheckpointPersistence:
    """Integration tests for PostgreSQL checkpoint persistence."""

    @pytest.fixture
    async def checkpointer(self):
        """Create checkpointer connected to test database."""
        return await get_checkpointer()

    @pytest.fixture
    async def graph(self, checkpointer):
        """Create graph with checkpointing enabled."""
        return create_supervisor_graph(checkpointer=checkpointer)

    async def test_state_persists_across_restart(self, graph, checkpointer):
        """Verify conversation state persists across simulated restart."""
        thread_id = "test-persistence-001"

        # Step 1: Start conversation
        config = {"configurable": {"thread_id": thread_id}}
        response1 = await graph.ainvoke(
            {"messages": [{"role": "user", "content": "Hello, my name is Alice"}]},
            config=config
        )

        # Step 2: Verify checkpoint created
        checkpoint = await checkpointer.get(config)
        assert checkpoint is not None, "Checkpoint not created"

        # Step 3: Simulate restart (clear in-memory state, recreate graph)
        del graph
        graph_new = create_supervisor_graph(checkpointer=checkpointer)

        # Step 4: Continue conversation with same thread_id
        response2 = await graph_new.ainvoke(
            {"messages": [{"role": "user", "content": "What is my name?"}]},
            config=config
        )

        # Step 5: Verify context preserved
        assert len(response2["messages"]) > 2, "Message history not restored"
        # Verify the assistant remembers the name (in a real test, check response content)

    async def test_checkpoint_on_every_turn(self, graph, checkpointer):
        """Verify checkpoint created after each conversation turn."""
        thread_id = "test-checkpoint-frequency-001"
        config = {"configurable": {"thread_id": thread_id}}

        # Multiple turns
        for i in range(3):
            await graph.ainvoke(
                {"messages": [{"role": "user", "content": f"Message {i}"}]},
                config=config
            )

        # Verify 3 checkpoints created (one per turn)
        checkpoint = await checkpointer.get(config)
        # Note: Actual verification depends on checkpoint schema
        assert checkpoint["metadata"]["step"] >= 3
```

#### Pattern 5: Worker Agent Isolation Testing

**Challenge:** Testing individual workers without full graph execution.

**Solution:** **Isolated Worker Tests** with mocked dependencies:

```python
# tests/unit/test_rag_agent.py

import pytest
from unittest.mock import AsyncMock, patch
from app.agents.workers.rag_agent import RAGAgent

class TestRAGAgent:
    """Unit tests for RAG worker agent in isolation."""

    @pytest.fixture
    def mock_lightrag_client(self):
        """Mock LightRAG HTTP client."""
        client = AsyncMock()
        client.query.return_value = {
            "response": "Retrieved context from documents...",
            "sources": [{"doc_id": "doc1", "score": 0.95}]
        }
        return client

    @pytest.fixture
    def mock_ollama_client(self):
        """Mock Ollama client for RAG synthesis."""
        client = AsyncMock()
        client.ainvoke.return_value = "Based on the retrieved documents..."
        return client

    @pytest.fixture
    def rag_agent(self, mock_lightrag_client, mock_ollama_client):
        """Create RAG agent with mocked dependencies."""
        return RAGAgent(
            lightrag_client=mock_lightrag_client,
            ollama_client=mock_ollama_client
        )

    async def test_rag_agent_retrieves_context(self, rag_agent, mock_lightrag_client):
        """Verify RAG agent calls LightRAG for context."""
        state = {
            "messages": [{"role": "user", "content": "What is the policy?"}],
            "query_type": "rag",
            "rag_context": None
        }

        result = await rag_agent.process(state)

        mock_lightrag_client.query.assert_called_once()
        assert result["rag_context"] is not None

    async def test_rag_agent_handles_empty_results(self, rag_agent, mock_lightrag_client):
        """Verify RAG agent handles empty retrieval gracefully."""
        mock_lightrag_client.query.return_value = {"response": "", "sources": []}

        state = {
            "messages": [{"role": "user", "content": "Unknown topic"}],
            "query_type": "rag",
            "rag_context": None
        }

        result = await rag_agent.process(state)

        # Should gracefully handle empty results
        assert "rag_context" in result
```

### 1.3 Test Environment Configuration

#### Test Environment Isolation Requirements

| Environment | Purpose | Services | Data Isolation |
|-------------|---------|----------|----------------|
| Unit Tests | Fast, deterministic | Mock all external services | In-memory only |
| Integration Tests | Service connectivity | Real PostgreSQL, Redis; Mock Ollama | Test database, namespaced Redis |
| E2E Tests | Full workflow validation | All real services | Test corpus, isolated collections |

#### Environment Configuration

```python
# tests/conftest.py - Test environment configuration

import os
import pytest

# Test environment markers
def pytest_configure(config):
    config.addinivalue_line("markers", "unit: Unit tests (mock all dependencies)")
    config.addinivalue_line("markers", "integration: Integration tests (real PostgreSQL/Redis)")
    config.addinivalue_line("markers", "e2e: End-to-end tests (all real services)")
    config.addinivalue_line("markers", "slow: Tests that take >30 seconds")

@pytest.fixture(scope="session")
def test_config():
    """Test environment configuration."""
    return {
        "postgres": {
            "host": os.getenv("TEST_POSTGRES_HOST", "hx-postgres-server.hx.dev.local"),
            "port": int(os.getenv("TEST_POSTGRES_PORT", "5432")),
            "database": "hx_lang_server_test",  # Isolated test database
            "user": "hx_lang_server_test"
        },
        "redis": {
            "url": os.getenv("TEST_REDIS_URL", "redis://hx-redis-server.hx.dev.local:6379/15"),
            # Use Redis database 15 for test isolation
        },
        "ollama": {
            "mock": os.getenv("MOCK_OLLAMA", "true").lower() == "true",
            "general_url": os.getenv("TEST_OLLAMA_GENERAL_URL", "http://hx-ollama1-server.hx.dev.local:11434"),
            "code_url": os.getenv("TEST_OLLAMA_CODE_URL", "http://hx-ollama2-server.hx.dev.local:11434"),
        },
        "lightrag": {
            "mock": os.getenv("MOCK_LIGHTRAG", "true").lower() == "true",
            "url": os.getenv("TEST_LIGHTRAG_URL", "http://hx-literag-server.hx.dev.local:8020"),
        }
    }
```

---

## 2. Test Coverage Matrix

### 2.1 Requirements Coverage Matrix

**100% coverage requirement: Every FR-xxx and SC-xxx MUST have at least one test case.**

| Requirement | Description | Test Case(s) | Coverage |
|-------------|-------------|--------------|----------|
| **Functional Requirements** ||||
| FR-001 | LangGraph supervisor pattern | tc-lang-functionality-001-supervisor-pattern, tc-lang-workflow-001-supervisor-routing | 100% |
| FR-002 | 3 worker agent types | tc-lang-functionality-002-rag-agent, tc-lang-functionality-003-code-agent, tc-lang-functionality-004-tool-agent | 100% |
| FR-003 | Query classification routing | tc-lang-functionality-005-query-classification, tc-lang-unit-001-classifier | 100% |
| FR-004 | Human-in-the-loop interrupts | tc-lang-functionality-006-human-interrupt | 100% |
| FR-005 | Recursion limits | tc-lang-functionality-007-recursion-limit | 100% |
| FR-006 | PostgreSQL checkpoints | tc-lang-integration-001-postgres-checkpoint, tc-lang-functionality-008-checkpoint-persistence | 100% |
| FR-007 | Redis session caching | tc-lang-integration-002-redis-session, tc-lang-functionality-009-session-cache | 100% |
| FR-008 | Conversation continuation | tc-lang-e2e-001-conversation-continuity | 100% |
| FR-009 | State schema versioning | tc-lang-functionality-010-schema-version | 100% |
| FR-010 | Ollama1 general routing | tc-lang-integration-003-ollama-general | 100% |
| FR-011 | Ollama2 code routing | tc-lang-integration-004-ollama-code | 100% |
| FR-012 | LightRAG embedding routing | tc-lang-integration-005-lightrag-embed | 100% |
| FR-013 | 32KB context validation | tc-lang-functionality-011-context-size | 100% |
| FR-014 | LightRAG HTTP integration | tc-lang-integration-006-lightrag-http | 100% |
| FR-015 | Adaptive retrieval iteration | tc-lang-functionality-012-adaptive-rag, tc-lang-e2e-002-rag-iteration | 100% |
| FR-016 | LightRAG query modes | tc-lang-functionality-013-lightrag-modes | 100% |
| FR-017 | MCP client implementation | tc-lang-integration-007-mcp-client | 100% |
| FR-018 | FastMCP gateway connection | tc-lang-integration-008-fastmcp-gateway | 100% |
| FR-019 | Crawl4AI tool invocation | tc-lang-integration-009-crawl4ai-tool, tc-lang-e2e-003-mcp-crawl | 100% |
| FR-020 | Tool namespace handling | tc-lang-functionality-014-namespace-prefix | 100% |
| FR-021 | FastAPI REST API | tc-lang-api-001-rest-endpoints | 100% |
| FR-022 | Async endpoints | tc-lang-api-002-async-invoke | 100% |
| FR-023 | Webhook callbacks | tc-lang-api-003-webhook-callback | 100% |
| FR-024 | Health endpoint | tc-lang-health-001-endpoint | 100% |
| FR-025 | OpenAPI docs | tc-lang-api-004-openapi-docs | 100% |
| FR-026 | n8n HTTP endpoint (Phase 2) | tc-lang-integration-010-n8n-http | 100% |
| FR-027 | Webhook registration (Phase 2) | tc-lang-integration-011-n8n-webhook | 100% |
| FR-028 | Thread ID continuity (Phase 2) | tc-lang-functionality-015-thread-continuity | 100% |
| **Non-Functional Requirements** ||||
| NFR-001 | API < 5s response | tc-lang-performance-001-api-latency | 100% |
| NFR-002 | Checkpoint < 100ms | tc-lang-performance-002-checkpoint-latency | 100% |
| NFR-003 | Startup < 30s | tc-lang-deployment-004-startup-time | 100% |
| NFR-004 | Memory < 4GB | tc-lang-health-002-resources | 100% |
| NFR-005 | 10 concurrent sessions | tc-lang-performance-003-concurrent-sessions | 100% |
| **Success Criteria** ||||
| SC-001 | Health endpoint 2s | tc-lang-health-001-endpoint | 100% |
| SC-002 | Checkpoint on first invocation | tc-lang-integration-001-postgres-checkpoint | 100% |
| SC-003 | 3 Ollama servers reachable | tc-lang-integration-012-ollama-connectivity | 100% |
| SC-004 | LightRAG functional | tc-lang-integration-006-lightrag-http | 100% |
| SC-005 | MCP gateway connected | tc-lang-integration-008-fastmcp-gateway | 100% |
| SC-006 | 95th percentile < 5s | tc-lang-performance-001-api-latency | 100% |
| SC-007 | Zero checkpoint failures 48h | tc-lang-e2e-004-checkpoint-stability | 100% |
| SC-008 | Classification > 90% | tc-lang-functionality-005-query-classification | 100% |
| SC-009 | Session persistence restart | tc-lang-e2e-001-conversation-continuity | 100% |
| SC-010 | 100% test pass rate | All tests | 100% |
| SC-011 | Supervisor + 3 workers | tc-lang-workflow-002-worker-orchestration | 100% |
| SC-012 | Adaptive RAG iteration | tc-lang-e2e-002-rag-iteration | 100% |
| SC-013 | Multi-Ollama routing | tc-lang-workflow-003-ollama-routing | 100% |
| SC-014 | State persistence validated | tc-lang-e2e-001-conversation-continuity | 100% |
| SC-015 | n8n HTTP working (Phase 2) | tc-lang-integration-010-n8n-http | 100% |
| SC-016 | Webhooks functional (Phase 2) | tc-lang-integration-011-n8n-webhook | 100% |
| SC-017 | Crawl4AI invocation (Phase 2) | tc-lang-e2e-003-mcp-crawl | 100% |
| **Infrastructure Requirements** ||||
| INFRA-001 | systemd service | tc-lang-deployment-005-systemd-unit | 100% |
| INFRA-002 | Bare metal deployment | tc-lang-deployment-006-bare-metal | 100% |
| INFRA-003 | Manual deployment | tc-lang-deployment-007-manual-execution | 100% |
| INFRA-004 | Ansible Vault secrets | tc-lang-deployment-008-vault-access | 100% |

### 2.2 Test Distribution Summary

| Test Category | Count | Percentage |
|---------------|-------|------------|
| Deployment Tests | 14 | 18% |
| Functionality Tests | 20 | 26% |
| Integration Tests | 16 | 21% |
| Health Check Tests | 6 | 8% |
| API Tests | 6 | 8% |
| Workflow Tests (Multi-Agent) | 8 | 10% |
| End-to-End Tests | 8 | 10% |
| **Total** | **78** | **100%** |

### 2.3 Phase-Based Test Allocation

| Phase | Test Types | Count | Gate |
|-------|------------|-------|------|
| Phase 1 (Core) | Deployment, Functionality (FR-001 to FR-016), Integration (Ollama, LightRAG, PostgreSQL, Redis), Health, Workflow | 52 | Phase 1 Exit |
| Phase 2 (n8n + MCP) | Functionality (FR-017 to FR-028), Integration (n8n, MCP), E2E (webhooks, MCP tools) | 26 | Phase 2 Exit |

---

## 3. Quality Gates

### 3.1 Phase Transition Gates

#### Gate 1: Specification Complete (Pre-Planning)

**Criteria:**
- [ ] All 28 functional requirements documented with testability specifications
- [ ] All 5 non-functional requirements have measurable thresholds
- [ ] All 17 success criteria have explicit validation methods
- [ ] Test strategy section complete (lines 844-885 of node-spec.md)
- [ ] Requirements coverage matrix shows 100% coverage planned

**Evidence Required:**
- Test coverage matrix document
- Success criteria testability specifications

**Approver:** Julia Santos (Testing & Quality Specialist)

---

#### Gate 2: Test Plan Complete (Pre-Implementation)

**Criteria:**
- [ ] test-plan.md created following test-plan-template.md
- [ ] All 78 test cases written before implementation begins
- [ ] Test cases cover: Deployment (14), Functionality (20), Integration (16), Health (6), API (6), Workflow (8), E2E (8)
- [ ] Infrastructure tests included (systemd, bare metal, vault)
- [ ] Test environment configuration documented
- [ ] Test data requirements specified

**Evidence Required:**
- `tests/test-plan.md`
- `tests/test-suite/` with all test case files
- `tests/test-suite-index.md`

**Approver:** Julia Santos (Testing & Quality Specialist)

---

#### Gate 3: Phase 1 Exit (Core LangGraph + RAG)

**Criteria:**
- [ ] All deployment tests pass (14/14)
- [ ] All Phase 1 functionality tests pass (15/15)
- [ ] All Phase 1 integration tests pass (10/10)
- [ ] All health check tests pass (6/6)
- [ ] All API tests pass (6/6)
- [ ] All workflow tests pass (8/8)
- [ ] State persistence validated across restart (SC-009)
- [ ] No Critical/High severity defects

**Quantitative Thresholds:**
| Metric | Threshold | Evidence |
|--------|-----------|----------|
| Test Pass Rate | 100% | test-execution-tracking.md |
| Deployment Tests | 14/14 pass | Test results |
| API Response P95 | < 5s | Performance test results |
| Checkpoint Latency | < 100ms | Performance test results |
| Classification Accuracy | > 90% | Classification test results |

**Evidence Required:**
- `tests/test-results/phase-1/` with all execution results
- `tests/test-execution-tracking.md` updated
- `defects/` directory showing no Critical/High unresolved

**Approver:** Julia Santos (Testing & Quality Specialist)

---

#### Gate 4: Phase 2 Exit (n8n + MCP Integration)

**Criteria:**
- [ ] All Phase 2 functionality tests pass (13/13)
- [ ] All Phase 2 integration tests pass (6/6)
- [ ] All E2E tests pass (8/8)
- [ ] n8n HTTP integration validated (SC-015)
- [ ] Webhook callbacks functional (SC-016)
- [ ] Crawl4AI MCP invocation successful (SC-017)
- [ ] No Critical/High severity defects

**Quantitative Thresholds:**
| Metric | Threshold | Evidence |
|--------|-----------|----------|
| Test Pass Rate | 100% | test-execution-tracking.md |
| n8n Response Time | < 10s | Integration test results |
| Webhook Delivery | 100% | Webhook test results |
| MCP Tool Success | 100% | MCP test results |

**Evidence Required:**
- `tests/test-results/phase-2/` with all execution results
- E2E test evidence (logs, screenshots)

**Approver:** Julia Santos (Testing & Quality Specialist)

---

#### Gate 5: Promotion to Operational

**Criteria:**
- [ ] 100% test pass rate across ALL test categories
- [ ] All 78 test cases executed and passing
- [ ] Zero Critical severity defects
- [ ] Zero High severity defects
- [ ] All infrastructure tests pass (systemd, bare metal, vault)
- [ ] 48-hour stability test completed (SC-007)
- [ ] Documentation complete
- [ ] Test suite index updated

**Final Checklist:**
- [ ] test-plan.md complete and approved
- [ ] test-suite-index.md shows 100% coverage
- [ ] test-execution-tracking.md shows all green
- [ ] No blocking defects in defects/
- [ ] Performance SLAs validated

**Approver:** Julia Santos (Testing & Quality Specialist), CAIO (Final approval)

---

### 3.2 Quality Gate Enforcement

**Gate enforcement is NON-NEGOTIABLE:**

```
BLOCKED: Cannot proceed to Phase 2 without Phase 1 Exit Gate PASS
BLOCKED: Cannot promote to operational without all gates PASS
BLOCKED: Any Critical/High defect STOPS progression until resolved
```

---

## 4. Success Criteria Testability

### 4.1 Success Criteria Validation Specifications

Each success criterion requires explicit testability specifications including:
- **Deterministic Test Inputs** - Specific inputs that trigger the behavior
- **Observable Expected Outputs** - Measurable outcomes (not internal state)
- **Pass/Fail Thresholds** - Unambiguous criteria for success

---

#### SC-001: Health Endpoint Response < 2 seconds

**Test Input:**
```bash
curl -w "@curl-format.txt" -o /dev/null -s "http://hx-lang-server.hx.dev.local:8100/health"
```

**Expected Output:**
- HTTP Status: 200
- Response Time: < 2000ms
- Body: JSON with `status: "healthy"` or `status: "degraded"`

**Pass Criteria:**
- Response time < 2000ms in 95% of 100 consecutive requests
- Status code is 200

**Fail Criteria:**
- Response time >= 2000ms in >5% of requests
- Status code is not 200

---

#### SC-002: Checkpoint Created on First Invocation

**Test Input:**
```python
# Test: First invocation creates checkpoint
response = await client.post("/invoke", json={
    "query": "Hello world",
    "thread_id": "test-first-checkpoint-001"
})
```

**Expected Output:**
- PostgreSQL `checkpoints` table contains row for thread_id
- Checkpoint created within 100ms of response

**Pass Criteria:**
```sql
SELECT COUNT(*) FROM langgraph.checkpoints
WHERE thread_id = 'test-first-checkpoint-001';
-- Expected: >= 1
```

**Fail Criteria:**
- No checkpoint row found
- Checkpoint created > 100ms after response

---

#### SC-003: All Three Ollama Servers Reachable

**Test Input:**
```bash
# Test connectivity to all Ollama servers
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags
curl -s http://hx-ollama3-server.hx.dev.local:11434/api/tags
```

**Expected Output:**
- All 3 servers return HTTP 200
- All 3 servers respond within 5 seconds
- Response contains model list

**Pass Criteria:**
- 3/3 servers reachable
- 3/3 servers respond < 5s
- 3/3 servers return valid JSON

**Fail Criteria:**
- Any server unreachable
- Any server timeout > 5s
- Any server returns invalid response

---

#### SC-004: LightRAG Integration Functional

**Test Input:**
```python
# RAG query test with known document
response = await client.post("/invoke", json={
    "query": "Search for information about test document alpha",
    "thread_id": "test-lightrag-001"
})
```

**Prerequisites:**
- Test document "alpha" pre-loaded in LightRAG test corpus

**Expected Output:**
- Response contains content from test document
- `worker_used: "rag_agent"` in response metadata
- `rag_context` field populated

**Pass Criteria:**
- Response references test document content
- RAG agent was invoked (verified via logs)
- Response time < 5s

**Fail Criteria:**
- Response contains no relevant content
- Wrong worker invoked
- LightRAG connection error

---

#### SC-005: MCP Client Connects to FastMCP Gateway

**Test Input:**
```python
# MCP tool discovery test
tools = await mcp_client.get_tools()
```

**Expected Output:**
- Tool list contains Crawl4AI tools with namespace prefix
- Connection established within 5 seconds

**Pass Criteria:**
- `crawl4ai__smart_crawl_url` in tool list
- No connection errors

**Fail Criteria:**
- Empty tool list
- Connection timeout
- Authentication failure

---

#### SC-006: 95th Percentile API Response < 5 seconds

**Test Input:**
```python
# 100 concurrent requests with representative queries
queries = [
    "Hello world",           # General
    "Write a sort function", # Code
    "Search for policy",     # RAG
]
# Execute 100 requests with random query selection
```

**Expected Output:**
- P95 response time < 5000ms
- P99 response time < 10000ms
- Error rate < 1%

**Pass Criteria:**
- P95 <= 5000ms across 100 requests
- Error rate < 1%

**Fail Criteria:**
- P95 > 5000ms
- Error rate >= 1%

---

#### SC-007: Zero Checkpoint Failures in 48-Hour Test

**Test Input:**
```python
# 48-hour soak test with periodic invocations
for hour in range(48):
    for i in range(10):  # 10 requests per hour
        response = await client.post("/invoke", json={
            "query": f"Soak test query {hour}-{i}",
            "thread_id": f"soak-test-{hour}-{i}"
        })
        await asyncio.sleep(random.uniform(300, 360))  # 5-6 min between requests
```

**Expected Output:**
- All 480 invocations complete successfully
- All 480 checkpoints created
- Zero checkpoint write errors in logs

**Pass Criteria:**
- 480/480 successful invocations
- Zero `checkpoint_failed` errors in logs
- PostgreSQL checkpoint table shows 480+ rows

**Fail Criteria:**
- Any checkpoint write failure
- Any invocation failure
- Database connection errors

---

#### SC-008: Query Classification Accuracy > 90%

**Test Input:**
```python
# 100 labeled test queries
test_queries = [
    ("Write Python code", "code"),
    ("Search documents", "rag"),
    ("Hello there", "general"),
    # ... 97 more labeled queries
]
```

**Expected Output:**
- >= 90 correct classifications out of 100

**Pass Criteria:**
- Accuracy >= 90%
- No systematic misclassification pattern

**Fail Criteria:**
- Accuracy < 90%
- Critical misclassifications (e.g., code queries sent to general)

---

#### SC-009: Session Persistence Across Service Restart

**Test Input:**
```python
# Step 1: Create conversation
response1 = await client.post("/invoke", json={
    "query": "My name is TestUser",
    "thread_id": "restart-test-001"
})

# Step 2: Restart service
subprocess.run(["sudo", "systemctl", "restart", "hx-lang-server"])
await asyncio.sleep(30)  # Wait for restart

# Step 3: Continue conversation
response2 = await client.post("/invoke", json={
    "query": "What is my name?",
    "thread_id": "restart-test-001"
})
```

**Expected Output:**
- Response2 contains reference to "TestUser"
- Conversation history preserved

**Pass Criteria:**
- Service restarts successfully
- Conversation context restored
- Response demonstrates memory of prior turn

**Fail Criteria:**
- Service fails to restart
- Context lost
- Response shows no memory of prior turn

---

#### SC-010: 100% Test Suite Pass Rate

**Test Input:**
```bash
pytest tests/ -v --tb=short
```

**Expected Output:**
- All 78 tests pass
- Zero failures
- Zero errors

**Pass Criteria:**
- 78/78 tests pass
- Exit code 0

**Fail Criteria:**
- Any test fails
- Any test errors
- Exit code non-zero

---

## 5. Test Case Specifications

### 5.1 Critical Test Case Examples

The following test case specifications follow the `test-case-template.md` format and represent critical tests for hx-lang-server.

---

#### Test Case: tc-lang-workflow-001-supervisor-routing

**Test ID**: tc-lang-workflow-001-supervisor-routing
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-01
**Status**: Not Run
**Priority**: Critical

---

**Test Metadata**

**Based on Spec**: FR-001 (Supervisor pattern), FR-003 (Query classification routing)
**Based on Plan**: Multi-Agent Test Strategy Section 1.2, Pattern 3
**Test Type**: Automated
**Estimated Execution Time**: 2 minutes

---

**Test Objective**

**What This Test Validates:**
Verifies the LangGraph supervisor agent correctly routes queries to the appropriate worker agent based on query classification (code -> Code Agent, rag -> RAG Agent, tool -> Tool Agent, general -> fallback).

**Why This Test Is Important:**
Incorrect routing would send queries to inappropriate workers, resulting in poor response quality and wasted compute resources. This is the core orchestration function of the supervisor.

---

**Prerequisites**

**Service State:**
- [x] Service is running
- [x] All worker agents registered

**Dependencies:**
- [x] hx-ollama1-server.hx.dev.local reachable
- [x] hx-ollama2-server.hx.dev.local reachable
- [x] hx-literag-server.hx.dev.local reachable
- [x] hx-fastmcp-server.hx.dev.local reachable

**Environment:**
- [x] Test environment configured with state inspector
- [x] Deterministic LLM mocks available

---

**Test Steps**

**Step 1: Send Code Query**
```python
response = await client.post("/invoke", json={
    "query": "Write a Python function to calculate fibonacci numbers",
    "thread_id": "routing-test-code-001"
})
```

**Expected Behavior:**
- Query classified as "code"
- Routed to Code Agent
- Ollama2 (code LLM) invoked

**How to Verify:**
- `response.json()["worker_used"] == "code_agent"`
- `response.json()["metadata"]["llm_used"]` contains "ollama2"

---

**Step 2: Send RAG Query**
```python
response = await client.post("/invoke", json={
    "query": "Search for documentation about company policy",
    "thread_id": "routing-test-rag-001"
})
```

**Expected Behavior:**
- Query classified as "rag"
- Routed to RAG Agent
- LightRAG invoked for retrieval

**How to Verify:**
- `response.json()["worker_used"] == "rag_agent"`
- `response.json()["rag_context"]` is not None

---

**Step 3: Send Tool Query**
```python
response = await client.post("/invoke", json={
    "query": "Crawl the website https://example.com for content",
    "thread_id": "routing-test-tool-001"
})
```

**Expected Behavior:**
- Query classified as "tool"
- Routed to Tool Agent
- MCP tool invocation attempted

**How to Verify:**
- `response.json()["worker_used"] == "tool_agent"`
- `response.json()["tool_results"]` present

---

**Step 4: Send General Query**
```python
response = await client.post("/invoke", json={
    "query": "Hello, how are you today?",
    "thread_id": "routing-test-general-001"
})
```

**Expected Behavior:**
- Query classified as "general"
- Handled by supervisor or general handler
- Ollama1 (general LLM) invoked

**How to Verify:**
- `response.json()["worker_used"]` in ["supervisor", "general_handler"]
- `response.json()["metadata"]["llm_used"]` contains "ollama1"

---

**Expected Results**

**Primary Expected Results:**
- [x] Code query routes to Code Agent with Ollama2
- [x] RAG query routes to RAG Agent with LightRAG
- [x] Tool query routes to Tool Agent with MCP
- [x] General query handled with Ollama1

**Observable Indicators:**
- Logs show routing decisions
- Response metadata shows correct worker
- No cross-contamination of workers

---

**Pass/Fail Criteria**

**PASS Criteria:**
1. All 4 query types route to correct worker
2. Correct LLM/service invoked for each type
3. Response metadata accurately reflects routing
4. No errors in service logs
5. Response time < 5s for each query

**FAIL Criteria:**
1. Any query routes to wrong worker
2. Wrong LLM/service invoked
3. Metadata shows incorrect routing
4. Errors in service logs
5. Timeout or error response

---

#### Test Case: tc-lang-e2e-001-conversation-continuity

**Test ID**: tc-lang-e2e-001-conversation-continuity
**Service**: hx-lang-server
**Test Area**: e2e
**Created**: 2025-12-01
**Status**: Not Run
**Priority**: Critical

---

**Test Metadata**

**Based on Spec**: FR-006 (PostgreSQL checkpoints), FR-008 (Conversation continuation), SC-009 (Session persistence across restart)
**Based on Plan**: State Persistence Architecture (lines 200-217)
**Test Type**: Semi-Automated (requires service restart)
**Estimated Execution Time**: 5 minutes

---

**Test Objective**

**What This Test Validates:**
Verifies complete conversation history and context are preserved across service restarts, validating PostgreSQL checkpoint persistence and state restoration.

**Why This Test Is Important:**
Users expect conversations to continue seamlessly after maintenance or failures. State loss would result in poor user experience and broken workflows.

---

**Prerequisites**

**Service State:**
- [x] Service is running
- [x] PostgreSQL checkpointing enabled

**Dependencies:**
- [x] hx-postgres-server.hx.dev.local operational
- [x] Database `hx_lang_server` accessible

**Permissions:**
- [x] sudo access for service restart

---

**Test Steps**

**Step 1: Establish Conversation with Unique Context**
```python
# Create conversation with memorable context
thread_id = f"continuity-test-{uuid.uuid4()}"
response1 = await client.post("/invoke", json={
    "query": "My favorite color is blue and my lucky number is 42",
    "thread_id": thread_id
})
```

**Expected Behavior:**
- Response acknowledges the information
- Checkpoint created in PostgreSQL

**How to Verify:**
- HTTP 200 response
- Query PostgreSQL: `SELECT * FROM langgraph.checkpoints WHERE thread_id = '{thread_id}'`

---

**Step 2: Verify Checkpoint Persisted**
```bash
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT thread_id, created_at FROM langgraph.checkpoints WHERE thread_id = '$THREAD_ID'"
```

**Expected Behavior:**
- Checkpoint row exists
- Created timestamp matches response time

---

**Step 3: Restart Service**
```bash
sudo systemctl restart hx-lang-server
sleep 30  # Wait for service to fully restart
```

**Expected Behavior:**
- Service restarts successfully
- Health check passes

**How to Verify:**
- `systemctl is-active hx-lang-server` returns "active"
- Health endpoint returns 200

---

**Step 4: Continue Conversation After Restart**
```python
response2 = await client.post("/invoke", json={
    "query": "What is my favorite color and lucky number?",
    "thread_id": thread_id  # Same thread_id
})
```

**Expected Behavior:**
- Response references "blue" and "42"
- Conversation history restored from checkpoint

**How to Verify:**
- Response contains "blue" and "42"
- Response shows message count > 2

---

**Expected Results**

**Primary Expected Results:**
- [x] Checkpoint created after first message
- [x] Service restarts successfully within 30 seconds
- [x] Conversation context restored after restart
- [x] Response demonstrates memory of prior context

---

**Pass/Fail Criteria**

**PASS Criteria:**
1. Checkpoint exists in PostgreSQL before restart
2. Service restarts within 30 seconds
3. Health check passes after restart
4. Second response contains "blue" and "42"
5. Conversation history count >= 2

**FAIL Criteria:**
1. No checkpoint found
2. Service fails to restart
3. Health check fails
4. Context not restored (no mention of blue/42)
5. Conversation treated as new

---

### 5.2 Additional Critical Test Cases (Summary)

| Test ID | Priority | Description | SC/FR Reference |
|---------|----------|-------------|-----------------|
| tc-lang-deployment-001-verify-installation | Critical | Verify all files installed correctly | Deployment |
| tc-lang-deployment-005-systemd-unit | Critical | Verify systemd service configuration | INFRA-001 |
| tc-lang-deployment-006-bare-metal | Critical | Verify bare metal deployment (no Docker) | INFRA-002 |
| tc-lang-integration-001-postgres-checkpoint | Critical | Verify PostgreSQL checkpoint creation | FR-006, SC-002 |
| tc-lang-integration-012-ollama-connectivity | Critical | Verify all 3 Ollama servers reachable | SC-003 |
| tc-lang-health-001-endpoint | Critical | Verify /health responds < 2s | SC-001 |
| tc-lang-e2e-002-rag-iteration | Critical | Verify adaptive RAG with retrieval iteration | SC-012 |
| tc-lang-e2e-004-checkpoint-stability | Critical | 48-hour stability test | SC-007 |

---

## 6. Validation of Specification (Testing-Related Corrections)

### 6.1 Gaps Identified in node-spec.md

| Line | Issue | Severity | Recommendation |
|------|-------|----------|----------------|
| 846-855 | Test counts (78) not broken down by phase | Medium | Add phase-specific test counts (Phase 1: 52, Phase 2: 26) |
| 877-884 | Quality gates incomplete | High | Add explicit phase transition gates with metrics |
| N/A | No test environment isolation specification | Medium | Add test environment configuration section |
| N/A | No deterministic testing strategy | High | Add mock LLM provider specification for unit tests |
| N/A | Success criteria lack testability specs | High | Add test input/output/threshold for each SC-xxx |
| 857-875 | Multi-agent test patterns example only | Medium | Expand with state inspector and routing validation patterns |

### 6.2 Specification Corrections Required

#### Correction 1: Expand Testing Strategy Section (lines 844-885)

**Current:**
```markdown
## Testing Strategy

### Test Categories
| Category | Count | Coverage |
|----------|-------|----------|
| Unit Tests | 25 | Core logic, classifiers, state management |
...
```

**Recommended Addition:**
Add the complete multi-agent test strategy from Section 1 of this contribution, including:
- Layered test architecture (pyramid diagram)
- Deterministic agent execution pattern
- State transition testing pattern
- Supervisor routing validation
- Checkpoint persistence testing
- Test environment isolation requirements

---

#### Correction 2: Add Phase-Specific Quality Gates

**Add to Section "Testing Strategy":**

```markdown
### Phase-Specific Quality Gates

#### Phase 1 Exit Gate
- All deployment tests pass (14/14)
- Phase 1 functionality tests pass (15/15)
- Phase 1 integration tests pass (10/10)
- All health check tests pass (6/6)
- No Critical/High defects

#### Phase 2 Exit Gate
- Phase 2 functionality tests pass (13/13)
- Phase 2 integration tests pass (6/6)
- All E2E tests pass (8/8)
- No Critical/High defects

#### Promotion Gate
- 100% test pass rate (78/78)
- 48-hour stability test pass
- All infrastructure tests pass
```

---

#### Correction 3: Add Success Criteria Testability Section

**Add new section after "Success Criteria" (line 888):**

```markdown
### Success Criteria Testability Specifications

Each success criterion has explicit testability specifications:

| SC-ID | Deterministic Input | Expected Output | Pass Threshold |
|-------|---------------------|-----------------|----------------|
| SC-001 | `curl /health` | HTTP 200, time | < 2000ms (95%) |
| SC-002 | First `/invoke` | PostgreSQL row | Checkpoint exists |
| SC-003 | `curl` to 3 servers | HTTP 200 | 3/3 reachable |
| SC-004 | RAG query | Content match | Retrieved docs match |
| SC-005 | `get_tools()` | Tool list | Contains crawl4ai |
| SC-006 | 100 requests | P95 latency | < 5000ms |
| SC-007 | 48h test | Checkpoint count | 480+, zero errors |
| SC-008 | 100 labeled queries | Accuracy | >= 90% |
| SC-009 | Restart test | Context recall | Memory preserved |
| SC-010 | `pytest` | Pass count | 78/78 |
```

---

#### Correction 4: Clarify Test Environment Requirements

**Add to Section "Dependencies" or new "Test Environment" section:**

```markdown
### Test Environment Requirements

| Environment | Services | Data Isolation | Purpose |
|-------------|----------|----------------|---------|
| Unit | All mocked | In-memory | Fast, deterministic |
| Integration | Real PostgreSQL/Redis, Mock LLM | Test DB, Redis DB 15 | Service connectivity |
| E2E | All real | Test corpus, isolated | Full workflow |

#### Test Database
- Database: `hx_lang_server_test`
- User: `hx_lang_server_test`
- Isolation: Separate from production data

#### Redis Test Namespace
- Database: 15 (isolated from production DB 0)
- Key prefix: `test:`

#### LLM Mocking
- Unit tests: DeterministicLLMProvider (see test strategy)
- Integration tests: Real Ollama with deterministic prompts
- E2E tests: Real Ollama with representative queries
```

---

## 7. Summary and Recommendations

### 7.1 Key Testing Priorities

1. **Multi-Agent Testing Infrastructure** - Implement deterministic LLM provider and state inspector utilities BEFORE test implementation
2. **Phase Gates** - Enforce strict phase transition criteria with explicit metrics
3. **Success Criteria Testability** - Every SC-xxx must have documented test input, expected output, and pass threshold
4. **Test Environment Isolation** - Configure separate test database and Redis namespace
5. **Infrastructure Compliance** - Include systemd, bare metal, and Ansible Vault tests per HX-Infrastructure standards

### 7.2 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Non-deterministic LLM responses break tests | High | High | Implement DeterministicLLMProvider for unit/integration tests |
| Test environment data contamination | Medium | High | Strict namespace isolation for PostgreSQL and Redis |
| Incomplete multi-agent coverage | Medium | High | State inspector captures all node transitions |
| Phase gate bypassed | Low | Critical | Julia Santos sign-off required for each gate |
| 48-hour stability test fails | Medium | Medium | Early detection via checkpoint monitoring |

### 7.3 Testing Timeline

| Week | Activities |
|------|------------|
| Week 1 | Create test-plan.md, write 40 test cases (deployment, functionality) |
| Week 2 | Write remaining 38 test cases (integration, health, workflow, e2e), peer review |
| Week 3 | Execute Phase 1 tests (52 tests), defect resolution |
| Week 4 | Execute Phase 2 tests (26 tests), 48-hour stability test |
| Week 5 | Final validation, promotion gate |

### 7.4 Coordination Requirements

| Agent | Coordination Need |
|-------|-------------------|
| Sophia (LangGraph SME) | State schema design impacts test fixtures; need `AgentState` TypedDict finalized |
| Trinity (PostgreSQL DBA) | Test database provisioning; checkpoint table schema for assertions |
| Sri (Redis SME) | Test Redis namespace (DB 15) configuration |
| Bob (FastAPI SME) | API endpoint test patterns, error response format |
| Jim (Ollama SME) | Deterministic prompt patterns for testing |

---

## Approval

This contribution addresses all testing and quality assurance gaps identified in the charter review (Q-001 through Q-010) and provides comprehensive specifications for multi-agent testing, quality gates, and success criteria testability.

**Recommendation:** Incorporate Sections 1-5 into test-plan.md and Section 6 corrections into node-spec.md.

---

**Signature:** Julia Santos (Testing & Quality Specialist)
**Date:** 2025-12-01
**Contribution Status:** COMPLETE
