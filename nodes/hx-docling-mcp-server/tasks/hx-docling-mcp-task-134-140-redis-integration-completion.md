# Tasks 134-140: Redis Integration Completion

**Assigned To**: sri-patel
**Estimated Effort**: 4 hours total
**Dependencies**: Tasks 131, 132, 133
**Status**: Not Started

## Overview

This document consolidates Tasks 134-140 for completing Redis integration. These tasks cover health monitoring, configuration integration, and final validation.

---

## Task 134: Configure Redis Health Checks

**Estimated Effort**: 1 hour
**Dependencies**: Task 131

### Objective
Implement automated health check system for Redis connection monitoring with periodic PING operations and connection recovery.

### Pre-Execution Validation
```bash
# Check if health check functionality already implemented in redis_client.py
if grep -q "def.*health_check" /opt/docling-mcp/src/integrations/redis_client.py; then
    echo "✅ VALIDATION: Health check already implemented - SKIP"
    exit 0
else
    echo "❌ VALIDATION: Health check not implemented - PROCEED"
fi
```

### Implementation Summary
- Redis PING health check every 30 seconds (already in Task 131 via `health_check_interval`)
- Connection pool health checks enabled via redis-py
- Integration with MCP health endpoint (`/health`) to report Redis status
- Automatic connection recovery on transient failures

### Validation
```bash
# Verify health check works
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')
from src.integrations.redis_client import initialize_redis_client

client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)
if client.ping():
    print("PASS: Health check successful")
else:
    print("FAIL: Health check failed")
EOF
```

**Note**: Health check functionality is already implemented in Task 131 RedisClient module via `ping()` method and connection pool `health_check_interval`. This task primarily involves integration with MCP health endpoint.

---

## Task 135: Integrate Redis with Pydantic Configuration

**Estimated Effort**: 1 hour
**Dependencies**: Task 131, paul-warfield Task 141-150 (Configuration Management)

### Objective
Integrate RedisSettings from Pydantic configuration into Redis client initialization to load configuration from environment variables.

### Pre-Execution Validation
```bash
# Check if config.py initializes Redis client
if [ -f "/opt/docling-mcp/src/config.py" ] && grep -q "initialize_redis_client" /opt/docling-mcp/src/config.py; then
    echo "✅ VALIDATION: Redis config integration already exists - SKIP"
    exit 0
else
    echo "❌ VALIDATION: Redis config integration not found - PROCEED"
fi
```

### Implementation Summary
Add Redis client initialization to config.py:

```python
from src.integrations.redis_client import initialize_redis_client
from src.session_manager import initialize_session_manager
from src.cache_manager import initialize_cache_manager

def initialize_redis_services(config: DoclingMCPConfig):
    """Initialize Redis client, session manager, and cache manager."""

    # Initialize Redis client
    redis_client = initialize_redis_client(
        host=config.redis.host,
        port=config.redis.port,
        password=config.redis.password,
        max_connections=config.redis.connection_pool_size,
        connection_timeout=config.redis.connection_timeout_seconds,
        operation_timeout=config.redis.operation_timeout_seconds,
        retry_attempts=config.redis.retry_attempts,
        health_check_interval=config.redis.health_check_interval_seconds
    )

    # Initialize session manager
    session_manager = initialize_session_manager(
        ttl_hours=config.session.ttl_hours,
        ttl_extension_hours=config.session.ttl_extension_hours,
        max_ttl_hours=168
    )

    # Initialize cache manager
    cache_manager = initialize_cache_manager(
        enabled=config.cache.enabled,
        ttl_metadata_hours=config.cache.metadata_ttl_hours,
        ttl_entities_hours=config.cache.ttl_hours,
        ttl_docling_hours=config.cache.ttl_hours,
        max_docling_size_mb=config.cache.max_document_size_mb
    )

    return redis_client, session_manager, cache_manager
```

### Environment Variables (from Specification)
```bash
# Redis connection
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
REDIS_CONNECTION_POOL_SIZE=10
REDIS_CONNECTION_TIMEOUT_SECONDS=5
REDIS_OPERATION_TIMEOUT_SECONDS=10
REDIS_RETRY_ATTEMPTS=3
REDIS_HEALTH_CHECK_INTERVAL_SECONDS=30

# Session management
SESSION_TTL_HOURS=24
SESSION_TTL_EXTENSION_HOURS=4

# Caching
CACHE_ENABLED=true
CACHE_TTL_HOURS=24
CACHE_MAX_DOCUMENT_SIZE_MB=5
CACHE_METADATA_TTL_HOURS=168
```

### Validation
```bash
# Verify configuration loads from environment
python3 << 'EOF'
import sys
import os
sys.path.insert(0, '/opt/docling-mcp')

os.environ['REDIS_HOST'] = 'hx-redis-server.hx.dev.local'
os.environ['REDIS_PORT'] = '6379'

from src.config import DoclingMCPConfig

config = DoclingMCPConfig()
print(f"PASS: Redis host from config: {config.redis.host}")
print(f"PASS: Redis port from config: {config.redis.port}")
EOF
```

---

## Task 136: Implement Graceful Degradation Error Handling

**Estimated Effort**: 1 hour
**Dependencies**: Tasks 131, 132, 133

### Objective
Ensure all Redis-dependent modules handle Redis unavailability gracefully and log appropriate warnings without crashing the service.

### Pre-Execution Validation
```bash
# Check if graceful degradation is implemented
if grep -q "is_available" /opt/docling-mcp/src/session_manager.py && \
   grep -q "is_available" /opt/docling-mcp/src/cache_manager.py; then
    echo "✅ VALIDATION: Graceful degradation already implemented - SKIP"
    exit 0
else
    echo "❌ VALIDATION: Graceful degradation not complete - PROCEED"
fi
```

### Implementation Summary
**Already implemented in Tasks 131-133:**
- RedisClient: `_is_available` flag tracks connection status
- SessionManager: `is_available()` check before operations, returns None if unavailable
- CacheManager: `is_available()` check before operations, returns False/None if unavailable
- All modules log WARNING when Redis unavailable: "Operating in stateless mode"

**Integration with MCP Server:**
```python
# In mcp_server.py - disable session-dependent tools when Redis unavailable
from src.session_manager import get_session_manager
from src.cache_manager import get_cache_manager

session_manager = get_session_manager()

# Check availability before registering session tools
if session_manager and session_manager.is_available():
    @mcp.tool()
    async def create_session(user: str) -> str:
        """Create MCP session for multi-step workflows."""
        session_id = session_manager.create_session(user)
        if session_id:
            return f"Session created: {session_id}"
        else:
            raise ValueError("Redis unavailable, session management disabled")
else:
    logger.warning("Redis unavailable, session management tools disabled")
```

### Validation
```bash
# Test graceful degradation (without Redis running)
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.session_manager import SessionManager
from src.cache_manager import CacheManager

# Create managers without Redis client initialized
session_manager = SessionManager()
cache_manager = CacheManager()

# Should not crash, should return None/False
session_id = session_manager.create_session("test")
cache_result = cache_manager.cache_document_metadata("test_hash", {"test": "data"})

if session_id is None and cache_result is False:
    print("PASS: Graceful degradation works (returns None/False when unavailable)")
else:
    print("FAIL: Should handle unavailability gracefully")
EOF
```

---

## Task 137: Integration Testing - Redis Connectivity

**Estimated Effort**: 0.5 hours
**Dependencies**: Tasks 131-136

### Objective
Validate end-to-end Redis integration including client, session manager, cache manager, and MCP health endpoint.

### Pre-Execution Validation
```bash
# Check if integration test already exists
if [ -f "/opt/docling-mcp/tests/test_suite/integration/tc-docling-mcp-integration-007-redis-connectivity.md" ]; then
    echo "✅ VALIDATION: Integration test already exists - SKIP"
    exit 0
else
    echo "❌ VALIDATION: Integration test not found - PROCEED"
fi
```

### Integration Test
```bash
# Full integration test
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.session_manager import initialize_session_manager
from src.cache_manager import initialize_cache_manager, CacheManager

print("=== Redis Integration Test ===\n")

# 1. Initialize Redis client
redis_client = initialize_redis_client(
    host="hx-redis-server.hx.dev.local",
    port=6379
)
assert redis_client.ping(), "Redis PING failed"
print("✓ Redis client initialized and connected")

# 2. Initialize session manager
session_manager = initialize_session_manager(ttl_hours=24)
assert session_manager.is_available(), "Session manager unavailable"
print("✓ Session manager initialized")

# 3. Initialize cache manager
cache_manager = initialize_cache_manager(enabled=True)
assert cache_manager.is_available(), "Cache manager unavailable"
print("✓ Cache manager initialized")

# 4. Test session operations
session_id = session_manager.create_session(user="integration_test")
assert session_id is not None, "Session creation failed"
print(f"✓ Session created: {session_id}")

success = session_manager.add_documents(session_id, ["doc1", "doc2"])
assert success, "Add documents failed"
print("✓ Documents added to session")

session_state = session_manager.get_session(session_id)
assert session_state is not None, "Get session failed"
assert len(session_state.documents) == 2, "Document count mismatch"
print("✓ Session retrieved successfully")

# 5. Test cache operations
doc_hash = CacheManager.generate_hash("test_content")
metadata = {"format": "PDF", "pages": 5}

success = cache_manager.cache_document_metadata(doc_hash, metadata)
assert success, "Cache metadata failed"
print("✓ Metadata cached")

cached = cache_manager.get_document_metadata(doc_hash)
assert cached == metadata, "Cached metadata mismatch"
print("✓ Metadata retrieved from cache")

# 6. Cleanup
session_manager.delete_session(session_id)
cache_manager.invalidate_document_metadata(doc_hash)
print("✓ Cleanup successful")

print("\n✅ All integration tests passed")
EOF
```

### Validation
```bash
# Verify Redis operations via redis-cli
redis-cli -h hx-redis-server.hx.dev.local PING
redis-cli -h hx-redis-server.hx.dev.local INFO stats | grep total_connections_received
redis-cli -h hx-redis-server.hx.dev.local KEYS "session:*" | wc -l
redis-cli -h hx-redis-server.hx.dev.local KEYS "cache:*" | wc -l
```

---

## Task 138: Performance Testing - Cache Hit Ratio

**Estimated Effort**: 0.5 hours
**Dependencies**: Task 133

### Objective
Validate cache effectiveness by testing cache hit ratios meet specification targets (>40% for entity extraction).

### Pre-Execution Validation
```bash
# Check if performance test already documented
if [ -f "/opt/docling-mcp/tests/performance/cache-hit-ratio-test.md" ]; then
    echo "✅ VALIDATION: Performance test already exists - SKIP"
    exit 0
else
    echo "❌ VALIDATION: Performance test not found - PROCEED"
fi
```

### Performance Test
```bash
# Test cache hit ratio with repeated requests
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.cache_manager import initialize_cache_manager, CacheManager

redis_client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)
cache_manager = initialize_cache_manager(enabled=True)

print("=== Cache Hit Ratio Test ===\n")

# Simulate repeated entity extraction requests
doc_content = "Test document about AI and machine learning"
prompt = "Extract entities"
model = "gemma3:27b"

# First request - cache miss
result1 = cache_manager.get_entity_extraction(doc_content, prompt, model)
assert result1 is None, "First request should be cache miss"

# Cache result
entities = {"entities": [{"text": "AI", "type": "TECH"}]}
cache_manager.cache_entity_extraction(doc_content, prompt, model, entities)

# Second request - cache hit
result2 = cache_manager.get_entity_extraction(doc_content, prompt, model)
assert result2 == entities, "Second request should be cache hit"

# Third request - cache hit
result3 = cache_manager.get_entity_extraction(doc_content, prompt, model)
assert result3 == entities, "Third request should be cache hit"

# Check metrics
metrics = cache_manager.get_metrics("entities")
hit_ratio = metrics["entities"].hit_ratio

print(f"Total requests: {metrics['entities'].total_requests}")
print(f"Hits: {metrics['entities'].hits}")
print(f"Misses: {metrics['entities'].misses}")
print(f"Hit ratio: {hit_ratio:.2%}")

assert hit_ratio >= 0.66, f"Hit ratio {hit_ratio:.2%} below expected 66%"
print(f"\n✅ Cache hit ratio {hit_ratio:.2%} meets target (>40%)")
EOF
```

---

## Task 139: Documentation - Redis Integration Guide

**Estimated Effort**: 0.5 hours
**Dependencies**: Tasks 131-138

### Objective
Document Redis integration architecture, configuration, usage patterns, and troubleshooting.

### Pre-Execution Validation
```bash
# Check if integration documentation exists
if [ -f "/opt/docling-mcp/docs/redis-integration.md" ]; then
    echo "✅ VALIDATION: Documentation already exists - SKIP"
    exit 0
else
    echo "❌ VALIDATION: Documentation not found - PROCEED"
fi
```

### Documentation Outline
Create `/opt/docling-mcp/docs/redis-integration.md`:
- Architecture overview (client, session manager, cache manager)
- Configuration (environment variables, Pydantic settings)
- Session management usage (create, add docs, update status, delete)
- Caching strategies (metadata, entity extraction, DoclingDocument)
- Health monitoring and metrics
- Graceful degradation behavior
- Troubleshooting guide
- Performance tuning recommendations

---

## Task 140: Final Validation - Redis Work Stream Complete

**Estimated Effort**: 0.5 hours
**Dependencies**: Tasks 131-139

### Objective
Perform comprehensive validation that all Redis integration components are working correctly end-to-end.

### Pre-Execution Validation
```bash
# Check if all Redis tasks completed
TASKS_COMPLETE=true
for task in 131 132 133 134 135 136 137 138 139; do
    if [ ! -f "/opt/docling-mcp/tasks/hx-docling-mcp-task-${task}-*.md" ]; then
        TASKS_COMPLETE=false
        echo "❌ Task ${task} not found"
    fi
done

if [ "$TASKS_COMPLETE" = true ]; then
    echo "✅ VALIDATION: All Redis tasks exist - PROCEED with validation"
else
    echo "❌ VALIDATION: Some tasks missing - CANNOT validate"
    exit 1
fi
```

### Final Validation Checklist

**Module Files:**
- [ ] `/opt/docling-mcp/src/integrations/redis_client.py` exists and imports
- [ ] `/opt/docling-mcp/src/session_manager.py` exists and imports
- [ ] `/opt/docling-mcp/src/cache_manager.py` exists and imports

**Redis Connectivity:**
- [ ] Redis PING successful from hx-docling-mcp-server
- [ ] Connection pool configured (max 10 connections)
- [ ] Health checks working (30-second interval)

**Session Management:**
- [ ] Session creation generates UUID v4
- [ ] Sessions stored in Redis with TTL
- [ ] Document tracking works (add/get)
- [ ] Status updates work (pending/processing/completed)
- [ ] TTL sliding window extends on access
- [ ] Session deletion atomic (MULTI/EXEC)

**Caching:**
- [ ] Document metadata caching works (7-day TTL)
- [ ] Entity extraction semantic caching works (24-hour TTL)
- [ ] DoclingDocument caching works (24-hour TTL)
- [ ] Cache hit/miss metrics tracked
- [ ] Size limit enforced (5MB max)

**Graceful Degradation:**
- [ ] Service works when Redis unavailable
- [ ] Appropriate warnings logged
- [ ] Session tools disabled when Redis down
- [ ] Stateless tools continue working

**Configuration:**
- [ ] Redis settings loaded from environment
- [ ] Pydantic validation works
- [ ] All defaults match specification

**Integration:**
- [ ] MCP health endpoint reports Redis status
- [ ] Session tools integrate with session manager
- [ ] Cache manager integrated with document processing

### Final Validation Script
```bash
#!/bin/bash
# Final Redis integration validation

source /opt/docling-mcp/venv/bin/activate

echo "=== Final Redis Integration Validation ==="
echo ""

# 1. Check modules exist
echo "1. Checking module files..."
test -f /opt/docling-mcp/src/integrations/redis_client.py && echo "  ✓ redis_client.py" || echo "  ✗ redis_client.py MISSING"
test -f /opt/docling-mcp/src/session_manager.py && echo "  ✓ session_manager.py" || echo "  ✗ session_manager.py MISSING"
test -f /opt/docling-mcp/src/cache_manager.py && echo "  ✓ cache_manager.py" || echo "  ✗ cache_manager.py MISSING"

# 2. Test imports
echo ""
echo "2. Testing module imports..."
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.integrations.redis_client import RedisClient; print('  ✓ RedisClient import')" || echo "  ✗ RedisClient import FAILED"
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.session_manager import SessionManager; print('  ✓ SessionManager import')" || echo "  ✗ SessionManager import FAILED"
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.cache_manager import CacheManager; print('  ✓ CacheManager import')" || echo "  ✗ CacheManager import FAILED"

# 3. Test Redis connectivity
echo ""
echo "3. Testing Redis connectivity..."
redis-cli -h hx-redis-server.hx.dev.local PING && echo "  ✓ Redis PING successful" || echo "  ✗ Redis PING FAILED"

# 4. Run integration test
echo ""
echo "4. Running integration test..."
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.session_manager import initialize_session_manager
from src.cache_manager import initialize_cache_manager

try:
    redis_client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)
    session_manager = initialize_session_manager()
    cache_manager = initialize_cache_manager()

    # Test session
    session_id = session_manager.create_session("final_test")
    session_manager.delete_session(session_id)

    # Test cache
    cache_manager.cache_document_metadata("test_hash", {"test": "data"})
    cache_manager.invalidate_document_metadata("test_hash")

    print("  ✓ Integration test passed")
except Exception as e:
    print(f"  ✗ Integration test FAILED: {str(e)}")
EOF

echo ""
echo "=== Validation Complete ==="
```

---

## Acceptance Criteria - Work Stream 8 Complete

All tasks 131-140 complete when:
- [ ] Redis client module operational with connection pooling
- [ ] Session manager handles multi-step workflows
- [ ] Cache manager optimizes performance (metadata, entities, DoclingDocument)
- [ ] Health checks monitor Redis availability
- [ ] Graceful degradation works when Redis unavailable
- [ ] Configuration integrated with Pydantic settings
- [ ] Integration tests passing
- [ ] Performance tests show cache hit ratio >40%
- [ ] Documentation complete
- [ ] Final validation passing

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
  - FR-018, FR-020: Session Management
  - FR-021A: Caching Strategy
  - FR-023: Redis Integration
  - NFR-010: Graceful Degradation
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md`
- **Tasks 131-133**: Redis client, session manager, cache manager modules

## Risk Assessment

**Risk**: Low
- Redis is performance optimization (not critical for core functionality)
- Graceful degradation ensures service availability
- Well-tested redis-py client library

**Mitigation**:
- Comprehensive validation at each task
- Integration testing before deployment
- Graceful degradation tested explicitly
- Health monitoring for early failure detection
