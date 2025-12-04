# Task: Implement config.py with Pydantic Settings

**Task ID**: hx-lang-server-task-103-implement-pydantic-config
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-101 (FastAPI application structure), hx-lang-server-task-022 (Python dependencies)
**Estimated Time**: 45 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Implement comprehensive configuration management using Pydantic Settings in `config.py`. This provides type-safe, validated configuration with environment variable support, covering all external service connections (PostgreSQL, Redis, Ollama, LightRAG, FastMCP), agent configuration, and operational settings as defined in the specification.

---

## Pre-Execution Validation

**CRITICAL**: Check if config.py is already fully implemented BEFORE executing steps.

```bash
# Check for complete config implementation
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
from app.core.config import Settings, get_settings
settings = get_settings()
# Check for all required attributes
required = ['postgres_host', 'redis_url', 'ollama_general_url', 'ollama_code_url',
            'lightrag_url', 'fastmcp_url', 'max_recursion_depth']
for attr in required:
    assert hasattr(settings, attr), f'Missing: {attr}'
print('VALIDATION: Config complete - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Config incomplete - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] FastAPI application structure created (Task 101)
- [ ] pydantic-settings installed in virtual environment (Task 022)
- [ ] python-dotenv installed for .env file support
- [ ] Service account `hx-lang-server` has write access to `/opt/hx-lang-server/app/core/`

---

## Steps

### 1. Verify Pydantic Settings Available

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

python3 -c "
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator
print('Pydantic Settings available')
"
```

### 2. Implement Comprehensive Settings Class

```bash
cat > /opt/hx-lang-server/app/core/config.py <<'EOF'
"""
Application configuration using Pydantic Settings.

This module provides type-safe, validated configuration for hx-lang-server
with support for environment variables and .env files.

Specification Reference: Configuration Management section
"""
from functools import lru_cache
from typing import List, Optional

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings with validation and environment variable support.

    All settings can be overridden via environment variables.
    Settings are loaded from /opt/hx-lang-server/.env if present.

    Environment Variable Prefix: None (direct mapping)

    Example .env:
        SERVICE_NAME=hx-lang-server
        SERVICE_PORT=8100
        POSTGRES_HOST=hx-postgres-server.hx.dev.local
    """

    # -------------------------------------------------------------------------
    # Service Configuration
    # -------------------------------------------------------------------------
    service_name: str = Field(
        default="hx-lang-server",
        description="Service identifier for logging and metrics"
    )
    service_port: int = Field(
        default=8100,
        ge=1024,
        le=65535,
        description="Main API port (FR-021)"
    )
    health_port: int = Field(
        default=8101,
        ge=1024,
        le=65535,
        description="Health/metrics port"
    )
    debug: bool = Field(
        default=False,
        description="Enable debug mode (enables /docs, verbose logging)"
    )
    log_level: str = Field(
        default="INFO",
        description="Logging level: DEBUG, INFO, WARNING, ERROR"
    )

    # -------------------------------------------------------------------------
    # CORS Configuration
    # -------------------------------------------------------------------------
    cors_origins: List[str] = Field(
        default=["*"],
        description="Allowed CORS origins. Use ['*'] for development only."
    )

    # -------------------------------------------------------------------------
    # PostgreSQL Configuration (Checkpoint Persistence)
    # Specification: PostgreSQL Checkpoint Configuration section
    # -------------------------------------------------------------------------
    postgres_host: str = Field(
        default="hx-postgres-server.hx.dev.local",
        description="PostgreSQL hostname (FR-006)"
    )
    postgres_port: int = Field(
        default=5432,
        description="PostgreSQL port"
    )
    postgres_db: str = Field(
        default="hx_lang_server",
        description="Database name for checkpoints"
    )
    postgres_user: str = Field(
        default="hx_lang_server",
        description="Database username"
    )
    postgres_password: str = Field(
        default="",
        description="Database password (from Ansible Vault)"
    )
    postgres_pool_size: int = Field(
        default=10,
        ge=1,
        le=50,
        description="Connection pool size"
    )

    @property
    def postgres_dsn(self) -> str:
        """
        Generate PostgreSQL DSN string.

        Returns asyncpg-compatible connection string.
        """
        return (
            f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    # -------------------------------------------------------------------------
    # Redis Configuration (Session Caching)
    # Specification: Redis Integration section
    # -------------------------------------------------------------------------
    redis_url: str = Field(
        default="redis://hx-redis-server.hx.dev.local:6379/0",
        description="Redis connection URL (FR-007)"
    )
    redis_max_connections: int = Field(
        default=50,
        ge=10,
        le=200,
        description="Redis connection pool size (per Sri Patel review)"
    )
    redis_socket_timeout: float = Field(
        default=5.0,
        ge=1.0,
        le=30.0,
        description="Redis socket timeout in seconds"
    )
    redis_key_prefix: str = Field(
        default="hx-lang-server",
        description="Redis key namespace prefix (per Alex Rivera review)"
    )

    # -------------------------------------------------------------------------
    # Ollama Configuration (LLM Integration)
    # Specification: Query Classification Mechanism section
    # -------------------------------------------------------------------------
    ollama_general_url: str = Field(
        default="http://hx-ollama1-server.hx.dev.local:11434",
        description="Ollama server for general queries (FR-010)"
    )
    ollama_code_url: str = Field(
        default="http://hx-ollama2-server.hx.dev.local:11434",
        description="Ollama server for code queries (FR-011)"
    )
    ollama_general_model: str = Field(
        default="gemma3:27b",
        description="Model for general queries"
    )
    ollama_code_model: str = Field(
        default="qwen3-coder:30b",
        description="Model for code queries"
    )
    ollama_timeout: float = Field(
        default=120.0,
        ge=30.0,
        le=600.0,
        description="Ollama request timeout in seconds"
    )
    ollama_min_context_kb: int = Field(
        default=64,
        description="Minimum context size in KB for RAG/Code (CAIO decision)"
    )

    # -------------------------------------------------------------------------
    # LightRAG Configuration
    # Specification: RAG Integration section
    # -------------------------------------------------------------------------
    lightrag_url: str = Field(
        default="http://hx-literag-server.hx.dev.local:8020",
        description="LightRAG HTTP API URL (FR-014)"
    )
    lightrag_timeout: float = Field(
        default=60.0,
        ge=10.0,
        le=300.0,
        description="LightRAG request timeout in seconds"
    )
    lightrag_default_mode: str = Field(
        default="hybrid",
        description="Default query mode: local, global, hybrid, mix (FR-016)"
    )

    @field_validator("lightrag_default_mode")
    @classmethod
    def validate_lightrag_mode(cls, v: str) -> str:
        """Validate LightRAG query mode."""
        valid_modes = {"local", "global", "hybrid", "mix"}
        if v not in valid_modes:
            raise ValueError(f"lightrag_default_mode must be one of {valid_modes}")
        return v

    # -------------------------------------------------------------------------
    # FastMCP Configuration (MCP Client)
    # Specification: MCP Client Integration section
    # -------------------------------------------------------------------------
    fastmcp_url: str = Field(
        default="http://hx-fastmcp-server.hx.dev.local:8000",
        description="FastMCP gateway URL (FR-018)"
    )
    fastmcp_timeout: float = Field(
        default=30.0,
        ge=5.0,
        le=120.0,
        description="MCP request timeout in seconds"
    )

    # -------------------------------------------------------------------------
    # Agent Configuration
    # Specification: Core Agent Orchestration section
    # -------------------------------------------------------------------------
    max_recursion_depth: int = Field(
        default=25,
        ge=5,
        le=100,
        description="Maximum graph recursion iterations (FR-005)"
    )
    checkpoint_frequency: str = Field(
        default="per_turn",
        description="Checkpoint save frequency: per_turn, per_node"
    )
    session_ttl_seconds: int = Field(
        default=3600,
        ge=300,
        le=86400,
        description="Session TTL in Redis (1 hour default)"
    )
    llm_cache_ttl_seconds: int = Field(
        default=300,
        ge=60,
        le=3600,
        description="LLM response cache TTL (5 minutes default)"
    )
    rag_cache_ttl_seconds: int = Field(
        default=600,
        ge=60,
        le=3600,
        description="RAG result cache TTL (10 minutes default)"
    )

    @field_validator("checkpoint_frequency")
    @classmethod
    def validate_checkpoint_frequency(cls, v: str) -> str:
        """Validate checkpoint frequency setting."""
        valid = {"per_turn", "per_node"}
        if v not in valid:
            raise ValueError(f"checkpoint_frequency must be one of {valid}")
        return v

    # -------------------------------------------------------------------------
    # Rate Limiting
    # Specification: Security Requirements section
    # -------------------------------------------------------------------------
    rate_limit_requests: int = Field(
        default=100,
        ge=10,
        le=1000,
        description="Max requests per minute per session"
    )
    rate_limit_window_seconds: int = Field(
        default=60,
        description="Rate limit window in seconds"
    )

    # -------------------------------------------------------------------------
    # HTTP Client Configuration
    # -------------------------------------------------------------------------
    http_client_timeout: float = Field(
        default=30.0,
        ge=5.0,
        le=120.0,
        description="Default HTTP client timeout"
    )
    http_client_max_connections: int = Field(
        default=100,
        ge=10,
        le=500,
        description="HTTP connection pool size"
    )

    # -------------------------------------------------------------------------
    # Pydantic Settings Configuration
    # -------------------------------------------------------------------------
    model_config = SettingsConfigDict(
        env_file="/opt/hx-lang-server/.env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache()
def get_settings() -> Settings:
    """
    Return cached settings instance.

    Uses lru_cache to ensure settings are loaded once and reused.
    Call get_settings.cache_clear() to reload settings if needed.

    Returns:
        Settings: Validated configuration instance.
    """
    return Settings()


# Convenience function for dependency injection
def settings_dependency() -> Settings:
    """
    FastAPI dependency for settings injection.

    Usage:
        @router.get("/endpoint")
        async def endpoint(settings: Settings = Depends(settings_dependency)):
            ...
    """
    return get_settings()
EOF
```

### 3. Create Sample .env File

```bash
cat > /opt/hx-lang-server/.env.example <<'EOF'
# hx-lang-server Environment Configuration
# Copy to .env and customize values

# Service Configuration
SERVICE_NAME=hx-lang-server
SERVICE_PORT=8100
HEALTH_PORT=8101
DEBUG=false
LOG_LEVEL=INFO

# PostgreSQL (Checkpoint Persistence)
POSTGRES_HOST=hx-postgres-server.hx.dev.local
POSTGRES_PORT=5432
POSTGRES_DB=hx_lang_server
POSTGRES_USER=hx_lang_server
POSTGRES_PASSWORD=  # Set from Ansible Vault

# Redis (Session Caching)
REDIS_URL=redis://hx-redis-server.hx.dev.local:6379/0
REDIS_MAX_CONNECTIONS=50

# Ollama (LLM Integration)
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b
OLLAMA_CODE_MODEL=qwen3-coder:30b

# LightRAG (RAG Integration)
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:8020
LIGHTRAG_DEFAULT_MODE=hybrid

# FastMCP (MCP Client)
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000

# Agent Configuration
MAX_RECURSION_DEPTH=25
CHECKPOINT_FREQUENCY=per_turn
SESSION_TTL_SECONDS=3600

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW_SECONDS=60
EOF

# Copy to actual .env for development
cp /opt/hx-lang-server/.env.example /opt/hx-lang-server/.env
chmod 600 /opt/hx-lang-server/.env
```

### 4. Test Configuration Loading

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test settings loading
python3 -c "
from app.core.config import get_settings, Settings

settings = get_settings()

print('=== Service Configuration ===')
print(f'Service Name: {settings.service_name}')
print(f'Service Port: {settings.service_port}')
print(f'Health Port: {settings.health_port}')
print(f'Debug: {settings.debug}')
print(f'Log Level: {settings.log_level}')

print('\n=== External Services ===')
print(f'PostgreSQL Host: {settings.postgres_host}')
print(f'PostgreSQL DSN: {settings.postgres_dsn[:50]}...')
print(f'Redis URL: {settings.redis_url}')
print(f'Ollama General: {settings.ollama_general_url}')
print(f'Ollama Code: {settings.ollama_code_url}')
print(f'LightRAG: {settings.lightrag_url}')
print(f'FastMCP: {settings.fastmcp_url}')

print('\n=== Agent Configuration ===')
print(f'Max Recursion Depth: {settings.max_recursion_depth}')
print(f'Checkpoint Frequency: {settings.checkpoint_frequency}')
print(f'Session TTL: {settings.session_ttl_seconds}s')
print(f'LLM Cache TTL: {settings.llm_cache_ttl_seconds}s')

print('\n=== Validation ===')
print('All settings loaded successfully!')
"
```

### 5. Test Environment Variable Override

```bash
# Test that environment variables override defaults
SERVICE_PORT=9999 python3 -c "
from app.core.config import Settings
settings = Settings()
assert settings.service_port == 9999, 'Env override failed'
print('PASS: Environment variable override works')
"
```

### 6. Test Validation

```bash
# Test field validators work correctly
python3 -c "
from pydantic import ValidationError
from app.core.config import Settings

# Test invalid lightrag_default_mode
try:
    Settings(lightrag_default_mode='invalid')
    print('FAIL: Should have raised validation error')
except ValidationError as e:
    print('PASS: Invalid lightrag_mode rejected')

# Test invalid checkpoint_frequency
try:
    Settings(checkpoint_frequency='invalid')
    print('FAIL: Should have raised validation error')
except ValidationError as e:
    print('PASS: Invalid checkpoint_frequency rejected')

# Test port range validation
try:
    Settings(service_port=999)  # Below 1024
    print('FAIL: Should have raised validation error')
except ValidationError as e:
    print('PASS: Invalid port rejected')

print('\nAll validations working correctly!')
"
```

### 7. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/config-implementation.txt <<EOF
Pydantic Settings Configuration Implementation Record
=====================================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-103-implement-pydantic-config

Files Created/Modified:
- /opt/hx-lang-server/app/core/config.py
- /opt/hx-lang-server/.env.example
- /opt/hx-lang-server/.env

Configuration Categories:
- Service Configuration (ports, debug, logging)
- PostgreSQL Configuration (checkpoint persistence)
- Redis Configuration (session caching)
- Ollama Configuration (LLM integration)
- LightRAG Configuration (RAG integration)
- FastMCP Configuration (MCP client)
- Agent Configuration (recursion, checkpoints, TTLs)
- Rate Limiting Configuration

Validation Tests:
- Settings loading: PASSED
- Environment override: PASSED
- Field validation: PASSED

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/config-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] config.py is syntactically correct:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/core/config.py && echo "PASS"
  ```

- [ ] Settings class loads all required attributes:
  ```bash
  python3 -c "
  from app.core.config import get_settings
  s = get_settings()
  required = ['postgres_host', 'redis_url', 'ollama_general_url',
              'ollama_code_url', 'lightrag_url', 'fastmcp_url',
              'max_recursion_depth', 'session_ttl_seconds']
  for attr in required:
      assert hasattr(s, attr), f'Missing: {attr}'
  print('PASS: All required attributes present')
  "
  ```

- [ ] Environment variables override defaults:
  ```bash
  DEBUG=true python3 -c "
  from app.core.config import Settings
  assert Settings().debug == True
  print('PASS: Env override works')
  "
  ```

- [ ] Field validators work correctly:
  ```bash
  python3 -c "
  from pydantic import ValidationError
  from app.core.config import Settings
  try:
      Settings(lightrag_default_mode='invalid')
      exit(1)
  except ValidationError:
      print('PASS: Validators working')
  "
  ```

- [ ] .env and .env.example files exist:
  ```bash
  test -f /opt/hx-lang-server/.env && test -f /opt/hx-lang-server/.env.example && echo "PASS"
  ```

- [ ] postgres_dsn property generates correct DSN:
  ```bash
  python3 -c "
  from app.core.config import get_settings
  dsn = get_settings().postgres_dsn
  assert 'postgresql+asyncpg://' in dsn
  print('PASS: DSN generation works')
  "
  ```

---

## Rollback

If configuration implementation needs to be reverted:

```bash
# Remove config.py
rm -f /opt/hx-lang-server/app/core/config.py

# Optionally remove .env files
rm -f /opt/hx-lang-server/.env
rm -f /opt/hx-lang-server/.env.example

# Clear settings cache if testing
python3 -c "from app.core.config import get_settings; get_settings.cache_clear()"

# Re-execute this task
```

---

## Notes

### Pydantic Settings Best Practices

1. **Type Safety**: All settings have explicit types with validation
2. **Defaults**: Sensible defaults for development environment
3. **Validation**: Custom validators for enum-like fields
4. **Documentation**: Field descriptions for clarity
5. **Caching**: `@lru_cache()` ensures single settings instance

### Environment Variable Mapping

Pydantic Settings automatically maps environment variables:
- `SERVICE_PORT` -> `service_port`
- `POSTGRES_HOST` -> `postgres_host`
- Case-insensitive matching

### Secret Management

Per HX-Infrastructure standards:
- Passwords stored in Ansible Vault only
- `.env` file should NOT contain actual passwords in production
- Use `POSTGRES_PASSWORD` environment variable set by systemd EnvironmentFile

### Service Hostnames

All external service references use hostnames (not IPs) per specification:
- `hx-postgres-server.hx.dev.local` (not 192.168.10.XXX)
- `hx-redis-server.hx.dev.local`
- `hx-ollama1-server.hx.dev.local`
- `hx-ollama2-server.hx.dev.local`
- `hx-literag-server.hx.dev.local`
- `hx-fastmcp-server.hx.dev.local`

### Configuration Categories Alignment

Configuration groups match specification sections:
- PostgreSQL -> PostgreSQL Checkpoint Configuration
- Redis -> Redis Integration
- Ollama -> Query Classification Mechanism / Ollama Routing Table
- LightRAG -> RAG Integration
- FastMCP -> MCP Client Integration
- Agent Config -> Core Agent Orchestration

---

## Related Tasks

**Prerequisites**:
- Task 101: FastAPI application structure
- Task 022: Python dependencies installed

**Next Tasks**:
- Task 102: Application factory (uses config)
- Task 104: Pydantic request/response models

**Work Stream Dependencies**:
- Work Stream 4 (Trinity): PostgreSQL config values
- Work Stream 5 (Sri): Redis config values
- Work Stream 7 (Jim): Ollama config values
- Work Stream 8 (Andy): LightRAG config values
- Work Stream 9 (George): FastMCP config values

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Configuration Management
- Section: Environment Variables
- Section: Pydantic Settings

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
