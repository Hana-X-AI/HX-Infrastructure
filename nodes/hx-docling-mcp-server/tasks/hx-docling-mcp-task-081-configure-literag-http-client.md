# Task: Configure LightRAG HTTP Client Module

**Task ID**: hx-docling-mcp-task-081-configure-literag-http-client
**Phase**: Development - Knowledge Graph Generation
**Work Stream**: 5 - Knowledge Graph Generation (LightRAG Integration)
**Status**: Not Started
**Assigned Agent**: andy-taylor (LightRAG SME)
**Dependencies**:
- hx-docling-mcp-task-030-configure-python-virtual-environment (Python venv ready)
- hx-literag-server operational at http://hx-literag-server.hx.dev.local:8000

**Estimated Time**: 90 minutes

---

## Objective

Create HTTP client module (`literag_client.py`) for communicating with hx-literag-server's LightRAG entity/relationship extraction API. Configure connection pooling, retry logic, timeout handling, and structured request/response parsing for graph construction workflows.

---

## Pre-Execution Validation

**Check if work already complete BEFORE executing steps:**

```bash
# Check if literag_client.py module exists
if [ -f "/opt/docling-mcp/src/literag_client.py" ]; then
    echo "✅ VALIDATION: LightRAG client module exists - checking completeness..."

    # Verify key components present
    grep -q "class LiteRAGClient" /opt/docling-mcp/src/literag_client.py && \
    grep -q "def extract_entities" /opt/docling-mcp/src/literag_client.py && \
    grep -q "def extract_relationships" /opt/docling-mcp/src/literag_client.py && \
    grep -q "httpx.AsyncClient" /opt/docling-mcp/src/literag_client.py

    if [ $? -eq 0 ]; then
        echo "✅ VALIDATION: LightRAG client module complete - SKIP task execution"
        exit 0
    else
        echo "⚠️  VALIDATION: Module incomplete - PROCEED with task"
    fi
else
    echo "❌ VALIDATION: LightRAG client module does not exist - PROCEED with task"
fi

# Verify hx-literag-server is operational
curl -s -o /dev/null -w "%{http_code}" http://hx-literag-server.hx.dev.local:8000/health
if [ $? -ne 0 ]; then
    echo "❌ BLOCKER: hx-literag-server not accessible - cannot proceed"
    exit 1
fi
```

**Validation Logic**:
- If `literag_client.py` exists with all required methods → SKIP execution
- If module missing or incomplete → PROCEED with implementation
- If hx-literag-server unavailable → BLOCK task (dependency failure)

---

## Prerequisites

- [x] Python 3.11 virtual environment created at `/opt/docling-mcp/venv/`
- [x] httpx library installed (async HTTP client)
- [x] Pydantic installed for request/response validation
- [x] hx-literag-server operational at http://hx-literag-server.hx.dev.local:8000
- [x] Source directory `/opt/docling-mcp/src/` exists

---

## Implementation Steps

### Step 1: Create LightRAG Client Module Structure

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Create literag_client.py module
cat > /opt/docling-mcp/src/literag_client.py << 'EOF'
"""
LightRAG HTTP Client for hx-docling-mcp-server

Provides async HTTP client for entity and relationship extraction via
hx-literag-server.hx.dev.local:8000 LightRAG API.

Key Features:
- Connection pooling (max 10 concurrent, 60s keepalive)
- Exponential backoff retry (3 attempts)
- 60-second timeout for LLM extraction operations
- Structured Pydantic request/response validation
- Graceful error handling with diagnostic context

Architecture:
- HTTP POST to /extract_entities (document text → entity list)
- HTTP POST to /extract_relationships (document text → relationship list)
- No direct LightRAG library dependency (server-side processing)
"""

import httpx
import asyncio
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field, field_validator
from uuid import UUID
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

# Configure LightRAG server endpoint
LITERAG_SERVER_URL = "http://hx-literag-server.hx.dev.local:8000"
REQUEST_TIMEOUT = 60.0  # LLM extraction can take 30-60s for large documents
MAX_RETRIES = 3
RETRY_BACKOFF_FACTOR = 2.0  # Exponential: 1s, 2s, 4s

EOF
```

### Step 2: Define Pydantic Request/Response Schemas

```bash
cat >> /opt/docling-mcp/src/literag_client.py << 'EOF'

# ============================================================================
# Request/Response Schemas (Pydantic Models)
# ============================================================================

class EntityExtractionRequest(BaseModel):
    """Request schema for /extract_entities endpoint."""

    document_text: str = Field(
        min_length=1,
        max_length=100000,  # 100K char limit (roughly 25K words)
        description="Document text for entity extraction"
    )
    document_id: str = Field(
        min_length=1,
        max_length=256,
        description="Document identifier for tracking"
    )
    entity_types: Optional[List[str]] = Field(
        default=None,
        description="Filter entity types (None = all types)"
    )
    confidence_threshold: float = Field(
        default=0.7,
        ge=0.0,
        le=1.0,
        description="Minimum confidence score for entity extraction"
    )
    model_name: str = Field(
        default="gemma3:27b",
        description="LLM model for entity extraction via LiteLLM"
    )

    @field_validator('document_text')
    @classmethod
    def validate_text(cls, v: str) -> str:
        """Trim whitespace and validate non-empty."""
        v_stripped = v.strip()
        if not v_stripped:
            raise ValueError("document_text cannot be empty or whitespace-only")
        return v_stripped


class ExtractedEntity(BaseModel):
    """Individual entity returned by LightRAG extraction."""

    entity_name: str = Field(description="Canonical entity name")
    entity_type: str = Field(description="Entity classification")
    aliases: List[str] = Field(default_factory=list, description="Alternative names")
    confidence: float = Field(ge=0.0, le=1.0, description="Extraction confidence")
    text_span_start: int = Field(ge=0, description="Character offset start")
    text_span_end: int = Field(ge=0, description="Character offset end")
    context_snippet: str = Field(max_length=500, description="Surrounding text")
    attributes: Dict[str, Any] = Field(default_factory=dict, description="Type-specific attributes")


class EntityExtractionResponse(BaseModel):
    """Response schema from /extract_entities endpoint."""

    entities: List[ExtractedEntity] = Field(description="Extracted entities")
    extraction_model: str = Field(description="Model used for extraction")
    processing_time_ms: float = Field(description="Server-side processing time")
    document_id: str = Field(description="Original document identifier")


class RelationshipExtractionRequest(BaseModel):
    """Request schema for /extract_relationships endpoint."""

    document_text: str = Field(
        min_length=1,
        max_length=100000,
        description="Document text for relationship extraction"
    )
    document_id: str = Field(
        min_length=1,
        max_length=256,
        description="Document identifier for tracking"
    )
    entities: List[ExtractedEntity] = Field(
        description="Pre-extracted entities (for relationship linking)"
    )
    confidence_threshold: float = Field(
        default=0.7,
        ge=0.0,
        le=1.0,
        description="Minimum confidence for relationship extraction"
    )
    model_name: str = Field(
        default="gemma3:27b",
        description="LLM model for relationship extraction"
    )


class ExtractedRelationship(BaseModel):
    """Individual relationship returned by LightRAG extraction."""

    subject_entity_name: str = Field(description="Subject entity canonical name")
    predicate: str = Field(description="Relationship type")
    object_entity_name: str = Field(description="Object entity canonical name")
    confidence: float = Field(ge=0.0, le=1.0, description="Extraction confidence")
    text_evidence: str = Field(max_length=1000, description="Supporting text evidence")
    text_span_start: int = Field(ge=0, description="Span start offset")
    text_span_end: int = Field(ge=0, description="Span end offset")
    bidirectional: bool = Field(default=False, description="Symmetric relationship flag")
    attributes: Dict[str, Any] = Field(default_factory=dict, description="Relationship attributes")


class RelationshipExtractionResponse(BaseModel):
    """Response schema from /extract_relationships endpoint."""

    relationships: List[ExtractedRelationship] = Field(description="Extracted relationships")
    extraction_model: str = Field(description="Model used for extraction")
    processing_time_ms: float = Field(description="Server-side processing time")
    document_id: str = Field(description="Original document identifier")

EOF
```

### Step 3: Implement LiteRAGClient Class with Connection Pooling

```bash
cat >> /opt/docling-mcp/src/literag_client.py << 'EOF'

# ============================================================================
# LiteRAGClient (Async HTTP Client)
# ============================================================================

class LiteRAGClient:
    """
    Async HTTP client for hx-literag-server LightRAG API.

    Features:
    - Connection pooling (10 max concurrent, 60s keepalive)
    - Exponential backoff retry logic (3 attempts)
    - 60-second timeout for LLM operations
    - Structured error handling with request context
    """

    def __init__(
        self,
        base_url: str = LITERAG_SERVER_URL,
        timeout: float = REQUEST_TIMEOUT,
        max_retries: int = MAX_RETRIES
    ):
        """
        Initialize LightRAG HTTP client.

        Args:
            base_url: LightRAG server endpoint (default: http://hx-literag-server.hx.dev.local:8000)
            timeout: Request timeout in seconds (default: 60.0)
            max_retries: Retry attempts for failed requests (default: 3)
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.max_retries = max_retries

        # Connection pool configuration
        limits = httpx.Limits(
            max_connections=10,      # Max concurrent connections
            max_keepalive_connections=5,  # Persistent connections
            keepalive_expiry=60.0    # 60s keepalive timeout
        )

        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=httpx.Timeout(timeout),
            limits=limits,
            follow_redirects=True
        )

        logger.info(f"LiteRAGClient initialized: base_url={base_url}, timeout={timeout}s, max_retries={max_retries}")


    async def close(self):
        """Close HTTP client connection pool."""
        await self.client.aclose()
        logger.info("LiteRAGClient connection pool closed")


    async def _request_with_retry(
        self,
        method: str,
        endpoint: str,
        json_data: Dict[str, Any],
        response_model: type[BaseModel]
    ) -> BaseModel:
        """
        Execute HTTP request with exponential backoff retry.

        Args:
            method: HTTP method (POST)
            endpoint: API endpoint path (e.g., "/extract_entities")
            json_data: Request payload (Pydantic model dict)
            response_model: Expected Pydantic response model class

        Returns:
            Validated Pydantic response model instance

        Raises:
            httpx.HTTPStatusError: Non-2xx response after retries
            httpx.TimeoutException: Request timeout after retries
            httpx.RequestError: Network error after retries
        """
        last_exception = None

        for attempt in range(1, self.max_retries + 1):
            try:
                logger.debug(f"LightRAG request attempt {attempt}/{self.max_retries}: {method} {endpoint}")

                response = await self.client.request(
                    method=method,
                    url=endpoint,
                    json=json_data
                )
                response.raise_for_status()

                # Parse and validate response
                response_data = response.json()
                validated_response = response_model.model_validate(response_data)

                logger.info(f"LightRAG request successful: {endpoint} (attempt {attempt})")
                return validated_response

            except httpx.HTTPStatusError as e:
                logger.warning(f"HTTP error on attempt {attempt}: {e.response.status_code} - {e.response.text[:200]}")
                last_exception = e

                # Don't retry client errors (4xx)
                if 400 <= e.response.status_code < 500:
                    raise

            except httpx.TimeoutException as e:
                logger.warning(f"Timeout on attempt {attempt}: {endpoint}")
                last_exception = e

            except httpx.RequestError as e:
                logger.warning(f"Network error on attempt {attempt}: {str(e)[:200]}")
                last_exception = e

            # Exponential backoff before retry
            if attempt < self.max_retries:
                backoff_delay = RETRY_BACKOFF_FACTOR ** (attempt - 1)
                logger.info(f"Retrying after {backoff_delay}s backoff...")
                await asyncio.sleep(backoff_delay)

        # All retries exhausted
        logger.error(f"LightRAG request failed after {self.max_retries} attempts: {endpoint}")
        raise last_exception

EOF
```

### Step 4: Implement Entity and Relationship Extraction Methods

```bash
cat >> /opt/docling-mcp/src/literag_client.py << 'EOF'

    async def extract_entities(
        self,
        document_text: str,
        document_id: str,
        entity_types: Optional[List[str]] = None,
        confidence_threshold: float = 0.7,
        model_name: str = "gemma3:27b"
    ) -> EntityExtractionResponse:
        """
        Extract entities from document text via hx-literag-server.

        Args:
            document_text: Document content for entity extraction
            document_id: Unique document identifier
            entity_types: Filter entity types (None = all types)
            confidence_threshold: Minimum confidence score (0.0-1.0)
            model_name: LLM model name (gemma3:27b, qwen3-coder:30b)

        Returns:
            EntityExtractionResponse with extracted entities

        Raises:
            ValidationError: Invalid request parameters
            httpx.HTTPStatusError: Server returned error response
            httpx.TimeoutException: Request timeout (>60s)

        Example:
            response = await client.extract_entities(
                document_text="IBM Research announced LightRAG framework...",
                document_id="doc_abc123",
                entity_types=["Organization", "Technology"],
                confidence_threshold=0.8
            )
            print(f"Extracted {len(response.entities)} entities in {response.processing_time_ms}ms")
        """
        # Validate request with Pydantic
        request = EntityExtractionRequest(
            document_text=document_text,
            document_id=document_id,
            entity_types=entity_types,
            confidence_threshold=confidence_threshold,
            model_name=model_name
        )

        logger.info(f"Extracting entities: document_id={document_id}, model={model_name}, threshold={confidence_threshold}")

        # Execute HTTP request with retry
        response = await self._request_with_retry(
            method="POST",
            endpoint="/extract_entities",
            json_data=request.model_dump(exclude_none=True),
            response_model=EntityExtractionResponse
        )

        logger.info(f"Entity extraction complete: {len(response.entities)} entities, {response.processing_time_ms:.0f}ms")
        return response


    async def extract_relationships(
        self,
        document_text: str,
        document_id: str,
        entities: List[ExtractedEntity],
        confidence_threshold: float = 0.7,
        model_name: str = "gemma3:27b"
    ) -> RelationshipExtractionResponse:
        """
        Extract relationships from document text via hx-literag-server.

        Args:
            document_text: Document content for relationship extraction
            document_id: Unique document identifier
            entities: Pre-extracted entities (for linking relationships)
            confidence_threshold: Minimum confidence score (0.0-1.0)
            model_name: LLM model name (gemma3:27b, qwen3-coder:30b)

        Returns:
            RelationshipExtractionResponse with extracted relationships

        Raises:
            ValidationError: Invalid request parameters
            httpx.HTTPStatusError: Server returned error response
            httpx.TimeoutException: Request timeout (>60s)

        Example:
            response = await client.extract_relationships(
                document_text="IBM Research announced LightRAG framework...",
                document_id="doc_abc123",
                entities=entity_response.entities,  # From extract_entities()
                confidence_threshold=0.8
            )
            print(f"Extracted {len(response.relationships)} relationships")
        """
        # Validate request with Pydantic
        request = RelationshipExtractionRequest(
            document_text=document_text,
            document_id=document_id,
            entities=entities,
            confidence_threshold=confidence_threshold,
            model_name=model_name
        )

        logger.info(f"Extracting relationships: document_id={document_id}, model={model_name}, entities={len(entities)}")

        # Execute HTTP request with retry
        response = await self._request_with_retry(
            method="POST",
            endpoint="/extract_relationships",
            json_data=request.model_dump(exclude_none=True),
            response_model=RelationshipExtractionResponse
        )

        logger.info(f"Relationship extraction complete: {len(response.relationships)} relationships, {response.processing_time_ms:.0f}ms")
        return response


    async def health_check(self) -> bool:
        """
        Check if hx-literag-server is operational.

        Returns:
            True if server healthy, False otherwise

        Example:
            if await client.health_check():
                print("LightRAG server operational")
        """
        try:
            response = await self.client.get("/health", timeout=5.0)
            is_healthy = response.status_code == 200

            if is_healthy:
                logger.info("LightRAG server health check: PASS")
            else:
                logger.warning(f"LightRAG server health check: FAIL (HTTP {response.status_code})")

            return is_healthy

        except Exception as e:
            logger.error(f"LightRAG server health check failed: {str(e)[:200]}")
            return False


# ============================================================================
# Context Manager Support (async with)
# ============================================================================

    async def __aenter__(self):
        """Enable 'async with LiteRAGClient() as client:' pattern."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Auto-close client on context exit."""
        await self.close()

EOF
```

### Step 5: Set File Permissions and Ownership

```bash
# Set ownership to docling-mcp service account
chown docling-mcp:docling-mcp /opt/docling-mcp/src/literag_client.py

# Read-only for owner/group (source code protection)
chmod 640 /opt/docling-mcp/src/literag_client.py

echo "✅ LightRAG HTTP client module created and secured"
```

---

## Verification

### Automated Verification

```bash
# Verify file exists and has correct permissions
ls -l /opt/docling-mcp/src/literag_client.py
# Expected: -rw-r----- 1 docling-mcp docling-mcp [size] [date] literag_client.py

# Verify Python syntax
source /opt/docling-mcp/venv/bin/activate
python -m py_compile /opt/docling-mcp/src/literag_client.py
if [ $? -eq 0 ]; then
    echo "✅ Python syntax valid"
else
    echo "❌ Python syntax errors detected"
    exit 1
fi

# Verify module can be imported
python -c "from literag_client import LiteRAGClient; print('✅ Import successful')"

# Test health check endpoint
python << 'PYEOF'
import asyncio
from literag_client import LiteRAGClient

async def test_health():
    async with LiteRAGClient() as client:
        is_healthy = await client.health_check()
        if is_healthy:
            print("✅ hx-literag-server health check PASSED")
        else:
            print("❌ hx-literag-server health check FAILED")
            exit(1)

asyncio.run(test_health())
PYEOF
```

### Manual Verification

- [ ] Module imports without errors
- [ ] LiteRAGClient class instantiates successfully
- [ ] Health check endpoint returns 200 OK
- [ ] Connection pool configuration present (max 10 connections, 60s keepalive)
- [ ] Retry logic configured (3 attempts, exponential backoff)
- [ ] Timeout set to 60 seconds
- [ ] Pydantic request/response schemas defined
- [ ] File ownership: docling-mcp:docling-mcp
- [ ] File permissions: 640 (rw-r-----)

---

## Rollback

If task needs to be reverted:

```bash
# Remove literag_client.py module
rm -f /opt/docling-mcp/src/literag_client.py

# Verify removal
if [ ! -f "/opt/docling-mcp/src/literag_client.py" ]; then
    echo "✅ LightRAG client module removed"
else
    echo "❌ Failed to remove module"
fi
```

---

## Integration Points

**Upstream Dependencies**:
- `hx-literag-server` operational at http://hx-literag-server.hx.dev.local:8000
- `httpx` Python library (async HTTP client)
- `pydantic` library (request/response validation)

**Downstream Consumers**:
- `hx-docling-mcp-task-082-implement-entity-extraction-workflow.md` (uses `extract_entities()`)
- `hx-docling-mcp-task-083-implement-relationship-extraction-workflow.md` (uses `extract_relationships()`)
- `hx-docling-mcp-task-084-integrate-qdrant-storage.md` (stores extraction results)

**Configuration Requirements**:
- Environment variable: `LITERAG_SERVER_URL` (default: http://hx-literag-server.hx.dev.local:8000)
- Environment variable: `LITERAG_REQUEST_TIMEOUT` (default: 60.0)
- Environment variable: `LITERAG_MAX_RETRIES` (default: 3)

---

## Notes

### LightRAG Architecture Considerations

1. **Server-Side Processing**: This client delegates all LightRAG logic (entity extraction, relationship extraction, graph construction) to hx-literag-server. No local LightRAG library dependency required.

2. **Connection Pooling**: Configured for 10 max concurrent connections with 60-second keepalive to optimize performance when processing multiple documents in parallel.

3. **Timeout Strategy**: 60-second timeout accounts for LLM inference latency (gemma3:27b can take 30-60s for large documents with complex entity extraction).

4. **Retry Logic**: Exponential backoff (1s, 2s, 4s) handles transient network failures and temporary server overload. Client errors (4xx) bypass retry logic.

5. **Context Size Requirements**: CRITICAL - LLM models MUST support ≥32KB context (64KB recommended) for LightRAG document chunking. Default Ollama models (8KB) WILL FAIL. Verify hx-literag-server uses custom Modelfile with extended context.

6. **Performance Expectations**:
   - Entity extraction: <30s per 10K words
   - Relationship extraction: <30s per 100 entities
   - Health check: <5s

### Security Considerations

- **No Credentials Required**: HTTP endpoint is internal-only (hx.dev.local domain), no authentication needed in Phase 1
- **Input Validation**: Pydantic models validate all request parameters (max document size 100K chars, confidence threshold 0.0-1.0)
- **Error Sanitization**: Exception messages truncated to 200 chars to prevent sensitive data leakage in logs

### Testing Strategy

- **Unit Tests**: Mock httpx responses for entity/relationship extraction (Phase 7)
- **Integration Tests**: Live hx-literag-server connectivity validation (TC-INT-004)
- **Performance Tests**: Measure extraction latency for 10K-word documents

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Version**: 1.0
