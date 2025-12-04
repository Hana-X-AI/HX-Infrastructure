# Task: Configure Redis Key Namespace

**Task ID**: hx-lang-server-task-043-configure-redis-key-namespace
**Phase**: Installation
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-041 (Redis connection pool), hx-lang-server-task-042 (SessionManager)
**Estimated Time**: 30 minutes

---

## Objective

Configure and document the Redis key namespace schema for hx-lang-server. All keys MUST use the `hx-lang-server:` prefix for namespace isolation as specified by Alex Rivera's architecture review. This task ensures consistent key naming across all Redis operations.

---

## Prerequisites

- [ ] Redis connection pool configured (task-041)
- [ ] SessionManager implemented with KEY_PREFIX (task-042)
- [ ] Understanding of Redis key naming conventions

---

## Specification Reference

**From node-spec.md v2.1, Section: Redis Key Schema (Lines 268-278)**

**Namespace Prefix:** All keys MUST use `hx-lang-server:` prefix for namespace isolation (per Alex Rivera's architecture review).

| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:session:{session_id}` | Active session data | 1 hour |
| `hx-lang-server:thread:{thread_id}:messages` | Message cache | 1 hour |
| `hx-lang-server:cache:llm:{hash}` | LLM response cache | 5 minutes |
| `hx-lang-server:cache:rag:{hash}` | RAG result cache | 10 minutes |
| `hx-lang-server:ratelimit:{user_id}` | Rate limiting | 1 minute |
| `hx-lang-server:classification:{hash}` | Query classification cache | 30 minutes |

---

## Implementation Steps

### Step 1: Create Key Schema Constants Module

Create file: `/opt/hx-lang-server/app/core/redis_keys.py`

```python
"""
Redis key schema constants for hx-lang-server.

All keys use the 'hx-lang-server:' namespace prefix per Alex Rivera's
architecture review. This module provides centralized key generation
and documentation of the key schema.

Key Schema:
-----------
hx-lang-server:
├── session:{session_id}           # Hash - session metadata and state
├── thread:{thread_id}:            # Thread-level namespace
│   ├── messages                   # List - message cache (last 50)
│   ├── state                      # String (JSON) - ephemeral agent state
│   └── meta                       # Hash - thread metadata
├── cache:                         # Cache namespace
│   ├── llm:{hash}                 # String - LLM response cache
│   ├── rag:{hash}                 # String - RAG result cache
│   └── classify:{hash}            # String - query classification cache
├── rate:                          # Rate limiting namespace
│   ├── user:{user_id}             # Sorted set - per-user rate limiting
│   └── session:{session_id}       # Sorted set - per-session rate limiting
└── lock:                          # Distributed locking namespace
    ├── checkpoint:{thread_id}     # String - checkpoint write lock
    └── cache:{hash}               # String - cache stampede prevention
"""

import hashlib
from typing import Optional


# Namespace prefix per Alex Rivera's architecture review
KEY_PREFIX = "hx-lang-server"


class RedisKeys:
    """
    Centralized Redis key generation for hx-lang-server.

    All methods return fully-qualified keys with the namespace prefix.
    """

    # TTL values in seconds (from specification)
    TTL_SESSION = 3600        # 1 hour
    TTL_THREAD = 3600         # 1 hour
    TTL_STATE = 1800          # 30 minutes
    TTL_LLM_CACHE = 300       # 5 minutes
    TTL_RAG_CACHE = 600       # 10 minutes
    TTL_CLASSIFY_CACHE = 1800  # 30 minutes
    TTL_RATE_LIMIT = 60       # 1 minute
    TTL_LOCK_CHECKPOINT = 30  # 30 seconds
    TTL_LOCK_CACHE = 10       # 10 seconds

    @staticmethod
    def _prefix(suffix: str) -> str:
        """Add namespace prefix to key suffix."""
        return f"{KEY_PREFIX}:{suffix}"

    # Session keys
    @classmethod
    def session(cls, session_id: str) -> str:
        """Generate session key."""
        return cls._prefix(f"session:{session_id}")

    # Thread keys
    @classmethod
    def thread_messages(cls, thread_id: str) -> str:
        """Generate thread messages cache key."""
        return cls._prefix(f"thread:{thread_id}:messages")

    @classmethod
    def thread_state(cls, thread_id: str) -> str:
        """Generate thread ephemeral state key."""
        return cls._prefix(f"thread:{thread_id}:state")

    @classmethod
    def thread_meta(cls, thread_id: str) -> str:
        """Generate thread metadata key."""
        return cls._prefix(f"thread:{thread_id}:meta")

    # Cache keys
    @classmethod
    def cache_llm(cls, content_hash: str) -> str:
        """Generate LLM response cache key."""
        return cls._prefix(f"cache:llm:{content_hash}")

    @classmethod
    def cache_rag(cls, content_hash: str) -> str:
        """Generate RAG result cache key."""
        return cls._prefix(f"cache:rag:{content_hash}")

    @classmethod
    def cache_classify(cls, content_hash: str) -> str:
        """Generate query classification cache key."""
        return cls._prefix(f"cache:classify:{content_hash}")

    # Rate limiting keys
    @classmethod
    def rate_user(cls, user_id: str) -> str:
        """Generate per-user rate limit key."""
        return cls._prefix(f"rate:user:{user_id}")

    @classmethod
    def rate_session(cls, session_id: str) -> str:
        """Generate per-session rate limit key."""
        return cls._prefix(f"rate:session:{session_id}")

    # Lock keys
    @classmethod
    def lock_checkpoint(cls, thread_id: str) -> str:
        """Generate checkpoint lock key."""
        return cls._prefix(f"lock:checkpoint:{thread_id}")

    @classmethod
    def lock_cache(cls, cache_key_hash: str) -> str:
        """Generate cache stampede prevention lock key."""
        return cls._prefix(f"lock:cache:{cache_key_hash}")

    # Utility methods
    @staticmethod
    def generate_hash(content: str) -> str:
        """
        Generate deterministic hash for cache keys.

        Uses SHA256 truncated to 16 characters for reasonable
        uniqueness with compact key size.

        Args:
            content: Content to hash

        Returns:
            16-character hex hash
        """
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    @classmethod
    def cache_llm_for_query(cls, model: str, query: str, config: Optional[dict] = None) -> str:
        """
        Generate LLM cache key for a specific query.

        Args:
            model: Model name (e.g., "gemma3:27b")
            query: User query
            config: Optional configuration dict

        Returns:
            Full cache key
        """
        import json
        content = f"{model}:{query}:{json.dumps(config or {}, sort_keys=True)}"
        content_hash = cls.generate_hash(content)
        return cls.cache_llm(content_hash)

    @classmethod
    def cache_rag_for_query(cls, query: str, mode: str = "hybrid") -> str:
        """
        Generate RAG cache key for a specific query.

        Args:
            query: RAG query
            mode: Query mode (local, global, hybrid, mix)

        Returns:
            Full cache key
        """
        content = f"{mode}:{query}"
        content_hash = cls.generate_hash(content)
        return cls.cache_rag(content_hash)

    @classmethod
    def cache_classify_for_query(cls, query: str) -> str:
        """
        Generate classification cache key for a query.

        Args:
            query: Query to classify

        Returns:
            Full cache key
        """
        content_hash = cls.generate_hash(query)
        return cls.cache_classify(content_hash)


# Convenience aliases
KEYS = RedisKeys


def get_all_keys_for_session(session_id: str, thread_id: str) -> list[str]:
    """
    Get all Redis keys associated with a session.

    Useful for session cleanup operations.

    Args:
        session_id: Session identifier
        thread_id: Associated thread identifier

    Returns:
        List of all keys to delete
    """
    return [
        RedisKeys.session(session_id),
        RedisKeys.thread_messages(thread_id),
        RedisKeys.thread_state(thread_id),
        RedisKeys.thread_meta(thread_id),
        RedisKeys.rate_session(session_id),
    ]
```

### Step 2: Update SessionManager to Use RedisKeys

Update `/opt/hx-lang-server/app/services/session_manager.py`:

```python
# At the top, add import:
from app.core.redis_keys import RedisKeys, KEYS

# Replace hardcoded key construction with RedisKeys methods:
# Before: self._key(f"session:{session_id}")
# After:  KEYS.session(session_id)

# Example update for create_session:
async def create_session(self, session_id: str, thread_id: str, ...):
    ...
    session_key = KEYS.session(session_id)
    ...
    thread_meta_key = KEYS.thread_meta(thread_id)
    ...
```

### Step 3: Document Key Schema in Configuration

Create file: `/opt/hx-lang-server/docs/redis-key-schema.md`

```markdown
# Redis Key Schema: hx-lang-server

## Overview

All Redis keys for hx-lang-server use the `hx-lang-server:` namespace prefix
for isolation per Alex Rivera's architecture review (node-spec.md v2.1).

## Key Patterns

### Session Keys

| Key | Type | Purpose | TTL |
|-----|------|---------|-----|
| `hx-lang-server:session:{session_id}` | Hash | Session metadata | 1 hour |

Fields:
- `session_id`: Unique identifier
- `thread_id`: Associated LangGraph thread
- `user_id`: Optional user identifier
- `created_at`: ISO 8601 timestamp
- `last_activity`: ISO 8601 timestamp
- `query_count`: Number of queries
- `metadata`: JSON string

### Thread Keys

| Key | Type | Purpose | TTL |
|-----|------|---------|-----|
| `hx-lang-server:thread:{thread_id}:messages` | List | Message cache (last 50) | 1 hour |
| `hx-lang-server:thread:{thread_id}:state` | String | Ephemeral agent state (JSON) | 30 min |
| `hx-lang-server:thread:{thread_id}:meta` | Hash | Thread metadata | 1 hour |

### Cache Keys

| Key | Type | Purpose | TTL |
|-----|------|---------|-----|
| `hx-lang-server:cache:llm:{hash}` | String | LLM response cache | 5 min |
| `hx-lang-server:cache:rag:{hash}` | String | RAG result cache | 10 min |
| `hx-lang-server:cache:classify:{hash}` | String | Query classification | 30 min |

Hash generation: SHA256 truncated to 16 characters.

### Rate Limiting Keys

| Key | Type | Purpose | TTL |
|-----|------|---------|-----|
| `hx-lang-server:rate:user:{user_id}` | Sorted Set | Per-user rate limiting | 1 min |
| `hx-lang-server:rate:session:{session_id}` | Sorted Set | Per-session rate limiting | 1 min |

### Lock Keys

| Key | Type | Purpose | TTL |
|-----|------|---------|-----|
| `hx-lang-server:lock:checkpoint:{thread_id}` | String | Checkpoint write lock | 30 sec |
| `hx-lang-server:lock:cache:{hash}` | String | Cache stampede prevention | 10 sec |

## Usage Examples

```python
from app.core.redis_keys import KEYS

# Session key
key = KEYS.session("abc123")
# Result: "hx-lang-server:session:abc123"

# LLM cache key for query
key = KEYS.cache_llm_for_query("gemma3:27b", "What is Python?")
# Result: "hx-lang-server:cache:llm:a1b2c3d4e5f67890"

# Rate limit key
key = KEYS.rate_user("user-001")
# Result: "hx-lang-server:rate:user:user-001"
```

## Monitoring

To monitor hx-lang-server keys:

```bash
# Count all keys
redis-cli KEYS "hx-lang-server:*" | wc -l

# List session keys
redis-cli KEYS "hx-lang-server:session:*"

# Check specific key TTL
redis-cli TTL "hx-lang-server:session:abc123"

# Monitor key operations (development only)
redis-cli MONITOR | grep "hx-lang-server"
```

## Cleanup

To remove all hx-lang-server keys (use with caution):

```bash
redis-cli KEYS "hx-lang-server:*" | xargs redis-cli DEL
```
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Redis keys module | `/opt/hx-lang-server/app/core/redis_keys.py` | Centralized key generation |
| Key schema docs | `/opt/hx-lang-server/docs/redis-key-schema.md` | Documentation |
| Updated SessionManager | `/opt/hx-lang-server/app/services/session_manager.py` | Use RedisKeys |

---

## Verification Steps

### Step 1: Verify Key Generation

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
from app.core.redis_keys import KEYS

# Test key generation
assert KEYS.session('abc123') == 'hx-lang-server:session:abc123'
assert KEYS.thread_messages('thread-1') == 'hx-lang-server:thread:thread-1:messages'
assert KEYS.cache_llm('hash123') == 'hx-lang-server:cache:llm:hash123'
assert KEYS.rate_user('user-1') == 'hx-lang-server:rate:user:user-1'
assert KEYS.lock_checkpoint('thread-1') == 'hx-lang-server:lock:checkpoint:thread-1'

print('SUCCESS: All key patterns verified')
"
```

### Step 2: Verify TTL Constants

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
from app.core.redis_keys import RedisKeys

assert RedisKeys.TTL_SESSION == 3600, 'Session TTL should be 1 hour'
assert RedisKeys.TTL_LLM_CACHE == 300, 'LLM cache TTL should be 5 minutes'
assert RedisKeys.TTL_RAG_CACHE == 600, 'RAG cache TTL should be 10 minutes'
assert RedisKeys.TTL_RATE_LIMIT == 60, 'Rate limit TTL should be 1 minute'

print('SUCCESS: All TTL constants verified')
"
```

### Step 3: Verify Hash Generation

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
from app.core.redis_keys import KEYS

# Test deterministic hash generation
hash1 = KEYS.generate_hash('test query')
hash2 = KEYS.generate_hash('test query')
hash3 = KEYS.generate_hash('different query')

assert hash1 == hash2, 'Same input should produce same hash'
assert hash1 != hash3, 'Different input should produce different hash'
assert len(hash1) == 16, 'Hash should be 16 characters'

print(f'Hash example: {hash1}')
print('SUCCESS: Hash generation verified')
"
```

### Step 4: Verify Namespace Prefix on Actual Keys

```bash
# On hx-lang-server (192.168.10.226)
/opt/hx-lang-server/venv/bin/python -c "
import asyncio
import redis.asyncio as redis
from app.core.redis_keys import KEYS

async def test():
    client = redis.from_url('redis://hx-redis-server.hx.dev.local:6379/0', decode_responses=True)

    # Create a test key using KEYS module
    test_key = KEYS.session('namespace-test')
    await client.set(test_key, 'test', ex=60)

    # Verify key has correct prefix
    assert test_key.startswith('hx-lang-server:'), 'Key must have namespace prefix'

    # Verify key exists in Redis
    exists = await client.exists(test_key)
    assert exists, 'Key should exist in Redis'

    # Cleanup
    await client.delete(test_key)

    print('SUCCESS: Namespace prefix verified in Redis')

asyncio.run(test())
"
```

---

## Acceptance Criteria

- [ ] RedisKeys class provides methods for all key patterns
- [ ] All keys use `hx-lang-server:` namespace prefix
- [ ] TTL constants match specification values
- [ ] Hash generation is deterministic and 16 characters
- [ ] SessionManager updated to use RedisKeys
- [ ] Documentation created for key schema
- [ ] Verification tests pass

---

## Rollback Procedure

If issues occur:

1. Revert redis_keys.py
2. Revert SessionManager changes
3. Remove documentation file

```bash
# Rollback commands
rm /opt/hx-lang-server/app/core/redis_keys.py
rm /opt/hx-lang-server/docs/redis-key-schema.md
git checkout /opt/hx-lang-server/app/services/session_manager.py
```

---

## Notes

- Namespace prefix ensures hx-lang-server keys don't conflict with other services using the same Redis instance
- 16-character SHA256 hash provides sufficient uniqueness while keeping keys compact
- Centralized key generation prevents typos and ensures consistency
- TTL constants in one place simplify configuration changes

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: Redis Key Schema
**Architecture Review:** Alex Rivera - namespace prefix requirement
