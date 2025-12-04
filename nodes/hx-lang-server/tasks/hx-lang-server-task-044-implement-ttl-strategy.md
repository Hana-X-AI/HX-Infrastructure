# Task: Implement TTL Strategy

**Task ID**: hx-lang-server-task-044-implement-ttl-strategy
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-043 (Redis key namespace)
**Estimated Time**: 45 minutes

---

## Objective

Implement a comprehensive TTL (Time-To-Live) management strategy for all Redis keys used by hx-lang-server. This includes TTL extension for active sessions (sliding expiration), automatic cleanup, and TTL monitoring. The strategy ensures ephemeral data expires appropriately while active sessions remain accessible.

---

## Prerequisites

- [ ] Redis key namespace configured (task-043)
- [ ] RedisKeys module with TTL constants available
- [ ] SessionManager implemented (task-042)

---

## Specification Reference

**From node-spec.md v2.1 and Sri Patel's Redis contribution:**

| Key Pattern | TTL | Rationale |
|-------------|-----|-----------|
| `session:{session_id}` | 3600s (1 hour) | Typical agent interaction duration |
| `thread:{thread_id}:messages` | 3600s (1 hour) | Align with session lifecycle |
| `thread:{thread_id}:state` | 1800s (30 min) | Short-term state between checkpoints |
| `cache:llm:{hash}` | 300s (5 min) | LLM responses may become stale |
| `cache:rag:{hash}` | 600s (10 min) | RAG context relatively stable |
| `cache:classify:{hash}` | 1800s (30 min) | Query classification is stable |
| `rate:user:{user_id}` | 60s (1 min) | Sliding window rate limiting |
| `lock:checkpoint:{thread_id}` | 30s | Checkpoint operation timeout |

---

## Implementation Steps

### Step 1: Create TTL Manager Module

Create file: `/opt/hx-lang-server/app/services/ttl_manager.py`

```python
"""
TTL management service for hx-lang-server.

Provides TTL extension, monitoring, and automatic cleanup strategies
for Redis keys. Implements sliding expiration for active sessions.
"""

import asyncio
from datetime import datetime, timedelta
from typing import Optional, List, Dict
import redis.asyncio as redis
import structlog

from app.core.redis_keys import RedisKeys, KEYS

logger = structlog.get_logger(__name__)


class TTLManager:
    """
    Manages TTL (Time-To-Live) for Redis keys.

    Implements sliding expiration where active sessions have their
    TTL extended automatically, preventing timeout during use.
    """

    # Extend TTL when remaining time is below this threshold (25%)
    EXTENSION_THRESHOLD = 0.25

    # Minimum remaining TTL before extension (in seconds)
    MIN_TTL_BEFORE_EXTEND = 300  # 5 minutes

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize TTL Manager.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    async def get_ttl(self, key: str) -> int:
        """
        Get remaining TTL for a key.

        Args:
            key: Redis key

        Returns:
            TTL in seconds, -1 if no TTL, -2 if key doesn't exist
        """
        return await self.redis.ttl(key)

    async def set_ttl(self, key: str, ttl_seconds: int) -> bool:
        """
        Set or update TTL for a key.

        Args:
            key: Redis key
            ttl_seconds: New TTL in seconds

        Returns:
            True if TTL was set successfully
        """
        result = await self.redis.expire(key, ttl_seconds)
        if result:
            logger.debug("ttl_set", key=key, ttl=ttl_seconds)
        return bool(result)

    async def should_extend_ttl(self, key: str, original_ttl: int) -> bool:
        """
        Check if TTL should be extended based on threshold.

        Args:
            key: Redis key
            original_ttl: Original TTL value for this key type

        Returns:
            True if TTL should be extended
        """
        current_ttl = await self.get_ttl(key)

        # Key doesn't exist or has no TTL
        if current_ttl < 0:
            return False

        # Check if below threshold
        threshold = original_ttl * self.EXTENSION_THRESHOLD
        return current_ttl < threshold

    async def maybe_extend_ttl(self, key: str, original_ttl: int) -> bool:
        """
        Extend TTL if below threshold.

        This implements sliding expiration - keys that are actively
        used get their TTL refreshed.

        Args:
            key: Redis key
            original_ttl: Original TTL to restore

        Returns:
            True if TTL was extended
        """
        if await self.should_extend_ttl(key, original_ttl):
            result = await self.set_ttl(key, original_ttl)
            if result:
                logger.debug("ttl_extended", key=key, new_ttl=original_ttl)
            return result
        return False

    async def extend_session_ttl(self, session_id: str) -> Dict[str, bool]:
        """
        Extend TTL for all session-related keys.

        Implements sliding expiration for active sessions.

        Args:
            session_id: Session identifier

        Returns:
            Dict mapping key names to extension success
        """
        session_key = KEYS.session(session_id)

        # Get associated thread_id
        thread_id = await self.redis.hget(session_key, "thread_id")

        results = {}

        # Extend session key
        results["session"] = await self.maybe_extend_ttl(
            session_key, RedisKeys.TTL_SESSION
        )

        if thread_id:
            # Extend thread-related keys
            results["thread_messages"] = await self.maybe_extend_ttl(
                KEYS.thread_messages(thread_id), RedisKeys.TTL_THREAD
            )
            results["thread_state"] = await self.maybe_extend_ttl(
                KEYS.thread_state(thread_id), RedisKeys.TTL_STATE
            )
            results["thread_meta"] = await self.maybe_extend_ttl(
                KEYS.thread_meta(thread_id), RedisKeys.TTL_THREAD
            )

        if any(results.values()):
            logger.info(
                "session_ttl_extended",
                session_id=session_id,
                extended_keys=[k for k, v in results.items() if v],
            )

        return results

    async def get_session_ttl_info(self, session_id: str) -> Dict[str, int]:
        """
        Get TTL information for all session-related keys.

        Useful for monitoring and debugging.

        Args:
            session_id: Session identifier

        Returns:
            Dict mapping key names to remaining TTL
        """
        session_key = KEYS.session(session_id)
        thread_id = await self.redis.hget(session_key, "thread_id")

        info = {
            "session": await self.get_ttl(session_key),
        }

        if thread_id:
            info["thread_messages"] = await self.get_ttl(KEYS.thread_messages(thread_id))
            info["thread_state"] = await self.get_ttl(KEYS.thread_state(thread_id))
            info["thread_meta"] = await self.get_ttl(KEYS.thread_meta(thread_id))

        return info

    async def ensure_ttl(self, key: str, ttl_seconds: int) -> bool:
        """
        Ensure a key has TTL set (defensive operation).

        Some operations may create keys without TTL. This ensures
        TTL is always set to prevent orphaned keys.

        Args:
            key: Redis key
            ttl_seconds: TTL to set if missing

        Returns:
            True if TTL was set (key had no TTL)
        """
        current_ttl = await self.get_ttl(key)

        # Key exists but has no TTL (-1)
        if current_ttl == -1:
            logger.warning("key_missing_ttl", key=key, setting_ttl=ttl_seconds)
            return await self.set_ttl(key, ttl_seconds)

        return False


class TTLMonitor:
    """
    Monitors TTL status across Redis keys.

    Provides statistics and alerts for TTL-related issues.
    """

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize TTL Monitor.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    async def scan_keys_without_ttl(self, pattern: str = "hx-lang-server:*") -> List[str]:
        """
        Find keys that don't have TTL set.

        Keys without TTL will never expire, potentially causing memory issues.

        Args:
            pattern: Key pattern to scan

        Returns:
            List of keys without TTL
        """
        keys_without_ttl = []

        async for key in self.redis.scan_iter(match=pattern, count=100):
            ttl = await self.redis.ttl(key)
            if ttl == -1:  # No TTL set
                keys_without_ttl.append(key)

        if keys_without_ttl:
            logger.warning(
                "keys_without_ttl_found",
                count=len(keys_without_ttl),
                keys=keys_without_ttl[:10],  # Log first 10
            )

        return keys_without_ttl

    async def get_ttl_statistics(self, pattern: str = "hx-lang-server:*") -> Dict:
        """
        Get TTL statistics for keys matching pattern.

        Args:
            pattern: Key pattern to analyze

        Returns:
            Statistics dictionary
        """
        stats = {
            "total_keys": 0,
            "keys_with_ttl": 0,
            "keys_without_ttl": 0,
            "avg_ttl_seconds": 0,
            "min_ttl_seconds": float("inf"),
            "max_ttl_seconds": 0,
            "keys_expiring_soon": 0,  # TTL < 60 seconds
        }

        ttl_sum = 0

        async for key in self.redis.scan_iter(match=pattern, count=100):
            stats["total_keys"] += 1
            ttl = await self.redis.ttl(key)

            if ttl == -1:
                stats["keys_without_ttl"] += 1
            elif ttl >= 0:
                stats["keys_with_ttl"] += 1
                ttl_sum += ttl
                stats["min_ttl_seconds"] = min(stats["min_ttl_seconds"], ttl)
                stats["max_ttl_seconds"] = max(stats["max_ttl_seconds"], ttl)

                if ttl < 60:
                    stats["keys_expiring_soon"] += 1

        if stats["keys_with_ttl"] > 0:
            stats["avg_ttl_seconds"] = ttl_sum / stats["keys_with_ttl"]

        if stats["min_ttl_seconds"] == float("inf"):
            stats["min_ttl_seconds"] = 0

        return stats

    async def fix_missing_ttls(self, pattern: str = "hx-lang-server:*") -> int:
        """
        Fix keys that are missing TTL by setting default TTL.

        Uses conservative TTL of 1 hour for unknown key types.

        Args:
            pattern: Key pattern to fix

        Returns:
            Number of keys fixed
        """
        DEFAULT_TTL = 3600  # 1 hour default

        fixed_count = 0
        keys_without_ttl = await self.scan_keys_without_ttl(pattern)

        for key in keys_without_ttl:
            # Determine appropriate TTL based on key pattern
            if ":session:" in key:
                ttl = RedisKeys.TTL_SESSION
            elif ":thread:" in key and ":state" in key:
                ttl = RedisKeys.TTL_STATE
            elif ":thread:" in key:
                ttl = RedisKeys.TTL_THREAD
            elif ":cache:llm:" in key:
                ttl = RedisKeys.TTL_LLM_CACHE
            elif ":cache:rag:" in key:
                ttl = RedisKeys.TTL_RAG_CACHE
            elif ":cache:classify:" in key:
                ttl = RedisKeys.TTL_CLASSIFY_CACHE
            elif ":rate:" in key:
                ttl = RedisKeys.TTL_RATE_LIMIT
            elif ":lock:" in key:
                ttl = RedisKeys.TTL_LOCK_CHECKPOINT
            else:
                ttl = DEFAULT_TTL

            await self.redis.expire(key, ttl)
            fixed_count += 1
            logger.info("ttl_fixed", key=key, ttl=ttl)

        return fixed_count


class SessionTTLMiddleware:
    """
    Middleware to automatically extend session TTL on activity.

    This can be integrated with FastAPI middleware to implement
    sliding expiration transparently.
    """

    def __init__(self, ttl_manager: TTLManager):
        """
        Initialize middleware.

        Args:
            ttl_manager: TTL manager instance
        """
        self.ttl_manager = ttl_manager

    async def on_session_activity(self, session_id: str) -> None:
        """
        Called when session activity is detected.

        Extends TTL for active sessions.

        Args:
            session_id: Active session identifier
        """
        await self.ttl_manager.extend_session_ttl(session_id)
```

### Step 2: Create TTL Configuration

Add to `/opt/hx-lang-server/app/core/config.py`:

```python
# TTL Configuration (add to Settings class)
class Settings(BaseSettings):
    # ... existing settings ...

    # TTL Configuration (seconds)
    ttl_session: int = 3600        # 1 hour
    ttl_thread: int = 3600         # 1 hour
    ttl_state: int = 1800          # 30 minutes
    ttl_llm_cache: int = 300       # 5 minutes
    ttl_rag_cache: int = 600       # 10 minutes
    ttl_classify_cache: int = 1800 # 30 minutes
    ttl_rate_limit: int = 60       # 1 minute
    ttl_extension_threshold: float = 0.25  # Extend when 25% remaining
```

### Step 3: Integrate with FastAPI Middleware

Add to `/opt/hx-lang-server/app/middleware/ttl_middleware.py`:

```python
"""
TTL extension middleware for FastAPI.

Automatically extends session TTL on API activity.
"""

from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import structlog

from app.services.ttl_manager import TTLManager

logger = structlog.get_logger(__name__)


class TTLExtensionMiddleware(BaseHTTPMiddleware):
    """
    Middleware that extends session TTL on each request.

    Implements sliding expiration - active sessions don't expire.
    """

    def __init__(self, app, ttl_manager: TTLManager):
        super().__init__(app)
        self.ttl_manager = ttl_manager

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request and extend session TTL."""

        # Extract session_id from request (header or query param)
        session_id = (
            request.headers.get("X-Session-ID") or
            request.query_params.get("session_id")
        )

        # Process request
        response = await call_next(request)

        # Extend TTL for active session (non-blocking)
        if session_id:
            try:
                await self.ttl_manager.extend_session_ttl(session_id)
            except Exception as e:
                logger.warning(
                    "ttl_extension_failed",
                    session_id=session_id,
                    error=str(e),
                )

        return response
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| TTL Manager | `/opt/hx-lang-server/app/services/ttl_manager.py` | TTL management service |
| TTL Middleware | `/opt/hx-lang-server/app/middleware/ttl_middleware.py` | FastAPI middleware |
| Updated config | `/opt/hx-lang-server/app/core/config.py` | TTL settings |

---

## Verification Steps

### Step 1: Verify TTL Manager Functions

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.ttl_manager import TTLManager
from app.core.redis_keys import KEYS, RedisKeys

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    ttl_mgr = TTLManager(client)

    # Create test key
    test_key = KEYS.session('ttl-test')
    await client.set(test_key, 'test', ex=3600)

    # Test get_ttl
    ttl = await ttl_mgr.get_ttl(test_key)
    print(f'TTL: {ttl} seconds')
    assert 3500 < ttl <= 3600

    # Test should_extend (shouldn't extend - TTL is high)
    should_extend = await ttl_mgr.should_extend_ttl(test_key, RedisKeys.TTL_SESSION)
    print(f'Should extend (high TTL): {should_extend}')
    assert not should_extend

    # Reduce TTL to trigger extension
    await client.expire(test_key, 100)  # Set low TTL
    should_extend = await ttl_mgr.should_extend_ttl(test_key, RedisKeys.TTL_SESSION)
    print(f'Should extend (low TTL): {should_extend}')
    assert should_extend

    # Test extend
    extended = await ttl_mgr.maybe_extend_ttl(test_key, RedisKeys.TTL_SESSION)
    print(f'Extended: {extended}')
    assert extended

    # Verify new TTL
    new_ttl = await ttl_mgr.get_ttl(test_key)
    print(f'New TTL after extension: {new_ttl} seconds')
    assert 3500 < new_ttl <= 3600

    # Cleanup
    await client.delete(test_key)
    print('SUCCESS: TTL Manager tests passed')

asyncio.run(test())
"
```

### Step 2: Verify TTL Monitor

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.ttl_manager import TTLMonitor
from app.core.redis_keys import KEYS

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    monitor = TTLMonitor(client)

    # Create test keys - one with TTL, one without
    await client.set(KEYS.session('monitor-test-1'), 'test', ex=3600)
    await client.set(KEYS.session('monitor-test-2'), 'test')  # No TTL

    # Test scan for keys without TTL
    keys_no_ttl = await monitor.scan_keys_without_ttl('hx-lang-server:session:monitor-test*')
    print(f'Keys without TTL: {keys_no_ttl}')
    assert 'hx-lang-server:session:monitor-test-2' in keys_no_ttl

    # Test fix missing TTLs
    fixed = await monitor.fix_missing_ttls('hx-lang-server:session:monitor-test*')
    print(f'Fixed {fixed} keys')
    assert fixed >= 1

    # Verify fix worked
    keys_no_ttl_after = await monitor.scan_keys_without_ttl('hx-lang-server:session:monitor-test*')
    print(f'Keys without TTL after fix: {keys_no_ttl_after}')
    assert len(keys_no_ttl_after) == 0

    # Get statistics
    stats = await monitor.get_ttl_statistics('hx-lang-server:session:monitor-test*')
    print(f'TTL stats: {stats}')

    # Cleanup
    await client.delete(KEYS.session('monitor-test-1'))
    await client.delete(KEYS.session('monitor-test-2'))
    print('SUCCESS: TTL Monitor tests passed')

asyncio.run(test())
"
```

### Step 3: Verify Session TTL Extension

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.session_manager import SessionManager
from app.services.ttl_manager import TTLManager

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    sm = SessionManager(client)
    ttl_mgr = TTLManager(client)

    # Create session
    session = await sm.create_session('ttl-session-test', 'ttl-thread-test')

    # Simulate low TTL
    await client.expire(f'hx-lang-server:session:{session.session_id}', 100)

    # Get TTL info before extension
    info_before = await ttl_mgr.get_session_ttl_info(session.session_id)
    print(f'TTL info before: {info_before}')
    assert info_before['session'] < 200

    # Extend session TTL
    results = await ttl_mgr.extend_session_ttl(session.session_id)
    print(f'Extension results: {results}')
    assert results['session'] == True

    # Verify TTL restored
    info_after = await ttl_mgr.get_session_ttl_info(session.session_id)
    print(f'TTL info after: {info_after}')
    assert info_after['session'] > 3500

    # Cleanup
    await sm.end_session(session.session_id)
    print('SUCCESS: Session TTL extension tests passed')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] TTLManager class implements TTL get, set, and extend operations
- [ ] Sliding expiration implemented (extend TTL when below 25% threshold)
- [ ] TTLMonitor can scan for keys without TTL
- [ ] TTLMonitor can fix missing TTLs with appropriate values
- [ ] Session TTL extension works for all related keys
- [ ] TTL statistics available for monitoring
- [ ] FastAPI middleware for automatic TTL extension created

---

## Rollback Procedure

If issues occur:

1. Remove ttl_manager.py
2. Remove ttl_middleware.py
3. Revert config.py changes
4. Clean up test keys

```bash
# Rollback commands
rm /opt/hx-lang-server/app/services/ttl_manager.py
rm /opt/hx-lang-server/app/middleware/ttl_middleware.py
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*test*" | xargs redis-cli -h hx-redis-server.hx.dev.local DEL
```

---

## Notes

- Sliding expiration prevents active sessions from timing out mid-conversation
- TTL monitoring helps identify memory leaks from keys without expiration
- The 25% threshold balances between too-frequent extensions and risk of timeout
- Fix missing TTLs should be run periodically as a maintenance task

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Redis Key Schema (TTL values)
