# Task 144: Integrate Configuration with MCP Server

**Assigned To**: paul-warfield
**Estimated Effort**: 1.0 hours
**Dependencies**: Task 141 (Pydantic Settings Module), Task 142 (Environment File), Task 031 (MCP Server Initialization)
**Status**: Not Started

## Objective

Integrate the Pydantic configuration module with the MCP server entry point (`mcp_server.py`) to load and validate configuration at startup, configure logging based on settings, and make configuration available to all MCP tools and service integrations.

## Pre-Execution Validation

**CRITICAL**: Check if configuration is already integrated into MCP server BEFORE modifying code.

```bash
# Check if mcp_server.py imports configuration
if grep -q "from src.config.settings import DoclingMCPConfig" /opt/docling-mcp/mcp_server.py 2>/dev/null; then
    echo "✅ VALIDATION RESULT: Configuration already integrated into MCP server"
    echo "ACTION: SKIP task execution - validate existing integration instead"

    # Verify configuration loading works at server startup
    cd /opt/docling-mcp
    source venv/bin/activate
    python3 -c "import mcp_server; print('✅ MCP server imports configuration successfully')" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Configuration integration working - task complete"
        exit 0
    else
        echo "⚠️ Configuration imported but has errors - may need fixing"
        exit 1
    fi
else
    echo "❌ VALIDATION RESULT: Configuration NOT integrated into MCP server"
    echo "ACTION: PROCEED with integration"
fi
```

**If Already Integrated and Working**: Skip to Validation section
**If Not Integrated**: Continue with Implementation Steps below

---

## Context

The MCP server entry point must load and validate configuration at startup to:
- Ensure all required environment variables are present
- Validate configuration constraints before service starts
- Configure logging based on MCP_LOG_LEVEL and MCP_LOG_FORMAT settings
- Make configuration available to all downstream modules (Redis, Qdrant, LiteLLM clients)
- Fail fast if configuration is invalid (prevent runtime errors)

This integration follows the "fail fast" principle: if configuration validation fails, the service exits immediately with status code 1 and logs detailed error information.

## Acceptance Criteria

- [ ] MCP server imports DoclingMCPConfig at module level
- [ ] Configuration loaded via DoclingMCPConfig.load_config() at startup
- [ ] Logging configured based on config.mcp.log_level and config.mcp.log_format
- [ ] Configuration validation failure causes service exit with status 1
- [ ] Configuration sanitized in logs (no passwords, API keys)
- [ ] Global config instance accessible to all modules
- [ ] Startup log messages include configuration summary
- [ ] Configuration loading happens BEFORE server initialization
- [ ] Integration tested with valid and invalid configurations

## Implementation Steps

### Step 1: Update MCP Server Entry Point

```bash
# SSH to target server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Backup existing mcp_server.py (if exists)
if [ -f /opt/docling-mcp/mcp_server.py ]; then
    sudo cp /opt/docling-mcp/mcp_server.py /opt/docling-mcp/mcp_server.py.backup
fi

# Update mcp_server.py to integrate configuration
# NOTE: This assumes mcp_server.py already exists from Task 031
# We're adding configuration loading at the top

sudo tee /opt/docling-mcp/mcp_server.py > /dev/null << 'EOF'
#!/usr/bin/env python3
"""Docling MCP Server entry point with configuration management.

This server provides MCP protocol access to document processing, knowledge graph
generation, and document manipulation capabilities via FastMCP framework.

Configuration is loaded from:
1. /etc/docling-mcp/env/.env file
2. System environment variables (override .env values)

The server validates configuration at startup and fails fast if validation fails.
"""

import logging
import sys
from pathlib import Path

# ============================================================================
# Configuration Loading (FIRST - before any other imports)
# ============================================================================
from src.config.settings import DoclingMCPConfig

# Load and validate configuration at startup
try:
    config = DoclingMCPConfig.load_config()
except SystemExit:
    # Configuration validation failed - exit immediately
    sys.exit(1)
except Exception as e:
    print(f"FATAL: Unexpected error loading configuration: {e}", file=sys.stderr)
    sys.exit(1)

# ============================================================================
# Logging Configuration (based on validated config)
# ============================================================================
def setup_logging(log_level: str, log_format: str) -> None:
    """Configure logging based on configuration settings.

    Args:
        log_level: Logging level (DEBUG, INFO, WARN, ERROR)
        log_format: Log format (json or text)
    """
    # Map config log level to logging module constants
    level_map = {
        "DEBUG": logging.DEBUG,
        "INFO": logging.INFO,
        "WARN": logging.WARNING,
        "ERROR": logging.ERROR,
    }
    level = level_map.get(log_level.upper(), logging.INFO)

    if log_format == "json":
        # JSON structured logging for production
        import json
        from datetime import datetime

        class JSONFormatter(logging.Formatter):
            def format(self, record):
                log_obj = {
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "level": record.levelname,
                    "logger": record.name,
                    "message": record.getMessage(),
                    "module": record.module,
                    "function": record.funcName,
                    "line": record.lineno,
                }
                if record.exc_info:
                    log_obj["exception"] = self.formatException(record.exc_info)
                return json.dumps(log_obj)

        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(JSONFormatter())
    else:
        # Text logging for development/debugging
        handler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter(
            fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        handler.setFormatter(formatter)

    # Configure root logger
    logging.root.handlers = []
    logging.root.addHandler(handler)
    logging.root.setLevel(level)

    # Log startup message
    logger = logging.getLogger(__name__)
    logger.info(f"Logging configured: level={log_level}, format={log_format}")


# Setup logging based on configuration
setup_logging(config.mcp.log_level, config.mcp.log_format)
logger = logging.getLogger(__name__)

# ============================================================================
# Log Configuration Summary (sanitized - no secrets)
# ============================================================================
logger.info("=" * 70)
logger.info("Docling MCP Server Configuration Summary")
logger.info("=" * 70)
logger.info(f"Redis: {config.redis.host}:{config.redis.port}")
logger.info(f"Qdrant: {config.qdrant.host}:{config.qdrant.port}")
logger.info(f"LiteLLM API: {config.llm.litellm_api_base}")
logger.info(f"LightRAG API: {config.llm.lightrag_api_url}")
logger.info(f"Entity Model: {config.llm.entity_extraction_model}")
logger.info(f"Session TTL: {config.session.ttl_hours} hours")
logger.info(f"Cache Enabled: {config.cache.enabled}")
logger.info(f"Document Max Size: {config.processing.document_max_size_mb} MB")
logger.info(f"Concurrent Workers: {config.processing.concurrent_workers}")
logger.info(f"Cache Directory: {config.processing.docling_cache_dir}")
logger.info(f"MCP HTTP Port: {config.mcp.http_port}")
logger.info(f"MCP SSE Enabled: {config.mcp.sse_enabled}")
logger.info(f"MCP stdio Enabled: {config.mcp.stdio_enabled}")
logger.info("=" * 70)

# ============================================================================
# FastMCP Server Initialization
# ============================================================================
from fastmcp import FastMCP

# Initialize FastMCP server with configuration
mcp = FastMCP(
    name="docling-mcp-server",
    version="1.0.0",
    description="Document processing and knowledge graph generation MCP server"
)

# ============================================================================
# MCP Tools Registration
# (Will be added in subsequent tasks - Task 031-060)
# ============================================================================
# TODO: Register 19 MCP tools (conversion, generation, manipulation)

# ============================================================================
# Health Check Endpoint
# ============================================================================
@mcp.tool()
async def health_check() -> dict:
    """Health check endpoint for service monitoring.

    Returns:
        dict: Health status with dependency checks
    """
    logger.debug("Health check requested")
    return {
        "status": "healthy",
        "service": "docling-mcp-server",
        "version": "1.0.0",
        "dependencies": {
            "redis": f"{config.redis.host}:{config.redis.port}",
            "qdrant": f"{config.qdrant.host}:{config.qdrant.port}",
            "litellm": str(config.llm.litellm_api_base),
            "lightrag": str(config.llm.lightrag_api_url),
        },
        "configuration": {
            "cache_enabled": config.cache.enabled,
            "concurrent_workers": config.processing.concurrent_workers,
            "log_level": config.mcp.log_level,
        }
    }

# ============================================================================
# Server Startup
# ============================================================================
def main():
    """Main entry point for MCP server."""
    logger.info("Starting Docling MCP Server...")
    logger.info(f"Listening on HTTP port {config.mcp.http_port}")

    # Start server with configured transports
    transports = []

    if config.mcp.sse_enabled:
        logger.info("Server-Sent Events (SSE) transport enabled")
        transports.append("sse")

    if config.mcp.stdio_enabled:
        logger.info("stdio transport enabled")
        transports.append("stdio")

    # Run server (FastMCP handles transport initialization)
    mcp.run(
        transport=transports,
        port=config.mcp.http_port
    )


if __name__ == "__main__":
    main()
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/mcp_server.py

# Set executable permissions
sudo chmod 755 /opt/docling-mcp/mcp_server.py
```

### Step 2: Create Configuration Access Module

```bash
# Create module for global configuration access across all modules
sudo tee /opt/docling-mcp/src/config/manager.py > /dev/null << 'EOF'
"""Global configuration manager for accessing configuration across modules.

This module provides a singleton pattern for accessing the validated configuration
from any module in the application.
"""

from src.config.settings import DoclingMCPConfig
from typing import Optional

_global_config: Optional[DoclingMCPConfig] = None


def set_global_config(config: DoclingMCPConfig) -> None:
    """Set the global configuration instance.

    This should be called once at application startup after configuration validation.

    Args:
        config: Validated DoclingMCPConfig instance
    """
    global _global_config
    _global_config = config


def get_config() -> DoclingMCPConfig:
    """Get the global configuration instance.

    Returns:
        DoclingMCPConfig: The validated configuration instance

    Raises:
        RuntimeError: If configuration has not been initialized
    """
    if _global_config is None:
        raise RuntimeError(
            "Configuration not initialized. Call set_global_config() at startup."
        )
    return _global_config


# Convenience function for accessing nested settings
def get_redis_config():
    """Get Redis configuration."""
    return get_config().redis


def get_qdrant_config():
    """Get Qdrant configuration."""
    return get_config().qdrant


def get_llm_config():
    """Get LLM configuration."""
    return get_config().llm


def get_cache_config():
    """Get cache configuration."""
    return get_config().cache


def get_session_config():
    """Get session configuration."""
    return get_config().session


def get_processing_config():
    """Get processing configuration."""
    return get_config().processing


def get_mcp_config():
    """Get MCP server configuration."""
    return get_config().mcp
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/config/manager.py
```

### Step 3: Update MCP Server to Use Configuration Manager

```bash
# Add configuration manager initialization to mcp_server.py
# (Add after config loading, before logging setup)

sudo sed -i '/^config = DoclingMCPConfig.load_config()/a\
\
# Set global configuration for access by all modules\
from src.config.manager import set_global_config\
set_global_config(config)' /opt/docling-mcp/mcp_server.py

# Verify insertion
grep -A 3 "config = DoclingMCPConfig.load_config()" /opt/docling-mcp/mcp_server.py
```

## Validation

**Validation Commands:**

```bash
# Activate virtual environment
cd /opt/docling-mcp
source venv/bin/activate

# Test 1: Verify configuration imports successfully
python3 -c "from src.config.settings import DoclingMCPConfig; print('PASS: Configuration module imports')" && echo "PASS" || echo "FAIL"

# Test 2: Verify MCP server imports configuration
grep -q "from src.config.settings import DoclingMCPConfig" /opt/docling-mcp/mcp_server.py && echo "PASS: MCP server imports config" || echo "FAIL: Config import missing"

# Test 3: Verify logging configuration function exists
grep -q "def setup_logging" /opt/docling-mcp/mcp_server.py && echo "PASS: Logging setup function exists" || echo "FAIL: Logging setup missing"

# Test 4: Verify configuration manager exists
python3 -c "from src.config.manager import get_config, set_global_config; print('PASS: Config manager imports')" && echo "PASS" || echo "FAIL"

# Test 5: Verify MCP server can load with valid configuration
python3 -c "
import sys
sys.path.insert(0, '/opt/docling-mcp')
import mcp_server
print('PASS: MCP server loads with valid configuration')
" && echo "PASS" || echo "FAIL"

# Test 6: Verify configuration validation failure exits with code 1
# (Create temporary invalid .env file)
sudo cp /etc/docling-mcp/env/.env /etc/docling-mcp/env/.env.backup
echo "REDIS_PORT=99999" | sudo tee /etc/docling-mcp/env/.env > /dev/null

python3 -c "
import sys
sys.path.insert(0, '/opt/docling-mcp')
try:
    import mcp_server
    print('FAIL: Should have exited with validation error')
except SystemExit as e:
    if e.code == 1:
        print('PASS: Configuration validation failure exits with code 1')
    else:
        print(f'FAIL: Unexpected exit code {e.code}')
"

# Restore valid .env file
sudo mv /etc/docling-mcp/env/.env.backup /etc/docling-mcp/env/.env

# Test 7: Verify health check tool returns configuration info
python3 << 'PYEOF'
import sys
import asyncio
sys.path.insert(0, '/opt/docling-mcp')
from mcp_server import health_check, config

async def test_health():
    result = await health_check()
    assert result["status"] == "healthy"
    assert "dependencies" in result
    assert result["dependencies"]["redis"] == f"{config.redis.host}:{config.redis.port}"
    print("PASS: Health check returns configuration info")

asyncio.run(test_health())
PYEOF

# Deactivate venv
deactivate
```

**Expected Outcomes:**
- All 7 validation tests return "PASS"
- MCP server imports configuration at startup
- Configuration validation runs before server initialization
- Invalid configuration causes exit with code 1
- Health check endpoint includes configuration details
- Configuration manager provides global access

## Notes

### Configuration Loading Order

**Critical Sequence:**
1. Import DoclingMCPConfig
2. Load and validate configuration (DoclingMCPConfig.load_config())
3. Set global configuration (set_global_config())
4. Setup logging based on configuration
5. Log configuration summary (sanitized)
6. Initialize FastMCP server
7. Register MCP tools
8. Start server

This order ensures configuration is validated BEFORE any service initialization.

### Fail Fast Philosophy

**Configuration Validation:**
- Happens at import time (not runtime)
- Invalid configuration → SystemExit(1)
- Clear error messages logged to stderr
- No partial initialization (all-or-nothing)
- Service won't start with invalid configuration

This prevents runtime failures and ensures operational reliability.

### Configuration Access Pattern

**From any module:**
```python
from src.config.manager import get_redis_config

redis_config = get_redis_config()
print(f"Connecting to Redis: {redis_config.host}:{redis_config.port}")
```

**Benefits:**
- Single source of truth (no config duplication)
- Type-safe access (IDE autocomplete)
- Validated configuration (guaranteed valid at access time)
- Centralized configuration management

### Logging Configuration Strategy

**JSON Format (Production):**
- Structured logs for log aggregation tools
- Machine-parseable for monitoring/alerting
- Includes timestamp, level, module, function, line
- Exception tracebacks in JSON format

**Text Format (Development):**
- Human-readable console output
- Easier debugging during development
- Standard Python logging format

### Security: Sanitized Logging

**Never logged:**
- REDIS_PASSWORD
- QDRANT_API_KEY
- Any field with "password", "secret", "key" in name

**Logged at startup:**
- Hostnames and ports (safe to log)
- Feature flags (cache_enabled, sse_enabled)
- Limits and thresholds (max_size, workers)

### Why Configuration Manager Pattern

**Singleton Configuration:**
- Prevents multiple configuration loads
- Guarantees configuration consistency
- Simplifies dependency injection
- Testable (can inject mock config)

Alternative patterns (NOT used):
- Global config import (less testable)
- Config passed to every function (verbose)
- Environment variable access (no validation)

## References

- **Task 141**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-141-create-pydantic-settings-module.md`
- **Task 142**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-142-create-environment-file.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Configuration Requirements)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 10)

## Risk Assessment

**Risk**: Medium
- Changes MCP server entry point (core file)
- Configuration validation errors could prevent startup
- Logging changes affect debugging capability

**Mitigation**:
- Backup existing mcp_server.py before modification
- Comprehensive validation tests
- Clear error messages for troubleshooting
- Health check endpoint for operational monitoring
- Fail-fast approach prevents partial initialization
