# Task: Configure Redis Connection Pool

**Task ID**: hx-lang-server-task-041-configure-redis-connection-pool
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-021 (Python virtual environment), hx-lang-server-task-022 (Python dependencies)
**Estimated Time**: 45 minutes

---

## Objective

Configure a production-grade Redis connection pool for hx-lang-server with 50 maximum connections, proper timeout settings, retry strategy with exponential backoff, and health check intervals. This pool will serve all Redis operations including session management, caching, and rate limiting.

---

## Prerequisites

- [ ] Python virtual environment created at `/opt/hx-lang-server/venv`
- [ ] `redis>=5.0.0` package installed in virtual environment
- [ ] Target Redis server operational: `hx-redis-server.hx.dev.local:6379`
- [ ] Network connectivity verified between hx-lang-server (192.168.10.226) and hx-redis-server (192.168.10.210)

---

## Specification Reference

**From node-spec.md v2.1, Section: Redis Integration (Lines 383-399)**

```python
redis_pool = redis.ConnectionPool.from_url(
    "redis://hx-redis-server.hx.dev.local:6379/0",
    max_connections=50,  # Increased from 20 per Sri Patel's Redis review
    socket_timeout=5.0,
    socket_connect_timeout=5.0,
    retry_on_timeout=True,
)
```

**Functional Requirement:**
- FR-007: Service MUST cache session data in Redis with configurable TTL

---

## Implementation Steps

### Step 1: Create Redis Configuration Module

Create file: `/opt/hx-lang-server/app/core/redis_config.py`

```python
"""
Redis connection pool configuration for hx-lang-server.

This module provides production-grade Redis connection pooling with:
- 50 maximum connections (per Sri Patel's recommendation)
- Exponential backoff retry strategy
- Health check intervals
- Graceful degradation support
"""

import redis.asyncio as redis
from redis.asyncio.connection import ConnectionPool
from redis.asyncio.retry import Retry
from redis.backoff import ExponentialBackoff
from typing import Optional
import structlog

logger = structlog.get_logger(__name__)

# Connection pool configuration aligned with node-spec.md v2.1
REDIS_POOL_CONFIG = {
    # Connection limits - 50 connections for 10 concurrent agent sessions
    "max_connections": 50,

    # Timeouts (seconds)
    "socket_timeout": 5.0,           # Read/write timeout
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

# Global pool instance (initialized at application startup)
_redis_pool: Optional[ConnectionPool] = None


def create_redis_pool(redis_url: str) -> ConnectionPool:
    """
    Create production-grade Redis connection pool.

    Args:
        redis_url: Redis URL in format redis://host:port/db

    Returns:
        Configured ConnectionPool instance
    """
    pool = redis.ConnectionPool.from_url(
        redis_url,
        **REDIS_POOL_CONFIG,
        retry=RETRY_STRATEGY,
    )
    logger.info(
        "redis_pool_created",
        url=redis_url.split("@")[-1],  # Log without credentials
        max_connections=REDIS_POOL_CONFIG["max_connections"],
    )
    return pool


async def get_redis_pool(redis_url: str) -> ConnectionPool:
    """
    Get or create the Redis connection pool singleton.

    Args:
        redis_url: Redis URL for pool creation

    Returns:
        ConnectionPool instance
    """
    global _redis_pool
    if _redis_pool is None:
        _redis_pool = create_redis_pool(redis_url)
    return _redis_pool


async def get_redis_client(redis_url: str) -> redis.Redis:
    """
    Get Redis client from connection pool.

    Args:
        redis_url: Redis URL for pool creation

    Returns:
        Redis client instance
    """
    pool = await get_redis_pool(redis_url)
    return redis.Redis(connection_pool=pool)


async def close_redis_pool() -> None:
    """Close the Redis connection pool."""
    global _redis_pool
    if _redis_pool is not None:
        await _redis_pool.disconnect()
        _redis_pool = None
        logger.info("redis_pool_closed")


async def get_pool_stats() -> dict:
    """
    Get connection pool statistics for monitoring.

    Returns:
        Dictionary with pool statistics
    """
    if _redis_pool is None:
        return {"status": "not_initialized"}

    return {
        "max_connections": _redis_pool.max_connections,
        "current_connections": len(_redis_pool._in_use_connections),
        "available_connections": len(_redis_pool._available_connections),
    }
```

### Step 2: Update Application Lifespan

Add to `/opt/hx-lang-server/app/main.py`:

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.core.redis_config import get_redis_client, close_redis_pool
from app.core.config import settings
import structlog

logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle including Redis pool."""

    # Startup: Initialize and verify Redis connection
    try:
        redis_client = await get_redis_client(settings.redis_url)
        await redis_client.ping()
        logger.info(
            "redis_connection_established",
            host="hx-redis-server.hx.dev.local",
            database=0,
        )
    except Exception as e:
        logger.error("redis_connection_failed", error=str(e))
        # Continue without Redis (graceful degradation)

    yield  # Application runs

    # Shutdown: Close Redis pool
    await close_redis_pool()


app = FastAPI(
    title="hx-lang-server",
    lifespan=lifespan,
)
```

### Step 3: Update Settings Model

Add to `/opt/hx-lang-server/app/core/config.py`:

```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings."""

    # Redis configuration
    redis_url: str = "redis://hx-redis-server.hx.dev.local:6379/0"
    redis_max_connections: int = 50
    redis_socket_timeout: float = 5.0
    redis_health_check_interval: int = 30

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
```

### Step 4: Update Environment File

Add to `/opt/hx-lang-server/.env`:

```bash
# Redis Configuration
REDIS_URL=redis://hx-redis-server.hx.dev.local:6379/0
REDIS_MAX_CONNECTIONS=50
REDIS_SOCKET_TIMEOUT=5.0
REDIS_HEALTH_CHECK_INTERVAL=30
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Redis config module | `/opt/hx-lang-server/app/core/redis_config.py` | Connection pool configuration |
| Updated main.py | `/opt/hx-lang-server/app/main.py` | Lifespan with Redis initialization |
| Updated config.py | `/opt/hx-lang-server/app/core/config.py` | Redis settings |
| Updated .env | `/opt/hx-lang-server/.env` | Environment variables |

---

## Verification Steps

### Step 1: Verify Redis Package Installed

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/pip show redis

# Expected: redis 5.x.x installed
```

### Step 2: Test Connection Pool Creation

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
from app.core.redis_config import create_redis_pool, REDIS_POOL_CONFIG

async def test():
    pool = create_redis_pool('redis://hx-redis-server.hx.dev.local:6379/0')
    print(f'Pool created with max_connections={pool.max_connections}')
    assert pool.max_connections == 50, 'Expected 50 connections'
    print('SUCCESS: Connection pool configured correctly')

asyncio.run(test())
"
```

### Step 3: Verify Redis Connectivity

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0')
    result = await client.ping()
    print(f'PING result: {result}')
    assert result == True, 'Redis PING failed'

    # Test set/get
    await client.set('hx-lang-server:test:connection', 'success', ex=60)
    value = await client.get('hx-lang-server:test:connection')
    print(f'Test key value: {value}')
    assert value == 'success', 'Redis SET/GET failed'

    await client.delete('hx-lang-server:test:connection')
    print('SUCCESS: Redis connectivity verified')

asyncio.run(test())
"
```

### Step 4: Verify Pool Statistics

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
from app.core.redis_config import get_redis_pool, get_pool_stats

async def test():
    pool = await get_redis_pool('redis://hx-redis-server.hx.dev.local:6379/0')
    stats = await get_pool_stats()
    print(f'Pool stats: {stats}')
    assert stats['max_connections'] == 50
    print('SUCCESS: Pool statistics verified')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] Redis connection pool created with `max_connections=50`
- [ ] Socket timeout configured to 5.0 seconds
- [ ] Retry strategy with exponential backoff enabled
- [ ] Health check interval set to 30 seconds
- [ ] Connection pool singleton pattern implemented
- [ ] Pool statistics available for monitoring
- [ ] Graceful shutdown closes pool properly
- [ ] PING command succeeds to hx-redis-server.hx.dev.local:6379

---

## Rollback Procedure

If issues occur:

1. Revert redis_config.py to previous version (if exists)
2. Remove Redis-related environment variables from .env
3. Update main.py to remove Redis lifespan management
4. Restart service

```bash
# Rollback commands
cd /opt/hx-lang-server
git checkout app/core/redis_config.py
git checkout app/main.py
sudo systemctl restart hx-lang-server
```

---

## Notes

- The 50 connection limit was recommended to handle 10 concurrent agent sessions with multiple operations per request
- Exponential backoff prevents overwhelming Redis during network transients
- The pool singleton pattern ensures connection reuse across the application
- Health check interval of 30 seconds balances detection speed with overhead

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Redis Integration
