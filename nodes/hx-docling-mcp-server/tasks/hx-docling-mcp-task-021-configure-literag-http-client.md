# Task 021: Configure hx-literag-server HTTP Client Integration

**Task ID**: hx-docling-mcp-task-021-configure-literag-http-client
**Task Type**: Integration
**Component**: LightRAG Knowledge Graph Engine (HTTP API Client)
**Priority**: HIGH
**Estimated Duration**: 1.5 hours
**Dependencies**: Task 008 (Environment Files configured)
**Assigned To**: andy-taylor (LightRAG SME)

---

## Objective

Configure HTTP client integration with hx-literag-server (192.168.10.220:8080) to enable knowledge graph generation capabilities WITHOUT local LightRAG installation. Use HTTP API for entity extraction, relationship modeling, and knowledge graph storage.

---

## Architecture Change Context

**CRITICAL**: This task replaces the original "Install LightRAG Framework" approach.

**Previous Architecture** (OBSOLETE):
- Local LightRAG package installation (`lightrag==0.1.0b6`)
- In-process entity extraction
- Direct Qdrant integration from this service

**New Architecture** (CURRENT):
- **NO local LightRAG installation**
- HTTP API client to hx-literag-server (192.168.10.220:8080)
- Remote knowledge graph generation
- Centralized LightRAG service

**Rationale**: Avoid duplicate service installation, use existing operational hx-literag-server.

---

## Prerequisites

**Before starting this task, verify**:

```bash
# 1. hx-literag-server is operational
curl -s http://192.168.10.220:8080/health
# Expected: {"status": "healthy", "version": "1.0.0"}

# 2. Environment variable configured
grep LIGHTRAG_API_URL /etc/docling-mcp/.env
# Expected: LIGHTRAG_API_URL=http://192.168.10.220:8080

# 3. httpx package installed
source /opt/docling-mcp/venv/bin/activate
python -c "import httpx; print(httpx.__version__)"
# Expected: 0.28.1 or higher

# 4. Network connectivity to hx-literag-server
ping -c 3 192.168.10.220
# Expected: 0% packet loss
```

**All prerequisites must pass before proceeding.**

---

## Acceptance Criteria

- [ ] HTTP client class created at `/opt/docling-mcp/application/docling_mcp/clients/literag_client.py`
- [ ] API methods implemented for all required operations:
  - [ ] `generate_knowledge_graph(document: str) -> dict`
  - [ ] `extract_entities(text: str) -> list[Entity]`
  - [ ] `extract_relationships(text: str) -> list[Relationship]`
  - [ ] `health_check() -> dict`
- [ ] Error handling for connection failures, timeouts, API errors
- [ ] Retry logic with exponential backoff (max 3 retries)
- [ ] Unit tests passing (minimum 5 test cases)
- [ ] Integration test with actual hx-literag-server passing
- [ ] Configuration loaded from environment variables
- [ ] Documentation complete

---

## Implementation Steps

### Step 1: Create HTTP Client Class

**File**: `/opt/docling-mcp/application/docling_mcp/clients/literag_client.py`

```python
"""
LightRAG HTTP Client for hx-literag-server integration.

This module provides HTTP client functionality to interact with the
centralized LightRAG service (hx-literag-server) for knowledge graph
generation WITHOUT local LightRAG installation.
"""

import httpx
from typing import List, Dict, Optional
from pydantic import BaseModel, Field
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

logger = structlog.get_logger(__name__)


class Entity(BaseModel):
    """Entity extracted from document."""
    text: str
    type: str
    confidence: float = Field(ge=0.0, le=1.0)
    metadata: Dict[str, any] = Field(default_factory=dict)


class Relationship(BaseModel):
    """Relationship between entities."""
    source: str
    target: str
    type: str
    confidence: float = Field(ge=0.0, le=1.0)
    metadata: Dict[str, any] = Field(default_factory=dict)


class LiteRAGClient:
    """
    HTTP client for hx-literag-server integration.

    Provides methods to interact with the centralized LightRAG service
    for knowledge graph generation, entity extraction, and relationship
    modeling.
    """

    def __init__(
        self,
        base_url: str,
        timeout: int = 60,
        max_retries: int = 3
    ):
        """
        Initialize LightRAG HTTP client.

        Args:
            base_url: Base URL of hx-literag-server (e.g., http://192.168.10.220:8080)
            timeout: Request timeout in seconds (default: 60)
            max_retries: Maximum retry attempts (default: 3)
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.max_retries = max_retries
        self.client = httpx.AsyncClient(timeout=timeout)
        logger.info("LiteRAG client initialized", base_url=base_url)

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def generate_knowledge_graph(
        self,
        document: str,
        document_id: Optional[str] = None
    ) -> Dict:
        """
        Generate knowledge graph from document via hx-literag-server.

        Args:
            document: Document text to process
            document_id: Optional document identifier

        Returns:
            Knowledge graph data with entities and relationships

        Raises:
            httpx.HTTPError: On API request failure
        """
        url = f"{self.base_url}/api/v1/knowledge-graph/generate"
        payload = {
            "document": document,
            "document_id": document_id
        }

        try:
            response = await self.client.post(url, json=payload)
            response.raise_for_status()
            result = response.json()

            logger.info(
                "Knowledge graph generated",
                document_id=document_id,
                entities_count=len(result.get("entities", [])),
                relationships_count=len(result.get("relationships", []))
            )

            return result

        except httpx.HTTPError as e:
            logger.error("Knowledge graph generation failed", error=str(e))
            raise

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def extract_entities(self, text: str) -> List[Entity]:
        """
        Extract entities from text via hx-literag-server.

        Args:
            text: Input text for entity extraction

        Returns:
            List of extracted entities

        Raises:
            httpx.HTTPError: On API request failure
        """
        url = f"{self.base_url}/api/v1/entities/extract"
        payload = {"text": text}

        try:
            response = await self.client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()

            entities = [Entity(**e) for e in data.get("entities", [])]

            logger.info("Entities extracted", count=len(entities))
            return entities

        except httpx.HTTPError as e:
            logger.error("Entity extraction failed", error=str(e))
            raise

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def extract_relationships(self, text: str) -> List[Relationship]:
        """
        Extract relationships from text via hx-literag-server.

        Args:
            text: Input text for relationship extraction

        Returns:
            List of extracted relationships

        Raises:
            httpx.HTTPError: On API request failure
        """
        url = f"{self.base_url}/api/v1/relationships/extract"
        payload = {"text": text}

        try:
            response = await self.client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()

            relationships = [Relationship(**r) for r in data.get("relationships", [])]

            logger.info("Relationships extracted", count=len(relationships))
            return relationships

        except httpx.HTTPError as e:
            logger.error("Relationship extraction failed", error=str(e))
            raise

    async def health_check(self) -> Dict:
        """
        Check health of hx-literag-server.

        Returns:
            Health status dictionary

        Raises:
            httpx.HTTPError: On API request failure
        """
        url = f"{self.base_url}/health"

        try:
            response = await self.client.get(url)
            response.raise_for_status()
            return response.json()

        except httpx.HTTPError as e:
            logger.error("Health check failed", error=str(e))
            raise

    async def close(self):
        """Close HTTP client connection."""
        await self.client.aclose()
        logger.info("LiteRAG client closed")
```

### Step 2: Create Unit Tests

**File**: `/opt/docling-mcp/application/tests/test_literag_client.py`

```python
"""Unit tests for LiteRAG HTTP client."""

import pytest
from unittest.mock import AsyncMock, patch
import httpx
from docling_mcp.clients.literag_client import LiteRAGClient, Entity, Relationship


@pytest.fixture
def literag_client():
    """Fixture for LiteRAG client."""
    return LiteRAGClient(base_url="http://192.168.10.220:8080")


@pytest.mark.asyncio
async def test_generate_knowledge_graph_success(literag_client):
    """Test successful knowledge graph generation."""
    mock_response = {
        "entities": [
            {"text": "Python", "type": "TECHNOLOGY", "confidence": 0.95}
        ],
        "relationships": [
            {"source": "Python", "target": "Programming", "type": "IS_A", "confidence": 0.90}
        ]
    }

    with patch.object(literag_client.client, 'post', new_callable=AsyncMock) as mock_post:
        mock_post.return_value.json.return_value = mock_response
        mock_post.return_value.raise_for_status = lambda: None

        result = await literag_client.generate_knowledge_graph("Python is a programming language")

        assert len(result["entities"]) == 1
        assert len(result["relationships"]) == 1


@pytest.mark.asyncio
async def test_extract_entities_success(literag_client):
    """Test successful entity extraction."""
    mock_response = {
        "entities": [
            {"text": "FastMCP", "type": "FRAMEWORK", "confidence": 0.92, "metadata": {}}
        ]
    }

    with patch.object(literag_client.client, 'post', new_callable=AsyncMock) as mock_post:
        mock_post.return_value.json.return_value = mock_response
        mock_post.return_value.raise_for_status = lambda: None

        entities = await literag_client.extract_entities("FastMCP is a framework")

        assert len(entities) == 1
        assert entities[0].text == "FastMCP"
        assert entities[0].type == "FRAMEWORK"


@pytest.mark.asyncio
async def test_health_check_success(literag_client):
    """Test successful health check."""
    mock_response = {"status": "healthy", "version": "1.0.0"}

    with patch.object(literag_client.client, 'get', new_callable=AsyncMock) as mock_get:
        mock_get.return_value.json.return_value = mock_response
        mock_get.return_value.raise_for_status = lambda: None

        health = await literag_client.health_check()

        assert health["status"] == "healthy"


@pytest.mark.asyncio
async def test_connection_failure_retry(literag_client):
    """Test retry logic on connection failure."""
    with patch.object(literag_client.client, 'post', new_callable=AsyncMock) as mock_post:
        mock_post.side_effect = httpx.ConnectError("Connection refused")

        with pytest.raises(httpx.ConnectError):
            await literag_client.extract_entities("test")

        # Verify retry attempts (3 attempts with tenacity)
        assert mock_post.call_count == 3


@pytest.mark.asyncio
async def test_client_close(literag_client):
    """Test client cleanup."""
    await literag_client.close()
    # Verify client closed without error
```

### Step 3: Integration Test with Real hx-literag-server

**File**: `/opt/docling-mcp/application/tests/integration/test_literag_integration.py`

```python
"""Integration tests with actual hx-literag-server."""

import pytest
from docling_mcp.clients.literag_client import LiteRAGClient


@pytest.fixture
def real_client():
    """Fixture for real hx-literag-server client."""
    return LiteRAGClient(base_url="http://192.168.10.220:8080")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_health_check_real_server(real_client):
    """Test health check against real hx-literag-server."""
    health = await real_client.health_check()

    assert health["status"] == "healthy"
    assert "version" in health


@pytest.mark.integration
@pytest.mark.asyncio
async def test_entity_extraction_real_server(real_client):
    """Test entity extraction against real hx-literag-server."""
    text = "FastMCP is a Python framework for building MCP servers."

    entities = await real_client.extract_entities(text)

    assert len(entities) > 0
    # At minimum should extract FastMCP and Python
```

### Step 4: Update Configuration

**Verify environment variable**:

```bash
# Check .env configuration
grep LIGHTRAG_API_URL /etc/docling-mcp/.env

# Expected output:
# LIGHTRAG_API_URL=http://192.168.10.220:8080
```

### Step 5: Execute Tests

```bash
# Activate venv
source /opt/docling-mcp/venv/bin/activate

# Run unit tests
cd /opt/docling-mcp/application
pytest tests/test_literag_client.py -v

# Run integration tests (requires hx-literag-server operational)
pytest tests/integration/test_literag_integration.py -v -m integration
```

**Expected Result**: All tests PASS

---

## Validation

### Validation Commands

```bash
# 1. Verify client file exists
ls -la /opt/docling-mcp/application/docling_mcp/clients/literag_client.py

# 2. Verify imports work
source /opt/docling-mcp/venv/bin/activate
python -c "from docling_mcp.clients.literag_client import LiteRAGClient; print('Import successful')"

# 3. Test health check
python -c "
import asyncio
from docling_mcp.clients.literag_client import LiteRAGClient

async def test():
    client = LiteRAGClient('http://192.168.10.220:8080')
    health = await client.health_check()
    print(f'Health: {health}')
    await client.close()

asyncio.run(test())
"

# 4. Run test suite
pytest tests/test_literag_client.py -v
```

### Success Criteria

- ✅ Client file created with correct structure
- ✅ All imports successful
- ✅ Health check returns healthy status from hx-literag-server
- ✅ All unit tests passing (5+ tests)
- ✅ Integration test with real server passing
- ✅ Error handling verified (connection failures, timeouts)
- ✅ Retry logic functional

---

## Documentation

Create documentation file:

**File**: `/opt/docling-mcp/documentation/literag-http-integration.md`

```markdown
# LightRAG HTTP Integration

## Architecture

**Service**: hx-literag-server (192.168.10.220:8080)
**Client**: HTTP API client (no local LightRAG installation)
**Protocol**: HTTP/JSON

## API Endpoints

### Generate Knowledge Graph
- **URL**: `POST /api/v1/knowledge-graph/generate`
- **Payload**: `{"document": "...", "document_id": "..."}`
- **Response**: `{"entities": [...], "relationships": [...]}`

### Extract Entities
- **URL**: `POST /api/v1/entities/extract`
- **Payload**: `{"text": "..."}`
- **Response**: `{"entities": [...]}`

### Extract Relationships
- **URL**: `POST /api/v1/relationships/extract`
- **Payload**: `{"text": "..."}`
- **Response**: `{"relationships": [...]}`

### Health Check
- **URL**: `GET /health`
- **Response**: `{"status": "healthy", "version": "1.0.0"}`

## Configuration

**Environment Variable**: `LIGHTRAG_API_URL=http://192.168.10.220:8080`

## Error Handling

- Automatic retry (max 3 attempts)
- Exponential backoff (2-10 seconds)
- Connection timeout: 60 seconds
- Detailed error logging

## Testing

```bash
# Unit tests
pytest tests/test_literag_client.py -v

# Integration tests
pytest tests/integration/test_literag_integration.py -v -m integration
```
```

---

## Rollback Procedure

**If this task fails or needs removal**:

```bash
# 1. Remove client file
rm -f /opt/docling-mcp/application/docling_mcp/clients/literag_client.py

# 2. Remove test files
rm -f /opt/docling-mcp/application/tests/test_literag_client.py
rm -f /opt/docling-mcp/application/tests/integration/test_literag_integration.py

# 3. Remove documentation
rm -f /opt/docling-mcp/documentation/literag-http-integration.md

# 4. Verify removal
ls -la /opt/docling-mcp/application/docling_mcp/clients/
```

---

## Dependencies

**Blocks**:
- Task 022: Configure Entity Extraction Pipeline (needs client)
- Task 023: Configure Relationship Extraction (needs client)
- Task 024: Implement Qdrant Knowledge Graph Storage (needs extracted data)

**Depends On**:
- Task 008: Configure Environment Files (LIGHTRAG_API_URL required)
- hx-literag-server operational (192.168.10.220:8080)

---

## Notes

### Architecture Change

**This task REPLACES the original Task 021 ("Install LightRAG Framework").**

**Previous approach** (OBSOLETE):
```python
# OLD: Local LightRAG installation
from lightrag import LightRAG
rag = LightRAG(...)
```

**New approach** (CURRENT):
```python
# NEW: HTTP API client
from docling_mcp.clients.literag_client import LiteRAGClient
client = LiteRAGClient("http://192.168.10.220:8080")
result = await client.generate_knowledge_graph(document)
```

### Benefits

1. **No duplicate installation**: Use existing hx-literag-server
2. **Centralized service**: Single LightRAG instance for all clients
3. **Easier maintenance**: Update LightRAG in one place
4. **Better resource utilization**: Shared LLM usage via hx-literag-server

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
