# Task: Test Redis Connection and Validate Integration

**Task ID**: hx-lang-server-task-048-test-redis-integration
**Phase**: Verification
**Assigned To**: Sri (Redis SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-041 through hx-lang-server-task-047 (All Redis tasks)
**Estimated Time**: 60 minutes

---

## Objective

Execute comprehensive integration tests for all Redis components in hx-lang-server. This task validates that the Redis connection pool, session management, caching, rate limiting, and graceful degradation all work correctly together. Tests should be run against the production Redis server (hx-redis-server.hx.dev.local).

---

## Prerequisites

- [ ] All Redis tasks (041-047) completed
- [ ] Redis server operational at hx-redis-server.hx.dev.local:6379
- [ ] Python virtual environment configured
- [ ] Network connectivity verified

---

## Specification Reference

**From node-spec.md v2.1, Section: Success Criteria:**

> - SC-001: Service responds to `/health` within 2 seconds
> - SC-XXX (proposed): Redis cache hit ratio > 80% for session and LLM response lookups after 1-hour warm-up period

---

## Test Categories

### 1. Connection Pool Tests
- Pool initialization with 50 connections
- Connection reuse
- Pool statistics
- Graceful shutdown

### 2. Session Manager Tests
- Session CRUD operations
- TTL enforcement
- Session-thread linking
- Message caching

### 3. Key Namespace Tests
- All keys use hx-lang-server: prefix
- No key collisions
- Key cleanup

### 4. TTL Strategy Tests
- TTL values match specification
- Sliding expiration works
- TTL monitoring

### 5. Cache Tests
- LLM response caching
- RAG result caching
- Classification caching
- Cache stampede prevention
- Cache invalidation

### 6. Rate Limiting Tests
- 100 requests/minute enforcement
- Sliding window behavior
- Scope isolation

### 7. Graceful Degradation Tests
- Fallback behavior
- Circuit breaker
- Health status reporting

---

## Test Execution Steps

### Step 1: Create Integration Test Script

Create file: `/opt/hx-lang-server/tests/test_redis_integration.py`

```python
"""
Redis Integration Tests for hx-lang-server.

Comprehensive test suite validating all Redis components.
Run against production Redis: hx-redis-server.hx.dev.local:6379
"""

import asyncio
import time
from datetime import datetime
from typing import Dict, List
import redis.asyncio as redis
import structlog

# Import all Redis modules
from app.core.redis_config import (
    create_redis_pool,
    get_redis_client,
    close_redis_pool,
    get_pool_stats,
    REDIS_POOL_CONFIG,
)
from app.core.redis_keys import RedisKeys, KEYS
from app.services.session_manager import SessionManager
from app.services.ttl_manager import TTLManager, TTLMonitor
from app.services.cache_service import (
    LLMResponseCache,
    RAGResultCache,
    QueryClassificationCache,
    CacheStampedePrevention,
    CacheInvalidator,
)
from app.services.rate_limiter import RateLimiter
from app.services.graceful_redis import GracefulRedisClient, RedisStatus

logger = structlog.get_logger(__name__)

# Test configuration
REDIS_URL = "redis://hx-redis-server.hx.dev.local:6379/0"
TEST_PREFIX = "test:"


class TestResult:
    """Container for test results."""

    def __init__(self):
        self.passed: List[str] = []
        self.failed: List[Dict] = []

    def record_pass(self, test_name: str):
        self.passed.append(test_name)
        print(f"  [PASS] {test_name}")

    def record_fail(self, test_name: str, error: str):
        self.failed.append({"test": test_name, "error": error})
        print(f"  [FAIL] {test_name}: {error}")

    def summary(self) -> str:
        total = len(self.passed) + len(self.failed)
        return f"Results: {len(self.passed)}/{total} passed"


class RedisIntegrationTests:
    """
    Redis integration test suite.
    """

    def __init__(self, redis_url: str = REDIS_URL):
        self.redis_url = redis_url
        self.client: redis.Redis = None
        self.results = TestResult()

    async def setup(self):
        """Initialize test environment."""
        self.client = redis.from_url(
            self.redis_url,
            decode_responses=True,
        )
        # Verify connectivity
        await self.client.ping()
        print(f"Connected to Redis at {self.redis_url}")

    async def teardown(self):
        """Cleanup test environment."""
        # Clean up all test keys
        test_pattern = "hx-lang-server:*test*"
        async for key in self.client.scan_iter(match=test_pattern, count=100):
            await self.client.delete(key)
        await self.client.close()
        print("Test cleanup complete")

    async def run_all(self):
        """Run all test categories."""
        await self.setup()

        try:
            print("\n=== Connection Pool Tests ===")
            await self.test_connection_pool()

            print("\n=== Session Manager Tests ===")
            await self.test_session_manager()

            print("\n=== Key Namespace Tests ===")
            await self.test_key_namespace()

            print("\n=== TTL Strategy Tests ===")
            await self.test_ttl_strategy()

            print("\n=== Cache Service Tests ===")
            await self.test_cache_services()

            print("\n=== Rate Limiter Tests ===")
            await self.test_rate_limiter()

            print("\n=== Graceful Degradation Tests ===")
            await self.test_graceful_degradation()

            print("\n" + "=" * 50)
            print(self.results.summary())
            if self.results.failed:
                print("\nFailed tests:")
                for fail in self.results.failed:
                    print(f"  - {fail['test']}: {fail['error']}")

        finally:
            await self.teardown()

        return len(self.results.failed) == 0

    # ==================== Connection Pool Tests ====================

    async def test_connection_pool(self):
        """Test connection pool configuration."""

        # Test 1: Pool creation
        try:
            pool = create_redis_pool(self.redis_url)
            assert pool.max_connections == 50, f"Expected 50, got {pool.max_connections}"
            self.results.record_pass("pool_max_connections_50")
        except Exception as e:
            self.results.record_fail("pool_max_connections_50", str(e))

        # Test 2: Pool statistics
        try:
            stats = await get_pool_stats()
            assert "max_connections" in stats or "status" in stats
            self.results.record_pass("pool_statistics_available")
        except Exception as e:
            self.results.record_fail("pool_statistics_available", str(e))

        # Test 3: Connection reuse
        try:
            client1 = await get_redis_client(self.redis_url)
            await client1.set("test:reuse", "value")
            client2 = await get_redis_client(self.redis_url)
            value = await client2.get("test:reuse")
            assert value == "value"
            await client1.delete("test:reuse")
            self.results.record_pass("connection_reuse")
        except Exception as e:
            self.results.record_fail("connection_reuse", str(e))

    # ==================== Session Manager Tests ====================

    async def test_session_manager(self):
        """Test session management."""
        sm = SessionManager(self.client)

        # Test 1: Create session
        try:
            session = await sm.create_session(
                "test-session-001",
                "test-thread-001",
                user_id="test-user",
            )
            assert session.session_id == "test-session-001"
            assert session.thread_id == "test-thread-001"
            self.results.record_pass("session_create")
        except Exception as e:
            self.results.record_fail("session_create", str(e))

        # Test 2: Get session
        try:
            retrieved = await sm.get_session("test-session-001")
            assert retrieved is not None
            assert retrieved.session_id == "test-session-001"
            self.results.record_pass("session_get")
        except Exception as e:
            self.results.record_fail("session_get", str(e))

        # Test 3: Update activity
        try:
            await sm.update_activity("test-session-001")
            updated = await sm.get_session("test-session-001")
            assert updated.query_count == 1
            self.results.record_pass("session_update_activity")
        except Exception as e:
            self.results.record_fail("session_update_activity", str(e))

        # Test 4: End session
        try:
            deleted = await sm.end_session("test-session-001")
            assert deleted >= 1
            gone = await sm.get_session("test-session-001")
            assert gone is None
            self.results.record_pass("session_end")
        except Exception as e:
            self.results.record_fail("session_end", str(e))

    # ==================== Key Namespace Tests ====================

    async def test_key_namespace(self):
        """Test key namespace configuration."""

        # Test 1: All key methods use prefix
        try:
            keys_to_test = [
                KEYS.session("test"),
                KEYS.thread_messages("test"),
                KEYS.cache_llm("test"),
                KEYS.rate_user("test"),
                KEYS.lock_checkpoint("test"),
            ]
            for key in keys_to_test:
                assert key.startswith("hx-lang-server:"), f"Key {key} missing prefix"
            self.results.record_pass("keys_have_prefix")
        except Exception as e:
            self.results.record_fail("keys_have_prefix", str(e))

        # Test 2: Hash generation is deterministic
        try:
            hash1 = KEYS.generate_hash("test content")
            hash2 = KEYS.generate_hash("test content")
            hash3 = KEYS.generate_hash("different")
            assert hash1 == hash2
            assert hash1 != hash3
            assert len(hash1) == 16
            self.results.record_pass("hash_deterministic")
        except Exception as e:
            self.results.record_fail("hash_deterministic", str(e))

        # Test 3: TTL constants correct
        try:
            assert RedisKeys.TTL_SESSION == 3600
            assert RedisKeys.TTL_LLM_CACHE == 300
            assert RedisKeys.TTL_RAG_CACHE == 600
            assert RedisKeys.TTL_RATE_LIMIT == 60
            self.results.record_pass("ttl_constants_correct")
        except Exception as e:
            self.results.record_fail("ttl_constants_correct", str(e))

    # ==================== TTL Strategy Tests ====================

    async def test_ttl_strategy(self):
        """Test TTL management."""
        ttl_mgr = TTLManager(self.client)

        # Test 1: TTL get/set
        try:
            test_key = KEYS.session("ttl-test")
            await self.client.set(test_key, "value", ex=3600)
            ttl = await ttl_mgr.get_ttl(test_key)
            assert 3500 < ttl <= 3600
            await self.client.delete(test_key)
            self.results.record_pass("ttl_get_set")
        except Exception as e:
            self.results.record_fail("ttl_get_set", str(e))

        # Test 2: TTL extension
        try:
            test_key = KEYS.session("extend-test")
            await self.client.set(test_key, "value", ex=100)  # Low TTL
            extended = await ttl_mgr.maybe_extend_ttl(test_key, 3600)
            assert extended
            new_ttl = await ttl_mgr.get_ttl(test_key)
            assert new_ttl > 3500
            await self.client.delete(test_key)
            self.results.record_pass("ttl_extension")
        except Exception as e:
            self.results.record_fail("ttl_extension", str(e))

    # ==================== Cache Service Tests ====================

    async def test_cache_services(self):
        """Test caching services."""

        # Test 1: LLM cache
        try:
            llm_cache = LLMResponseCache(self.client)
            await llm_cache.set("test-model", "test query", "test response")
            cached = await llm_cache.get("test-model", "test query")
            assert cached == "test response"
            await llm_cache.delete("test-model", "test query")
            self.results.record_pass("llm_cache_set_get")
        except Exception as e:
            self.results.record_fail("llm_cache_set_get", str(e))

        # Test 2: RAG cache
        try:
            rag_cache = RAGResultCache(self.client)
            test_result = {"docs": ["doc1"], "scores": [0.9]}
            await rag_cache.set("test query", test_result)
            cached = await rag_cache.get("test query")
            assert cached == test_result
            self.results.record_pass("rag_cache_set_get")
        except Exception as e:
            self.results.record_fail("rag_cache_set_get", str(e))

        # Test 3: Classification cache
        try:
            class_cache = QueryClassificationCache(self.client)
            await class_cache.set("write code", "code")
            cached = await class_cache.get("write code")
            assert cached == "code"
            self.results.record_pass("classification_cache")
        except Exception as e:
            self.results.record_fail("classification_cache", str(e))

        # Test 4: Cache stampede prevention
        try:
            stampede = CacheStampedePrevention(self.client)
            compute_count = 0

            async def slow_compute():
                nonlocal compute_count
                compute_count += 1
                await asyncio.sleep(0.05)
                return {"result": compute_count}

            cache_key = "hx-lang-server:cache:test:stampede"
            await self.client.delete(cache_key)

            # Launch concurrent requests
            tasks = [
                stampede.get_or_compute(cache_key, slow_compute, 300)
                for _ in range(3)
            ]
            results = await asyncio.gather(*tasks)

            # Should only compute once
            assert compute_count == 1, f"Expected 1 compute, got {compute_count}"
            await self.client.delete(cache_key)
            self.results.record_pass("cache_stampede_prevention")
        except Exception as e:
            self.results.record_fail("cache_stampede_prevention", str(e))

    # ==================== Rate Limiter Tests ====================

    async def test_rate_limiter(self):
        """Test rate limiting."""
        limiter = RateLimiter(self.client)

        # Test 1: Basic rate limiting
        try:
            await limiter.reset("test-ratelimit", scope="user")
            limit = 5
            for i in range(limit):
                allowed, remaining = await limiter.is_allowed(
                    "test-ratelimit", limit=limit, window_seconds=60
                )
                assert allowed, f"Request {i+1} should be allowed"

            # Next request should be denied
            allowed, _ = await limiter.is_allowed(
                "test-ratelimit", limit=limit, window_seconds=60
            )
            assert not allowed, "Request over limit should be denied"

            await limiter.reset("test-ratelimit", scope="user")
            self.results.record_pass("rate_limit_enforcement")
        except Exception as e:
            self.results.record_fail("rate_limit_enforcement", str(e))

        # Test 2: Scope isolation
        try:
            await limiter.reset("scope-test", scope="user")
            await limiter.reset("scope-test", scope="session")

            await limiter.is_allowed("scope-test", limit=5, scope="user")
            user_remaining = await limiter.get_remaining("scope-test", limit=5, scope="user")
            session_remaining = await limiter.get_remaining("scope-test", limit=5, scope="session")

            assert user_remaining == 4
            assert session_remaining == 5

            await limiter.reset("scope-test", scope="user")
            await limiter.reset("scope-test", scope="session")
            self.results.record_pass("rate_limit_scope_isolation")
        except Exception as e:
            self.results.record_fail("rate_limit_scope_isolation", str(e))

    # ==================== Graceful Degradation Tests ====================

    async def test_graceful_degradation(self):
        """Test graceful degradation."""

        # Test 1: Healthy status
        try:
            graceful = GracefulRedisClient(self.client)
            health = await graceful.health_check()
            assert health["status"] == "healthy"
            self.results.record_pass("graceful_healthy_status")
        except Exception as e:
            self.results.record_fail("graceful_healthy_status", str(e))

        # Test 2: Fallback with working Redis
        try:
            graceful = GracefulRedisClient(self.client)
            result = await graceful.execute_with_fallback(
                lambda: self.client.get("nonexistent"),
                fallback_value="fallback",
                operation_name="test_get",
            )
            # Should return None (key doesn't exist), not fallback
            assert result is None
            self.results.record_pass("graceful_returns_actual_result")
        except Exception as e:
            self.results.record_fail("graceful_returns_actual_result", str(e))

        # Test 3: Optional operations
        try:
            graceful = GracefulRedisClient(self.client)
            success = await graceful.execute_optional(
                lambda: self.client.set("test:optional", "value", ex=60),
                operation_name="test_optional",
            )
            assert success
            await self.client.delete("test:optional")
            self.results.record_pass("graceful_optional_operations")
        except Exception as e:
            self.results.record_fail("graceful_optional_operations", str(e))


async def main():
    """Run integration tests."""
    print("=" * 50)
    print("HX-LANG-SERVER REDIS INTEGRATION TESTS")
    print(f"Target: {REDIS_URL}")
    print(f"Time: {datetime.utcnow().isoformat()}")
    print("=" * 50)

    tests = RedisIntegrationTests()
    success = await tests.run_all()

    return 0 if success else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
```

### Step 2: Run Integration Tests

```bash
# On hx-lang-server (192.168.10.226)
cd /opt/hx-lang-server
/opt/hx-lang-server/venv/bin/python tests/test_redis_integration.py
```

### Step 3: Verify Results

Expected output should show all tests passing:

```
==================================================
HX-LANG-SERVER REDIS INTEGRATION TESTS
Target: redis://hx-redis-server.hx.dev.local:6379/0
Time: 2025-12-04T...
==================================================
Connected to Redis at redis://hx-redis-server.hx.dev.local:6379/0

=== Connection Pool Tests ===
  [PASS] pool_max_connections_50
  [PASS] pool_statistics_available
  [PASS] connection_reuse

=== Session Manager Tests ===
  [PASS] session_create
  [PASS] session_get
  [PASS] session_update_activity
  [PASS] session_end

... (all tests)

==================================================
Results: X/X passed
Test cleanup complete
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Integration test script | `/opt/hx-lang-server/tests/test_redis_integration.py` | Comprehensive test suite |
| Test execution report | `/opt/hx-lang-server/tests/reports/redis-integration-report.txt` | Test results |

---

## Verification Steps

### Step 1: Manual Connectivity Test

```bash
# From hx-lang-server (192.168.10.226)
redis-cli -h hx-redis-server.hx.dev.local ping
# Expected: PONG
```

### Step 2: Run Full Test Suite

```bash
# On hx-lang-server
cd /opt/hx-lang-server
/opt/hx-lang-server/venv/bin/python tests/test_redis_integration.py
```

### Step 3: Verify Key Cleanup

```bash
# Check no test keys remain
redis-cli -h hx-redis-server.hx.dev.local KEYS "hx-lang-server:*test*"
# Expected: (empty list)
```

### Step 4: Generate Test Report

```bash
# Generate report
cd /opt/hx-lang-server
mkdir -p tests/reports
/opt/hx-lang-server/venv/bin/python tests/test_redis_integration.py > tests/reports/redis-integration-report.txt 2>&1
echo "Exit code: $?" >> tests/reports/redis-integration-report.txt
cat tests/reports/redis-integration-report.txt
```

---

## Acceptance Criteria

- [ ] All connection pool tests pass
- [ ] All session manager tests pass
- [ ] All key namespace tests pass
- [ ] All TTL strategy tests pass
- [ ] All cache service tests pass
- [ ] All rate limiter tests pass
- [ ] All graceful degradation tests pass
- [ ] Test cleanup removes all test keys
- [ ] Test report generated and saved

---

## Rollback Procedure

If tests fail:

1. Review failed test output
2. Fix identified issues in respective modules
3. Re-run tests
4. If persistent failures, check Redis server health

```bash
# Check Redis server health
redis-cli -h hx-redis-server.hx.dev.local INFO server
redis-cli -h hx-redis-server.hx.dev.local INFO memory
```

---

## Notes

- Tests run against production Redis but use test: prefixed keys
- All test keys are cleaned up after test completion
- Failed tests provide specific error messages for debugging
- Test suite can be run repeatedly safely
- Integration tests validate real Redis operations, not mocks

---

**Created By:** Sri (Redis SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Success Criteria
