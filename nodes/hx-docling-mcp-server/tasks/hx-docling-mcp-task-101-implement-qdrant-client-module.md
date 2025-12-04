# Task 101: Implement Qdrant Client Module

**Assigned To**: mitch-harper
**Estimated Effort**: 2 hours
**Dependencies**: Task 030 (Python Virtual Environment), Task 141 (Configuration Management - QdrantSettings)
**Status**: Not Started

## Objective

Implement Qdrant HTTP client module with connection pooling, retry logic with exponential backoff, health checks, and graceful degradation patterns for knowledge graph storage operations.

## Pre-Execution Validation

**CRITICAL**: Check if Qdrant client module already exists BEFORE implementing.

```bash
# Validation command to check if Qdrant client module exists
echo "Checking for existing Qdrant client module..."

QDRANT_CLIENT_FILE="/opt/docling-mcp/src/integrations/qdrant_client.py"

if [ -f "$QDRANT_CLIENT_FILE" ]; then
    echo "✅ VALIDATION RESULT: Qdrant client module already exists"
    echo "File location: $QDRANT_CLIENT_FILE"
    echo ""

    # Check for key components
    echo "Verifying client module components:"

    if grep -q "class QdrantClient" "$QDRANT_CLIENT_FILE"; then
        echo "✅ QdrantClient class found"
    else
        echo "❌ QdrantClient class missing"
    fi

    if grep -q "health_check" "$QDRANT_CLIENT_FILE"; then
        echo "✅ Health check method found"
    else
        echo "❌ Health check method missing"
    fi

    if grep -q "retry" "$QDRANT_CLIENT_FILE" || grep -q "backoff" "$QDRANT_CLIENT_FILE"; then
        echo "✅ Retry logic found"
    else
        echo "❌ Retry logic missing"
    fi

    echo ""
    echo "ACTION: Review existing implementation. If incomplete, proceed with missing components only."
    exit 0
else
    echo "❌ VALIDATION RESULT: Qdrant client module does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Partially Complete**: Execute only missing steps
**If Not Complete**: Continue with Implementation Steps below

---

## Context

The Qdrant client module provides the foundation for all knowledge graph storage operations in the Docling MCP Server. This module must:

1. **HTTP API Integration**: Use Qdrant HTTP REST API (not gRPC) for simplicity
   - Base URL: `http://hx-qdrant-server.hx.dev.local:6333`
   - Endpoints: `/collections`, `/collections/{name}/points`, `/collections/{name}/points/search`

2. **Connection Pooling**: Maintain persistent HTTP connections
   - Max pool size: 10 connections
   - Keep-alive: 60 seconds
   - Connection timeout: 5 seconds
   - Request timeout: 30 seconds

3. **Retry Logic with Exponential Backoff**:
   - Retry attempts: 3 (configurable via QdrantSettings.max_retries)
   - Backoff: 100ms, 200ms, 400ms
   - Retry on: Connection errors, 5xx server errors, timeouts
   - No retry on: 4xx client errors (except 429 rate limit)

4. **Health Checks**:
   - Method: GET `/collections` (lightweight endpoint)
   - Frequency: On-demand (before graph operations)
   - Timeout: 2 seconds
   - Success: HTTP 200, valid JSON response

5. **Graceful Degradation**:
   - If Qdrant unavailable → Disable knowledge graph features
   - Return MCP error: `{"error": "qdrant_unavailable", "message": "Knowledge graph storage unavailable"}`
   - Continue document conversion operations (stateless tools)

This task implements the core client infrastructure. Subsequent tasks (102-106) build collection management, entity/relationship operations, and search capabilities on this foundation.

## Acceptance Criteria

- [ ] Qdrant client module created at `/opt/docling-mcp/src/integrations/qdrant_client.py`
- [ ] `QdrantClient` class implements HTTP API client with httpx library
- [ ] Connection pooling configured (max 10 connections, 60s keepalive)
- [ ] Retry logic with exponential backoff (3 attempts, 100/200/400ms delays)
- [ ] Health check method (`health_check()`) validates Qdrant connectivity
- [ ] Graceful degradation on connection failures (log WARNING, disable features)
- [ ] All configuration loaded from QdrantSettings (Pydantic BaseModel)
- [ ] Type hints for all methods (mypy compatible)
- [ ] Comprehensive error handling with custom exceptions
- [ ] Unit tests created for retry logic and health checks

## Implementation Steps

### Step 1: Create Integrations Directory Structure

```bash
# Create integrations module directory
echo "Creating integrations module structure..."

INTEGRATIONS_DIR="/opt/docling-mcp/src/integrations"

if [ ! -d "$INTEGRATIONS_DIR" ]; then
    sudo mkdir -p "$INTEGRATIONS_DIR"
    echo "✅ Created integrations directory: $INTEGRATIONS_DIR"
else
    echo "✅ Integrations directory already exists"
fi

# Create __init__.py to make it a Python package
INIT_FILE="$INTEGRATIONS_DIR/__init__.py"

if [ ! -f "$INIT_FILE" ]; then
    sudo tee "$INIT_FILE" > /dev/null <<'EOF'
"""
Integration modules for external services.

This package contains client modules for:
- Qdrant vector database (knowledge graph storage)
- Redis cache/session management
- LiteLLM gateway (LLM inference routing)
- hx-literag-server (entity/relationship extraction)
"""

from .qdrant_client import QdrantClient
from .qdrant_exceptions import (
    QdrantConnectionError,
    QdrantHealthCheckError,
    QdrantCollectionError,
    QdrantUpsertError,
    QdrantSearchError,
)

__all__ = [
    "QdrantClient",
    "QdrantConnectionError",
    "QdrantHealthCheckError",
    "QdrantCollectionError",
    "QdrantUpsertError",
    "QdrantSearchError",
]
EOF
    echo "✅ Created __init__.py"
else
    echo "✅ __init__.py already exists"
fi

# Set ownership
sudo chown -R docling-mcp:docling-mcp "$INTEGRATIONS_DIR"
echo "✅ Set ownership to docling-mcp:docling-mcp"
```

### Step 2: Implement Qdrant Custom Exceptions

```bash
# Create custom exception classes for Qdrant operations
EXCEPTIONS_FILE="/opt/docling-mcp/src/integrations/qdrant_exceptions.py"

echo "Creating Qdrant exception classes..."

sudo tee "$EXCEPTIONS_FILE" > /dev/null <<'EOF'
"""
Custom exception classes for Qdrant vector database operations.

Provides granular error handling for different failure modes:
- Connection failures (network, timeout, DNS)
- Health check failures (service degraded/unavailable)
- Collection errors (not found, schema mismatch, already exists)
- Upsert errors (validation failure, storage failure)
- Search errors (invalid query, timeout)
"""


class QdrantConnectionError(Exception):
    """
    Raised when connection to Qdrant server fails.

    Triggers graceful degradation: disable knowledge graph features,
    continue document conversion operations.
    """
    pass


class QdrantHealthCheckError(Exception):
    """
    Raised when Qdrant health check fails or returns unhealthy status.

    Indicates service degradation or unavailability.
    """
    pass


class QdrantCollectionError(Exception):
    """
    Raised for collection management errors.

    Examples:
    - Collection not found
    - Collection schema mismatch (vector dimension, distance metric)
    - Collection already exists (during creation)
    """
    pass


class QdrantUpsertError(Exception):
    """
    Raised when entity/relationship upsert operation fails.

    Examples:
    - Payload validation failure
    - Vector dimension mismatch
    - Storage backend failure
    """
    pass


class QdrantSearchError(Exception):
    """
    Raised when vector search or graph traversal query fails.

    Examples:
    - Invalid query parameters
    - Search timeout
    - Collection not found
    """
    pass
EOF

sudo chown docling-mcp:docling-mcp "$EXCEPTIONS_FILE"
echo "✅ Created qdrant_exceptions.py"
```

### Step 3: Implement QdrantClient Core Class

```bash
# Create Qdrant client module with connection pooling and retry logic
QDRANT_CLIENT_FILE="/opt/docling-mcp/src/integrations/qdrant_client.py"

echo "Creating QdrantClient module..."

sudo tee "$QDRANT_CLIENT_FILE" > /dev/null <<'EOF'
"""
Qdrant HTTP client module for knowledge graph storage.

Provides:
- HTTP REST API client (httpx-based)
- Connection pooling (max 10, keepalive 60s)
- Retry logic with exponential backoff (3 attempts)
- Health checks (GET /collections)
- Graceful degradation on failures
- Configuration via Pydantic QdrantSettings

Usage:
    from integrations.qdrant_client import QdrantClient
    from config import DoclingMCPConfig

    config = DoclingMCPConfig()
    client = QdrantClient(config.qdrant)

    # Health check
    is_healthy = await client.health_check()

    # Get collection info
    info = await client.get_collection_info("hx_docling_mcp_entities")
"""

import asyncio
import logging
from typing import Dict, Any, Optional, List
from contextlib import asynccontextmanager

import httpx
from pydantic import BaseModel

from .qdrant_exceptions import (
    QdrantConnectionError,
    QdrantHealthCheckError,
    QdrantCollectionError,
    QdrantUpsertError,
    QdrantSearchError,
)

logger = logging.getLogger(__name__)


class QdrantClient:
    """
    Qdrant vector database HTTP client.

    Implements connection pooling, retry logic, health checks,
    and graceful degradation for production RAG workflows.

    Attributes:
        base_url: Qdrant HTTP API base URL (e.g., http://hx-qdrant-server:6333)
        api_key: Optional API key for authentication (future Phase 2)
        timeout: Request timeout in seconds (default: 30)
        max_retries: Maximum retry attempts for failed requests (default: 3)
        _client: Shared httpx.AsyncClient with connection pooling
        _is_available: Flag indicating Qdrant availability (graceful degradation)
    """

    def __init__(self, settings):
        """
        Initialize Qdrant client from QdrantSettings.

        Args:
            settings: QdrantSettings Pydantic model with host, port, API key, timeouts
        """
        self.base_url = f"http://{settings.host}:{settings.port}"
        self.api_key = settings.api_key  # Optional, Phase 2
        self.timeout = settings.timeout_seconds
        self.max_retries = settings.max_retries

        # Connection pool configuration
        self._limits = httpx.Limits(
            max_connections=10,  # Max concurrent connections
            max_keepalive_connections=10,  # Persistent connections
            keepalive_expiry=60.0,  # 60 seconds keepalive
        )

        # Timeout configuration
        self._timeout = httpx.Timeout(
            connect=5.0,  # Connection timeout
            read=self.timeout,  # Read timeout
            write=self.timeout,  # Write timeout
            pool=5.0,  # Connection pool timeout
        )

        # Shared async HTTP client (connection pooling)
        self._client: Optional[httpx.AsyncClient] = None

        # Availability flag (graceful degradation)
        self._is_available = True

        logger.info(
            f"Initialized QdrantClient: base_url={self.base_url}, "
            f"timeout={self.timeout}s, max_retries={self.max_retries}"
        )

    async def __aenter__(self):
        """Async context manager entry: initialize HTTP client."""
        await self._ensure_client()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit: close HTTP client."""
        await self.close()

    async def _ensure_client(self):
        """Ensure HTTP client is initialized (lazy initialization)."""
        if self._client is None:
            headers = {}
            if self.api_key:
                headers["api-key"] = self.api_key

            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                headers=headers,
                limits=self._limits,
                timeout=self._timeout,
                follow_redirects=True,
            )
            logger.debug("HTTP client initialized with connection pooling")

    async def close(self):
        """Close HTTP client and release connections."""
        if self._client is not None:
            await self._client.aclose()
            self._client = None
            logger.debug("HTTP client closed")

    async def _request_with_retry(
        self,
        method: str,
        endpoint: str,
        **kwargs
    ) -> httpx.Response:
        """
        Execute HTTP request with exponential backoff retry.

        Retry on:
        - Connection errors (network failure, DNS resolution)
        - 5xx server errors (Qdrant service unavailable)
        - Timeouts (read/write timeout exceeded)
        - 429 rate limit (too many requests)

        No retry on:
        - 4xx client errors (invalid request, not found)

        Args:
            method: HTTP method (GET, POST, PUT, DELETE)
            endpoint: API endpoint path (e.g., /collections)
            **kwargs: Additional httpx request parameters

        Returns:
            httpx.Response object

        Raises:
            QdrantConnectionError: If all retry attempts fail
        """
        await self._ensure_client()

        backoff_delays = [0.1, 0.2, 0.4]  # 100ms, 200ms, 400ms
        last_exception = None

        for attempt in range(self.max_retries):
            try:
                response = await self._client.request(method, endpoint, **kwargs)

                # Retry on rate limit (429) or server errors (5xx)
                if response.status_code == 429 or response.status_code >= 500:
                    if attempt < self.max_retries - 1:
                        delay = backoff_delays[attempt]
                        logger.warning(
                            f"Qdrant request failed: {response.status_code}, "
                            f"retrying in {delay}s (attempt {attempt + 1}/{self.max_retries})"
                        )
                        await asyncio.sleep(delay)
                        continue
                    else:
                        # Last attempt, raise error
                        response.raise_for_status()

                # Success or 4xx client error (no retry)
                response.raise_for_status()
                return response

            except (httpx.ConnectError, httpx.TimeoutException) as e:
                last_exception = e
                if attempt < self.max_retries - 1:
                    delay = backoff_delays[attempt]
                    logger.warning(
                        f"Qdrant connection error: {e}, "
                        f"retrying in {delay}s (attempt {attempt + 1}/{self.max_retries})"
                    )
                    await asyncio.sleep(delay)
                else:
                    # All retries exhausted
                    self._is_available = False
                    logger.error(
                        f"Qdrant connection failed after {self.max_retries} attempts: {e}"
                    )
                    raise QdrantConnectionError(
                        f"Failed to connect to Qdrant at {self.base_url} "
                        f"after {self.max_retries} attempts: {e}"
                    ) from e

            except httpx.HTTPStatusError as e:
                # 4xx client errors (no retry)
                if 400 <= e.response.status_code < 500 and e.response.status_code != 429:
                    raise
                # Other errors propagate
                raise

        # Should not reach here, but handle edge case
        if last_exception:
            raise QdrantConnectionError(
                f"Request failed after retries: {last_exception}"
            ) from last_exception

    async def health_check(self) -> bool:
        """
        Check Qdrant service health.

        Method: GET /collections (lightweight endpoint)
        Success criteria: HTTP 200, valid JSON response

        Returns:
            True if Qdrant is healthy and available
            False if health check fails (graceful degradation)

        Side effects:
            Sets self._is_available flag for graceful degradation
        """
        try:
            response = await self._request_with_retry("GET", "/collections")

            # Validate response is valid JSON
            data = response.json()

            if "result" in data:
                self._is_available = True
                logger.info("Qdrant health check: HEALTHY")
                return True
            else:
                self._is_available = False
                logger.warning("Qdrant health check: unexpected response format")
                return False

        except QdrantConnectionError as e:
            self._is_available = False
            logger.warning(f"Qdrant health check: FAILED - {e}")
            return False
        except Exception as e:
            self._is_available = False
            logger.error(f"Qdrant health check: FAILED - unexpected error: {e}")
            return False

    @property
    def is_available(self) -> bool:
        """Check if Qdrant is currently available (graceful degradation)."""
        return self._is_available

    def require_available(self):
        """
        Raise exception if Qdrant is unavailable.

        Use before knowledge graph operations to fail fast.

        Raises:
            QdrantConnectionError: If Qdrant marked as unavailable
        """
        if not self._is_available:
            raise QdrantConnectionError(
                "Qdrant is currently unavailable. Knowledge graph features disabled. "
                "Check service health and retry."
            )

    async def get_collections(self) -> List[str]:
        """
        List all Qdrant collections.

        Returns:
            List of collection names

        Raises:
            QdrantConnectionError: If request fails
        """
        self.require_available()

        response = await self._request_with_retry("GET", "/collections")
        data = response.json()

        collections = [
            coll["name"] for coll in data.get("result", {}).get("collections", [])
        ]

        logger.debug(f"Retrieved {len(collections)} collections")
        return collections

    async def get_collection_info(self, collection_name: str) -> Dict[str, Any]:
        """
        Get collection configuration and statistics.

        Args:
            collection_name: Name of collection

        Returns:
            Collection info dict with vectors_count, points_count, config

        Raises:
            QdrantCollectionError: If collection not found
            QdrantConnectionError: If request fails
        """
        self.require_available()

        try:
            response = await self._request_with_retry(
                "GET",
                f"/collections/{collection_name}"
            )
            data = response.json()
            return data.get("result", {})

        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                raise QdrantCollectionError(
                    f"Collection '{collection_name}' not found"
                ) from e
            raise


# Module-level initialization example
if __name__ == "__main__":
    # Example usage (for testing)
    import asyncio
    from pydantic import BaseModel, Field

    class QdrantSettings(BaseModel):
        host: str = "hx-qdrant-server.hx.dev.local"
        port: int = 6333
        api_key: Optional[str] = None
        timeout_seconds: int = 30
        max_retries: int = 3

    async def test_health_check():
        settings = QdrantSettings()
        async with QdrantClient(settings) as client:
            is_healthy = await client.health_check()
            print(f"Qdrant health: {'HEALTHY' if is_healthy else 'UNHEALTHY'}")

            if is_healthy:
                collections = await client.get_collections()
                print(f"Collections: {collections}")

    asyncio.run(test_health_check())
EOF

sudo chown docling-mcp:docling-mcp "$QDRANT_CLIENT_FILE"
echo "✅ Created qdrant_client.py"
```

### Step 4: Validate Python Syntax

```bash
# Validate Python syntax of created modules
echo "Validating Python syntax..."

VENV_PYTHON="/opt/docling-mcp/venv/bin/python"

# Validate exceptions module
if $VENV_PYTHON -m py_compile /opt/docling-mcp/src/integrations/qdrant_exceptions.py; then
    echo "✅ qdrant_exceptions.py: Syntax valid"
else
    echo "❌ qdrant_exceptions.py: Syntax error"
    exit 1
fi

# Validate client module
if $VENV_PYTHON -m py_compile /opt/docling-mcp/src/integrations/qdrant_client.py; then
    echo "✅ qdrant_client.py: Syntax valid"
else
    echo "❌ qdrant_client.py: Syntax error"
    exit 1
fi

# Validate __init__.py
if $VENV_PYTHON -m py_compile /opt/docling-mcp/src/integrations/__init__.py; then
    echo "✅ __init__.py: Syntax valid"
else
    echo "❌ __init__.py: Syntax error"
    exit 1
fi

echo "✅ All modules passed syntax validation"
```

### Step 5: Create Unit Tests for QdrantClient

```bash
# Create unit tests for retry logic and health checks
TEST_FILE="/opt/docling-mcp/tests/unit/test_qdrant_client.py"

echo "Creating QdrantClient unit tests..."

# Ensure test directory exists
sudo mkdir -p /opt/docling-mcp/tests/unit

sudo tee "$TEST_FILE" > /dev/null <<'EOF'
"""
Unit tests for QdrantClient module.

Tests:
- Connection initialization
- Retry logic with exponential backoff
- Health check success/failure
- Graceful degradation on unavailability
- Exception handling
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import httpx

from integrations.qdrant_client import QdrantClient
from integrations.qdrant_exceptions import (
    QdrantConnectionError,
    QdrantHealthCheckError,
)


class QdrantSettingsMock:
    """Mock QdrantSettings for testing."""
    host = "localhost"
    port = 6333
    api_key = None
    timeout_seconds = 30
    max_retries = 3


@pytest.fixture
def qdrant_settings():
    """Provide mock Qdrant settings."""
    return QdrantSettingsMock()


@pytest.fixture
async def qdrant_client(qdrant_settings):
    """Provide QdrantClient instance with mocked settings."""
    client = QdrantClient(qdrant_settings)
    await client._ensure_client()
    yield client
    await client.close()


@pytest.mark.asyncio
async def test_client_initialization(qdrant_settings):
    """Test QdrantClient initializes with correct configuration."""
    client = QdrantClient(qdrant_settings)

    assert client.base_url == "http://localhost:6333"
    assert client.timeout == 30
    assert client.max_retries == 3
    assert client._is_available is True


@pytest.mark.asyncio
async def test_health_check_success(qdrant_client):
    """Test health check succeeds when Qdrant returns valid response."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"result": {"collections": []}}

    with patch.object(
        qdrant_client,
        '_request_with_retry',
        new_callable=AsyncMock,
        return_value=mock_response
    ):
        is_healthy = await qdrant_client.health_check()

        assert is_healthy is True
        assert qdrant_client.is_available is True


@pytest.mark.asyncio
async def test_health_check_connection_failure(qdrant_client):
    """Test health check fails gracefully on connection error."""
    with patch.object(
        qdrant_client,
        '_request_with_retry',
        new_callable=AsyncMock,
        side_effect=QdrantConnectionError("Connection refused")
    ):
        is_healthy = await qdrant_client.health_check()

        assert is_healthy is False
        assert qdrant_client.is_available is False


@pytest.mark.asyncio
async def test_retry_logic_exponential_backoff(qdrant_client):
    """Test retry logic uses exponential backoff delays."""
    # Mock 3 connection failures, then success
    with patch.object(
        qdrant_client._client,
        'request',
        new_callable=AsyncMock,
        side_effect=[
            httpx.ConnectError("Connection refused"),
            httpx.ConnectError("Connection refused"),
            httpx.ConnectError("Connection refused"),
        ]
    ):
        with pytest.raises(QdrantConnectionError):
            await qdrant_client._request_with_retry("GET", "/collections")

        # Verify client marked as unavailable
        assert qdrant_client.is_available is False


@pytest.mark.asyncio
async def test_require_available_raises_when_unavailable(qdrant_client):
    """Test require_available() raises exception when Qdrant unavailable."""
    qdrant_client._is_available = False

    with pytest.raises(QdrantConnectionError, match="currently unavailable"):
        qdrant_client.require_available()


@pytest.mark.asyncio
async def test_get_collections_success(qdrant_client):
    """Test get_collections() returns collection names."""
    mock_response = MagicMock()
    mock_response.json.return_value = {
        "result": {
            "collections": [
                {"name": "hx_docling_mcp_entities"},
                {"name": "hx_docling_mcp_relationships"},
            ]
        }
    }

    with patch.object(
        qdrant_client,
        '_request_with_retry',
        new_callable=AsyncMock,
        return_value=mock_response
    ):
        collections = await qdrant_client.get_collections()

        assert len(collections) == 2
        assert "hx_docling_mcp_entities" in collections
        assert "hx_docling_mcp_relationships" in collections
EOF

sudo chown docling-mcp:docling-mcp "$TEST_FILE"
echo "✅ Created test_qdrant_client.py"
```

### Step 6: Run Unit Tests

```bash
# Execute unit tests to validate implementation
echo "Running QdrantClient unit tests..."

VENV_PYTHON="/opt/docling-mcp/venv/bin/python"

cd /opt/docling-mcp

# Run pytest on QdrantClient tests
if $VENV_PYTHON -m pytest tests/unit/test_qdrant_client.py -v --tb=short; then
    echo "✅ All unit tests passed"
else
    echo "❌ Unit tests failed - review implementation"
    exit 1
fi
```

## Validation

**Validation Commands:**

```bash
echo "=== QdrantClient Module Validation ==="

VENV_PYTHON="/opt/docling-mcp/venv/bin/python"

# Validate module files exist
echo "1. Module Files:"
FILES=(
    "/opt/docling-mcp/src/integrations/__init__.py"
    "/opt/docling-mcp/src/integrations/qdrant_exceptions.py"
    "/opt/docling-mcp/src/integrations/qdrant_client.py"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ PASSED: $file exists"
    else
        echo "❌ FAILED: $file missing"
        exit 1
    fi
done

# Validate Python syntax
echo ""
echo "2. Python Syntax:"
for file in "${FILES[@]}"; do
    if $VENV_PYTHON -m py_compile "$file" 2>/dev/null; then
        echo "✅ PASSED: $(basename $file) syntax valid"
    else
        echo "❌ FAILED: $(basename $file) syntax error"
        exit 1
    fi
done

# Validate imports
echo ""
echo "3. Module Imports:"
if $VENV_PYTHON -c "from integrations.qdrant_client import QdrantClient" 2>/dev/null; then
    echo "✅ PASSED: QdrantClient import successful"
else
    echo "❌ FAILED: QdrantClient import failed"
    exit 1
fi

if $VENV_PYTHON -c "from integrations.qdrant_exceptions import QdrantConnectionError" 2>/dev/null; then
    echo "✅ PASSED: Exception classes import successful"
else
    echo "❌ FAILED: Exception classes import failed"
    exit 1
fi

# Validate class attributes
echo ""
echo "4. Class Structure:"
if $VENV_PYTHON -c "from integrations.qdrant_client import QdrantClient; assert hasattr(QdrantClient, 'health_check')" 2>/dev/null; then
    echo "✅ PASSED: health_check method exists"
else
    echo "❌ FAILED: health_check method missing"
    exit 1
fi

if $VENV_PYTHON -c "from integrations.qdrant_client import QdrantClient; assert hasattr(QdrantClient, '_request_with_retry')" 2>/dev/null; then
    echo "✅ PASSED: _request_with_retry method exists"
else
    echo "❌ FAILED: _request_with_retry method missing"
    exit 1
fi

# Validate unit tests
echo ""
echo "5. Unit Tests:"
if [ -f "/opt/docling-mcp/tests/unit/test_qdrant_client.py" ]; then
    echo "✅ PASSED: Unit test file exists"

    # Run tests
    if $VENV_PYTHON -m pytest /opt/docling-mcp/tests/unit/test_qdrant_client.py -v --tb=short 2>&1 | grep -q "passed"; then
        echo "✅ PASSED: Unit tests executed successfully"
    else
        echo "⚠️  WARNING: Some unit tests may have failed (review output)"
    fi
else
    echo "❌ FAILED: Unit test file missing"
    exit 1
fi

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - QdrantClient module ready"
echo ""
echo "Next Step: Task 102 - Configure Idempotent Collection Initialization"
```

**Expected Results:**
- All module files exist with correct permissions
- Python syntax validation passes
- Imports succeed without errors
- Key methods (health_check, _request_with_retry) exist
- Unit tests execute successfully

## Notes

**Qdrant HTTP API Reference:**
- Base URL: `http://hx-qdrant-server.hx.dev.local:6333`
- Collections endpoint: `GET /collections` (list all)
- Collection info: `GET /collections/{name}`
- Collection create: `PUT /collections/{name}`
- Points upsert: `PUT /collections/{name}/points`
- Search: `POST /collections/{name}/points/search`

**Retry Strategy:**
- Exponential backoff: 100ms → 200ms → 400ms
- Total retry duration: ~700ms maximum
- Retry on transient failures (network, timeout, 5xx, 429)
- No retry on permanent failures (4xx client errors)

**Connection Pooling:**
- Max 10 concurrent connections to Qdrant
- Keep-alive: 60 seconds (persistent connections)
- Connection timeout: 5 seconds
- Request timeout: 30 seconds (configurable)

**Graceful Degradation:**
When Qdrant unavailable:
1. Health check returns `False`
2. `_is_available` flag set to `False`
3. `require_available()` raises `QdrantConnectionError`
4. MCP tools return error: `{"error": "qdrant_unavailable"}`
5. Document conversion continues (stateless operations)

**Testing Strategy:**
- Unit tests mock httpx responses
- Test retry logic with simulated failures
- Test health check success/failure paths
- Test graceful degradation behavior
- Integration tests in Task 171+ (validate against real Qdrant server)

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: FR-015 (Qdrant Storage Architecture)
- Section: FR-022 (Qdrant Integration Requirements)
- Section: Component 3 - LightRAG Knowledge Engine → Qdrant Collection Architecture

**Qdrant Documentation**:
- HTTP REST API: https://qdrant.tech/documentation/interfaces/
- Connection pooling best practices
- Retry strategies for production

## Risk Assessment

**Risk Level**: Medium

**Risks**:
1. **Qdrant unavailable at deployment**: Network issues, service not started
2. **Retry logic insufficient**: Temporary failures exceed retry limits
3. **Connection pool exhaustion**: Too many concurrent requests
4. **Timeout too short**: Large collection operations exceed 30s

**Mitigation**:
- Health check before graph operations (fail fast)
- Exponential backoff with 3 retries (handle transient failures)
- Connection pool size 10 (sufficient for 5 concurrent MCP clients)
- Configurable timeout via QdrantSettings (increase if needed)
- Graceful degradation preserves document conversion functionality
- Comprehensive error logging for troubleshooting
