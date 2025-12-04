# Task 131: Configure Redis Client Connection Module

**Assigned To**: sri-patel
**Estimated Effort**: 2 hours
**Dependencies**: Task 030 (Python virtual environment setup)
**Status**: Not Started

## Objective

Create Redis client module (`/opt/docling-mcp/src/integrations/redis_client.py`) with connection pooling, health checks, and error handling to enable session management and caching for hx-docling-mcp-server.

## Pre-Execution Validation

**CRITICAL**: Check if Redis client module already exists BEFORE creating it to prevent duplication.

```bash
# Check if Redis client module file exists
if [ -f "/opt/docling-mcp/src/integrations/redis_client.py" ]; then
    echo "✅ VALIDATION RESULT: Redis client module already exists"
    echo "ACTION: SKIP task execution - validate module functionality instead"
    echo "NEXT: Verify Redis connectivity with: python3 -c 'from src.integrations.redis_client import RedisClient; client = RedisClient(); client.ping()'"
    exit 0
else
    echo "❌ VALIDATION RESULT: Redis client module does NOT exist"
    echo "ACTION: PROCEED with module creation"
fi
```

**If Module Exists**: Skip to Validation section, verify Redis connectivity and module functionality

**If Module Does Not Exist**: Continue with Implementation Steps below

---

## Context

Redis integration provides critical infrastructure for hx-docling-mcp-server:
- **Session Management**: Multi-step document processing workflows with state persistence
- **Performance Optimization**: Caching for document metadata, LLM responses, and DoclingDocument objects
- **Graceful Degradation**: Service continues in stateless mode if Redis unavailable

**Redis Server**: hx-redis-server.hx.dev.local:6379 (hostname-based, NO IP addresses)

**Key Design Principles**:
- Connection pooling (max 10 connections) for efficiency
- Health checks (PING every 30 seconds) for resilience
- Retry logic with exponential backoff (3 attempts) for transient failures
- Graceful degradation (disable sessions) if Redis unavailable
- No authentication required (Phase 1 - internal network security)

## Acceptance Criteria

- [ ] Redis client module created at `/opt/docling-mcp/src/integrations/redis_client.py`
- [ ] Connection pooling configured with max 10 connections
- [ ] Health check method implemented (PING command)
- [ ] Retry logic with exponential backoff (3 attempts, 100ms/200ms/400ms delays)
- [ ] Error handling for connection failures and timeouts
- [ ] Connection timeout: 5 seconds
- [ ] Operation timeout: 10 seconds
- [ ] Module follows RedisSettings from Pydantic configuration
- [ ] Graceful error messages for Redis unavailability
- [ ] Module imported successfully in Python environment

## Implementation Steps

### Step 1: Create Integration Directory Structure

```bash
# SSH to hx-docling-mcp-server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create integrations directory if not exists
sudo mkdir -p /opt/docling-mcp/src/integrations

# Set ownership to docling-mcp service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/integrations

# Verify directory structure
ls -la /opt/docling-mcp/src/integrations/
```

### Step 2: Create Redis Client Module

```bash
# Create redis_client.py module
sudo -u docling-mcp@hx.dev.local bash -c 'cat > /opt/docling-mcp/src/integrations/redis_client.py << '\''EOF'\''
"""
Redis Client Module for Docling MCP Server

Provides Redis connection pooling, health checks, retry logic, and graceful
degradation for session management and caching functionality.

Integration: hx-redis-server.hx.dev.local:6379 (hostname-based)
"""

import redis
from redis.connection import ConnectionPool
import logging
import time
from typing import Optional, Any, Dict
from contextlib import contextmanager

logger = logging.getLogger(__name__)


class RedisClientError(Exception):
    """Base exception for Redis client errors."""
    pass


class RedisConnectionError(RedisClientError):
    """Exception raised when Redis connection fails."""
    pass


class RedisOperationError(RedisClientError):
    """Exception raised when Redis operation fails."""
    pass


class RedisClient:
    """
    Redis client with connection pooling, health checks, and retry logic.

    Features:
    - Connection pooling (max 10 connections by default)
    - Health checks (PING every 30 seconds)
    - Retry logic with exponential backoff (3 attempts)
    - Graceful error handling
    - Connection timeout: 5 seconds
    - Operation timeout: 10 seconds
    """

    def __init__(
        self,
        host: str = "hx-redis-server.hx.dev.local",
        port: int = 6379,
        password: Optional[str] = None,
        max_connections: int = 10,
        connection_timeout: int = 5,
        operation_timeout: int = 10,
        retry_attempts: int = 3,
        health_check_interval: int = 30
    ):
        """
        Initialize Redis client with connection pooling.

        Args:
            host: Redis server hostname (default: hx-redis-server.hx.dev.local)
            port: Redis server port (default: 6379)
            password: Redis password (optional, None for Phase 1)
            max_connections: Maximum connection pool size (default: 10)
            connection_timeout: Connection timeout in seconds (default: 5)
            operation_timeout: Operation timeout in seconds (default: 10)
            retry_attempts: Number of retry attempts for transient failures (default: 3)
            health_check_interval: Health check interval in seconds (default: 30)
        """
        self.host = host
        self.port = port
        self.password = password
        self.retry_attempts = retry_attempts
        self.health_check_interval = health_check_interval

        # Create connection pool
        self.pool = ConnectionPool(
            host=host,
            port=port,
            password=password,
            max_connections=max_connections,
            socket_connect_timeout=connection_timeout,
            socket_timeout=operation_timeout,
            decode_responses=True,  # Decode bytes to strings
            retry_on_timeout=True,
            health_check_interval=health_check_interval
        )

        # Create Redis client from pool
        self._client = redis.Redis(connection_pool=self.pool)

        # Track connection status
        self._is_available = True

        logger.info(
            f"Redis client initialized: {host}:{port}, "
            f"max_connections={max_connections}, "
            f"retry_attempts={retry_attempts}"
        )

    def _execute_with_retry(self, operation: callable, *args, **kwargs) -> Any:
        """
        Execute Redis operation with retry logic and exponential backoff.

        Args:
            operation: Redis operation to execute (callable)
            *args: Positional arguments for operation
            **kwargs: Keyword arguments for operation

        Returns:
            Result of Redis operation

        Raises:
            RedisOperationError: If all retry attempts fail
        """
        last_error = None

        for attempt in range(self.retry_attempts):
            try:
                result = operation(*args, **kwargs)

                # Mark as available on success
                if not self._is_available:
                    logger.info("Redis connection restored")
                    self._is_available = True

                return result

            except (redis.ConnectionError, redis.TimeoutError) as e:
                last_error = e

                # Calculate exponential backoff delay: 100ms, 200ms, 400ms
                delay = 0.1 * (2 ** attempt)

                logger.warning(
                    f"Redis operation failed (attempt {attempt + 1}/{self.retry_attempts}): {str(e)}. "
                    f"Retrying in {delay * 1000:.0f}ms..."
                )

                if attempt < self.retry_attempts - 1:
                    time.sleep(delay)

        # All retries failed
        self._is_available = False
        error_msg = f"Redis operation failed after {self.retry_attempts} attempts: {str(last_error)}"
        logger.error(error_msg)
        raise RedisOperationError(error_msg) from last_error

    def ping(self) -> bool:
        """
        Health check: Send PING command to Redis server.

        Returns:
            True if Redis responds to PING, False otherwise
        """
        try:
            response = self._execute_with_retry(self._client.ping)
            logger.debug("Redis health check: PING successful")
            return response is True
        except RedisOperationError:
            logger.warning("Redis health check: PING failed")
            return False

    def is_available(self) -> bool:
        """
        Check if Redis is currently available.

        Returns:
            True if Redis is available, False otherwise
        """
        return self._is_available

    def get(self, key: str) -> Optional[str]:
        """
        Get value for key from Redis.

        Args:
            key: Redis key

        Returns:
            Value as string, or None if key not found

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.get, key)
        except RedisOperationError as e:
            logger.error(f"Failed to GET key '{key}': {str(e)}")
            raise

    def set(
        self,
        key: str,
        value: str,
        ex: Optional[int] = None,
        px: Optional[int] = None,
        nx: bool = False,
        xx: bool = False
    ) -> bool:
        """
        Set key to value in Redis with optional TTL.

        Args:
            key: Redis key
            value: Value to set
            ex: Expiry time in seconds (TTL)
            px: Expiry time in milliseconds (TTL)
            nx: Only set if key does not exist (SET NX)
            xx: Only set if key exists (SET XX)

        Returns:
            True if set succeeded, False otherwise

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(
                self._client.set,
                key,
                value,
                ex=ex,
                px=px,
                nx=nx,
                xx=xx
            )
        except RedisOperationError as e:
            logger.error(f"Failed to SET key '{key}': {str(e)}")
            raise

    def delete(self, *keys: str) -> int:
        """
        Delete one or more keys from Redis.

        Args:
            *keys: One or more Redis keys to delete

        Returns:
            Number of keys deleted

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.delete, *keys)
        except RedisOperationError as e:
            logger.error(f"Failed to DELETE keys {keys}: {str(e)}")
            raise

    def exists(self, *keys: str) -> int:
        """
        Check if keys exist in Redis.

        Args:
            *keys: One or more Redis keys to check

        Returns:
            Number of keys that exist

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.exists, *keys)
        except RedisOperationError as e:
            logger.error(f"Failed to check EXISTS for keys {keys}: {str(e)}")
            raise

    def expire(self, key: str, seconds: int) -> bool:
        """
        Set TTL (time to live) for key in seconds.

        Args:
            key: Redis key
            seconds: TTL in seconds

        Returns:
            True if TTL set, False if key does not exist

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.expire, key, seconds)
        except RedisOperationError as e:
            logger.error(f"Failed to set EXPIRE for key '{key}': {str(e)}")
            raise

    def hset(self, name: str, key: str, value: str) -> int:
        """
        Set hash field to value in Redis.

        Args:
            name: Redis hash name
            key: Hash field name
            value: Field value

        Returns:
            1 if field is new, 0 if field was updated

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.hset, name, key, value)
        except RedisOperationError as e:
            logger.error(f"Failed to HSET hash '{name}' field '{key}': {str(e)}")
            raise

    def hget(self, name: str, key: str) -> Optional[str]:
        """
        Get hash field value from Redis.

        Args:
            name: Redis hash name
            key: Hash field name

        Returns:
            Field value as string, or None if field not found

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.hget, name, key)
        except RedisOperationError as e:
            logger.error(f"Failed to HGET hash '{name}' field '{key}': {str(e)}")
            raise

    def hgetall(self, name: str) -> Dict[str, str]:
        """
        Get all fields and values from Redis hash.

        Args:
            name: Redis hash name

        Returns:
            Dictionary of field-value pairs

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.hgetall, name)
        except RedisOperationError as e:
            logger.error(f"Failed to HGETALL hash '{name}': {str(e)}")
            raise

    def hdel(self, name: str, *keys: str) -> int:
        """
        Delete one or more hash fields from Redis.

        Args:
            name: Redis hash name
            *keys: One or more hash field names to delete

        Returns:
            Number of fields deleted

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.hdel, name, *keys)
        except RedisOperationError as e:
            logger.error(f"Failed to HDEL hash '{name}' fields {keys}: {str(e)}")
            raise

    def sadd(self, name: str, *values: str) -> int:
        """
        Add members to Redis set.

        Args:
            name: Redis set name
            *values: One or more values to add to set

        Returns:
            Number of members added (excludes already existing members)

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.sadd, name, *values)
        except RedisOperationError as e:
            logger.error(f"Failed to SADD to set '{name}': {str(e)}")
            raise

    def smembers(self, name: str) -> set:
        """
        Get all members from Redis set.

        Args:
            name: Redis set name

        Returns:
            Set of members

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.smembers, name)
        except RedisOperationError as e:
            logger.error(f"Failed to SMEMBERS from set '{name}': {str(e)}")
            raise

    def srem(self, name: str, *values: str) -> int:
        """
        Remove members from Redis set.

        Args:
            name: Redis set name
            *values: One or more values to remove from set

        Returns:
            Number of members removed

        Raises:
            RedisOperationError: If operation fails after retries
        """
        try:
            return self._execute_with_retry(self._client.srem, name, *values)
        except RedisOperationError as e:
            logger.error(f"Failed to SREM from set '{name}': {str(e)}")
            raise

    @contextmanager
    def pipeline(self, transaction: bool = True):
        """
        Context manager for Redis pipeline (atomic multi-command execution).

        Args:
            transaction: Use MULTI/EXEC for atomicity (default: True)

        Yields:
            Redis pipeline object

        Example:
            with redis_client.pipeline() as pipe:
                pipe.set("key1", "value1")
                pipe.set("key2", "value2")
                pipe.execute()
        """
        pipe = self._client.pipeline(transaction=transaction)
        try:
            yield pipe
        finally:
            pipe.reset()

    def close(self):
        """
        Close Redis connection pool.

        Should be called during service shutdown for graceful cleanup.
        """
        try:
            self.pool.disconnect()
            logger.info("Redis connection pool closed")
        except Exception as e:
            logger.warning(f"Error closing Redis connection pool: {str(e)}")


# Singleton instance (initialized by config.py)
_redis_client: Optional[RedisClient] = None


def get_redis_client() -> Optional[RedisClient]:
    """
    Get singleton Redis client instance.

    Returns:
        RedisClient instance, or None if not initialized
    """
    return _redis_client


def initialize_redis_client(
    host: str = "hx-redis-server.hx.dev.local",
    port: int = 6379,
    password: Optional[str] = None,
    max_connections: int = 10,
    connection_timeout: int = 5,
    operation_timeout: int = 10,
    retry_attempts: int = 3,
    health_check_interval: int = 30
) -> RedisClient:
    """
    Initialize singleton Redis client instance.

    Args:
        host: Redis server hostname
        port: Redis server port
        password: Redis password (optional)
        max_connections: Maximum connection pool size
        connection_timeout: Connection timeout in seconds
        operation_timeout: Operation timeout in seconds
        retry_attempts: Number of retry attempts
        health_check_interval: Health check interval in seconds

    Returns:
        Initialized RedisClient instance
    """
    global _redis_client

    _redis_client = RedisClient(
        host=host,
        port=port,
        password=password,
        max_connections=max_connections,
        connection_timeout=connection_timeout,
        operation_timeout=operation_timeout,
        retry_attempts=retry_attempts,
        health_check_interval=health_check_interval
    )

    logger.info(f"Redis client singleton initialized: {host}:{port}")
    return _redis_client
EOF'

# Verify file created
ls -la /opt/docling-mcp/src/integrations/redis_client.py
```

### Step 3: Create __init__.py for Integration Module

```bash
# Create __init__.py to make integrations a Python package
sudo -u docling-mcp@hx.dev.local bash -c 'cat > /opt/docling-mcp/src/integrations/__init__.py << '\''EOF'\''
"""
Integration modules for external services.

Modules:
- redis_client: Redis connection pooling and operations
"""

from .redis_client import (
    RedisClient,
    RedisClientError,
    RedisConnectionError,
    RedisOperationError,
    get_redis_client,
    initialize_redis_client
)

__all__ = [
    "RedisClient",
    "RedisClientError",
    "RedisConnectionError",
    "RedisOperationError",
    "get_redis_client",
    "initialize_redis_client"
]
EOF'

# Verify file created
ls -la /opt/docling-mcp/src/integrations/__init__.py
```

### Step 4: Install Redis Python Package

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Install redis package
pip install redis~=5.0

# Verify installation
pip show redis

# Expected output includes:
# Name: redis
# Version: 5.0.x
# Summary: Python client for Redis database and key-value store
```

### Step 5: Test Redis Module Import

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test module import
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import RedisClient, initialize_redis_client

print("✅ Redis client module imported successfully")

# Initialize client
client = initialize_redis_client(
    host="hx-redis-server.hx.dev.local",
    port=6379,
    max_connections=10
)

print(f"✅ Redis client initialized: {client.host}:{client.port}")
print(f"✅ Connection pool max connections: {client.pool.max_connections}")
EOF
```

## Validation

**Validation Commands (Run on hx-docling-mcp-server):**

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# 1. Verify Redis client module file exists
test -f /opt/docling-mcp/src/integrations/redis_client.py && echo "PASS: Redis client module exists" || echo "FAIL: Module not found"

# 2. Verify redis package installed
pip show redis | grep -q "Name: redis" && echo "PASS: Redis package installed" || echo "FAIL: Redis package not installed"

# 3. Verify module imports successfully
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.integrations.redis_client import RedisClient; print('PASS: Module imports successfully')" 2>&1 | grep -q "PASS" && echo "PASS: Import successful" || echo "FAIL: Import failed"

# 4. Verify Redis connectivity (health check)
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client

client = initialize_redis_client(
    host="hx-redis-server.hx.dev.local",
    port=6379,
    connection_timeout=5
)

if client.ping():
    print("PASS: Redis health check successful (PING returned True)")
else:
    print("FAIL: Redis health check failed (PING returned False)")
EOF

# 5. Verify basic Redis operations (set/get)
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client

client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)

# Test SET
client.set("test:task131", "validation_test", ex=60)
print("✓ SET operation successful")

# Test GET
value = client.get("test:task131")
if value == "validation_test":
    print("PASS: GET operation successful, value matches")
else:
    print(f"FAIL: GET returned unexpected value: {value}")

# Cleanup
client.delete("test:task131")
print("✓ Cleanup successful")
EOF
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Redis client module imports without errors
- PING health check returns True
- SET/GET operations work correctly
- Connection pool configured with 10 max connections
- Module ready for integration with session manager and cache modules

## Notes

### Redis Server Configuration

**hx-redis-server Details:**
- Hostname: hx-redis-server.hx.dev.local (NEVER use IP 192.168.10.210)
- Port: 6379 (default Redis port)
- Authentication: None (Phase 1 - internal network security)
- Persistence: RDB + AOF enabled (production configuration)
- Eviction Policy: volatile-lru (evict keys with TTL when memory full)
- Max Memory: Configured on server (not client concern)

### Connection Pooling Benefits

**Why Connection Pooling:**
- Reuse connections across multiple operations (reduce TCP handshake overhead)
- Limit concurrent connections to prevent Redis resource exhaustion
- Automatic connection recovery on transient failures
- Thread-safe connection management

**Pool Configuration:**
- Max connections: 10 (sufficient for FastMCP async operations)
- Health check interval: 30 seconds (automatic PING)
- Connection timeout: 5 seconds (fail fast on network issues)
- Operation timeout: 10 seconds (prevent hanging operations)

### Retry Logic Strategy

**Exponential Backoff:**
- Attempt 1: Immediate execution
- Attempt 2: Wait 100ms, retry
- Attempt 3: Wait 200ms, retry
- Attempt 4 (if configured): Wait 400ms, retry

**Why 3 Attempts:**
- Handle transient network glitches
- Avoid overwhelming Redis during recovery
- Fail fast after 3 attempts (700ms total delay)

### Graceful Degradation Pattern

**Redis Unavailable Behavior:**
1. Client detects connection failure via health check
2. Sets `_is_available = False`
3. Session manager checks `is_available()` before operations
4. If unavailable: Disable session features, log WARNING
5. Continue operating stateless MCP tools (document conversion)
6. Re-enable sessions when `ping()` succeeds

### Security Considerations

**Phase 1 (Current):**
- No authentication (internal network, trusted environment)
- No TLS encryption (plaintext Redis protocol)
- Network-level security (firewall disabled in HX-Infrastructure, but isolated network)

**Phase 2 (Future - Not Implemented Now):**
- Redis password authentication (requirepass)
- TLS encryption (Redis 6+ feature)
- ACL-based access control

### Module Design Patterns

**Singleton Pattern:**
- Single Redis client instance shared across application
- Initialized via `initialize_redis_client()` in config.py
- Accessed via `get_redis_client()` from other modules
- Prevents multiple connection pools (resource waste)

**Context Manager for Pipelines:**
- `with redis_client.pipeline() as pipe:` ensures proper cleanup
- Atomic multi-command execution (MULTI/EXEC)
- Automatic pipeline reset on exception

### Troubleshooting

**If Redis connection fails:**
```bash
# Test Redis connectivity from server
redis-cli -h hx-redis-server.hx.dev.local PING
# Expected: PONG

# Check Redis server status
ssh agent0@hx-redis-server.hx.dev.local "systemctl status redis"

# Check network connectivity
ping -c 3 hx-redis-server.hx.dev.local

# Verify DNS resolution
nslookup hx-redis-server.hx.dev.local
# Should resolve to 192.168.10.210
```

**If module import fails:**
```bash
# Check Python path
python3 -c "import sys; print('\n'.join(sys.path))"

# Verify file permissions
ls -la /opt/docling-mcp/src/integrations/redis_client.py
# Should be owned by docling-mcp@hx.dev.local

# Check for syntax errors
python3 -m py_compile /opt/docling-mcp/src/integrations/redis_client.py
```

**If connection pool errors:**
```bash
# Check redis package version
pip show redis | grep Version
# Should be 5.0.x or higher

# Reinstall redis package
pip uninstall redis -y
pip install redis~=5.0
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
  - Section 2.4.4: Integration Requirements (FR-023)
  - Section 2.4.6: Session Management (FR-018, FR-020)
  - Section 2.4.7: Caching Strategy (FR-021A)
  - Section 3.5: Configuration Management (RedisSettings)
- **Redis Documentation**: https://redis.io/docs/
- **redis-py Documentation**: https://redis-py.readthedocs.io/
- **HX-Infrastructure Standards**: `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`

## Risk Assessment

**Risk**: Medium
- Redis connectivity required for session management (but graceful degradation available)
- Connection pooling misconfiguration could cause resource exhaustion
- Retry logic timing critical for performance

**Mitigation**:
- Health checks detect Redis unavailability early
- Graceful degradation allows stateless operation
- Conservative connection pool size (10 connections)
- Exponential backoff prevents retry storms
- Comprehensive error logging for troubleshooting
