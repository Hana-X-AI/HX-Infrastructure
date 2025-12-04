# Task: Implement LLM Response Cache

**Task ID**: hx-lang-server-task-045-implement-llm-response-cache
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-043 (Redis key namespace), hx-lang-server-task-044 (TTL strategy)
**Estimated Time**: 45 minutes

---

## Objective

Implement an LLM response caching layer to reduce redundant Ollama calls and improve response latency. The cache uses semantic key generation based on model, query, and configuration to enable cache hits for identical requests. Includes cache stampede prevention to handle concurrent requests for the same uncached query.

---

## Prerequisites

- [ ] Redis key namespace configured (task-043)
- [ ] TTL strategy implemented (task-044)
- [ ] RedisKeys module available

---

## Specification Reference

**From node-spec.md v2.1, Section: Redis Key Schema:**

| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:cache:llm:{hash}` | LLM response cache | 5 minutes |
| `hx-lang-server:cache:rag:{hash}` | RAG result cache | 10 minutes |
| `hx-lang-server:cache:classify:{hash}` | Query classification cache | 30 minutes |

**From Sri Patel's Redis contribution - LLM Response Cache Implementation pattern.**

---

## Implementation Steps

### Step 1: Create Cache Service Module

Create file: `/opt/hx-lang-server/app/services/cache_service.py`

```python
"""
Caching services for hx-lang-server.

Provides caching for:
- LLM responses (5 minute TTL)
- RAG results (10 minute TTL)
- Query classifications (30 minute TTL)

Includes cache stampede prevention using distributed locking.
"""

import json
import hashlib
import asyncio
from typing import Optional, Callable, TypeVar, Any
import redis.asyncio as redis
import structlog

from app.core.redis_keys import RedisKeys, KEYS

logger = structlog.get_logger(__name__)

T = TypeVar("T")


class LLMResponseCache:
    """
    Cache for LLM responses with semantic key generation.

    Uses model + query + config to generate deterministic cache keys,
    enabling cache hits for identical requests.
    """

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize LLM response cache.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    def _generate_cache_key(
        self,
        model: str,
        query: str,
        config: Optional[dict] = None,
    ) -> str:
        """
        Generate deterministic cache key from query parameters.

        Args:
            model: Model name (e.g., "gemma3:27b")
            query: User query
            config: Optional configuration affecting response

        Returns:
            Full cache key with namespace prefix
        """
        # Normalize and combine inputs
        content = f"{model}:{query}:{json.dumps(config or {}, sort_keys=True)}"
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        return KEYS.cache_llm(content_hash)

    async def get(
        self,
        model: str,
        query: str,
        config: Optional[dict] = None,
    ) -> Optional[str]:
        """
        Get cached LLM response.

        Args:
            model: Model name
            query: User query
            config: Optional configuration

        Returns:
            Cached response if found, None otherwise
        """
        key = self._generate_cache_key(model, query, config)
        cached = await self.redis.get(key)

        if cached:
            logger.debug(
                "llm_cache_hit",
                model=model,
                query_preview=query[:50],
            )
            return cached

        logger.debug(
            "llm_cache_miss",
            model=model,
            query_preview=query[:50],
        )
        return None

    async def set(
        self,
        model: str,
        query: str,
        response: str,
        config: Optional[dict] = None,
    ) -> None:
        """
        Cache LLM response.

        Args:
            model: Model name
            query: User query
            response: LLM response to cache
            config: Optional configuration
        """
        key = self._generate_cache_key(model, query, config)
        await self.redis.setex(key, RedisKeys.TTL_LLM_CACHE, response)
        logger.debug(
            "llm_cache_set",
            key=key,
            ttl=RedisKeys.TTL_LLM_CACHE,
            response_length=len(response),
        )

    async def delete(
        self,
        model: str,
        query: str,
        config: Optional[dict] = None,
    ) -> bool:
        """
        Delete cached response.

        Args:
            model: Model name
            query: User query
            config: Optional configuration

        Returns:
            True if key was deleted
        """
        key = self._generate_cache_key(model, query, config)
        deleted = await self.redis.delete(key)
        return bool(deleted)

    async def get_or_invoke(
        self,
        model: str,
        query: str,
        invoke_func: Callable[[], Any],
        config: Optional[dict] = None,
    ) -> str:
        """
        Get from cache or invoke LLM and cache result.

        This is the primary method for cache-aside pattern.

        Args:
            model: Model name
            query: User query
            invoke_func: Async function to call LLM if cache miss
            config: Optional configuration

        Returns:
            Cached or freshly generated response
        """
        # Try cache first
        cached = await self.get(model, query, config)
        if cached:
            return cached

        # Cache miss - invoke LLM
        response = await invoke_func()

        # Cache the result
        await self.set(model, query, response, config)

        return response


class RAGResultCache:
    """
    Cache for RAG (Retrieval-Augmented Generation) results.

    RAG results are relatively stable, so longer TTL is used.
    """

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize RAG result cache.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    def _generate_cache_key(self, query: str, mode: str = "hybrid") -> str:
        """
        Generate cache key for RAG query.

        Args:
            query: RAG query
            mode: Query mode (local, global, hybrid, mix)

        Returns:
            Full cache key
        """
        content = f"{mode}:{query}"
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        return KEYS.cache_rag(content_hash)

    async def get(self, query: str, mode: str = "hybrid") -> Optional[dict]:
        """
        Get cached RAG result.

        Args:
            query: RAG query
            mode: Query mode

        Returns:
            Cached result dict if found, None otherwise
        """
        key = self._generate_cache_key(query, mode)
        cached = await self.redis.get(key)

        if cached:
            logger.debug("rag_cache_hit", query_preview=query[:50])
            return json.loads(cached)

        logger.debug("rag_cache_miss", query_preview=query[:50])
        return None

    async def set(self, query: str, result: dict, mode: str = "hybrid") -> None:
        """
        Cache RAG result.

        Args:
            query: RAG query
            result: Result dict to cache
            mode: Query mode
        """
        key = self._generate_cache_key(query, mode)
        await self.redis.setex(
            key,
            RedisKeys.TTL_RAG_CACHE,
            json.dumps(result),
        )
        logger.debug("rag_cache_set", key=key, ttl=RedisKeys.TTL_RAG_CACHE)

    async def get_or_invoke(
        self,
        query: str,
        invoke_func: Callable[[], Any],
        mode: str = "hybrid",
    ) -> dict:
        """
        Get from cache or invoke RAG and cache result.

        Args:
            query: RAG query
            invoke_func: Async function to call RAG if cache miss
            mode: Query mode

        Returns:
            Cached or freshly generated result
        """
        cached = await self.get(query, mode)
        if cached:
            return cached

        result = await invoke_func()
        await self.set(query, result, mode)
        return result


class QueryClassificationCache:
    """
    Cache for query classification results.

    Classifications are very stable, so longest TTL is used.
    """

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize query classification cache.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    def _generate_cache_key(self, query: str) -> str:
        """
        Generate cache key for classification.

        Args:
            query: Query to classify

        Returns:
            Full cache key
        """
        content_hash = hashlib.sha256(query.encode()).hexdigest()[:16]
        return KEYS.cache_classify(content_hash)

    async def get(self, query: str) -> Optional[str]:
        """
        Get cached classification.

        Args:
            query: Query to look up

        Returns:
            Classification (general, code, rag, tool) if found
        """
        key = self._generate_cache_key(query)
        cached = await self.redis.get(key)

        if cached:
            logger.debug("classify_cache_hit", classification=cached)
            return cached

        return None

    async def set(self, query: str, classification: str) -> None:
        """
        Cache classification result.

        Args:
            query: Classified query
            classification: Classification result
        """
        key = self._generate_cache_key(query)
        await self.redis.setex(
            key,
            RedisKeys.TTL_CLASSIFY_CACHE,
            classification,
        )
        logger.debug(
            "classify_cache_set",
            classification=classification,
            ttl=RedisKeys.TTL_CLASSIFY_CACHE,
        )


class CacheStampedePrevention:
    """
    Prevent cache stampede using distributed locking.

    When multiple requests arrive for the same uncached key,
    only one should compute while others wait.
    """

    LOCK_TTL = 10  # seconds
    LOCK_RETRY_INTERVAL = 0.1  # seconds
    MAX_RETRIES = 50

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize stampede prevention.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    async def get_or_compute(
        self,
        cache_key: str,
        compute_func: Callable[[], Any],
        cache_ttl: int,
    ) -> Any:
        """
        Get from cache or compute with stampede prevention.

        Uses a lock to ensure only one process computes on cache miss.
        Other processes wait for the result.

        Args:
            cache_key: Full Redis cache key
            compute_func: Async function to compute value
            cache_ttl: TTL for cached value

        Returns:
            Cached or computed value
        """
        # Try cache first
        cached = await self.redis.get(cache_key)
        if cached:
            try:
                return json.loads(cached)
            except json.JSONDecodeError:
                return cached

        # Generate lock key
        lock_key = KEYS.lock_cache(
            hashlib.sha256(cache_key.encode()).hexdigest()[:8]
        )

        # Try to acquire lock
        for attempt in range(self.MAX_RETRIES):
            lock_acquired = await self.redis.set(
                lock_key,
                "1",
                nx=True,  # Only set if not exists
                ex=self.LOCK_TTL,
            )

            if lock_acquired:
                try:
                    # We got the lock - compute value
                    logger.debug("lock_acquired", cache_key=cache_key)
                    value = await compute_func()

                    # Cache result
                    cache_value = (
                        json.dumps(value)
                        if isinstance(value, (dict, list))
                        else str(value)
                    )
                    await self.redis.setex(cache_key, cache_ttl, cache_value)

                    return value
                finally:
                    # Release lock
                    await self.redis.delete(lock_key)
            else:
                # Another process has the lock - wait and retry
                await asyncio.sleep(self.LOCK_RETRY_INTERVAL)

                # Check if cache is now populated
                cached = await self.redis.get(cache_key)
                if cached:
                    try:
                        return json.loads(cached)
                    except json.JSONDecodeError:
                        return cached

        # Fallback: compute without lock (accept potential stampede)
        logger.warning(
            "cache_stampede_fallback",
            cache_key=cache_key,
            attempts=self.MAX_RETRIES,
        )
        return await compute_func()


class CacheInvalidator:
    """
    Handles cache invalidation for LangGraph state management.

    Coordinates with PostgreSQL checkpointer to invalidate
    Redis cache when state changes.
    """

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize cache invalidator.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    async def invalidate_thread_state(self, thread_id: str) -> int:
        """
        Invalidate thread state cache after checkpoint.

        Args:
            thread_id: Thread to invalidate

        Returns:
            Number of keys deleted
        """
        key = KEYS.thread_state(thread_id)
        deleted = await self.redis.delete(key)
        logger.info("cache_invalidated", key=key, deleted=deleted)
        return deleted

    async def invalidate_llm_cache(self, model: Optional[str] = None) -> int:
        """
        Invalidate LLM response cache.

        Args:
            model: Optional model to invalidate (None = all)

        Returns:
            Number of keys deleted
        """
        if model:
            pattern = f"hx-lang-server:cache:llm:{model}:*"
        else:
            pattern = "hx-lang-server:cache:llm:*"

        keys_to_delete = []
        async for key in self.redis.scan_iter(match=pattern, count=100):
            keys_to_delete.append(key)

        if keys_to_delete:
            deleted = await self.redis.delete(*keys_to_delete)
            logger.info(
                "llm_cache_invalidated",
                pattern=pattern,
                keys_deleted=deleted,
            )
            return deleted
        return 0

    async def invalidate_rag_cache(self) -> int:
        """
        Invalidate all RAG result cache.

        Returns:
            Number of keys deleted
        """
        pattern = "hx-lang-server:cache:rag:*"

        keys_to_delete = []
        async for key in self.redis.scan_iter(match=pattern, count=100):
            keys_to_delete.append(key)

        if keys_to_delete:
            deleted = await self.redis.delete(*keys_to_delete)
            logger.info("rag_cache_invalidated", keys_deleted=deleted)
            return deleted
        return 0

    async def invalidate_classification_cache(self) -> int:
        """
        Invalidate query classification cache.

        Returns:
            Number of keys deleted
        """
        pattern = "hx-lang-server:cache:classify:*"

        keys_to_delete = []
        async for key in self.redis.scan_iter(match=pattern, count=100):
            keys_to_delete.append(key)

        if keys_to_delete:
            deleted = await self.redis.delete(*keys_to_delete)
            logger.info("classify_cache_invalidated", keys_deleted=deleted)
            return deleted
        return 0


class CacheMetrics:
    """
    Cache metrics collector for monitoring.

    Tracks hit/miss rates and cache utilization.
    """

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize cache metrics.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    async def get_cache_stats(self) -> dict:
        """
        Get cache statistics from Redis INFO.

        Returns:
            Cache statistics dictionary
        """
        info = await self.redis.info("stats")

        return {
            "keyspace_hits": info.get("keyspace_hits", 0),
            "keyspace_misses": info.get("keyspace_misses", 0),
            "hit_rate": self._calculate_hit_rate(
                info.get("keyspace_hits", 0),
                info.get("keyspace_misses", 0),
            ),
        }

    @staticmethod
    def _calculate_hit_rate(hits: int, misses: int) -> float:
        """Calculate cache hit rate."""
        total = hits + misses
        if total == 0:
            return 0.0
        return hits / total

    async def count_cache_keys(self) -> dict:
        """
        Count cache keys by type.

        Returns:
            Dictionary of key counts
        """
        counts = {
            "llm_cache": 0,
            "rag_cache": 0,
            "classify_cache": 0,
        }

        patterns = {
            "llm_cache": "hx-lang-server:cache:llm:*",
            "rag_cache": "hx-lang-server:cache:rag:*",
            "classify_cache": "hx-lang-server:cache:classify:*",
        }

        for cache_type, pattern in patterns.items():
            async for _ in self.redis.scan_iter(match=pattern, count=100):
                counts[cache_type] += 1

        return counts
```

### Step 2: Add Dependency Injection

Add to `/opt/hx-lang-server/app/dependencies.py`:

```python
from app.services.cache_service import (
    LLMResponseCache,
    RAGResultCache,
    QueryClassificationCache,
    CacheStampedePrevention,
)


async def get_llm_cache(
    redis_client: redis.Redis = Depends(get_redis),
) -> LLMResponseCache:
    """Get LLM response cache dependency."""
    return LLMResponseCache(redis_client)


async def get_rag_cache(
    redis_client: redis.Redis = Depends(get_redis),
) -> RAGResultCache:
    """Get RAG result cache dependency."""
    return RAGResultCache(redis_client)


async def get_classification_cache(
    redis_client: redis.Redis = Depends(get_redis),
) -> QueryClassificationCache:
    """Get query classification cache dependency."""
    return QueryClassificationCache(redis_client)
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Cache service | `/opt/hx-lang-server/app/services/cache_service.py` | All cache implementations |
| Updated dependencies | `/opt/hx-lang-server/app/dependencies.py` | Cache dependency injection |

---

## Verification Steps

### Step 1: Verify LLM Cache Operations

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.cache_service import LLMResponseCache

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    cache = LLMResponseCache(client)

    # Test cache miss
    result = await cache.get('gemma3:27b', 'What is Python?')
    print(f'Cache miss result: {result}')
    assert result is None

    # Test cache set
    await cache.set('gemma3:27b', 'What is Python?', 'Python is a programming language.')

    # Test cache hit
    result = await cache.get('gemma3:27b', 'What is Python?')
    print(f'Cache hit result: {result}')
    assert result == 'Python is a programming language.'

    # Test cache with different config produces different key
    await cache.set('gemma3:27b', 'What is Python?', 'Different response', config={'temp': 0.5})
    result_default = await cache.get('gemma3:27b', 'What is Python?')
    result_config = await cache.get('gemma3:27b', 'What is Python?', config={'temp': 0.5})
    print(f'Default config result: {result_default}')
    print(f'Custom config result: {result_config}')
    assert result_default != result_config

    # Cleanup
    await cache.delete('gemma3:27b', 'What is Python?')
    await cache.delete('gemma3:27b', 'What is Python?', config={'temp': 0.5})
    print('SUCCESS: LLM cache tests passed')

asyncio.run(test())
"
```

### Step 2: Verify RAG Cache Operations

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.cache_service import RAGResultCache

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    cache = RAGResultCache(client)

    # Test cache operations
    test_result = {'documents': ['doc1', 'doc2'], 'scores': [0.9, 0.8]}

    # Cache miss
    result = await cache.get('test query')
    assert result is None

    # Cache set
    await cache.set('test query', test_result)

    # Cache hit
    result = await cache.get('test query')
    print(f'RAG cache result: {result}')
    assert result == test_result

    # Different mode produces different key
    await cache.set('test query', {'other': 'result'}, mode='local')
    result_hybrid = await cache.get('test query', mode='hybrid')
    result_local = await cache.get('test query', mode='local')
    assert result_hybrid != result_local

    print('SUCCESS: RAG cache tests passed')

asyncio.run(test())
"
```

### Step 3: Verify Cache Stampede Prevention

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.cache_service import CacheStampedePrevention

compute_count = 0

async def slow_compute():
    global compute_count
    compute_count += 1
    await asyncio.sleep(0.1)  # Simulate slow operation
    return f'result-{compute_count}'

async def test():
    global compute_count
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    stampede = CacheStampedePrevention(client)

    cache_key = 'hx-lang-server:cache:test:stampede'

    # Clean up any existing key
    await client.delete(cache_key)

    # Launch multiple concurrent requests
    tasks = [
        stampede.get_or_compute(cache_key, slow_compute, 300)
        for _ in range(5)
    ]

    results = await asyncio.gather(*tasks)
    print(f'Results: {results}')
    print(f'Compute called: {compute_count} times')

    # Should only compute once due to lock
    assert compute_count == 1, f'Expected 1 compute, got {compute_count}'
    # All results should be the same
    assert all(r == results[0] for r in results)

    # Cleanup
    await client.delete(cache_key)
    print('SUCCESS: Cache stampede prevention tests passed')

asyncio.run(test())
"
```

### Step 4: Verify Cache Invalidation

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.cache_service import LLMResponseCache, CacheInvalidator

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    cache = LLMResponseCache(client)
    invalidator = CacheInvalidator(client)

    # Create some cache entries
    await cache.set('gemma3:27b', 'test1', 'response1')
    await cache.set('gemma3:27b', 'test2', 'response2')
    await cache.set('qwen3-coder:30b', 'test3', 'response3')

    # Verify entries exist
    assert await cache.get('gemma3:27b', 'test1') is not None

    # Invalidate all LLM cache
    deleted = await invalidator.invalidate_llm_cache()
    print(f'Deleted {deleted} cache entries')
    assert deleted >= 3

    # Verify entries are gone
    assert await cache.get('gemma3:27b', 'test1') is None

    print('SUCCESS: Cache invalidation tests passed')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] LLMResponseCache implements get, set, delete, and get_or_invoke
- [ ] RAGResultCache implements caching with 10-minute TTL
- [ ] QueryClassificationCache implements caching with 30-minute TTL
- [ ] Semantic key generation produces deterministic keys
- [ ] Different configs produce different cache keys
- [ ] Cache stampede prevention limits concurrent computes to 1
- [ ] Cache invalidation can clear cache by type or pattern
- [ ] All cache operations use proper namespace prefix

---

## Rollback Procedure

If issues occur:

1. Remove cache_service.py
2. Revert dependencies.py changes
3. Clean up test cache keys

```bash
# Rollback commands
rm /opt/hx-lang-server/app/services/cache_service.py
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:cache:*" | xargs redis-cli -h hx-redis-server.hx.dev.local DEL
```

---

## Notes

- 5-minute LLM cache TTL balances freshness with performance
- Cache stampede prevention uses Redis SETNX for distributed locking
- Semantic key generation ensures cache hits for identical requests regardless of whitespace
- Cache invalidation uses SCAN (not KEYS) for production safety

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Redis Key Schema
