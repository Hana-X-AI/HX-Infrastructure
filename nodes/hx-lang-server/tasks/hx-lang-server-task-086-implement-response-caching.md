# Task: Implement LightRAG Response Caching

**Task ID:** hx-lang-server-task-086-implement-response-caching
**Work Stream:** 8 - LightRAG Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-081-configure-lightrag-http-client, hx-lang-server-task-041-configure-redis-connection-pool
**Estimated Time:** 2.5 hours

---

## Objective

Implement a caching layer for LightRAG query responses using Redis, reducing latency and LLM API costs for repeated or similar queries while maintaining cache coherence with the knowledge graph.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **FR-007**: Service MUST cache session data in Redis with configurable TTL
- Redis key `hx-lang-server:cache:rag:{hash}` with 10-minute TTL

From LightRAG Cost Analysis:
- Hybrid queries require 2-3 API calls
- Caching can reduce these to zero for repeated queries
- Important to invalidate cache when knowledge graph is updated

---

## Prerequisites

- [ ] Task 081 complete: LightRAG HTTP client configured
- [ ] Task 041 complete: Redis connection pool configured
- [ ] Task 042 complete: Session manager implemented
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`

---

## Implementation Details

### File Location

```
/opt/hx-lang-server/app/rag/response_cache.py
```

### Response Caching Implementation

```python
"""
LightRAG Response Caching Layer.

This module provides Redis-based caching for LightRAG query responses,
optimizing for:

1. Latency reduction: Cached responses return in <10ms vs 1-3s
2. Cost reduction: Avoid repeated LLM API calls
3. Cache coherence: Invalidate on knowledge graph updates

Cache Strategy:
- Query hash based on normalized query + mode
- TTL-based expiration (default 10 minutes)
- Manual invalidation on document ingestion
- Namespace isolation with hx-lang-server: prefix
"""

from dataclasses import dataclass, asdict
from typing import Optional, Dict, Any
import hashlib
import json
import structlog
import redis.asyncio as redis

from app.clients.lightrag_client import LightRAGClient, QueryResponse
from app.rag.adaptive_retrieval import RetrievalResult

logger = structlog.get_logger()


# Cache configuration
CACHE_KEY_PREFIX = "hx-lang-server:cache:rag"
DEFAULT_TTL_SECONDS = 600  # 10 minutes per spec
MAX_TTL_SECONDS = 3600     # 1 hour maximum


@dataclass
class CacheConfig:
    """Configuration for response caching."""
    enabled: bool = True
    ttl_seconds: int = DEFAULT_TTL_SECONDS
    key_prefix: str = CACHE_KEY_PREFIX
    # Cache warming
    warm_on_miss: bool = True
    # Cache bypass conditions
    bypass_for_modes: list = None  # e.g., ["mix"] to never cache mix mode
    min_query_length: int = 3  # Don't cache very short queries

    def __post_init__(self):
        if self.bypass_for_modes is None:
            self.bypass_for_modes = []


@dataclass
class CacheEntry:
    """A cached response entry."""
    response: str
    context: Optional[str]
    mode_used: str
    confidence: float
    entities_found: int
    relationships_found: int
    cached_at: str
    hit_count: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CacheEntry":
        return cls(**data)

    def to_retrieval_result(self, query_hash: str) -> RetrievalResult:
        """Convert to RetrievalResult for API compatibility."""
        from app.rag.adaptive_retrieval import QueryMode
        return RetrievalResult(
            response=self.response,
            context=self.context,
            mode_used=QueryMode(self.mode_used),
            iterations=0,  # Cached = no iterations
            confidence=self.confidence,
            entities_found=self.entities_found,
            relationships_found=self.relationships_found,
            fallback_used=False,
            query_hash=query_hash
        )


class ResponseCache:
    """
    Redis-based cache for LightRAG responses.

    Key Features:
    - Query normalization for better hit rates
    - Mode-aware caching (different cache per mode)
    - TTL-based expiration
    - Hit/miss tracking for observability
    - Batch invalidation support
    """

    def __init__(
        self,
        redis_client: redis.Redis,
        config: Optional[CacheConfig] = None
    ):
        self.redis = redis_client
        self.config = config or CacheConfig()
        self._logger = logger.bind(component="response_cache")

        # Metrics
        self._hits = 0
        self._misses = 0

    def _normalize_query(self, query: str) -> str:
        """
        Normalize query for consistent cache keys.

        Normalization:
        - Lowercase
        - Collapse whitespace
        - Strip leading/trailing whitespace
        """
        return " ".join(query.lower().split())

    def _generate_cache_key(self, query: str, mode: str) -> str:
        """
        Generate cache key from query and mode.

        Format: hx-lang-server:cache:rag:{mode}:{hash}
        """
        normalized = self._normalize_query(query)
        query_hash = hashlib.sha256(normalized.encode()).hexdigest()[:16]
        return f"{self.config.key_prefix}:{mode}:{query_hash}"

    def _should_cache(self, query: str, mode: str) -> bool:
        """Determine if query should be cached."""
        if not self.config.enabled:
            return False

        if len(query) < self.config.min_query_length:
            return False

        if mode in self.config.bypass_for_modes:
            return False

        return True

    async def get(
        self,
        query: str,
        mode: str
    ) -> Optional[CacheEntry]:
        """
        Get cached response for query.

        Args:
            query: The query text
            mode: Query mode (local, global, hybrid, mix)

        Returns:
            CacheEntry if found, None otherwise
        """
        if not self._should_cache(query, mode):
            return None

        cache_key = self._generate_cache_key(query, mode)

        try:
            data = await self.redis.get(cache_key)

            if data is None:
                self._misses += 1
                self._logger.debug(
                    "cache_miss",
                    cache_key=cache_key,
                    mode=mode
                )
                return None

            entry = CacheEntry.from_dict(json.loads(data))
            entry.hit_count += 1

            # Update hit count in cache (fire and forget)
            await self.redis.setex(
                cache_key,
                self.config.ttl_seconds,
                json.dumps(entry.to_dict())
            )

            self._hits += 1
            self._logger.info(
                "cache_hit",
                cache_key=cache_key,
                mode=mode,
                hit_count=entry.hit_count
            )

            return entry

        except Exception as e:
            self._logger.error(
                "cache_get_error",
                cache_key=cache_key,
                error=str(e)
            )
            return None

    async def set(
        self,
        query: str,
        mode: str,
        result: RetrievalResult,
        ttl: Optional[int] = None
    ) -> bool:
        """
        Cache a response.

        Args:
            query: The query text
            mode: Query mode
            result: The retrieval result to cache
            ttl: Optional TTL override

        Returns:
            True if cached successfully
        """
        if not self._should_cache(query, mode):
            return False

        cache_key = self._generate_cache_key(query, mode)
        ttl = ttl or self.config.ttl_seconds
        ttl = min(ttl, MAX_TTL_SECONDS)

        from datetime import datetime
        entry = CacheEntry(
            response=result.response,
            context=result.context,
            mode_used=result.mode_used.value if hasattr(result.mode_used, 'value') else str(result.mode_used),
            confidence=result.confidence,
            entities_found=result.entities_found,
            relationships_found=result.relationships_found,
            cached_at=datetime.utcnow().isoformat(),
            hit_count=0
        )

        try:
            await self.redis.setex(
                cache_key,
                ttl,
                json.dumps(entry.to_dict())
            )

            self._logger.debug(
                "cache_set",
                cache_key=cache_key,
                mode=mode,
                ttl=ttl
            )
            return True

        except Exception as e:
            self._logger.error(
                "cache_set_error",
                cache_key=cache_key,
                error=str(e)
            )
            return False

    async def invalidate(self, query: str, mode: Optional[str] = None) -> int:
        """
        Invalidate cache for a query.

        Args:
            query: The query to invalidate
            mode: Optional mode (if None, invalidates all modes)

        Returns:
            Number of keys deleted
        """
        deleted = 0

        if mode:
            cache_key = self._generate_cache_key(query, mode)
            deleted = await self.redis.delete(cache_key)
        else:
            # Invalidate all modes
            for m in ["local", "global", "hybrid", "mix"]:
                cache_key = self._generate_cache_key(query, m)
                deleted += await self.redis.delete(cache_key)

        self._logger.info(
            "cache_invalidated",
            query_length=len(query),
            mode=mode,
            keys_deleted=deleted
        )
        return deleted

    async def invalidate_all(self) -> int:
        """
        Invalidate entire RAG cache.

        Use after bulk document ingestion.

        Returns:
            Number of keys deleted
        """
        pattern = f"{self.config.key_prefix}:*"

        keys = []
        async for key in self.redis.scan_iter(match=pattern):
            keys.append(key)

        deleted = 0
        if keys:
            deleted = await self.redis.delete(*keys)

        self._logger.info(
            "cache_invalidated_all",
            keys_deleted=deleted
        )
        return deleted

    async def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total = self._hits + self._misses
        hit_rate = (self._hits / total * 100) if total > 0 else 0

        # Count current cache entries
        pattern = f"{self.config.key_prefix}:*"
        count = 0
        async for _ in self.redis.scan_iter(match=pattern):
            count += 1

        return {
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate_percent": round(hit_rate, 2),
            "cached_entries": count,
            "ttl_seconds": self.config.ttl_seconds,
            "enabled": self.config.enabled
        }


class CachedLightRAGClient:
    """
    LightRAG client with integrated response caching.

    Wraps the base client to add transparent caching:
    1. Check cache before query
    2. Execute query on cache miss
    3. Cache successful responses
    4. Handle cache invalidation
    """

    def __init__(
        self,
        client: LightRAGClient,
        cache: ResponseCache
    ):
        self.client = client
        self.cache = cache
        self._logger = logger.bind(component="cached_lightrag_client")

    async def query(
        self,
        query: str,
        mode: str = "hybrid",
        bypass_cache: bool = False,
        **kwargs
    ) -> RetrievalResult:
        """
        Execute cached query.

        Args:
            query: Query text
            mode: Query mode
            bypass_cache: Skip cache lookup
            **kwargs: Additional query parameters

        Returns:
            RetrievalResult (from cache or fresh)
        """
        # Check cache first
        if not bypass_cache:
            cached = await self.cache.get(query, mode)
            if cached:
                query_hash = hashlib.sha256(query.lower().encode()).hexdigest()[:16]
                return cached.to_retrieval_result(query_hash)

        # Cache miss - execute query
        from app.rag.adaptive_retrieval import AdaptiveRetriever, QueryMode

        retriever = AdaptiveRetriever(self.client)
        result = await retriever.retrieve(
            query=query,
            force_mode=QueryMode(mode) if mode else None,
            **kwargs
        )

        # Cache successful results
        if result.confidence > 0.5:  # Only cache confident results
            await self.cache.set(query, mode, result)

        return result

    async def invalidate_on_ingestion(self) -> int:
        """
        Invalidate cache after document ingestion.

        Call this after ingesting new documents to ensure
        queries reflect updated knowledge graph.
        """
        return await self.cache.invalidate_all()


# Factory function for dependency injection

async def create_cached_client(
    redis_client: redis.Redis,
    lightrag_client: Optional[LightRAGClient] = None,
    cache_config: Optional[CacheConfig] = None
) -> CachedLightRAGClient:
    """
    Create a cached LightRAG client.

    Args:
        redis_client: Redis connection
        lightrag_client: Optional existing client
        cache_config: Optional cache configuration

    Returns:
        CachedLightRAGClient ready for use
    """
    if lightrag_client is None:
        lightrag_client = LightRAGClient()
        await lightrag_client.connect()

    cache = ResponseCache(redis_client, cache_config)

    return CachedLightRAGClient(lightrag_client, cache)
```

---

## Manual Steps

### Step 1: Create Response Cache Module

```bash
# Create the response_cache.py file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/app/rag/response_cache.py
```

### Step 2: Update Module Init

```bash
# Update __init__.py to include response_cache exports
cat << 'EOF' | sudo -u hx-lang-server tee -a /opt/hx-lang-server/app/rag/__init__.py

# Response caching
from .response_cache import (
    CacheConfig,
    CacheEntry,
    ResponseCache,
    CachedLightRAGClient,
    create_cached_client,
    CACHE_KEY_PREFIX,
    DEFAULT_TTL_SECONDS,
)
EOF
```

---

## Redis Key Schema

Per specification, RAG cache keys follow this pattern:

| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:cache:rag:local:{hash}` | Local mode query cache | 10 min |
| `hx-lang-server:cache:rag:global:{hash}` | Global mode query cache | 10 min |
| `hx-lang-server:cache:rag:hybrid:{hash}` | Hybrid mode query cache | 10 min |
| `hx-lang-server:cache:rag:mix:{hash}` | Mix mode query cache | 10 min |

---

## Acceptance Criteria

- [ ] ResponseCache class implemented with:
  - Query normalization for consistent keys
  - Mode-aware cache keys
  - TTL-based expiration (10 minutes default)
  - Hit/miss tracking
  - Manual invalidation support
  - Batch invalidation (`invalidate_all`)
- [ ] CachedLightRAGClient wrapper:
  - Transparent cache integration
  - Bypass option for fresh queries
  - Automatic cache population on miss
  - Confidence threshold for caching
- [ ] Cache key format follows specification:
  - Prefix: `hx-lang-server:cache:rag`
  - Mode included in key
  - SHA256 hash of normalized query
- [ ] Statistics endpoint for cache monitoring
- [ ] Proper error handling (cache failures dont break queries)

---

## Verification

```bash
# Python integration test
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python << 'EOF'
import asyncio
import redis.asyncio as redis
from app.rag.response_cache import (
    ResponseCache,
    CacheConfig,
    CacheEntry,
    CachedLightRAGClient,
    CACHE_KEY_PREFIX,
)
from app.clients.lightrag_client import LightRAGClient
from app.rag.adaptive_retrieval import RetrievalResult, QueryMode

async def test_response_cache():
    # Connect to Redis
    redis_client = redis.from_url("redis://hx-redis-server.hx.dev.local:6379/0")

    try:
        # Create cache
        config = CacheConfig(ttl_seconds=60)  # 1 minute for testing
        cache = ResponseCache(redis_client, config)

        # Test key generation
        key1 = cache._generate_cache_key("What is LightRAG?", "hybrid")
        key2 = cache._generate_cache_key("what is lightrag?", "hybrid")  # Same normalized
        key3 = cache._generate_cache_key("What is LightRAG?", "local")   # Different mode

        print(f"Key 1: {key1}")
        print(f"Key 2: {key2}")
        print(f"Key 3: {key3}")

        assert key1 == key2, "Normalized queries should have same key"
        assert key1 != key3, "Different modes should have different keys"
        assert CACHE_KEY_PREFIX in key1, "Key should include prefix"

        # Test cache operations
        test_result = RetrievalResult(
            response="LightRAG is a graph-based RAG framework.",
            context="Some context here",
            mode_used=QueryMode.HYBRID,
            iterations=1,
            confidence=0.85,
            entities_found=3,
            relationships_found=2,
            fallback_used=False,
            query_hash="test123"
        )

        # Set cache
        success = await cache.set("What is LightRAG?", "hybrid", test_result)
        assert success, "Cache set should succeed"

        # Get cache (should hit)
        cached = await cache.get("What is LightRAG?", "hybrid")
        assert cached is not None, "Cache get should hit"
        print(f"\nCached entry:")
        print(f"  Response: {cached.response[:50]}...")
        print(f"  Confidence: {cached.confidence}")
        print(f"  Hit count: {cached.hit_count}")

        # Get with normalized query (should also hit)
        cached2 = await cache.get("  WHAT is  LightRAG?  ", "hybrid")
        assert cached2 is not None, "Normalized query should hit cache"
        print(f"  Hit count after second get: {cached2.hit_count}")

        # Get different mode (should miss)
        cached_local = await cache.get("What is LightRAG?", "local")
        assert cached_local is None, "Different mode should miss"

        # Test stats
        stats = await cache.get_stats()
        print(f"\nCache stats: {stats}")
        assert stats["hits"] >= 2, "Should have at least 2 hits"
        assert stats["misses"] >= 1, "Should have at least 1 miss"

        # Test invalidation
        deleted = await cache.invalidate("What is LightRAG?", "hybrid")
        assert deleted == 1, "Should delete 1 key"

        # Verify deleted
        cached_after = await cache.get("What is LightRAG?", "hybrid")
        assert cached_after is None, "Should miss after invalidation"

        print("\nAll response cache tests passed!")

    finally:
        await redis_client.close()

asyncio.run(test_response_cache())
EOF
```

---

## Rollback

```bash
# Remove response cache module
sudo rm -f /opt/hx-lang-server/app/rag/response_cache.py

# Clear cache from Redis
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:cache:rag:*" | xargs redis-cli -h hx-redis-server.hx.dev.local DEL
```

---

## Notes

- **Cache Invalidation Strategy**: The cache is invalidated after document ingestion because new documents may change query results. For more granular invalidation, consider tracking which queries touched which documents.

- **Confidence Threshold**: Only responses with confidence > 0.5 are cached. This prevents caching low-quality or failed responses.

- **TTL Considerations**: The 10-minute TTL balances freshness vs performance. For rapidly changing knowledge bases, consider shorter TTLs. For static content, longer TTLs improve hit rates.

- **Mode Separation**: Each query mode has its own cache entry because the same query may return different results in different modes.

---

## Related Tasks

- **Task 081**: LightRAG HTTP client (cached by this layer)
- **Task 041**: Redis connection pool (prerequisite)
- **Task 082**: Adaptive retrieval (uses cached client)
- **Task 085**: Document ingestion (triggers cache invalidation)

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
