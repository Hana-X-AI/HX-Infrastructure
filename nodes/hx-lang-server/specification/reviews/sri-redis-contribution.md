# Specification Contribution: Sri (Redis SME)

**Contribution Date:** 2025-12-01
**Spec Version:** 1.0
**Focus Areas:** Redis, caching, sessions, TTL strategy, connection pooling, cache invalidation

---

## Executive Summary

This contribution provides comprehensive Redis integration guidance for hx-lang-server, addressing the concerns raised in my charter review. The specification draft has a solid foundation but requires enhanced key schema design, explicit TTL policies, production-grade connection pooling, and cache invalidation strategies. This contribution provides production-ready configurations and code patterns for LangGraph state management with Redis.

---

## Key Schema Enhancements

### Complete Key Namespace Design

The current specification defines a basic key schema. I recommend the following enhanced namespace design with proper prefixing and hierarchical structure:

```
hx-lang:                           # Service-level namespace prefix
├── session:{session_id}           # Hash - session metadata and state
├── thread:{thread_id}:            # Thread-level namespace
│   ├── messages                   # List - message cache (recent N messages)
│   ├── state                      # String (JSON) - current agent state snapshot
│   └── meta                       # Hash - thread metadata (created, updated, user_id)
├── cache:                         # Cache namespace
│   ├── llm:{model}:{query_hash}   # String - LLM response cache
│   ├── rag:{query_hash}           # String - RAG result cache
│   ├── classify:{query_hash}      # String - query classification cache
│   └── tool:{tool_name}:{hash}    # String - MCP tool result cache
├── worker:                        # Worker-level namespace
│   ├── routing:{query_type}       # Hash - worker routing metadata
│   └── stats:{worker_name}        # Hash - worker invocation statistics
├── rate:                          # Rate limiting namespace
│   ├── user:{user_id}             # Sorted set - per-user rate limiting
│   ├── session:{session_id}       # Sorted set - per-session rate limiting
│   └── global                     # Sorted set - global rate limiting
└── lock:                          # Distributed locking namespace
    ├── checkpoint:{thread_id}     # String - checkpoint write lock
    └── cache:{key_hash}           # String - cache stampede prevention
```

### Key Naming Conventions

| Rule | Example | Rationale |
|------|---------|-----------|
| Use colons as separators | `hx-lang:session:abc123` | Standard Redis convention |
| Prefix with service name | `hx-lang:*` | Multi-tenant safety |
| Use lowercase | `hx-lang:cache:llm` | Consistency |
| Include data type hint | `session` (hash), `messages` (list) | Self-documenting |
| Use hashes for query/content | `hx-lang:cache:llm:abc123def` | Deterministic lookup |

### Key Hash Generation

```python
import hashlib

def generate_cache_key(prefix: str, content: str) -> str:
    """Generate a deterministic cache key from content."""
    content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
    return f"hx-lang:{prefix}:{content_hash}"

# Examples:
# LLM response cache: hx-lang:cache:llm:gemma3:a1b2c3d4e5f67890
# RAG result cache: hx-lang:cache:rag:f0e1d2c3b4a59876
# Classification cache: hx-lang:cache:classify:1234567890abcdef
```

---

## TTL Policy Matrix

### Complete TTL Configuration

| Key Pattern | TTL | Rationale | Eviction Behavior |
|-------------|-----|-----------|-------------------|
| `session:{session_id}` | 3600s (1 hour) | Typical agent interaction duration; prevents orphaned sessions | Expire silently |
| `thread:{thread_id}:messages` | 3600s (1 hour) | Align with session; messages in PostgreSQL checkpoints | Expire silently |
| `thread:{thread_id}:state` | 1800s (30 min) | Short-term state between PostgreSQL checkpoints | Expire silently |
| `thread:{thread_id}:meta` | 3600s (1 hour) | Align with session lifecycle | Expire silently |
| `cache:llm:{model}:{hash}` | 300s (5 min) | LLM responses may become stale; short cache | Expire silently |
| `cache:rag:{hash}` | 600s (10 min) | RAG context relatively stable; longer cache | Expire silently |
| `cache:classify:{hash}` | 1800s (30 min) | Query classification is stable | Expire silently |
| `cache:tool:{tool}:{hash}` | 180s (3 min) | Tool results may change frequently | Expire silently |
| `rate:user:{user_id}` | 60s (1 min) | Sliding window rate limiting | Auto-trim via ZREMRANGEBYSCORE |
| `rate:session:{session_id}` | 60s (1 min) | Per-session rate limiting | Auto-trim via ZREMRANGEBYSCORE |
| `lock:checkpoint:{thread_id}` | 30s | Checkpoint operation timeout | Expire as safety valve |
| `lock:cache:{hash}` | 10s | Cache stampede prevention | Expire as safety valve |

### TTL Extension Strategy

```python
class TTLManager:
    """Manages TTL extension for active sessions."""

    EXTENSION_THRESHOLD = 0.25  # Extend when 25% TTL remaining

    async def maybe_extend_ttl(self, key: str, original_ttl: int) -> bool:
        """Extend TTL if below threshold."""
        current_ttl = await self.redis.ttl(key)
        if current_ttl < original_ttl * self.EXTENSION_THRESHOLD:
            await self.redis.expire(key, original_ttl)
            return True
        return False

    async def extend_session(self, session_id: str) -> None:
        """Extend all session-related keys."""
        session_ttl = 3600  # 1 hour
        thread_ttl = 3600

        session_key = f"hx-lang:session:{session_id}"
        await self.redis.expire(session_key, session_ttl)

        # Get associated thread_id and extend thread keys
        session_data = await self.redis.hgetall(session_key)
        if thread_id := session_data.get("thread_id"):
            await self.redis.expire(f"hx-lang:thread:{thread_id}:messages", thread_ttl)
            await self.redis.expire(f"hx-lang:thread:{thread_id}:state", 1800)
            await self.redis.expire(f"hx-lang:thread:{thread_id}:meta", thread_ttl)
```

---

## Connection Pool Configuration

### Production Connection Pool Settings

```python
import redis.asyncio as redis
from redis.asyncio.connection import ConnectionPool
from redis.asyncio.retry import Retry
from redis.backoff import ExponentialBackoff

# Connection pool configuration for hx-lang-server
REDIS_POOL_CONFIG = {
    # Connection limits
    "max_connections": 50,           # Max concurrent connections

    # Timeouts
    "socket_timeout": 5.0,           # Read/write timeout (seconds)
    "socket_connect_timeout": 5.0,   # Connection establishment timeout
    "socket_keepalive": True,        # Enable TCP keepalive

    # Retry configuration
    "retry_on_timeout": True,        # Retry on timeout errors
    "retry_on_error": [              # Retry on these error types
        redis.ConnectionError,
        redis.TimeoutError,
    ],

    # Health checking
    "health_check_interval": 30,     # Seconds between health checks

    # Response decoding
    "decode_responses": True,        # Return strings instead of bytes
    "encoding": "utf-8",
}

# Retry strategy with exponential backoff
RETRY_STRATEGY = Retry(
    retries=3,
    backoff=ExponentialBackoff(
        cap=10.0,    # Maximum backoff in seconds
        base=0.5,    # Initial backoff in seconds
    ),
)

def create_redis_pool() -> ConnectionPool:
    """Create production-grade Redis connection pool."""
    return redis.ConnectionPool.from_url(
        "redis://hx-redis-server.hx.dev.local:6379/0",
        **REDIS_POOL_CONFIG,
        retry=RETRY_STRATEGY,
    )

# Global pool instance (initialize at application startup)
redis_pool: ConnectionPool | None = None

async def get_redis_client() -> redis.Redis:
    """Get Redis client from connection pool."""
    global redis_pool
    if redis_pool is None:
        redis_pool = create_redis_pool()
    return redis.Redis(connection_pool=redis_pool)
```

### Connection Pool Lifecycle Management

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage Redis pool lifecycle."""
    global redis_pool

    # Startup: Create pool
    redis_pool = create_redis_pool()

    # Verify connectivity
    client = redis.Redis(connection_pool=redis_pool)
    try:
        await client.ping()
        logger.info("redis_connection_established", host="hx-redis-server.hx.dev.local")
    except redis.ConnectionError as e:
        logger.error("redis_connection_failed", error=str(e))
        # Continue without Redis (graceful degradation)

    yield  # Application runs

    # Shutdown: Close pool
    if redis_pool:
        await redis_pool.disconnect()
        logger.info("redis_pool_closed")

app = FastAPI(lifespan=lifespan)
```

### Connection Pool Monitoring

```python
async def get_pool_stats() -> dict:
    """Get connection pool statistics for monitoring."""
    if redis_pool is None:
        return {"status": "not_initialized"}

    return {
        "max_connections": redis_pool.max_connections,
        "current_connections": len(redis_pool._in_use_connections),
        "available_connections": len(redis_pool._available_connections),
        "created_connections": redis_pool._created_connections,
    }
```

---

## Cache Invalidation Strategy

### Invalidation Triggers

| Event | Keys to Invalidate | Method |
|-------|-------------------|--------|
| Agent state mutation | `thread:{thread_id}:state` | Explicit DELETE |
| Checkpoint saved to PostgreSQL | `thread:{thread_id}:state` | Explicit DELETE |
| Session end | All `session:{session_id}` and `thread:{thread_id}:*` keys | Pattern DELETE |
| Model configuration change | All `cache:llm:*` keys | Pattern DELETE |
| RAG index update | All `cache:rag:*` keys | Pattern DELETE |
| Worker routing change | `worker:routing:*` keys | Pattern DELETE |

### Invalidation Implementation

```python
class CacheInvalidator:
    """Handles cache invalidation for LangGraph state management."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    async def invalidate_thread_state(self, thread_id: str) -> int:
        """Invalidate thread state cache after checkpoint."""
        key = f"hx-lang:thread:{thread_id}:state"
        deleted = await self.redis.delete(key)
        logger.info("cache_invalidated", key=key, deleted=deleted)
        return deleted

    async def invalidate_session(self, session_id: str) -> int:
        """Invalidate all session-related keys."""
        session_key = f"hx-lang:session:{session_id}"

        # Get thread_id before deleting session
        session_data = await self.redis.hgetall(session_key)
        thread_id = session_data.get("thread_id")

        keys_to_delete = [session_key]

        if thread_id:
            # Use SCAN to find all thread keys (safe for production)
            async for key in self.redis.scan_iter(
                match=f"hx-lang:thread:{thread_id}:*",
                count=100
            ):
                keys_to_delete.append(key)

        if keys_to_delete:
            deleted = await self.redis.delete(*keys_to_delete)
            logger.info("session_invalidated", session_id=session_id, keys_deleted=deleted)
            return deleted
        return 0

    async def invalidate_llm_cache(self, model: str | None = None) -> int:
        """Invalidate LLM response cache, optionally for specific model."""
        pattern = f"hx-lang:cache:llm:{model or '*'}:*"

        keys_to_delete = []
        async for key in self.redis.scan_iter(match=pattern, count=100):
            keys_to_delete.append(key)

        if keys_to_delete:
            deleted = await self.redis.delete(*keys_to_delete)
            logger.info("llm_cache_invalidated", pattern=pattern, keys_deleted=deleted)
            return deleted
        return 0

    async def invalidate_rag_cache(self) -> int:
        """Invalidate all RAG result cache."""
        pattern = "hx-lang:cache:rag:*"

        keys_to_delete = []
        async for key in self.redis.scan_iter(match=pattern, count=100):
            keys_to_delete.append(key)

        if keys_to_delete:
            deleted = await self.redis.delete(*keys_to_delete)
            logger.info("rag_cache_invalidated", keys_deleted=deleted)
            return deleted
        return 0
```

### Invalidation on Checkpoint

```python
from langgraph.checkpoint.base import BaseCheckpointSaver

class CacheAwareCheckpointer:
    """Wrapper that invalidates cache on checkpoint save."""

    def __init__(
        self,
        postgres_checkpointer: BaseCheckpointSaver,
        cache_invalidator: CacheInvalidator
    ):
        self.checkpointer = postgres_checkpointer
        self.invalidator = cache_invalidator

    async def aput(self, config: dict, checkpoint: dict, metadata: dict) -> dict:
        """Save checkpoint and invalidate cache."""
        # Save to PostgreSQL
        result = await self.checkpointer.aput(config, checkpoint, metadata)

        # Invalidate Redis cache for this thread
        thread_id = config.get("configurable", {}).get("thread_id")
        if thread_id:
            await self.invalidator.invalidate_thread_state(thread_id)

        return result
```

---

## Code Examples

### Complete Session Manager Implementation

```python
import json
from datetime import datetime
from typing import Optional
import redis.asyncio as redis
from pydantic import BaseModel

class SessionData(BaseModel):
    """Session data model."""
    session_id: str
    thread_id: str
    user_id: Optional[str] = None
    created_at: datetime
    last_activity: datetime
    query_count: int = 0
    metadata: dict = {}

class SessionManager:
    """Production-grade session management with Redis."""

    SESSION_TTL = 3600      # 1 hour
    MESSAGE_CACHE_SIZE = 50  # Last N messages to cache

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    async def create_session(self, session_id: str, thread_id: str, user_id: str | None = None) -> SessionData:
        """Create a new session."""
        now = datetime.utcnow()
        session = SessionData(
            session_id=session_id,
            thread_id=thread_id,
            user_id=user_id,
            created_at=now,
            last_activity=now,
        )

        session_key = f"hx-lang:session:{session_id}"

        # Use HSET for hash storage (memory efficient)
        await self.redis.hset(session_key, mapping={
            "session_id": session.session_id,
            "thread_id": session.thread_id,
            "user_id": session.user_id or "",
            "created_at": session.created_at.isoformat(),
            "last_activity": session.last_activity.isoformat(),
            "query_count": str(session.query_count),
            "metadata": json.dumps(session.metadata),
        })
        await self.redis.expire(session_key, self.SESSION_TTL)

        # Initialize thread metadata
        thread_meta_key = f"hx-lang:thread:{thread_id}:meta"
        await self.redis.hset(thread_meta_key, mapping={
            "session_id": session_id,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
        })
        await self.redis.expire(thread_meta_key, self.SESSION_TTL)

        logger.info("session_created", session_id=session_id, thread_id=thread_id)
        return session

    async def get_session(self, session_id: str) -> SessionData | None:
        """Retrieve session data."""
        session_key = f"hx-lang:session:{session_id}"
        data = await self.redis.hgetall(session_key)

        if not data:
            return None

        return SessionData(
            session_id=data["session_id"],
            thread_id=data["thread_id"],
            user_id=data["user_id"] or None,
            created_at=datetime.fromisoformat(data["created_at"]),
            last_activity=datetime.fromisoformat(data["last_activity"]),
            query_count=int(data["query_count"]),
            metadata=json.loads(data["metadata"]),
        )

    async def update_activity(self, session_id: str) -> None:
        """Update session activity and extend TTL."""
        session_key = f"hx-lang:session:{session_id}"
        now = datetime.utcnow().isoformat()

        # Update activity and increment query count atomically
        pipe = self.redis.pipeline()
        pipe.hset(session_key, "last_activity", now)
        pipe.hincrby(session_key, "query_count", 1)
        pipe.expire(session_key, self.SESSION_TTL)
        await pipe.execute()

    async def end_session(self, session_id: str) -> None:
        """End session and clean up all related keys."""
        session_key = f"hx-lang:session:{session_id}"

        # Get thread_id before deletion
        thread_id = await self.redis.hget(session_key, "thread_id")

        # Delete session and thread keys
        keys_to_delete = [session_key]
        if thread_id:
            keys_to_delete.extend([
                f"hx-lang:thread:{thread_id}:messages",
                f"hx-lang:thread:{thread_id}:state",
                f"hx-lang:thread:{thread_id}:meta",
            ])

        await self.redis.delete(*keys_to_delete)
        logger.info("session_ended", session_id=session_id, thread_id=thread_id)
```

### LLM Response Cache Implementation

```python
class LLMResponseCache:
    """Cache for LLM responses with semantic key generation."""

    CACHE_TTL = 300  # 5 minutes

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    def _generate_cache_key(self, model: str, query: str, config: dict) -> str:
        """Generate deterministic cache key."""
        # Include model, query, and relevant config in hash
        content = f"{model}:{query}:{json.dumps(config, sort_keys=True)}"
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        return f"hx-lang:cache:llm:{model}:{content_hash}"

    async def get(self, model: str, query: str, config: dict = {}) -> str | None:
        """Get cached LLM response."""
        key = self._generate_cache_key(model, query, config)
        cached = await self.redis.get(key)

        if cached:
            logger.debug("cache_hit", key=key)
            return cached

        logger.debug("cache_miss", key=key)
        return None

    async def set(self, model: str, query: str, response: str, config: dict = {}) -> None:
        """Cache LLM response."""
        key = self._generate_cache_key(model, query, config)
        await self.redis.setex(key, self.CACHE_TTL, response)
        logger.debug("cache_set", key=key, ttl=self.CACHE_TTL)

    async def get_or_invoke(
        self,
        model: str,
        query: str,
        invoke_func,
        config: dict = {},
    ) -> str:
        """Get from cache or invoke LLM and cache result."""
        cached = await self.get(model, query, config)
        if cached:
            return cached

        # Invoke LLM
        response = await invoke_func(query, config)

        # Cache result
        await self.set(model, query, response, config)

        return response
```

### Rate Limiting Implementation

```python
import time

class RateLimiter:
    """Sliding window rate limiting with Redis sorted sets."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    async def is_allowed(
        self,
        identifier: str,
        limit: int,
        window_seconds: int = 60,
        scope: str = "user"
    ) -> tuple[bool, int]:
        """
        Check if request is allowed under rate limit.

        Returns:
            (is_allowed, remaining_requests)
        """
        key = f"hx-lang:rate:{scope}:{identifier}"
        now = time.time()
        window_start = now - window_seconds

        # Atomic rate limit check using pipeline
        pipe = self.redis.pipeline()

        # Remove old entries outside window
        pipe.zremrangebyscore(key, "-inf", window_start)

        # Count current entries
        pipe.zcard(key)

        # Add current request (will be rolled back if over limit)
        pipe.zadd(key, {str(now): now})

        # Set TTL
        pipe.expire(key, window_seconds)

        results = await pipe.execute()
        current_count = results[1]

        if current_count >= limit:
            # Over limit - remove the request we just added
            await self.redis.zrem(key, str(now))
            remaining = 0
            allowed = False
        else:
            remaining = limit - current_count - 1
            allowed = True

        logger.debug(
            "rate_limit_check",
            identifier=identifier,
            scope=scope,
            allowed=allowed,
            remaining=remaining,
        )

        return allowed, remaining

    async def get_remaining(self, identifier: str, limit: int, window_seconds: int = 60, scope: str = "user") -> int:
        """Get remaining requests in current window."""
        key = f"hx-lang:rate:{scope}:{identifier}"
        now = time.time()
        window_start = now - window_seconds

        # Remove old entries and count
        await self.redis.zremrangebyscore(key, "-inf", window_start)
        current_count = await self.redis.zcard(key)

        return max(0, limit - current_count)
```

### Graceful Degradation Implementation

```python
from enum import Enum
from typing import Callable, TypeVar

T = TypeVar("T")

class RedisStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNAVAILABLE = "unavailable"

class GracefulRedisClient:
    """Redis client with graceful degradation when unavailable."""

    def __init__(self, redis_client: redis.Redis):
        self._redis = redis_client
        self._status = RedisStatus.HEALTHY
        self._consecutive_failures = 0
        self._failure_threshold = 3

    @property
    def status(self) -> RedisStatus:
        return self._status

    async def _check_health(self) -> bool:
        """Check Redis connectivity."""
        try:
            await self._redis.ping()
            self._consecutive_failures = 0
            self._status = RedisStatus.HEALTHY
            return True
        except (redis.ConnectionError, redis.TimeoutError):
            self._consecutive_failures += 1
            if self._consecutive_failures >= self._failure_threshold:
                self._status = RedisStatus.UNAVAILABLE
            else:
                self._status = RedisStatus.DEGRADED
            return False

    async def execute_with_fallback(
        self,
        redis_operation: Callable[[], T],
        fallback_value: T,
        operation_name: str = "unknown",
    ) -> T:
        """
        Execute Redis operation with fallback on failure.

        If Redis is unavailable, returns fallback value and logs warning.
        """
        if self._status == RedisStatus.UNAVAILABLE:
            # Skip Redis entirely when known unavailable
            logger.warning(
                "redis_skipped",
                operation=operation_name,
                reason="redis_unavailable",
            )
            return fallback_value

        try:
            result = await redis_operation()
            self._consecutive_failures = 0
            self._status = RedisStatus.HEALTHY
            return result
        except (redis.ConnectionError, redis.TimeoutError) as e:
            self._consecutive_failures += 1

            if self._consecutive_failures >= self._failure_threshold:
                self._status = RedisStatus.UNAVAILABLE
                logger.error(
                    "redis_unavailable",
                    consecutive_failures=self._consecutive_failures,
                    error=str(e),
                )
            else:
                self._status = RedisStatus.DEGRADED
                logger.warning(
                    "redis_operation_failed",
                    operation=operation_name,
                    error=str(e),
                    will_retry=True,
                )

            return fallback_value

# Usage example
graceful_redis = GracefulRedisClient(redis_client)

# Session lookup with fallback
session = await graceful_redis.execute_with_fallback(
    lambda: session_manager.get_session(session_id),
    fallback_value=None,
    operation_name="get_session",
)

# If session is None due to Redis unavailability, create fresh session
# or retrieve from PostgreSQL checkpoint
```

### Cache Stampede Prevention

```python
class CacheStampedePrevention:
    """Prevent cache stampede using distributed locking."""

    LOCK_TTL = 10  # seconds
    LOCK_RETRY_INTERVAL = 0.1  # seconds
    MAX_RETRIES = 50

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    async def get_or_compute(
        self,
        cache_key: str,
        compute_func,
        cache_ttl: int,
    ):
        """
        Get from cache or compute with stampede prevention.

        Uses a lock to ensure only one process computes on cache miss.
        """
        # Try cache first
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)

        # Generate lock key
        lock_key = f"hx-lang:lock:cache:{hashlib.sha256(cache_key.encode()).hexdigest()[:8]}"

        # Try to acquire lock
        for _ in range(self.MAX_RETRIES):
            lock_acquired = await self.redis.set(
                lock_key,
                "1",
                nx=True,  # Only set if not exists
                ex=self.LOCK_TTL,
            )

            if lock_acquired:
                try:
                    # Compute value
                    value = await compute_func()

                    # Cache result
                    await self.redis.setex(cache_key, cache_ttl, json.dumps(value))

                    return value
                finally:
                    # Release lock
                    await self.redis.delete(lock_key)
            else:
                # Wait and retry (another process is computing)
                await asyncio.sleep(self.LOCK_RETRY_INTERVAL)

                # Check if cache is now populated
                cached = await self.redis.get(cache_key)
                if cached:
                    return json.loads(cached)

        # Fallback: compute without lock (stampede accepted)
        logger.warning("cache_stampede_fallback", cache_key=cache_key)
        return await compute_func()
```

---

## Spec Validation

### Confirmed Items (Correct in Current Spec)

1. **Redis Key Schema (Lines 256-265)**: Basic structure is correct. My contribution enhances with hierarchical namespacing.

2. **Connection Configuration (Lines 375-387)**: Async redis-py usage is correct. My contribution adds production pool settings.

3. **Session Management (Lines 393-412)**: Basic pattern is correct. My contribution adds TTL extension and activity tracking.

4. **FR-007**: "Service MUST cache session data in Redis with configurable TTL" - Correct requirement, needs implementation detail.

### Items Requiring Correction

1. **max_connections setting (Line 380)**:
   - Current: `max_connections=20`
   - Recommended: `max_connections=50`
   - Rationale: With 10 concurrent agent sessions and multiple operations per request, 20 connections may cause starvation under load.

2. **Missing health_check_interval**:
   - Current: Not specified
   - Recommended: Add `health_check_interval=30`
   - Rationale: Detect and remove dead connections from pool.

3. **Missing retry configuration**:
   - Current: Only `retry_on_timeout=True`
   - Recommended: Add full retry strategy with exponential backoff
   - Rationale: Network transients should not fail requests immediately.

4. **TTL values inconsistency (Lines 214-215 vs 262-264)**:
   - Architecture diagram shows: "TTL: 1 hour (sessions), TTL: 5 min (LLM cache)"
   - Key schema shows: "1 hour" for session but mixed values for cache
   - Recommended: Consolidate to single TTL matrix (see my contribution above)

5. **Missing graceful degradation strategy**:
   - Current: Not specified
   - Recommended: Add explicit fallback behavior when Redis unavailable
   - Rationale: My charter review identified this as HIGH severity concern

6. **Missing cache invalidation triggers**:
   - Current: Not specified
   - Recommended: Add invalidation strategy (see my contribution above)
   - Rationale: LangGraph state mutations require coordinated invalidation

---

## Recommended Changes to node-spec.md

### Section: Redis Integration (Lines 371-413)

Replace current section with:

```markdown
## Redis Integration

### Connection Configuration

```python
import redis.asyncio as redis
from redis.asyncio.retry import Retry
from redis.backoff import ExponentialBackoff

REDIS_CONFIG = {
    "max_connections": 50,
    "socket_timeout": 5.0,
    "socket_connect_timeout": 5.0,
    "socket_keepalive": True,
    "retry_on_timeout": True,
    "health_check_interval": 30,
    "decode_responses": True,
}

RETRY_STRATEGY = Retry(
    retries=3,
    backoff=ExponentialBackoff(cap=10.0, base=0.5),
)

redis_pool = redis.ConnectionPool.from_url(
    "redis://hx-redis-server.hx.dev.local:6379/0",
    **REDIS_CONFIG,
    retry=RETRY_STRATEGY,
)
```

### Session Management

```python
class SessionManager:
    """Manages ephemeral session state in Redis."""

    SESSION_TTL = 3600   # 1 hour
    STATE_TTL = 1800     # 30 minutes
    CACHE_TTL = 300      # 5 minutes

    async def create_session(self, session_id: str, thread_id: str) -> None:
        await self.redis.hset(
            f"hx-lang:session:{session_id}",
            mapping={"thread_id": thread_id, "created_at": datetime.utcnow().isoformat()}
        )
        await self.redis.expire(f"hx-lang:session:{session_id}", self.SESSION_TTL)

    async def get_session(self, session_id: str) -> Optional[dict]:
        return await self.redis.hgetall(f"hx-lang:session:{session_id}")

    async def extend_session(self, session_id: str) -> None:
        await self.redis.expire(f"hx-lang:session:{session_id}", self.SESSION_TTL)
```

### Graceful Degradation

When Redis is unavailable:
- Session cache lookups return None (fall through to PostgreSQL checkpoint)
- LLM response cache misses proceed to Ollama invocation
- Rate limiting disabled (log warning, allow all requests)
- Service continues in degraded mode with warning logs
- Health endpoint reports status as "degraded" with Redis unavailability noted
```

### Section: Redis Key Schema (Lines 256-265)

Replace current table with:

```markdown
### Redis Key Schema

| Key Pattern | Type | Purpose | TTL |
|-------------|------|---------|-----|
| `hx-lang:session:{session_id}` | Hash | Session metadata | 1 hour |
| `hx-lang:thread:{thread_id}:messages` | List | Message cache (last 50) | 1 hour |
| `hx-lang:thread:{thread_id}:state` | String | Ephemeral agent state (JSON) | 30 min |
| `hx-lang:thread:{thread_id}:meta` | Hash | Thread metadata | 1 hour |
| `hx-lang:cache:llm:{model}:{hash}` | String | LLM response cache | 5 min |
| `hx-lang:cache:rag:{hash}` | String | RAG result cache | 10 min |
| `hx-lang:cache:classify:{hash}` | String | Query classification cache | 30 min |
| `hx-lang:rate:user:{user_id}` | Sorted Set | Per-user rate limiting | 1 min |
| `hx-lang:lock:checkpoint:{thread_id}` | String | Checkpoint write lock | 30 sec |

All keys use `hx-lang:` prefix for namespace isolation. Hash-based keys use SHA256 truncated to 16 characters.
```

### Add New Section: Cache Invalidation Strategy

Add after Redis Integration section:

```markdown
### Cache Invalidation Strategy

| Event | Keys Invalidated | Method |
|-------|------------------|--------|
| PostgreSQL checkpoint saved | `hx-lang:thread:{thread_id}:state` | Explicit DELETE after checkpoint |
| Session ended | All `hx-lang:session:{session_id}` and `hx-lang:thread:{thread_id}:*` | Pattern DELETE via SCAN |
| Model configuration changed | `hx-lang:cache:llm:{model}:*` | Pattern DELETE via SCAN |
| RAG index updated | `hx-lang:cache:rag:*` | Pattern DELETE via SCAN |

**Critical:** Cache invalidation for thread state MUST occur immediately after PostgreSQL checkpoint save to prevent stale state reads.
```

---

## Additional Recommendations

### 1. Redis Database Selection

The specification uses database 0 (`redis://...6379/0`). I recommend continuing with database 0 but ensuring all keys use the `hx-lang:` prefix. This provides:
- Operational simplicity (no database switching)
- Clear key isolation via naming convention
- Compatibility with Redis Cluster (if future scaling needed)

### 2. Memory Budget Estimation

For 10 concurrent sessions with typical agent workloads:

| Data Type | Count | Avg Size | Total |
|-----------|-------|----------|-------|
| Session hashes | 10 | 500 bytes | 5 KB |
| Thread state | 10 | 2 KB | 20 KB |
| Message cache | 10 x 50 | 1 KB/msg | 500 KB |
| LLM cache | 100 | 5 KB | 500 KB |
| RAG cache | 50 | 10 KB | 500 KB |
| Rate limiting | 100 | 100 bytes | 10 KB |
| **Total** | | | **~1.5 MB** |

This is minimal; hx-redis-server has ample capacity. No special memory allocation needed for hx-lang-server workload.

### 3. Monitoring Integration

Add to health check response:

```python
async def check_redis() -> dict:
    """Check Redis connectivity and metrics."""
    try:
        info = await redis_client.info("memory", "stats", "clients")
        return {
            "status": "healthy",
            "connected_clients": info.get("connected_clients", 0),
            "used_memory_human": info.get("used_memory_human", "unknown"),
            "keyspace_hits": info.get("keyspace_hits", 0),
            "keyspace_misses": info.get("keyspace_misses", 0),
        }
    except redis.ConnectionError:
        return {"status": "unavailable", "error": "connection_failed"}
```

### 4. Success Criteria Addition

Add Redis-specific success criterion:

**SC-XXX**: Redis cache hit ratio > 80% for session and LLM response lookups after 1-hour warm-up period.

---

**Signature:** Sri
**Date:** 2025-12-01
