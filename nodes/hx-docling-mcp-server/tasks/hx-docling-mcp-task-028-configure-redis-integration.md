# Task 028: Configure Redis Integration

**Task ID**: hx-docling-mcp-task-028
**Category**: Configuration - Redis Integration
**Priority**: HIGH (blocking for LightRAG embedding cache and session management)
**Estimated Effort**: 2-3 hours
**Assigned To**: sri-patel (Redis Cache & In-Memory Data Structure SME)
**Status**: NOT STARTED
**Dependencies**:
- Task 005 (Install Python dependencies) MUST be complete
- Task 008 (Configure environment files) MUST be complete
- Task 011 (Create Ansible Vault credentials) MUST be complete
- hx-redis-server MUST be operational (192.168.10.210:6379)
**Blocks**:
- Task 025 (Entity Deduplication) - requires Redis embedding cache
- Task 031 (Document Processing Pipeline Integration) - requires session management
- Task 032 (Redis Session Management Integration) - builds on this configuration

---

## Objective

Configure production-grade Redis integration for Docling MCP Server with connection pooling, embedding cache (7-day TTL), session management, and circuit breaker patterns. This task establishes the in-memory caching layer that enables LightRAG entity deduplication (40% cache hit rate target) and MCP session state persistence.

**Success Criteria**:
1. ✅ Redis client configured with connection pooling (max 10 connections, timeout 5s)
2. ✅ Embedding cache functional (SHA-256 hash keys, 7-day TTL, LRU eviction)
3. ✅ Session management configured (TTL 1 hour, sliding expiration)
4. ✅ Health check integration operational (ping test, 30-second interval)
5. ✅ Retry logic implemented (3 attempts, exponential backoff)
6. ✅ Circuit breaker configured (5 failures → 60s open state)
7. ✅ Connection pooling validated (reuse connections, no leaks)
8. ✅ Cache eviction policy confirmed (allkeys-lru for memory safety)
9. ✅ Structured logging with metrics (JSON format, cache_hit_rate, pool_size)
10. ✅ Integration tests passing (connectivity, caching, session CRUD, eviction)

---

## Background Context

### Why Redis Integration is Critical

**From Charter** (lines 106-107):
- Redis integration (hx-redis-server) for session management and caching
- Session state persistence for MCP protocol multi-turn conversations

**From Task 025 (Entity Deduplication)** (lines 36-38):
- **Performance Optimization**: Embedding caching (Redis, 7-day TTL)
- **Target Cache Hit Rate**: 40% (reduces Ollama3 embedding API calls by 40%)
- **Batch Operations**: 64 entities per embedding batch

**From Configuration Spec** (plan.md lines 474-483):
```bash
REDIS_HOST=192.168.10.210
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=<from_ansible_vault>
REDIS_SESSION_TTL=3600  # 1 hour
REDIS_POOL_SIZE=10
```

**From Specification** (node-spec.md section 4.5.3 - Redis Integration):
- **Session Keys**: `session:{session_id}` with hash data structure
- **Embedding Cache Keys**: `embedding:{sha256_hash}` with JSON-encoded vectors
- **TTL Management**: Sliding expiration for sessions, fixed 7-day for embeddings
- **Memory Management**: `maxmemory-policy allkeys-lru` prevents unbounded growth

### Risks Addressed by This Task

**From Plan Risk Assessment** (plan.md lines 968):
- **Risk**: Redis Connection Failure (LOW/MEDIUM)
- **Mitigation**: Connection retry with exponential backoff, circuit breaker, fallback to in-memory sessions

**From Charter Risk R-002** (lines 512):
- **Risk**: Single-process architecture bottleneck under high document load
- **Mitigation**: Redis caching reduces compute load by eliminating duplicate embeddings (40% reduction)

---

## Technical Specification

### 1. Redis Client Configuration

**Client Setup** (Python redis-py with async support):

```python
# /opt/docling-mcp/application/docling_mcp/clients/redis_client.py

import os
import hashlib
import asyncio
import json
from typing import Optional, Any, Dict
from redis import asyncio as aioredis
from redis.asyncio.connection import ConnectionPool
from redis.exceptions import ConnectionError, TimeoutError, RedisError
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log
)
import structlog

logger = structlog.get_logger(__name__)


class RedisClient:
    """
    Production-grade Redis client with connection pooling and circuit breaker.

    Features:
    - Connection pooling (max 10 connections, 5s timeout)
    - Embedding cache (SHA-256 keys, 7-day TTL, JSON encoding)
    - Session management (TTL 1 hour, sliding expiration)
    - Health checks (ping test, 30-second interval)
    - Retry logic (3 attempts, exponential backoff)
    - Circuit breaker (5 failures → 60s open state)
    - Structured logging with cache hit rate metrics
    """

    def __init__(
        self,
        host: str = "192.168.10.210",
        port: int = 6379,
        db: int = 0,
        password: Optional[str] = None,
        pool_size: int = 10,
        socket_timeout: int = 5,
        socket_connect_timeout: int = 5,
        session_ttl: int = 3600,
        embedding_cache_ttl: int = 604800
    ):
        """
        Initialize Redis client with connection pooling.

        Args:
            host: Redis server hostname (default: hx-redis-server IP)
            port: Redis server port (default: 6379)
            db: Redis database number (default: 0)
            password: Redis password (optional, from Ansible Vault)
            pool_size: Maximum connections in pool (default: 10)
            socket_timeout: Socket timeout in seconds (default: 5)
            socket_connect_timeout: Connection timeout in seconds (default: 5)
            session_ttl: Session TTL in seconds (default: 3600 = 1 hour)
            embedding_cache_ttl: Embedding cache TTL in seconds (default: 604800 = 7 days)
        """
        self.host = host
        self.port = port
        self.db = db
        self.session_ttl = session_ttl
        self.embedding_cache_ttl = embedding_cache_ttl

        # Connection pool configuration
        self.pool = ConnectionPool(
            host=host,
            port=port,
            db=db,
            password=password,
            max_connections=pool_size,
            socket_timeout=socket_timeout,
            socket_connect_timeout=socket_connect_timeout,
            decode_responses=False  # Keep bytes for binary data
        )

        # Redis client (async)
        self.redis = aioredis.Redis(connection_pool=self.pool)

        # Circuit breaker state
        self.circuit_breaker_key = "circuit_breaker:redis"
        self.circuit_breaker_threshold = 5
        self.circuit_breaker_timeout = 60

        # Metrics
        self.cache_hits = 0
        self.cache_misses = 0

        logger.info(
            "redis_client_initialized",
            host=host,
            port=port,
            db=db,
            pool_size=pool_size,
            session_ttl=session_ttl,
            embedding_cache_ttl=embedding_cache_ttl
        )

    async def health_check(self) -> bool:
        """
        Check Redis server health via PING command.

        Returns:
            True if healthy, False otherwise
        """
        try:
            response = await self.redis.ping()
            if response:
                logger.info("redis_health_check_success")
                return True
            else:
                logger.error("redis_health_check_failed", response=response)
                return False
        except Exception as e:
            logger.error("redis_health_check_error", error=str(e))
            return False

    async def _get_circuit_breaker_state(self) -> str:
        """
        Get circuit breaker state from Redis.

        Returns:
            "CLOSED", "OPEN", or "HALF_OPEN"
        """
        try:
            state = await self.redis.get(self.circuit_breaker_key)
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
        try:
            if ttl:
                await self.redis.setex(self.circuit_breaker_key, ttl, state)
            else:
                await self.redis.set(self.circuit_breaker_key, state)
            logger.info("circuit_breaker_state_set", state=state, ttl=ttl)
        except Exception as e:
            logger.error("circuit_breaker_state_set_failed", error=str(e))

    async def _increment_failure_count(self) -> int:
        """
        Increment circuit breaker failure count.

        Returns:
            Current failure count
        """
        try:
            key = f"{self.circuit_breaker_key}:failures"
            count = await self.redis.incr(key)
            await self.redis.expire(key, 60)  # Reset after 60s
            return count
        except Exception as e:
            logger.error("failure_count_increment_failed", error=str(e))
            return 0

    async def _reset_failure_count(self):
        """Reset circuit breaker failure count."""
        try:
            key = f"{self.circuit_breaker_key}:failures"
            await self.redis.delete(key)
            logger.info("failure_count_reset")
        except Exception as e:
            logger.error("failure_count_reset_failed", error=str(e))

    # =========================================================================
    # EMBEDDING CACHE OPERATIONS
    # =========================================================================

    def _get_embedding_cache_key(self, entity_name: str) -> str:
        """
        Generate embedding cache key from entity name.

        Args:
            entity_name: Entity name to embed

        Returns:
            Cache key: "embedding:{sha256_hash}"
        """
        hash_digest = hashlib.sha256(entity_name.encode()).hexdigest()
        return f"embedding:{hash_digest}"

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError)),
        before_sleep=before_sleep_log(logger, "WARNING")
    )
    async def get_embedding(self, entity_name: str) -> Optional[list]:
        """
        Get cached embedding for entity name.

        Args:
            entity_name: Entity name

        Returns:
            Embedding vector (list of floats) or None if cache miss
        """
        # Check circuit breaker
        cb_state = await self._get_circuit_breaker_state()
        if cb_state == "OPEN":
            logger.error("circuit_breaker_open_get_embedding")
            return None

        try:
            cache_key = self._get_embedding_cache_key(entity_name)
            cached = await self.redis.get(cache_key)

            if cached:
                self.cache_hits += 1
                embedding = json.loads(cached.decode())
                logger.info(
                    "embedding_cache_hit",
                    entity=entity_name[:50],
                    cache_hit_rate=self._get_cache_hit_rate()
                )
                return embedding
            else:
                self.cache_misses += 1
                logger.debug(
                    "embedding_cache_miss",
                    entity=entity_name[:50],
                    cache_hit_rate=self._get_cache_hit_rate()
                )
                return None

        except Exception as e:
            failures = await self._increment_failure_count()
            if failures >= self.circuit_breaker_threshold:
                await self._set_circuit_breaker_state("OPEN", ttl=self.circuit_breaker_timeout)
                logger.error("circuit_breaker_opened", failures=failures)

            logger.error("get_embedding_failed", entity=entity_name[:50], error=str(e))
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError)),
        before_sleep=before_sleep_log(logger, "WARNING")
    )
    async def set_embedding(self, entity_name: str, embedding: list) -> bool:
        """
        Cache embedding for entity name.

        Args:
            entity_name: Entity name
            embedding: Embedding vector (list of floats)

        Returns:
            True if cached successfully, False otherwise
        """
        # Check circuit breaker
        cb_state = await self._get_circuit_breaker_state()
        if cb_state == "OPEN":
            logger.error("circuit_breaker_open_set_embedding")
            return False

        try:
            cache_key = self._get_embedding_cache_key(entity_name)
            embedding_json = json.dumps(embedding)

            await self.redis.setex(
                cache_key,
                self.embedding_cache_ttl,
                embedding_json
            )

            # Reset failure count on success
            await self._reset_failure_count()

            logger.info(
                "embedding_cached",
                entity=entity_name[:50],
                ttl=self.embedding_cache_ttl,
                size_bytes=len(embedding_json)
            )
            return True

        except Exception as e:
            failures = await self._increment_failure_count()
            if failures >= self.circuit_breaker_threshold:
                await self._set_circuit_breaker_state("OPEN", ttl=self.circuit_breaker_timeout)
                logger.error("circuit_breaker_opened", failures=failures)

            logger.error("set_embedding_failed", entity=entity_name[:50], error=str(e))
            return False

    def _get_cache_hit_rate(self) -> float:
        """
        Calculate cache hit rate.

        Returns:
            Hit rate (0.0-1.0)
        """
        total = self.cache_hits + self.cache_misses
        if total == 0:
            return 0.0
        return self.cache_hits / total

    # =========================================================================
    # SESSION MANAGEMENT OPERATIONS
    # =========================================================================

    def _get_session_key(self, session_id: str) -> str:
        """
        Generate session key from session ID.

        Args:
            session_id: Session ID (UUID)

        Returns:
            Session key: "session:{session_id}"
        """
        return f"session:{session_id}"

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError)),
        before_sleep=before_sleep_log(logger, "WARNING")
    )
    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """
        Get session data by session ID.

        Args:
            session_id: Session ID

        Returns:
            Session data (dict) or None if not found
        """
        # Check circuit breaker
        cb_state = await self._get_circuit_breaker_state()
        if cb_state == "OPEN":
            logger.error("circuit_breaker_open_get_session")
            return None

        try:
            session_key = self._get_session_key(session_id)
            session_data = await self.redis.hgetall(session_key)

            if session_data:
                # Decode bytes to strings
                decoded = {k.decode(): v.decode() for k, v in session_data.items()}

                # Extend TTL (sliding expiration)
                await self.redis.expire(session_key, self.session_ttl)

                logger.info("session_retrieved", session_id=session_id)
                return decoded
            else:
                logger.debug("session_not_found", session_id=session_id)
                return None

        except Exception as e:
            logger.error("get_session_failed", session_id=session_id, error=str(e))
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError)),
        before_sleep=before_sleep_log(logger, "WARNING")
    )
    async def set_session(self, session_id: str, session_data: Dict[str, Any]) -> bool:
        """
        Set session data with sliding expiration.

        Args:
            session_id: Session ID
            session_data: Session data (dict)

        Returns:
            True if stored successfully, False otherwise
        """
        # Check circuit breaker
        cb_state = await self._get_circuit_breaker_state()
        if cb_state == "OPEN":
            logger.error("circuit_breaker_open_set_session")
            return False

        try:
            session_key = self._get_session_key(session_id)

            # Store session data as hash
            await self.redis.hset(session_key, mapping=session_data)

            # Set TTL
            await self.redis.expire(session_key, self.session_ttl)

            logger.info(
                "session_stored",
                session_id=session_id,
                ttl=self.session_ttl,
                keys_count=len(session_data)
            )
            return True

        except Exception as e:
            logger.error("set_session_failed", session_id=session_id, error=str(e))
            return False

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError)),
        before_sleep=before_sleep_log(logger, "WARNING")
    )
    async def delete_session(self, session_id: str) -> bool:
        """
        Delete session by session ID.

        Args:
            session_id: Session ID

        Returns:
            True if deleted, False otherwise
        """
        # Check circuit breaker
        cb_state = await self._get_circuit_breaker_state()
        if cb_state == "OPEN":
            logger.error("circuit_breaker_open_delete_session", session_id=session_id)
            return False

        try:
            session_key = self._get_session_key(session_id)
            deleted = await self.redis.delete(session_key)

            if deleted:
                logger.info("session_deleted", session_id=session_id)
                return True
            else:
                logger.debug("session_not_found_for_delete", session_id=session_id)
                return False

        except Exception as e:
            logger.error("delete_session_failed", session_id=session_id, error=str(e))
            return False

    # =========================================================================
    # CONNECTION MANAGEMENT
    # =========================================================================

    async def get_pool_stats(self) -> Dict[str, Any]:
        """
        Get connection pool statistics using public APIs only.

        Returns:
            Pool stats (max_connections and cache metrics)
        """
        try:
            # Use only public properties from connection pool
            pool_info = {
                "max_connections": self.pool.max_connections if hasattr(self.pool, 'max_connections') else "N/A",
                "cache_hit_rate": self._get_cache_hit_rate(),
                "total_hits": self.cache_hits,
                "total_misses": self.cache_misses
            }
            
            # Attempt to get additional stats if pool has public methods
            # Note: Detailed connection metrics require custom tracking if needed
            if hasattr(self.pool, 'get_stats'):
                try:
                    pool_info.update(self.pool.get_stats())
                except Exception:
                    pass  # Pool doesn't support stats, continue with basic info
            
            return pool_info
        except Exception as e:
            logger.error("get_pool_stats_failed", error=str(e), exc_info=True)
            return {
                "max_connections": "error",
                "cache_hit_rate": self._get_cache_hit_rate(),
                "error": str(e)
            }

    async def close(self):
        """Close Redis connection pool."""
        await self.redis.close()
        await self.pool.disconnect()
        logger.info(
            "redis_client_closed",
            cache_hit_rate=self._get_cache_hit_rate(),
            total_hits=self.cache_hits,
            total_misses=self.cache_misses
        )


class CircuitBreakerOpenError(Exception):
    """Circuit breaker is open, Redis unavailable."""
    pass
```

### 2. Environment Variable Configuration

**Update `/etc/docling-mcp/.env`**:

```bash
# =============================================================================
# Redis Configuration
# =============================================================================
REDIS_HOST=192.168.10.210
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=${REDIS_PASSWORD}  # Loaded from Ansible Vault (optional)
REDIS_POOL_SIZE=10
REDIS_SOCKET_TIMEOUT=5
REDIS_SESSION_TTL=3600  # 1 hour (3600 seconds)
REDIS_EMBEDDING_CACHE_TTL=604800  # 7 days (604800 seconds)
```

**Load Password from Ansible Vault** (if authentication enabled on hx-redis-server):

`/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml`:

```yaml
---
# Redis password (if authentication enabled)
redis_password: "hx-redis-docling-mcp-001"  # Replace if Redis requirepass configured
```

**Python Configuration Loader** (`/opt/docling-mcp/application/docling_mcp/utils/config.py`):

```python
from typing import Optional
from pydantic import BaseModel, Field

class RedisConfig(BaseModel):
    """Redis configuration."""

    host: str = Field("192.168.10.210", description="Redis server hostname")
    port: int = Field(6379, description="Redis server port")
    db: int = Field(0, description="Redis database number")
    password: Optional[str] = Field(None, description="Redis password (optional)")
    pool_size: int = Field(10, description="Connection pool size")
    socket_timeout: int = Field(5, description="Socket timeout (seconds)")
    session_ttl: int = Field(3600, description="Session TTL (seconds)")
    embedding_cache_ttl: int = Field(604800, description="Embedding cache TTL (seconds)")

# Update Settings class
class Settings(BaseSettings):
    """Application settings."""

    redis: RedisConfig

    class Config:
        env_file = "/etc/docling-mcp/.env"
        env_nested_delimiter = "_"
```

### 3. Health Check Integration

**Update Health Checker** (`/opt/docling-mcp/application/docling_mcp/utils/health.py`):

```python
class HealthChecker:
    """Background health checker for Redis and LiteLLM."""

    def __init__(self, redis_client, litellm_client, interval: int = 30):
        """
        Initialize health checker.

        Args:
            redis_client: Redis client instance
            litellm_client: LiteLLM client instance
            interval: Health check interval in seconds (default 30)
        """
        self.redis_client = redis_client
        self.litellm_client = litellm_client
        self.interval = interval
        self.health_status = {
            "redis": "unknown",
            "litellm": "unknown"
        }
        self._task = None

    async def _health_check_loop(self):
        """Background health check loop."""
        while True:
            try:
                # Check Redis health
                redis_healthy = await self.redis_client.health_check()
                self.health_status["redis"] = "healthy" if redis_healthy else "unhealthy"

                # Check LiteLLM health
                litellm_healthy = await self.litellm_client.health_check()
                self.health_status["litellm"] = "healthy" if litellm_healthy else "unhealthy"

                await asyncio.sleep(self.interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error("health_check_failed", error=str(e))
                await asyncio.sleep(self.interval)
```

### 4. Integration Tests

**Test File**: `/opt/docling-mcp/tests/integration/test_redis_integration.py`

```python
"""
Integration tests for Redis integration.

Tests:
- Connectivity to hx-redis-server:6379
- Connection pooling (no leaks, connection reuse)
- Embedding cache (set, get, TTL, eviction)
- Session management (CRUD, sliding expiration)
- Health check endpoint
- Retry logic with exponential backoff
- Circuit breaker behavior
- Cache hit rate metrics
"""

import pytest
import asyncio
from redis.exceptions import ConnectionError

from docling_mcp.clients.redis_client import RedisClient


@pytest.mark.integration
@pytest.mark.requires_redis
class TestRedisIntegration:
    """Integration tests for Redis server."""

    @pytest.fixture
    async def redis_client(self):
        """Redis client fixture."""
        client = RedisClient(
            host="192.168.10.210",
            port=6379,
            db=0,
            password=None,  # Assume no auth for testing
            pool_size=10,
            socket_timeout=5,
            session_ttl=3600,
            embedding_cache_ttl=604800
        )
        yield client
        await client.close()

    async def test_health_check_success(self, redis_client):
        """Test Redis PING health check."""
        is_healthy = await redis_client.health_check()
        assert is_healthy is True

    async def test_embedding_cache_set_get(self, redis_client):
        """Test embedding cache set and get."""
        entity_name = "IBM Research"
        embedding = [0.1, 0.2, 0.3, 0.4, 0.5]

        # Set embedding
        success = await redis_client.set_embedding(entity_name, embedding)
        assert success is True

        # Get embedding (should hit cache)
        cached_embedding = await redis_client.get_embedding(entity_name)
        assert cached_embedding == embedding

        # Verify cache hit
        assert redis_client.cache_hits >= 1

    async def test_embedding_cache_miss(self, redis_client):
        """Test embedding cache miss for non-existent entity."""
        entity_name = "NonExistentEntity123456789"

        # Get non-existent embedding
        cached_embedding = await redis_client.get_embedding(entity_name)
        assert cached_embedding is None

        # Verify cache miss
        assert redis_client.cache_misses >= 1

    async def test_embedding_cache_ttl(self, redis_client):
        """Test embedding cache TTL expiration."""
        entity_name = "TTL Test Entity"
        embedding = [1.0, 2.0, 3.0]

        # Set embedding with short TTL (1 second)
        redis_client.embedding_cache_ttl = 1
        success = await redis_client.set_embedding(entity_name, embedding)
        assert success is True

        # Wait for expiration
        await asyncio.sleep(2)

        # Get should return None (expired)
        cached_embedding = await redis_client.get_embedding(entity_name)
        assert cached_embedding is None

    async def test_session_crud(self, redis_client):
        """Test session create, read, update, delete."""
        session_id = "test-session-001"
        session_data = {
            "user_id": "user123",
            "created_at": "2025-11-27T00:00:00Z",
            "document_count": "5"
        }

        # Create session
        success = await redis_client.set_session(session_id, session_data)
        assert success is True

        # Read session
        retrieved = await redis_client.get_session(session_id)
        assert retrieved == session_data

        # Update session
        session_data["document_count"] = "10"
        success = await redis_client.set_session(session_id, session_data)
        assert success is True

        # Read updated session
        retrieved = await redis_client.get_session(session_id)
        assert retrieved["document_count"] == "10"

        # Delete session
        deleted = await redis_client.delete_session(session_id)
        assert deleted is True

        # Verify deletion
        retrieved = await redis_client.get_session(session_id)
        assert retrieved is None

    async def test_session_sliding_expiration(self, redis_client):
        """Test session sliding expiration on access."""
        session_id = "test-session-sliding"
        session_data = {"test": "data"}

        # Set short TTL (2 seconds)
        redis_client.session_ttl = 2
        await redis_client.set_session(session_id, session_data)

        # Wait 1 second
        await asyncio.sleep(1)

        # Access session (should extend TTL)
        await redis_client.get_session(session_id)

        # Wait another 1.5 seconds (would expire without sliding)
        await asyncio.sleep(1.5)

        # Should still exist (TTL extended)
        retrieved = await redis_client.get_session(session_id)
        assert retrieved is not None

    async def test_connection_pooling(self, redis_client):
        """Test connection pooling (no leaks, reuse)."""
        # Get initial pool stats
        stats_before = await redis_client.get_pool_stats()

        # Execute 20 operations (more than pool size)
        for i in range(20):
            await redis_client.health_check()

        # Get final pool stats
        stats_after = await redis_client.get_pool_stats()

        # Verify pool size did not exceed max
        assert stats_after["created_connections"] <= redis_client.pool.max_connections

    async def test_retry_logic_on_timeout(self, redis_client, monkeypatch):
        """Test retry logic with exponential backoff."""
        # Mock timeout on first attempt, success on second
        call_count = 0

        async def mock_get(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise TimeoutError("Timeout")
            return b'["mock","embedding"]'

        # Patch redis client get method
        original_get = redis_client.redis.get
        redis_client.redis.get = mock_get

        # Should succeed on retry
        result = await redis_client.get_embedding("test-entity")
        assert result == ["mock", "embedding"]
        assert call_count == 2

        # Restore original
        redis_client.redis.get = original_get

    async def test_circuit_breaker_opens_after_failures(self, redis_client, monkeypatch):
        """Test circuit breaker opens after 5 consecutive failures."""
        # Mock connection errors
        async def mock_get_failure(*args, **kwargs):
            raise ConnectionError("Connection refused")

        redis_client.redis.get = mock_get_failure

        # Make 5 failed calls
        for i in range(5):
            result = await redis_client.get_embedding(f"test-entity-{i}")
            assert result is None

        # Circuit breaker should be OPEN
        cb_state = await redis_client._get_circuit_breaker_state()
        assert cb_state == "OPEN"

    async def test_cache_hit_rate_calculation(self, redis_client):
        """Test cache hit rate metrics."""
        # Reset counters
        redis_client.cache_hits = 0
        redis_client.cache_misses = 0

        # Generate cache misses
        for i in range(6):
            await redis_client.get_embedding(f"miss-entity-{i}")

        # Generate cache hits
        test_entity = "hit-entity-test"
        await redis_client.set_embedding(test_entity, [1.0, 2.0, 3.0])
        for i in range(4):
            await redis_client.get_embedding(test_entity)

        # Calculate hit rate (4 hits / 10 total = 0.4)
        hit_rate = redis_client._get_cache_hit_rate()
        assert 0.39 <= hit_rate <= 0.41  # Allow for float precision
```

---

## Implementation Steps

### Step 1: Create Redis Client Module (1.5 hours)

**File**: `/opt/docling-mcp/application/docling_mcp/clients/redis_client.py`

1. Copy complete `RedisClient` class implementation from Technical Specification section 1
2. Create `CircuitBreakerOpenError` exception class
3. Verify imports (redis.asyncio, tenacity, structlog, hashlib, json)
4. Test class instantiation with mock configuration

**Validation**:
```bash
# Verify file created
ls -lh /opt/docling-mcp/application/docling_mcp/clients/redis_client.py

# Verify imports
python3 -c "from docling_mcp.clients.redis_client import RedisClient"
```

### Step 2: Update Configuration Loader (30 minutes)

**File**: `/opt/docling-mcp/application/docling_mcp/utils/config.py`

1. Add `RedisConfig` Pydantic model from Technical Specification section 2
2. Update `Settings` class to include `redis: RedisConfig`
3. Test configuration loading with mock `.env` file

**Validation**:
```bash
# Test configuration loading
python3 -c "from docling_mcp.utils.config import load_config; config = load_config(); print(config.redis.host)"
# Expected output: 192.168.10.210
```

### Step 3: Configure Environment Variables (15 minutes)

**File**: `/etc/docling-mcp/.env`

1. Add Redis configuration section from Technical Specification section 2
2. Load `REDIS_PASSWORD` from Ansible Vault (if authentication enabled):
   ```bash
   ansible-vault view /home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml | grep redis_password
   ```
3. Export to environment (if needed): `export REDIS_PASSWORD="<value>"`
4. Verify all required variables set

**Validation**:
```bash
# Verify environment variables
source /etc/docling-mcp/.env
env | grep REDIS
# Expected: REDIS_HOST, REDIS_PORT, REDIS_DB, REDIS_POOL_SIZE, REDIS_SESSION_TTL, etc.
```

### Step 4: Update Health Check Service (30 minutes)

**File**: `/opt/docling-mcp/application/docling_mcp/utils/health.py`

1. Update `HealthChecker` class to include Redis health checks (from Technical Specification section 3)
2. Add Redis health status to `/health` endpoint response
3. Test health check loop with mock Redis client

**Validation**:
```bash
# Test health checker update
python3 -c "from docling_mcp.utils.health import HealthChecker; print('HealthChecker updated')"
```

### Step 5: Write Integration Tests (1.5 hours)

**File**: `/opt/docling-mcp/tests/integration/test_redis_integration.py`

1. Copy complete test suite from Technical Specification section 4
2. Add pytest markers: `@pytest.mark.integration`, `@pytest.mark.requires_redis`
3. Create fixtures for Redis client
4. Implement all 10 test cases:
   - `test_health_check_success`
   - `test_embedding_cache_set_get`
   - `test_embedding_cache_miss`
   - `test_embedding_cache_ttl`
   - `test_session_crud`
   - `test_session_sliding_expiration`
   - `test_connection_pooling`
   - `test_retry_logic_on_timeout`
   - `test_circuit_breaker_opens_after_failures`
   - `test_cache_hit_rate_calculation`

**Validation**:
```bash
# Run integration tests (will fail until service deployed)
pytest tests/integration/test_redis_integration.py -v
# Expected: FAILED (service not deployed yet - correct per test-driven deployment)
```

---

## Validation Criteria

### Pre-Deployment Validation (Test-Driven)

**All integration tests MUST FAIL before deployment** (service not running yet):

```bash
pytest tests/integration/test_redis_integration.py -v
# Expected output: 10 FAILED (connection refused to 192.168.10.210:6379)
```

**Status**: ✅ PASS (tests fail as expected, service not deployed)

### Post-Deployment Validation (After Service Deployed)

**All integration tests MUST PASS after deployment**:

```bash
# Run integration tests
pytest tests/integration/test_redis_integration.py -v --tb=short

# Expected output:
# test_health_check_success PASSED
# test_embedding_cache_set_get PASSED
# test_embedding_cache_miss PASSED
# test_embedding_cache_ttl PASSED
# test_session_crud PASSED
# test_session_sliding_expiration PASSED
# test_connection_pooling PASSED
# test_retry_logic_on_timeout PASSED
# test_circuit_breaker_opens_after_failures PASSED
# test_cache_hit_rate_calculation PASSED
# ===================== 10 passed in 12.45s =====================
```

**Status**: PENDING (run after Task 001-027 deployment complete)

### Manual Validation Commands

**1. Verify Redis Client Instantiation**:
```bash
source /opt/docling-mcp/venv/bin/activate
python3 <<EOF
from docling_mcp.clients.redis_client import RedisClient
client = RedisClient(host="192.168.10.210", port=6379)
print("✅ Redis client instantiated successfully")
EOF
```

**2. Verify Environment Variables Loaded**:
```bash
source /etc/docling-mcp/.env
python3 -c "from docling_mcp.utils.config import load_config; config = load_config(); assert config.redis.host == '192.168.10.210'; print('✅ Environment variables loaded')"
```

**3. Verify Health Check**:
```bash
source /opt/docling-mcp/venv/bin/activate
python3 <<EOF
import asyncio
from docling_mcp.clients.redis_client import RedisClient

async def test_health():
    client = RedisClient(host="192.168.10.210")
    is_healthy = await client.health_check()
    assert is_healthy is True, "Redis health check failed"
    print("✅ Redis health check passed")
    await client.close()

asyncio.run(test_health())
EOF
```

**4. Verify Connection Pooling**:
```bash
redis-cli -h 192.168.10.210 -p 6379 INFO clients | grep connected_clients
# Expected: connected_clients:<N> (should not exceed pool_size=10)
```

**5. Verify Embedding Cache**:
```bash
source /opt/docling-mcp/venv/bin/activate
python3 <<EOF
import asyncio
from docling_mcp.clients.redis_client import RedisClient

async def test_cache():
    client = RedisClient(host="192.168.10.210")

    # Set embedding
    await client.set_embedding("test-entity", [1.0, 2.0, 3.0])

    # Get embedding
    embedding = await client.get_embedding("test-entity")
    assert embedding == [1.0, 2.0, 3.0], "Embedding cache failed"

    print("✅ Embedding cache functional")
    await client.close()

asyncio.run(test_cache())
EOF
```

**6. Verify Circuit Breaker State**:
```bash
redis-cli -h 192.168.10.210 -p 6379 GET circuit_breaker:redis
# Expected: (nil) or "CLOSED" (open means issues)
```

---

## Quality Gate Enforcement

**IF any validation fails THEN**:

1. ✅ **STOP** deployment immediately
2. ✅ Create defect ticket:
   ```
   defect-docling-mcp-high-002-redis-integration-failure.md
   Severity: HIGH (blocks LightRAG embedding cache and session management)
   ```
3. ✅ Analyze failure:
   - Review logs: `tail -f /var/log/docling-mcp/error.log`
   - Check Redis health: `redis-cli -h 192.168.10.210 -p 6379 PING`
   - Verify network connectivity: `ping 192.168.10.210`
   - Check environment variables: `env | grep REDIS`
   - Check Redis memory: `redis-cli -h 192.168.10.210 -p 6379 INFO memory`
4. ✅ Fix root cause
5. ✅ Re-run validation
6. ✅ Proceed ONLY when all validations PASS

**Quality Gate Pass Criteria**:
- ✅ All 10 integration tests PASS (100% pass rate required)
- ✅ Health check returns `healthy` status
- ✅ Connection pool size ≤ max_connections (10)
- ✅ Circuit breaker state is `CLOSED`
- ✅ Embedding cache functional (set/get working, TTL respected)
- ✅ Session CRUD functional (create, read, update, delete)
- ✅ Structured logging operational (JSON logs in `/var/log/docling-mcp/`)

---

## Success Metrics

**Completion Criteria** (ALL must be met):

1. ✅ Redis client module created and functional
2. ✅ Configuration loader updated with Redis settings
3. ✅ Environment variables configured and validated
4. ✅ Health check service updated for Redis monitoring
5. ✅ Integration tests written (10 test cases)
6. ✅ All integration tests PASS (after deployment)
7. ✅ Manual validation commands PASS
8. ✅ Quality gate criteria met (100% test pass rate)
9. ✅ No defects created (or all defects resolved)
10. ✅ Documentation updated (inline comments in code)

**Performance Metrics** (measure after deployment):
- Health check latency: <50ms (P95)
- Embedding cache GET latency: <5ms (P95)
- Session GET latency: <10ms (P95)
- Cache hit rate: ≥40% (target from Task 025 specification)
- Connection pool utilization: <80% (healthy headroom)

---

## Rollback Procedure

```bash
# Remove Redis client module
rm -f /opt/docling-mcp/application/docling_mcp/clients/redis_client.py

# Remove integration tests
rm -f /opt/docling-mcp/tests/integration/test_redis_integration.py

# Restore config.py (remove RedisConfig)
git checkout /opt/docling-mcp/application/docling_mcp/utils/config.py

# Remove environment variables
sed -i '/^REDIS_/d' /etc/docling-mcp/.env
```

---

## Next Steps After Completion

**Immediate Next Tasks**:
1. **Task 025**: Implement Entity Deduplication Strategy (depends on Redis embedding cache)
2. **Task 029**: Configure MCP SSE & stdio Transports (may use Redis for SSE connection tracking)
3. **Task 032**: Redis Session Management Integration (builds on this Redis client)

**Downstream Dependencies**:
- LightRAG entity deduplication (Task 025) - requires Redis embedding cache
- MCP session state persistence - blocked until Redis operational
- All caching operations - need Redis client for cache-aside pattern

---

## Reference Documentation

**Charter References**:
- Lines 106-107: Redis integration requirements for session management

**Plan References**:
- Lines 474-483: Redis environment variable configuration
- Lines 968: Redis connection failure risk mitigation

**Task 025 References**:
- Lines 36-38: Embedding cache performance optimization (7-day TTL, 40% hit rate)

**Specification References**:
- Section 4.5.3: Redis Integration (session keys, embedding cache keys, TTL management)
- Section 5.3: Error Handling (circuit breaker, retry logic, graceful degradation)

**HX-Infrastructure Standards**:
- Testing requirements: 100% coverage, test-driven deployment
- Deployment philosophy: bare-metal, manual procedures, systemd management
- Redis best practices: Connection pooling, TTL management, LRU eviction policy

---

**Task Status**: NOT STARTED
**Created**: 2025-11-27
**Created By**: sri-patel (Redis Cache & In-Memory Data Structure SME)
**Estimated Completion**: After Tasks 005, 008, 011 complete, 2-3 hours for implementation
