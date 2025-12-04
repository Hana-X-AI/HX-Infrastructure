# Task: Implement Graceful Degradation

**Task ID**: hx-lang-server-task-047-implement-graceful-degradation
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-041 (Redis connection pool), hx-lang-server-task-042 (SessionManager)
**Estimated Time**: 45 minutes

---

## Objective

Implement graceful degradation patterns for Redis operations in hx-lang-server. When Redis is unavailable, the service should continue operating in a degraded mode rather than failing completely. This ensures high availability by falling back to PostgreSQL checkpoints for state and disabling optional features like caching and rate limiting.

---

## Prerequisites

- [ ] Redis connection pool configured (task-041)
- [ ] SessionManager implemented (task-042)
- [ ] Understanding of fallback behavior from specification

---

## Specification Reference

**From node-spec.md v2.1, Section: Operational Requirements (Lines 56-59):**

> - Service Failure: Supervisor agent gracefully degrades; in-progress work checkpointed to PostgreSQL; Redis cache cleared on restart
> - Network Interruption: Retry logic with exponential backoff for Ollama/LightRAG connections; circuit breaker prevents cascade failures

**From Sri Patel's Redis contribution - Graceful Degradation Implementation:**

> When Redis is unavailable:
> - Session cache lookups return None (fall through to PostgreSQL checkpoint)
> - LLM response cache misses proceed to Ollama invocation
> - Rate limiting disabled (log warning, allow all requests)
> - Service continues in degraded mode with warning logs
> - Health endpoint reports status as "degraded" with Redis unavailability noted

---

## Implementation Steps

### Step 1: Create Graceful Redis Client

Create file: `/opt/hx-lang-server/app/services/graceful_redis.py`

```python
"""
Graceful degradation wrapper for Redis operations.

Provides fallback behavior when Redis is unavailable, allowing
the service to continue operating in degraded mode.
"""

import asyncio
from enum import Enum
from typing import TypeVar, Callable, Optional, Any
import redis.asyncio as redis
import structlog

logger = structlog.get_logger(__name__)

T = TypeVar("T")


class RedisStatus(Enum):
    """Redis connection status levels."""

    HEALTHY = "healthy"           # Normal operation
    DEGRADED = "degraded"         # Some failures, retrying
    UNAVAILABLE = "unavailable"   # Persistent failures, fallback mode


class CircuitState(Enum):
    """Circuit breaker states."""

    CLOSED = "closed"       # Normal operation, allow requests
    OPEN = "open"           # Failure detected, reject requests
    HALF_OPEN = "half_open" # Testing if service recovered


class CircuitBreaker:
    """
    Circuit breaker pattern implementation.

    Prevents cascade failures by stopping requests to
    a failing service after threshold failures.
    """

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 30.0,
        half_open_max_calls: int = 3,
    ):
        """
        Initialize circuit breaker.

        Args:
            failure_threshold: Failures before opening circuit
            recovery_timeout: Seconds before trying half-open
            half_open_max_calls: Test calls in half-open state
        """
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.half_open_max_calls = half_open_max_calls

        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._last_failure_time: Optional[float] = None
        self._half_open_calls = 0

    @property
    def state(self) -> CircuitState:
        """Get current circuit state."""
        return self._state

    @property
    def is_open(self) -> bool:
        """Check if circuit is open (blocking requests)."""
        if self._state == CircuitState.OPEN:
            # Check if we should transition to half-open
            if self._last_failure_time:
                import time
                if time.time() - self._last_failure_time >= self.recovery_timeout:
                    self._transition_to_half_open()
                    return False
            return True
        return False

    def record_success(self) -> None:
        """Record successful operation."""
        if self._state == CircuitState.HALF_OPEN:
            self._half_open_calls += 1
            if self._half_open_calls >= self.half_open_max_calls:
                self._transition_to_closed()
        elif self._state == CircuitState.CLOSED:
            self._failure_count = 0

    def record_failure(self) -> None:
        """Record failed operation."""
        import time
        self._last_failure_time = time.time()

        if self._state == CircuitState.HALF_OPEN:
            self._transition_to_open()
        elif self._state == CircuitState.CLOSED:
            self._failure_count += 1
            if self._failure_count >= self.failure_threshold:
                self._transition_to_open()

    def _transition_to_open(self) -> None:
        """Transition to open state."""
        self._state = CircuitState.OPEN
        logger.warning(
            "circuit_breaker_opened",
            failure_count=self._failure_count,
        )

    def _transition_to_half_open(self) -> None:
        """Transition to half-open state."""
        self._state = CircuitState.HALF_OPEN
        self._half_open_calls = 0
        logger.info("circuit_breaker_half_open")

    def _transition_to_closed(self) -> None:
        """Transition to closed state."""
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._half_open_calls = 0
        logger.info("circuit_breaker_closed")


class GracefulRedisClient:
    """
    Redis client wrapper with graceful degradation.

    Provides fallback behavior when Redis is unavailable,
    logging warnings and returning safe defaults.
    """

    def __init__(
        self,
        redis_client: redis.Redis,
        failure_threshold: int = 3,
    ):
        """
        Initialize graceful Redis client.

        Args:
            redis_client: Underlying Redis client
            failure_threshold: Failures before marking unavailable
        """
        self._redis = redis_client
        self._status = RedisStatus.HEALTHY
        self._consecutive_failures = 0
        self._failure_threshold = failure_threshold
        self._circuit_breaker = CircuitBreaker(failure_threshold=5)

    @property
    def status(self) -> RedisStatus:
        """Get current Redis status."""
        return self._status

    @property
    def is_available(self) -> bool:
        """Check if Redis is available for operations."""
        return self._status != RedisStatus.UNAVAILABLE

    async def health_check(self) -> dict:
        """
        Perform health check on Redis connection.

        Returns:
            Health status dictionary
        """
        try:
            await self._redis.ping()
            self._consecutive_failures = 0
            self._status = RedisStatus.HEALTHY
            self._circuit_breaker.record_success()

            return {
                "status": "healthy",
                "circuit_state": self._circuit_breaker.state.value,
            }
        except (redis.ConnectionError, redis.TimeoutError) as e:
            self._handle_failure(e)
            return {
                "status": self._status.value,
                "error": str(e),
                "circuit_state": self._circuit_breaker.state.value,
            }

    def _handle_failure(self, error: Exception) -> None:
        """Handle Redis operation failure."""
        self._consecutive_failures += 1
        self._circuit_breaker.record_failure()

        if self._consecutive_failures >= self._failure_threshold:
            self._status = RedisStatus.UNAVAILABLE
            logger.error(
                "redis_unavailable",
                consecutive_failures=self._consecutive_failures,
                error=str(error),
            )
        else:
            self._status = RedisStatus.DEGRADED
            logger.warning(
                "redis_degraded",
                consecutive_failures=self._consecutive_failures,
                error=str(error),
            )

    def _handle_success(self) -> None:
        """Handle successful Redis operation."""
        self._consecutive_failures = 0
        self._status = RedisStatus.HEALTHY
        self._circuit_breaker.record_success()

    async def execute_with_fallback(
        self,
        redis_operation: Callable[[], T],
        fallback_value: T,
        operation_name: str = "unknown",
        log_fallback: bool = True,
    ) -> T:
        """
        Execute Redis operation with fallback on failure.

        This is the primary method for graceful degradation.
        Returns fallback value if Redis is unavailable.

        Args:
            redis_operation: Async function performing Redis operation
            fallback_value: Value to return on failure
            operation_name: Name for logging
            log_fallback: Whether to log fallback usage

        Returns:
            Operation result or fallback value
        """
        # Check circuit breaker
        if self._circuit_breaker.is_open:
            if log_fallback:
                logger.warning(
                    "redis_circuit_open",
                    operation=operation_name,
                )
            return fallback_value

        # Skip if known unavailable
        if self._status == RedisStatus.UNAVAILABLE:
            if log_fallback:
                logger.warning(
                    "redis_skipped",
                    operation=operation_name,
                    reason="unavailable",
                )
            return fallback_value

        try:
            result = await redis_operation()
            self._handle_success()
            return result
        except (redis.ConnectionError, redis.TimeoutError) as e:
            self._handle_failure(e)
            if log_fallback:
                logger.warning(
                    "redis_fallback",
                    operation=operation_name,
                    error=str(e),
                    fallback_type=type(fallback_value).__name__,
                )
            return fallback_value

    async def execute_optional(
        self,
        redis_operation: Callable[[], Any],
        operation_name: str = "unknown",
    ) -> bool:
        """
        Execute optional Redis operation (fire-and-forget).

        Used for operations where failure is acceptable,
        like cache updates.

        Args:
            redis_operation: Async function to execute
            operation_name: Name for logging

        Returns:
            True if operation succeeded
        """
        if not self.is_available or self._circuit_breaker.is_open:
            return False

        try:
            await redis_operation()
            self._handle_success()
            return True
        except (redis.ConnectionError, redis.TimeoutError) as e:
            self._handle_failure(e)
            logger.debug(
                "redis_optional_failed",
                operation=operation_name,
                error=str(e),
            )
            return False


class GracefulSessionManager:
    """
    Session manager with graceful degradation.

    Falls back to PostgreSQL checkpoint data when Redis unavailable.
    """

    def __init__(
        self,
        graceful_redis: GracefulRedisClient,
        session_manager,  # Type hint avoided for circular import
    ):
        """
        Initialize graceful session manager.

        Args:
            graceful_redis: Graceful Redis client
            session_manager: Underlying SessionManager
        """
        self.graceful = graceful_redis
        self.session_manager = session_manager

    async def get_session(
        self,
        session_id: str,
        checkpoint_fallback: Callable[[], Any] = None,
    ):
        """
        Get session with fallback to checkpoint.

        Args:
            session_id: Session to retrieve
            checkpoint_fallback: Function to load from PostgreSQL

        Returns:
            Session data or None
        """
        session = await self.graceful.execute_with_fallback(
            lambda: self.session_manager.get_session(session_id),
            fallback_value=None,
            operation_name="get_session",
        )

        if session is None and checkpoint_fallback:
            logger.info(
                "session_fallback_to_checkpoint",
                session_id=session_id,
            )
            return await checkpoint_fallback()

        return session

    async def create_session(self, *args, **kwargs):
        """Create session (skip if Redis unavailable)."""
        return await self.graceful.execute_with_fallback(
            lambda: self.session_manager.create_session(*args, **kwargs),
            fallback_value=None,
            operation_name="create_session",
        )

    async def update_activity(self, session_id: str) -> bool:
        """Update activity (optional, may fail silently)."""
        return await self.graceful.execute_optional(
            lambda: self.session_manager.update_activity(session_id),
            operation_name="update_activity",
        )


class GracefulRateLimiter:
    """
    Rate limiter with graceful degradation.

    Allows all requests when Redis unavailable (logs warning).
    """

    def __init__(
        self,
        graceful_redis: GracefulRedisClient,
        rate_limiter,  # Type hint avoided for circular import
    ):
        """
        Initialize graceful rate limiter.

        Args:
            graceful_redis: Graceful Redis client
            rate_limiter: Underlying RateLimiter
        """
        self.graceful = graceful_redis
        self.rate_limiter = rate_limiter
        self._degraded_warning_logged = False

    async def is_allowed(
        self,
        identifier: str,
        limit: int = 100,
        window_seconds: int = 60,
        scope: str = "user",
    ) -> tuple[bool, int]:
        """
        Check rate limit with fallback to allow all.

        When Redis unavailable, allows all requests (degraded mode).

        Args:
            identifier: Rate limit identifier
            limit: Request limit
            window_seconds: Window size
            scope: Rate limit scope

        Returns:
            Tuple of (is_allowed, remaining)
        """
        result = await self.graceful.execute_with_fallback(
            lambda: self.rate_limiter.is_allowed(
                identifier, limit, window_seconds, scope
            ),
            fallback_value=(True, limit),  # Allow all in degraded mode
            operation_name="rate_limit_check",
            log_fallback=not self._degraded_warning_logged,
        )

        # Log degraded mode warning once
        if not self.graceful.is_available and not self._degraded_warning_logged:
            logger.warning(
                "rate_limiting_disabled",
                reason="redis_unavailable",
            )
            self._degraded_warning_logged = True

        return result


class GracefulCacheService:
    """
    Cache service with graceful degradation.

    Always calls backend on cache miss when Redis unavailable.
    """

    def __init__(
        self,
        graceful_redis: GracefulRedisClient,
        cache_service,  # LLM or RAG cache
    ):
        """
        Initialize graceful cache service.

        Args:
            graceful_redis: Graceful Redis client
            cache_service: Underlying cache service
        """
        self.graceful = graceful_redis
        self.cache = cache_service

    async def get(self, *args, **kwargs):
        """Get from cache (return None if Redis unavailable)."""
        return await self.graceful.execute_with_fallback(
            lambda: self.cache.get(*args, **kwargs),
            fallback_value=None,
            operation_name="cache_get",
            log_fallback=False,  # Don't log every cache miss
        )

    async def set(self, *args, **kwargs) -> bool:
        """Set cache (skip if Redis unavailable)."""
        return await self.graceful.execute_optional(
            lambda: self.cache.set(*args, **kwargs),
            operation_name="cache_set",
        )

    async def get_or_invoke(
        self,
        invoke_func: Callable,
        *args,
        **kwargs,
    ):
        """
        Get from cache or invoke with graceful handling.

        When Redis unavailable, always invokes the function.
        """
        # Try cache first
        cached = await self.get(*args, **kwargs)
        if cached is not None:
            return cached

        # Invoke function
        result = await invoke_func()

        # Try to cache (may fail silently)
        await self.set(*args, result, **kwargs)

        return result
```

### Step 2: Create Health Check Integration

Add to `/opt/hx-lang-server/app/api/health.py`:

```python
"""
Health check endpoints with Redis status.
"""

from fastapi import APIRouter, Depends
from app.services.graceful_redis import GracefulRedisClient, RedisStatus

router = APIRouter()


@router.get("/health")
async def health_check(
    graceful_redis: GracefulRedisClient = Depends(get_graceful_redis),
):
    """
    Health check including Redis status.

    Returns degraded status if Redis unavailable.
    """
    redis_health = await graceful_redis.health_check()

    overall_status = "healthy"
    if redis_health["status"] != "healthy":
        overall_status = "degraded"

    return {
        "status": overall_status,
        "dependencies": {
            "redis": redis_health,
            # ... other dependencies
        },
    }
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Graceful Redis module | `/opt/hx-lang-server/app/services/graceful_redis.py` | Degradation implementation |
| Health endpoint updates | `/opt/hx-lang-server/app/api/health.py` | Redis status reporting |

---

## Verification Steps

### Step 1: Verify Circuit Breaker

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
from app.services.graceful_redis import CircuitBreaker, CircuitState

# Test circuit breaker behavior
cb = CircuitBreaker(failure_threshold=3)

print(f'Initial state: {cb.state}')
assert cb.state == CircuitState.CLOSED

# Record failures
for i in range(3):
    cb.record_failure()
    print(f'After failure {i+1}: {cb.state}')

# Should be open after threshold
assert cb.state == CircuitState.OPEN
print('SUCCESS: Circuit breaker opens after threshold')
"
```

### Step 2: Verify Graceful Fallback

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.graceful_redis import GracefulRedisClient, RedisStatus

async def test():
    # Create client with invalid URL to simulate unavailability
    client = redis.from_url('redis://invalid-host:6379/0', decode_responses=True)
    graceful = GracefulRedisClient(client, failure_threshold=2)

    # Test fallback behavior
    result = await graceful.execute_with_fallback(
        lambda: client.get('test-key'),
        fallback_value='fallback-result',
        operation_name='test_get',
    )

    print(f'Result: {result}')
    print(f'Status: {graceful.status}')

    assert result == 'fallback-result'
    # Status should be degraded after first failure
    assert graceful.status in [RedisStatus.DEGRADED, RedisStatus.UNAVAILABLE]

    print('SUCCESS: Graceful fallback works')

asyncio.run(test())
"
```

### Step 3: Verify Optional Operations Skip

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.graceful_redis import GracefulRedisClient

async def test():
    # Valid client
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    graceful = GracefulRedisClient(client)

    # Test optional operation
    success = await graceful.execute_optional(
        lambda: client.set('test-optional', 'value', ex=60),
        operation_name='test_set',
    )

    print(f'Optional operation success: {success}')
    assert success == True

    # Cleanup
    await client.delete('test-optional')
    print('SUCCESS: Optional operations work')

asyncio.run(test())
"
```

### Step 4: Verify Health Check Reports Degraded

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.graceful_redis import GracefulRedisClient, RedisStatus

async def test():
    # Valid Redis connection
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    graceful = GracefulRedisClient(client)

    # Health check
    health = await graceful.health_check()
    print(f'Health check: {health}')

    assert health['status'] == 'healthy'
    assert 'circuit_state' in health

    print('SUCCESS: Health check reports correctly')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] Circuit breaker pattern implemented
- [ ] Graceful fallback returns default values on Redis failure
- [ ] Optional operations skip silently when unavailable
- [ ] Service status tracked (healthy, degraded, unavailable)
- [ ] Health check reports Redis status accurately
- [ ] Consecutive failure counting works
- [ ] Recovery detection (half-open state) works
- [ ] Logging appropriate for each degradation state

---

## Rollback Procedure

If issues occur:

1. Remove graceful_redis.py
2. Revert to direct Redis calls
3. Update health endpoint

```bash
# Rollback commands
rm /opt/hx-lang-server/app/services/graceful_redis.py
git checkout /opt/hx-lang-server/app/api/health.py
```

---

## Notes

- Circuit breaker prevents overwhelming a failing Redis server
- Fallback values should be safe defaults (None, True for rate limiting)
- Logging should indicate degraded operation clearly
- Recovery timeout allows circuit to close after Redis recovers
- Health endpoint must report accurate status for monitoring

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Operational Requirements
