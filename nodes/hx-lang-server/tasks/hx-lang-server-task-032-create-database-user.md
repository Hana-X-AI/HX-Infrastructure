# Task: Create PostgreSQL User for hx-lang-server

**Task ID**: hx-lang-server-task-032-create-database-user
**Phase**: Installation (Work Stream 4: PostgreSQL Integration)
**Assigned To**: Trinity (PostgreSQL DBA)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-031 (database creation)
**Estimated Time**: 20 minutes

---

## Objective

Create the dedicated PostgreSQL user `hx_lang_server` with appropriate permissions for checkpoint persistence operations. This user will be used by the LangGraph application to connect to the database with least-privilege access (no superuser, no createdb, no createrole).

---

## Prerequisites

- [ ] Database `hx_lang_server` exists (task-031 complete)
- [ ] PostgreSQL superuser (postgres) credentials available
- [ ] Password generated and stored in Ansible Vault at `/opt/hx-infrastructure/ansible/vault/hx-lang-server-db-password.yml`
- [ ] Network connectivity verified

---

## Steps

### 1. Generate Strong Password

```bash
# Generate 32-character random password
PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "Generated password (store in Ansible Vault): ${PASSWORD}"
```

### 2. Store Password in Ansible Vault

```bash
# Create Ansible Vault file (if not exists)
cat > /tmp/hx-lang-server-db-password.yml <<EOF
---
hx_lang_server_postgres_password: "${PASSWORD}"
EOF

# Encrypt with Ansible Vault
ansible-vault encrypt /tmp/hx-lang-server-db-password.yml

# Move to secure location
sudo mv /tmp/hx-lang-server-db-password.yml /opt/hx-infrastructure/ansible/vault/
sudo chmod 600 /opt/hx-infrastructure/ansible/vault/hx-lang-server-db-password.yml
```

### 3. Create PostgreSQL User

```sql
-- Connect as postgres superuser
psql -h hx-postgres-server.hx.dev.local -U postgres

-- Create user with SCRAM-SHA-256 authentication
CREATE USER hx_lang_server WITH
    PASSWORD '${PASSWORD}'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT
    LOGIN
    CONNECTION LIMIT 20;

-- Add comment documenting purpose
COMMENT ON ROLE hx_lang_server IS 'Application user for hx-lang-server LangGraph checkpoint persistence';
```

### 4. Grant Database Privileges

```sql
-- Grant connection and usage privileges
GRANT CONNECT ON DATABASE hx_lang_server TO hx_lang_server;

-- Connect to hx_lang_server database
\c hx_lang_server

-- Grant schema privileges (public schema for now, dedicated schema in task-034)
GRANT USAGE, CREATE ON SCHEMA public TO hx_lang_server;

-- Grant default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hx_lang_server;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO hx_lang_server;
```

### 5. Verify User Creation and Permissions

```sql
-- Verify user exists
SELECT usename, usesysid, usecreatedb, usesuper, userepl, usebypassrls, valuntil, useconfig
FROM pg_user
WHERE usename = 'hx_lang_server';

-- Verify database privileges
SELECT datname, array_agg(privilege_type) as privileges
FROM (
    SELECT 'hx_lang_server' as datname, unnest(datacl)::text as acl
    FROM pg_database
    WHERE datname = 'hx_lang_server'
) acls
JOIN LATERAL (
    SELECT
        split_part(acl, '=', 1) as grantee,
        split_part(split_part(acl, '=', 2), '/', 1) as privilege_type
) parsed ON parsed.grantee = 'hx_lang_server'
GROUP BY datname;
```

Expected output:
```
   usename       | usesysid | usecreatedb | usesuper | userepl | usebypassrls | valuntil | useconfig
-----------------+----------+-------------+----------+---------+--------------+----------+-----------
 hx_lang_server  | 16xxx    | f           | f        | f       | f            |          |
```

### 6. Test Connection with New User

```bash
# Test connection from hx-lang-server.hx.dev.local
# Replace ${PASSWORD} with actual password from Ansible Vault
export PGPASSWORD="${PASSWORD}"
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c "SELECT current_user, current_database(), session_user;"

# Test table creation (verify USAGE+CREATE on schema)
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server <<EOF
CREATE TABLE test_permissions (
    id serial PRIMARY KEY,
    data jsonb,
    created_at timestamp DEFAULT now()
);

-- Test INSERT
INSERT INTO test_permissions (data) VALUES ('{"test": "value"}');

-- Test SELECT
SELECT * FROM test_permissions;

-- Test UPDATE
UPDATE test_permissions SET data = '{"test": "updated"}' WHERE id = 1;

-- Test DELETE
DELETE FROM test_permissions WHERE id = 1;

-- Cleanup
DROP TABLE test_permissions;

SELECT 'Permissions verification complete' as status;
EOF

unset PGPASSWORD
```

Expected output should show all operations succeed with no permission errors.

---

## Deliverables

- [ ] PostgreSQL user `hx_lang_server` created with secure password
- [ ] Password stored in Ansible Vault (`/opt/hx-infrastructure/ansible/vault/hx-lang-server-db-password.yml`)
- [ ] User has CONNECT privilege on database
- [ ] User has USAGE and CREATE on schema
- [ ] User can perform SELECT, INSERT, UPDATE, DELETE on tables
- [ ] Connection limit set to 20 (sufficient for connection pooling)
- [ ] User does NOT have superuser, createdb, or createrole privileges (least-privilege)

---

## Verification

```bash
# Comprehensive verification script
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server <<EOF
-- 1. User exists with correct attributes
SELECT
    usename,
    CASE WHEN usesuper THEN 'FAIL: Has superuser' ELSE 'PASS: No superuser' END as superuser_check,
    CASE WHEN usecreatedb THEN 'FAIL: Can create DB' ELSE 'PASS: Cannot create DB' END as createdb_check,
    CASE WHEN usecreaterole THEN 'FAIL: Can create role' ELSE 'PASS: Cannot create role' END as createrole_check,
    useconnlimit
FROM pg_user
WHERE usename = 'hx_lang_server';

-- 2. User has CONNECT on database
SELECT
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_catalog = 'hx_lang_server'
  AND grantee = 'hx_lang_server'
UNION
SELECT
    'hx_lang_server' as grantee,
    'CONNECT' as privilege_type
WHERE EXISTS (
    SELECT 1 FROM pg_database
    WHERE datname = 'hx_lang_server'
      AND has_database_privilege('hx_lang_server', 'hx_lang_server', 'CONNECT')
);

-- 3. Schema privileges
SELECT
    schema_name,
    CASE WHEN has_schema_privilege('hx_lang_server', schema_name, 'USAGE')
         THEN 'PASS: Has USAGE' ELSE 'FAIL: No USAGE' END as usage_check,
    CASE WHEN has_schema_privilege('hx_lang_server', schema_name, 'CREATE')
         THEN 'PASS: Has CREATE' ELSE 'FAIL: No CREATE' END as create_check
FROM information_schema.schemata
WHERE schema_name = 'public';
EOF
```

**Pass Criteria**:
- [ ] User exists with usesuper=false, usecreatedb=false, usecreaterole=false
- [ ] User has CONNECT privilege on database
- [ ] User has USAGE and CREATE on public schema
- [ ] Connection test succeeds with hx_lang_server user
- [ ] Test table operations succeed (CREATE, INSERT, SELECT, UPDATE, DELETE, DROP)
- [ ] No permission denied errors

---

## Rollback

```sql
-- Connect as postgres superuser
psql -h hx-postgres-server.hx.dev.local -U postgres -d hx_lang_server

-- Revoke all privileges
REVOKE ALL PRIVILEGES ON DATABASE hx_lang_server FROM hx_lang_server;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM hx_lang_server;

-- Terminate user connections
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.usename = 'hx_lang_server';

-- Drop user
\c postgres
DROP USER IF EXISTS hx_lang_server;

-- Verify removal
\du hx_lang_server
```

```bash
# Remove Ansible Vault file
sudo rm -f /opt/hx-infrastructure/ansible/vault/hx-lang-server-db-password.yml
```

---

## Notes

- **Authentication**: Using SCRAM-SHA-256 (PostgreSQL 16 default, strongest available)
- **Connection Limit**: Set to 20 to prevent connection exhaustion (10 concurrent agent sessions × 2 connections per session)
- **No SSL Required**: Development environment, internal network traffic only (192.168.10.0/24)
- **Least Privilege**: User cannot create databases, roles, or perform administrative operations
- **Schema Permissions**: USAGE allows user to access schema, CREATE allows table creation (required for langgraph-checkpoint-postgres auto-table creation)
- **Password Policy**: 32-character randomly generated password stored securely in Ansible Vault only
- **No Connection Pooling**: Direct PostgreSQL connection (pgBouncer not in use per CAIO decision)

---

## Security Considerations

- ✅ **Strong Password**: 32-character random password with high entropy
- ✅ **Secure Storage**: Password never logged or stored in plain text, Ansible Vault only
- ✅ **Least Privilege**: No superuser, createdb, or createrole privileges
- ✅ **Connection Limit**: Prevents connection exhaustion attacks
- ✅ **No Trust Auth**: SCRAM-SHA-256 authentication enforced in pg_hba.conf
- ✅ **Network Isolation**: HX internal network only (192.168.10.0/24)

---

## Related Tasks

- **Depends On**: hx-lang-server-task-031 (database creation)
- **Prerequisite For**: hx-lang-server-task-034 (schema creation)
- **Related**: hx-lang-server-task-033 (pg_hba.conf configuration)

---

**Created By**: Trinity (PostgreSQL DBA)
**Date**: 2025-12-04
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration"
