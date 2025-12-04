# Task: Create PostgreSQL Database for hx-lang-server

**Task ID**: hx-lang-server-task-031-create-database-hx-lang-server
**Phase**: Installation (Work Stream 4: PostgreSQL Integration)
**Assigned To**: Trinity (PostgreSQL DBA)
**Status**: Not Started
**Dependencies**: None (can run independently)
**Estimated Time**: 15 minutes

---

## Objective

Create the dedicated PostgreSQL database `hx_lang_server` on hx-postgres-server.hx.dev.local for LangGraph checkpoint persistence. This database will store conversation state, agent checkpoints, and thread branching information via the langgraph-checkpoint-postgres library.

---

## Prerequisites

- [ ] PostgreSQL server hx-postgres-server.hx.dev.local is operational and accessible
- [ ] PostgreSQL superuser (postgres) credentials available
- [ ] Network connectivity from hx-lang-server.hx.dev.local to hx-postgres-server.hx.dev.local:5432
- [ ] Verified via: `psql -h hx-postgres-server.hx.dev.local -U postgres -c "SELECT version();"` succeeds

---

## Steps

### 1. Connect to PostgreSQL Server

```bash
# Connect as postgres superuser from hx-postgres-server or management host
psql -h hx-postgres-server.hx.dev.local -U postgres
```

### 2. Create Database

```sql
-- Create database with UTF8 encoding and en_US.UTF-8 locale
CREATE DATABASE hx_lang_server
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0
    CONNECTION LIMIT = 50;

-- Add comment documenting purpose
COMMENT ON DATABASE hx_lang_server IS 'LangGraph checkpoint persistence for hx-lang-server orchestration hub';
```

### 3. Verify Database Creation

```sql
-- List databases and verify hx_lang_server exists
\l hx_lang_server

-- Connect to new database
\c hx_lang_server

-- Verify database settings
SELECT
    datname,
    pg_size_pretty(pg_database_size(datname)) as size,
    datconnlimit,
    encoding,
    datcollate,
    datctype
FROM pg_database
WHERE datname = 'hx_lang_server';
```

Expected output:
```
     datname     | size  | datconnlimit | encoding | datcollate   | datctype
-----------------+-------+--------------+----------+--------------+--------------
 hx_lang_server  | 8393 kB | 50         | 6        | en_US.UTF-8  | en_US.UTF-8
```

### 4. Verify Connectivity from hx-lang-server Node

```bash
# Test connection from hx-lang-server.hx.dev.local
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server -c "SELECT current_database(), version();"
```

Expected output should include:
```
 current_database |                          version
------------------+-----------------------------------------------------------
 hx_lang_server   | PostgreSQL 16.x on x86_64-pc-linux-gnu...
```

---

## Deliverables

- [ ] Database `hx_lang_server` created with UTF8 encoding
- [ ] Connection limit set to 50
- [ ] Database accessible from hx-lang-server.hx.dev.local
- [ ] Database size verified (initial size ~8MB)

---

## Verification

```bash
# Verification checklist
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server <<EOF
-- 1. Verify database exists
SELECT datname FROM pg_database WHERE datname = 'hx_lang_server';

-- 2. Verify encoding
SELECT pg_encoding_to_char(encoding) as encoding FROM pg_database WHERE datname = 'hx_lang_server';

-- 3. Verify connection limit
SELECT datconnlimit FROM pg_database WHERE datname = 'hx_lang_server';

-- 4. Verify can create table (permissions check)
CREATE TABLE test_connectivity (id serial PRIMARY KEY, test_value text);
DROP TABLE test_connectivity;
SELECT 'Database creation verified' as status;
EOF
```

**Pass Criteria**:
- [ ] All SELECT queries return expected values
- [ ] Test table creation/drop succeeds
- [ ] No errors in output

---

## Rollback

```sql
-- Connect as postgres superuser
psql -h hx-postgres-server.hx.dev.local -U postgres

-- Terminate all connections to database
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'hx_lang_server'
  AND pid <> pg_backend_pid();

-- Drop database
DROP DATABASE IF EXISTS hx_lang_server;

-- Verify removal
\l hx_lang_server
```

---

## Notes

- **Database Purpose**: Stores LangGraph checkpoint tables (checkpoints, checkpoint_blobs, checkpoint_writes, checkpoint_migrations)
- **Connection Limit**: Set to 50 to accommodate multiple concurrent agent sessions (up to 10 sessions with connection pooling)
- **No pgBouncer**: Direct PostgreSQL connection per CAIO decision (pgBouncer not in use)
- **Retention**: Checkpoint data retained for 30 days per operational requirements (RTO < 5 minutes, RPO < 1 minute)
- **Encoding**: UTF8 required for international character support in conversation data
- **Template0**: Used to ensure clean database with specified locale settings

---

## Related Tasks

- **Prerequisite For**: hx-lang-server-task-032 (create database user)
- **Related**: hx-lang-server-task-034 (create schema), hx-lang-server-task-035 (configure checkpoint library)

---

**Created By**: Trinity (PostgreSQL DBA)
**Date**: 2025-12-04
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration"
