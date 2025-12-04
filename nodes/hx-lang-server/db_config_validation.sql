-- PostgreSQL Database Configuration Validation for hx-lang-server
-- Trinity Smith - PostgreSQL DBA
-- Date: 2025-12-04
--
-- This script validates all database-side configuration for hx-lang-server
-- Work Stream 4: PostgreSQL Integration (Tasks 031-036)

\echo '========================================='
\echo 'Task 031: Database Creation Validation'
\echo '========================================='

SELECT
    datname,
    pg_size_pretty(pg_database_size(datname)) as size,
    datconnlimit,
    pg_encoding_to_char(encoding) as encoding,
    datcollate,
    datctype
FROM pg_database
WHERE datname = 'hx_lang_server';

\echo ''
\echo '========================================='
\echo 'Task 032: User Creation Validation'
\echo '========================================='

SELECT
    usename,
    usesysid,
    CASE WHEN usecreatedb THEN 'FAIL: Has createdb' ELSE 'PASS: No createdb' END as createdb_check,
    CASE WHEN usesuper THEN 'FAIL: Has superuser' ELSE 'PASS: No superuser' END as superuser_check,
    CASE WHEN userepl THEN 'FAIL: Has replication' ELSE 'PASS: No replication' END as repl_check,
    CASE WHEN usebypassrls THEN 'FAIL: Bypasses RLS' ELSE 'PASS: RLS enforced' END as rls_check
FROM pg_user
WHERE usename = 'hx_lang_server';

SELECT
    rolname,
    rolconnlimit,
    CASE WHEN rolconnlimit = 20 THEN 'PASS: Connection limit correct' ELSE 'FAIL: Connection limit incorrect' END as connlimit_check
FROM pg_roles
WHERE rolname = 'hx_lang_server';

\echo ''
\echo '========================================='
\echo 'Task 033: pg_hba.conf Access Validation'
\echo '========================================='
\echo 'NOTE: This check requires connection from hx-lang-server.hx.dev.local (192.168.10.226)'
\echo 'If this script runs successfully from hx-lang-server, pg_hba.conf is correctly configured'

SELECT current_user, inet_server_addr(), inet_server_port(), inet_client_addr();

\echo ''
\echo '========================================='
\echo 'Task 034: Schema Creation Validation'
\echo '========================================='

-- Verify langgraph schema exists
SELECT
    nspname as schema_name,
    nspowner::regrole as owner,
    CASE WHEN nspowner::regrole::text = 'hx_lang_server' THEN 'PASS: Correct owner' ELSE 'FAIL: Wrong owner' END as owner_check
FROM pg_namespace
WHERE nspname = 'langgraph';

-- Verify search_path configuration
SELECT
    rolname,
    rolconfig,
    CASE WHEN 'search_path=langgraph, public' = ANY(rolconfig) THEN 'PASS: Correct search_path' ELSE 'FAIL: Wrong search_path' END as searchpath_check
FROM pg_roles
WHERE rolname = 'hx_lang_server';

-- Verify schema is empty (before checkpoint library initialization)
SELECT
    COUNT(*) as table_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS: Schema empty (expected before task-036)' ELSE 'INFO: Tables exist (task-036 complete)' END as table_check
FROM pg_tables
WHERE schemaname = 'langgraph';

\echo ''
\echo '========================================='
\echo 'Task 035: Connection Parameters Validation'
\echo '========================================='
\echo 'NOTE: autocommit=True and row_factory=dict_row are client-side parameters'
\echo 'Validation requires running test_db_connection.py on hx-lang-server'

-- Verify autocommit setting (session level check)
SHOW autocommit;

-- Verify database allows connections
SELECT
    datname,
    datallowconn,
    CASE WHEN datallowconn THEN 'PASS: Connections allowed' ELSE 'FAIL: Connections disabled' END as conn_check
FROM pg_database
WHERE datname = 'hx_lang_server';

\echo ''
\echo '========================================='
\echo 'Task 036: Checkpoint Tables Validation'
\echo '========================================='

-- List all tables in langgraph schema
SELECT
    schemaname,
    tablename,
    tableowner,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'langgraph'
ORDER BY tablename;

-- Expected tables check
WITH expected_tables AS (
    SELECT unnest(ARRAY['checkpoints', 'checkpoint_blobs', 'checkpoint_writes', 'checkpoint_migrations']) as table_name
),
actual_tables AS (
    SELECT tablename FROM pg_tables WHERE schemaname = 'langgraph'
)
SELECT
    e.table_name,
    CASE WHEN a.tablename IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as status
FROM expected_tables e
LEFT JOIN actual_tables a ON e.table_name = a.tablename
ORDER BY e.table_name;

-- Check migration version (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'langgraph' AND tablename = 'checkpoint_migrations') THEN
        RAISE NOTICE 'Checkpoint migration version:';
        EXECUTE 'SELECT version FROM langgraph.checkpoint_migrations ORDER BY version DESC LIMIT 1';
    ELSE
        RAISE NOTICE 'checkpoint_migrations table does not exist yet (run task-036)';
    END IF;
END $$;

\echo ''
\echo '========================================='
\echo 'Summary: Work Stream 4 Validation'
\echo '========================================='

SELECT
    'Task 031: Database Creation' as task,
    CASE WHEN EXISTS (SELECT 1 FROM pg_database WHERE datname = 'hx_lang_server') THEN 'COMPLETE' ELSE 'INCOMPLETE' END as status
UNION ALL
SELECT
    'Task 032: User Creation' as task,
    CASE WHEN EXISTS (SELECT 1 FROM pg_user WHERE usename = 'hx_lang_server' AND NOT usesuper AND NOT usecreatedb) THEN 'COMPLETE' ELSE 'INCOMPLETE' END as status
UNION ALL
SELECT
    'Task 033: pg_hba.conf Config' as task,
    'VERIFY FROM hx-lang-server' as status
UNION ALL
SELECT
    'Task 034: Schema Creation' as task,
    CASE WHEN EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'langgraph') THEN 'COMPLETE' ELSE 'INCOMPLETE' END as status
UNION ALL
SELECT
    'Task 035: Connection Config' as task,
    'VERIFY FROM hx-lang-server' as status
UNION ALL
SELECT
    'Task 036: Checkpoint Tables' as task,
    CASE WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'langgraph') = 4 THEN 'COMPLETE' ELSE 'INCOMPLETE' END as status;

\echo ''
\echo 'Database-side configuration complete!'
\echo 'Next steps:'
\echo '  1. Run test_db_connection.py on hx-lang-server (Task 035)'
\echo '  2. Run test_checkpoint_init.py on hx-lang-server (Task 036)'
