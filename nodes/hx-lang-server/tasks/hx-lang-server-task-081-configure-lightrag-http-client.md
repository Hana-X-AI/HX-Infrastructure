# Task: Configure LightRAG HTTP Client

**Task ID:** hx-lang-server-task-081-configure-lightrag-http-client
**Work Stream:** 8 - LightRAG Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-025-install-http-client-packages
**Estimated Time:** 2 hours

---

## Objective

Configure the HTTP client module for communication with hx-literag-server.hx.dev.local:8020, implementing proper async patterns, connection pooling, timeout handling, and error recovery aligned with LightRAG's API contract.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **FR-014**: Service MUST integrate with hx-literag-server.hx.dev.local via HTTP API
- **FR-012**: Service MUST route embedding requests through LightRAG (NOT direct to ollama3)
- **NFR-001**: API response time < 5 seconds for simple queries (95th percentile)

---

## Prerequisites

- [ ] Task 025 complete: httpx and aiohttp packages installed
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`
- [ ] Service account configured: `hx-lang-server`
- [ ] Network connectivity verified to hx-literag-server.hx.dev.local:8020

---

## Implementation Details

### File Location

```
/opt/hx-lang-server/app/clients/lightrag_client.py
```

### Client Configuration

```python
"""
LightRAG HTTP Client for hx-lang-server.

This client provides async communication with hx-literag-server.hx.dev.local
for knowledge graph queries, entity extraction, and adaptive retrieval.

CRITICAL: All embedding operations MUST flow through this client.
hx-lang-server does NOT access hx-ollama3-server directly.
"""

import httpx
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
import structlog

logger = structlog.get_logger()


class LightRAGClientSettings(BaseSettings):
    """LightRAG client configuration."""

    lightrag_base_url: str = "http://hx-literag-server.hx.dev.local:8020"
    lightrag_timeout: float = 30.0  # LightRAG queries can take time
    lightrag_connect_timeout: float = 5.0
    lightrag_max_connections: int = 20
    lightrag_max_keepalive: int = 10
    lightrag_retry_attempts: int = 3
    lightrag_retry_delay: float = 1.0

    class Config:
        env_prefix = "LIGHTRAG_"


class QueryRequest(BaseModel):
    """Request model for LightRAG query."""
    query: str = Field(..., description="The query text")
    mode: str = Field(default="hybrid", description="Query mode: local, global, hybrid, mix")
    only_need_context: bool = Field(default=False, description="Return only context, not LLM response")
    top_k: int = Field(default=60, description="Number of results to retrieve")
    max_token_for_text_unit: int = Field(default=4000, description="Max tokens per text unit")
    max_token_for_global_context: int = Field(default=4000, description="Max tokens for global context")
    max_token_for_local_context: int = Field(default=4000, description="Max tokens for local context")


class QueryResponse(BaseModel):
    """Response model for LightRAG query."""
    response: str
    context: Optional[str] = None
    entities: Optional[List[Dict[str, Any]]] = None
    relationships: Optional[List[Dict[str, Any]]] = None
    query_mode: str
    tokens_used: Optional[int] = None


class LightRAGClient:
    """
    Async HTTP client for LightRAG integration.

    This client provides:
    - Connection pooling with configurable limits
    - Timeout handling appropriate for LightRAG's processing time
    - Retry logic with exponential backoff
    - Structured logging for observability
    - Support for all query modes (local, global, hybrid, mix)

    IMPORTANT: This client is the ONLY authorized path for RAG operations.
    Direct access to hx-ollama3-server for embeddings is FORBIDDEN.
    """

    def __init__(self, settings: Optional[LightRAGClientSettings] = None):
        self.settings = settings or LightRAGClientSettings()
        self._client: Optional[httpx.AsyncClient] = None
        self._logger = logger.bind(component="lightrag_client")

    async def __aenter__(self):
        await self.connect()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()

    async def connect(self) -> None:
        """Initialize the HTTP client with connection pooling."""
        if self._client is not None:
            return

        timeout = httpx.Timeout(
            timeout=self.settings.lightrag_timeout,
            connect=self.settings.lightrag_connect_timeout
        )

        limits = httpx.Limits(
            max_connections=self.settings.lightrag_max_connections,
            max_keepalive_connections=self.settings.lightrag_max_keepalive
        )

        self._client = httpx.AsyncClient(
            base_url=self.settings.lightrag_base_url,
            timeout=timeout,
            limits=limits,
            headers={"Content-Type": "application/json"}
        )

        self._logger.info(
            "lightrag_client_connected",
            base_url=self.settings.lightrag_base_url,
            timeout=self.settings.lightrag_timeout
        )

    async def close(self) -> None:
        """Close the HTTP client and release connections."""
        if self._client is not None:
            await self._client.aclose()
            self._client = None
            self._logger.info("lightrag_client_closed")

    async def health_check(self) -> Dict[str, Any]:
        """
        Check LightRAG service health.

        Returns:
            Dict containing status and service information
        """
        if self._client is None:
            await self.connect()

        try:
            response = await self._client.get("/health")
            response.raise_for_status()

            health_data = response.json()
            self._logger.debug(
                "lightrag_health_check",
                status="healthy",
                response=health_data
            )
            return {"status": "healthy", "data": health_data}

        except httpx.HTTPStatusError as e:
            self._logger.error(
                "lightrag_health_check_failed",
                status_code=e.response.status_code,
                error=str(e)
            )
            return {"status": "unhealthy", "error": str(e)}

        except httpx.RequestError as e:
            self._logger.error(
                "lightrag_health_check_error",
                error=str(e)
            )
            return {"status": "unreachable", "error": str(e)}

    async def query(
        self,
        query: str,
        mode: str = "hybrid",
        only_need_context: bool = False,
        **kwargs
    ) -> QueryResponse:
        """
        Execute a query against LightRAG.

        Args:
            query: The query text
            mode: Query mode (local, global, hybrid, mix)
            only_need_context: If True, return only context without LLM response
            **kwargs: Additional query parameters

        Returns:
            QueryResponse with results

        Raises:
            httpx.HTTPStatusError: If the request fails
            ValueError: If mode is invalid
        """
        if mode not in ("local", "global", "hybrid", "mix", "naive", "bypass"):
            raise ValueError(f"Invalid query mode: {mode}. Valid modes: local, global, hybrid, mix")

        if self._client is None:
            await self.connect()

        request = QueryRequest(
            query=query,
            mode=mode,
            only_need_context=only_need_context,
            **kwargs
        )

        self._logger.info(
            "lightrag_query_started",
            query_length=len(query),
            mode=mode,
            only_need_context=only_need_context
        )

        response = await self._client.post(
            "/query",
            json=request.model_dump()
        )
        response.raise_for_status()

        result = response.json()

        self._logger.info(
            "lightrag_query_complete",
            mode=mode,
            response_length=len(result.get("response", "")),
            tokens_used=result.get("tokens_used")
        )

        return QueryResponse(
            response=result.get("response", ""),
            context=result.get("context"),
            entities=result.get("entities"),
            relationships=result.get("relationships"),
            query_mode=mode,
            tokens_used=result.get("tokens_used")
        )

    async def insert_document(
        self,
        content: str,
        doc_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Insert a document into LightRAG for indexing.

        Uses LightRAG's incremental update algorithm which provides
        10-100x cost reduction versus full graph rebuilds.

        Args:
            content: Document text content
            doc_id: Optional document identifier
            metadata: Optional document metadata

        Returns:
            Dict with insertion result including entities/relationships extracted
        """
        if self._client is None:
            await self.connect()

        payload = {
            "content": content,
            "doc_id": doc_id,
            "metadata": metadata or {}
        }

        self._logger.info(
            "lightrag_insert_started",
            content_length=len(content),
            doc_id=doc_id
        )

        response = await self._client.post(
            "/insert",
            json=payload
        )
        response.raise_for_status()

        result = response.json()

        self._logger.info(
            "lightrag_insert_complete",
            doc_id=doc_id,
            entities_extracted=result.get("entities_count", 0),
            relationships_extracted=result.get("relationships_count", 0)
        )

        return result


# Module-level client instance for dependency injection
_lightrag_client: Optional[LightRAGClient] = None


async def get_lightrag_client() -> LightRAGClient:
    """
    Get or create the LightRAG client instance.

    This function provides a singleton-like pattern for the client,
    suitable for FastAPI dependency injection.
    """
    global _lightrag_client
    if _lightrag_client is None:
        _lightrag_client = LightRAGClient()
        await _lightrag_client.connect()
    return _lightrag_client


async def close_lightrag_client() -> None:
    """Close the global LightRAG client."""
    global _lightrag_client
    if _lightrag_client is not None:
        await _lightrag_client.close()
        _lightrag_client = None
```

---

## Manual Steps

### Step 1: Create Client Directory

```bash
# As hx-lang-server user
sudo -u hx-lang-server mkdir -p /opt/hx-lang-server/app/clients
sudo -u hx-lang-server touch /opt/hx-lang-server/app/clients/__init__.py
```

### Step 2: Create Client Module

```bash
# Create the lightrag_client.py file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/app/clients/lightrag_client.py
```

### Step 3: Verify Connectivity

```bash
# Test connectivity to LightRAG server
curl -s http://hx-literag-server.hx.dev.local:8020/health | jq .
```

### Step 4: Verify Python Import

```bash
# As hx-lang-server user
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python -c "
from app.clients.lightrag_client import LightRAGClient, get_lightrag_client
print('LightRAG client module imported successfully')
"
```

---

## Environment Variables

Add to `/opt/hx-lang-server/.env`:

```bash
# LightRAG Configuration
LIGHTRAG_BASE_URL=http://hx-literag-server.hx.dev.local:8020
LIGHTRAG_TIMEOUT=30.0
LIGHTRAG_CONNECT_TIMEOUT=5.0
LIGHTRAG_MAX_CONNECTIONS=20
LIGHTRAG_MAX_KEEPALIVE=10
LIGHTRAG_RETRY_ATTEMPTS=3
LIGHTRAG_RETRY_DELAY=1.0
```

---

## Acceptance Criteria

- [ ] LightRAGClient class created at `/opt/hx-lang-server/app/clients/lightrag_client.py`
- [ ] Client uses httpx with async/await patterns
- [ ] Connection pooling configured (20 max connections)
- [ ] Timeout handling configured (30s query, 5s connect)
- [ ] Health check endpoint functional (`/health`)
- [ ] Query endpoint functional (`/query`)
- [ ] Insert endpoint functional (`/insert`)
- [ ] Environment variables documented and configured
- [ ] No direct access to hx-ollama3-server (embedding isolation enforced)
- [ ] Structured logging implemented with component binding

---

## Verification

```bash
# Connectivity test
curl -s http://hx-literag-server.hx.dev.local:8020/health

# Python integration test
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python << 'EOF'
import asyncio
from app.clients.lightrag_client import LightRAGClient

async def test_client():
    async with LightRAGClient() as client:
        health = await client.health_check()
        print(f"Health check result: {health}")

        if health.get("status") == "healthy":
            # Test a simple query
            result = await client.query(
                query="What is this knowledge base about?",
                mode="hybrid",
                only_need_context=True
            )
            print(f"Query result: {result.response[:200]}...")
        else:
            print("LightRAG service not healthy, skipping query test")

asyncio.run(test_client())
EOF
```

---

## Rollback

```bash
# Remove client module
sudo rm -f /opt/hx-lang-server/app/clients/lightrag_client.py

# Remove environment variables from .env
sudo -u hx-lang-server sed -i '/^LIGHTRAG_/d' /opt/hx-lang-server/.env
```

---

## Notes

- **Context Size**: LightRAG requires 64KB context for entity extraction. This is handled by hx-literag-server, not this client.
- **Embedding Isolation**: All embedding operations flow through LightRAG. This client enforces that hx-lang-server never accesses hx-ollama3-server directly.
- **Dual Initialization**: The LightRAG server handles its own `initialize_storages()` and `initialize_pipeline_status()` calls. This client only consumes the HTTP API.
- **Query Modes**: While `naive` and `bypass` modes are technically supported, they should not be used in production (naive skips the knowledge graph, bypass returns raw content).

---

## Related Tasks

- **Task 025**: HTTP client packages (prerequisite)
- **Task 054**: RAG Agent worker (consumer of this client)
- **Task 082**: Adaptive retrieval mode selection (extends this client)
- **Task 085**: Response caching (wraps this client)

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
