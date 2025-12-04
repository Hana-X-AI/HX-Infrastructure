# Task: Implement Rate Limiting with Redis

**Task ID**: hx-lang-server-task-046-implement-rate-limiting
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-043 (Redis key namespace)
**Estimated Time**: 45 minutes

---

## Objective

Implement rate limiting using Redis sorted sets with sliding window algorithm. Rate limiting protects hx-lang-server from abuse and ensures fair resource allocation across users and sessions. The implementation supports per-user, per-session, and per-endpoint rate limits.

---

## Prerequisites

- [ ] Redis key namespace configured (task-043)
- [ ] RedisKeys module available with rate limit key patterns
- [ ] Python virtual environment with redis>=5.0.0

---

## Specification Reference

**From node-spec.md v2.1, Section: Authorization (Lines 718-719):**

> Rate Limiting: 100 requests/minute per session (Redis-based)

**From Redis Key Schema:**

| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:ratelimit:{user_id}` | Rate limiting | 1 minute |

**From Sri Patel's Redis contribution - Rate Limiting Implementation using sorted sets.**

---

## Implementation Steps

### Step 1: Create Rate Limiter Module

Create file: `/opt/hx-lang-server/app/services/rate_limiter.py`

```python
"""
Rate limiting service for hx-lang-server.

Implements sliding window rate limiting using Redis sorted sets.
Supports per-user, per-session, and per-endpoint limits.

Rate limiting protects the service from abuse and ensures
fair resource allocation across consumers.
"""

import time
from typing import Tuple, Optional
from dataclasses import dataclass
import redis.asyncio as redis
import structlog

from app.core.redis_keys import KEYS, RedisKeys

logger = structlog.get_logger(__name__)


@dataclass
class RateLimitResult:
    """Result of a rate limit check."""

    allowed: bool
    remaining: int
    limit: int
    reset_after: float  # Seconds until window resets
    retry_after: Optional[float] = None  # Seconds until next request allowed

    def to_headers(self) -> dict:
        """Convert to HTTP headers for response."""
        headers = {
            "X-RateLimit-Limit": str(self.limit),
            "X-RateLimit-Remaining": str(self.remaining),
            "X-RateLimit-Reset": str(int(time.time() + self.reset_after)),
        }
        if self.retry_after is not None:
            headers["Retry-After"] = str(int(self.retry_after))
        return headers


class RateLimiter:
    """
    Sliding window rate limiter using Redis sorted sets.

    Uses sorted sets with timestamps as scores to implement
    precise sliding window rate limiting.
    """

    # Default limits from specification
    DEFAULT_LIMIT = 100  # requests
    DEFAULT_WINDOW = 60  # seconds (1 minute)

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize rate limiter.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    async def check(
        self,
        identifier: str,
        limit: int = DEFAULT_LIMIT,
        window_seconds: int = DEFAULT_WINDOW,
        scope: str = "user",
    ) -> RateLimitResult:
        """
        Check if request is allowed under rate limit.

        This is a read-only check that does not consume the limit.

        Args:
            identifier: User ID, session ID, or other identifier
            limit: Maximum requests in window
            window_seconds: Window size in seconds
            scope: Rate limit scope (user, session, endpoint)

        Returns:
            RateLimitResult with allowed status and metadata
        """
        key = self._get_key(identifier, scope)
        now = time.time()
        window_start = now - window_seconds

        # Remove old entries and count current
        pipe = self.redis.pipeline()
        pipe.zremrangebyscore(key, "-inf", window_start)
        pipe.zcard(key)
        results = await pipe.execute()

        current_count = results[1]
        remaining = max(0, limit - current_count)
        allowed = current_count < limit

        # Calculate reset time
        if current_count > 0:
            oldest = await self.redis.zrange(key, 0, 0, withscores=True)
            if oldest:
                oldest_time = oldest[0][1]
                reset_after = oldest_time + window_seconds - now
            else:
                reset_after = window_seconds
        else:
            reset_after = window_seconds

        result = RateLimitResult(
            allowed=allowed,
            remaining=remaining,
            limit=limit,
            reset_after=max(0, reset_after),
            retry_after=None if allowed else max(0, reset_after),
        )

        logger.debug(
            "rate_limit_check",
            identifier=identifier,
            scope=scope,
            allowed=allowed,
            remaining=remaining,
            current_count=current_count,
        )

        return result

    async def is_allowed(
        self,
        identifier: str,
        limit: int = DEFAULT_LIMIT,
        window_seconds: int = DEFAULT_WINDOW,
        scope: str = "user",
    ) -> Tuple[bool, int]:
        """
        Check if request is allowed AND consume one request slot.

        This is the primary method for rate limiting API endpoints.

        Args:
            identifier: User ID, session ID, or other identifier
            limit: Maximum requests in window
            window_seconds: Window size in seconds
            scope: Rate limit scope

        Returns:
            Tuple of (is_allowed, remaining_requests)
        """
        key = self._get_key(identifier, scope)
        now = time.time()
        window_start = now - window_seconds

        # Atomic rate limit check and increment using pipeline
        pipe = self.redis.pipeline()

        # Remove old entries outside window
        pipe.zremrangebyscore(key, "-inf", window_start)

        # Count current entries
        pipe.zcard(key)

        # Add current request timestamp
        # Use unique member (timestamp with microseconds) to handle rapid requests
        member = f"{now}:{id(now)}"
        pipe.zadd(key, {member: now})

        # Set TTL on key
        pipe.expire(key, window_seconds)

        results = await pipe.execute()
        current_count = results[1]

        if current_count >= limit:
            # Over limit - remove the request we just added
            await self.redis.zrem(key, member)
            remaining = 0
            allowed = False
        else:
            remaining = limit - current_count - 1
            allowed = True

        logger.debug(
            "rate_limit_consumed",
            identifier=identifier,
            scope=scope,
            allowed=allowed,
            remaining=remaining,
        )

        return allowed, remaining

    async def get_remaining(
        self,
        identifier: str,
        limit: int = DEFAULT_LIMIT,
        window_seconds: int = DEFAULT_WINDOW,
        scope: str = "user",
    ) -> int:
        """
        Get remaining requests in current window.

        Args:
            identifier: User ID, session ID, or other identifier
            limit: Maximum requests in window
            window_seconds: Window size in seconds
            scope: Rate limit scope

        Returns:
            Number of remaining requests
        """
        key = self._get_key(identifier, scope)
        now = time.time()
        window_start = now - window_seconds

        # Clean old entries and count
        await self.redis.zremrangebyscore(key, "-inf", window_start)
        current_count = await self.redis.zcard(key)

        return max(0, limit - current_count)

    async def reset(
        self,
        identifier: str,
        scope: str = "user",
    ) -> bool:
        """
        Reset rate limit for an identifier.

        Useful for administrative actions or testing.

        Args:
            identifier: Identifier to reset
            scope: Rate limit scope

        Returns:
            True if key was deleted
        """
        key = self._get_key(identifier, scope)
        deleted = await self.redis.delete(key)
        logger.info("rate_limit_reset", identifier=identifier, scope=scope)
        return bool(deleted)

    def _get_key(self, identifier: str, scope: str) -> str:
        """
        Generate Redis key for rate limiting.

        Args:
            identifier: User/session identifier
            scope: Rate limit scope

        Returns:
            Full Redis key
        """
        if scope == "user":
            return KEYS.rate_user(identifier)
        elif scope == "session":
            return KEYS.rate_session(identifier)
        else:
            # Generic rate limit key for custom scopes
            return f"hx-lang-server:rate:{scope}:{identifier}"


class EndpointRateLimiter:
    """
    Rate limiter with per-endpoint configuration.

    Different endpoints may have different rate limits based
    on their resource consumption.
    """

    # Endpoint-specific limits
    ENDPOINT_LIMITS = {
        # Heavy endpoints - lower limits
        "/invoke": {"limit": 100, "window": 60},
        "/stream": {"limit": 50, "window": 60},

        # Light endpoints - higher limits
        "/health": {"limit": 300, "window": 60},
        "/ready": {"limit": 300, "window": 60},
        "/threads": {"limit": 200, "window": 60},

        # Default for unlisted endpoints
        "default": {"limit": 100, "window": 60},
    }

    def __init__(self, rate_limiter: RateLimiter):
        """
        Initialize endpoint rate limiter.

        Args:
            rate_limiter: Base rate limiter instance
        """
        self.limiter = rate_limiter

    def get_limits(self, endpoint: str) -> dict:
        """
        Get rate limits for an endpoint.

        Args:
            endpoint: API endpoint path

        Returns:
            Dict with limit and window
        """
        return self.ENDPOINT_LIMITS.get(endpoint, self.ENDPOINT_LIMITS["default"])

    async def is_allowed(
        self,
        identifier: str,
        endpoint: str,
        scope: str = "user",
    ) -> Tuple[bool, int, dict]:
        """
        Check rate limit for specific endpoint.

        Args:
            identifier: User/session identifier
            endpoint: API endpoint
            scope: Rate limit scope

        Returns:
            Tuple of (is_allowed, remaining, limits_dict)
        """
        limits = self.get_limits(endpoint)

        # Create endpoint-specific identifier
        endpoint_identifier = f"{identifier}:{endpoint}"

        allowed, remaining = await self.limiter.is_allowed(
            endpoint_identifier,
            limit=limits["limit"],
            window_seconds=limits["window"],
            scope=scope,
        )

        return allowed, remaining, limits


class RateLimitMiddlewareConfig:
    """
    Configuration for rate limiting middleware.

    Provides settings for FastAPI middleware integration.
    """

    def __init__(
        self,
        rate_limiter: RateLimiter,
        enabled: bool = True,
        default_limit: int = 100,
        default_window: int = 60,
        identifier_header: str = "X-User-ID",
        fallback_to_ip: bool = True,
    ):
        """
        Initialize middleware configuration.

        Args:
            rate_limiter: Rate limiter instance
            enabled: Whether rate limiting is enabled
            default_limit: Default request limit
            default_window: Default window in seconds
            identifier_header: Header containing user identifier
            fallback_to_ip: Use IP if no identifier found
        """
        self.rate_limiter = rate_limiter
        self.enabled = enabled
        self.default_limit = default_limit
        self.default_window = default_window
        self.identifier_header = identifier_header
        self.fallback_to_ip = fallback_to_ip

    def get_identifier(self, request) -> str:
        """
        Extract identifier from request for rate limiting.

        Args:
            request: FastAPI request object

        Returns:
            Identifier string
        """
        # Try header first
        identifier = request.headers.get(self.identifier_header)

        # Try session ID
        if not identifier:
            identifier = request.headers.get("X-Session-ID")

        # Fallback to IP
        if not identifier and self.fallback_to_ip:
            identifier = request.client.host if request.client else "unknown"

        return identifier or "anonymous"
```

### Step 2: Create FastAPI Rate Limiting Middleware

Create file: `/opt/hx-lang-server/app/middleware/rate_limit_middleware.py`

```python
"""
Rate limiting middleware for FastAPI.

Integrates rate limiting with FastAPI request/response cycle.
"""

from typing import Callable
from fastapi import Request, Response, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import structlog

from app.services.rate_limiter import RateLimiter, RateLimitMiddlewareConfig

logger = structlog.get_logger(__name__)


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Middleware that enforces rate limits on API requests.

    Returns 429 Too Many Requests when limit exceeded.
    """

    # Endpoints excluded from rate limiting
    EXCLUDED_ENDPOINTS = ["/health", "/ready", "/docs", "/openapi.json"]

    def __init__(self, app, config: RateLimitMiddlewareConfig):
        super().__init__(app)
        self.config = config

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request with rate limiting."""

        # Skip if disabled
        if not self.config.enabled:
            return await call_next(request)

        # Skip excluded endpoints
        if request.url.path in self.EXCLUDED_ENDPOINTS:
            return await call_next(request)

        # Get identifier
        identifier = self.config.get_identifier(request)

        # Check rate limit
        allowed, remaining = await self.config.rate_limiter.is_allowed(
            identifier,
            limit=self.config.default_limit,
            window_seconds=self.config.default_window,
            scope="user",
        )

        if not allowed:
            logger.warning(
                "rate_limit_exceeded",
                identifier=identifier,
                endpoint=request.url.path,
            )
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded. Please retry later.",
                headers={
                    "X-RateLimit-Limit": str(self.config.default_limit),
                    "X-RateLimit-Remaining": "0",
                    "Retry-After": str(self.config.default_window),
                },
            )

        # Process request
        response = await call_next(request)

        # Add rate limit headers
        response.headers["X-RateLimit-Limit"] = str(self.config.default_limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)

        return response
```

### Step 3: Add to FastAPI Application

Add to `/opt/hx-lang-server/app/main.py`:

```python
from app.services.rate_limiter import RateLimiter, RateLimitMiddlewareConfig
from app.middleware.rate_limit_middleware import RateLimitMiddleware

# In lifespan or startup:
rate_limiter = RateLimiter(redis_client)
rate_limit_config = RateLimitMiddlewareConfig(
    rate_limiter=rate_limiter,
    enabled=True,
    default_limit=100,
    default_window=60,
)

# Add middleware
app.add_middleware(RateLimitMiddleware, config=rate_limit_config)
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Rate limiter service | `/opt/hx-lang-server/app/services/rate_limiter.py` | Rate limiting implementation |
| Rate limit middleware | `/opt/hx-lang-server/app/middleware/rate_limit_middleware.py` | FastAPI middleware |

---

## Verification Steps

### Step 1: Verify Basic Rate Limiting

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.rate_limiter import RateLimiter

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    limiter = RateLimiter(client)

    # Clean up
    await limiter.reset('test-user')

    # Test first request (should be allowed)
    allowed, remaining = await limiter.is_allowed('test-user', limit=5, window_seconds=60)
    print(f'Request 1: allowed={allowed}, remaining={remaining}')
    assert allowed == True
    assert remaining == 4

    # Test subsequent requests
    for i in range(4):
        allowed, remaining = await limiter.is_allowed('test-user', limit=5, window_seconds=60)
        print(f'Request {i+2}: allowed={allowed}, remaining={remaining}')

    # 6th request should be denied
    allowed, remaining = await limiter.is_allowed('test-user', limit=5, window_seconds=60)
    print(f'Request 6: allowed={allowed}, remaining={remaining}')
    assert allowed == False
    assert remaining == 0

    # Clean up
    await limiter.reset('test-user')
    print('SUCCESS: Basic rate limiting tests passed')

asyncio.run(test())
"
```

### Step 2: Verify Sliding Window Behavior

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import time
import redis.asyncio as redis
from app.services.rate_limiter import RateLimiter

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    limiter = RateLimiter(client)

    # Clean up
    await limiter.reset('sliding-test')

    # Use small window for testing
    limit = 3
    window = 2  # 2 seconds

    # Make 3 requests (use up limit)
    for i in range(3):
        allowed, _ = await limiter.is_allowed('sliding-test', limit=limit, window_seconds=window)
        print(f'Request {i+1}: {allowed}')
        assert allowed

    # 4th request should fail
    allowed, _ = await limiter.is_allowed('sliding-test', limit=limit, window_seconds=window)
    print(f'Request 4 (should fail): {allowed}')
    assert not allowed

    # Wait for window to pass
    print('Waiting for window to expire...')
    await asyncio.sleep(window + 0.5)

    # Should be allowed again
    allowed, remaining = await limiter.is_allowed('sliding-test', limit=limit, window_seconds=window)
    print(f'After window: allowed={allowed}, remaining={remaining}')
    assert allowed

    # Clean up
    await limiter.reset('sliding-test')
    print('SUCCESS: Sliding window tests passed')

asyncio.run(test())
"
```

### Step 3: Verify Rate Limit Result Headers

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.rate_limiter import RateLimiter

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    limiter = RateLimiter(client)

    # Clean up
    await limiter.reset('header-test')

    # Check rate limit
    result = await limiter.check('header-test', limit=100, window_seconds=60)
    print(f'Rate limit check: {result}')

    headers = result.to_headers()
    print(f'HTTP headers: {headers}')

    assert 'X-RateLimit-Limit' in headers
    assert 'X-RateLimit-Remaining' in headers
    assert 'X-RateLimit-Reset' in headers
    assert headers['X-RateLimit-Limit'] == '100'

    # Clean up
    await limiter.reset('header-test')
    print('SUCCESS: Rate limit headers tests passed')

asyncio.run(test())
"
```

### Step 4: Verify Scope Isolation

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.rate_limiter import RateLimiter

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    limiter = RateLimiter(client)

    # Clean up
    await limiter.reset('scope-test', scope='user')
    await limiter.reset('scope-test', scope='session')

    # User scope rate limit
    await limiter.is_allowed('scope-test', limit=5, scope='user')
    user_remaining = await limiter.get_remaining('scope-test', limit=5, scope='user')

    # Session scope should be independent
    session_remaining = await limiter.get_remaining('scope-test', limit=5, scope='session')

    print(f'User remaining: {user_remaining}')
    print(f'Session remaining: {session_remaining}')

    assert user_remaining == 4  # One request consumed
    assert session_remaining == 5  # Independent counter

    # Clean up
    await limiter.reset('scope-test', scope='user')
    await limiter.reset('scope-test', scope='session')
    print('SUCCESS: Scope isolation tests passed')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] Sliding window rate limiting implemented with sorted sets
- [ ] Per-user rate limiting working (100 requests/minute default)
- [ ] Per-session rate limiting working
- [ ] Rate limit headers returned in responses
- [ ] 429 status returned when limit exceeded
- [ ] Retry-After header included on rate limit
- [ ] Rate limit reset functionality available
- [ ] Scope isolation between user and session limits
- [ ] FastAPI middleware integrates with application

---

## Rollback Procedure

If issues occur:

1. Remove rate_limiter.py
2. Remove rate_limit_middleware.py
3. Remove middleware from main.py
4. Clean up rate limit keys

```bash
# Rollback commands
rm /opt/hx-lang-server/app/services/rate_limiter.py
rm /opt/hx-lang-server/app/middleware/rate_limit_middleware.py
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:rate:*" | xargs redis-cli -h hx-redis-server.hx.dev.local DEL
```

---

## Notes

- Sorted sets provide O(log N) operations for rate limiting
- Sliding window is more accurate than fixed window but uses slightly more memory
- Unique members (timestamp + id) prevent issues with rapid requests
- Scope isolation allows different limits for different dimensions
- 100 requests/minute aligns with specification requirement

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Authorization - Rate Limiting
