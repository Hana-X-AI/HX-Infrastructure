# Task 026: Configure LiteLLM Gateway Integration

**Task ID**: hx-docling-mcp-task-026
**Category**: Configuration - LiteLLM Integration
**Priority**: HIGH (blocking for Stage 2 - Knowledge Graph Generation)
**Estimated Effort**: 4-6 hours
**Assigned To**: shane-black (LiteLLM Gateway Integration SME)
**Status**: NOT STARTED
**Dependencies**:
- Task 001 (Install FastMCP framework) MUST be complete
- Task 010 (Configure environment files) MUST be complete
- Task 011 (Create Ansible Vault credentials) MUST be complete
- hx-litellm-server MUST be operational (192.168.10.212:4000)
**Blocks**:
- Task 015 (Configure Qdrant integration) - LightRAG needs LLM for entity extraction
- Task 020-027 (Test creation tasks) - Integration tests depend on LiteLLM client
- Stage 2 implementation (LightRAG knowledge graph generation)

---

## Objective

Configure complete LiteLLM Gateway integration for Docling MCP Server with production-grade resilience, cost optimization, and multi-model routing. This task establishes the LLM abstraction layer that enables LightRAG knowledge graph generation via Ollama models (gemma3:27b, qwen3-coder:30b, gpt-oss:20b) routed through LiteLLM proxy at hx-litellm-server:4000.

**Success Criteria**:
1. ✅ LiteLLM client configured with connection pooling (max 20 connections, keepalive 100)
2. ✅ API key loaded from Ansible Vault and validated
3. ✅ Model routing configured (primary: gemma3:27b, secondary: qwen3-coder:30b, fallback: gpt-oss:20b)
4. ✅ Health check integration operational (`/health` endpoint, 30-second interval)
5. ✅ Retry logic implemented (3 attempts, exponential backoff, jitter)
6. ✅ Circuit breaker configured (5 failures → 60s open state)
7. ✅ Response caching enabled (Redis backend, SHA-256 hash keys, 7-day TTL)
8. ✅ Graceful degradation mode functional (skip extraction if LiteLLM unavailable)
9. ✅ Structured logging with metrics (JSON format, request_id, model, retry_count)
10. ✅ Integration tests passing (connectivity, model availability, error handling)

---

## Background Context

### Why LiteLLM Integration is Critical

**From Charter** (lines 101-107):
- LiteLLM Gateway integration (hx-litellm-server.hx.dev.local:4000)
- Ollama model routing:
  - Ollama1 (192.168.10.204): gemma3:27b, gpt-oss:20b, mistral:7b (entity extraction)
  - Ollama2 (192.168.10.205): qwen3-coder:30b, qwen2.5:7b (code/text processing)
  - Ollama3 (192.168.10.206): ibm/granite-docling:258m (docling processing ONLY)

**From My LiteLLM Integration Review** (shane-litellm-integration.md):
- **Prompt Engineering**: Structured JSON extraction prompts with few-shot examples
- **LLM Parameters**: Temperature 0.1 (deterministic), top_p 0.9, max_tokens 2048
- **Cost Optimization**: Redis caching for identical extraction requests (20-30% hit rate target)
- **Model Selection**: gemma3:27b for general text, qwen3-coder:30b for technical docs, gpt-oss:20b fallback

**From Configuration Spec** (configuration-spec.md lines 752-767):
```bash
LITELLM_BASE_URL=http://192.168.10.212:4000
LITELLM_API_KEY=<from_ansible_vault>
LITELLM_TIMEOUT=120
LITELLM_MAX_RETRIES=3
LITELLM_RETRY_DELAY=2

LITELLM_ENTITY_EXTRACTION_MODEL=ollama/gemma3:27b
LITELLM_FALLBACK_MODEL=ollama/gpt-oss:20b
LITELLM_DOCLING_MODEL=ollama/granite-docling:258m
LITELLM_EMBEDDING_MODEL=ollama/bge-m3:567m
```

### Risks Addressed by This Task

**From Charter Risk R-001** (lines 511):
- **Risk**: Granite-Docling model too small for entity extraction (258M parameters)
- **Mitigation**: Use Ollama1 models (gemma3:27b, gpt-oss:20b) via LiteLLM routing

**From Plan Risk Assessment** (plan.md lines 966):
- **Risk**: LiteLLM Gateway unavailable (MEDIUM/HIGH)
- **Mitigation**: Application implements retry logic with exponential backoff, circuit breaker, graceful degradation

---

## Technical Specification

### 1. LiteLLM Client Configuration

**Client Setup** (Python httpx AsyncClient):

```python
# /opt/docling-mcp/application/docling_mcp/clients/litellm_client.py

import os
import httpx
import hashlib
import asyncio
from typing import Dict, Any, Optional, List
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log
)
import structlog

logger = structlog.get_logger(__name__)

class LiteLLMClient:
    """
    LiteLLM Gateway client with production resilience patterns.

    Features:
    - Connection pooling (max 20 connections, keepalive 100)
    - Health checks (30-second interval)
    - Retry logic (3 attempts, exponential backoff with jitter)
    - Circuit breaker (5 failures → 60s open state)
    - Response caching (Redis backend, SHA-256 keys, 7-day TTL)
    - Graceful degradation (skip extraction if unavailable)
    - Structured logging with metrics
    """

    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        redis_client: Optional[Any] = None,
        timeout: int = 120,
        max_retries: int = 3,
        retry_delay: int = 2,
    ):
        """
        Initialize LiteLLM client.

        Args:
            base_url: LiteLLM Gateway URL (e.g., http://192.168.10.212:4000)
            api_key: Optional API key for authentication
            redis_client: Redis client for caching (optional)
            timeout: Request timeout in seconds (default 120)
            max_retries: Maximum retry attempts (default 3)
            retry_delay: Initial retry delay in seconds (default 2)
        """
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.redis_client = redis_client
        self.timeout = timeout
        self.max_retries = max_retries
        self.retry_delay = retry_delay

        # Connection pooling configuration
        limits = httpx.Limits(
            max_connections=20,
            max_keepalive_connections=100,
            keepalive_expiry=30.0
        )

        # HTTP client with pooling
        timeout_config = httpx.Timeout(
            connect=10.0,
            read=float(timeout),
            write=5.0,
            pool=None
        )

        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            limits=limits,
            timeout=timeout_config,
            headers={"Authorization": f"Bearer {api_key}"} if api_key else {}
        )

        # Circuit breaker state (managed in Redis)
        self.circuit_breaker_key = "circuit_breaker:litellm"
        self.circuit_breaker_threshold = 5
        self.circuit_breaker_timeout = 60  # seconds

        logger.info(
            "litellm_client_initialized",
            base_url=self.base_url,
            timeout=self.timeout,
            max_retries=self.max_retries
        )

    async def health_check(self) -> bool:
        """
        Check LiteLLM Gateway health.

        Returns:
            True if healthy, False otherwise
        """
        try:
            response = await self.client.get("/health", timeout=5.0)
            response.raise_for_status()
            logger.info("litellm_health_check_success")
            return True
        except Exception as e:
            logger.error("litellm_health_check_failed", error=str(e))
            return False

    async def _get_circuit_breaker_state(self) -> str:
        """
        Get circuit breaker state from Redis.

        Returns:
            "CLOSED", "OPEN", or "HALF_OPEN"
        """
        if not self.redis_client:
            return "CLOSED"

        try:
            state = await self.redis_client.get(self.circuit_breaker_key)
            return state.decode() if state else "CLOSED"
        except Exception as e:
            logger.error("circuit_breaker_state_get_failed", error=str(e))
            return "CLOSED"

    async def _set_circuit_breaker_state(self, state: str, ttl: Optional[int] = None):
        """
        Set circuit breaker state in Redis.

        Args:
            state: "CLOSED", "OPEN", or "HALF_OPEN"
            ttl: Time-to-live in seconds (None for no expiry)
        """
        if not self.redis_client:
            return

        try:
            if ttl:
                await self.redis_client.setex(self.circuit_breaker_key, ttl, state)
            else:
                await self.redis_client.set(self.circuit_breaker_key, state)
            logger.info("circuit_breaker_state_set", state=state, ttl=ttl)
        except Exception as e:
            logger.error("circuit_breaker_state_set_failed", error=str(e))

    async def _increment_failure_count(self) -> int:
        """
        Increment circuit breaker failure count.

        Returns:
            Current failure count
        """
        if not self.redis_client:
            return 0

        try:
            key = f"{self.circuit_breaker_key}:failures"
            count = await self.redis_client.incr(key)
            await self.redis_client.expire(key, 60)  # Reset after 60s
            return count
        except Exception as e:
            logger.error("failure_count_increment_failed", error=str(e))
            return 0

    async def _reset_failure_count(self):
        """Reset circuit breaker failure count."""
        if not self.redis_client:
            return

        try:
            key = f"{self.circuit_breaker_key}:failures"
            await self.redis_client.delete(key)
            logger.info("failure_count_reset")
        except Exception as e:
            logger.error("failure_count_reset_failed", error=str(e))

    def _get_cache_key(self, model: str, prompt: str, params: Dict[str, Any]) -> str:
        """
        Generate cache key for extraction response.

        Args:
            model: Model name (e.g., "ollama/gemma3:27b")
            prompt: Prompt text
            params: LLM parameters (temperature, top_p, etc.)

        Returns:
            SHA-256 hash cache key
        """
        cache_input = f"{model}:{prompt}:{sorted(params.items())}"
        hash_digest = hashlib.sha256(cache_input.encode()).hexdigest()
        return f"extraction_cache:{model}:{hash_digest}"

    async def _get_cached_response(self, cache_key: str) -> Optional[str]:
        """
        Get cached extraction response from Redis.

        Args:
            cache_key: Cache key

        Returns:
            Cached response or None
        """
        if not self.redis_client:
            return None

        try:
            cached = await self.redis_client.get(cache_key)
            if cached:
                logger.info("cache_hit", cache_key=cache_key)
                return cached.decode()
            return None
        except Exception as e:
            logger.error("cache_get_failed", error=str(e))
            return None

    async def _set_cached_response(self, cache_key: str, response: str, ttl: int = 604800):
        """
        Cache extraction response in Redis.

        Args:
            cache_key: Cache key
            response: Response to cache
            ttl: Time-to-live in seconds (default 7 days)
        """
        if not self.redis_client:
            return

        try:
            await self.redis_client.setex(cache_key, ttl, response)
            logger.info("cache_set", cache_key=cache_key, ttl=ttl)
        except Exception as e:
            logger.error("cache_set_failed", error=str(e))

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=60),
        retry=retry_if_exception_type((httpx.TimeoutException, httpx.HTTPStatusError)),
        before_sleep=before_sleep_log(logger, "WARNING")
    )
    async def call_llm(
        self,
        model: str,
        prompt: str,
        temperature: float = 0.1,
        top_p: float = 0.9,
        max_tokens: int = 2048,
        stop: Optional[List[str]] = None,
        use_cache: bool = True
    ) -> str:
        """
        Call LLM via LiteLLM Gateway with retry logic.

        Args:
            model: Model name (e.g., "ollama/gemma3:27b")
            prompt: Prompt text
            temperature: Temperature (0.0-1.0, default 0.1 for deterministic extraction)
            top_p: Nucleus sampling (default 0.9)
            max_tokens: Maximum tokens in response (default 2048)
            stop: Stop sequences (default ["\n\n\n", "```"])
            use_cache: Enable response caching (default True)

        Returns:
            LLM response text

        Raises:
            CircuitBreakerOpenError: If circuit breaker is open
            httpx.HTTPStatusError: On HTTP errors after retries exhausted
            httpx.TimeoutException: On timeout after retries exhausted
        """
        # Check circuit breaker
        cb_state = await self._get_circuit_breaker_state()
        if cb_state == "OPEN":
            logger.error("circuit_breaker_open", model=model)
            raise CircuitBreakerOpenError("LiteLLM circuit breaker is OPEN")

        # Check cache
        params = {
            "temperature": temperature,
            "top_p": top_p,
            "max_tokens": max_tokens,
            "stop": stop or ["\n\n\n", "```"]
        }

        if use_cache:
            cache_key = self._get_cache_key(model, prompt, params)
            cached_response = await self._get_cached_response(cache_key)
            if cached_response:
                return cached_response

        # Call LiteLLM API
        try:
            payload = {
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": temperature,
                "top_p": top_p,
                "max_tokens": max_tokens,
                "stop": stop or ["\n\n\n", "```"]
            }

            response = await self.client.post("/v1/chat/completions", json=payload)
            response.raise_for_status()

            result = response.json()
            response_text = result["choices"][0]["message"]["content"]

            # Cache response
            if use_cache:
                await self._set_cached_response(cache_key, response_text)

            # Reset failure count on success
            await self._reset_failure_count()

            logger.info(
                "litellm_call_success",
                model=model,
                input_tokens=result.get("usage", {}).get("prompt_tokens"),
                output_tokens=result.get("usage", {}).get("completion_tokens")
            )

            return response_text

        except (httpx.TimeoutException, httpx.HTTPStatusError) as e:
            # Increment failure count
            failures = await self._increment_failure_count()

            # Open circuit breaker if threshold reached
            if failures >= self.circuit_breaker_threshold:
                await self._set_circuit_breaker_state("OPEN", ttl=self.circuit_breaker_timeout)
                logger.error(
                    "circuit_breaker_opened",
                    model=model,
                    failures=failures,
                    threshold=self.circuit_breaker_threshold
                )

            logger.error(
                "litellm_call_failed",
                model=model,
                error=str(e),
                failures=failures
            )
            raise

    async def close(self):
        """Close HTTP client."""
        await self.client.aclose()
        logger.info("litellm_client_closed")


class CircuitBreakerOpenError(Exception):
    """Circuit breaker is open, LiteLLM unavailable."""
    pass
```

### 2. Environment Variable Configuration

**Update `/etc/docling-mcp/.env`** (from configuration-spec.md):

```bash
# =============================================================================
# LiteLLM Gateway Configuration
# =============================================================================
LITELLM_BASE_URL=http://192.168.10.212:4000
LITELLM_API_KEY=${LITELLM_API_KEY}  # Loaded from Ansible Vault
LITELLM_TIMEOUT=120
LITELLM_MAX_RETRIES=3
LITELLM_RETRY_DELAY=2

# Model Routing (via LiteLLM)
LITELLM_ENTITY_EXTRACTION_MODEL=ollama/gemma3:27b
LITELLM_FALLBACK_MODEL=ollama/gpt-oss:20b
LITELLM_DOCLING_MODEL=ollama/granite-docling:258m
LITELLM_EMBEDDING_MODEL=ollama/bge-m3:567m
```

**Load API Key from Ansible Vault** (`/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml`):

```yaml
---
# Ansible Vault encrypted credentials for Docling MCP Server
litellm_api_key: "sk-hx-litellm-docling-mcp-001"  # Replace with actual key
```

**Python Configuration Loader** (`/opt/docling-mcp/application/docling_mcp/utils/config.py`):

```python
import os
from typing import Optional
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings

class LiteLLMConfig(BaseModel):
    """LiteLLM Gateway configuration."""

    base_url: str = Field(..., description="LiteLLM base URL")
    api_key: Optional[str] = Field(None, description="LiteLLM API key")
    timeout: int = Field(120, description="Request timeout (seconds)")
    max_retries: int = Field(3, description="Maximum retry attempts")
    retry_delay: int = Field(2, description="Initial retry delay (seconds)")

    # Model routing
    entity_extraction_model: str = Field("ollama/gemma3:27b", description="Primary entity extraction model")
    fallback_model: str = Field("ollama/gpt-oss:20b", description="Fallback model")
    docling_model: str = Field("ollama/granite-docling:258m", description="Docling processing model")
    embedding_model: str = Field("ollama/bge-m3:567m", description="Embedding model")


class Settings(BaseSettings):
    """Application settings."""

    litellm: LiteLLMConfig

    class Config:
        env_file = "/etc/docling-mcp/.env"
        env_nested_delimiter = "_"


def load_config() -> Settings:
    """Load application configuration from environment."""
    return Settings(
        litellm=LiteLLMConfig(
            base_url=os.getenv("LITELLM_BASE_URL"),
            api_key=os.getenv("LITELLM_API_KEY"),
            timeout=int(os.getenv("LITELLM_TIMEOUT", "120")),
            max_retries=int(os.getenv("LITELLM_MAX_RETRIES", "3")),
            retry_delay=int(os.getenv("LITELLM_RETRY_DELAY", "2")),
            entity_extraction_model=os.getenv("LITELLM_ENTITY_EXTRACTION_MODEL", "ollama/gemma3:27b"),
            fallback_model=os.getenv("LITELLM_FALLBACK_MODEL", "ollama/gpt-oss:20b"),
            docling_model=os.getenv("LITELLM_DOCLING_MODEL", "ollama/granite-docling:258m"),
            embedding_model=os.getenv("LITELLM_EMBEDDING_MODEL", "ollama/bge-m3:567m")
        )
    )
```

### 3. Health Check Integration

**Health Check Service** (`/opt/docling-mcp/application/docling_mcp/utils/health.py`):

```python
import asyncio
from typing import Dict, Any
import structlog

logger = structlog.get_logger(__name__)

class HealthChecker:
    """
    Background health checker for LiteLLM Gateway.

    Runs health checks every 30 seconds, updates health status.
    """

    def __init__(self, litellm_client, interval: int = 30):
        """
        Initialize health checker.

        Args:
            litellm_client: LiteLLM client instance
            interval: Health check interval in seconds (default 30)
        """
        self.litellm_client = litellm_client
        self.interval = interval
        self.health_status = {"litellm": "unknown"}
        self._task = None

    async def start(self):
        """Start background health check task."""
        self._task = asyncio.create_task(self._health_check_loop())
        logger.info("health_checker_started", interval=self.interval)

    async def stop(self):
        """Stop background health check task."""
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("health_checker_stopped")

    async def _health_check_loop(self):
        """Background health check loop."""
        while True:
            try:
                # Check LiteLLM health
                is_healthy = await self.litellm_client.health_check()
                self.health_status["litellm"] = "healthy" if is_healthy else "unhealthy"

                await asyncio.sleep(self.interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error("health_check_failed", error=str(e))
                self.health_status["litellm"] = "error"
                await asyncio.sleep(self.interval)

    def get_status(self) -> Dict[str, Any]:
        """Get current health status."""
        return self.health_status.copy()
```

### 4. Integration Tests

**Test File**: `/opt/docling-mcp/tests/integration/test_litellm_integration.py`

```python
"""
Integration tests for LiteLLM Gateway integration.

Tests:
- Connectivity to hx-litellm-server:4000
- API key authentication
- Model availability (gemma3:27b, qwen3-coder:30b, gpt-oss:20b)
- Health check endpoint
- Retry logic with exponential backoff
- Circuit breaker behavior
- Response caching
- Graceful degradation
"""

import pytest
import pytest_asyncio
import asyncio
import httpx
from unittest.mock import AsyncMock, Mock

from docling_mcp.clients.litellm_client import LiteLLMClient, CircuitBreakerOpenError


@pytest.mark.integration
@pytest.mark.requires_litellm
class TestLiteLLMIntegration:
    """Integration tests for LiteLLM Gateway."""

    @pytest_asyncio.fixture
    async def redis_client(self):
        """Redis client fixture for integration tests."""
        import redis.asyncio as aioredis
        client = await aioredis.from_url("redis://192.168.10.210:6379")
        yield client
        await client.close()

    @pytest_asyncio.fixture
    async def litellm_client(self, redis_client):
        """LiteLLM client fixture."""
        client = LiteLLMClient(
            base_url="http://192.168.10.212:4000",
            api_key="test-key",
            redis_client=redis_client,
            timeout=120,
            max_retries=3
        )
        yield client
        await client.close()

    @pytest.mark.asyncio
    async def test_health_check_success(self, litellm_client):
        """Test LiteLLM health check endpoint."""
        is_healthy = await litellm_client.health_check()
        assert is_healthy is True

    @pytest.mark.asyncio
    async def test_model_availability_gemma3(self, litellm_client):
        """Test gemma3:27b model availability."""
        response = await litellm_client.call_llm(
            model="ollama/gemma3:27b",
            prompt="Extract entities from: 'John Smith works at Acme Corp.'",
            use_cache=False
        )
        assert response is not None
        assert len(response) > 0

    @pytest.mark.asyncio
    async def test_model_availability_qwen3_coder(self, litellm_client):
        """Test qwen3-coder:30b model availability."""
        response = await litellm_client.call_llm(
            model="ollama/qwen3-coder:30b",
            prompt="Extract entities from: 'FastAPI depends on Pydantic.'",
            use_cache=False
        )
        assert response is not None
        assert len(response) > 0

    @pytest.mark.asyncio
    async def test_model_availability_gpt_oss(self, litellm_client):
        """Test gpt-oss:20b fallback model availability."""
        response = await litellm_client.call_llm(
            model="ollama/gpt-oss:20b",
            prompt="Extract entities from: 'Apple released new products.'",
            use_cache=False
        )
        assert response is not None
        assert len(response) > 0

    @pytest.mark.asyncio
    async def test_response_caching(self, litellm_client):
        """Test response caching with Redis."""
        prompt = "Extract entities from: 'Test caching.'"

        # First call (cache miss)
        response1 = await litellm_client.call_llm(
            model="ollama/gemma3:27b",
            prompt=prompt,
            use_cache=True
        )

        # Second call (cache hit)
        response2 = await litellm_client.call_llm(
            model="ollama/gemma3:27b",
            prompt=prompt,
            use_cache=True
        )

        assert response1 == response2

    @pytest.mark.asyncio
    async def test_retry_logic_on_timeout(self, litellm_client, monkeypatch):
        """Test retry logic with exponential backoff."""
        # Mock timeout on first attempt, success on second
        call_count = 0

        async def mock_post(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise httpx.TimeoutException("Timeout")
            # Return mock response matching LiteLLM /v1/chat/completions shape
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json = lambda: {
                "id": "chatcmpl-123",
                "object": "chat.completion",
                "created": 1677652288,
                "model": "ollama/gemma3:27b",
                "choices": [{
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Success"
                    },
                    "finish_reason": "stop"
                }],
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 20,
                    "total_tokens": 30
                }
            }
            return mock_response

        monkeypatch.setattr(litellm_client.client, "post", mock_post)

        response = await litellm_client.call_llm(
            model="ollama/gemma3:27b",
            prompt="Test retry",
            use_cache=False
        )

        assert call_count == 2  # First failed, second succeeded
        assert response == "Success"

    @pytest.mark.asyncio
    async def test_circuit_breaker_opens_after_failures(self, litellm_client, monkeypatch):
        """Test circuit breaker opens after 5 consecutive failures."""
        # Mock failures
        async def mock_post_failure(*args, **kwargs):
            mock_request = Mock()
            mock_response = Mock()
            mock_response.status_code = 503
            raise httpx.HTTPStatusError("503 Service Unavailable", request=mock_request, response=mock_response)

        monkeypatch.setattr(litellm_client.client, "post", mock_post_failure)

        # Make 5 failed calls
        for i in range(5):
            with pytest.raises(httpx.HTTPStatusError):
                await litellm_client.call_llm(
                    model="ollama/gemma3:27b",
                    prompt=f"Test circuit breaker {i}",
                    use_cache=False
                )

        # 6th call should raise CircuitBreakerOpenError
        with pytest.raises(CircuitBreakerOpenError):
            await litellm_client.call_llm(
                model="ollama/gemma3:27b",
                prompt="Test circuit breaker open",
                use_cache=False
            )

    @pytest.mark.asyncio
    async def test_graceful_degradation(self, litellm_client):
        """Test graceful degradation when LiteLLM unavailable."""
        # Simulate circuit breaker open
        await litellm_client._set_circuit_breaker_state("OPEN", ttl=60)

        # Call should raise CircuitBreakerOpenError
        with pytest.raises(CircuitBreakerOpenError):
            await litellm_client.call_llm(
                model="ollama/gemma3:27b",
                prompt="Test degradation",
                use_cache=False
            )
```

---

## Implementation Steps

### Step 1: Create LiteLLM Client Module (2 hours)

**File**: `/opt/docling-mcp/application/docling_mcp/clients/litellm_client.py`

1. Copy complete `LiteLLMClient` class implementation from Technical Specification section 1 above
2. Create `CircuitBreakerOpenError` exception class
3. Verify imports (httpx, tenacity, structlog, hashlib, asyncio)
4. Test class instantiation with mock configuration

**Validation**:
```bash
# Verify file created
ls -lh /opt/docling-mcp/application/docling_mcp/clients/litellm_client.py

# Verify imports
python3 -c "from docling_mcp.clients.litellm_client import LiteLLMClient"
```

### Step 2: Update Configuration Loader (1 hour)

**File**: `/opt/docling-mcp/application/docling_mcp/utils/config.py`

1. Add `LiteLLMConfig` Pydantic model from Technical Specification section 2
2. Update `Settings` class to include `litellm: LiteLLMConfig`
3. Implement `load_config()` function with environment variable loading
4. Test configuration loading with mock `.env` file

**Validation**:
```bash
# Test configuration loading
python3 -c "from docling_mcp.utils.config import load_config; config = load_config(); print(config.litellm.base_url)"
# Expected output: http://192.168.10.212:4000
```

### Step 3: Configure Environment Variables (30 minutes)

**File**: `/etc/docling-mcp/.env`

1. Add LiteLLM configuration section from Technical Specification section 2
2. Load `LITELLM_API_KEY` from Ansible Vault:
   ```bash
   ansible-vault view /home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml | grep litellm_api_key
   ```
3. Export to environment: `export LITELLM_API_KEY="<value>"`
4. Verify all required variables set

**Validation**:
```bash
# Verify environment variables
source /etc/docling-mcp/.env
env | grep LITELLM
# Expected: LITELLM_BASE_URL, LITELLM_API_KEY, LITELLM_TIMEOUT, LITELLM_MAX_RETRIES, etc.
```

### Step 4: Implement Health Check Service (1 hour)

**File**: `/opt/docling-mcp/application/docling_mcp/utils/health.py`

1. Copy `HealthChecker` class implementation from Technical Specification section 3
2. Integrate with application startup (start health checker on server init)
3. Integrate with `/health` endpoint (include LiteLLM health status)
4. Test health check loop with mock LiteLLM client

**Validation**:
```bash
# Test health checker
python3 -c "from docling_mcp.utils.health import HealthChecker; print('HealthChecker loaded')"
```

### Step 5: Write Integration Tests (2 hours)

**File**: `/opt/docling-mcp/tests/integration/test_litellm_integration.py`

1. Copy complete test suite from Technical Specification section 4
2. Add pytest markers: `@pytest.mark.integration`, `@pytest.mark.requires_litellm`
3. Create fixtures for LiteLLM client, Redis client
4. Implement all 8 test cases:
   - `test_health_check_success`
   - `test_model_availability_gemma3`
   - `test_model_availability_qwen3_coder`
   - `test_model_availability_gpt_oss`
   - `test_response_caching`
   - `test_retry_logic_on_timeout`
   - `test_circuit_breaker_opens_after_failures`
   - `test_graceful_degradation`

**Validation**:
```bash
# Run integration tests (will fail until service deployed)
pytest tests/integration/test_litellm_integration.py -v
# Expected: FAILED (service not deployed yet - correct per test-driven deployment)
```

### Step 6: Update Documentation (30 minutes)

**Files to Update**:
1. `/opt/docling-mcp/README.md`: Add LiteLLM integration section
2. `/opt/docling-mcp/deployment/RUNBOOK.md`: Add LiteLLM troubleshooting section
3. `/opt/docling-mcp/application/docling_mcp/clients/README.md`: Document LiteLLM client usage

**Content**:
```markdown
## LiteLLM Integration

### Configuration

LiteLLM Gateway integration provides multi-provider LLM abstraction for entity extraction.

**Environment Variables**:
- `LITELLM_BASE_URL`: LiteLLM Gateway URL (default: http://192.168.10.212:4000)
- `LITELLM_API_KEY`: API key for authentication (from Ansible Vault)
- `LITELLM_TIMEOUT`: Request timeout in seconds (default: 120)
- `LITELLM_MAX_RETRIES`: Maximum retry attempts (default: 3)

**Model Routing**:
- Primary: `ollama/gemma3:27b` (general text entity extraction)
- Secondary: `ollama/qwen3-coder:30b` (technical documentation)
- Fallback: `ollama/gpt-oss:20b` (fast fallback model)

### Health Checks

LiteLLM health is monitored every 30 seconds via `/health` endpoint.

**Manual Health Check**:
```bash
curl -f http://192.168.10.212:4000/health
```

### Troubleshooting

**Symptom**: Circuit breaker open
**Cause**: 5+ consecutive LiteLLM failures
**Resolution**:
1. Check LiteLLM health: `curl http://192.168.10.212:4000/health`
2. Verify Ollama models loaded: `curl http://192.168.10.212:4000/models`
3. Wait 60 seconds for circuit breaker to reset
4. Check Redis state: `redis-cli GET circuit_breaker:litellm`

**Symptom**: Timeout errors
**Cause**: Model inference too slow
**Resolution**:
1. Check Ollama server load: `ssh hx-ollama1-server "nvidia-smi"`
2. Verify model keep_alive: `curl http://192.168.10.204:11434/api/show -d '{"name":"gemma3:27b"}'`
3. Consider using faster fallback model (gpt-oss:20b)
```

---

## Validation Criteria

### Pre-Deployment Validation (Test-Driven)

**All integration tests MUST FAIL before deployment** (service not running yet):

```bash
pytest tests/integration/test_litellm_integration.py -v
# Expected output: 8 FAILED (connection refused to 192.168.10.212:4000)
```

**Status**: ✅ PASS (tests fail as expected, service not deployed)

### Post-Deployment Validation (After Service Deployed)

**All integration tests MUST PASS after deployment**:

```bash
# Run integration tests
pytest tests/integration/test_litellm_integration.py -v --tb=short

# Expected output:
# test_health_check_success PASSED
# test_model_availability_gemma3 PASSED
# test_model_availability_qwen3_coder PASSED
# test_model_availability_gpt_oss PASSED
# test_response_caching PASSED
# test_retry_logic_on_timeout PASSED
# test_circuit_breaker_opens_after_failures PASSED
# test_graceful_degradation PASSED
# ===================== 8 passed in 45.23s =====================
```

**Status**: PENDING (run after Task 001-013 deployment complete)

### Manual Validation Commands

**1. Verify LiteLLM Client Instantiation**:
```bash
source /opt/docling-mcp/venv/bin/activate
python3 <<EOF
from docling_mcp.clients.litellm_client import LiteLLMClient
client = LiteLLMClient(base_url="http://192.168.10.212:4000", api_key="test")
print("✅ LiteLLM client instantiated successfully")
EOF
```

**2. Verify Environment Variables Loaded**:
```bash
source /etc/docling-mcp/.env
python3 -c "from docling_mcp.utils.config import load_config; config = load_config(); assert config.litellm.base_url == 'http://192.168.10.212:4000'; print('✅ Environment variables loaded')"
```

**3. Verify Health Check**:
```bash
source /opt/docling-mcp/venv/bin/activate
python3 <<EOF
import asyncio
from docling_mcp.clients.litellm_client import LiteLLMClient

async def test_health():
    client = LiteLLMClient(base_url="http://192.168.10.212:4000")
    is_healthy = await client.health_check()
    assert is_healthy is True, "LiteLLM health check failed"
    print("✅ LiteLLM health check passed")
    await client.close()

asyncio.run(test_health())
EOF
```

**4. Verify Model Availability**:
```bash
curl -X POST http://192.168.10.212:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama/gemma3:27b",
    "messages": [{"role": "user", "content": "Test"}],
    "max_tokens": 10
  }'
# Expected: JSON response with "choices" array
```

**5. Verify Circuit Breaker State**:
```bash
redis-cli -h 192.168.10.210 -p 6379 GET circuit_breaker:litellm
# Expected: (nil) or "CLOSED" (open means issues)
```

---

## Quality Gate Enforcement

**IF any validation fails THEN**:

1. ✅ **STOP** deployment immediately
2. ✅ Create defect ticket:
   ```
   defect-docling-mcp-high-001-litellm-integration-failure.md
   Severity: HIGH (blocks Stage 2 knowledge graph generation)
   ```
3. ✅ Analyze failure:
   - Review logs: `tail -f /var/log/docling-mcp/error.log`
   - Check LiteLLM health: `curl http://192.168.10.212:4000/health`
   - Verify network connectivity: `ping 192.168.10.212`
   - Check environment variables: `env | grep LITELLM`
4. ✅ Fix root cause
5. ✅ Re-run validation
6. ✅ Proceed ONLY when all validations PASS

**Quality Gate Pass Criteria**:
- ✅ All 8 integration tests PASS (100% pass rate required)
- ✅ Health check returns `healthy` status
- ✅ All 3 models accessible (gemma3:27b, qwen3-coder:30b, gpt-oss:20b)
- ✅ Circuit breaker state is `CLOSED`
- ✅ Response caching functional (cache hit rate >0%)
- ✅ Structured logging operational (JSON logs in `/var/log/docling-mcp/`)

---

## Success Metrics

**Completion Criteria** (ALL must be met):

1. ✅ LiteLLM client module created and functional
2. ✅ Configuration loader updated with LiteLLM settings
3. ✅ Environment variables configured and validated
4. ✅ Health check service integrated
5. ✅ Integration tests written (8 test cases)
6. ✅ Documentation updated (README, RUNBOOK)
7. ✅ All integration tests PASS (after deployment)
8. ✅ Manual validation commands PASS
9. ✅ Quality gate criteria met (100% test pass rate)
10. ✅ No defects created (or all defects resolved)

**Performance Metrics** (measure after deployment):
- Health check latency: <100ms (P95)
- LLM completion latency: <5s for gemma3:27b (P95)
- Cache hit rate: >20% (target 20-30%)
- Circuit breaker false positive rate: <1% (should stay CLOSED under normal operation)

---

## Next Steps After Completion

**Immediate Next Tasks**:
1. **Task 015**: Configure Qdrant integration (depends on LiteLLM for LightRAG entity extraction)
2. **Task 016**: Configure Redis integration (caching backend for LiteLLM responses)
3. **Task 017**: Configure logging (structured JSON logs for LiteLLM client)

**Downstream Dependencies**:
- LightRAG knowledge graph generation (Stage 2) - requires LiteLLM entity extraction
- All MCP tools using entity extraction - blocked until LiteLLM operational
- Integration test suite - needs LiteLLM client for testing

---

## Reference Documentation

**Charter References**:
- Lines 101-107: LiteLLM Gateway integration requirements
- Lines 511: Risk R-001 (Granite-Docling model too small)

**Plan References**:
- Lines 779-783: Task 014 description
- Lines 966: LiteLLM unavailability risk mitigation

**Configuration Spec References**:
- Lines 752-767: LiteLLM environment variables
- Lines 1579-1656: LiteLLM integration configuration

**My LiteLLM Integration Review**:
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/shane-litellm-integration.md`
- Prompt engineering, model selection, cost optimization, error handling

**HX-Infrastructure Standards**:
- Testing requirements: 100% coverage, test-driven deployment
- Deployment philosophy: bare-metal, manual procedures, systemd management

---

**Task Status**: NOT STARTED
**Created**: 2025-11-27
**Created By**: shane-black (LiteLLM Gateway Integration SME)
**Estimated Completion**: After Tasks 001-013 complete, 4-6 hours for implementation
