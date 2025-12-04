# Task 016: Install Database Client Dependencies

**Task ID**: hx-lang-server-task-016
**Phase**: Pre-Deployment (System Dependencies)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 015 (Core Python Dependencies), Task 012 (System Packages - libpq-dev)
**Estimated Effort**: 30 minutes

---

## Objective

Install Python database client libraries for PostgreSQL (psycopg) and Redis (redis-py) required for checkpoint persistence and session caching in hx-lang-server.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 012 (System Packages) completed - libpq-dev installed
- [ ] Task 015 (Core Python Dependencies) completed
- [ ] Network connectivity to PyPI

---

## Pre-Execution Validation

**CRITICAL**: Check if database client packages are already installed BEFORE running pip install.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check installed packages
VENV_PATH="/opt/hx-lang-server/venv"

echo "Checking database client dependencies..."

PACKAGES_TO_CHECK=(
    "psycopg"
    "redis"
)

MISSING_PACKAGES=()

for pkg in "${PACKAGES_TO_CHECK[@]}"; do
    if "$VENV_PATH/bin/pip" show "$pkg" > /dev/null 2>&1; then
        VERSION=$("$VENV_PATH/bin/pip" show "$pkg" | grep "Version:" | awk '{print $2}')
        echo "INSTALLED: $pkg ($VERSION)"
    else
        echo "MISSING: $pkg"
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo ""
    echo "VALIDATION RESULT: All database client packages already installed"
    echo "ACTION: SKIP installation, proceed to validation section"
else
    echo ""
    echo "VALIDATION RESULT: ${#MISSING_PACKAGES[@]} packages missing"
    echo "ACTION: PROCEED with installation steps"
fi
```

**If Already Installed**: Skip to Validation section
**If Missing Packages**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Verify libpq-dev Prerequisite

```bash
# Verify PostgreSQL development libraries are installed
echo "Verifying libpq-dev prerequisite..."

if dpkg -l | grep -q "^ii  libpq-dev "; then
    VERSION=$(dpkg -l | grep libpq-dev | awk '{print $3}')
    echo "libpq-dev installed: $VERSION"
else
    echo "ERROR: libpq-dev not installed"
    echo "Run Task 012 (Install System Packages) first"
    exit 1
fi
```

### Step 2: Create Database Requirements File

```bash
# Create requirements file for database dependencies
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Creating database requirements file..."

sudo tee "$APP_DIR/requirements-database.txt" > /dev/null <<'EOF'
# Database Client Dependencies for hx-lang-server
# Task: hx-lang-server-task-016
# Date: 2025-12-04

# PostgreSQL Driver (async support)
# Note: [binary] extra provides pre-compiled binary wheels
psycopg[binary]>=3.2.0

# Redis Client (async support)
redis>=5.0.0
EOF

# Set ownership
sudo chown hx-lang-server "$APP_DIR/requirements-database.txt" 2>/dev/null || true

echo "Database requirements file created: $APP_DIR/requirements-database.txt"
cat "$APP_DIR/requirements-database.txt"
```

### Step 3: Install Database Client Packages

```bash
# Install database client packages
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Installing database client packages..."

# Determine service account
if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
else
    SERVICE_USER="root"
fi

# Install packages
sudo -u "$SERVICE_USER" "$VENV_PATH/bin/pip" install -r "$APP_DIR/requirements-database.txt" 2>/dev/null || \
    sudo "$VENV_PATH/bin/pip" install -r "$APP_DIR/requirements-database.txt"

if [ $? -eq 0 ]; then
    echo "Database client packages installed successfully"
else
    echo "ERROR: Database client package installation failed"
    exit 1
fi
```

### Step 4: Verify Package Installations

```bash
# Verify each package installed correctly
VENV_PATH="/opt/hx-lang-server/venv"

echo "Verifying package installations..."

PACKAGES=(
    "psycopg"
    "redis"
)

ALL_INSTALLED=true

for pkg in "${PACKAGES[@]}"; do
    if "$VENV_PATH/bin/pip" show "$pkg" > /dev/null 2>&1; then
        VERSION=$("$VENV_PATH/bin/pip" show "$pkg" | grep "Version:" | awk '{print $2}')
        echo "VERIFIED: $pkg ($VERSION)"
    else
        echo "MISSING: $pkg"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    echo "All database client packages verified"
else
    echo "ERROR: Some packages missing"
    exit 1
fi
```

### Step 5: Test Package Imports

```bash
# Test that packages can be imported
VENV_PATH="/opt/hx-lang-server/venv"

echo "Testing package imports..."

"$VENV_PATH/bin/python" <<'EOF'
import sys

# Test psycopg import
try:
    import psycopg
    print(f"PASS: psycopg {psycopg.__version__} imported")

    # Test async connection capability
    from psycopg import AsyncConnection
    print("PASS: psycopg AsyncConnection available")
except ImportError as e:
    print(f"FAIL: psycopg - {e}")
    sys.exit(1)

# Test redis import
try:
    import redis
    print(f"PASS: redis {redis.__version__} imported")

    # Test async client
    from redis.asyncio import Redis as AsyncRedis
    print("PASS: redis asyncio support available")
except ImportError as e:
    print(f"FAIL: redis - {e}")
    sys.exit(1)

print("\nAll database client imports successful")
EOF

if [ $? -eq 0 ]; then
    echo "Package import test passed"
else
    echo "ERROR: Package import test failed"
    exit 1
fi
```

### Step 6: Test PostgreSQL Connection Capability

```bash
# Test PostgreSQL connection capability (syntax only, no actual connection)
VENV_PATH="/opt/hx-lang-server/venv"

echo "Testing PostgreSQL connection capability..."

"$VENV_PATH/bin/python" <<'EOF'
import asyncio
from psycopg import AsyncConnection, OperationalError

async def test_connection_syntax():
    """Test that connection string parsing works (no actual connection)"""
    # This tests the connection string parser without actually connecting
    connection_string = "postgresql://user:password@localhost:5432/database"

    try:
        # Test connection string parsing (will fail to connect, but that's expected)
        conn = await AsyncConnection.connect(
            connection_string,
            autocommit=True,
        )
        await conn.close()
    except OperationalError as e:
        # Expected - we can't connect to localhost:5432
        # But the fact that we got here means the driver works
        print(f"Connection attempt (expected failure): {type(e).__name__}")
        print("PASS: psycopg connection capability verified")
        return True
    except Exception as e:
        print(f"Unexpected error: {type(e).__name__}: {e}")
        return False

    return True

result = asyncio.run(test_connection_syntax())
print(f"PostgreSQL connection capability: {'VERIFIED' if result else 'FAILED'}")
EOF

echo "PostgreSQL connection capability test completed"
```

### Step 7: Test Redis Connection Capability

```bash
# Test Redis connection capability (syntax only, no actual connection)
VENV_PATH="/opt/hx-lang-server/venv"

echo "Testing Redis connection capability..."

"$VENV_PATH/bin/python" <<'EOF'
import asyncio
import redis.asyncio as aioredis
from redis.exceptions import ConnectionError

async def test_redis_capability():
    """Test that Redis client creation works (no actual connection)"""
    try:
        # Create connection pool (doesn't connect yet)
        pool = aioredis.ConnectionPool.from_url(
            "redis://localhost:6379/0",
            max_connections=10,
            socket_timeout=5.0,
        )
        print("PASS: Redis connection pool created")

        # Create client
        client = aioredis.Redis(connection_pool=pool)
        print("PASS: Redis async client created")

        # Try to ping (will fail - no server)
        try:
            await client.ping()
        except ConnectionError:
            print("Connection attempt (expected failure): ConnectionError")

        await pool.disconnect()
        print("PASS: Redis connection capability verified")
        return True

    except Exception as e:
        print(f"Unexpected error: {type(e).__name__}: {e}")
        return False

result = asyncio.run(test_redis_capability())
print(f"Redis connection capability: {'VERIFIED' if result else 'FAILED'}")
EOF

echo "Redis connection capability test completed"
```

### Step 8: Document Installed Packages

```bash
# Document installed packages
DOC_DIR="/opt/hx-lang-server/deployment-docs"
VENV_PATH="/opt/hx-lang-server/venv"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/database-dependencies-inventory.txt" > /dev/null <<EOF
# Database Client Dependencies Inventory
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-016

## Package Summary

### PostgreSQL Driver
psycopg: $("$VENV_PATH/bin/pip" show psycopg | grep "Version:" | awk '{print $2}')
Features: Async support (AsyncConnection), binary protocol, connection pooling

### Redis Client
redis-py: $("$VENV_PATH/bin/pip" show redis | grep "Version:" | awk '{print $2}')
Features: Async support (redis.asyncio), connection pooling, retry on timeout

## Target Services
PostgreSQL: hx-postgres-server.hx.dev.local:5432
Redis: hx-redis-server.hx.dev.local:6379

## Connection Configuration
PostgreSQL connection parameters from spec:
- autocommit: True (required for langgraph-checkpoint-postgres)
- row_factory: dict_row (required for langgraph-checkpoint-postgres)

Redis connection parameters from spec:
- max_connections: 50
- socket_timeout: 5.0
- retry_on_timeout: True

## Specification Reference
- PostgreSQL: node-spec.md lines 329-379 (Checkpoint Configuration)
- Redis: node-spec.md lines 388-429 (Session Management)
EOF

echo "Database dependencies documented: $DOC_DIR/database-dependencies-inventory.txt"
cat "$DOC_DIR/database-dependencies-inventory.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Requirements File | /opt/hx-lang-server/requirements-database.txt | Database dependency specifications |
| psycopg Package | venv/lib/python3.x/site-packages/psycopg | PostgreSQL async driver |
| redis Package | venv/lib/python3.x/site-packages/redis | Redis async client |
| Documentation | /opt/hx-lang-server/deployment-docs/database-dependencies-inventory.txt | Package inventory |

---

## Verification

**Validation Commands:**

```bash
echo "=== Database Client Dependencies Validation ==="

VENV_PATH="/opt/hx-lang-server/venv"
VALIDATION_PASSED=true

# Check 1: psycopg installed with correct version
echo "1. psycopg Installation:"
if "$VENV_PATH/bin/pip" show psycopg | grep -q "Version: 3"; then
    VERSION=$("$VENV_PATH/bin/pip" show psycopg | grep "Version:" | awk '{print $2}')
    echo "PASSED: psycopg $VERSION installed"
else
    echo "FAILED: psycopg 3.x not installed"
    VALIDATION_PASSED=false
fi

# Check 2: redis installed with correct version
echo ""
echo "2. redis Installation:"
if "$VENV_PATH/bin/pip" show redis | grep -q "Version: 5"; then
    VERSION=$("$VENV_PATH/bin/pip" show redis | grep "Version:" | awk '{print $2}')
    echo "PASSED: redis $VERSION installed"
else
    echo "FAILED: redis 5.x not installed"
    VALIDATION_PASSED=false
fi

# Check 3: psycopg async import
echo ""
echo "3. psycopg Async Support:"
if "$VENV_PATH/bin/python" -c "from psycopg import AsyncConnection" 2>/dev/null; then
    echo "PASSED: psycopg AsyncConnection available"
else
    echo "FAILED: psycopg async support not available"
    VALIDATION_PASSED=false
fi

# Check 4: redis async import
echo ""
echo "4. redis Async Support:"
if "$VENV_PATH/bin/python" -c "from redis.asyncio import Redis" 2>/dev/null; then
    echo "PASSED: redis asyncio support available"
else
    echo "FAILED: redis async support not available"
    VALIDATION_PASSED=false
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Database clients ready for hx-lang-server"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- psycopg version 3.2.0 or higher installed
- redis version 5.0.0 or higher installed
- psycopg AsyncConnection can be imported
- redis.asyncio.Redis can be imported

---

## Rollback Procedure

Remove installed packages if needed:

```bash
# Uninstall database client packages
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Removing database client dependencies..."

# Uninstall packages
"$VENV_PATH/bin/pip" uninstall -y psycopg redis

# Remove requirements file
rm -f "$APP_DIR/requirements-database.txt"

echo "Database client dependencies removed"
```

---

## Notes

**psycopg vs psycopg2:**
- psycopg (version 3) is the modern async-first PostgreSQL driver
- psycopg2 is the legacy synchronous driver
- langgraph-checkpoint-postgres requires psycopg 3.x
- Using [binary] extra provides pre-compiled wheels (faster install)

**Redis Client:**
- redis-py version 5.x includes native asyncio support
- No need for separate aioredis package
- Connection pooling built-in
- Retry on timeout enabled for resilience

**Connection Parameters:**
- PostgreSQL: autocommit=True required for checkpoint writes
- PostgreSQL: row_factory=dict_row required by langgraph library
- Redis: 50 max connections (per Sri Patel's review)
- Redis: 5s socket timeout for connection health

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: PostgreSQL Checkpoint Configuration (lines 329-379)
- Section: Redis Integration (lines 388-429)
- Section: Dependencies - Python Dependencies (lines 607-611)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 2: System Dependencies (Task Range 011-020)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **libpq-dev missing**: psycopg compilation fails
   - Mitigation: Pre-check libpq-dev; use [binary] wheels
2. **Version incompatibility**: Package conflicts with LangGraph
   - Mitigation: Version pins match specification requirements
3. **Binary wheel unavailable**: Falls back to source compilation
   - Mitigation: libpq-dev and build-essential installed

**Dependencies Blocked:**
- Work Stream 4 (PostgreSQL Integration) requires psycopg
- Work Stream 5 (Redis Integration) requires redis
