# Task Contribution: Sri (Redis SME)

**Contribution Date:** 2025-12-04
**Work Stream:** 5 - Redis Integration
**Task Range:** 041-048
**Specification Reference:** node-spec.md v2.1 (APPROVED)

---

## Executive Summary

This contribution provides 8 comprehensive deployment tasks for Work Stream 5: Redis Integration. These tasks implement production-grade Redis integration for hx-lang-server, including connection pooling, session management, caching, rate limiting, and graceful degradation patterns.

All implementations align with the approved specification v2.1 and incorporate recommendations from my earlier specification contribution (50 connection pool, namespace prefix, TTL strategies).

---

## Tasks Created

| Task ID | Description | Dependencies | Est. Time |
|---------|-------------|--------------|-----------|
| 041 | Configure Redis Connection Pool | 021, 022 | 45 min |
| 042 | Implement SessionManager Class | 041 | 60 min |
| 043 | Configure Redis Key Namespace | 041, 042 | 30 min |
| 044 | Implement TTL Strategy | 043 | 45 min |
| 045 | Implement LLM Response Cache | 043, 044 | 45 min |
| 046 | Implement Rate Limiting | 043 | 45 min |
| 047 | Implement Graceful Degradation | 041, 042 | 45 min |
| 048 | Test Redis Integration | 041-047 | 60 min |

**Total Estimated Time:** 6.25 hours

---

## Task Summaries

### Task 041: Configure Redis Connection Pool

**Objective:** Configure production-grade Redis connection pool with 50 max connections.

**Key Deliverables:**
- `/opt/hx-lang-server/app/core/redis_config.py` - Connection pool configuration
- Pool singleton pattern for connection reuse
- Exponential backoff retry strategy
- Health check interval configuration

**Critical Configuration:**
```python
REDIS_POOL_CONFIG = {
    "max_connections": 50,
    "socket_timeout": 5.0,
    "socket_connect_timeout": 5.0,
    "health_check_interval": 30,
    "retry_on_timeout": True,
}
```

---

### Task 042: Implement SessionManager Class

**Objective:** Implement session management with Redis hashes for memory efficiency.

**Key Deliverables:**
- `/opt/hx-lang-server/app/models/session.py` - SessionData Pydantic model
- `/opt/hx-lang-server/app/services/session_manager.py` - SessionManager class
- Session CRUD operations with KEY_PREFIX
- Thread metadata linking
- Message caching (last 50 messages)

**Key Features:**
- Hash storage with ziplist encoding (memory efficient)
- Pipeline operations for atomicity
- Activity tracking with query_count
- Session-to-thread bidirectional lookup

---

### Task 043: Configure Redis Key Namespace

**Objective:** Implement centralized key generation with `hx-lang-server:` namespace prefix.

**Key Deliverables:**
- `/opt/hx-lang-server/app/core/redis_keys.py` - RedisKeys class
- `/opt/hx-lang-server/docs/redis-key-schema.md` - Documentation

**Key Schema:**
```
hx-lang-server:
├── session:{session_id}          # Hash - TTL 1 hour
├── thread:{thread_id}:messages   # List - TTL 1 hour
├── thread:{thread_id}:state      # String - TTL 30 min
├── cache:llm:{hash}              # String - TTL 5 min
├── cache:rag:{hash}              # String - TTL 10 min
├── cache:classify:{hash}         # String - TTL 30 min
├── rate:user:{user_id}           # Sorted Set - TTL 1 min
└── lock:checkpoint:{thread_id}   # String - TTL 30 sec
```

---

### Task 044: Implement TTL Strategy

**Objective:** Implement comprehensive TTL management with sliding expiration.

**Key Deliverables:**
- `/opt/hx-lang-server/app/services/ttl_manager.py` - TTLManager class
- `/opt/hx-lang-server/app/middleware/ttl_middleware.py` - FastAPI middleware

**Key Features:**
- Sliding expiration (extend at 25% remaining)
- TTLMonitor for finding keys without TTL
- Automatic TTL fix for orphaned keys
- Session TTL extension on activity

---

### Task 045: Implement LLM Response Cache

**Objective:** Implement caching for LLM, RAG, and classification results.

**Key Deliverables:**
- `/opt/hx-lang-server/app/services/cache_service.py` - All cache implementations

**Cache Types:**
| Cache | TTL | Key Hash |
|-------|-----|----------|
| LLMResponseCache | 5 min | model + query + config |
| RAGResultCache | 10 min | mode + query |
| QueryClassificationCache | 30 min | query |

**Key Features:**
- Semantic key generation (SHA256 truncated to 16 chars)
- Cache stampede prevention with distributed locking
- Cache invalidation for model/RAG updates
- Cache metrics collection

---

### Task 046: Implement Rate Limiting

**Objective:** Implement sliding window rate limiting with Redis sorted sets.

**Key Deliverables:**
- `/opt/hx-lang-server/app/services/rate_limiter.py` - RateLimiter class
- `/opt/hx-lang-server/app/middleware/rate_limit_middleware.py` - FastAPI middleware

**Default Limits:**
- 100 requests/minute per user (from specification)
- Per-endpoint customization available
- 429 response with Retry-After header

**Key Features:**
- Sliding window algorithm (accurate, O(log N))
- Scope isolation (user, session, endpoint)
- Rate limit headers in responses
- Reset functionality for testing/admin

---

### Task 047: Implement Graceful Degradation

**Objective:** Implement fallback patterns for Redis unavailability.

**Key Deliverables:**
- `/opt/hx-lang-server/app/services/graceful_redis.py` - GracefulRedisClient class

**Degradation Behavior:**
| Component | Healthy | Degraded/Unavailable |
|-----------|---------|----------------------|
| Session get | Return session | Return None (fall to PostgreSQL) |
| Cache get | Return cached | Return None (invoke backend) |
| Rate limit | Enforce limit | Allow all (log warning) |
| Health check | Report healthy | Report degraded |

**Key Features:**
- Circuit breaker pattern (5 failures opens)
- Automatic recovery detection (half-open state)
- Three status levels: healthy, degraded, unavailable
- Logging for all fallback events

---

### Task 048: Test Redis Integration

**Objective:** Validate all Redis components with comprehensive integration tests.

**Key Deliverables:**
- `/opt/hx-lang-server/tests/test_redis_integration.py` - Test suite
- `/opt/hx-lang-server/tests/reports/redis-integration-report.txt` - Results

**Test Categories:**
1. Connection Pool Tests (3 tests)
2. Session Manager Tests (4 tests)
3. Key Namespace Tests (3 tests)
4. TTL Strategy Tests (2 tests)
5. Cache Service Tests (4 tests)
6. Rate Limiter Tests (2 tests)
7. Graceful Degradation Tests (3 tests)

**Total:** 21+ test cases

---

## Dependencies

### Upstream Dependencies (from other work streams)

| Task | Work Stream | Agent | Description |
|------|-------------|-------|-------------|
| 021 | 3 - Core Framework | Sophia | Python virtual environment |
| 022 | 3 - Core Framework | Sophia | Python dependencies (redis>=5.0.0) |

### Downstream Dependencies (other work streams depend on Redis)

| Work Stream | Tasks | Agent | Dependency |
|-------------|-------|-------|------------|
| 6 - LangGraph Agents | 051-070 | Sophia | Session caching |
| 10 - FastAPI | 101-120 | Bob | Rate limiting middleware |
| 12 - Logging | 131-140 | William | Health check integration |

---

## Critical Implementation Notes

### 1. Connection Pool Sizing

The 50-connection pool was sized for:
- 10 concurrent agent sessions (specification)
- 3-5 Redis operations per API request
- Headroom for burst traffic

```
Calculation: 10 sessions x 5 ops/request = 50 connections
```

### 2. Namespace Isolation

All keys use `hx-lang-server:` prefix per Alex Rivera's architecture review:
- Prevents collision with other services using same Redis
- Enables key pattern scanning for monitoring
- Supports future multi-tenant scenarios

### 3. Graceful Degradation Priority

When Redis is unavailable:
1. **Session Management** - Falls back to PostgreSQL checkpoints
2. **Caching** - Bypasses cache, calls backend directly
3. **Rate Limiting** - Disabled (allows all requests)
4. **Service** - Continues in degraded mode

### 4. TTL Enforcement

All keys MUST have TTL to prevent memory leaks:
- TTLMonitor scans for orphaned keys
- Default TTL applied to unknown key patterns
- Sliding expiration for active sessions

---

## Quality Assurance

### Code Patterns Used

1. **Cache-Aside Pattern** - Check cache, fetch on miss, store in cache
2. **Circuit Breaker Pattern** - Prevent cascade failures
3. **Sliding Window Rate Limiting** - Accurate request counting
4. **Distributed Locking** - Cache stampede prevention

### Production-Ready Features

- Structured logging with structlog
- Comprehensive error handling
- Type hints throughout
- Pydantic models for data validation
- Dependency injection for testing

### Test Coverage

- Unit tests in each task verification section
- Integration tests in task-048
- All tests use SCAN (not KEYS) for production safety
- Test cleanup removes all test keys

---

## Files Created

| Path | Description |
|------|-------------|
| `tasks/hx-lang-server-task-041-configure-redis-connection-pool.md` | Connection pool task |
| `tasks/hx-lang-server-task-042-implement-session-manager.md` | Session manager task |
| `tasks/hx-lang-server-task-043-configure-redis-key-namespace.md` | Key namespace task |
| `tasks/hx-lang-server-task-044-implement-ttl-strategy.md` | TTL strategy task |
| `tasks/hx-lang-server-task-045-implement-llm-response-cache.md` | Caching task |
| `tasks/hx-lang-server-task-046-implement-rate-limiting.md` | Rate limiting task |
| `tasks/hx-lang-server-task-047-implement-graceful-degradation.md` | Degradation task |
| `tasks/hx-lang-server-task-048-test-redis-integration.md` | Integration tests task |

---

## Alignment with Specification

All tasks align with node-spec.md v2.1:

| Spec Section | Task Coverage |
|--------------|---------------|
| Redis Integration (Lines 383-429) | Tasks 041, 042 |
| Redis Key Schema (Lines 268-278) | Task 043 |
| TTL values from key schema | Task 044 |
| Session Management pattern | Task 042 |
| Rate Limiting (Line 718) | Task 046 |
| Operational Requirements (Lines 56-59) | Task 047 |
| Success Criteria | Task 048 |

---

## Recommendations for Agent Zero

1. **Parallel Execution:** Tasks 044, 045, 046 can execute in parallel after 043 completes
2. **Integration Points:** Coordinate with Sophia (LangGraph) for session integration
3. **Testing Order:** Task 048 should run after all other Redis tasks complete
4. **Monitoring:** Consider adding Prometheus metrics export (future enhancement)

---

**Signature:** Sri (Redis SME)
**Date:** 2025-12-04
**Work Stream:** 5 - Redis Integration
**Tasks Created:** 8 (041-048)
