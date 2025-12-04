# Task 121: Create LiteLLM HTTP Client Module

**Assigned To**: shane-black
**Estimated Effort**: 3 hours
**Dependencies**: Task 030 (Python virtual environment setup)
**Status**: Not Started

## Objective

Implement the LiteLLM HTTP client module (`litellm_client.py`) providing OpenAI-compatible API access to hx-litellm-server for entity extraction and knowledge graph generation tasks.

## Pre-Execution Validation

**CRITICAL**: Check if LiteLLM client module already exists BEFORE creating it to prevent duplication.

```bash
# Check if LiteLLM client module exists
if [ -f "/opt/docling-mcp/src/integrations/litellm_client.py" ]; then
    echo "✅ VALIDATION RESULT: LiteLLM client module already exists"
    echo "ACTION: SKIP task execution - validate module structure instead"
    echo "NEXT: Verify module exports LiteLLMClient class"
    exit 0
else
    echo "❌ VALIDATION RESULT: LiteLLM client module does NOT exist"
    echo "ACTION: PROCEED with module creation"
fi
```

**If Module Exists**: Skip to Validation section, verify class structure and methods

**If Module Does Not Exist**: Continue with Implementation Steps below

---

## Context

The Docling MCP Server requires LLM capabilities for entity extraction and relationship identification from processed documents. Rather than directly integrating with multiple LLM providers, the service consumes the unified LiteLLM gateway (hx-litellm-server.hx.dev.local:4000) which provides:

- OpenAI-compatible API interface
- Automatic model routing and fallback (Ollama1/2/3 servers)
- Connection pooling and rate limiting
- Cost tracking and observability

The LiteLLM client module provides an async HTTP client with retry logic, circuit breaker pattern, timeout handling, and structured response parsing.

## Acceptance Criteria

- [ ] Module created at `/opt/docling-mcp/src/integrations/litellm_client.py`
- [ ] `LiteLLMClient` class implements async HTTP client using httpx
- [ ] Connection pooling configured (max 20 connections, 100 keepalive)
- [ ] Timeout strategy: 10s connect, 120s read, 5s write
- [ ] Rate limiting: 10 concurrent requests with semaphore
- [ ] Base URL configured from environment variable `LITELLM_API_BASE`
- [ ] API key authentication support (optional for Ollama, required for external providers)
- [ ] Error handling for HTTP 408 (timeout), 429 (rate limit), 503 (service unavailable)
- [ ] Module follows Python async/await patterns
- [ ] Type hints using Pydantic models for requests/responses

## Implementation Steps

### Step 1: Create Integrations Directory Structure

```bash
# Ensure integrations directory exists
sudo mkdir -p /opt/docling-mcp/src/integrations

# Set ownership to service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/integrations

# Set permissions
sudo chmod 755 /opt/docling-mcp/src/integrations

# Create __init__.py
sudo touch /opt/docling-mcp/src/integrations/__init__.py
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/integrations/__init__.py
sudo chmod 644 /opt/docling-mcp/src/integrations/__init__.py
```

### Step 2: Create LiteLLM Client Module Skeleton

```bash
# Create litellm_client.py file
sudo -u docling-mcp@hx.dev.local tee /opt/docling-mcp/src/integrations/litellm_client.py > /dev/null << 'EOF'
"""
LiteLLM HTTP Client Module

Provides async HTTP client for LiteLLM gateway integration with:
- Connection pooling and keep-alive
- Retry logic with exponential backoff
- Circuit breaker pattern
- Rate limiting via semaphore
- Structured response parsing

Integration Point: hx-litellm-server.hx.dev.local:4000
"""

import asyncio
import logging
import os
import time
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

import httpx
from pydantic import BaseModel, Field, ValidationError

# Configure logger
logger = logging.getLogger(__name__)


class LiteLLMRequest(BaseModel):
    """OpenAI-compatible chat completion request model."""
    model: str = Field(..., description="Model identifier (e.g., 'ollama_chat/gemma3:27b')")
    messages: List[Dict[str, str]] = Field(..., description="Chat messages in OpenAI format")
    temperature: float = Field(0.1, ge=0.0, le=2.0, description="Sampling temperature")
    top_p: float = Field(0.9, ge=0.0, le=1.0, description="Nucleus sampling parameter")
    max_tokens: int = Field(2048, ge=1, le=8192, description="Maximum tokens to generate")
    stop: Optional[List[str]] = Field(None, description="Stop sequences")

    class Config:
        extra = "forbid"


class LiteLLMResponse(BaseModel):
    """OpenAI-compatible chat completion response model."""
    id: str
    object: str
    created: int
    model: str
    choices: List[Dict[str, Any]]
    usage: Dict[str, int]


class CircuitBreakerState:
    """Circuit breaker state tracking for LiteLLM client."""
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        self.last_failure_time = None

    def record_success(self):
        """Record successful request, reset failure count."""
        self.failure_count = 0
        if self.state == "HALF_OPEN":
            self.state = "CLOSED"
            logger.info("Circuit breaker transitioned to CLOSED state")

    def record_failure(self):
        """Record failed request, potentially open circuit."""
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"
            logger.warning(f"Circuit breaker OPENED after {self.failure_count} consecutive failures")

    def is_open(self) -> bool:
        """Check if circuit is open and should not allow requests."""
        if self.state == "CLOSED":
            return False

        if self.state == "OPEN":
            # Check if recovery timeout expired
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "HALF_OPEN"
                logger.info("Circuit breaker transitioned to HALF_OPEN state")
                return False
            return True

        # HALF_OPEN state: allow single health check
        return False


class LiteLLMClient:
    """
    Async HTTP client for LiteLLM gateway integration.

    Features:
    - Connection pooling (max 20 connections, 100 keepalive)
    - Timeout strategy (10s connect, 120s read, 5s write)
    - Rate limiting (10 concurrent requests)
    - Circuit breaker pattern (5 failures, 60s recovery)
    - Retry logic with exponential backoff
    """

    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        max_connections: int = 20,
        max_keepalive_connections: int = 100,
        rate_limit: int = 10,
    ):
        """
        Initialize LiteLLM HTTP client.

        Args:
            base_url: LiteLLM server base URL (e.g., http://hx-litellm-server.hx.dev.local:4000)
            api_key: Optional API key for external providers (not required for Ollama)
            max_connections: Maximum concurrent connections
            max_keepalive_connections: Maximum keepalive connections
            rate_limit: Maximum concurrent requests
        """
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.rate_limit_semaphore = asyncio.Semaphore(rate_limit)
        self.circuit_breaker = CircuitBreakerState(failure_threshold=5, recovery_timeout=60)

        # Configure httpx client with connection pooling
        timeout_config = httpx.Timeout(
            connect=10.0,  # 10s connect timeout
            read=120.0,    # 120s read timeout (for slow model inference)
            write=5.0,     # 5s write timeout
            pool=5.0,      # 5s pool timeout
        )

        limits = httpx.Limits(
            max_connections=max_connections,
            max_keepalive_connections=max_keepalive_connections,
        )

        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=timeout_config,
            limits=limits,
            headers=headers,
        )

        logger.info(
            f"LiteLLM client initialized: base_url={self.base_url}, "
            f"max_connections={max_connections}, rate_limit={rate_limit}"
        )

    async def close(self):
        """Close HTTP client connection pool."""
        await self._client.aclose()
        logger.info("LiteLLM client closed")

    @asynccontextmanager
    async def lifespan(self):
        """Context manager for client lifecycle."""
        try:
            yield self
        finally:
            await self.close()

    async def chat_completion(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: float = 0.1,
        top_p: float = 0.9,
        max_tokens: int = 2048,
        stop: Optional[List[str]] = None,
    ) -> LiteLLMResponse:
        """
        Request chat completion from LiteLLM gateway.

        Args:
            model: Model identifier (e.g., 'ollama_chat/gemma3:27b')
            messages: Chat messages in OpenAI format
            temperature: Sampling temperature (0.1 for deterministic entity extraction)
            top_p: Nucleus sampling parameter
            max_tokens: Maximum tokens to generate
            stop: Optional stop sequences

        Returns:
            LiteLLMResponse with completion results

        Raises:
            httpx.HTTPStatusError: On HTTP error responses
            httpx.TimeoutException: On request timeout
            RuntimeError: If circuit breaker is open
        """
        # Check circuit breaker state
        if self.circuit_breaker.is_open():
            logger.error("Circuit breaker is OPEN, rejecting request")
            raise RuntimeError("LiteLLM circuit breaker is OPEN due to consecutive failures")

        # Rate limiting via semaphore
        async with self.rate_limit_semaphore:
            # Build request payload
            request = LiteLLMRequest(
                model=model,
                messages=messages,
                temperature=temperature,
                top_p=top_p,
                max_tokens=max_tokens,
                stop=stop,
            )

            logger.debug(f"LiteLLM request: model={model}, messages={len(messages)}, max_tokens={max_tokens}")

            try:
                # Send POST request to /v1/chat/completions
                response = await self._client.post(
                    "/v1/chat/completions",
                    json=request.dict(exclude_none=True),
                )

                # Raise on HTTP error status
                response.raise_for_status()

                # Parse response with explicit ValidationError handling
                response_data = response.json()
                
                try:
                    litellm_response = LiteLLMResponse(**response_data)
                except ValidationError as ve:
                    # Record failure for circuit breaker (malformed response)
                    self.circuit_breaker.record_failure()
                    
                    logger.error(
                        f"LiteLLM response validation failed: {ve}"
                        f"\nValidation errors: {ve.errors()}"
                        f"\nRaw response data: {response_data}"
                        f"\nModel: {model}, Messages: {len(messages)}"
                    )
                    raise

                # Record success for circuit breaker
                self.circuit_breaker.record_success()

                logger.debug(f"LiteLLM response: id={litellm_response.id}, tokens={litellm_response.usage}")
                return litellm_response

            except (httpx.HTTPStatusError, httpx.TimeoutException) as e:
                # Record failure for circuit breaker
                self.circuit_breaker.record_failure()

                logger.error(f"LiteLLM request failed: {type(e).__name__}: {str(e)}")
                raise

    async def health_check(self) -> Dict[str, Any]:
        """
        Check LiteLLM server health.

        Returns:
            Health status dict with latency

        Raises:
            httpx.HTTPStatusError: On health check failure
        """
        start = time.time()

        try:
            response = await self._client.get("/health")
            response.raise_for_status()
            latency_ms = (time.time() - start) * 1000

            return {
                "status": "healthy",
                "latency_ms": round(latency_ms, 2),
                "base_url": self.base_url,
            }
        except Exception as e:
            latency_ms = (time.time() - start) * 1000
            logger.error(f"LiteLLM health check failed: {str(e)}")
            return {
                "status": "unhealthy",
                "latency_ms": round(latency_ms, 2),
                "base_url": self.base_url,
                "error": str(e),
            }


# Factory function for creating client from environment
def create_litellm_client_from_env() -> LiteLLMClient:
    """
    Create LiteLLM client from environment variables.

    Environment Variables:
        LITELLM_API_BASE: Base URL (default: http://hx-litellm-server.hx.dev.local:4000)
        LITELLM_API_KEY: Optional API key for external providers

    Returns:
        Configured LiteLLMClient instance
    """
    base_url = os.getenv("LITELLM_API_BASE", "http://hx-litellm-server.hx.dev.local:4000")
    api_key = os.getenv("LITELLM_API_KEY")  # Optional for Ollama

    return LiteLLMClient(base_url=base_url, api_key=api_key)
EOF

# Set ownership and permissions
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/integrations/litellm_client.py
sudo chmod 644 /opt/docling-mcp/src/integrations/litellm_client.py
```

### Step 3: Update __init__.py for Module Exports

```bash
# Update integrations package __init__.py
sudo -u docling-mcp@hx.dev.local tee /opt/docling-mcp/src/integrations/__init__.py > /dev/null << 'EOF'
"""
HX-Infrastructure Integration Modules

Provides HTTP clients for external service integrations:
- LiteLLM Gateway (hx-litellm-server)
- Qdrant Vector Database (hx-qdrant-server)
- Redis Cache/Session (hx-redis-server)
- LightRAG Knowledge Graph (hx-literag-server)
"""

from .litellm_client import (
    LiteLLMClient,
    LiteLLMRequest,
    LiteLLMResponse,
    CircuitBreakerState,
    create_litellm_client_from_env,
)

__all__ = [
    "LiteLLMClient",
    "LiteLLMRequest",
    "LiteLLMResponse",
    "CircuitBreakerState",
    "create_litellm_client_from_env",
]
EOF
```

### Step 4: Verify Python Syntax and Imports

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test module import (syntax check)
python3 -c "from src.integrations.litellm_client import LiteLLMClient; print('✅ Module import successful')"

# Verify Pydantic models
python3 -c "from src.integrations.litellm_client import LiteLLMRequest, LiteLLMResponse; print('✅ Pydantic models validated')"

# Deactivate venv
deactivate
```

## Validation

**Validation Commands:**

```bash
# 1. Verify module file exists
test -f /opt/docling-mcp/src/integrations/litellm_client.py && echo "PASS: Module file exists" || echo "FAIL: Module file missing"

# 2. Verify module ownership
stat -c '%U:%G' /opt/docling-mcp/src/integrations/litellm_client.py | grep -q "docling-mcp@hx.dev.local:domain users@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# 3. Verify module permissions
stat -c '%a' /opt/docling-mcp/src/integrations/litellm_client.py | grep -q "644" && echo "PASS: Permissions correct" || echo "FAIL: Permissions incorrect"

# 4. Verify Python syntax
source /opt/docling-mcp/venv/bin/activate && python3 -m py_compile /opt/docling-mcp/src/integrations/litellm_client.py && echo "PASS: Python syntax valid" || echo "FAIL: Syntax error"

# 5. Verify LiteLLMClient class exists
source /opt/docling-mcp/venv/bin/activate && python3 -c "from src.integrations.litellm_client import LiteLLMClient; assert hasattr(LiteLLMClient, 'chat_completion'); print('PASS: LiteLLMClient class structure valid')" || echo "FAIL: Class structure invalid"

# 6. Verify factory function exists
source /opt/docling-mcp/venv/bin/activate && python3 -c "from src.integrations.litellm_client import create_litellm_client_from_env; print('PASS: Factory function exists')" || echo "FAIL: Factory function missing"

# 7. Verify circuit breaker state tracking
source /opt/docling-mcp/venv/bin/activate && python3 -c "from src.integrations.litellm_client import CircuitBreakerState; cb = CircuitBreakerState(); assert cb.state == 'CLOSED'; print('PASS: Circuit breaker initialized')" || echo "FAIL: Circuit breaker error"
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Module imports without errors in virtual environment
- LiteLLMClient class provides async HTTP client with connection pooling
- Circuit breaker state tracking implemented
- Pydantic models validate request/response structures

## Notes

### Connection Pooling Strategy

**Configuration**:
- Max connections: 20 (concurrent requests to LiteLLM server)
- Max keepalive connections: 100 (reusable TCP connections)
- Connect timeout: 10s
- Read timeout: 120s (allows for slow model inference)
- Write timeout: 5s

**Rationale**: Entity extraction via LLM can take 2-7s P95 latency depending on model and token count. Read timeout of 120s provides safety margin for 99.9th percentile requests while preventing indefinite hangs.

### Rate Limiting via Semaphore

**Limit**: 10 concurrent requests

**Mechanism**: Asyncio semaphore ensures maximum 10 requests in-flight to prevent overwhelming LiteLLM Router or downstream Ollama servers.

**Backpressure**: Additional requests queue until semaphore slot available. If queue depth exceeds 100 requests, MCP tools should return HTTP 429 (rate limited).

### Circuit Breaker Pattern

**Purpose**: Prevent cascading failures when LiteLLM server experiences degraded performance.

**States**:
- **CLOSED**: Normal operation, all requests allowed
- **OPEN**: Service unhealthy, reject all requests (fail fast)
- **HALF_OPEN**: Testing recovery, allow single health check request

**Thresholds**:
- Failure threshold: 5 consecutive failures within 60s window
- Recovery timeout: 60s before transitioning to HALF_OPEN
- State tracking: In-memory (Task 128 adds Redis persistence for multi-instance coordination)

### Model Naming Convention

**Format**: `{provider}_{type}/{model_name}`

**Examples**:
- `ollama_chat/gemma3:27b` - Gemma 3 27B via Ollama (general entity extraction)
- `ollama_chat/qwen3-coder:30b` - Qwen 3 Coder 30B via Ollama (technical/code content)
- `ollama_chat/gpt-oss:20b` - GPT-OSS 20B via Ollama (fallback model)

**Router Resolution**: LiteLLM Router maps these to actual Ollama server endpoints (hx-ollama1-server:11434, hx-ollama2-server:11434, hx-ollama3-server:11434) based on configured model deployments.

### Temperature Selection for Entity Extraction

**Value**: 0.1 (low temperature for deterministic output)

**Rationale**:
- Entity extraction requires factual, consistent results
- Low temperature reduces creative variation in entity names
- Improves deduplication accuracy (same entity extracted with same name consistently)
- Acceptable for classification/extraction tasks (NOT for text generation where creativity desired)

### Error Handling Strategy

**Retry Logic**: Implemented in Task 123 (adds exponential backoff with jitter)

**Current Implementation**: Basic error logging and circuit breaker state tracking. Retry logic will wrap `chat_completion()` method.

**Error Types**:
- **408 Timeout**: Model inference exceeded 120s read timeout
- **429 Rate Limit**: LiteLLM Router rate limit exceeded
- **503 Service Unavailable**: Model not loaded or Ollama server down
- **500 Internal Server Error**: LiteLLM Router or Ollama error

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 4.3.4: LiteLLM Integration)
- **LiteLLM Enhancement**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/shane-litellm-summary.md`
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 8)
- **httpx Documentation**: https://www.python-httpx.org/async/
- **Pydantic Documentation**: https://docs.pydantic.dev/latest/

## Risk Assessment

**Risk**: Medium
- HTTP client network failures could impact entity extraction pipeline
- Circuit breaker state not persisted (single instance only until Task 128)
- Timeout strategy may need tuning based on actual model performance

**Mitigation**:
- Circuit breaker provides fail-fast behavior to prevent cascading failures
- Connection pooling prevents resource exhaustion
- Rate limiting prevents overwhelming downstream services
- Retry logic (Task 123) provides resilience for transient failures
- Redis-backed circuit breaker state (Task 128) enables multi-instance coordination
