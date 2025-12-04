# Charter Review: Sri (Redis SME)

**Review Date:** 2025-12-01
**Charter Version:** 1.1
**Reviewer Role:** Redis SME - Cache Architecture, Session Management, In-Memory Data Structures

## Executive Summary

The hx-lang-server charter demonstrates a solid understanding of Redis's role in the LangGraph architecture, positioning it correctly for ephemeral state and session caching while delegating durable persistence to PostgreSQL. The dual-persistence strategy (PostgreSQL checkpoints + Redis ephemeral cache) is architecturally sound. However, the charter lacks specific implementation details for Redis session management patterns, connection pooling configuration, TTL strategies, and cache invalidation approaches that are critical for production-grade LangGraph state management.

## Strengths

- **Correct architectural separation**: PostgreSQL for durable checkpoints, Redis for ephemeral session state - this is the canonical pattern for LangGraph deployments
- **Existing infrastructure leverage**: Proper dependency on operational hx-redis-server (192.168.10.210) rather than deploying new infrastructure
- **Technology stack alignment**: redis-py client selection is appropriate and well-supported
- **Agent assignment**: Sri (Redis SME) explicitly assigned to session/cache integration - correct resource allocation
- **State persistence success criteria**: Clear metric defined (conversations persist across service restarts) with validation approach
- **Phased approach**: Redis integration included in Phase 1 (Core LangGraph + RAG), ensuring early validation of cache layer

## Concerns / Risks

### HIGH Severity

1. **Lack of Redis session schema definition**
   - The charter mentions "session caching and ephemeral state" but does not define what data structures will be used (hashes, strings, sorted sets)
   - LangGraph state can be complex with nested objects; improper schema design leads to memory inefficiency
   - **Recommendation**: Specification must define Redis key schema (e.g., `hx-lang:session:{thread_id}`, `hx-lang:cache:{agent}:{query_hash}`)

2. **Missing TTL strategy**
   - No mention of TTL values for ephemeral state, session data, or cached results
   - Without explicit TTL policy, keys accumulate forever leading to memory exhaustion
   - **Recommendation**: Define TTL tiers - session state (24h), response cache (1h), temporary state (15m)

3. **No cache invalidation strategy defined**
   - LangGraph state updates require coordinated cache invalidation
   - Stale cache can cause incorrect agent behavior or state inconsistency
   - **Recommendation**: Define invalidation triggers (state mutation, checkpoint save, explicit API call)

### MEDIUM Severity

4. **Connection pooling configuration absent**
   - redis-py listed but no mention of connection pool size, max connections, or timeout handling
   - LangGraph with multiple concurrent agents requires proper pool configuration to avoid connection starvation
   - **Recommendation**: Specify min 10, max 50 connections with 30-second timeout, health check interval

5. **No Redis HA consideration**
   - Charter assumes single Redis server availability
   - If hx-redis-server fails, all ephemeral state is lost
   - **Recommendation**: Document expected behavior on Redis unavailability (graceful degradation vs hard failure)

6. **Missing cache-aside vs write-through decision**
   - No clarity on caching pattern for LangGraph state
   - Wrong pattern choice impacts consistency guarantees
   - **Recommendation**: Cache-aside pattern for read-heavy agent state, write-through for critical session data

### LOW Severity

7. **No memory budget defined**
   - Redis memory allocation for hx-lang-server workload not specified
   - Without budget, hard to configure maxmemory-policy correctly
   - **Recommendation**: Estimate memory footprint based on expected concurrent sessions

8. **Monitoring integration not specified**
   - No mention of Redis metrics (hit rate, memory usage, connection count) for observability
   - **Recommendation**: Define key metrics to track for operational health

## Recommendations

### Specification Phase Requirements

1. **Define Redis key namespace schema**
   ```
   hx-lang:session:{thread_id}          # Hash - session metadata
   hx-lang:state:{thread_id}:{node}     # String (JSON) - ephemeral node state
   hx-lang:cache:{agent}:{query_hash}   # String - response cache
   hx-lang:rate:{client_id}             # Sorted set - rate limiting (if needed)
   ```

2. **Establish TTL policy matrix**
   | Data Type | TTL | Rationale |
   |-----------|-----|-----------|
   | Session metadata | 24 hours | Align with typical user session duration |
   | Ephemeral node state | 1 hour | Short-term state between checkpoints |
   | Response cache | 15 minutes | Prevent stale LLM responses |
   | Rate limit windows | 1 minute | Sliding window rate limiting |

3. **Document connection pool configuration**
   - Use `redis.ConnectionPool` with blocking connection pool
   - Configure: `max_connections=50`, `timeout=30`, `health_check_interval=30`
   - Implement connection retry with exponential backoff

4. **Specify cache patterns**
   - **Session state**: Write-through (ensure consistency with PostgreSQL checkpoints)
   - **LLM response cache**: Cache-aside with TTL (performance optimization)
   - **Agent routing cache**: Cache-aside with explicit invalidation

5. **Add graceful degradation strategy**
   - If Redis unavailable: fall back to PostgreSQL-only mode (degraded performance)
   - Log warning, continue operation without session cache
   - Alert operators via monitoring system

### Implementation Phase Requirements

6. **Use redis-py async client** for FastAPI integration
   ```python
   import redis.asyncio as redis
   pool = redis.ConnectionPool.from_url(
       "redis://hx-redis-server.hx.dev.local:6379/0",
       max_connections=50,
       decode_responses=True
   )
   ```

7. **Implement hash-based session storage**
   - Use Redis hashes for session metadata (memory efficient with ziplist encoding)
   - Store complex state as JSON strings with proper serialization

8. **Configure eviction policy coordination**
   - Ensure hx-redis-server has `maxmemory-policy allkeys-lru` or `volatile-lru`
   - All hx-lang-server keys should have TTL (use `volatile-lru` for safety)

## Redis Architecture Assessment

### Recommended Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        hx-lang-server                               │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    FastAPI Application                       │   │
│  │                                                              │   │
│  │   ┌──────────────────┐    ┌──────────────────────────────┐  │   │
│  │   │ Session Manager  │    │     LangGraph State Cache     │  │   │
│  │   │ (Write-Through)  │    │      (Cache-Aside + TTL)     │  │   │
│  │   └────────┬─────────┘    └─────────────┬────────────────┘  │   │
│  │            │                             │                   │   │
│  │   ┌────────▼─────────────────────────────▼────────────────┐  │   │
│  │   │          Redis Connection Pool (async)                │  │   │
│  │   │          max_connections=50, timeout=30s              │  │   │
│  │   └────────────────────────┬─────────────────────────────┘  │   │
│  └────────────────────────────┼─────────────────────────────────┘   │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                                ▼
                 ┌──────────────────────────────┐
                 │      hx-redis-server         │
                 │    192.168.10.210:6379       │
                 │                              │
                 │  Database 0: hx-lang-server  │
                 │  Key prefix: hx-lang:*       │
                 │  maxmemory-policy: volatile  │
                 └──────────────────────────────┘
```

### Redis + PostgreSQL Complementary Roles

| Concern | Redis Role | PostgreSQL Role |
|---------|------------|-----------------|
| **LangGraph checkpoints** | Not used | Primary store (langgraph-checkpoint-postgres) |
| **Session metadata** | Primary (fast access) | Backup (audit trail if needed) |
| **Ephemeral agent state** | Primary (TTL-based) | Not stored |
| **Response cache** | Primary (LRU eviction) | Not stored |
| **Conversation history** | Not used | Primary (durable) |
| **Thread/run tracking** | Index/counter | Authoritative source |

### Key Design Decisions Required

1. **Database isolation**: Should hx-lang-server use dedicated Redis database (e.g., DB 1) or share DB 0 with other services?
   - **Recommendation**: Use DB 0 with key prefix `hx-lang:` for operational simplicity

2. **Serialization format**: JSON vs MessagePack for complex state
   - **Recommendation**: JSON for debuggability, MessagePack only if memory/performance critical

3. **Cache stampede prevention**: Multiple concurrent requests for same uncached data
   - **Recommendation**: Implement probabilistic early expiration or distributed locking

## Approval Status

- [ ] Approved as-is
- [x] Approved with minor changes
- [ ] Requires changes before approval
- [ ] Not approved

**Conditions for Approval:**

The charter is approved with the requirement that the specification phase must address:

1. Redis key schema and namespace design
2. TTL policy matrix for all data types
3. Connection pool configuration parameters
4. Cache invalidation strategy
5. Graceful degradation behavior on Redis unavailability

These items are appropriate for the specification phase (not charter level) but must be explicitly planned.

## Additional Notes

### Integration with Existing hx-redis-server

The hx-redis-server (192.168.10.210) is currently configured with:
- RDB + AOF persistence (production-grade)
- maxmemory configured for 75% RAM utilization
- Standard redis.conf with security enabled

**Pre-deployment verification required:**
- Confirm database availability for hx-lang-server workload
- Verify network connectivity from hx-lang-server to hx-redis-server
- Review current memory utilization to ensure capacity for new workload

### Recommended Success Criteria Addition

Consider adding a Redis-specific success metric:

**Redis Cache Effectiveness**
- Metric: Cache hit ratio for session and state lookups
- Target: >80% hit rate after warm-up period
- Validation: Monitor `INFO stats` keyspace_hits/keyspace_misses

---

**Signature:** Sri
**Date:** 2025-12-01
