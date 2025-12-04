# Charter Review: Trinity (PostgreSQL DBA)

**Review Date:** 2025-12-01
**Charter Version:** 1.1
**Reviewer Role:** PostgreSQL DBA SME
**Service:** hx-lang-server (LangGraph Orchestration)

---

## Executive Summary

The charter outlines a solid foundation for LangGraph deployment with PostgreSQL checkpointing. The use of `langgraph-checkpoint-postgres` with psycopg3 async drivers aligns with production-grade patterns. However, **CRITICAL database design decisions are deferred**, including checkpoint schema structure, connection pooling strategy, backup/recovery procedures, and integration architecture with hx-postgres-server. These must be resolved during specification phase before implementation begins.

**Overall Assessment:** Approved with mandatory database architecture specification required before development.

---

## Strengths

- **Proven Technology Stack**: `langgraph-checkpoint-postgres` is the official, stable checkpoint backend for LangGraph with production deployments
- **Async-First Design**: psycopg3 async driver selection aligns with FastAPI's async architecture (no connection blocking)
- **Dual Persistence Strategy**: PostgreSQL (durable checkpoints) + Redis (ephemeral sessions) provides optimal performance and reliability balance
- **Existing Infrastructure Leverage**: Integration with operational hx-postgres-server eliminates new database server deployment
- **Clear Scope Boundaries**: "Use existing PostgreSQL" constraint prevents scope creep into database server modifications
- **State Management Emphasis**: Success criteria includes "conversations persist across service restarts" with validation plan
- **SOLID Principles Mandate**: Will enforce clean separation of concerns in database access layer

---

## Concerns / Risks

### HIGH Severity

**H-001: Checkpoint Schema Design Not Specified**
- **Issue**: Charter does not specify which checkpoint schema will be used:
  - Default `langgraph-checkpoint-postgres` schema (single `checkpoints` table with JSONB)
  - Custom schema with normalized tables for better queryability
  - Partitioning strategy for checkpoint growth management
- **Impact**: Schema design affects query performance, storage growth, backup strategy, and migration complexity
- **Resolution Required**: Specification phase must document exact schema with DDL
- **Recommendation**: Start with default `langgraph-checkpoint-postgres` schema (proven in production), evaluate partitioning if checkpoint volume exceeds 1M rows

**H-002: Connection Pooling Strategy Undefined**
- **Issue**: No specification for connection pooling configuration:
  - Connection pool size (min/max connections)
  - Connection lifetime and timeout settings
  - Handling connection exhaustion scenarios
  - Integration with hx-postgres-server's global connection limits
- **Impact**: Improper pooling causes connection exhaustion (blocking all database access) or resource waste
- **Resolution Required**: Specification must define pgBouncer integration OR psycopg3 connection pool parameters
- **Recommendation**: Use pgBouncer in transaction pooling mode (already proven in HX-Infrastructure) with dedicated pool for hx-lang-server (pool size: 10-20 connections based on FastAPI worker count)

**H-003: Backup and Recovery Strategy Missing**
- **Issue**: No mention of:
  - Checkpoint data backup procedures
  - Point-in-time recovery requirements
  - Conversation restoration after data loss
  - Checkpoint data retention policy
- **Impact**: Data loss scenarios not addressed; conversations may be unrecoverable
- **Resolution Required**: Specification must document backup strategy and RTO/RPO targets
- **Recommendation**: Leverage hx-postgres-server's existing WAL archiving and pg_basebackup procedures; define checkpoint retention (recommend 30 days for development, longer for production)

### MEDIUM Severity

**M-001: Database User and Permission Model Not Defined**
- **Issue**: No specification of PostgreSQL user(s) for hx-lang-server:
  - Dedicated service account with least-privilege access?
  - Schema ownership model (public schema vs. dedicated `langgraph` schema)?
  - DDL vs. DML permission separation
- **Impact**: Security risk (overprivileged accounts) or operational friction (insufficient permissions)
- **Resolution Required**: Specification must define database user, permissions, and schema ownership
- **Recommendation**: Create dedicated `hx_lang_server` PostgreSQL user with:
  - `CONNECT` on database
  - `USAGE, CREATE` on dedicated `langgraph` schema
  - `SELECT, INSERT, UPDATE, DELETE` on checkpoint tables
  - No superuser privileges

**M-002: Checkpoint Growth and Maintenance Not Addressed**
- **Issue**: LangGraph checkpoints accumulate over time without built-in expiration:
  - How will old checkpoints be purged?
  - What triggers checkpoint cleanup (time-based? storage-based?)?
  - VACUUM strategy for checkpoint tables (high INSERT/UPDATE churn)?
- **Impact**: Unbounded growth leads to disk exhaustion and query performance degradation
- **Resolution Required**: Specification must define checkpoint lifecycle management
- **Recommendation**: Implement automated cleanup:
  - Time-based: DELETE checkpoints older than 30 days (configurable)
  - Use pg_cron or systemd timer for cleanup job
  - Monitor autovacuum effectiveness on checkpoint tables

**M-003: Transaction Isolation Level Not Specified**
- **Issue**: No mention of transaction isolation requirements:
  - Default READ COMMITTED sufficient?
  - REPEATABLE READ needed for multi-step checkpoint writes?
  - Serialization failure handling strategy?
- **Impact**: Race conditions in concurrent checkpoint writes could corrupt conversation state
- **Resolution Required**: Specification must define isolation level and conflict resolution
- **Recommendation**: Use READ COMMITTED (PostgreSQL default) with application-level retry for serialization failures; `langgraph-checkpoint-postgres` handles concurrency internally with optimistic locking

**M-004: Database Migration Strategy Missing**
- **Issue**: No mention of schema migration approach:
  - Initial schema creation procedure
  - Future schema version upgrades
  - Migration rollback procedures
- **Impact**: Operational friction during deployment and maintenance
- **Resolution Required**: Specification must define migration tooling (Alembic? raw SQL?)
- **Recommendation**: Use Alembic migrations:
  - Initial migration creates checkpoint schema
  - Version-controlled migrations in repository
  - Manual execution (no auto-migration on service startup in production)

### LOW Severity

**L-001: SSL/TLS Connection Requirements Not Specified**
- **Issue**: Charter states "NO FIREWALL" for dev environment but doesn't specify database connection security:
  - sslmode=disable acceptable for dev?
  - Certificate verification requirements?
- **Impact**: Minor - dev environment security is relaxed, but sets precedent for production
- **Resolution**: Specification should document connection string with explicit sslmode
- **Recommendation**: Use `sslmode=prefer` for dev (encrypted if available, unencrypted fallback), `sslmode=require` minimum for future production

**L-002: Checkpoint Query Patterns Not Documented**
- **Issue**: No discussion of how checkpoints will be queried:
  - Lookup by conversation ID (primary key)?
  - Time-range queries for debugging?
  - Aggregation queries for analytics?
- **Impact**: Minor - default schema supports primary key lookups; additional indexes may be needed later
- **Resolution**: Specification should document query patterns to inform index strategy
- **Recommendation**: Start with default indexes; add covering indexes if analytics queries needed

**L-003: Database Observability Not Addressed**
- **Issue**: No mention of database monitoring integration:
  - Will pg_stat_statements track LangGraph queries?
  - Integration with hx-metric-server (Prometheus + Grafana)?
  - Slow query alerting?
- **Impact**: Minor - operational visibility gap, not blocking for initial deployment
- **Resolution**: Defer to operational integration phase (Phase 3 backlog)
- **Recommendation**: Enable pg_stat_statements for hx-lang-server queries; create Grafana dashboard for checkpoint table metrics

---

## Recommendations

### Mandatory (Must Address Before Specification Sign-off)

1. **Define Checkpoint Database Schema**
   - Document exact DDL for checkpoint tables
   - Specify schema name (`langgraph` vs. `public`)
   - Define table partitioning strategy if expecting >1M checkpoints
   - Include sample checkpoint record for size estimation

2. **Specify Connection Pooling Architecture**
   - Document pgBouncer integration with dedicated pool OR psycopg3 connection pool configuration
   - Define pool size based on FastAPI worker count (recommend: workers * 2)
   - Specify connection timeout and lifetime settings
   - Document connection exhaustion handling (queue? reject requests?)

3. **Document Backup and Recovery Procedures**
   - Leverage existing hx-postgres-server backup strategy (WAL archiving + pg_basebackup)
   - Define checkpoint retention policy (30 days minimum for dev)
   - Specify RTO (1 hour) and RPO (5 minutes) targets
   - Document conversation restoration test procedure

4. **Define Database User and Permissions**
   - Create dedicated `hx_lang_server` PostgreSQL user
   - Use dedicated `langgraph` schema (not `public`)
   - Grant least-privilege permissions (no DDL in production user)
   - Document credential storage in Ansible Vault

5. **Implement Checkpoint Lifecycle Management**
   - Define cleanup policy: DELETE checkpoints older than 30 days
   - Use pg_cron or systemd timer for automated cleanup
   - Monitor checkpoint table growth and autovacuum activity
   - Set autovacuum thresholds for high-churn checkpoint tables

### Recommended (Should Address During Development)

6. **Create Database Migration Framework**
   - Use Alembic for schema version management
   - Initial migration creates `langgraph` schema and checkpoint tables
   - Version-control all migrations in repository
   - Document manual migration execution procedure (no auto-migrate)

7. **Configure Transaction Isolation and Retry Logic**
   - Use READ COMMITTED (default) for checkpoint operations
   - Implement application-level retry for serialization failures (exponential backoff, max 3 attempts)
   - Log transaction conflicts for monitoring

8. **Implement Database Connection Health Checks**
   - Add `/health/db` endpoint that executes `SELECT 1` against PostgreSQL
   - Include in systemd service health check (startup verification)
   - Alert on connection failures (>3 consecutive failures)

9. **Enable Database Observability**
   - Verify pg_stat_statements captures LangGraph queries
   - Create Grafana dashboard with:
     - Checkpoint table size and growth rate
     - Query latency (P50, P95, P99)
     - Connection pool utilization
     - Transaction throughput
   - Set alert thresholds for slow queries (>1s) and connection exhaustion (>80% pool)

### Optional (Future Enhancements - Backlog)

10. **Evaluate Read Replicas for Analytics**
    - If analytics queries impact checkpoint writes, consider read replica
    - Defer until proven bottleneck (not needed for Phase 1)

11. **Implement Checkpoint Compression**
    - If checkpoint JSONB payloads are large (>10KB average), evaluate PostgreSQL TOAST compression
    - Measure storage savings vs. CPU overhead
    - Defer until storage becomes constraint

12. **Add Checkpoint Versioning**
    - If LangGraph schema evolves, implement checkpoint version field
    - Support migration from old checkpoint format to new
    - Defer until first schema breaking change

---

## Database Architecture Assessment

### Checkpoint Schema Design

**Recommended Approach: Use Default `langgraph-checkpoint-postgres` Schema**

The `langgraph-checkpoint-postgres` library provides a battle-tested schema optimized for LangGraph's checkpoint model:

```sql
-- Recommended Schema (langgraph-checkpoint-postgres default)
CREATE SCHEMA IF NOT EXISTS langgraph;

CREATE TABLE langgraph.checkpoints (
    thread_id TEXT NOT NULL,
    checkpoint_id TEXT NOT NULL,
    parent_checkpoint_id TEXT,
    checkpoint JSONB NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (thread_id, checkpoint_id)
);

CREATE INDEX idx_checkpoints_thread_created
    ON langgraph.checkpoints (thread_id, created_at DESC);

CREATE INDEX idx_checkpoints_parent
    ON langgraph.checkpoints (parent_checkpoint_id)
    WHERE parent_checkpoint_id IS NOT NULL;
```

**Rationale:**
- **JSONB Storage**: Flexible schema for evolving checkpoint structure (LangGraph updates don't require migrations)
- **Composite Primary Key**: (thread_id, checkpoint_id) enables efficient conversation history retrieval
- **Parent Tracking**: Supports LangGraph's branching conversation model (time travel, A/B testing)
- **Timestamp Index**: Enables time-range queries for debugging and cleanup
- **Production Proven**: Used by LangGraph Cloud and enterprise deployments

**Partitioning Strategy (If Needed):**

Only implement if checkpoint volume exceeds 1 million rows:

```sql
-- Range partitioning by created_at (monthly partitions)
CREATE TABLE langgraph.checkpoints (
    thread_id TEXT NOT NULL,
    checkpoint_id TEXT NOT NULL,
    parent_checkpoint_id TEXT,
    checkpoint JSONB NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (thread_id, checkpoint_id, created_at)
) PARTITION BY RANGE (created_at);

-- Create initial partitions (automate with pg_partman)
CREATE TABLE langgraph.checkpoints_2025_12
    PARTITION OF langgraph.checkpoints
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
```

**For Phase 1 (Development):** Use default schema without partitioning. Monitor growth and implement partitioning if checkpoint volume exceeds 500K rows.

### Connection Pooling Architecture

**Recommended Approach: pgBouncer Transaction Pooling with Dedicated Pool**

```ini
# /etc/pgbouncer/pgbouncer.ini (on hx-postgres-server)

[databases]
# Existing pools...
hx_lang_server_db = host=localhost port=5432 dbname=hx_lang_server pool_size=15 reserve_pool=5

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
reserve_pool_size = 5
reserve_pool_timeout = 3
```

**Connection String for hx-lang-server:**
```python
# config.py
DATABASE_URL = "postgresql+psycopg://hx_lang_server:${PASSWORD}@hx-postgres-server.hx.dev.local:6432/hx_lang_server?sslmode=prefer"
```

**Pool Sizing:**
- **FastAPI Workers**: 4-8 workers (typical for development server)
- **Connections per Worker**: 2-3 connections (async I/O reduces connection needs)
- **Pool Size**: 15 connections (sufficient for 4-8 workers * 2 connections)
- **Reserve Pool**: 5 connections (emergency capacity for connection spikes)

**Rationale:**
- **Transaction Pooling**: LangGraph checkpoint writes are short transactions (no long-lived connections needed)
- **Existing Infrastructure**: pgBouncer already operational on hx-postgres-server (no new components)
- **Connection Reuse**: 15 pooled connections support hundreds of concurrent requests
- **Isolation**: Dedicated pool prevents hx-lang-server from exhausting connections for other services

**Alternative (If pgBouncer Not Available):**

Use psycopg3 built-in connection pooling:

```python
# database.py
from psycopg_pool import AsyncConnectionPool

db_pool = AsyncConnectionPool(
    conninfo=DATABASE_URL,
    min_size=5,
    max_size=15,
    max_waiting=10,
    timeout=30.0,
    max_lifetime=3600.0,
    max_idle=600.0,
)
```

### PostgreSQL Configuration Tuning

**Recommended Settings for Checkpoint Workload:**

```ini
# postgresql.conf (on hx-postgres-server)

# Checkpoint tables have high INSERT/UPDATE churn
autovacuum_naptime = 1min
autovacuum_vacuum_scale_factor = 0.1  # Vacuum when 10% of table changed
autovacuum_analyze_scale_factor = 0.05

# JSONB checkpoint payloads benefit from increased work_mem
work_mem = 16MB  # For JSONB operations and sorting

# Async queries benefit from parallel execution
max_parallel_workers_per_gather = 2

# pg_stat_statements for query performance monitoring
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```

**Rationale:**
- **Aggressive Autovacuum**: Checkpoint tables have high churn (frequent updates); aggressive autovacuum prevents bloat
- **Increased work_mem**: JSONB operations (checkpoint serialization/deserialization) benefit from larger memory buffers
- **Parallel Queries**: If analytics queries scan large checkpoint ranges, parallel workers improve performance

### Backup and Recovery Strategy

**Recommended Approach: Leverage Existing hx-postgres-server Backup Infrastructure**

**Backup Strategy:**
1. **Continuous WAL Archiving**: Already operational on hx-postgres-server
   - Enables point-in-time recovery (PITR) for checkpoint data
   - No additional configuration needed for hx-lang-server database

2. **Daily Base Backups**: pg_basebackup (already scheduled)
   - Checkpoint data included in full database backup
   - Retention: 30 days (development), extend for production

3. **Checkpoint-Specific Backup (Optional):**
   ```bash
   # Daily logical backup of checkpoint data for faster restore
   pg_dump -h hx-postgres-server.hx.dev.local \
           -U hx_lang_server \
           -d hx_lang_server \
           -n langgraph \
           -Fc \
           -f /backup/langgraph-checkpoints-$(date +%Y%m%d).dump
   ```

**Recovery Procedures:**

**Scenario 1: Single Conversation Loss (Application Error)**
```sql
-- Restore conversation from most recent valid checkpoint
SELECT * FROM langgraph.checkpoints
WHERE thread_id = '<conversation-id>'
ORDER BY created_at DESC
LIMIT 10;

-- Application-level conversation rebuild from last valid checkpoint
```

**Scenario 2: Database Corruption (Hardware Failure)**
```bash
# Point-in-time recovery using WAL archives
# (Handled by hx-postgres-server DBA procedures)
pg_basebackup restore + WAL replay to specific timestamp
```

**Scenario 3: Accidental Checkpoint Deletion**
```bash
# Restore from logical backup (if available)
pg_restore -h hx-postgres-server.hx.dev.local \
           -U hx_lang_server \
           -d hx_lang_server \
           /backup/langgraph-checkpoints-20251201.dump
```

**RTO/RPO Targets:**
- **Recovery Time Objective (RTO)**: <1 hour (time to restore service)
- **Recovery Point Objective (RPO)**: <5 minutes (maximum data loss)
- **Validation**: Quarterly disaster recovery drills

### Data Lifecycle Management

**Recommended Checkpoint Cleanup Strategy:**

```sql
-- Automated cleanup job (pg_cron or systemd timer)
-- Run daily at 2 AM

-- Delete checkpoints older than 30 days (configurable)
DELETE FROM langgraph.checkpoints
WHERE created_at < NOW() - INTERVAL '30 days';

-- Log cleanup statistics
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % old checkpoints', deleted_count;
END $$;
```

**Cleanup Scheduling Options:**

**Option 1: pg_cron (Recommended - Database-Native)**
```sql
-- Install pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily cleanup at 2 AM
SELECT cron.schedule(
    'cleanup-langgraph-checkpoints',
    '0 2 * * *',
    $$
    DELETE FROM langgraph.checkpoints
    WHERE created_at < NOW() - INTERVAL '30 days';
    $$
);
```

**Option 2: systemd Timer (Alternative - OS-Level)**
```ini
# /etc/systemd/system/langgraph-checkpoint-cleanup.timer
[Unit]
Description=LangGraph Checkpoint Cleanup Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
#!/bin/bash
# /usr/local/bin/langgraph-checkpoint-cleanup.sh
psql -h hx-postgres-server.hx.dev.local \
     -U hx_lang_server \
     -d hx_lang_server \
     -c "DELETE FROM langgraph.checkpoints WHERE created_at < NOW() - INTERVAL '30 days';"
```

**Monitoring Cleanup Effectiveness:**
```sql
-- Dashboard query: Checkpoint age distribution
SELECT
    date_trunc('day', created_at) AS date,
    COUNT(*) AS checkpoints,
    pg_size_pretty(SUM(pg_column_size(checkpoint))) AS total_size
FROM langgraph.checkpoints
GROUP BY date_trunc('day', created_at)
ORDER BY date DESC
LIMIT 30;
```

### Integration with hx-postgres-server

**Database Provisioning Steps:**

```sql
-- Execute on hx-postgres-server as postgres superuser

-- 1. Create dedicated database
CREATE DATABASE hx_lang_server
    OWNER postgres
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.UTF-8'
    LC_CTYPE 'en_US.UTF-8'
    TEMPLATE template0;

-- 2. Create service user with least-privilege access
CREATE USER hx_lang_server WITH PASSWORD '<secure-password-from-vault>';

-- 3. Grant database connection
GRANT CONNECT ON DATABASE hx_lang_server TO hx_lang_server;

-- Connect to hx_lang_server database
\c hx_lang_server

-- 4. Create dedicated schema
CREATE SCHEMA IF NOT EXISTS langgraph AUTHORIZATION hx_lang_server;

-- 5. Set search path for user
ALTER ROLE hx_lang_server SET search_path = langgraph, public;

-- 6. Grant schema permissions
GRANT USAGE, CREATE ON SCHEMA langgraph TO hx_lang_server;

-- 7. Grant table permissions (after tables created by migration)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA langgraph TO hx_lang_server;
ALTER DEFAULT PRIVILEGES IN SCHEMA langgraph GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hx_lang_server;

-- 8. Enable pg_stat_statements for query monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

**Credential Management:**

```yaml
# Ansible Vault: hx-lang-server/credentials.yml (encrypted)
postgresql:
  host: hx-postgres-server.hx.dev.local
  port: 6432  # pgBouncer port (or 5432 if direct connection)
  database: hx_lang_server
  user: hx_lang_server
  password: <vault-encrypted-password>
  sslmode: prefer
  pool_size: 15
  max_overflow: 5
  pool_timeout: 30
```

**Environment Variable Injection:**
```bash
# /opt/hx-lang-server/.env
DATABASE_URL=postgresql+psycopg://hx_lang_server:${POSTGRES_PASSWORD}@hx-postgres-server.hx.dev.local:6432/hx_lang_server?sslmode=prefer
```

### Performance Considerations

**Expected Performance Profile:**

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Checkpoint Write Latency** | <50ms (P95) | Single INSERT operation with JSONB payload (<10KB typical) |
| **Checkpoint Read Latency** | <10ms (P95) | Primary key lookup with covering index |
| **Conversation History Query** | <100ms (P95) | Index scan on (thread_id, created_at) for last N checkpoints |
| **Storage Growth** | ~500MB/month | Assuming 10K conversations/month, 50KB avg checkpoint size, 30-day retention |
| **Connection Utilization** | <60% pool | 15-connection pool with FastAPI async should stay below 10 active connections |

**Performance Validation Tests:**

```python
# tests/performance/test_checkpoint_performance.py

async def test_checkpoint_write_latency():
    """Validate checkpoint write completes in <50ms."""
    start = time.time()
    await checkpoint_saver.save(thread_id, checkpoint_id, checkpoint_data)
    latency = (time.time() - start) * 1000
    assert latency < 50, f"Checkpoint write took {latency}ms (target: <50ms)"

async def test_conversation_history_query():
    """Validate conversation history query completes in <100ms."""
    start = time.time()
    history = await checkpoint_saver.get_history(thread_id, limit=20)
    latency = (time.time() - start) * 1000
    assert latency < 100, f"History query took {latency}ms (target: <100ms)"
```

**Optimization Triggers:**

If performance targets not met:
1. **Write Latency >50ms**: Check pgBouncer queue depth, increase pool size
2. **Read Latency >10ms**: Verify index usage with EXPLAIN ANALYZE, consider covering indexes
3. **Storage Growth >1GB/month**: Reduce checkpoint retention window, compress JSONB payloads
4. **Connection Pool Exhaustion**: Increase pool size, investigate connection leaks

---

## PostgreSQL-Specific Testing Requirements

### Test Cases to Add to Test Plan

**TC-POSTGRES-001: Checkpoint Persistence Across Restart**
- **Objective**: Validate conversations persist after hx-lang-server restart
- **Procedure**:
  1. Create conversation with 5 checkpoint writes
  2. Stop hx-lang-server service
  3. Start hx-lang-server service
  4. Query conversation history
- **Success Criteria**: All 5 checkpoints retrieved, conversation state intact

**TC-POSTGRES-002: Concurrent Checkpoint Writes**
- **Objective**: Validate no checkpoint corruption under concurrent writes
- **Procedure**:
  1. Launch 10 parallel conversations (different thread_ids)
  2. Each conversation writes 10 checkpoints
  3. Query all conversation histories
- **Success Criteria**: All 100 checkpoints (10 threads * 10 checkpoints) present, no duplicates

**TC-POSTGRES-003: Database Connection Failover**
- **Objective**: Validate graceful handling of database connection loss
- **Procedure**:
  1. Start conversation
  2. Simulate database connection failure (iptables DROP or pg_ctl stop)
  3. Attempt checkpoint write
  4. Restore database connection
  5. Retry checkpoint write
- **Success Criteria**: Initial write fails gracefully (error logged, no crash), retry succeeds

**TC-POSTGRES-004: Checkpoint Cleanup Job**
- **Objective**: Validate old checkpoints deleted without affecting active conversations
- **Procedure**:
  1. Create checkpoints with backdated timestamps (31 days old)
  2. Create recent checkpoints (1 day old)
  3. Execute cleanup job
  4. Query checkpoint counts
- **Success Criteria**: Old checkpoints deleted, recent checkpoints retained

**TC-POSTGRES-005: Connection Pool Exhaustion**
- **Objective**: Validate graceful degradation when connection pool exhausted
- **Procedure**:
  1. Configure pool with max_size=5 (artificially low)
  2. Launch 10 concurrent requests (exceeding pool capacity)
  3. Monitor request latency and error rates
- **Success Criteria**: Requests queue (no immediate failures), timeout after 30s with clear error, no connection leaks

**TC-POSTGRES-006: Large Checkpoint Payload**
- **Objective**: Validate handling of large conversation state (>1MB JSONB)
- **Procedure**:
  1. Create checkpoint with 1MB JSONB payload (large conversation history)
  2. Write to database
  3. Read from database
  4. Measure latency
- **Success Criteria**: Write completes successfully (may exceed <50ms target), read latency <100ms, no TOAST errors

---

## Implementation Guidance for Sophia (Technical Lead)

### langgraph-checkpoint-postgres Integration

**Installation:**
```bash
# Python 3.10+ required
pip install langgraph-checkpoint-postgres psycopg[pool]
```

**Configuration Example:**
```python
# config.py
from pydantic_settings import BaseSettings

class DatabaseSettings(BaseSettings):
    database_url: str
    pool_size: int = 15
    max_overflow: int = 5
    pool_timeout: float = 30.0
    pool_recycle: int = 3600  # Recycle connections after 1 hour

    class Config:
        env_file = ".env"

# checkpoint_config.py
from langgraph.checkpoint.postgres import PostgresSaver
from psycopg_pool import AsyncConnectionPool
from config import DatabaseSettings

db_settings = DatabaseSettings()

# Create connection pool
db_pool = AsyncConnectionPool(
    conninfo=db_settings.database_url,
    min_size=db_settings.pool_size // 2,
    max_size=db_settings.pool_size,
    max_waiting=db_settings.max_overflow,
    timeout=db_settings.pool_timeout,
    max_lifetime=db_settings.pool_recycle,
)

# Initialize checkpoint saver
checkpoint_saver = PostgresSaver(db_pool)

# Initialize schema (run once during deployment)
await checkpoint_saver.setup()
```

**LangGraph Integration:**
```python
# agent.py
from langgraph.graph import StateGraph
from checkpoint_config import checkpoint_saver

# Define agent graph
graph = StateGraph(AgentState)
# ... add nodes and edges ...

# Compile with checkpointing
agent = graph.compile(checkpointer=checkpoint_saver)

# Execute with conversation thread
result = await agent.ainvoke(
    input_data,
    config={"configurable": {"thread_id": conversation_id}}
)
```

**Error Handling:**
```python
# database.py
from psycopg import OperationalError
import asyncio

async def checkpoint_with_retry(saver, thread_id, checkpoint, max_retries=3):
    """Write checkpoint with exponential backoff retry."""
    for attempt in range(max_retries):
        try:
            await saver.save(thread_id, checkpoint)
            return
        except OperationalError as e:
            if attempt == max_retries - 1:
                raise
            wait_time = 2 ** attempt  # Exponential backoff: 1s, 2s, 4s
            logger.warning(f"Checkpoint write failed (attempt {attempt+1}/{max_retries}): {e}. Retrying in {wait_time}s...")
            await asyncio.sleep(wait_time)
```

### Database Migration with Alembic

**Setup:**
```bash
pip install alembic
alembic init migrations
```

**Initial Migration:**
```python
# migrations/versions/001_create_langgraph_schema.py
from alembic import op
import sqlalchemy as sa

def upgrade():
    # Create langgraph schema
    op.execute("CREATE SCHEMA IF NOT EXISTS langgraph")

    # langgraph-checkpoint-postgres handles table creation
    # This migration just ensures schema exists

def downgrade():
    op.execute("DROP SCHEMA IF EXISTS langgraph CASCADE")
```

**Execution:**
```bash
# Run migration manually (DO NOT auto-migrate on service startup)
alembic upgrade head
```

### Health Check Implementation

**Database Health Endpoint:**
```python
# api/health.py
from fastapi import APIRouter, HTTPException
from checkpoint_config import db_pool

router = APIRouter()

@router.get("/health/db")
async def database_health():
    """Check PostgreSQL connectivity."""
    try:
        async with db_pool.connection() as conn:
            result = await conn.execute("SELECT 1")
            await result.fetchone()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database unhealthy: {str(e)}")
```

**Systemd Integration:**
```ini
# /etc/systemd/system/hx-lang-server.service
[Unit]
After=network.target postgresql.service

[Service]
# Wait for database before starting
ExecStartPre=/usr/bin/timeout 30 /bin/bash -c 'until pg_isready -h hx-postgres-server.hx.dev.local; do sleep 1; done'
```

---

## Approval Status

[X] Approved with mandatory changes (database architecture specification required)
[ ] Approved as-is
[ ] Requires significant changes before approval
[ ] Not approved

**Conditions for Final Approval:**
1. ✅ **Specification phase must address all HIGH severity concerns:**
   - H-001: Checkpoint schema design documented with DDL
   - H-002: Connection pooling strategy specified (pgBouncer recommended)
   - H-003: Backup and recovery procedures documented
2. ✅ **Mandatory recommendations implemented:**
   - Database user and permissions defined
   - Checkpoint cleanup strategy documented
3. ✅ **PostgreSQL test cases added to test plan** (TC-POSTGRES-001 through TC-POSTGRES-006)

**Signature:** Trinity Smith, PostgreSQL DBA SME
**Date:** 2025-12-01
**Status:** APPROVED WITH CONDITIONS - Proceed to specification phase with database architecture requirements

---

## Next Steps for Sophia

1. **Review this assessment** with Agent Zero and Alex Rivera
2. **Incorporate database architecture decisions** into specification document:
   - Copy recommended schema DDL
   - Document connection pooling strategy (pgBouncer or psycopg3 pool)
   - Reference backup procedures from hx-postgres-server
3. **Coordinate with Trinity** for database provisioning (user creation, schema setup)
4. **Add PostgreSQL test cases** to test plan (TC-POSTGRES-001 through TC-POSTGRES-006)
5. **Document database migration procedure** in deployment plan

**I am available for consultation during specification and implementation phases.**

---

**Review Complete**
**Trinity Smith**
**PostgreSQL DBA SME - HX-Infrastructure**
**2025-12-01**
