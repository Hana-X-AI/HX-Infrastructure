# Task: Implement SessionManager Class

**Task ID**: hx-lang-server-task-042-implement-session-manager
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-041 (Redis connection pool)
**Estimated Time**: 60 minutes

---

## Objective

Implement the `SessionManager` class for managing ephemeral session state in Redis. This class handles session creation, retrieval, activity tracking, TTL extension, and session cleanup. Sessions coordinate with PostgreSQL checkpoints for durable state persistence.

---

## Prerequisites

- [ ] Redis connection pool configured (task-041)
- [ ] Redis server accessible at hx-redis-server.hx.dev.local:6379
- [ ] Python virtual environment with `redis>=5.0.0` and `pydantic>=2.9.0`

---

## Specification Reference

**From node-spec.md v2.1, Section: Session Management (Lines 405-429)**

```python
class SessionManager:
    """Manages ephemeral session state in Redis."""

    KEY_PREFIX = "hx-lang-server"  # Namespace prefix for key isolation
    SESSION_TTL = 3600  # 1 hour
    CACHE_TTL = 300     # 5 minutes

    def _key(self, suffix: str) -> str:
        """Generate namespaced key."""
        return f"{self.KEY_PREFIX}:{suffix}"
```

**Redis Key Schema:**
| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:session:{session_id}` | Active session data | 1 hour |
| `hx-lang-server:thread:{thread_id}:messages` | Message cache | 1 hour |

**Functional Requirement:**
- FR-007: Service MUST cache session data in Redis with configurable TTL

---

## Implementation Steps

### Step 1: Create Session Data Model

Create file: `/opt/hx-lang-server/app/models/session.py`

```python
"""
Session data models for hx-lang-server.

These models define the structure of session data stored in Redis.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class SessionData(BaseModel):
    """Session data model stored in Redis hash."""

    session_id: str = Field(..., description="Unique session identifier")
    thread_id: str = Field(..., description="LangGraph thread ID for this session")
    user_id: Optional[str] = Field(None, description="Optional user identifier")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_activity: datetime = Field(default_factory=datetime.utcnow)
    query_count: int = Field(default=0, description="Number of queries in session")
    metadata: dict = Field(default_factory=dict)

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ThreadMetadata(BaseModel):
    """Thread metadata stored in Redis hash."""

    session_id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    message_count: int = 0
```

### Step 2: Implement SessionManager Class

Create file: `/opt/hx-lang-server/app/services/session_manager.py`

```python
"""
Session management service for hx-lang-server.

Manages ephemeral session state in Redis with proper TTL handling,
activity tracking, and cleanup. Sessions are linked to LangGraph
threads for conversation continuity.
"""

import json
from datetime import datetime
from typing import Optional, List
import redis.asyncio as redis
import structlog

from app.models.session import SessionData, ThreadMetadata

logger = structlog.get_logger(__name__)


class SessionManager:
    """
    Production-grade session management with Redis.

    Implements the session management pattern from node-spec.md v2.1
    with KEY_PREFIX for namespace isolation.
    """

    # Namespace prefix per Alex Rivera's architecture review
    KEY_PREFIX = "hx-lang-server"

    # TTL values per specification
    SESSION_TTL = 3600      # 1 hour
    THREAD_TTL = 3600       # 1 hour
    STATE_TTL = 1800        # 30 minutes for ephemeral state
    MESSAGE_CACHE_SIZE = 50  # Last N messages to cache

    def __init__(self, redis_client: redis.Redis):
        """
        Initialize SessionManager with Redis client.

        Args:
            redis_client: Async Redis client instance
        """
        self.redis = redis_client

    def _key(self, suffix: str) -> str:
        """
        Generate namespaced key.

        Args:
            suffix: Key suffix (e.g., "session:abc123")

        Returns:
            Full key with namespace prefix
        """
        return f"{self.KEY_PREFIX}:{suffix}"

    async def create_session(
        self,
        session_id: str,
        thread_id: str,
        user_id: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> SessionData:
        """
        Create a new session with associated thread.

        Args:
            session_id: Unique session identifier
            thread_id: LangGraph thread ID
            user_id: Optional user identifier
            metadata: Optional session metadata

        Returns:
            Created SessionData instance
        """
        now = datetime.utcnow()
        session = SessionData(
            session_id=session_id,
            thread_id=thread_id,
            user_id=user_id,
            created_at=now,
            last_activity=now,
            query_count=0,
            metadata=metadata or {},
        )

        session_key = self._key(f"session:{session_id}")

        # Store session as hash (memory efficient with ziplist encoding)
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
        thread_meta_key = self._key(f"thread:{thread_id}:meta")
        await self.redis.hset(thread_meta_key, mapping={
            "session_id": session_id,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
            "message_count": "0",
        })
        await self.redis.expire(thread_meta_key, self.THREAD_TTL)

        logger.info(
            "session_created",
            session_id=session_id,
            thread_id=thread_id,
            user_id=user_id,
        )

        return session

    async def get_session(self, session_id: str) -> Optional[SessionData]:
        """
        Retrieve session data by ID.

        Args:
            session_id: Session identifier to retrieve

        Returns:
            SessionData if found, None otherwise
        """
        session_key = self._key(f"session:{session_id}")
        data = await self.redis.hgetall(session_key)

        if not data:
            logger.debug("session_not_found", session_id=session_id)
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

    async def update_activity(self, session_id: str) -> bool:
        """
        Update session activity timestamp and increment query count.

        Extends TTL on activity to implement sliding expiration.

        Args:
            session_id: Session to update

        Returns:
            True if session exists and was updated
        """
        session_key = self._key(f"session:{session_id}")

        # Check if session exists
        exists = await self.redis.exists(session_key)
        if not exists:
            logger.warning("update_activity_session_not_found", session_id=session_id)
            return False

        now = datetime.utcnow().isoformat()

        # Update activity and increment query count atomically
        pipe = self.redis.pipeline()
        pipe.hset(session_key, "last_activity", now)
        pipe.hincrby(session_key, "query_count", 1)
        pipe.expire(session_key, self.SESSION_TTL)
        await pipe.execute()

        logger.debug("session_activity_updated", session_id=session_id)
        return True

    async def extend_session(self, session_id: str) -> bool:
        """
        Extend session TTL without updating activity.

        Used when session should be kept alive but no new query occurred.

        Args:
            session_id: Session to extend

        Returns:
            True if session exists and TTL was extended
        """
        session_key = self._key(f"session:{session_id}")

        # Get thread_id to extend related keys
        thread_id = await self.redis.hget(session_key, "thread_id")
        if not thread_id:
            return False

        # Extend all session-related keys
        pipe = self.redis.pipeline()
        pipe.expire(session_key, self.SESSION_TTL)
        pipe.expire(self._key(f"thread:{thread_id}:meta"), self.THREAD_TTL)
        pipe.expire(self._key(f"thread:{thread_id}:messages"), self.THREAD_TTL)
        await pipe.execute()

        logger.debug("session_extended", session_id=session_id, thread_id=thread_id)
        return True

    async def end_session(self, session_id: str) -> int:
        """
        End session and clean up all related keys.

        Args:
            session_id: Session to terminate

        Returns:
            Number of keys deleted
        """
        session_key = self._key(f"session:{session_id}")

        # Get thread_id before deletion
        thread_id = await self.redis.hget(session_key, "thread_id")

        keys_to_delete = [session_key]

        if thread_id:
            keys_to_delete.extend([
                self._key(f"thread:{thread_id}:messages"),
                self._key(f"thread:{thread_id}:state"),
                self._key(f"thread:{thread_id}:meta"),
            ])

        deleted = await self.redis.delete(*keys_to_delete)

        logger.info(
            "session_ended",
            session_id=session_id,
            thread_id=thread_id,
            keys_deleted=deleted,
        )

        return deleted

    async def get_session_by_thread(self, thread_id: str) -> Optional[SessionData]:
        """
        Find session associated with a thread.

        Args:
            thread_id: LangGraph thread ID

        Returns:
            SessionData if found, None otherwise
        """
        thread_meta_key = self._key(f"thread:{thread_id}:meta")
        session_id = await self.redis.hget(thread_meta_key, "session_id")

        if not session_id:
            return None

        return await self.get_session(session_id)

    async def cache_message(
        self,
        thread_id: str,
        message: dict,
    ) -> None:
        """
        Cache a message for the thread.

        Uses a list with fixed size to cache recent messages.

        Args:
            thread_id: Thread to cache message for
            message: Message dict to cache
        """
        messages_key = self._key(f"thread:{thread_id}:messages")

        # Push message to list and trim to size
        pipe = self.redis.pipeline()
        pipe.rpush(messages_key, json.dumps(message))
        pipe.ltrim(messages_key, -self.MESSAGE_CACHE_SIZE, -1)
        pipe.expire(messages_key, self.THREAD_TTL)
        await pipe.execute()

    async def get_cached_messages(self, thread_id: str) -> List[dict]:
        """
        Get cached messages for a thread.

        Args:
            thread_id: Thread to get messages for

        Returns:
            List of cached message dicts
        """
        messages_key = self._key(f"thread:{thread_id}:messages")
        messages = await self.redis.lrange(messages_key, 0, -1)
        return [json.loads(m) for m in messages]

    async def get_active_sessions_count(self) -> int:
        """
        Count active sessions.

        Uses SCAN to count session keys without blocking.

        Returns:
            Number of active sessions
        """
        count = 0
        pattern = self._key("session:*")
        async for _ in self.redis.scan_iter(match=pattern, count=100):
            count += 1
        return count

    async def health_check(self) -> dict:
        """
        Perform health check for session storage.

        Returns:
            Health status dictionary
        """
        try:
            await self.redis.ping()
            active_sessions = await self.get_active_sessions_count()
            return {
                "status": "healthy",
                "active_sessions": active_sessions,
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
            }
```

### Step 3: Create Dependency Injection

Add to `/opt/hx-lang-server/app/dependencies.py`:

```python
"""
FastAPI dependency injection for services.
"""

from typing import AsyncGenerator
from fastapi import Depends
import redis.asyncio as redis

from app.core.redis_config import get_redis_client
from app.core.config import settings
from app.services.session_manager import SessionManager


async def get_redis() -> AsyncGenerator[redis.Redis, None]:
    """Get Redis client dependency."""
    client = await get_redis_client(settings.redis_url)
    yield client


async def get_session_manager(
    redis_client: redis.Redis = Depends(get_redis),
) -> SessionManager:
    """Get SessionManager dependency."""
    return SessionManager(redis_client)
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Session models | `/opt/hx-lang-server/app/models/session.py` | Pydantic models for session data |
| SessionManager | `/opt/hx-lang-server/app/services/session_manager.py` | Session management service |
| Dependencies | `/opt/hx-lang-server/app/dependencies.py` | FastAPI dependency injection |

---

## Verification Steps

### Step 1: Verify Module Imports

```bash
# On hx-lang-server (192.168.10.226)
cd /opt/hx-lang-server
/opt/hx-lang-server/venv/bin/python -c "
from app.services.session_manager import SessionManager
from app.models.session import SessionData
print('SUCCESS: Imports verified')
"
```

### Step 2: Test Session CRUD Operations

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.session_manager import SessionManager

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    sm = SessionManager(client)

    # Test create
    session = await sm.create_session(
        session_id='test-session-001',
        thread_id='test-thread-001',
        user_id='test-user',
    )
    print(f'Created session: {session.session_id}')
    assert session.session_id == 'test-session-001'

    # Test get
    retrieved = await sm.get_session('test-session-001')
    print(f'Retrieved session: {retrieved.session_id}')
    assert retrieved.thread_id == 'test-thread-001'

    # Test update activity
    await sm.update_activity('test-session-001')
    updated = await sm.get_session('test-session-001')
    print(f'Query count after update: {updated.query_count}')
    assert updated.query_count == 1

    # Test cleanup
    deleted = await sm.end_session('test-session-001')
    print(f'Keys deleted: {deleted}')
    assert deleted >= 1

    # Verify deletion
    gone = await sm.get_session('test-session-001')
    assert gone is None

    print('SUCCESS: All SessionManager tests passed')

asyncio.run(test())
"
```

### Step 3: Verify Key Namespace

```bash
# On hx-redis-server (192.168.10.210) or via redis-cli
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*"

# Expected: Keys should use hx-lang-server: prefix
# After test cleanup: No keys should remain
```

### Step 4: Verify TTL Settings

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.services.session_manager import SessionManager

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)
    sm = SessionManager(client)

    # Create session
    await sm.create_session('ttl-test-session', 'ttl-test-thread')

    # Check TTL
    ttl = await client.ttl('hx-lang-server:session:ttl-test-session')
    print(f'Session TTL: {ttl} seconds')
    assert 3500 < ttl <= 3600, f'Expected ~3600, got {ttl}'

    # Cleanup
    await sm.end_session('ttl-test-session')
    print('SUCCESS: TTL verification passed')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] SessionManager class implemented with KEY_PREFIX = "hx-lang-server"
- [ ] Session CRUD operations (create, get, update, delete) working
- [ ] TTL set to 3600 seconds (1 hour) for sessions
- [ ] Activity tracking increments query_count and extends TTL
- [ ] Thread metadata linked to sessions
- [ ] Message caching with fixed size (50 messages)
- [ ] Namespace prefix applied to all keys
- [ ] Health check method returns session statistics

---

## Rollback Procedure

If issues occur:

1. Remove session_manager.py
2. Remove session.py models
3. Revert dependencies.py changes
4. Clean up any test keys in Redis

```bash
# Rollback commands
rm /opt/hx-lang-server/app/services/session_manager.py
rm /opt/hx-lang-server/app/models/session.py
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*" | xargs redis-cli -h hx-redis-server.hx.dev.local DEL
```

---

## Notes

- Hash storage (HSET) is used for sessions to leverage Redis ziplist encoding for memory efficiency
- Pipeline operations ensure atomicity for multi-step updates
- SCAN is used instead of KEYS for production-safe iteration
- Session-to-thread relationship enables bidirectional lookup

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Session Management
