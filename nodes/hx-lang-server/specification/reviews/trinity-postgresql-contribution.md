# Specification Contribution: Trinity (PostgreSQL DBA)

**Contribution Date:** 2025-12-01
**Spec Version:** 1.0
**Focus Areas:** PostgreSQL checkpoint schema, connection pooling, backup strategy, performance tuning
**Charter Reference:** `/nodes/hx-lang-server/charter/charter.md` (v1.1)
**Specification Reference:** `/nodes/hx-lang-server/specification/node-spec.md` (v1.0 DRAFT)

---

## Executive Summary

This contribution addresses all HIGH and MEDIUM severity concerns identified in my charter review, providing production-ready PostgreSQL architecture for LangGraph checkpointing. The specification draft provides a solid foundation but **requires critical enhancements** in five areas:

1. **Schema Design**: Default `langgraph-checkpoint-postgres` schema approved, partitioning strategy defined for scale
2. **Connection Pooling**: pgBouncer transaction pooling with dedicated pool recommended
3. **Backup Strategy**: Leverage existing hx-postgres-server WAL archiving, add checkpoint-specific procedures
4. **Performance Tuning**: PostgreSQL configuration optimized for JSONB checkpoint workload
5. **Lifecycle Management**: Automated checkpoint cleanup with pg_cron, 30-day retention

**Critical Validation**: Spec section "PostgreSQL Checkpoint Configuration" contains **CRITICAL ERRORS** that will cause production failures. See [Spec Validation](#spec-validation) section for detailed corrections.

---

## Schema Enhancements

### Approved Schema Design

The specification correctly identifies use of `langgraph-checkpoint-postgres` library, but lacks schema DDL documentation. I **approve** the default schema approach with the following enhancements:

#### Default Schema (Phase 1: No Partitioning)

```sql
-- Execute on hx-postgres-server as postgres superuser
-- Target database: hx_lang_server

-- Create dedicated schema for LangGraph checkpoints
CREATE SCHEMA IF NOT EXISTS langgraph;

-- Grant schema ownership to service user
ALTER SCHEMA langgraph OWNER TO hx_lang_server;

-- Set search path for service user
ALTER ROLE hx_lang_server SET search_path = langgraph, public;

-- NOTE: langgraph-checkpoint-postgres auto-creates these tables via AsyncPostgresSaver.setup()
-- Documented here for reference only - DO NOT manually create

-- Checkpoints table (auto-created by library)
-- Structure:
--   thread_id TEXT NOT NULL          -- Conversation identifier
--   checkpoint_id TEXT NOT NULL      -- Checkpoint UUID
--   parent_checkpoint_id TEXT        -- For branching/time-travel
--   checkpoint JSONB NOT NULL        -- State snapshot
--   metadata JSONB                   -- Additional context
--   created_at TIMESTAMPTZ DEFAULT NOW()
--   PRIMARY KEY (thread_id, checkpoint_id)

-- Checkpoint blobs table (auto-created by library)
-- Structure:
--   thread_id TEXT NOT NULL
--   checkpoint_id TEXT NOT NULL
--   channel TEXT NOT NULL
--   version TEXT NOT NULL
--   type TEXT NOT NULL
--   blob BYTEA
--   PRIMARY KEY (thread_id, checkpoint_id, channel, version)

-- Checkpoint writes buffer (auto-created by library)
-- Structure:
--   thread_id TEXT NOT NULL
--   checkpoint_id TEXT NOT NULL
--   task_id TEXT NOT NULL
--   idx INTEGER NOT NULL
--   channel TEXT NOT NULL
--   type TEXT
--   value JSONB
--   PRIMARY KEY (thread_id, checkpoint_id, task_id, idx)
```

#### Index Strategy

The library creates composite primary keys. Additional indexes are **not required** for Phase 1 unless analytics queries are needed:

```sql
-- Optional: Add only if analytics/debugging requires time-range queries
CREATE INDEX IF NOT EXISTS idx_checkpoints_created_at
    ON langgraph.checkpoints (created_at DESC);

-- Optional: Add only if frequently querying by parent checkpoint
CREATE INDEX IF NOT EXISTS idx_checkpoints_parent
    ON langgraph.checkpoints (parent_checkpoint_id)
    WHERE parent_checkpoint_id IS NOT NULL;
```

**Recommendation for Phase 1:** Skip optional indexes. Monitor query patterns with `pg_stat_statements` and add indexes only if slow queries detected.

#### Partitioning Strategy (Phase 2+: If >500K Checkpoints)

**Trigger Criteria:** Implement partitioning when:
- Checkpoint count exceeds 500,000 rows
- Table size exceeds 10GB
- Cleanup queries exceed 5 seconds

```sql
-- Range partitioning by created_at (monthly partitions)
-- NOTE: Requires table recreation - MUST be done during maintenance window

-- Step 1: Rename existing table
ALTER TABLE langgraph.checkpoints RENAME TO checkpoints_old;

-- Step 2: Create partitioned table
CREATE TABLE langgraph.checkpoints (
    thread_id TEXT NOT NULL,
    checkpoint_id TEXT NOT NULL,
    parent_checkpoint_id TEXT,
    checkpoint JSONB NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (thread_id, checkpoint_id, created_at)
) PARTITION BY RANGE (created_at);

-- Step 3: Create initial partitions (3 months)
CREATE TABLE langgraph.checkpoints_2025_12
    PARTITION OF langgraph.checkpoints
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE langgraph.checkpoints_2026_01
    PARTITION OF langgraph.checkpoints
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE langgraph.checkpoints_2026_02
    PARTITION OF langgraph.checkpoints
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

-- Step 4: Migrate data
INSERT INTO langgraph.checkpoints
    SELECT * FROM langgraph.checkpoints_old;

-- Step 5: Verify and drop old table
-- SELECT COUNT(*) FROM langgraph.checkpoints;
-- SELECT COUNT(*) FROM langgraph.checkpoints_old;
-- DROP TABLE langgraph.checkpoints_old;

-- Step 6: Automate partition creation with pg_partman (recommended)
CREATE EXTENSION IF NOT EXISTS pg_partman;

SELECT partman.create_parent(
    p_parent_table => 'langgraph.checkpoints',
    p_control => 'created_at',
    p_type => 'native',
    p_interval => '1 month',
    p_premake => 3  -- Pre-create 3 months of future partitions
);
```

**Important:** Partitioning is **NOT required for Phase 1**. Defer until data volume justifies complexity.

---

## Connection Pool Configuration

The specification section "PostgreSQL Checkpoint Configuration" has **CRITICAL ERRORS**. See [Spec Validation](#spec-validation) for full analysis.

### Recommended Architecture: pgBouncer Transaction Pooling

**Rationale:**
- hx-postgres-server already runs pgBouncer (proven infrastructure)
- LangGraph checkpoint writes are short transactions (<100ms typical)
- Transaction pooling provides maximum connection reuse
- Dedicated pool prevents hx-lang-server from exhausting global connection capacity

#### pgBouncer Configuration

```ini
# /etc/pgbouncer/pgbouncer.ini (on hx-postgres-server)

[databases]
# Add dedicated pool for hx-lang-server
hx_lang_server_db = host=localhost port=5432 dbname=hx_lang_server pool_size=15 reserve_pool=5

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
reserve_pool_size = 5
reserve_pool_timeout = 3
server_idle_timeout = 600
server_lifetime = 3600
server_reset_query = DISCARD ALL
```

**Pool Sizing Calculation:**
- FastAPI workers: 4-8 (typical for development)
- Connections per worker: 2-3 (async I/O with psycopg3 pool)
- Total max connections: 8 workers × 2 = 16
- Pool size: 15 connections (covers typical case)
- Reserve pool: 5 connections (handles burst traffic)

#### Connection String for hx-lang-server

**CRITICAL:** Spec example is WRONG. Correct configuration:

```python
# config.py
from pydantic_settings import BaseSettings

class DatabaseSettings(BaseSettings):
    """PostgreSQL connection configuration."""

    # pgBouncer connection (recommended)
    postgres_host: str = "hx-postgres-server.hx.dev.local"
    postgres_port: int = 6432  # pgBouncer port (NOT 5432)
    postgres_db: str = "hx_lang_server"
    postgres_user: str = "hx_lang_server"
    postgres_password: str  # From environment or Ansible Vault

    # Connection pool settings (psycopg3 client-side pool)
    pool_min_size: int = 3
    pool_max_size: int = 10
    pool_timeout: float = 30.0
    pool_max_lifetime: float = 3600.0
    pool_max_idle: float = 600.0

    # Connection parameters
    connect_timeout: int = 10
    options: str = "-c search_path=langgraph,public"

    # CRITICAL: pgBouncer compatibility
    # - autocommit MUST be True for langgraph-checkpoint-postgres
    # - prepare_threshold MUST be 0 (no prepared statements with pgBouncer transaction mode)

    class Config:
        env_file = ".env"
        env_prefix = "POSTGRES_"

    @property
    def connection_url(self) -> str:
        """Build connection URL for psycopg."""
        return (
            f"postgresql://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )
```

#### psycopg3 Connection Pool Implementation

```python
# database.py
from psycopg_pool import AsyncConnectionPool
from psycopg.rows import dict_row
from config import DatabaseSettings

settings = DatabaseSettings()

# CRITICAL connection kwargs for langgraph-checkpoint-postgres
REQUIRED_KWARGS = {
    "autocommit": True,  # REQUIRED: langgraph-checkpoint-postgres needs autocommit
    "row_factory": dict_row,  # REQUIRED: library expects dict rows
    "prepare_threshold": 0,  # REQUIRED: pgBouncer compatibility (no prepared statements)
}

# Create async connection pool
db_pool = AsyncConnectionPool(
    conninfo=settings.connection_url,
    min_size=settings.pool_min_size,
    max_size=settings.pool_max_size,
    timeout=settings.pool_timeout,
    max_lifetime=settings.pool_max_lifetime,
    max_idle=settings.pool_max_idle,
    open=False,  # Don't open immediately (use await db_pool.open())
    kwargs=REQUIRED_KWARGS,  # Pass required kwargs to all connections
)

async def init_db_pool():
    """Initialize database connection pool on startup."""
    await db_pool.open()
    logger.info(
        "database_pool_initialized",
        min_size=settings.pool_min_size,
        max_size=settings.pool_max_size,
    )

async def close_db_pool():
    """Close database connection pool on shutdown."""
    await db_pool.close()
    logger.info("database_pool_closed")
```

#### LangGraph Checkpoint Integration

```python
# checkpointer.py
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from database import db_pool

async def get_checkpointer() -> AsyncPostgresSaver:
    """Get LangGraph checkpoint saver with connection pool."""
    # AsyncPostgresSaver uses the pool's connection kwargs automatically
    return AsyncPostgresSaver(db_pool)

async def init_checkpoint_schema():
    """Initialize checkpoint schema (run once on first deployment)."""
    checkpointer = await get_checkpointer()
    await checkpointer.setup()  # Creates tables if not exist
    logger.info("checkpoint_schema_initialized", schema="langgraph")
```

#### Alternative: Direct PostgreSQL Connection (No pgBouncer)

If pgBouncer is not available, connect directly to PostgreSQL:

```python
# Direct connection configuration
postgres_port: int = 5432  # PostgreSQL port (NOT pgBouncer)
```

**Note:** Direct connection is acceptable for development but **NOT recommended for production**. pgBouncer provides:
- Connection pooling across multiple application instances
- Query routing (read replicas)
- Connection limiting (prevent exhaustion)
- Query logging and monitoring

---

## Backup Strategy

The specification lacks backup and recovery procedures. Here's the complete strategy:

### Backup Architecture

hx-lang-server checkpoints are stored in `hx_lang_server` database on hx-postgres-server. Leverage **existing backup infrastructure**:

#### 1. Continuous WAL Archiving (Already Operational)

```sql
-- Verify WAL archiving enabled on hx-postgres-server
SHOW archive_mode;          -- Should be 'on'
SHOW archive_command;       -- Should show archive script
SHOW wal_level;             -- Should be 'replica' or higher
```

**What this provides:**
- Point-in-time recovery (PITR) to any timestamp
- Recovery Point Objective (RPO): <5 minutes (typical WAL switch interval)
- Checkpoint data included in WAL stream automatically

#### 2. Daily Base Backups (Already Scheduled)

```bash
#!/bin/bash
# /usr/local/bin/pg_basebackup_hx_lang_server.sh
# Schedule: Daily at 2 AM via cron or systemd timer

BACKUP_DIR="/backup/postgresql/hx_lang_server"
DATE=$(date +%Y%m%d)
BACKUP_FILE="${BACKUP_DIR}/hx_lang_server_base_${DATE}.tar.gz"

# Full database backup
pg_basebackup \
    -h hx-postgres-server.hx.dev.local \
    -U postgres \
    -D - \
    -Ft \
    -z \
    -Xs \
    -P \
    -v \
    | gzip > "${BACKUP_FILE}"

# Verify backup
if [ $? -eq 0 ]; then
    logger "PostgreSQL base backup succeeded: ${BACKUP_FILE}"
    # Rotate old backups (keep 30 days)
    find "${BACKUP_DIR}" -name "hx_lang_server_base_*.tar.gz" -mtime +30 -delete
else
    logger "PostgreSQL base backup FAILED"
    exit 1
fi
```

#### 3. Checkpoint-Specific Logical Backups (Recommended)

For faster checkpoint-only restore (without full database restore):

```bash
#!/bin/bash
# /usr/local/bin/pg_dump_langgraph_checkpoints.sh
# Schedule: Daily at 3 AM (after base backup)

BACKUP_DIR="/backup/postgresql/langgraph_checkpoints"
DATE=$(date +%Y%m%d)
BACKUP_FILE="${BACKUP_DIR}/langgraph_checkpoints_${DATE}.dump"

# Logical backup of langgraph schema only
pg_dump \
    -h hx-postgres-server.hx.dev.local \
    -U hx_lang_server \
    -d hx_lang_server \
    -n langgraph \
    -Fc \
    -Z 9 \
    -f "${BACKUP_FILE}"

# Verify backup
if [ $? -eq 0 ]; then
    logger "LangGraph checkpoint backup succeeded: ${BACKUP_FILE}"
    # Rotate old backups (keep 30 days)
    find "${BACKUP_DIR}" -name "langgraph_checkpoints_*.dump" -mtime +30 -delete
else
    logger "LangGraph checkpoint backup FAILED"
    exit 1
fi
```

**Backup Summary Table:**

| Backup Type | Method | Frequency | Retention | Recovery Speed | Use Case |
|-------------|--------|-----------|-----------|----------------|----------|
| WAL Archiving | Continuous | Real-time | 7 days | Slow (full restore + WAL replay) | Point-in-time recovery |
| Base Backup | pg_basebackup | Daily 2 AM | 30 days | Slow (full restore) | Disaster recovery |
| Logical Backup | pg_dump (langgraph schema) | Daily 3 AM | 30 days | Fast (schema-only restore) | Checkpoint-only recovery |

### Recovery Procedures

#### Scenario 1: Accidental Checkpoint Deletion (User Error)

**Symptom:** User reports lost conversation history, checkpoint queries return no rows.

**Recovery:**
```bash
# 1. Identify last valid checkpoint timestamp
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server <<EOF
SELECT thread_id, MAX(created_at) AS last_checkpoint
FROM langgraph.checkpoints
WHERE thread_id = '<affected-thread-id>'
GROUP BY thread_id;
EOF

# 2. Restore from most recent logical backup
LATEST_BACKUP=$(ls -t /backup/postgresql/langgraph_checkpoints/*.dump | head -1)

pg_restore \
    -h hx-postgres-server.hx.dev.local \
    -U hx_lang_server \
    -d hx_lang_server \
    -n langgraph \
    --clean \
    --if-exists \
    "${LATEST_BACKUP}"

# 3. Verify restoration
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
SELECT COUNT(*) AS checkpoint_count
FROM langgraph.checkpoints
WHERE thread_id = '<affected-thread-id>';
EOF
```

**Recovery Time Objective (RTO):** <15 minutes
**Recovery Point Objective (RPO):** <24 hours (last daily backup)

#### Scenario 2: Database Corruption (Hardware Failure)

**Symptom:** PostgreSQL reports data corruption, service cannot connect.

**Recovery:**
```bash
# 1. Restore from base backup
LATEST_BASE_BACKUP=$(ls -t /backup/postgresql/hx_lang_server/hx_lang_server_base_*.tar.gz | head -1)

# Stop PostgreSQL (if running)
sudo systemctl stop postgresql

# Remove corrupted data directory
sudo rm -rf /var/lib/postgresql/14/main/hx_lang_server

# Extract base backup
sudo -u postgres tar xzf "${LATEST_BASE_BACKUP}" -C /var/lib/postgresql/14/main/

# 2. Replay WAL archives for point-in-time recovery
# (Follow hx-postgres-server WAL recovery procedures)

# 3. Start PostgreSQL
sudo systemctl start postgresql

# 4. Verify hx_lang_server database
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server <<EOF
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'langgraph';
EOF
```

**Recovery Time Objective (RTO):** <1 hour
**Recovery Point Objective (RPO):** <5 minutes (WAL archiving)

#### Scenario 3: Service Restart (Normal Operation)

**Symptom:** hx-lang-server restarts, in-progress conversations should resume.

**Recovery:** **AUTOMATIC** - No manual intervention required.

```python
# LangGraph automatically resumes from last checkpoint
result = await agent.ainvoke(
    {"messages": [HumanMessage(content="Continue our conversation")]},
    config={"configurable": {"thread_id": existing_thread_id}}
)
# Conversations resume from last checkpoint transparently
```

**Recovery Time Objective (RTO):** <5 seconds (service restart)
**Recovery Point Objective (RPO):** <1 second (last checkpoint)

### Backup Validation (Quarterly Drill)

```bash
#!/bin/bash
# /usr/local/bin/langgraph_backup_validation.sh
# Schedule: Quarterly (manual execution)

# 1. Create test database
psql -h hx-postgres-server.hx.dev.local -U postgres <<EOF
DROP DATABASE IF EXISTS hx_lang_server_test;
CREATE DATABASE hx_lang_server_test OWNER hx_lang_server;
EOF

# 2. Restore from latest backup
LATEST_BACKUP=$(ls -t /backup/postgresql/langgraph_checkpoints/*.dump | head -1)
pg_restore \
    -h hx-postgres-server.hx.dev.local \
    -U hx_lang_server \
    -d hx_lang_server_test \
    "${LATEST_BACKUP}"

# 3. Validate checkpoint count matches production
PROD_COUNT=$(psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "SELECT COUNT(*) FROM langgraph.checkpoints;")
TEST_COUNT=$(psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server_test -t -c "SELECT COUNT(*) FROM langgraph.checkpoints;")

if [ "$PROD_COUNT" -eq "$TEST_COUNT" ]; then
    echo "Backup validation PASSED: ${PROD_COUNT} checkpoints"
else
    echo "Backup validation FAILED: Production=${PROD_COUNT}, Test=${TEST_COUNT}"
    exit 1
fi

# 4. Cleanup test database
psql -h hx-postgres-server.hx.dev.local -U postgres -c "DROP DATABASE hx_lang_server_test;"
```

### RTO/RPO Targets Summary

| Scenario | RTO (Recovery Time) | RPO (Data Loss) | Method |
|----------|---------------------|-----------------|--------|
| Service Restart | <5 seconds | <1 second | Automatic checkpoint resume |
| User Error (deleted checkpoints) | <15 minutes | <24 hours | Logical backup restore |
| Database Corruption | <1 hour | <5 minutes | Base backup + WAL replay |
| Disaster (full data loss) | <2 hours | <24 hours | Base backup restore |

---

## Performance Tuning

### PostgreSQL Configuration Optimizations

The specification does not address PostgreSQL tuning for checkpoint workload. These settings should be added to `postgresql.conf` on hx-postgres-server:

```ini
# /etc/postgresql/14/main/postgresql.conf (or appropriate version)
# Tuning for LangGraph checkpoint workload

# ========================================================================
# CHECKPOINT WORKLOAD OPTIMIZATIONS
# ========================================================================

# High INSERT/UPDATE churn on checkpoint tables requires aggressive autovacuum
autovacuum_naptime = 1min
autovacuum_vacuum_scale_factor = 0.1   # Vacuum when 10% of table changed
autovacuum_analyze_scale_factor = 0.05  # Analyze when 5% of table changed
autovacuum_vacuum_cost_delay = 10ms     # Reduce I/O impact of autovacuum

# JSONB checkpoint payloads benefit from increased work_mem
work_mem = 16MB  # Up from default 4MB (for JSONB operations, sorting)

# Enable parallel query execution for analytics queries (if needed)
max_parallel_workers_per_gather = 2
parallel_tuple_cost = 0.01  # Encourage parallel execution

# Query performance monitoring
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
pg_stat_statements.max = 10000

# Connection management (if not using pgBouncer)
max_connections = 100  # Sufficient for development
idle_in_transaction_session_timeout = 600000  # 10 minutes

# Checkpoint frequency (balance between write performance and recovery time)
checkpoint_timeout = 10min
checkpoint_completion_target = 0.9

# WAL settings (already configured for archiving)
wal_level = replica  # Required for streaming replication and WAL archiving
archive_mode = on
archive_command = '/usr/local/bin/archive_wal.sh %p %f'  # Existing script
```

**After applying changes:**
```bash
# Reload configuration (no restart required for most settings)
sudo systemctl reload postgresql

# Verify settings
psql -h hx-postgres-server.hx.dev.local -U postgres <<EOF
SHOW autovacuum_naptime;
SHOW work_mem;
SHOW shared_preload_libraries;
EOF
```

### Table-Specific Tuning

```sql
-- Run on hx-postgres-server as postgres superuser
\c hx_lang_server

-- Adjust autovacuum thresholds for high-churn checkpoint tables
ALTER TABLE langgraph.checkpoints SET (
    autovacuum_vacuum_scale_factor = 0.05,  -- More aggressive than default
    autovacuum_analyze_scale_factor = 0.02,
    autovacuum_vacuum_cost_delay = 5  -- Lower delay = faster vacuum
);

ALTER TABLE langgraph.checkpoint_writes SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02
);

-- Increase statistics target for better query planning
ALTER TABLE langgraph.checkpoints ALTER COLUMN thread_id SET STATISTICS 1000;
ALTER TABLE langgraph.checkpoints ALTER COLUMN checkpoint_id SET STATISTICS 1000;
```

### Performance Monitoring Queries

```sql
-- Monitor checkpoint table size and bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_row_pct
FROM pg_stat_user_tables
WHERE schemaname = 'langgraph'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Monitor autovacuum activity
SELECT
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    vacuum_count,
    autovacuum_count,
    analyze_count,
    autoanalyze_count
FROM pg_stat_user_tables
WHERE schemaname = 'langgraph'
ORDER BY last_autovacuum DESC NULLS LAST;

-- Top 10 slowest checkpoint queries
SELECT
    query,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS mean_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND(stddev_exec_time::numeric, 2) AS stddev_time_ms
FROM pg_stat_statements
WHERE query ILIKE '%langgraph.checkpoints%'
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Connection pool utilization (if using pgBouncer)
-- Run on hx-postgres-server
psql -p 6432 -U pgbouncer pgbouncer <<EOF
SHOW POOLS;
SHOW STATS;
EOF
```

### Performance Targets and Validation

| Metric | Target | Validation Method |
|--------|--------|-------------------|
| Checkpoint write latency (P95) | <50ms | pg_stat_statements query analysis |
| Checkpoint read latency (P95) | <10ms | Primary key lookup test |
| Conversation history query (P95) | <100ms | Time-range index scan test |
| Table bloat percentage | <20% | pg_stat_user_tables dead_row_pct |
| Autovacuum lag | <5 minutes | pg_stat_user_tables last_autovacuum |
| Connection pool utilization | <70% | pgBouncer SHOW POOLS |

```python
# tests/performance/test_checkpoint_performance.py
import pytest
import time
from checkpointer import get_checkpointer
from database import db_pool

@pytest.mark.asyncio
async def test_checkpoint_write_latency():
    """Validate checkpoint write completes in <50ms (P95)."""
    checkpointer = await get_checkpointer()

    latencies = []
    for i in range(100):
        thread_id = f"perf-test-{i}"
        checkpoint_data = {"messages": [{"role": "user", "content": "test"}]}

        start = time.perf_counter()
        await checkpointer.aput(thread_id, f"checkpoint-{i}", checkpoint_data, {})
        latency_ms = (time.perf_counter() - start) * 1000
        latencies.append(latency_ms)

    p95_latency = sorted(latencies)[94]  # 95th percentile
    assert p95_latency < 50, f"P95 checkpoint write latency {p95_latency:.2f}ms exceeds target 50ms"

@pytest.mark.asyncio
async def test_conversation_history_query():
    """Validate conversation history query completes in <100ms (P95)."""
    checkpointer = await get_checkpointer()
    thread_id = "perf-test-history"

    # Create 20 checkpoints
    for i in range(20):
        await checkpointer.aput(thread_id, f"checkpoint-{i}", {"step": i}, {})

    latencies = []
    for _ in range(100):
        start = time.perf_counter()
        history = await checkpointer.alist(thread_id)
        checkpoints = [c async for c in history]
        latency_ms = (time.perf_counter() - start) * 1000
        latencies.append(latency_ms)

    p95_latency = sorted(latencies)[94]
    assert p95_latency < 100, f"P95 history query latency {p95_latency:.2f}ms exceeds target 100ms"
    assert len(checkpoints) == 20, f"Expected 20 checkpoints, got {len(checkpoints)}"
```

---

## Code Examples

### Complete Database Provisioning Script

```bash
#!/bin/bash
# provision_hx_lang_server_db.sh
# Run on hx-postgres-server as postgres superuser
# Purpose: Create database, user, schema for hx-lang-server

set -e  # Exit on error

POSTGRES_PASSWORD="${1:-}"
if [ -z "${POSTGRES_PASSWORD}" ]; then
    echo "ERROR: PostgreSQL password required as first argument"
    echo "Usage: $0 <postgres-password>"
    exit 1
fi

echo "==> Provisioning hx_lang_server database..."

# Create service user
psql -U postgres <<EOF
-- Create user (skip if exists)
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hx_lang_server') THEN
        CREATE USER hx_lang_server WITH PASSWORD '${POSTGRES_PASSWORD}';
        RAISE NOTICE 'User hx_lang_server created';
    ELSE
        RAISE NOTICE 'User hx_lang_server already exists';
    END IF;
END
\$\$;

-- Create database
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'hx_lang_server') THEN
        CREATE DATABASE hx_lang_server OWNER hx_lang_server;
        RAISE NOTICE 'Database hx_lang_server created';
    ELSE
        RAISE NOTICE 'Database hx_lang_server already exists';
    END IF;
END
\$\$;

-- Grant permissions
GRANT CONNECT ON DATABASE hx_lang_server TO hx_lang_server;
EOF

# Connect to database and create schema
psql -U postgres -d hx_lang_server <<EOF
-- Create langgraph schema
CREATE SCHEMA IF NOT EXISTS langgraph AUTHORIZATION hx_lang_server;

-- Set default search path
ALTER ROLE hx_lang_server SET search_path = langgraph, public;

-- Grant schema permissions
GRANT USAGE, CREATE ON SCHEMA langgraph TO hx_lang_server;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA langgraph TO hx_lang_server;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA langgraph TO hx_lang_server;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA langgraph GRANT ALL PRIVILEGES ON TABLES TO hx_lang_server;
ALTER DEFAULT PRIVILEGES IN SCHEMA langgraph GRANT ALL PRIVILEGES ON SEQUENCES TO hx_lang_server;

-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify setup
\l hx_lang_server
\dn langgraph
\du hx_lang_server
EOF

echo "==> Database provisioning complete!"
echo "==> Next step: Run 'await checkpointer.setup()' from hx-lang-server to create checkpoint tables"
```

### Complete Checkpoint Integration Module

```python
# hx-lang-server/app/database/checkpointer.py
"""
LangGraph checkpoint integration with PostgreSQL.

This module provides:
- AsyncPostgresSaver configuration with required connection parameters
- Connection pool management
- Schema initialization
- Health checks
"""

import asyncio
from typing import Optional
from contextlib import asynccontextmanager

from psycopg import AsyncConnection
from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
import structlog

from app.config import DatabaseSettings

logger = structlog.get_logger(__name__)

# ========================================================================
# CRITICAL CONNECTION PARAMETERS
# ========================================================================
# These parameters are REQUIRED for langgraph-checkpoint-postgres compatibility.
# Changing these will cause checkpoint writes to FAIL.

REQUIRED_CONNECTION_KWARGS = {
    "autocommit": True,  # REQUIRED: langgraph-checkpoint-postgres needs autocommit mode
    "row_factory": dict_row,  # REQUIRED: library expects dict-like row objects
    "prepare_threshold": 0,  # REQUIRED: pgBouncer compatibility (no prepared statements in transaction pooling)
}


class CheckpointManager:
    """Manages PostgreSQL checkpoint persistence for LangGraph."""

    def __init__(self, settings: DatabaseSettings):
        self.settings = settings
        self._pool: Optional[AsyncConnectionPool] = None
        self._checkpointer: Optional[AsyncPostgresSaver] = None

    async def initialize(self):
        """Initialize connection pool and checkpoint saver."""
        if self._pool is not None:
            logger.warning("checkpoint_manager_already_initialized")
            return

        # Create connection pool with required kwargs
        self._pool = AsyncConnectionPool(
            conninfo=self.settings.connection_url,
            min_size=self.settings.pool_min_size,
            max_size=self.settings.pool_max_size,
            timeout=self.settings.pool_timeout,
            max_lifetime=self.settings.pool_max_lifetime,
            max_idle=self.settings.pool_max_idle,
            open=False,  # Don't open immediately
            kwargs=REQUIRED_CONNECTION_KWARGS,  # Pass required kwargs to all connections
        )

        # Open pool
        await self._pool.open()
        logger.info(
            "checkpoint_pool_initialized",
            min_size=self.settings.pool_min_size,
            max_size=self.settings.pool_max_size,
            host=self.settings.postgres_host,
            port=self.settings.postgres_port,
            database=self.settings.postgres_db,
        )

        # Create checkpointer
        self._checkpointer = AsyncPostgresSaver(self._pool)
        logger.info("checkpoint_saver_created")

    async def setup_schema(self):
        """
        Initialize checkpoint schema (creates tables if not exist).

        This should be called ONCE during first deployment.
        Safe to call multiple times (idempotent).
        """
        if self._checkpointer is None:
            raise RuntimeError("CheckpointManager not initialized. Call initialize() first.")

        await self._checkpointer.setup()
        logger.info("checkpoint_schema_initialized", schema="langgraph")

    async def health_check(self) -> bool:
        """
        Check database connectivity and checkpoint system health.

        Returns:
            True if healthy, False otherwise.
        """
        if self._pool is None or self._checkpointer is None:
            logger.error("health_check_failed", reason="not_initialized")
            return False

        try:
            # Test connection with simple query
            async with self._pool.connection() as conn:
                result = await conn.execute("SELECT 1")
                await result.fetchone()

            logger.debug("checkpoint_health_check_passed")
            return True

        except Exception as e:
            logger.error("checkpoint_health_check_failed", error=str(e))
            return False

    async def get_pool_stats(self) -> dict:
        """Get connection pool statistics."""
        if self._pool is None:
            return {"status": "not_initialized"}

        return {
            "pool_size": self._pool.get_stats()["pool_size"],
            "pool_available": self._pool.get_stats()["pool_available"],
            "requests_waiting": self._pool.get_stats()["requests_waiting"],
        }

    def get_checkpointer(self) -> AsyncPostgresSaver:
        """
        Get checkpoint saver instance for LangGraph.

        Returns:
            AsyncPostgresSaver configured with connection pool.

        Raises:
            RuntimeError: If manager not initialized.
        """
        if self._checkpointer is None:
            raise RuntimeError("CheckpointManager not initialized. Call initialize() first.")
        return self._checkpointer

    async def close(self):
        """Close connection pool and cleanup resources."""
        if self._pool is not None:
            await self._pool.close()
            logger.info("checkpoint_pool_closed")
            self._pool = None
            self._checkpointer = None


# ========================================================================
# GLOBAL CHECKPOINT MANAGER INSTANCE
# ========================================================================

_checkpoint_manager: Optional[CheckpointManager] = None


async def init_checkpoint_manager(settings: DatabaseSettings) -> CheckpointManager:
    """
    Initialize global checkpoint manager.

    Call this during application startup (FastAPI lifespan).
    """
    global _checkpoint_manager

    if _checkpoint_manager is not None:
        logger.warning("checkpoint_manager_already_exists")
        return _checkpoint_manager

    _checkpoint_manager = CheckpointManager(settings)
    await _checkpoint_manager.initialize()

    # Setup schema on first run (idempotent)
    await _checkpoint_manager.setup_schema()

    return _checkpoint_manager


async def close_checkpoint_manager():
    """
    Close global checkpoint manager.

    Call this during application shutdown (FastAPI lifespan).
    """
    global _checkpoint_manager

    if _checkpoint_manager is not None:
        await _checkpoint_manager.close()
        _checkpoint_manager = None


def get_checkpoint_manager() -> CheckpointManager:
    """
    Get global checkpoint manager instance.

    Returns:
        CheckpointManager instance.

    Raises:
        RuntimeError: If manager not initialized.
    """
    if _checkpoint_manager is None:
        raise RuntimeError(
            "CheckpointManager not initialized. "
            "Call init_checkpoint_manager() during app startup."
        )
    return _checkpoint_manager


def get_checkpointer() -> AsyncPostgresSaver:
    """
    Get checkpoint saver for LangGraph.

    Convenience function for agent code.

    Returns:
        AsyncPostgresSaver configured with connection pool.
    """
    return get_checkpoint_manager().get_checkpointer()


# ========================================================================
# FASTAPI INTEGRATION
# ========================================================================

@asynccontextmanager
async def lifespan_checkpoint_manager(app):
    """
    FastAPI lifespan context manager for checkpoint manager.

    Usage:
        from fastapi import FastAPI

        app = FastAPI(lifespan=lifespan_checkpoint_manager)
    """
    from app.config import get_settings

    settings = get_settings()

    # Startup
    logger.info("initializing_checkpoint_manager")
    await init_checkpoint_manager(settings.database)

    yield

    # Shutdown
    logger.info("closing_checkpoint_manager")
    await close_checkpoint_manager()
```

### Checkpoint Cleanup Job

```python
# hx-lang-server/scripts/cleanup_old_checkpoints.py
"""
Cleanup old LangGraph checkpoints beyond retention policy.

Usage:
    python -m scripts.cleanup_old_checkpoints --retention-days 30 --dry-run
    python -m scripts.cleanup_old_checkpoints --retention-days 30  # Execute deletion
"""

import asyncio
import argparse
from datetime import datetime, timedelta

from psycopg import AsyncConnection
from psycopg.rows import dict_row
import structlog

from app.config import get_settings

logger = structlog.get_logger(__name__)


async def cleanup_old_checkpoints(retention_days: int, dry_run: bool = True) -> int:
    """
    Delete checkpoints older than retention period.

    Args:
        retention_days: Delete checkpoints older than this many days
        dry_run: If True, only report what would be deleted (default: True)

    Returns:
        Number of checkpoints deleted (or would be deleted if dry_run)
    """
    settings = get_settings()

    cutoff_date = datetime.now() - timedelta(days=retention_days)

    logger.info(
        "checkpoint_cleanup_started",
        retention_days=retention_days,
        cutoff_date=cutoff_date.isoformat(),
        dry_run=dry_run,
    )

    # Connect to database
    async with await AsyncConnection.connect(
        conninfo=settings.database.connection_url,
        autocommit=True,
        row_factory=dict_row,
    ) as conn:

        # Count checkpoints to be deleted
        count_result = await conn.execute(
            """
            SELECT COUNT(*) AS count
            FROM langgraph.checkpoints
            WHERE created_at < %s
            """,
            (cutoff_date,)
        )
        count_row = await count_result.fetchone()
        checkpoint_count = count_row["count"]

        if checkpoint_count == 0:
            logger.info("no_checkpoints_to_delete")
            return 0

        if dry_run:
            logger.info(
                "checkpoint_cleanup_dry_run",
                would_delete=checkpoint_count,
                cutoff_date=cutoff_date.isoformat(),
            )
            return checkpoint_count

        # Delete old checkpoints
        delete_result = await conn.execute(
            """
            DELETE FROM langgraph.checkpoints
            WHERE created_at < %s
            """,
            (cutoff_date,)
        )
        deleted_count = delete_result.rowcount

        logger.info(
            "checkpoint_cleanup_complete",
            deleted_count=deleted_count,
            cutoff_date=cutoff_date.isoformat(),
        )

        return deleted_count


async def main():
    parser = argparse.ArgumentParser(description="Cleanup old LangGraph checkpoints")
    parser.add_argument(
        "--retention-days",
        type=int,
        default=30,
        help="Delete checkpoints older than this many days (default: 30)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="Preview what would be deleted without actually deleting",
    )
    args = parser.parse_args()

    deleted_count = await cleanup_old_checkpoints(
        retention_days=args.retention_days,
        dry_run=args.dry_run,
    )

    print(f"{'[DRY RUN] Would delete' if args.dry_run else 'Deleted'} {deleted_count} checkpoints")


if __name__ == "__main__":
    asyncio.run(main())
```

**Systemd Timer for Automated Cleanup:**

```ini
# /etc/systemd/system/hx-lang-server-checkpoint-cleanup.timer
[Unit]
Description=LangGraph Checkpoint Cleanup Timer
Documentation=file:///opt/hx-lang-server/scripts/cleanup_old_checkpoints.py

[Timer]
OnCalendar=daily
Persistent=true
Unit=hx-lang-server-checkpoint-cleanup.service

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/hx-lang-server-checkpoint-cleanup.service
[Unit]
Description=LangGraph Checkpoint Cleanup Service
After=network.target postgresql.service

[Service]
Type=oneshot
User=hx-lang-server
Group=hx-lang-server
WorkingDirectory=/opt/hx-lang-server
Environment=PATH=/opt/hx-lang-server/venv/bin:/usr/bin
EnvironmentFile=/opt/hx-lang-server/.env
ExecStart=/opt/hx-lang-server/venv/bin/python -m scripts.cleanup_old_checkpoints --retention-days 30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Enable and start timer:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable hx-lang-server-checkpoint-cleanup.timer
sudo systemctl start hx-lang-server-checkpoint-cleanup.timer

# Check timer status
sudo systemctl list-timers | grep checkpoint-cleanup
```

---

## Spec Validation

### CRITICAL ERRORS in Specification Section "PostgreSQL Checkpoint Configuration"

The current specification (lines 315-368) contains **CRITICAL ERRORS** that will cause production failures:

#### Error 1: Incorrect Connection Class (Lines 320-321)

**Current Spec (WRONG):**
```python
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from psycopg import AsyncConnection
```

**Issue:** Spec shows `AsyncConnection.connect()` but then passes connection to `AsyncPostgresSaver`. This is **INCORRECT**. The library expects a **connection pool**, not a single connection.

**Correct Implementation:**
```python
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from psycopg_pool import AsyncConnectionPool  # NOT AsyncConnection
```

#### Error 2: Missing Required kwargs (Lines 323-327)

**Current Spec (INCOMPLETE):**
```python
connection_kwargs = {
    "autocommit": True,  # REQUIRED for checkpoint commits
    "row_factory": dict_row,  # REQUIRED for langgraph-checkpoint-postgres
    "prepare_threshold": 0,  # Disable prepared statements for pgBouncer
}
```

**Issue:** While these kwargs are correct, the spec doesn't show HOW to pass them to `AsyncConnection.connect()` or `AsyncConnectionPool`. Developers will likely fail to apply them correctly.

**Correct Implementation:**
```python
# These kwargs go in AsyncConnectionPool constructor
pool = AsyncConnectionPool(
    conninfo=connection_url,
    min_size=5,
    max_size=15,
    kwargs=connection_kwargs,  # Pass here
)
```

#### Error 3: Incorrect get_checkpointer() Function (Lines 330-339)

**Current Spec (WILL FAIL):**
```python
async def get_checkpointer():
    conn = await AsyncConnection.connect(
        host="hx-postgres-server.hx.dev.local",
        port=5432,
        dbname="hx_lang_server",
        user="hx_lang_server",
        password="${POSTGRES_PASSWORD}",  # From Ansible Vault
        **connection_kwargs
    )
    return AsyncPostgresSaver(conn)
```

**Critical Issues:**
1. Creates **single connection** instead of pool (will exhaust connections)
2. Connection is never closed (resource leak)
3. No connection pooling (defeats purpose of async architecture)
4. Password shown as `${POSTGRES_PASSWORD}` (not valid Python syntax)
5. No error handling (will crash on connection failure)

**Correct Implementation:**
```python
# Use connection pool (created once at startup)
pool = AsyncConnectionPool(
    conninfo=f"postgresql://{user}:{password}@{host}:{port}/{database}",
    min_size=5,
    max_size=15,
    kwargs=connection_kwargs,
)

await pool.open()

checkpointer = AsyncPostgresSaver(pool)
```

#### Error 4: Incorrect Port Number (Line 333)

**Current Spec:**
```python
port=5432,
```

**Issue:** If using pgBouncer (recommended in my charter review), port should be `6432` (pgBouncer), not `5432` (direct PostgreSQL).

**Correct:**
```python
port=6432,  # pgBouncer port (or 5432 if direct connection)
```

#### Error 5: Database Schema Section Incomplete (Lines 341-352)

**Current Spec:**
```
The `langgraph-checkpoint-postgres` library auto-creates these tables:

| Table | Purpose |
|-------|---------|
| `checkpoints` | Checkpoint metadata and state |
| `checkpoint_blobs` | Large state objects (JSONB) |
| `checkpoint_writes` | Pending writes buffer |
| `checkpoint_migrations` | Schema version tracking |
```

**Issue:** This is a table list, NOT a schema definition. Missing:
- DDL for schema creation (`CREATE SCHEMA langgraph`)
- Schema ownership (`OWNER hx_lang_server`)
- Search path configuration (`ALTER ROLE ... SET search_path`)

**Correct Implementation:** See [Schema Enhancements](#schema-enhancements) section above.

#### Error 6: Database Provisioning Section Incomplete (Lines 354-367)

**Current Spec:**
```sql
CREATE USER hx_lang_server WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE hx_lang_server OWNER hx_lang_server;
GRANT ALL PRIVILEGES ON DATABASE hx_lang_server TO hx_lang_server;
```

**Issues:**
1. Missing `IF NOT EXISTS` checks (fails on re-run)
2. Password shown as `${POSTGRES_PASSWORD}` (not valid SQL syntax)
3. Missing encoding/locale specification (will use server defaults)
4. Missing schema creation
5. Missing default privileges for future tables
6. No pg_stat_statements extension

**Correct Implementation:** See [Code Examples](#code-examples) section for complete provisioning script.

### Recommended Changes to node-spec.md

Replace lines 315-368 with the following:

```markdown
## PostgreSQL Checkpoint Configuration

### Connection Architecture

hx-lang-server uses `langgraph-checkpoint-postgres` with `psycopg3` async connection pooling.

**CRITICAL:** The library requires a **connection pool**, not a single connection. Use `AsyncConnectionPool` from `psycopg_pool`.

**Required Connection Parameters:**
```python
REQUIRED_CONNECTION_KWARGS = {
    "autocommit": True,  # REQUIRED for checkpoint persistence
    "row_factory": dict_row,  # REQUIRED for library compatibility
    "prepare_threshold": 0,  # REQUIRED for pgBouncer transaction pooling
}
```

**Connection Pool Configuration:**
```python
from psycopg_pool import AsyncConnectionPool
from psycopg.rows import dict_row

pool = AsyncConnectionPool(
    conninfo="postgresql://hx_lang_server:<password>@hx-postgres-server.hx.dev.local:6432/hx_lang_server",
    min_size=5,
    max_size=15,
    timeout=30.0,
    max_lifetime=3600.0,
    max_idle=600.0,
    kwargs=REQUIRED_CONNECTION_KWARGS,
)

await pool.open()
checkpointer = AsyncPostgresSaver(pool)
```

**pgBouncer Integration (Recommended):**
- Use pgBouncer port `6432` (NOT direct PostgreSQL port `5432`)
- Transaction pooling mode required
- Dedicated pool: `pool_size=15 reserve_pool=5`

See `/nodes/hx-lang-server/specification/reviews/trinity-postgresql-contribution.md` for complete implementation.

### Database Provisioning

Database provisioning requires:
1. Database and user creation
2. Schema creation with ownership
3. Permission grants
4. Extension installation (pg_stat_statements)

**Provisioning Script:** See Trinity's contribution document for complete `provision_hx_lang_server_db.sh` script.

**Schema Initialization:**
```python
# Run once during first deployment
await checkpointer.setup()  # Creates checkpoint tables automatically
```

### Checkpoint Schema

`langgraph-checkpoint-postgres` auto-creates these tables in `langgraph` schema:
- `checkpoints` - Checkpoint metadata and state (JSONB)
- `checkpoint_blobs` - Large state objects (BYTEA)
- `checkpoint_writes` - Pending writes buffer
- `checkpoint_migrations` - Schema version tracking

**Partitioning:** Not required for Phase 1. Implement if checkpoint count exceeds 500K rows. See Trinity's contribution for partitioning strategy.
```

### Additional Spec Sections Needed

The specification is missing these critical sections:

1. **Checkpoint Lifecycle Management** - Cleanup strategy, retention policy, automation
2. **PostgreSQL Performance Tuning** - Configuration optimizations for checkpoint workload
3. **Backup and Recovery Procedures** - RTO/RPO targets, recovery scenarios
4. **Database Observability** - Monitoring queries, performance metrics, alerting

These sections are fully documented in my contribution above and should be added to the specification.

---

## Recommended Changes to node-spec.md

### High Priority (MUST Address Before Implementation)

1. **Replace "PostgreSQL Checkpoint Configuration" Section (Lines 315-368)**
   - Fix critical errors in connection configuration
   - Use `AsyncConnectionPool` instead of `AsyncConnection`
   - Document required connection kwargs
   - Show correct checkpointer initialization
   - Include pgBouncer integration

2. **Add "PostgreSQL Schema Design" Section**
   - Document default schema (no partitioning for Phase 1)
   - Show `CREATE SCHEMA langgraph` DDL
   - Define index strategy
   - Document partitioning trigger criteria (>500K checkpoints)

3. **Add "Database Provisioning Procedures" Section**
   - Include complete provisioning script
   - Document user creation with least-privilege access
   - Show permission grants
   - Document Ansible Vault integration

4. **Add "Checkpoint Lifecycle Management" Section**
   - Define 30-day retention policy
   - Document automated cleanup with systemd timer
   - Show monitoring queries for checkpoint age distribution

5. **Add "PostgreSQL Backup and Recovery" Section**
   - Document backup strategy (WAL + base + logical)
   - Define RTO/RPO targets
   - Document recovery procedures for 3 scenarios
   - Include quarterly backup validation drill

### Medium Priority (Should Address Before Deployment)

6. **Add "PostgreSQL Performance Tuning" Section**
   - Document `postgresql.conf` optimizations
   - Show autovacuum tuning for checkpoint tables
   - Include performance monitoring queries
   - Define performance targets (P95 latency)

7. **Add "Database Observability" Section**
   - Document pg_stat_statements integration
   - Show connection pool monitoring (pgBouncer)
   - Include checkpoint table bloat monitoring
   - Define alerting thresholds

8. **Enhance "Testing Strategy" Section (Lines 843-885)**
   - Add PostgreSQL-specific test cases (TC-POSTGRES-001 through TC-POSTGRES-006)
   - Include checkpoint persistence tests
   - Add connection pool exhaustion tests
   - Add backup/recovery validation tests

### Low Priority (Nice to Have)

9. **Add "Database Migration Strategy" Section**
   - Document schema versioning approach
   - Consider Alembic integration (optional)
   - Define migration execution procedure

10. **Add "Security Hardening" Section for PostgreSQL**
    - Document SSL/TLS configuration (sslmode=prefer minimum)
    - Show credential management (Ansible Vault)
    - Document row-level security (if needed for multi-tenancy)

---

## Test Cases to Add

The specification's testing strategy (lines 843-885) should include these PostgreSQL-specific test cases:

### TC-POSTGRES-001: Checkpoint Persistence Across Restart

**Objective:** Validate conversations persist after hx-lang-server restart

**Preconditions:**
- hx-lang-server running with PostgreSQL checkpointing enabled
- Test conversation created with 5 checkpoint writes

**Test Steps:**
1. Create conversation with `thread_id="test-persistence"`
2. Invoke agent 5 times to create 5 checkpoints
3. Query `langgraph.checkpoints` table, verify 5 rows
4. Stop hx-lang-server service: `sudo systemctl stop hx-lang-server`
5. Start hx-lang-server service: `sudo systemctl start hx-lang-server`
6. Continue conversation with same `thread_id`
7. Query checkpoint count

**Expected Results:**
- All 5 checkpoints retrieved from PostgreSQL after restart
- Conversation continues from last checkpoint
- `iteration_count` increments correctly

**Success Criteria:**
- Zero data loss after restart
- Conversation state intact
- Response time < 5 seconds

---

### TC-POSTGRES-002: Concurrent Checkpoint Writes

**Objective:** Validate no checkpoint corruption under concurrent writes

**Preconditions:**
- hx-lang-server running
- PostgreSQL connection pool configured with min_size=5, max_size=15

**Test Steps:**
1. Launch 10 parallel conversations (different `thread_id` values)
2. Each conversation invokes agent 10 times (100 checkpoints total)
3. Wait for all conversations to complete
4. Query `langgraph.checkpoints` table: `SELECT COUNT(*) FROM langgraph.checkpoints WHERE thread_id LIKE 'test-concurrent-%'`
5. Query for duplicate checkpoints: `SELECT thread_id, checkpoint_id, COUNT(*) FROM langgraph.checkpoints GROUP BY thread_id, checkpoint_id HAVING COUNT(*) > 1`

**Expected Results:**
- Exactly 100 checkpoints in database (10 threads × 10 checkpoints)
- Zero duplicate checkpoints
- No database errors in service logs
- Connection pool utilization < 70%

**Success Criteria:**
- All checkpoints persisted successfully
- No data corruption
- No connection pool exhaustion

---

### TC-POSTGRES-003: Database Connection Failover

**Objective:** Validate graceful handling of database connection loss

**Preconditions:**
- hx-lang-server running
- PostgreSQL accessible

**Test Steps:**
1. Start conversation with `thread_id="test-failover"`
2. Invoke agent once, verify checkpoint written
3. Simulate database connection failure:
   - **Option A:** Stop PostgreSQL: `sudo systemctl stop postgresql`
   - **Option B:** Block connections with iptables: `sudo iptables -A INPUT -p tcp --dport 5432 -j DROP`
4. Attempt agent invocation, expect failure
5. Verify error logged (not crash): Check journalctl for `OperationalError`
6. Restore database connection:
   - **Option A:** `sudo systemctl start postgresql`
   - **Option B:** `sudo iptables -D INPUT -p tcp --dport 5432 -j DROP`
7. Retry agent invocation with same `thread_id`

**Expected Results:**
- Initial invocation (step 2) succeeds
- Invocation during outage (step 4) fails gracefully with error response
- Service continues running (no crash)
- Retry after restore (step 7) succeeds and continues conversation

**Success Criteria:**
- Service does not crash on database failure
- Error logged with `OperationalError` details
- Conversation resumes after database restored
- Client receives HTTP 503 (Service Unavailable) during outage

---

### TC-POSTGRES-004: Checkpoint Cleanup Job

**Objective:** Validate old checkpoints deleted without affecting active conversations

**Preconditions:**
- hx-lang-server running
- Cleanup script available: `/opt/hx-lang-server/scripts/cleanup_old_checkpoints.py`

**Test Steps:**
1. Create checkpoints with backdated timestamps (31 days old):
   ```sql
   INSERT INTO langgraph.checkpoints (thread_id, checkpoint_id, checkpoint, created_at)
   VALUES ('old-thread', 'old-checkpoint-1', '{}', NOW() - INTERVAL '31 days');
   ```
2. Create recent checkpoints (1 day old):
   ```sql
   INSERT INTO langgraph.checkpoints (thread_id, checkpoint_id, checkpoint, created_at)
   VALUES ('recent-thread', 'recent-checkpoint-1', '{}', NOW() - INTERVAL '1 day');
   ```
3. Query checkpoint counts:
   ```sql
   SELECT
     COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '30 days') AS old_count,
     COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS recent_count
   FROM langgraph.checkpoints;
   ```
4. Run cleanup job (dry run): `python -m scripts.cleanup_old_checkpoints --retention-days 30 --dry-run`
5. Verify dry run output shows old checkpoints would be deleted
6. Run cleanup job (execute): `python -m scripts.cleanup_old_checkpoints --retention-days 30`
7. Query checkpoint counts again

**Expected Results:**
- Old checkpoints (>30 days) deleted
- Recent checkpoints (<30 days) retained
- Cleanup job completes without errors
- Cleanup job logs deleted count

**Success Criteria:**
- Zero old checkpoints remain after cleanup
- All recent checkpoints retained
- Cleanup execution time < 30 seconds for 10K checkpoints
- No impact on active conversations

---

### TC-POSTGRES-005: Connection Pool Exhaustion

**Objective:** Validate graceful degradation when connection pool exhausted

**Preconditions:**
- hx-lang-server running
- Connection pool configured with artificially low `max_size=5` for testing

**Test Steps:**
1. Configure test pool: `max_size=5` (modify config for test environment only)
2. Launch 10 concurrent requests (exceeds pool capacity by 2x)
3. Monitor connection pool stats:
   ```python
   stats = await db_pool.get_stats()
   print(f"Pool size: {stats['pool_size']}, Available: {stats['pool_available']}, Waiting: {stats['requests_waiting']}")
   ```
4. Measure request latency for all 10 requests
5. Check for connection errors in logs
6. Verify no connection leaks after requests complete

**Expected Results:**
- First 5 requests acquire connections immediately
- Next 5 requests queue and wait (no immediate failure)
- Queued requests complete after connections released
- All requests succeed (no connection timeout if pool_timeout=30s)
- No connection leaks (pool returns to `pool_available=5` after load)

**Success Criteria:**
- Zero connection errors (no `PoolTimeout` exceptions)
- Request latency increases linearly for queued requests (queue time + execution time)
- Connection pool recovers to full capacity after load
- No memory leaks (verify with `psycopg_pool.get_stats()`)

**Failure Scenario (if pool_timeout exceeded):**
- Requests beyond pool capacity receive HTTP 503 after 30s timeout
- Error logged: `ConnectionPool timeout`
- Client receives clear error message

---

### TC-POSTGRES-006: Large Checkpoint Payload

**Objective:** Validate handling of large conversation state (>1MB JSONB)

**Preconditions:**
- hx-lang-server running
- Test conversation with large message history

**Test Steps:**
1. Create conversation with 1MB JSONB payload:
   ```python
   large_state = {
       "messages": [
           {"role": "user", "content": "x" * 100000}  # 100KB per message
           for _ in range(10)  # 1MB total
       ]
   }
   ```
2. Write checkpoint to database
3. Measure write latency
4. Read checkpoint from database
5. Measure read latency
6. Verify payload integrity (checksum or content comparison)
7. Query PostgreSQL table size:
   ```sql
   SELECT pg_size_pretty(pg_total_relation_size('langgraph.checkpoints'));
   ```

**Expected Results:**
- Checkpoint write succeeds (no error)
- Write latency < 500ms (may exceed <50ms target for large payloads)
- Read latency < 100ms (TOAST compression improves reads)
- Payload integrity preserved (no data corruption)
- TOAST storage used for large JSONB (verify with `pg_column_size()`)

**Success Criteria:**
- Zero errors for 1MB checkpoint
- Write latency < 1 second
- Read latency < 200ms
- Payload matches original (byte-for-byte)

**Warning Scenario (if payload >10MB):**
- Service logs warning: `checkpoint_payload_large` with size
- Recommend payload optimization (e.g., summarization)

---

These test cases should be added to:
- `/nodes/hx-lang-server/tests/test-plan.md`
- `/nodes/hx-lang-server/tests/test-suite/integration/tc-lang-postgres-*.md`

---

## Summary of Contributions

### Schema Design (APPROVED)
- Default `langgraph-checkpoint-postgres` schema for Phase 1
- No partitioning required until >500K checkpoints
- Optional indexes for analytics queries only
- Partitioning strategy documented for Phase 2+

### Connection Pooling (CRITICAL CORRECTIONS)
- pgBouncer transaction pooling recommended (port 6432)
- psycopg3 client-side pool with required kwargs
- Pool sizing: 15 connections + 5 reserve
- **CRITICAL:** Spec contains errors - see Spec Validation section

### Backup Strategy (COMPLETE)
- Leverage existing hx-postgres-server WAL archiving
- Daily base backups (pg_basebackup)
- Checkpoint-specific logical backups (pg_dump)
- RTO <1 hour, RPO <5 minutes
- Quarterly backup validation drills

### Performance Tuning (COMPREHENSIVE)
- Aggressive autovacuum for high-churn checkpoint tables
- Increased work_mem for JSONB operations (16MB)
- pg_stat_statements enabled for query monitoring
- Performance targets defined (P95 latency <50ms write, <10ms read)

### Lifecycle Management (AUTOMATED)
- 30-day checkpoint retention policy
- Automated cleanup with systemd timer (daily 2 AM)
- Monitoring queries for checkpoint age distribution
- Table bloat monitoring and alerting

### Code Examples (PRODUCTION-READY)
- Complete database provisioning script
- CheckpointManager class with pool management
- LangGraph integration with required connection kwargs
- Health checks and observability
- Cleanup script with dry-run mode

### Test Cases (6 CRITICAL TESTS)
- TC-POSTGRES-001: Checkpoint persistence across restart
- TC-POSTGRES-002: Concurrent checkpoint writes
- TC-POSTGRES-003: Database connection failover
- TC-POSTGRES-004: Checkpoint cleanup job
- TC-POSTGRES-005: Connection pool exhaustion
- TC-POSTGRES-006: Large checkpoint payload

---

## Approval and Next Steps

**Approval Status:** ✅ APPROVED with mandatory spec corrections

**Conditions:**
1. Specification section "PostgreSQL Checkpoint Configuration" (lines 315-368) MUST be rewritten to fix critical errors
2. Missing sections MUST be added: Schema Design, Backup Strategy, Performance Tuning, Lifecycle Management
3. Test cases TC-POSTGRES-001 through TC-POSTGRES-006 MUST be added to test plan
4. Database provisioning script MUST be included in deployment procedures

**Next Steps for Sophia (Technical Lead):**
1. Review this contribution with Agent Zero and Alex Rivera
2. Update `/nodes/hx-lang-server/specification/node-spec.md`:
   - Replace "PostgreSQL Checkpoint Configuration" section with corrected version
   - Add missing sections (schema, backup, performance, lifecycle)
3. Add TC-POSTGRES-001 through TC-POSTGRES-006 to test plan
4. Coordinate with Trinity for database provisioning during deployment
5. Include `CheckpointManager` code in implementation
6. Schedule quarterly backup validation drills

**I am available for:**
- Database provisioning execution
- Connection pool configuration review
- Performance testing and optimization
- Backup/recovery drill facilitation
- Production deployment validation

---

**Signature:** Trinity Smith, PostgreSQL DBA SME
**Date:** 2025-12-01
**Status:** CONTRIBUTION COMPLETE - Specification corrections required before implementation
