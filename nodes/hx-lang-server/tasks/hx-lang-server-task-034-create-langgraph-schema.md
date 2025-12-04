# Task: Create Dedicated langgraph Schema

**Task ID**: hx-lang-server-task-034-create-langgraph-schema
**Phase**: Installation (Work Stream 4: PostgreSQL Integration)
**Assigned To**: Trinity (PostgreSQL DBA)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-032 (user creation)
**Estimated Time**: 10 minutes

---

## Objective

Create a dedicated `langgraph` schema in the hx_lang_server database to isolate LangGraph checkpoint tables from the public schema. This provides namespace isolation, improves security, and simplifies permissions management for future application extensions.

---

## Prerequisites

- [ ] Database `hx_lang_server` exists (task-031 complete)
- [ ] User `hx_lang_server` exists (task-032 complete)
- [ ] PostgreSQL superuser (postgres) credentials available
- [ ] pg_hba.conf configured (task-033 recommended)

---

## Steps

### 1. Create langgraph Schema

```sql
-- Connect as postgres superuser
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server

-- Create schema owned by hx_lang_server user
CREATE SCHEMA IF NOT EXISTS langgraph AUTHORIZATION hx_lang_server;

-- Add comment documenting purpose
COMMENT ON SCHEMA langgraph IS 'LangGraph checkpoint persistence tables (checkpoints, checkpoint_blobs, checkpoint_writes, checkpoint_migrations)';
```

### 2. Grant Schema Privileges

```sql
-- Grant USAGE to allow hx_lang_server to access schema
GRANT USAGE ON SCHEMA langgraph TO hx_lang_server;

-- Grant CREATE to allow table creation (required for langgraph-checkpoint-postgres auto-table creation)
GRANT CREATE ON SCHEMA langgraph TO hx_lang_server;

-- Grant ALL for comprehensive access (user owns the schema)
GRANT ALL PRIVILEGES ON SCHEMA langgraph TO hx_lang_server;
```

### 3. Set Default Search Path for User

```sql
-- Configure hx_lang_server user to use langgraph schema by default
ALTER USER hx_lang_server SET search_path TO langgraph, public;

-- Verify search_path configuration
SELECT usename, useconfig
FROM pg_user
WHERE usename = 'hx_lang_server';
```

Expected output:
```
   usename       |           useconfig
-----------------+-------------------------------
 hx_lang_server  | {search_path=langgraph,public}
```

### 4. Grant Default Privileges for Future Tables

```sql
-- Configure default privileges for all future tables in langgraph schema
ALTER DEFAULT PRIVILEGES FOR ROLE hx_lang_server IN SCHEMA langgraph
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hx_lang_server;

-- Configure default privileges for sequences (auto-increment columns)
ALTER DEFAULT PRIVILEGES FOR ROLE hx_lang_server IN SCHEMA langgraph
    GRANT USAGE, SELECT ON SEQUENCES TO hx_lang_server;
```

### 5. Verify Schema Creation and Ownership

```sql
-- List all schemas and verify langgraph exists
\dn+

-- Verify schema privileges
SELECT
    schema_name,
    schema_owner,
    ARRAY_AGG(privilege_type) as privileges
FROM information_schema.schemata
JOIN information_schema.schema_privileges USING (schema_name)
WHERE schema_name = 'langgraph'
  AND grantee = 'hx_lang_server'
GROUP BY schema_name, schema_owner;
```

Expected output:
```
 schema_name | schema_owner |          privileges
-------------+--------------+------------------------------
 langgraph   | hx_lang_server | {USAGE,CREATE}
```

### 6. Test Schema Access from Application User

```bash
# SSH to hx-lang-server.hx.dev.local or connect from management host
export PGPASSWORD="${PASSWORD}"
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
-- Verify search_path includes langgraph
SHOW search_path;

-- Create test table in langgraph schema (implicit via search_path)
CREATE TABLE test_schema_access (
    id serial PRIMARY KEY,
    checkpoint_data jsonb NOT NULL,
    created_at timestamp DEFAULT now()
);

-- Verify table created in correct schema
SELECT schemaname, tablename, tableowner
FROM pg_tables
WHERE tablename = 'test_schema_access';

-- Test DML operations
INSERT INTO test_schema_access (checkpoint_data) VALUES ('{"test": "checkpoint"}');
SELECT * FROM test_schema_access;
UPDATE test_schema_access SET checkpoint_data = '{"test": "updated"}';
DELETE FROM test_schema_access;

-- Cleanup
DROP TABLE test_schema_access;

SELECT 'Schema access verification complete' as status;
EOF
unset PGPASSWORD
```

Expected output should show:
- search_path: `langgraph, public`
- Table created in schema: `langgraph`
- All DML operations succeed

---

## Deliverables

- [ ] Schema `langgraph` created and owned by `hx_lang_server` user
- [ ] Schema privileges (USAGE, CREATE, ALL) granted to `hx_lang_server`
- [ ] User search_path configured to prioritize `langgraph` schema
- [ ] Default privileges configured for future tables and sequences
- [ ] Schema access verified with test table operations

---

## Verification

```bash
# Comprehensive verification script
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server <<EOF
-- 1. Schema exists and has correct owner
SELECT
    schema_name,
    schema_owner,
    CASE WHEN schema_owner = 'hx_lang_server' THEN 'PASS' ELSE 'FAIL' END as owner_check
FROM information_schema.schemata
WHERE schema_name = 'langgraph';

-- 2. User has correct search_path
SELECT
    usename,
    useconfig,
    CASE WHEN 'search_path=langgraph,public' = ANY(useconfig) THEN 'PASS' ELSE 'FAIL' END as searchpath_check
FROM pg_user
WHERE usename = 'hx_lang_server';

-- 3. Schema privileges verification
SELECT
    grantee,
    privilege_type,
    CASE WHEN privilege_type IN ('USAGE', 'CREATE') THEN 'PASS' ELSE 'INFO' END as privilege_check
FROM information_schema.schema_privileges
WHERE schema_name = 'langgraph'
  AND grantee = 'hx_lang_server';

-- 4. Verify no tables exist yet (will be auto-created by langgraph-checkpoint-postgres)
SELECT
    COUNT(*) as table_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS: Schema empty (expected)' ELSE 'INFO: Tables exist' END as table_check
FROM pg_tables
WHERE schemaname = 'langgraph';

-- 5. Test hx_lang_server can create table in langgraph schema
SET ROLE hx_lang_server;
CREATE TABLE IF NOT EXISTS langgraph.test_privilege (id serial);
DROP TABLE IF EXISTS langgraph.test_privilege;
SELECT 'PASS: Can create/drop tables' as privilege_test;
RESET ROLE;
EOF
```

**Pass Criteria**:
- [ ] Schema `langgraph` exists with owner `hx_lang_server`
- [ ] User search_path is `langgraph, public`
- [ ] User has USAGE and CREATE privileges on schema
- [ ] Schema is empty (no tables yet, auto-created later by langgraph-checkpoint-postgres)
- [ ] Test table creation/drop succeeds as hx_lang_server user

---

## Rollback

```sql
-- Connect as postgres superuser
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server

-- Remove search_path configuration from user
ALTER USER hx_lang_server RESET search_path;

-- Drop schema (CASCADE removes all objects in schema)
DROP SCHEMA IF EXISTS langgraph CASCADE;

-- Verify removal
\dn langgraph
SELECT usename, useconfig FROM pg_user WHERE usename = 'hx_lang_server';
```

---

## Notes

- **Schema Purpose**: Isolates LangGraph checkpoint tables (checkpoints, checkpoint_blobs, checkpoint_writes, checkpoint_migrations) from application logic in public schema
- **Auto-Table Creation**: langgraph-checkpoint-postgres library will automatically create required tables on first use (task-036)
- **Search Path**: Configured to `langgraph, public` so unqualified table references (e.g., `SELECT * FROM checkpoints`) resolve to langgraph schema first
- **Ownership**: hx_lang_server owns the schema, giving full control over schema objects
- **Default Privileges**: Pre-configured for future tables; langgraph-checkpoint-postgres will inherit these privileges automatically
- **No Manual Table Creation**: Do NOT manually create checkpoint tables; let langgraph-checkpoint-postgres handle schema initialization

---

## Expected Tables (Auto-Created by langgraph-checkpoint-postgres)

After langgraph-checkpoint-postgres runs its setup:

| Table Name | Purpose | Key Columns |
|------------|---------|-------------|
| `checkpoints` | Checkpoint metadata | thread_id, checkpoint_ns, checkpoint_id, parent_checkpoint_id, type, checkpoint (jsonb) |
| `checkpoint_blobs` | Large state objects | thread_id, checkpoint_ns, checkpoint_id, channel, type, blob (bytea) |
| `checkpoint_writes` | Pending writes buffer | thread_id, checkpoint_ns, checkpoint_id, task_id, idx, channel, type, blob (bytea) |
| `checkpoint_migrations` | Schema version tracking | version (integer) |

---

## Related Tasks

- **Depends On**: hx-lang-server-task-032 (user creation)
- **Prerequisite For**: hx-lang-server-task-036 (checkpoint library verification)
- **Related**: hx-lang-server-task-035 (connection configuration)

---

**Created By**: Trinity (PostgreSQL DBA)
**Date**: 2025-12-04
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration" and "Database Schema"
