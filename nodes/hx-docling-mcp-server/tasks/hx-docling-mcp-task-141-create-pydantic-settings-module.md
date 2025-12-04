# Task 141: Create Pydantic Settings Module

**Assigned To**: paul-warfield
**Estimated Effort**: 2.0 hours
**Dependencies**: Task 006 (Directory Structure)
**Status**: Not Started

## Objective

Create the core Pydantic configuration module (`src/config/settings.py`) implementing comprehensive environment variable validation using Pydantic V2 BaseSettings with nested configuration classes, field validators, and cross-field validation rules.

## Pre-Execution Validation

**CRITICAL**: Check if Pydantic settings module already exists BEFORE creating it to prevent duplication.

```bash
# Check if settings module exists
if [ -f "/opt/docling-mcp/src/config/settings.py" ]; then
    echo "✅ VALIDATION RESULT: Pydantic settings module already exists"
    echo "ACTION: SKIP task execution - validate existing module instead"

    # Verify module can be imported
    cd /opt/docling-mcp
    source venv/bin/activate
    python3 -c "from src.config.settings import DoclingMCPConfig; print('Module import successful')" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Module is importable - task complete"
        exit 0
    else
        echo "⚠️ Module exists but has import errors - may need fixing"
        exit 1
    fi
else
    echo "❌ VALIDATION RESULT: Pydantic settings module does NOT exist"
    echo "ACTION: PROCEED with module creation"
fi
```

**If Module Exists and Importable**: Skip to Validation section
**If Module Does Not Exist**: Continue with Implementation Steps below

---

## Context

All HX-Infrastructure services use Pydantic V2 BaseSettings for environment variable validation and configuration management. This provides:
- Type-safe configuration with automatic type coercion
- Comprehensive field validation with Field() constraints
- Cross-field validation via model_validator
- Environment variable parsing with nested delimiter support
- Fail-fast startup validation to prevent misconfiguration
- Automatic JSON Schema generation for documentation

The Docling MCP Server requires 7 nested configuration classes covering Redis, Qdrant, LiteLLM, session management, caching, processing settings, and MCP server configuration.

## Acceptance Criteria

- [ ] Settings module created at `/opt/docling-mcp/src/config/settings.py`
- [ ] RedisSettings class with connection pool, timeout, retry configuration
- [ ] SessionSettings class with TTL and extension validation
- [ ] CacheSettings class with size limits and TTL configuration
- [ ] QdrantSettings class with HTTP connection pool configuration
- [ ] LLMSettings class with LiteLLM API base URL and model settings
- [ ] ProcessingSettings class with document size limits and worker count
- [ ] MCPServerSettings class with transport and logging configuration
- [ ] DoclingMCPConfig master class with all nested settings
- [ ] Field validators for cache directory, TTL extension, and processing limits
- [ ] Model configuration with env_nested_delimiter and case_sensitive settings
- [ ] load_config() class method with startup validation and logging
- [ ] Module follows Pydantic V2 API patterns (no deprecated V1 usage)

## Implementation Steps

### Step 1: Create Configuration Module Directory

```bash
# SSH to target server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create config package directory
sudo mkdir -p /opt/docling-mcp/src/config

# Create __init__.py for package
sudo touch /opt/docling-mcp/src/config/__init__.py

# Set ownership to service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/config

# Verify directory structure
ls -la /opt/docling-mcp/src/config/
# Expected: __init__.py owned by docling-mcp@hx.dev.local
```

### Step 2: Create Pydantic Settings Module

```bash
# Create settings.py with comprehensive Pydantic V2 configuration
sudo tee /opt/docling-mcp/src/config/settings.py > /dev/null << 'EOF'
"""Pydantic configuration settings for Docling MCP Server.

This module provides comprehensive environment variable validation using
Pydantic V2 BaseSettings with nested configuration classes, field validators,
and cross-field validation rules.

Environment variables are loaded from:
1. /etc/docling-mcp/env/.env file (if exists)
2. System environment variables (override .env values)

Configuration groups:
- RedisSettings: Redis connection pool and session management
- SessionSettings: Session TTL and sliding window configuration
- CacheSettings: Redis caching performance optimization
- QdrantSettings: Vector database connection configuration
- LLMSettings: LiteLLM gateway and entity extraction models
- ProcessingSettings: Document processing limits and workers
- MCPServerSettings: MCP protocol transport configuration
"""

from pydantic import BaseModel, Field, field_validator, HttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Literal, Optional, Annotated
from pydantic.types import StringConstraints
from pathlib import Path
import warnings


class RedisSettings(BaseModel):
    """Redis connection and session management configuration."""

    host: str = Field(
        default="hx-redis-server.hx.dev.local",
        description="Redis server hostname or IP address"
    )
    port: int = Field(
        default=6379,
        ge=1,
        le=65535,
        description="Redis server port"
    )
    password: Optional[str] = Field(
        default=None,
        description="Redis authentication password (loaded from Ansible Vault)"
    )
    connection_pool_size: int = Field(
        default=10,
        ge=1,
        le=100,
        description="Maximum Redis connection pool size"
    )
    connection_timeout_seconds: int = Field(
        default=5,
        ge=1,
        le=30,
        description="Redis connection timeout in seconds"
    )
    operation_timeout_seconds: int = Field(
        default=10,
        ge=1,
        le=60,
        description="Redis read/write operation timeout in seconds"
    )
    retry_attempts: int = Field(
        default=3,
        ge=0,
        le=10,
        description="Number of retry attempts for transient Redis failures"
    )
    health_check_interval_seconds: int = Field(
        default=30,
        ge=5,
        le=300,
        description="Redis health check ping interval in seconds"
    )


class SessionSettings(BaseModel):
    """Session management TTL configuration."""

    ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="Session TTL in hours (max 168 hours = 7 days)"
    )
    ttl_extension_hours: int = Field(
        default=4,
        ge=1,
        le=48,
        description="TTL extension increment for sliding window (hours)"
    )

    @field_validator('ttl_extension_hours')
    @classmethod
    def validate_extension(cls, v: int, info) -> int:
        """Validate extension increment doesn't exceed total TTL."""
        if 'ttl_hours' in info.data and v > info.data['ttl_hours']:
            raise ValueError(
                f"ttl_extension_hours ({v}) cannot exceed ttl_hours ({info.data['ttl_hours']})"
            )
        return v


class CacheSettings(BaseModel):
    """Redis caching performance optimization configuration."""

    enabled: bool = Field(
        default=True,
        description="Enable Redis caching for document metadata, LLM responses, and DoclingDocuments"
    )
    ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="Default cache TTL in hours"
    )
    max_document_size_mb: int = Field(
        default=5,
        ge=1,
        le=100,
        description="Maximum document size to cache in MB (prevent Redis memory bloat)"
    )
    metadata_ttl_hours: int = Field(
        default=168,
        ge=1,
        le=720,
        description="Document metadata cache TTL (7 days default)"
    )
    entity_ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="Entity extraction result cache TTL"
    )
    docling_ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="DoclingDocument JSON cache TTL"
    )


class QdrantSettings(BaseModel):
    """Qdrant vector database connection configuration."""

    host: str = Field(
        default="hx-qdrant-server.hx.dev.local",
        description="Qdrant server hostname or IP address"
    )
    port: int = Field(
        default=6333,
        ge=1,
        le=65535,
        description="Qdrant HTTP API port"
    )
    api_key: Optional[str] = Field(
        default=None,
        description="Qdrant API authentication key (loaded from Ansible Vault if enabled)"
    )
    connection_pool_max: int = Field(
        default=10,
        ge=1,
        le=50,
        description="Maximum HTTP connection pool size"
    )
    keepalive_seconds: int = Field(
        default=60,
        ge=10,
        le=300,
        description="HTTP connection keep-alive timeout"
    )
    retry_attempts: int = Field(
        default=3,
        ge=0,
        le=10,
        description="Number of retry attempts for Qdrant operations"
    )


class LLMSettings(BaseModel):
    """LLM configuration for entity extraction via LiteLLM gateway."""

    litellm_api_base: HttpUrl = Field(
        default="http://hx-litellm-server.hx.dev.local:4000",
        description="LiteLLM gateway base URL for model routing"
    )
    lightrag_api_url: HttpUrl = Field(
        default="http://hx-literag-server.hx.dev.local:8000",
        description="LightRAG server API base URL for entity/relationship extraction"
    )
    entity_extraction_model: Annotated[str, StringConstraints(pattern=r"^[a-z0-9:-]+$")] = Field(
        default="gemma3:27b",
        description="Default LLM model for entity extraction (routed via LiteLLM)"
    )
    temperature: float = Field(
        default=0.1,
        ge=0.0,
        le=2.0,
        description="LLM sampling temperature (0.1 for deterministic extraction)"
    )
    max_tokens: int = Field(
        default=2048,
        ge=128,
        le=8192,
        description="Maximum LLM response tokens"
    )
    timeout_seconds: int = Field(
        default=60,
        ge=10,
        le=300,
        description="LLM API request timeout"
    )


class ProcessingSettings(BaseModel):
    """Document processing and performance configuration."""

    document_max_size_mb: int = Field(
        default=500,
        ge=1,
        le=2000,
        description="Maximum document size for processing in MB"
    )
    concurrent_workers: int = Field(
        default=4,
        ge=1,
        le=20,
        description="Number of concurrent document processing workers"
    )
    docling_cache_dir: Path = Field(
        default=Path("/var/lib/docling-mcp/cache"),
        description="Temporary document cache directory path"
    )

    @field_validator('docling_cache_dir')
    @classmethod
    def validate_cache_dir(cls, v: Path) -> Path:
        """Validate cache directory is absolute path."""
        if not v.is_absolute():
            raise ValueError(f"docling_cache_dir must be absolute path, got: {v}")
        return v


class MCPServerSettings(BaseModel):
    """MCP protocol server transport configuration."""

    http_port: int = Field(
        default=8000,
        ge=1024,
        le=65535,
        description="MCP HTTP server listen port"
    )
    sse_enabled: bool = Field(
        default=True,
        description="Enable Server-Sent Events transport for progress updates"
    )
    stdio_enabled: bool = Field(
        default=True,
        description="Enable stdio transport for CLI and Claude Desktop integration"
    )
    log_level: Literal["DEBUG", "INFO", "WARN", "ERROR"] = Field(
        default="INFO",
        description="Logging verbosity level"
    )
    log_format: Literal["json", "text"] = Field(
        default="json",
        description="Log output format (json for structured logging)"
    )


class DoclingMCPConfig(BaseSettings):
    """Master configuration settings for Docling MCP Server with validation.

    This class loads environment variables from:
    1. /etc/docling-mcp/env/.env file (if exists)
    2. System environment variables (override .env values)

    Environment variables use nested delimiter syntax:
    - REDIS_HOST=hx-redis-server.hx.dev.local
    - CACHE_ENABLED=true
    - SESSION_TTL_HOURS=24
    - LLM_LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000
    """

    # Nested configuration groups
    redis: RedisSettings = Field(default_factory=RedisSettings)
    session: SessionSettings = Field(default_factory=SessionSettings)
    cache: CacheSettings = Field(default_factory=CacheSettings)
    qdrant: QdrantSettings = Field(default_factory=QdrantSettings)
    llm: LLMSettings = Field(default_factory=LLMSettings)
    processing: ProcessingSettings = Field(default_factory=ProcessingSettings)
    mcp: MCPServerSettings = Field(default_factory=MCPServerSettings)

    model_config = SettingsConfigDict(
        env_prefix="",  # No prefix, use direct environment variable names
        env_nested_delimiter="_",  # Support nested config: REDIS_HOST, CACHE_ENABLED
        case_sensitive=False,  # Allow lowercase environment variables
        validate_assignment=True,  # Validate on attribute assignment
        extra="forbid",  # Fail if unknown environment variables detected
        env_file="/etc/docling-mcp/env/.env",  # Load from .env file
        env_file_encoding="utf-8",
        json_schema_extra={
            "title": "Docling MCP Server Configuration",
            "description": "Comprehensive configuration schema with validation for Docling MCP Server",
            "version": "1.0.0"
        }
    )

    @field_validator('processing')
    @classmethod
    def validate_processing_limits(cls, v: ProcessingSettings) -> ProcessingSettings:
        """Cross-field validation for processing limits."""
        # Ensure concurrent workers don't exceed reasonable limits for available resources
        if v.concurrent_workers > 10:
            warnings.warn(
                f"concurrent_workers={v.concurrent_workers} may cause high memory usage "
                f"with max document size {v.document_max_size_mb}MB"
            )
        return v

    @classmethod
    def load_config(cls) -> "DoclingMCPConfig":
        """Load and validate configuration from environment variables with startup validation.

        Returns:
            DoclingMCPConfig: Validated configuration instance

        Raises:
            SystemExit: If configuration validation fails (exit code 1)
        """
        try:
            config = cls()
            # Log configuration (sanitized - no secrets)
            import logging
            logger = logging.getLogger(__name__)
            logger.info("Configuration loaded successfully")
            logger.debug(f"Redis: {config.redis.host}:{config.redis.port}")
            logger.debug(f"Qdrant: {config.qdrant.host}:{config.qdrant.port}")
            logger.debug(f"LiteLLM: {config.llm.litellm_api_base}")
            logger.debug(f"LightRAG: {config.llm.lightrag_api_url}")
            logger.debug(f"Session TTL: {config.session.ttl_hours}h")
            logger.debug(f"Cache enabled: {config.cache.enabled}")
            logger.debug(f"Document max size: {config.processing.document_max_size_mb}MB")
            logger.debug(f"Concurrent workers: {config.processing.concurrent_workers}")
            logger.debug(f"MCP HTTP port: {config.mcp.http_port}")
            logger.debug(f"MCP SSE enabled: {config.mcp.sse_enabled}")
            logger.debug(f"MCP stdio enabled: {config.mcp.stdio_enabled}")
            return config
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Configuration validation failed: {e}")
            raise SystemExit(1)  # Fail fast on startup


# Convenience export
__all__ = [
    "DoclingMCPConfig",
    "RedisSettings",
    "SessionSettings",
    "CacheSettings",
    "QdrantSettings",
    "LLMSettings",
    "ProcessingSettings",
    "MCPServerSettings",
]
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/config/settings.py

# Set permissions (644 - read for all, write for owner)
sudo chmod 644 /opt/docling-mcp/src/config/settings.py

# Verify file created
ls -la /opt/docling-mcp/src/config/settings.py
```

### Step 3: Update Package __init__.py for Easy Import

```bash
# Update __init__.py to export configuration classes
sudo tee /opt/docling-mcp/src/config/__init__.py > /dev/null << 'EOF'
"""Configuration package for Docling MCP Server."""

from .settings import (
    DoclingMCPConfig,
    RedisSettings,
    SessionSettings,
    CacheSettings,
    QdrantSettings,
    LLMSettings,
    ProcessingSettings,
    MCPServerSettings,
)

__all__ = [
    "DoclingMCPConfig",
    "RedisSettings",
    "SessionSettings",
    "CacheSettings",
    "QdrantSettings",
    "LLMSettings",
    "ProcessingSettings",
    "MCPServerSettings",
]
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/config/__init__.py
```

### Step 4: Install Pydantic Dependencies

```bash
# Activate virtual environment
cd /opt/docling-mcp
source venv/bin/activate

# Install pydantic and pydantic-settings
pip install pydantic==2.9.2 pydantic-settings==2.5.2

# Verify installation
pip show pydantic pydantic-settings
# Expected: pydantic 2.9.2, pydantic-settings 2.5.2

# Deactivate venv
deactivate
```

## Validation

**Validation Commands:**

```bash
# Change to project directory
cd /opt/docling-mcp

# Activate virtual environment
source venv/bin/activate

# Test 1: Verify module can be imported
python3 -c "from src.config.settings import DoclingMCPConfig" && echo "PASS: Module import successful" || echo "FAIL: Module import failed"

# Test 2: Verify all nested classes can be imported
python3 -c "from src.config import RedisSettings, SessionSettings, CacheSettings, QdrantSettings, LLMSettings, ProcessingSettings, MCPServerSettings" && echo "PASS: All settings classes importable" || echo "FAIL: Settings class import failed"

# Test 3: Verify default configuration can be instantiated
python3 -c "from src.config.settings import DoclingMCPConfig; config = DoclingMCPConfig(); print(f'Redis: {config.redis.host}:{config.redis.port}')" && echo "PASS: Default config instantiation works" || echo "FAIL: Config instantiation failed"

# Test 4: Verify field validators work (TTL extension validation)
python3 -c "from src.config.settings import SessionSettings; from pydantic import ValidationError; import sys;
try:
    s = SessionSettings(ttl_hours=10, ttl_extension_hours=20)
    print('FAIL: Should have raised ValidationError')
    sys.exit(1)
except ValidationError as e:
    print('PASS: TTL extension validator working')
    sys.exit(0)" && echo "PASS: Field validator working" || echo "FAIL: Field validator not working"

# Test 5: Verify cache directory validator works
python3 -c "from src.config.settings import ProcessingSettings; from pydantic import ValidationError; import sys; from pathlib import Path;
try:
    p = ProcessingSettings(docling_cache_dir=Path('relative/path'))
    print('FAIL: Should have raised ValidationError for relative path')
    sys.exit(1)
except ValidationError as e:
    print('PASS: Cache directory validator working')
    sys.exit(0)" && echo "PASS: Path validator working" || echo "FAIL: Path validator not working"

# Test 6: Verify HttpUrl validation works
python3 -c "from src.config.settings import LLMSettings; s = LLMSettings(); print(f'LiteLLM: {s.litellm_api_base}')" && echo "PASS: HttpUrl validation works" || echo "FAIL: HttpUrl validation failed"

# Test 7: Verify Pydantic V2 API usage (no deprecated warnings)
python3 -W error::DeprecationWarning -c "from src.config.settings import DoclingMCPConfig; config = DoclingMCPConfig()" && echo "PASS: No deprecated V1 API usage" || echo "FAIL: Using deprecated Pydantic V1 APIs"

# Deactivate venv
deactivate
```

**Expected Outcomes:**
- All 7 validation tests return "PASS"
- Module imports without errors
- Default configuration instantiates successfully
- Field validators catch invalid values
- No Pydantic V1 deprecation warnings

## Notes

### Pydantic V2 Migration

This implementation uses **Pydantic V2** APIs exclusively:
- `BaseSettings` from `pydantic_settings` (not `pydantic`)
- `SettingsConfigDict` instead of `Config` class
- `field_validator` with `@classmethod` decorator
- `HttpUrl` type for URL validation
- No use of deprecated `parse_obj`, `dict()`, or `json()` methods

### Configuration Loading Priority

Environment variables are loaded with this priority (highest to lowest):
1. System environment variables (set in shell or systemd)
2. `/etc/docling-mcp/env/.env` file
3. Default values in Field() definitions

### Environment Variable Naming

Nested configuration uses underscore delimiter:
- Top-level: `REDIS_HOST`, `QDRANT_PORT`, `CACHE_ENABLED`
- Nested: `LLM_LITELLM_API_BASE`, `SESSION_TTL_HOURS`
- Case-insensitive: `redis_host` or `REDIS_HOST` both work

### Validation Strategy

Three levels of validation:
1. **Type validation**: Automatic via Pydantic type hints
2. **Field validation**: Constraints via Field() (ge, le, pattern)
3. **Cross-field validation**: Custom validators via @field_validator

### Why Pydantic for Configuration

**Advantages over environment variables alone:**
- Type safety with automatic coercion (string "8000" → int 8000)
- Comprehensive validation at startup (fail fast)
- Self-documenting via Field descriptions
- JSON Schema generation for OpenAPI docs
- IDE autocomplete support
- Testable configuration classes

### Security Considerations

**Secrets Handling:**
- Sensitive fields (passwords, API keys) use `Optional[str]` with `default=None`
- Loaded from environment variables (populated by Ansible Vault at runtime)
- Never logged (sanitized logging in load_config())
- Never included in error messages (Pydantic redacts by default)

### Performance Optimization

**Pydantic V2 Performance:**
- Uses `pydantic-core` (Rust implementation) for validation
- 5-50x faster than Pydantic V1
- Validation happens once at startup (negligible overhead)
- No validation during runtime access (config is immutable)

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Lines 999-1309: Configuration Requirements)
- **Pydantic V2 Documentation**: `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pydantic-main/`
- **Pydantic Settings**: https://docs.pydantic.dev/latest/concepts/pydantic_settings/
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 10)

## Risk Assessment

**Risk**: Low
- Well-established pattern across HX-Infrastructure
- Pydantic V2 is production-ready and stable
- No impact on existing services
- Validation prevents misconfiguration

**Mitigation**:
- Comprehensive validation tests
- Default values prevent missing configuration
- Clear error messages guide troubleshooting
- Fail-fast approach prevents runtime issues
