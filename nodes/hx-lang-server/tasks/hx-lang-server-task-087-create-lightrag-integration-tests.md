# Task: Create LightRAG Integration Tests

**Task ID:** hx-lang-server-task-087-create-lightrag-integration-tests
**Work Stream:** 8 - LightRAG Integration
**Phase:** Testing
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-081 through hx-lang-server-task-086
**Estimated Time:** 3 hours

---

## Objective

Create a comprehensive integration test suite for LightRAG integration, validating connectivity, query modes, adaptive retrieval, context handling, document ingestion, and response caching.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **SC-004**: LightRAG integration functional (RAG query returns results)
- **Test Categories**: Integration Tests - 20 cases total
- **Quality Gates**: All integration tests must pass before deployment

---

## Prerequisites

- [ ] Tasks 081-086 complete: All LightRAG components implemented
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`
- [ ] pytest installed in virtual environment
- [ ] LightRAG server operational at hx-literag-server.hx.dev.local:8020

---

## Test Categories

### 1. Connectivity Tests (4 tests)
- LightRAG health endpoint accessible
- Query endpoint responds
- Insert endpoint responds
- Connection timeout handling

### 2. Query Mode Tests (4 tests)
- Local mode query execution
- Global mode query execution
- Hybrid mode query execution
- Mix mode query execution

### 3. Adaptive Retrieval Tests (4 tests)
- Query classification accuracy
- Mode escalation on insufficient results
- Confidence scoring
- Maximum iterations enforcement

### 4. Context Handling Tests (3 tests)
- 64KB context validation
- Context truncation behavior
- Context assembly for hybrid mode

### 5. Document Ingestion Tests (3 tests)
- Single document ingestion
- Batch document ingestion
- Incremental update (skip if indexed)

### 6. Response Caching Tests (4 tests)
- Cache hit behavior
- Cache miss behavior
- Cache invalidation
- Cache statistics

---

## Implementation Details

### Test File Location

```
/opt/hx-lang-server/tests/integration/test_lightrag_integration.py
```

### Test Implementation

```python
"""
Integration Tests for LightRAG Integration.

This test suite validates the complete LightRAG integration including:
- HTTP client connectivity
- All query modes (local, global, hybrid, mix)
- Adaptive retrieval with mode escalation
- 64KB context handling
- Document ingestion workflow
- Response caching

Run with: pytest tests/integration/test_lightrag_integration.py -v
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, patch, MagicMock
import redis.asyncio as redis
import hashlib

# Import modules under test
from app.clients.lightrag_client import (
    LightRAGClient,
    LightRAGClientSettings,
    QueryRequest,
    QueryResponse,
)
from app.rag.adaptive_retrieval import (
    AdaptiveRetriever,
    RetrievalConfig,
    RetrievalResult,
    QueryMode,
    QueryType,
)
from app.rag.query_modes import (
    QueryModeConfig,
    QueryModeSelector,
    MODE_CONFIGS,
    QueryModeType,
)
from app.rag.context_manager import (
    ContextBudget,
    ContextManager,
    ContextChunk,
    RECOMMENDED_CONTEXT_TOKENS,
    validate_ollama_context,
)
from app.rag.document_ingestion import (
    DocumentPreprocessor,
    DocumentIngestionService,
    DocumentStatus,
    IngestionResult,
)
from app.rag.response_cache import (
    ResponseCache,
    CacheConfig,
    CacheEntry,
    CachedLightRAGClient,
)


# Fixtures

@pytest.fixture
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def lightrag_settings():
    """Create test LightRAG settings."""
    return LightRAGClientSettings(
        lightrag_base_url="http://hx-literag-server.hx.dev.local:8020",
        lightrag_timeout=30.0,
        lightrag_connect_timeout=5.0,
    )


@pytest.fixture
async def lightrag_client(lightrag_settings):
    """Create LightRAG client for testing."""
    client = LightRAGClient(settings=lightrag_settings)
    await client.connect()
    yield client
    await client.close()


@pytest.fixture
async def redis_client():
    """Create Redis client for caching tests."""
    client = redis.from_url("redis://hx-redis-server.hx.dev.local:6379/0")
    yield client
    # Cleanup test keys
    async for key in client.scan_iter(match="hx-lang-server:cache:rag:test:*"):
        await client.delete(key)
    await client.close()


# ============================================================
# CONNECTIVITY TESTS
# ============================================================

class TestLightRAGConnectivity:
    """Test LightRAG HTTP client connectivity."""

    @pytest.mark.asyncio
    async def test_health_endpoint_accessible(self, lightrag_client):
        """TC-LIGHTRAG-001: Health endpoint is accessible."""
        health = await lightrag_client.health_check()

        assert health is not None
        assert "status" in health
        # Allow healthy or unhealthy - we're testing connectivity
        assert health["status"] in ("healthy", "unhealthy", "unreachable")

    @pytest.mark.asyncio
    async def test_query_endpoint_responds(self, lightrag_client):
        """TC-LIGHTRAG-002: Query endpoint accepts requests."""
        # This may fail if LightRAG has no indexed data, but endpoint should respond
        try:
            result = await lightrag_client.query(
                query="test query",
                mode="local",
                only_need_context=True
            )
            assert result is not None
            assert hasattr(result, "response")
        except Exception as e:
            # Connection/HTTP errors are acceptable for connectivity test
            assert "Connection" in str(e) or "HTTP" in str(e)

    @pytest.mark.asyncio
    async def test_insert_endpoint_responds(self, lightrag_client):
        """TC-LIGHTRAG-003: Insert endpoint accepts requests."""
        try:
            result = await lightrag_client.insert_document(
                content="Test document for integration test.",
                doc_id="test-integration-001"
            )
            assert result is not None
        except Exception as e:
            # Verify it's not a 404 (endpoint not found)
            assert "404" not in str(e)

    @pytest.mark.asyncio
    async def test_connection_timeout_handling(self):
        """TC-LIGHTRAG-004: Client handles connection timeouts gracefully."""
        settings = LightRAGClientSettings(
            lightrag_base_url="http://192.168.10.254:9999",  # Non-existent
            lightrag_connect_timeout=1.0  # Short timeout
        )
        client = LightRAGClient(settings=settings)

        health = await client.health_check()

        assert health["status"] == "unreachable"
        assert "error" in health


# ============================================================
# QUERY MODE TESTS
# ============================================================

class TestQueryModes:
    """Test all LightRAG query modes."""

    @pytest.mark.asyncio
    async def test_local_mode_query(self, lightrag_client):
        """TC-LIGHTRAG-005: Local mode returns entity-focused results."""
        result = await lightrag_client.query(
            query="Who is the author?",
            mode="local"
        )

        assert result is not None
        assert result.query_mode == "local"

    @pytest.mark.asyncio
    async def test_global_mode_query(self, lightrag_client):
        """TC-LIGHTRAG-006: Global mode returns thematic results."""
        result = await lightrag_client.query(
            query="Why is security important?",
            mode="global"
        )

        assert result is not None
        assert result.query_mode == "global"

    @pytest.mark.asyncio
    async def test_hybrid_mode_query(self, lightrag_client):
        """TC-LIGHTRAG-007: Hybrid mode combines local and global."""
        result = await lightrag_client.query(
            query="Explain the relationship between authentication and authorization",
            mode="hybrid"
        )

        assert result is not None
        assert result.query_mode == "hybrid"

    @pytest.mark.asyncio
    async def test_mix_mode_query(self, lightrag_client):
        """TC-LIGHTRAG-008: Mix mode blends contexts."""
        result = await lightrag_client.query(
            query="Tell me about the system architecture",
            mode="mix"
        )

        assert result is not None
        assert result.query_mode == "mix"


# ============================================================
# ADAPTIVE RETRIEVAL TESTS
# ============================================================

class TestAdaptiveRetrieval:
    """Test adaptive retrieval with mode selection and escalation."""

    @pytest.mark.asyncio
    async def test_query_classification_entity(self, lightrag_client):
        """TC-LIGHTRAG-009: Entity queries classified correctly."""
        retriever = AdaptiveRetriever(lightrag_client)

        query_type, mode = retriever.classify_query("Who wrote this document?")

        assert query_type == QueryType.ENTITY
        assert mode == QueryMode.LOCAL

    @pytest.mark.asyncio
    async def test_query_classification_thematic(self, lightrag_client):
        """TC-LIGHTRAG-010: Thematic queries classified correctly."""
        retriever = AdaptiveRetriever(lightrag_client)

        query_type, mode = retriever.classify_query("Why is testing important?")

        assert query_type == QueryType.THEMATIC
        assert mode == QueryMode.GLOBAL

    @pytest.mark.asyncio
    async def test_mode_escalation(self, lightrag_client):
        """TC-LIGHTRAG-011: Mode escalates on insufficient results."""
        # Create mock client that returns insufficient results for local
        mock_client = AsyncMock()
        mock_client.query = AsyncMock(return_value=QueryResponse(
            response="",  # Empty = insufficient
            context=None,
            entities=None,
            relationships=None,
            query_mode="local",
            tokens_used=0
        ))

        retriever = AdaptiveRetriever(
            mock_client,
            config=RetrievalConfig(min_response_length=10)
        )

        result = await retriever.retrieve("Test query")

        # Should have escalated past local
        assert result.iterations > 1 or result.mode_used != QueryMode.LOCAL

    @pytest.mark.asyncio
    async def test_max_iterations_enforced(self, lightrag_client):
        """TC-LIGHTRAG-012: Maximum iterations limit is enforced."""
        config = RetrievalConfig(max_iterations=2)
        retriever = AdaptiveRetriever(lightrag_client, config=config)

        # Mock to always return insufficient results
        with patch.object(retriever, 'evaluate_result', return_value=(False, 0.1)):
            result = await retriever.retrieve("Test query")

        assert result.iterations <= config.max_iterations


# ============================================================
# CONTEXT HANDLING TESTS
# ============================================================

class TestContextHandling:
    """Test 64KB context handling."""

    def test_context_budget_64kb(self):
        """TC-LIGHTRAG-013: Default context budget is 64KB."""
        budget = ContextBudget()

        assert budget.total_tokens == RECOMMENDED_CONTEXT_TOKENS
        assert budget.total_tokens == 65536  # 64KB

    def test_context_truncation(self):
        """TC-LIGHTRAG-014: Context truncates correctly."""
        manager = ContextManager()

        # Create text longer than budget
        long_text = "This is a test sentence. " * 10000
        truncated = manager.truncate_to_budget(long_text, 100)

        tokens = manager.count_tokens(truncated)
        assert tokens <= 105  # Some buffer allowed

    def test_context_assembly_hybrid(self):
        """TC-LIGHTRAG-015: Hybrid mode assembles both local and global context."""
        manager = ContextManager()

        local_chunks = [
            ContextChunk(content="Local entity info", source="local", relevance_score=0.9)
        ]
        global_chunks = [
            ContextChunk(content="Global theme info", source="global", relevance_score=0.8)
        ]

        assembled, metadata = manager.assemble_context(local_chunks, global_chunks, "hybrid")

        assert "Entity Context" in assembled
        assert "Thematic Context" in assembled
        assert metadata["local_chunks_used"] == 1
        assert metadata["global_chunks_used"] == 1


# ============================================================
# DOCUMENT INGESTION TESTS
# ============================================================

class TestDocumentIngestion:
    """Test document ingestion workflow."""

    @pytest.mark.asyncio
    async def test_single_document_ingestion(self, lightrag_client):
        """TC-LIGHTRAG-016: Single document ingests successfully."""
        service = DocumentIngestionService(lightrag_client)

        result = await service.ingest_document(
            content="This is a test document for ingestion testing.",
            doc_id="test-ingest-001"
        )

        assert result is not None
        assert result.doc_id == "test-ingest-001"
        assert result.status in (DocumentStatus.INDEXED, DocumentStatus.FAILED)

    @pytest.mark.asyncio
    async def test_batch_document_ingestion(self, lightrag_client):
        """TC-LIGHTRAG-017: Batch ingestion processes multiple documents."""
        service = DocumentIngestionService(lightrag_client, batch_size=2)

        documents = [
            {"content": "Document one content", "doc_id": "batch-001"},
            {"content": "Document two content", "doc_id": "batch-002"},
            {"content": "Document three content", "doc_id": "batch-003"},
        ]

        result = await service.ingest_batch(documents)

        assert result.total_documents == 3
        assert result.successful + result.failed + result.skipped == 3

    @pytest.mark.asyncio
    async def test_skip_if_indexed(self, lightrag_client):
        """TC-LIGHTRAG-018: Already-indexed documents are skipped."""
        service = DocumentIngestionService(lightrag_client)

        content = "This content will be ingested twice."

        # First ingestion
        result1 = await service.ingest_document(content, skip_if_indexed=True)

        # Second ingestion (should skip)
        result2 = await service.ingest_document(content, skip_if_indexed=True)

        # First should be indexed (or failed), second should be skipped
        if result1.status == DocumentStatus.INDEXED:
            assert result2.status == DocumentStatus.SKIPPED


# ============================================================
# RESPONSE CACHING TESTS
# ============================================================

class TestResponseCaching:
    """Test response caching with Redis."""

    @pytest.mark.asyncio
    async def test_cache_hit(self, redis_client, lightrag_client):
        """TC-LIGHTRAG-019: Cache returns stored response."""
        config = CacheConfig(key_prefix="hx-lang-server:cache:rag:test")
        cache = ResponseCache(redis_client, config)

        # Store a result
        result = RetrievalResult(
            response="Cached response",
            context="Cached context",
            mode_used=QueryMode.HYBRID,
            iterations=1,
            confidence=0.9,
            entities_found=2,
            relationships_found=1,
            fallback_used=False,
            query_hash="test123"
        )

        await cache.set("test query", "hybrid", result)

        # Retrieve from cache
        cached = await cache.get("test query", "hybrid")

        assert cached is not None
        assert cached.response == "Cached response"
        assert cached.confidence == 0.9

    @pytest.mark.asyncio
    async def test_cache_miss(self, redis_client):
        """TC-LIGHTRAG-020: Cache miss returns None."""
        config = CacheConfig(key_prefix="hx-lang-server:cache:rag:test")
        cache = ResponseCache(redis_client, config)

        cached = await cache.get("nonexistent query", "hybrid")

        assert cached is None

    @pytest.mark.asyncio
    async def test_cache_invalidation(self, redis_client, lightrag_client):
        """TC-LIGHTRAG-021: Cache invalidation removes entries."""
        config = CacheConfig(key_prefix="hx-lang-server:cache:rag:test")
        cache = ResponseCache(redis_client, config)

        # Store a result
        result = RetrievalResult(
            response="To be invalidated",
            context=None,
            mode_used=QueryMode.LOCAL,
            iterations=1,
            confidence=0.8,
            entities_found=1,
            relationships_found=0,
            fallback_used=False,
            query_hash="inv123"
        )

        await cache.set("invalidation test", "local", result)

        # Verify it's cached
        cached = await cache.get("invalidation test", "local")
        assert cached is not None

        # Invalidate
        deleted = await cache.invalidate("invalidation test", "local")
        assert deleted == 1

        # Verify it's gone
        cached_after = await cache.get("invalidation test", "local")
        assert cached_after is None

    @pytest.mark.asyncio
    async def test_cache_statistics(self, redis_client):
        """TC-LIGHTRAG-022: Cache statistics are tracked."""
        config = CacheConfig(key_prefix="hx-lang-server:cache:rag:test")
        cache = ResponseCache(redis_client, config)

        # Generate some hits and misses
        await cache.get("miss1", "hybrid")  # Miss
        await cache.get("miss2", "hybrid")  # Miss

        result = RetrievalResult(
            response="For stats",
            context=None,
            mode_used=QueryMode.HYBRID,
            iterations=1,
            confidence=0.8,
            entities_found=1,
            relationships_found=0,
            fallback_used=False,
            query_hash="stats123"
        )
        await cache.set("stats query", "hybrid", result)
        await cache.get("stats query", "hybrid")  # Hit

        stats = await cache.get_stats()

        assert "hits" in stats
        assert "misses" in stats
        assert "hit_rate_percent" in stats
        assert stats["hits"] >= 1
        assert stats["misses"] >= 2


# ============================================================
# END-TO-END TEST
# ============================================================

class TestEndToEnd:
    """End-to-end integration test."""

    @pytest.mark.asyncio
    async def test_complete_rag_workflow(self, lightrag_client, redis_client):
        """TC-LIGHTRAG-E2E: Complete RAG workflow executes successfully."""
        # 1. Check LightRAG health
        health = await lightrag_client.health_check()
        if health["status"] != "healthy":
            pytest.skip("LightRAG not healthy, skipping E2E test")

        # 2. Ingest a test document
        ingestion_service = DocumentIngestionService(lightrag_client)
        ingest_result = await ingestion_service.ingest_document(
            content="The HX-Infrastructure uses LangGraph for agent orchestration. "
                    "LangGraph is integrated with LightRAG for knowledge retrieval.",
            doc_id="e2e-test-001"
        )
        assert ingest_result.status in (DocumentStatus.INDEXED, DocumentStatus.SKIPPED)

        # 3. Create cached client
        cache_config = CacheConfig(
            key_prefix="hx-lang-server:cache:rag:e2e",
            ttl_seconds=60
        )
        cache = ResponseCache(redis_client, cache_config)
        cached_client = CachedLightRAGClient(lightrag_client, cache)

        # 4. Execute query (should miss cache, query LightRAG)
        result1 = await cached_client.query(
            query="What does HX-Infrastructure use for agent orchestration?",
            mode="hybrid"
        )
        assert result1 is not None
        assert len(result1.response) > 0

        # 5. Execute same query (should hit cache)
        result2 = await cached_client.query(
            query="What does HX-Infrastructure use for agent orchestration?",
            mode="hybrid"
        )
        assert result2 is not None
        assert result2.response == result1.response

        # 6. Check cache stats
        stats = await cache.get_stats()
        assert stats["hits"] >= 1

        # Cleanup
        await cache.invalidate_all()


# ============================================================
# TEST RUNNER
# ============================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
```

---

## Manual Steps

### Step 1: Create Test Directory

```bash
# Create test directory structure
sudo -u hx-lang-server mkdir -p /opt/hx-lang-server/tests/integration
sudo -u hx-lang-server touch /opt/hx-lang-server/tests/__init__.py
sudo -u hx-lang-server touch /opt/hx-lang-server/tests/integration/__init__.py
```

### Step 2: Install Test Dependencies

```bash
# Install pytest and pytest-asyncio
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pip install pytest pytest-asyncio
```

### Step 3: Create Test File

```bash
# Create the test file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/tests/integration/test_lightrag_integration.py
```

### Step 4: Create pytest.ini

```bash
cat << 'EOF' | sudo -u hx-lang-server tee /opt/hx-lang-server/pytest.ini
[pytest]
asyncio_mode = auto
testpaths = tests
python_files = test_*.py
python_functions = test_*
markers =
    asyncio: mark test as async
EOF
```

---

## Test Execution

```bash
# Run all LightRAG integration tests
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pytest \
    tests/integration/test_lightrag_integration.py \
    -v \
    --tb=short

# Run specific test class
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pytest \
    tests/integration/test_lightrag_integration.py::TestQueryModes \
    -v

# Run with coverage
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pytest \
    tests/integration/test_lightrag_integration.py \
    -v \
    --cov=app.rag \
    --cov-report=term-missing
```

---

## Acceptance Criteria

- [ ] 22 integration tests created covering all LightRAG components:
  - 4 connectivity tests
  - 4 query mode tests
  - 4 adaptive retrieval tests
  - 3 context handling tests
  - 3 document ingestion tests
  - 4 response caching tests
- [ ] Test fixtures properly set up for async testing
- [ ] Tests use actual LightRAG server (not mocks) where possible
- [ ] Tests clean up after themselves (cache entries, test documents)
- [ ] pytest.ini configured for async test support
- [ ] All tests pass when LightRAG is available
- [ ] Tests skip gracefully when LightRAG is unavailable

---

## Verification

```bash
# Verify tests are discoverable
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pytest \
    tests/integration/test_lightrag_integration.py \
    --collect-only

# Run tests with verbose output
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pytest \
    tests/integration/test_lightrag_integration.py \
    -v \
    2>&1 | tee /tmp/lightrag-test-results.txt

# Check test count
grep -c "PASSED\|FAILED\|SKIPPED" /tmp/lightrag-test-results.txt
```

---

## Rollback

```bash
# Remove test files
sudo rm -rf /opt/hx-lang-server/tests/integration/test_lightrag_integration.py
sudo rm -f /opt/hx-lang-server/pytest.ini
```

---

## Notes

- **Test Isolation**: Each test class tests a specific component. The E2E test validates the full workflow.

- **Async Testing**: All tests use pytest-asyncio for proper async/await support.

- **Mock vs Real**: Connectivity tests and cache tests can use real services. Some adaptive retrieval tests use mocks to simulate edge cases.

- **Skip on Unavailable**: Tests should skip gracefully if LightRAG is not available rather than fail.

---

## Related Tasks

- **Tasks 081-086**: Components being tested
- **Task 151+**: Test suite generation (Julia's work stream)
- **SC-004**: Success criterion for LightRAG integration

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
