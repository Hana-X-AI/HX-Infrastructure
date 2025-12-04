# Task: Create Integration Tests for Ollama Connectivity

**Task ID:** hx-lang-server-task-078-create-ollama-integration-tests
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:**
- hx-lang-server-task-071 through 077 (All Ollama tasks)
**Estimated Time:** 60 minutes

---

## Objective

Create comprehensive integration tests for Ollama connectivity, verifying:
- Connection to both Ollama servers
- Model availability and 64KB context support
- Query routing logic
- Health check functionality
- Retry logic and circuit breaker behavior

---

## Prerequisites

- [ ] Tasks 071-077 completed (All Ollama configuration)
- [ ] pytest and pytest-asyncio installed
- [ ] Both Ollama servers accessible from hx-lang-server
- [ ] Test directory structure exists

---

## Specification References

From node-spec.md (v2.1):
- **Testing Strategy**: Integration tests for Ollama, LightRAG, PostgreSQL, Redis
- **SC-003**: All three Ollama servers reachable and responding
- **FR-013**: Service MUST validate Ollama model context size >= 64KB

---

## Steps

### Step 1: Create Test Directory Structure

```bash
mkdir -p /opt/hx-lang-server/tests/integration/ollama
touch /opt/hx-lang-server/tests/integration/__init__.py
touch /opt/hx-lang-server/tests/integration/ollama/__init__.py
```

### Step 2: Create Ollama Connection Tests

Create file `/opt/hx-lang-server/tests/integration/ollama/test_ollama_connection.py`:

```python
"""
Integration Tests: Ollama Server Connectivity

Tests connection to hx-ollama1-server (general) and hx-ollama2-server (code).
"""

import pytest
import httpx
from langchain_ollama import ChatOllama


# Server configuration
OLLAMA_GENERAL_URL = "http://hx-ollama1-server.hx.dev.local:11434"
OLLAMA_CODE_URL = "http://hx-ollama2-server.hx.dev.local:11434"


class TestOllamaGeneralConnection:
    """Tests for hx-ollama1-server connection."""

    @pytest.mark.asyncio
    async def test_server_reachable(self):
        """TC-OLLAMA-001: Verify hx-ollama1-server is reachable."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_GENERAL_URL}/api/tags")

        assert response.status_code == 200, (
            f"hx-ollama1-server not reachable: {response.status_code}"
        )

    @pytest.mark.asyncio
    async def test_models_available(self):
        """TC-OLLAMA-002: Verify models are available on hx-ollama1-server."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_GENERAL_URL}/api/tags")

        data = response.json()
        models = data.get("models", [])

        assert len(models) > 0, "No models available on hx-ollama1-server"

    @pytest.mark.asyncio
    async def test_gemma_model_available(self):
        """TC-OLLAMA-003: Verify gemma model is available for general queries."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_GENERAL_URL}/api/tags")

        data = response.json()
        models = data.get("models", [])
        model_names = [m["name"].lower() for m in models]

        has_gemma = any("gemma" in name for name in model_names)
        assert has_gemma, (
            f"gemma model not found on hx-ollama1-server. "
            f"Available: {model_names}"
        )

    @pytest.mark.asyncio
    async def test_api_generate_works(self):
        """TC-OLLAMA-004: Verify /api/generate endpoint works."""
        async with httpx.AsyncClient(timeout=60.0) as client:
            # Get first available model
            tags_response = await client.get(f"{OLLAMA_GENERAL_URL}/api/tags")
            models = tags_response.json().get("models", [])

            if not models:
                pytest.skip("No models available")

            model = models[0]["name"]

            # Test generate
            response = await client.post(
                f"{OLLAMA_GENERAL_URL}/api/generate",
                json={
                    "model": model,
                    "prompt": "Say 'test' and nothing else.",
                    "stream": False,
                }
            )

        assert response.status_code == 200
        assert "response" in response.json()


class TestOllamaCodeConnection:
    """Tests for hx-ollama2-server connection."""

    @pytest.mark.asyncio
    async def test_server_reachable(self):
        """TC-OLLAMA-005: Verify hx-ollama2-server is reachable."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_CODE_URL}/api/tags")

        assert response.status_code == 200, (
            f"hx-ollama2-server not reachable: {response.status_code}"
        )

    @pytest.mark.asyncio
    async def test_models_available(self):
        """TC-OLLAMA-006: Verify models are available on hx-ollama2-server."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_CODE_URL}/api/tags")

        data = response.json()
        models = data.get("models", [])

        assert len(models) > 0, "No models available on hx-ollama2-server"

    @pytest.mark.asyncio
    async def test_coder_model_available(self):
        """TC-OLLAMA-007: Verify coder model is available for code queries."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_CODE_URL}/api/tags")

        data = response.json()
        models = data.get("models", [])
        model_names = [m["name"].lower() for m in models]

        has_coder = any("coder" in name for name in model_names)
        assert has_coder, (
            f"coder model not found on hx-ollama2-server. "
            f"Available: {model_names}"
        )

    @pytest.mark.asyncio
    async def test_api_generate_works(self):
        """TC-OLLAMA-008: Verify /api/generate endpoint works on code server."""
        async with httpx.AsyncClient(timeout=120.0) as client:
            # Get first available model
            tags_response = await client.get(f"{OLLAMA_CODE_URL}/api/tags")
            models = tags_response.json().get("models", [])

            if not models:
                pytest.skip("No models available")

            model = models[0]["name"]

            # Test generate with code prompt
            response = await client.post(
                f"{OLLAMA_CODE_URL}/api/generate",
                json={
                    "model": model,
                    "prompt": "def hello(): return 'hello'",
                    "stream": False,
                }
            )

        assert response.status_code == 200
        assert "response" in response.json()
```

### Step 3: Create 64KB Context Tests

Create file `/opt/hx-lang-server/tests/integration/ollama/test_64kb_context.py`:

```python
"""
Integration Tests: 64KB Context Window

Validates CAIO decision: 64KB context for RAG and Code operations.
Tests FR-013 compliance.
"""

import pytest
import httpx


OLLAMA_GENERAL_URL = "http://hx-ollama1-server.hx.dev.local:11434"
OLLAMA_CODE_URL = "http://hx-ollama2-server.hx.dev.local:11434"


class Test64KBContextRAG:
    """Tests for 64KB context on RAG operations (hx-ollama1-server)."""

    @pytest.mark.asyncio
    async def test_64kb_context_accepted(self):
        """TC-OLLAMA-009: Verify 64KB context is accepted for RAG."""
        async with httpx.AsyncClient(timeout=120.0) as client:
            # Get model
            tags_response = await client.get(f"{OLLAMA_GENERAL_URL}/api/tags")
            models = tags_response.json().get("models", [])

            if not models:
                pytest.skip("No models available")

            # Find gemma model
            model = next(
                (m["name"] for m in models if "gemma" in m["name"].lower()),
                models[0]["name"]
            )

            # Test with 64KB context
            response = await client.post(
                f"{OLLAMA_GENERAL_URL}/api/generate",
                json={
                    "model": model,
                    "prompt": "test",
                    "options": {"num_ctx": 65536},
                    "stream": False,
                }
            )

        assert response.status_code == 200, (
            f"64KB context rejected: {response.text}"
        )

    @pytest.mark.asyncio
    async def test_large_context_prompt(self):
        """TC-OLLAMA-010: Verify large prompts work within 64KB context."""
        async with httpx.AsyncClient(timeout=180.0) as client:
            # Get model
            tags_response = await client.get(f"{OLLAMA_GENERAL_URL}/api/tags")
            models = tags_response.json().get("models", [])

            if not models:
                pytest.skip("No models available")

            model = next(
                (m["name"] for m in models if "gemma" in m["name"].lower()),
                models[0]["name"]
            )

            # Create ~16KB prompt (well within 64KB)
            large_prompt = "Document chunk: " + ("sample text " * 2000)

            response = await client.post(
                f"{OLLAMA_GENERAL_URL}/api/generate",
                json={
                    "model": model,
                    "prompt": f"Summarize: {large_prompt}",
                    "options": {"num_ctx": 65536},
                    "stream": False,
                },
                timeout=180.0,
            )

        assert response.status_code == 200
        assert "response" in response.json()


class Test64KBContextCode:
    """Tests for 64KB context on Code operations (hx-ollama2-server)."""

    @pytest.mark.asyncio
    async def test_64kb_context_accepted(self):
        """TC-OLLAMA-011: Verify 64KB context is accepted for Code."""
        async with httpx.AsyncClient(timeout=120.0) as client:
            # Get model
            tags_response = await client.get(f"{OLLAMA_CODE_URL}/api/tags")
            models = tags_response.json().get("models", [])

            if not models:
                pytest.skip("No models available")

            # Find coder model
            model = next(
                (m["name"] for m in models if "coder" in m["name"].lower()),
                models[0]["name"]
            )

            # Test with 64KB context
            response = await client.post(
                f"{OLLAMA_CODE_URL}/api/generate",
                json={
                    "model": model,
                    "prompt": "def test(): pass",
                    "options": {"num_ctx": 65536},
                    "stream": False,
                }
            )

        assert response.status_code == 200, (
            f"64KB context rejected on code server: {response.text}"
        )

    @pytest.mark.asyncio
    async def test_large_code_context(self):
        """TC-OLLAMA-012: Verify large code context works within 64KB."""
        async with httpx.AsyncClient(timeout=180.0) as client:
            # Get model
            tags_response = await client.get(f"{OLLAMA_CODE_URL}/api/tags")
            models = tags_response.json().get("models", [])

            if not models:
                pytest.skip("No models available")

            model = next(
                (m["name"] for m in models if "coder" in m["name"].lower()),
                models[0]["name"]
            )

            # Create multi-file code context (~8KB)
            code_context = """
# file1.py
class UserService:
    def get_user(self, id): pass
    def create_user(self, data): pass

# file2.py
class OrderService:
    def create_order(self, user_id, items): pass
    def get_orders(self, user_id): pass
""" * 50

            response = await client.post(
                f"{OLLAMA_CODE_URL}/api/generate",
                json={
                    "model": model,
                    "prompt": f"Review this code:\n{code_context}",
                    "options": {"num_ctx": 65536},
                    "stream": False,
                },
                timeout=180.0,
            )

        assert response.status_code == 200
        assert "response" in response.json()
```

### Step 4: Create Routing Tests

Create file `/opt/hx-lang-server/tests/integration/ollama/test_model_routing.py`:

```python
"""
Integration Tests: Model Routing

Tests FR-003, FR-010, FR-011 - query routing to appropriate Ollama servers.
"""

import pytest
import sys

sys.path.insert(0, '/opt/hx-lang-server')


class TestModelRouting:
    """Tests for Ollama model routing based on query type."""

    def test_routing_table_configured(self):
        """TC-OLLAMA-013: Verify routing table is properly configured."""
        from app.llm.ollama_router import ROUTING_TABLE, QueryType

        # Verify all query types have routing config
        assert QueryType.GENERAL in ROUTING_TABLE
        assert QueryType.CODE in ROUTING_TABLE
        assert QueryType.RAG in ROUTING_TABLE
        assert QueryType.TOOL in ROUTING_TABLE

    def test_general_routes_to_ollama1(self):
        """TC-OLLAMA-014: Verify general queries route to hx-ollama1-server."""
        from app.llm.ollama_router import ROUTING_TABLE, QueryType

        config = ROUTING_TABLE[QueryType.GENERAL]

        assert "hx-ollama1-server" in config.server_url
        assert config.min_context == 8192  # 8KB

    def test_code_routes_to_ollama2(self):
        """TC-OLLAMA-015: Verify code queries route to hx-ollama2-server."""
        from app.llm.ollama_router import ROUTING_TABLE, QueryType

        config = ROUTING_TABLE[QueryType.CODE]

        assert "hx-ollama2-server" in config.server_url
        assert config.min_context == 65536  # 64KB per CAIO

    def test_rag_routes_to_ollama1_with_64kb(self):
        """TC-OLLAMA-016: Verify RAG queries route to ollama1 with 64KB."""
        from app.llm.ollama_router import ROUTING_TABLE, QueryType

        config = ROUTING_TABLE[QueryType.RAG]

        assert "hx-ollama1-server" in config.server_url
        assert config.min_context == 65536  # 64KB per CAIO

    def test_tool_routes_to_ollama1(self):
        """TC-OLLAMA-017: Verify tool queries route to hx-ollama1-server."""
        from app.llm.ollama_router import ROUTING_TABLE, QueryType

        config = ROUTING_TABLE[QueryType.TOOL]

        assert "hx-ollama1-server" in config.server_url

    def test_router_get_llm(self):
        """TC-OLLAMA-018: Verify router returns LLM for query type."""
        from app.llm.ollama_router import OllamaRouter

        router = OllamaRouter()

        # Should not raise
        general_llm = router.get_llm("general")
        code_llm = router.get_llm("code")

        assert general_llm is not None
        assert code_llm is not None

    def test_router_handles_unknown_type(self):
        """TC-OLLAMA-019: Verify router defaults unknown types to general."""
        from app.llm.ollama_router import OllamaRouter, QueryType

        router = OllamaRouter()
        config = router.get_routing_config("unknown_type")

        assert config.query_type == QueryType.GENERAL
```

### Step 5: Create Health Check Tests

Create file `/opt/hx-lang-server/tests/integration/ollama/test_health_checks.py`:

```python
"""
Integration Tests: Ollama Health Checks

Tests health check functionality for Ollama servers.
"""

import pytest
import sys

sys.path.insert(0, '/opt/hx-lang-server')


class TestOllamaHealthChecks:
    """Tests for Ollama health check functionality."""

    @pytest.mark.asyncio
    async def test_check_general_server(self):
        """TC-OLLAMA-020: Verify health check for hx-ollama1-server."""
        from app.health.ollama_health import check_ollama_general

        result = await check_ollama_general()

        assert "status" in result
        assert "response_time_ms" in result
        assert result["status"] in ["healthy", "degraded", "unhealthy"]

    @pytest.mark.asyncio
    async def test_check_code_server(self):
        """TC-OLLAMA-021: Verify health check for hx-ollama2-server."""
        from app.health.ollama_health import check_ollama_code

        result = await check_ollama_code()

        assert "status" in result
        assert "response_time_ms" in result
        assert result["status"] in ["healthy", "degraded", "unhealthy"]

    @pytest.mark.asyncio
    async def test_check_all_servers(self):
        """TC-OLLAMA-022: Verify combined health check."""
        from app.health.ollama_health import check_all_ollama

        result = await check_all_ollama()

        assert "overall_status" in result
        assert "servers" in result
        assert "ollama_general" in result["servers"]
        assert "ollama_code" in result["servers"]

    @pytest.mark.asyncio
    async def test_health_response_time(self):
        """TC-OLLAMA-023: Verify health checks complete within timeout."""
        import asyncio
        from app.health.ollama_health import OllamaHealthChecker

        checker = OllamaHealthChecker(timeout=10.0)

        start = asyncio.get_event_loop().time()
        await checker.check_all()
        duration = asyncio.get_event_loop().time() - start

        # Should complete well under timeout
        assert duration < 15.0, f"Health checks took too long: {duration}s"
```

### Step 6: Create Retry Logic Tests

Create file `/opt/hx-lang-server/tests/integration/ollama/test_retry_logic.py`:

```python
"""
Integration Tests: Retry Logic and Circuit Breaker

Tests retry behavior and circuit breaker patterns.
"""

import pytest
import asyncio
import sys

sys.path.insert(0, '/opt/hx-lang-server')


class TestRetryLogic:
    """Tests for retry and circuit breaker functionality."""

    def test_retry_config_defaults(self):
        """TC-OLLAMA-024: Verify retry configuration defaults."""
        from app.llm.retry_config import RetryConfig

        config = RetryConfig()

        assert config.max_attempts == 3
        assert config.initial_delay == 1.0
        assert config.max_delay == 30.0
        assert config.jitter is True

    def test_circuit_breaker_initial_state(self):
        """TC-OLLAMA-025: Verify circuit breaker starts closed."""
        from app.llm.retry_config import CircuitBreaker, CircuitState

        cb = CircuitBreaker("test")

        assert cb.state == CircuitState.CLOSED
        assert cb.allow_request() is True

    def test_circuit_breaker_opens_on_failures(self):
        """TC-OLLAMA-026: Verify circuit opens after threshold failures."""
        from app.llm.retry_config import (
            CircuitBreaker,
            CircuitBreakerConfig,
            CircuitState,
        )

        cb = CircuitBreaker(
            "test",
            CircuitBreakerConfig(failure_threshold=3),
        )

        # Record failures up to threshold
        for _ in range(3):
            cb.record_failure()

        assert cb.state == CircuitState.OPEN
        assert cb.allow_request() is False

    def test_circuit_breaker_success_resets(self):
        """TC-OLLAMA-027: Verify success decrements failure count."""
        from app.llm.retry_config import CircuitBreaker, CircuitState

        cb = CircuitBreaker("test")

        # Some failures
        cb.record_failure()
        cb.record_failure()

        # Success should decrement
        cb.record_success()

        assert cb.state == CircuitState.CLOSED

    @pytest.mark.asyncio
    async def test_retry_succeeds_eventually(self):
        """TC-OLLAMA-028: Verify retry succeeds after transient failures."""
        from app.llm.retry_config import RetryableOllamaClient, RetryConfig

        client = RetryableOllamaClient(
            "test",
            RetryConfig(max_attempts=3, initial_delay=0.1),
        )

        attempts = [0]

        async def flaky_operation():
            attempts[0] += 1
            if attempts[0] < 2:
                raise ConnectionError("Transient failure")
            return "success"

        result = await client.execute_with_retry(flaky_operation)

        assert result == "success"
        assert attempts[0] == 2

    @pytest.mark.asyncio
    async def test_retry_exhausted_raises(self):
        """TC-OLLAMA-029: Verify exception raised when retries exhausted."""
        from app.llm.retry_config import RetryableOllamaClient, RetryConfig

        client = RetryableOllamaClient(
            "test",
            RetryConfig(max_attempts=2, initial_delay=0.1),
        )

        async def always_fails():
            raise ConnectionError("Permanent failure")

        with pytest.raises(ConnectionError):
            await client.execute_with_retry(always_fails)

    def test_delay_calculation_exponential(self):
        """TC-OLLAMA-030: Verify exponential backoff calculation."""
        from app.llm.retry_config import calculate_delay, RetryConfig

        config = RetryConfig(
            initial_delay=1.0,
            exponential_base=2.0,
            jitter=False,
        )

        delays = [calculate_delay(i, config) for i in range(1, 5)]

        # Should approximately double each time
        assert delays[0] == 1.0
        assert delays[1] == 2.0
        assert delays[2] == 4.0
        assert delays[3] == 8.0
```

### Step 7: Create Test Runner Script

Create file `/opt/hx-lang-server/scripts/run_ollama_tests.sh`:

```bash
#!/bin/bash
# Run Ollama integration tests

cd /opt/hx-lang-server

# Activate virtual environment
source venv/bin/activate

# Run pytest with verbose output
pytest tests/integration/ollama/ -v --tb=short -x

# Exit with pytest's exit code
exit $?
```

Make executable:
```bash
chmod +x /opt/hx-lang-server/scripts/run_ollama_tests.sh
```

---

## Acceptance Criteria

- [ ] Test directory structure created under tests/integration/ollama/
- [ ] Connection tests for both Ollama servers (8 test cases)
- [ ] 64KB context tests for RAG and Code (4 test cases)
- [ ] Routing tests verify correct server/model assignment (7 test cases)
- [ ] Health check tests verify health endpoint integration (4 test cases)
- [ ] Retry logic tests verify backoff and circuit breaker (7 test cases)
- [ ] Total: 30 test cases for Ollama integration
- [ ] Test runner script created
- [ ] All tests pass when Ollama servers are available

---

## Verification Commands

```bash
# Verify test files exist
ls -la /opt/hx-lang-server/tests/integration/ollama/

# Count test cases
grep -r "def test_" /opt/hx-lang-server/tests/integration/ollama/ | wc -l

# Run tests
source /opt/hx-lang-server/venv/bin/activate
pytest /opt/hx-lang-server/tests/integration/ollama/ -v --collect-only

# Run with coverage
pytest /opt/hx-lang-server/tests/integration/ollama/ -v --cov=app.llm --cov=app.health
```

---

## Rollback Procedure

1. Remove tests/integration/ollama/ directory
2. Remove test runner script

---

## Related Tasks

- **Tasks 071-077:** All Ollama configuration tasks
- **Task 151-200:** Julia's test suite generation

---

## Test Case Summary

| Test ID | Description | Category |
|---------|-------------|----------|
| TC-OLLAMA-001 | hx-ollama1-server reachable | Connection |
| TC-OLLAMA-002 | Models available on ollama1 | Connection |
| TC-OLLAMA-003 | gemma model available | Connection |
| TC-OLLAMA-004 | Generate endpoint works (general) | Connection |
| TC-OLLAMA-005 | hx-ollama2-server reachable | Connection |
| TC-OLLAMA-006 | Models available on ollama2 | Connection |
| TC-OLLAMA-007 | coder model available | Connection |
| TC-OLLAMA-008 | Generate endpoint works (code) | Connection |
| TC-OLLAMA-009 | 64KB context accepted (RAG) | 64KB Context |
| TC-OLLAMA-010 | Large RAG prompt works | 64KB Context |
| TC-OLLAMA-011 | 64KB context accepted (Code) | 64KB Context |
| TC-OLLAMA-012 | Large code context works | 64KB Context |
| TC-OLLAMA-013 | Routing table configured | Routing |
| TC-OLLAMA-014 | General routes to ollama1 | Routing |
| TC-OLLAMA-015 | Code routes to ollama2 | Routing |
| TC-OLLAMA-016 | RAG routes with 64KB | Routing |
| TC-OLLAMA-017 | Tool routes to ollama1 | Routing |
| TC-OLLAMA-018 | Router returns LLM | Routing |
| TC-OLLAMA-019 | Unknown type defaults | Routing |
| TC-OLLAMA-020 | Health check general | Health |
| TC-OLLAMA-021 | Health check code | Health |
| TC-OLLAMA-022 | Combined health check | Health |
| TC-OLLAMA-023 | Health check timing | Health |
| TC-OLLAMA-024 | Retry config defaults | Retry |
| TC-OLLAMA-025 | Circuit breaker initial | Retry |
| TC-OLLAMA-026 | Circuit opens on failures | Retry |
| TC-OLLAMA-027 | Success resets circuit | Retry |
| TC-OLLAMA-028 | Retry succeeds eventually | Retry |
| TC-OLLAMA-029 | Retry exhausted raises | Retry |
| TC-OLLAMA-030 | Exponential backoff | Retry |

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
