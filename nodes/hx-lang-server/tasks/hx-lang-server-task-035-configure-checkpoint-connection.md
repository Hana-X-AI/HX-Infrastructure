# Task: Configure langgraph-checkpoint-postgres Connection Parameters

**Task ID**: hx-lang-server-task-035-configure-checkpoint-connection
**Phase**: Installation (Work Stream 4: PostgreSQL Integration)
**Assigned To**: Trinity (PostgreSQL DBA)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-033 (pg_hba.conf), hx-lang-server-task-034 (schema creation)
**Estimated Time**: 20 minutes

---

## Objective

Configure and validate the PostgreSQL connection parameters required by langgraph-checkpoint-postgres. This includes creating the connection configuration module, setting environment variables, and validating the critical `autocommit=True` and `row_factory=dict_row` parameters.

---

## Prerequisites

- [ ] Database `hx_lang_server` exists with `langgraph` schema (task-031, task-034 complete)
- [ ] User `hx_lang_server` created with appropriate permissions (task-032 complete)
- [ ] pg_hba.conf configured for hx-lang-server access (task-033 complete)
- [ ] Password stored in Ansible Vault (`/opt/hx-infrastructure/ansible/vault/hx-lang-server-db-password.yml`)
- [ ] Python virtual environment created on hx-lang-server.hx.dev.local
- [ ] `psycopg[binary]>=3.2.0` installed in virtual environment

---

## Steps

### 1. Create Database Connection Configuration Module

```bash
# SSH to hx-lang-server.hx.dev.local
ssh hx-lang-server@hx-lang-server.hx.dev.local

# Create config directory structure
mkdir -p /opt/hx-lang-server/app/config
cd /opt/hx-lang-server/app/config

# Create database configuration module
cat > db_config.py <<'EOF'
"""
PostgreSQL connection configuration for langgraph-checkpoint-postgres.

CRITICAL: The connection parameters autocommit and row_factory are REQUIRED
for langgraph-checkpoint-postgres to function correctly.
"""

import os
from typing import Any, Dict
from psycopg.rows import dict_row


def get_postgres_connection_params() -> Dict[str, Any]:
    """
    Get PostgreSQL connection parameters for AsyncConnection.connect().

    Returns:
        Dictionary of connection parameters including:
        - host, port, dbname, user, password (connection details)
        - autocommit=True (REQUIRED for checkpoint commits)
        - row_factory=dict_row (REQUIRED for langgraph-checkpoint-postgres)

    Environment Variables:
        POSTGRES_HOST: PostgreSQL server hostname (default: hx-postgres-server.hx.dev.local)
        POSTGRES_PORT: PostgreSQL server port (default: 5432)
        POSTGRES_DB: Database name (default: hx_lang_server)
        POSTGRES_USER: Database user (default: hx_lang_server)
        POSTGRES_PASSWORD: Database password (required, from Ansible Vault)
    """
    return {
        "host": os.getenv("POSTGRES_HOST", "hx-postgres-server.hx.dev.local"),
        "port": int(os.getenv("POSTGRES_PORT", "5432")),
        "dbname": os.getenv("POSTGRES_DB", "hx_lang_server"),
        "user": os.getenv("POSTGRES_USER", "hx_lang_server"),
        "password": os.getenv("POSTGRES_PASSWORD"),  # Required, no default
        "autocommit": True,  # REQUIRED for checkpoint commits
        "row_factory": dict_row,  # REQUIRED for langgraph-checkpoint-postgres
    }


def get_connection_string() -> str:
    """
    Get PostgreSQL connection string (for debugging/logging only).

    Returns:
        Connection string WITHOUT password for safe logging.
    """
    params = get_postgres_connection_params()
    return f"postgresql://{params['user']}@{params['host']}:{params['port']}/{params['dbname']}"
EOF

# Set ownership
chown hx-lang-server:hx-lang-server db_config.py
chmod 644 db_config.py
```

### 2. Create Environment Configuration File

```bash
# Create .env file for environment variables
cat > /opt/hx-lang-server/.env <<EOF
# PostgreSQL Connection Configuration
POSTGRES_HOST=hx-postgres-server.hx.dev.local
POSTGRES_PORT=5432
POSTGRES_DB=hx_lang_server
POSTGRES_USER=hx_lang_server
POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}  # Loaded from Ansible Vault at runtime

# PostgreSQL Connection Pool Settings (for reference, not used with direct connection)
# Note: pgBouncer not in use per CAIO decision
POSTGRES_MAX_CONNECTIONS=20
POSTGRES_MIN_CONNECTIONS=5

# Schema Configuration
POSTGRES_SCHEMA=langgraph
EOF

# Set restrictive permissions (contains password reference)
chown hx-lang-server:hx-lang-server /opt/hx-lang-server/.env
chmod 600 /opt/hx-lang-server/.env
```

### 3. Load Password from Ansible Vault and Update .env

```bash
# Decrypt password from Ansible Vault
# NOTE: This requires the Ansible Vault password. In production, this would be automated
# via systemd EnvironmentFile= with secure password loading mechanism.

# Manual process for now (to be automated in systemd service configuration):
# 1. Decrypt Ansible Vault file
ansible-vault view /opt/hx-infrastructure/ansible/vault/hx-lang-server-db-password.yml > /tmp/db-password-decrypted.yml

# 2. Extract password value
DB_PASSWORD=$(grep "hx_lang_server_postgres_password:" /tmp/db-password-decrypted.yml | cut -d':' -f2 | tr -d ' "')

# 3. Update .env file with actual password
sed -i "s/\${POSTGRES_PASSWORD}/${DB_PASSWORD}/" /opt/hx-lang-server/.env

# 4. Securely remove temporary file
shred -vfz /tmp/db-password-decrypted.yml
unset DB_PASSWORD

# Verify .env permissions
ls -lh /opt/hx-lang-server/.env
```

### 4. Create Connection Test Script

```bash
# Create test script to validate connection parameters
cat > /opt/hx-lang-server/test_db_connection.py <<'EOF'
#!/usr/bin/env python3
"""
Test PostgreSQL connection with langgraph-checkpoint-postgres parameters.
"""

import asyncio
import sys
from pathlib import Path

# Add app directory to path
sys.path.insert(0, str(Path(__file__).parent / "app"))

from psycopg import AsyncConnection
from config.db_config import get_postgres_connection_params, get_connection_string


async def test_connection():
    """Test PostgreSQL connection with required parameters."""
    print("=" * 70)
    print("PostgreSQL Connection Test for langgraph-checkpoint-postgres")
    print("=" * 70)

    # Get connection parameters
    params = get_postgres_connection_params()

    # Validate critical parameters
    print("\n[1/6] Validating connection parameters...")
    assert params.get("autocommit") is True, "FAIL: autocommit must be True"
    print("  ✓ autocommit = True (REQUIRED)")

    from psycopg.rows import dict_row
    assert params.get("row_factory") is dict_row, "FAIL: row_factory must be dict_row"
    print("  ✓ row_factory = dict_row (REQUIRED)")

    assert params.get("password"), "FAIL: POSTGRES_PASSWORD not set"
    print("  ✓ POSTGRES_PASSWORD loaded")

    # Test connection
    print("\n[2/6] Connecting to PostgreSQL...")
    print(f"  Connection string: {get_connection_string()}")

    try:
        conn = await AsyncConnection.connect(
            host=params["host"],
            port=params["port"],
            dbname=params["dbname"],
            user=params["user"],
            password=params["password"],
            autocommit=params["autocommit"],
            row_factory=params["row_factory"],
        )
        print("  ✓ Connection established")
    except Exception as e:
        print(f"  ✗ Connection failed: {e}")
        return False

    # Test autocommit mode
    print("\n[3/6] Verifying autocommit mode...")
    try:
        result = await conn.execute("SHOW autocommit;")
        row = await result.fetchone()
        autocommit_value = row["autocommit"] if isinstance(row, dict) else row[0]
        assert autocommit_value == "on", f"Autocommit is {autocommit_value}, expected 'on'"
        print(f"  ✓ Autocommit enabled: {autocommit_value}")
    except Exception as e:
        print(f"  ✗ Autocommit check failed: {e}")
        await conn.close()
        return False

    # Test row_factory (dict rows)
    print("\n[4/6] Verifying dict row factory...")
    try:
        result = await conn.execute("SELECT 'test' as key, 123 as value;")
        row = await result.fetchone()
        assert isinstance(row, dict), f"Row type is {type(row)}, expected dict"
        assert row["key"] == "test" and row["value"] == 123
        print(f"  ✓ Rows returned as dicts: {row}")
    except Exception as e:
        print(f"  ✗ Dict row factory check failed: {e}")
        await conn.close()
        return False

    # Test schema access
    print("\n[5/6] Verifying langgraph schema access...")
    try:
        result = await conn.execute("SELECT current_schema();")
        row = await result.fetchone()
        current_schema = row["current_schema"] if isinstance(row, dict) else row[0]
        print(f"  ✓ Current schema: {current_schema}")

        # Verify search_path includes langgraph
        result = await conn.execute("SHOW search_path;")
        row = await result.fetchone()
        search_path = row["search_path"] if isinstance(row, dict) else row[0]
        assert "langgraph" in search_path, f"langgraph not in search_path: {search_path}"
        print(f"  ✓ Search path includes langgraph: {search_path}")
    except Exception as e:
        print(f"  ✗ Schema check failed: {e}")
        await conn.close()
        return False

    # Test write permissions
    print("\n[6/6] Verifying write permissions...")
    try:
        # Create test table in langgraph schema
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS test_checkpoint_connection (
                id serial PRIMARY KEY,
                test_data jsonb,
                created_at timestamp DEFAULT now()
            );
        """)
        print("  ✓ Table creation succeeded")

        # Insert test data
        await conn.execute("""
            INSERT INTO test_checkpoint_connection (test_data)
            VALUES ('{"test": "checkpoint_data"}');
        """)
        print("  ✓ Insert succeeded (autocommit verified)")

        # Query test data
        result = await conn.execute("SELECT * FROM test_checkpoint_connection;")
        rows = await result.fetchall()
        assert len(rows) > 0, "No rows returned"
        assert isinstance(rows[0], dict), "Row not returned as dict"
        print(f"  ✓ Query succeeded: {len(rows)} row(s) returned as dicts")

        # Cleanup
        await conn.execute("DROP TABLE test_checkpoint_connection;")
        print("  ✓ Cleanup complete")
    except Exception as e:
        print(f"  ✗ Write permission check failed: {e}")
        await conn.close()
        return False

    # Close connection
    await conn.close()
    print("\n" + "=" * 70)
    print("✅ ALL TESTS PASSED - Connection configured correctly")
    print("=" * 70)
    return True


if __name__ == "__main__":
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv("/opt/hx-lang-server/.env")

    # Run tests
    success = asyncio.run(test_connection())
    sys.exit(0 if success else 1)
EOF

# Make executable
chmod +x /opt/hx-lang-server/test_db_connection.py
chown hx-lang-server:hx-lang-server /opt/hx-lang-server/test_db_connection.py
```

### 5. Install Required Python Dependencies

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Install psycopg with binary support
pip install psycopg[binary]>=3.2.0

# Install python-dotenv for .env file loading
pip install python-dotenv>=1.0.0

# Verify installation
python -c "from psycopg import AsyncConnection; from psycopg.rows import dict_row; print('✓ psycopg imported successfully')"
```

### 6. Run Connection Test

```bash
# Run test script as hx-lang-server user
su - hx-lang-server -c "source /opt/hx-lang-server/venv/bin/activate && python /opt/hx-lang-server/test_db_connection.py"
```

Expected output:
```
======================================================================
PostgreSQL Connection Test for langgraph-checkpoint-postgres
======================================================================

[1/6] Validating connection parameters...
  ✓ autocommit = True (REQUIRED)
  ✓ row_factory = dict_row (REQUIRED)
  ✓ POSTGRES_PASSWORD loaded

[2/6] Connecting to PostgreSQL...
  Connection string: postgresql://hx_lang_server@hx-postgres-server.hx.dev.local:5432/hx_lang_server
  ✓ Connection established

[3/6] Verifying autocommit mode...
  ✓ Autocommit enabled: on

[4/6] Verifying dict row factory...
  ✓ Rows returned as dicts: {'key': 'test', 'value': 123}

[5/6] Verifying langgraph schema access...
  ✓ Current schema: langgraph
  ✓ Search path includes langgraph: langgraph, public

[6/6] Verifying write permissions...
  ✓ Table creation succeeded
  ✓ Insert succeeded (autocommit verified)
  ✓ Query succeeded: 1 row(s) returned as dicts
  ✓ Cleanup complete

======================================================================
✅ ALL TESTS PASSED - Connection configured correctly
======================================================================
```

---

## Deliverables

- [ ] Database connection configuration module created (`app/config/db_config.py`)
- [ ] Environment configuration file created (`.env`) with restricted permissions (600)
- [ ] Password loaded from Ansible Vault and stored securely in `.env`
- [ ] Connection test script created and executed successfully
- [ ] psycopg[binary] installed with AsyncConnection support
- [ ] `autocommit=True` parameter validated
- [ ] `row_factory=dict_row` parameter validated
- [ ] Connection test passes all 6 validation steps

---

## Verification

```bash
# Comprehensive verification checklist
ssh hx-lang-server@hx-lang-server.hx.dev.local

# 1. Verify db_config.py exists and is readable
echo "=== db_config.py Verification ==="
test -f /opt/hx-lang-server/app/config/db_config.py && echo "✓ File exists" || echo "✗ File missing"
grep -q "autocommit.*True" /opt/hx-lang-server/app/config/db_config.py && echo "✓ autocommit=True configured" || echo "✗ autocommit not configured"
grep -q "row_factory.*dict_row" /opt/hx-lang-server/app/config/db_config.py && echo "✓ row_factory=dict_row configured" || echo "✗ row_factory not configured"

# 2. Verify .env file exists with correct permissions
echo -e "\n=== .env File Verification ==="
test -f /opt/hx-lang-server/.env && echo "✓ .env exists" || echo "✗ .env missing"
PERMS=$(stat -c "%a" /opt/hx-lang-server/.env)
test "$PERMS" = "600" && echo "✓ Permissions correct (600)" || echo "✗ Permissions incorrect ($PERMS)"

# 3. Verify password is set in .env (without exposing it)
grep -q "^POSTGRES_PASSWORD=.\+$" /opt/hx-lang-server/.env && echo "✓ Password configured in .env" || echo "✗ Password not set"

# 4. Verify psycopg installation
echo -e "\n=== Python Dependencies Verification ==="
source /opt/hx-lang-server/venv/bin/activate
python -c "from psycopg import AsyncConnection; print('✓ psycopg AsyncConnection available')" 2>/dev/null || echo "✗ psycopg not installed"
python -c "from psycopg.rows import dict_row; print('✓ dict_row available')" 2>/dev/null || echo "✗ dict_row not available"

# 5. Run connection test
echo -e "\n=== Connection Test ==="
python /opt/hx-lang-server/test_db_connection.py && echo "✓ Connection test passed" || echo "✗ Connection test failed"
```

**Pass Criteria**:
- [ ] db_config.py exists with `autocommit=True` and `row_factory=dict_row`
- [ ] .env file exists with permissions 600
- [ ] POSTGRES_PASSWORD set in .env (not empty)
- [ ] psycopg[binary] installed with AsyncConnection and dict_row
- [ ] Connection test script passes all 6 validation steps
- [ ] No exceptions or errors during test execution

---

## Rollback

```bash
# SSH to hx-lang-server.hx.dev.local
ssh hx-lang-server@hx-lang-server.hx.dev.local

# Remove configuration files
rm -f /opt/hx-lang-server/app/config/db_config.py
rm -f /opt/hx-lang-server/.env
rm -f /opt/hx-lang-server/test_db_connection.py

# Optionally uninstall psycopg
source /opt/hx-lang-server/venv/bin/activate
pip uninstall -y psycopg psycopg-binary python-dotenv
```

---

## Notes

- **autocommit=True**: REQUIRED for langgraph-checkpoint-postgres. Without this, checkpoint writes will not persist (transactions not committed). The library expects autocommit mode for its internal checkpoint management.

- **row_factory=dict_row**: REQUIRED for langgraph-checkpoint-postgres. The library expects rows as dictionaries for JSON serialization and state reconstruction. Without this, the library will fail with KeyError exceptions.

- **No Connection Pooling**: pgBouncer not in use per CAIO decision. Direct AsyncConnection to PostgreSQL. Each LangGraph invocation creates its own connection.

- **Password Security**: Password stored in .env with 600 permissions (owner read/write only). In production systemd service, password loaded via EnvironmentFile= directive.

- **Schema Search Path**: User-level search_path configuration (task-034) ensures `langgraph` schema is checked first for unqualified table references.

- **Connection Limits**: User connection limit (20) and database connection limit (50) prevent connection exhaustion with multiple concurrent agent sessions.

---

## Configuration Reference

**Critical Connection Parameters** (from specification):
```python
connection_kwargs = {
    "autocommit": True,  # REQUIRED for checkpoint commits
    "row_factory": dict_row,  # REQUIRED for langgraph-checkpoint-postgres
}
```

**Usage in LangGraph Application**:
```python
from psycopg import AsyncConnection
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from config.db_config import get_postgres_connection_params

async def get_checkpointer():
    params = get_postgres_connection_params()
    conn = await AsyncConnection.connect(**params)
    return AsyncPostgresSaver(conn)
```

---

## Related Tasks

- **Depends On**: hx-lang-server-task-033 (pg_hba.conf), hx-lang-server-task-034 (schema creation)
- **Prerequisite For**: hx-lang-server-task-036 (checkpoint table verification)
- **Related**: hx-lang-server-task-032 (user creation)

---

**Created By**: Trinity (PostgreSQL DBA)
**Date**: 2025-12-04
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration"
