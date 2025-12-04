# Task: Verify langgraph-checkpoint-postgres Table Auto-Creation

**Task ID**: hx-lang-server-task-036-verify-checkpoint-tables
**Phase**: Installation (Work Stream 4: PostgreSQL Integration)
**Assigned To**: Trinity (PostgreSQL DBA)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-035 (connection configuration)
**Estimated Time**: 15 minutes

---

## Objective

Verify that the langgraph-checkpoint-postgres library automatically creates the required checkpoint tables (checkpoints, checkpoint_blobs, checkpoint_writes, checkpoint_migrations) in the `langgraph` schema when the AsyncPostgresSaver is first initialized.

---

## Prerequisites

- [ ] Database `hx_lang_server` exists with `langgraph` schema (task-031, task-034)
- [ ] Connection parameters configured with `autocommit=True` and `row_factory=dict_row` (task-035)
- [ ] Connection test passed successfully (task-035 verification)
- [ ] langgraph-checkpoint-postgres installed in virtual environment (`pip install langgraph-checkpoint-postgres>=2.0.0`)

---

## Steps

### 1. Verify langgraph Schema is Empty

```bash
# SSH to hx-lang-server.hx.dev.local
ssh hx-lang-server@hx-lang-server.hx.dev.local

# Check current schema state (should be empty before initialization)
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
-- List all tables in langgraph schema
SELECT schemaname, tablename, tableowner
FROM pg_tables
WHERE schemaname = 'langgraph'
ORDER BY tablename;
EOF
```

Expected output: `(0 rows)` - Schema should be empty

### 2. Install langgraph-checkpoint-postgres

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Install checkpoint library
pip install langgraph-checkpoint-postgres>=2.0.0

# Verify installation
python -c "from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver; print('✓ AsyncPostgresSaver imported successfully')"
```

### 3. Create Checkpoint Initialization Script

```bash
# Create script to initialize AsyncPostgresSaver and trigger table creation
cat > /opt/hx-lang-server/test_checkpoint_init.py <<'EOF'
#!/usr/bin/env python3
"""
Initialize langgraph-checkpoint-postgres and verify table auto-creation.
"""

import asyncio
import sys
from pathlib import Path

# Add app directory to path
sys.path.insert(0, str(Path(__file__).parent / "app"))

from psycopg import AsyncConnection
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from config.db_config import get_postgres_connection_params, get_connection_string


async def initialize_checkpoint_tables():
    """Initialize AsyncPostgresSaver to trigger table auto-creation."""
    print("=" * 70)
    print("langgraph-checkpoint-postgres Table Initialization Test")
    print("=" * 70)

    # Connect to PostgreSQL
    print("\n[1/5] Connecting to PostgreSQL...")
    params = get_postgres_connection_params()
    print(f"  Connection string: {get_connection_string()}")

    try:
        conn = await AsyncConnection.connect(**params)
        print("  ✓ Connection established")
    except Exception as e:
        print(f"  ✗ Connection failed: {e}")
        return False

    # Verify schema is empty before initialization
    print("\n[2/5] Checking initial schema state...")
    try:
        result = await conn.execute("""
            SELECT COUNT(*) as table_count
            FROM pg_tables
            WHERE schemaname = 'langgraph';
        """)
        row = await result.fetchone()
        initial_count = row["table_count"] if isinstance(row, dict) else row[0]
        print(f"  Tables in langgraph schema (before): {initial_count}")
    except Exception as e:
        print(f"  ✗ Schema check failed: {e}")
        await conn.close()
        return False

    # Initialize AsyncPostgresSaver (triggers table creation)
    print("\n[3/5] Initializing AsyncPostgresSaver...")
    try:
        checkpointer = AsyncPostgresSaver(conn)
        await checkpointer.setup()  # Explicitly call setup() to create tables
        print("  ✓ AsyncPostgresSaver initialized")
        print("  ✓ setup() completed (tables auto-created)")
    except Exception as e:
        print(f"  ✗ Initialization failed: {e}")
        await conn.close()
        return False

    # Verify tables were created
    print("\n[4/5] Verifying checkpoint tables exist...")
    expected_tables = ["checkpoints", "checkpoint_blobs", "checkpoint_writes", "checkpoint_migrations"]

    try:
        result = await conn.execute("""
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'langgraph'
            ORDER BY tablename;
        """)
        rows = await result.fetchall()
        created_tables = [row["tablename"] if isinstance(row, dict) else row[0] for row in rows]

        print(f"  Tables found: {', '.join(created_tables)}")

        # Check each expected table
        missing_tables = []
        for table in expected_tables:
            if table in created_tables:
                print(f"  ✓ {table} exists")
            else:
                print(f"  ✗ {table} missing")
                missing_tables.append(table)

        if missing_tables:
            print(f"\n  ERROR: Missing tables: {', '.join(missing_tables)}")
            await conn.close()
            return False

    except Exception as e:
        print(f"  ✗ Table verification failed: {e}")
        await conn.close()
        return False

    # Verify table structure
    print("\n[5/5] Verifying table structures...")

    try:
        # Check checkpoints table structure
        result = await conn.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'langgraph' AND table_name = 'checkpoints'
            ORDER BY ordinal_position;
        """)
        columns = await result.fetchall()
        print(f"  checkpoints table: {len(columns)} columns")

        # Verify key columns exist
        column_names = [col["column_name"] if isinstance(col, dict) else col[0] for col in columns]
        required_columns = ["thread_id", "checkpoint_ns", "checkpoint_id", "checkpoint"]

        for col in required_columns:
            if col in column_names:
                print(f"    ✓ {col} column exists")
            else:
                print(f"    ✗ {col} column missing")
                await conn.close()
                return False

    except Exception as e:
        print(f"  ✗ Structure verification failed: {e}")
        await conn.close()
        return False

    # Close connection
    await conn.close()
    print("\n" + "=" * 70)
    print("✅ ALL TESTS PASSED - Checkpoint tables initialized correctly")
    print("=" * 70)
    return True


if __name__ == "__main__":
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv("/opt/hx-lang-server/.env")

    # Run initialization test
    success = asyncio.run(initialize_checkpoint_tables())
    sys.exit(0 if success else 1)
EOF

# Make executable
chmod +x /opt/hx-lang-server/test_checkpoint_init.py
chown hx-lang-server:hx-lang-server /opt/hx-lang-server/test_checkpoint_init.py
```

### 4. Run Checkpoint Initialization Test

```bash
# Run as hx-lang-server user
su - hx-lang-server -c "source /opt/hx-lang-server/venv/bin/activate && python /opt/hx-lang-server/test_checkpoint_init.py"
```

Expected output:
```
======================================================================
langgraph-checkpoint-postgres Table Initialization Test
======================================================================

[1/5] Connecting to PostgreSQL...
  Connection string: postgresql://hx_lang_server@hx-postgres-server.hx.dev.local:5432/hx_lang_server
  ✓ Connection established

[2/5] Checking initial schema state...
  Tables in langgraph schema (before): 0

[3/5] Initializing AsyncPostgresSaver...
  ✓ AsyncPostgresSaver initialized
  ✓ setup() completed (tables auto-created)

[4/5] Verifying checkpoint tables exist...
  Tables found: checkpoint_blobs, checkpoint_migrations, checkpoint_writes, checkpoints
  ✓ checkpoints exists
  ✓ checkpoint_blobs exists
  ✓ checkpoint_writes exists
  ✓ checkpoint_migrations exists

[5/5] Verifying table structures...
  checkpoints table: 10 columns
    ✓ thread_id column exists
    ✓ checkpoint_ns column exists
    ✓ checkpoint_id column exists
    ✓ checkpoint column exists

======================================================================
✅ ALL TESTS PASSED - Checkpoint tables initialized correctly
======================================================================
```

### 5. Inspect Table Structures

```bash
# Connect and inspect created tables
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
-- Set schema
SET search_path TO langgraph, public;

-- List all tables with sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'langgraph'
ORDER BY tablename;

-- Describe checkpoints table
\d+ checkpoints

-- Describe checkpoint_blobs table
\d+ checkpoint_blobs

-- Describe checkpoint_writes table
\d+ checkpoint_writes

-- Describe checkpoint_migrations table
\d+ checkpoint_migrations

-- Check for indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'langgraph'
ORDER BY tablename, indexname;
EOF
```

### 6. Verify Checkpoint Migration Version

```bash
# Check migration version (should be current langgraph-checkpoint-postgres version)
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
SET search_path TO langgraph, public;

SELECT version FROM checkpoint_migrations ORDER BY version DESC LIMIT 1;
EOF
```

Expected output: Current version number (e.g., `1` or higher)

---

## Deliverables

- [ ] langgraph-checkpoint-postgres library installed (`>=2.0.0`)
- [ ] AsyncPostgresSaver initialized successfully
- [ ] All 4 checkpoint tables created in `langgraph` schema:
  - [ ] `checkpoints` - Checkpoint metadata and state
  - [ ] `checkpoint_blobs` - Large state objects (JSONB/BYTEA)
  - [ ] `checkpoint_writes` - Pending writes buffer
  - [ ] `checkpoint_migrations` - Schema version tracking
- [ ] Table structures validated with required columns
- [ ] Primary keys and indexes created automatically
- [ ] Migration version recorded in checkpoint_migrations table

---

## Verification

```bash
# Comprehensive verification checklist
ssh hx-lang-server@hx-lang-server.hx.dev.local

# 1. Verify all 4 tables exist
echo "=== Table Existence Check ==="
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "
SELECT
    CASE WHEN COUNT(*) = 4 THEN '✓ All 4 tables exist' ELSE '✗ Missing tables' END as status,
    COUNT(*) as table_count,
    STRING_AGG(tablename, ', ') as tables
FROM pg_tables
WHERE schemaname = 'langgraph';
"

# 2. Verify table ownership
echo -e "\n=== Table Ownership Check ==="
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "
SELECT
    tablename,
    tableowner,
    CASE WHEN tableowner = 'hx_lang_server' THEN '✓' ELSE '✗' END as owner_check
FROM pg_tables
WHERE schemaname = 'langgraph'
ORDER BY tablename;
"

# 3. Verify checkpoint_migrations has version
echo -e "\n=== Migration Version Check ==="
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "
SET search_path TO langgraph, public;
SELECT
    CASE WHEN COUNT(*) > 0 THEN '✓ Migration version recorded' ELSE '✗ No migration version' END as status,
    MAX(version) as current_version
FROM checkpoint_migrations;
"

# 4. Verify indexes exist
echo -e "\n=== Index Check ==="
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "
SELECT
    COUNT(*) as index_count,
    CASE WHEN COUNT(*) > 0 THEN '✓ Indexes created' ELSE '✗ No indexes' END as status
FROM pg_indexes
WHERE schemaname = 'langgraph';
"

# 5. Run checkpoint initialization test
echo -e "\n=== Full Initialization Test ==="
source /opt/hx-lang-server/venv/bin/activate
python /opt/hx-lang-server/test_checkpoint_init.py && echo "✓ Initialization test passed" || echo "✗ Initialization test failed"
```

**Pass Criteria**:
- [ ] All 4 tables exist in `langgraph` schema (checkpoints, checkpoint_blobs, checkpoint_writes, checkpoint_migrations)
- [ ] All tables owned by `hx_lang_server` user
- [ ] checkpoint_migrations table contains at least 1 version entry
- [ ] Primary keys and indexes created automatically
- [ ] Initialization test script passes all 5 checks
- [ ] No errors during AsyncPostgresSaver.setup()

---

## Rollback

```bash
# Connect as hx_lang_server user
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
-- Set schema
SET search_path TO langgraph, public;

-- Drop all checkpoint tables (CASCADE removes dependent objects)
DROP TABLE IF EXISTS checkpoint_writes CASCADE;
DROP TABLE IF EXISTS checkpoint_blobs CASCADE;
DROP TABLE IF EXISTS checkpoints CASCADE;
DROP TABLE IF EXISTS checkpoint_migrations CASCADE;

-- Verify removal
SELECT tablename FROM pg_tables WHERE schemaname = 'langgraph';
EOF
```

Expected output: `(0 rows)` - Schema should be empty again

```bash
# Optionally uninstall langgraph-checkpoint-postgres
source /opt/hx-lang-server/venv/bin/activate
pip uninstall -y langgraph-checkpoint-postgres
```

---

## Notes

- **Auto-Table Creation**: langgraph-checkpoint-postgres automatically creates tables on first `setup()` call. Manual table creation is NOT required and NOT recommended.

- **Table Purposes**:
  - `checkpoints`: Main checkpoint metadata and serialized state (JSONB)
  - `checkpoint_blobs`: Large state objects stored as binary blobs (BYTEA)
  - `checkpoint_writes`: Buffer for pending writes (supports async operations)
  - `checkpoint_migrations`: Schema version tracking for library upgrades

- **Schema Versioning**: Migration table tracks schema version. Future langgraph-checkpoint-postgres upgrades may add columns or tables; migration system handles this automatically.

- **No Manual DDL**: Do NOT manually create, alter, or drop these tables. Let langgraph-checkpoint-postgres manage the schema.

- **Idempotency**: Calling `setup()` multiple times is safe (idempotent). Existing tables are not recreated.

- **Primary Keys**: langgraph-checkpoint-postgres creates composite primary keys on (thread_id, checkpoint_ns, checkpoint_id) for optimal lookup performance.

- **Indexes**: Library creates indexes for common query patterns (thread lookups, checkpoint retrieval, parent-child relationships).

---

## Expected Table Structures

### checkpoints Table
```sql
CREATE TABLE checkpoints (
    thread_id text NOT NULL,
    checkpoint_ns text NOT NULL DEFAULT '',
    checkpoint_id text NOT NULL,
    parent_checkpoint_id text,
    type text,
    checkpoint jsonb NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id)
);
```

### checkpoint_blobs Table
```sql
CREATE TABLE checkpoint_blobs (
    thread_id text NOT NULL,
    checkpoint_ns text NOT NULL DEFAULT '',
    checkpoint_id text NOT NULL,
    channel text NOT NULL,
    type text,
    blob bytea,
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id, channel)
);
```

### checkpoint_writes Table
```sql
CREATE TABLE checkpoint_writes (
    thread_id text NOT NULL,
    checkpoint_ns text NOT NULL DEFAULT '',
    checkpoint_id text NOT NULL,
    task_id text NOT NULL,
    idx integer NOT NULL,
    channel text NOT NULL,
    type text,
    blob bytea,
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id, task_id, idx)
);
```

### checkpoint_migrations Table
```sql
CREATE TABLE checkpoint_migrations (
    version integer PRIMARY KEY
);
```

---

## Related Tasks

- **Depends On**: hx-lang-server-task-035 (connection configuration)
- **Prerequisite For**: Work Stream 6 (LangGraph Agent Implementation)
- **Related**: hx-lang-server-task-034 (schema creation)

---

**Created By**: Trinity (PostgreSQL DBA)
**Date**: 2025-12-04
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Database Schema" and "PostgreSQL Checkpoint Configuration"
