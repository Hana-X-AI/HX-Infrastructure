# Task 143: Implement Configuration Validation Tests

**Assigned To**: paul-warfield
**Estimated Effort**: 1.5 hours
**Dependencies**: Task 141 (Pydantic Settings Module), Task 142 (Environment File)
**Status**: Not Started

## Objective

Create comprehensive pytest-based validation tests for the Pydantic configuration module to ensure all field validators, cross-field validation, type coercion, and error handling work correctly across all configuration scenarios.

## Pre-Execution Validation

**CRITICAL**: Check if configuration tests already exist BEFORE creating them to prevent duplication.

```bash
# Check if configuration test file exists
if [ -f "/opt/docling-mcp/tests/config/test_settings.py" ]; then
    echo "✅ VALIDATION RESULT: Configuration tests already exist"
    echo "ACTION: SKIP task execution - run existing tests instead"

    # Run existing tests to verify they pass
    cd /opt/docling-mcp
    source venv/bin/activate
    pytest tests/config/test_settings.py -v 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Existing tests passing - task complete"
        exit 0
    else
        echo "⚠️ Tests exist but some are failing - may need updates"
        exit 1
    fi
else
    echo "❌ VALIDATION RESULT: Configuration tests do NOT exist"
    echo "ACTION: PROCEED with test creation"
fi
```

**If Tests Exist and Pass**: Skip to Validation section
**If Tests Do Not Exist**: Continue with Implementation Steps below

---

## Context

Configuration validation tests ensure the Pydantic settings module correctly handles:
- Valid configuration values (happy path)
- Invalid configuration values (validation errors)
- Type coercion (string → int, string → bool)
- Field constraints (ranges, patterns, URL validation)
- Cross-field validation (TTL extension < TTL)
- Environment variable loading
- Default value fallbacks
- Error message clarity

These tests provide confidence that misconfiguration will be caught at startup before causing runtime failures.

## Acceptance Criteria

- [ ] Test directory created at `/opt/docling-mcp/tests/config/`
- [ ] Configuration test file created: `test_settings.py`
- [ ] Test fixtures for environment variable setup and teardown
- [ ] Tests for RedisSettings validation (host, port, connection pool)
- [ ] Tests for SessionSettings validation (TTL, extension validation)
- [ ] Tests for CacheSettings validation (TTL, size limits)
- [ ] Tests for QdrantSettings validation (host, port, connection pool)
- [ ] Tests for LLMSettings validation (URL, model pattern, temperature)
- [ ] Tests for ProcessingSettings validation (cache directory absolute path)
- [ ] Tests for MCPServerSettings validation (port range, log level)
- [ ] Tests for DoclingMCPConfig integration (full configuration loading)
- [ ] Tests for field validator behavior (TTL extension validator)
- [ ] Tests for type coercion (string → int, string → bool)
- [ ] Tests for validation error messages and clarity
- [ ] All tests pass with 100% success rate
- [ ] pytest integration with coverage reporting

## Implementation Steps

### Step 1: Create Test Directory Structure

```bash
# SSH to target server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create config test directory
sudo mkdir -p /opt/docling-mcp/tests/config

# Create __init__.py for test package
sudo touch /opt/docling-mcp/tests/config/__init__.py

# Set ownership to service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/config

# Verify directory structure
ls -la /opt/docling-mcp/tests/config/
# Expected: __init__.py owned by docling-mcp@hx.dev.local
```

### Step 2: Install pytest and Testing Dependencies

```bash
# Activate virtual environment
cd /opt/docling-mcp
source venv/bin/activate

# Install pytest and related packages
pip install pytest==8.3.3 pytest-cov==6.0.0 pytest-env==1.1.5

# Verify installation
pip show pytest pytest-cov pytest-env
# Expected: pytest 8.3.3, pytest-cov 6.0.0, pytest-env 1.1.5

# Deactivate venv
deactivate
```

### Step 3: Create Configuration Validation Tests

```bash
# Create comprehensive test suite for Pydantic settings
sudo tee /opt/docling-mcp/tests/config/test_settings.py > /dev/null << 'EOF'
"""Configuration validation tests for Pydantic settings module.

Tests cover:
- Field validation (types, ranges, patterns)
- Cross-field validation (custom validators)
- Environment variable loading
- Default value behavior
- Type coercion (string → int, bool)
- Error handling and messages
"""

import pytest
import os
from pathlib import Path
from pydantic import ValidationError
from src.config.settings import (
    DoclingMCPConfig,
    RedisSettings,
    SessionSettings,
    CacheSettings,
    QdrantSettings,
    LLMSettings,
    ProcessingSettings,
    MCPServerSettings,
)


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def clean_env(monkeypatch):
    """Clean environment before each test."""
    # Remove all config-related environment variables
    env_vars_to_remove = [
        k for k in os.environ.keys()
        if any(k.startswith(prefix) for prefix in [
            "REDIS_", "SESSION_", "CACHE_", "QDRANT_",
            "LLM_", "PROCESSING_", "MCP_"
        ])
    ]
    for var in env_vars_to_remove:
        monkeypatch.delenv(var, raising=False)
    yield


# ============================================================================
# RedisSettings Tests
# ============================================================================

def test_redis_settings_defaults():
    """Test RedisSettings uses correct default values."""
    settings = RedisSettings()
    assert settings.host == "hx-redis-server.hx.dev.local"
    assert settings.port == 6379
    assert settings.password is None
    assert settings.connection_pool_size == 10
    assert settings.connection_timeout_seconds == 5
    assert settings.operation_timeout_seconds == 10
    assert settings.retry_attempts == 3
    assert settings.health_check_interval_seconds == 30


def test_redis_settings_custom_values():
    """Test RedisSettings accepts valid custom values."""
    settings = RedisSettings(
        host="custom-redis.local",
        port=6380,
        password="secret123",
        connection_pool_size=20,
        connection_timeout_seconds=10,
        operation_timeout_seconds=20,
        retry_attempts=5,
        health_check_interval_seconds=60
    )
    assert settings.host == "custom-redis.local"
    assert settings.port == 6380
    assert settings.password == "secret123"
    assert settings.connection_pool_size == 20


def test_redis_settings_port_validation():
    """Test RedisSettings validates port range (1-65535)."""
    # Valid port
    settings = RedisSettings(port=1024)
    assert settings.port == 1024

    # Invalid port (too low)
    with pytest.raises(ValidationError) as exc_info:
        RedisSettings(port=0)
    assert "greater than or equal to 1" in str(exc_info.value)

    # Invalid port (too high)
    with pytest.raises(ValidationError) as exc_info:
        RedisSettings(port=70000)
    assert "less than or equal to 65535" in str(exc_info.value)


def test_redis_settings_pool_size_validation():
    """Test RedisSettings validates connection pool size (1-100)."""
    # Valid pool size
    settings = RedisSettings(connection_pool_size=50)
    assert settings.connection_pool_size == 50

    # Invalid pool size (too low)
    with pytest.raises(ValidationError) as exc_info:
        RedisSettings(connection_pool_size=0)
    assert "greater than or equal to 1" in str(exc_info.value)

    # Invalid pool size (too high)
    with pytest.raises(ValidationError) as exc_info:
        RedisSettings(connection_pool_size=150)
    assert "less than or equal to 100" in str(exc_info.value)


# ============================================================================
# SessionSettings Tests
# ============================================================================

def test_session_settings_defaults():
    """Test SessionSettings uses correct default values."""
    settings = SessionSettings()
    assert settings.ttl_hours == 24
    assert settings.ttl_extension_hours == 4


def test_session_settings_ttl_validation():
    """Test SessionSettings validates TTL range (1-168 hours)."""
    # Valid TTL
    settings = SessionSettings(ttl_hours=48)
    assert settings.ttl_hours == 48

    # Invalid TTL (too low)
    with pytest.raises(ValidationError) as exc_info:
        SessionSettings(ttl_hours=0)
    assert "greater than or equal to 1" in str(exc_info.value)

    # Invalid TTL (too high - max 7 days)
    with pytest.raises(ValidationError) as exc_info:
        SessionSettings(ttl_hours=200)
    assert "less than or equal to 168" in str(exc_info.value)


def test_session_settings_extension_validator():
    """Test SessionSettings validates extension doesn't exceed TTL."""
    # Valid: extension < TTL
    settings = SessionSettings(ttl_hours=24, ttl_extension_hours=4)
    assert settings.ttl_extension_hours == 4

    # Invalid: extension > TTL
    with pytest.raises(ValidationError) as exc_info:
        SessionSettings(ttl_hours=10, ttl_extension_hours=20)
    assert "cannot exceed ttl_hours" in str(exc_info.value)

    # Valid: extension == TTL (edge case)
    settings = SessionSettings(ttl_hours=24, ttl_extension_hours=24)
    assert settings.ttl_extension_hours == 24


# ============================================================================
# CacheSettings Tests
# ============================================================================

def test_cache_settings_defaults():
    """Test CacheSettings uses correct default values."""
    settings = CacheSettings()
    assert settings.enabled is True
    assert settings.ttl_hours == 24
    assert settings.max_document_size_mb == 5
    assert settings.metadata_ttl_hours == 168
    assert settings.entity_ttl_hours == 24
    assert settings.docling_ttl_hours == 24


def test_cache_settings_boolean_type_coercion():
    """Test CacheSettings coerces string to bool."""
    # Pydantic should coerce string "true" → bool True
    settings = CacheSettings(enabled="true")
    assert settings.enabled is True
    assert isinstance(settings.enabled, bool)

    settings = CacheSettings(enabled="false")
    assert settings.enabled is False


def test_cache_settings_max_size_validation():
    """Test CacheSettings validates max document size (1-100 MB)."""
    # Valid size
    settings = CacheSettings(max_document_size_mb=10)
    assert settings.max_document_size_mb == 10

    # Invalid size (too low)
    with pytest.raises(ValidationError) as exc_info:
        CacheSettings(max_document_size_mb=0)
    assert "greater than or equal to 1" in str(exc_info.value)

    # Invalid size (too high)
    with pytest.raises(ValidationError) as exc_info:
        CacheSettings(max_document_size_mb=200)
    assert "less than or equal to 100" in str(exc_info.value)


# ============================================================================
# QdrantSettings Tests
# ============================================================================

def test_qdrant_settings_defaults():
    """Test QdrantSettings uses correct default values."""
    settings = QdrantSettings()
    assert settings.host == "hx-qdrant-server.hx.dev.local"
    assert settings.port == 6333
    assert settings.api_key is None
    assert settings.connection_pool_max == 10
    assert settings.keepalive_seconds == 60
    assert settings.retry_attempts == 3


# ============================================================================
# LLMSettings Tests
# ============================================================================

def test_llm_settings_defaults():
    """Test LLMSettings uses correct default values."""
    settings = LLMSettings()
    assert str(settings.litellm_api_base) == "http://hx-litellm-server.hx.dev.local:4000/"
    assert str(settings.lightrag_api_url) == "http://hx-literag-server.hx.dev.local:8000/"
    assert settings.entity_extraction_model == "gemma3:27b"
    assert settings.temperature == 0.1
    assert settings.max_tokens == 2048
    assert settings.timeout_seconds == 60


def test_llm_settings_url_validation():
    """Test LLMSettings validates HTTP URLs."""
    # Valid HTTP URL
    settings = LLMSettings(litellm_api_base="http://custom-server.local:4000")
    assert "custom-server.local" in str(settings.litellm_api_base)

    # Invalid URL (missing scheme)
    with pytest.raises(ValidationError) as exc_info:
        LLMSettings(litellm_api_base="invalid-url")
    assert "URL" in str(exc_info.value).upper()


def test_llm_settings_model_pattern_validation():
    """Test LLMSettings validates model name pattern."""
    # Valid model names
    valid_models = ["gemma3:27b", "llama3:8b", "mixtral:8x7b", "gpt-4"]
    for model in valid_models:
        settings = LLMSettings(entity_extraction_model=model)
        assert settings.entity_extraction_model == model

    # Invalid model name (uppercase not allowed)
    with pytest.raises(ValidationError) as exc_info:
        LLMSettings(entity_extraction_model="GPT-4")
    assert "pattern" in str(exc_info.value).lower()


def test_llm_settings_temperature_validation():
    """Test LLMSettings validates temperature range (0.0-2.0)."""
    # Valid temperature
    settings = LLMSettings(temperature=0.5)
    assert settings.temperature == 0.5

    # Invalid temperature (too low)
    with pytest.raises(ValidationError) as exc_info:
        LLMSettings(temperature=-0.1)
    assert "greater than or equal to 0" in str(exc_info.value)

    # Invalid temperature (too high)
    with pytest.raises(ValidationError) as exc_info:
        LLMSettings(temperature=3.0)
    assert "less than or equal to 2" in str(exc_info.value)


# ============================================================================
# ProcessingSettings Tests
# ============================================================================

def test_processing_settings_defaults():
    """Test ProcessingSettings uses correct default values."""
    settings = ProcessingSettings()
    assert settings.document_max_size_mb == 500
    assert settings.concurrent_workers == 4
    assert settings.docling_cache_dir == Path("/var/lib/docling-mcp/cache")


def test_processing_settings_cache_dir_absolute_path_validator():
    """Test ProcessingSettings validates cache directory is absolute path."""
    # Valid absolute path
    settings = ProcessingSettings(docling_cache_dir=Path("/tmp/cache"))
    assert settings.docling_cache_dir.is_absolute()

    # Invalid relative path
    with pytest.raises(ValidationError) as exc_info:
        ProcessingSettings(docling_cache_dir=Path("relative/path"))
    assert "absolute path" in str(exc_info.value)


def test_processing_settings_concurrent_workers_validation():
    """Test ProcessingSettings validates concurrent workers (1-20)."""
    # Valid worker count
    settings = ProcessingSettings(concurrent_workers=8)
    assert settings.concurrent_workers == 8

    # Invalid worker count (too low)
    with pytest.raises(ValidationError) as exc_info:
        ProcessingSettings(concurrent_workers=0)
    assert "greater than or equal to 1" in str(exc_info.value)

    # Invalid worker count (too high)
    with pytest.raises(ValidationError) as exc_info:
        ProcessingSettings(concurrent_workers=30)
    assert "less than or equal to 20" in str(exc_info.value)


# ============================================================================
# MCPServerSettings Tests
# ============================================================================

def test_mcp_server_settings_defaults():
    """Test MCPServerSettings uses correct default values."""
    settings = MCPServerSettings()
    assert settings.http_port == 8000
    assert settings.sse_enabled is True
    assert settings.stdio_enabled is True
    assert settings.log_level == "INFO"
    assert settings.log_format == "json"


def test_mcp_server_settings_port_validation():
    """Test MCPServerSettings validates port range (1024-65535)."""
    # Valid port
    settings = MCPServerSettings(http_port=8080)
    assert settings.http_port == 8080

    # Invalid port (too low - privileged ports)
    with pytest.raises(ValidationError) as exc_info:
        MCPServerSettings(http_port=80)
    assert "greater than or equal to 1024" in str(exc_info.value)


def test_mcp_server_settings_log_level_literal():
    """Test MCPServerSettings validates log level is valid Literal."""
    # Valid log levels
    for level in ["DEBUG", "INFO", "WARN", "ERROR"]:
        settings = MCPServerSettings(log_level=level)
        assert settings.log_level == level

    # Invalid log level
    with pytest.raises(ValidationError) as exc_info:
        MCPServerSettings(log_level="INVALID")
    assert "Input should be" in str(exc_info.value)


# ============================================================================
# DoclingMCPConfig Integration Tests
# ============================================================================

def test_docling_mcp_config_defaults(clean_env, monkeypatch):
    """Test DoclingMCPConfig loads all default values correctly."""
    # Disable .env file loading for this test
    monkeypatch.setattr("src.config.settings.DoclingMCPConfig.model_config", {
        **DoclingMCPConfig.model_config,
        "env_file": None
    })

    config = DoclingMCPConfig()

    # Verify nested settings
    assert config.redis.host == "hx-redis-server.hx.dev.local"
    assert config.qdrant.host == "hx-qdrant-server.hx.dev.local"
    assert "hx-litellm-server" in str(config.llm.litellm_api_base)
    assert config.session.ttl_hours == 24
    assert config.cache.enabled is True
    assert config.processing.concurrent_workers == 4
    assert config.mcp.http_port == 8000


def test_docling_mcp_config_environment_override(clean_env, monkeypatch):
    """Test DoclingMCPConfig loads values from environment variables."""
    # Set environment variables
    monkeypatch.setenv("REDIS_HOST", "custom-redis.local")
    monkeypatch.setenv("REDIS_PORT", "6380")
    monkeypatch.setenv("SESSION_TTL_HOURS", "48")
    monkeypatch.setenv("CACHE_ENABLED", "false")
    monkeypatch.setenv("MCP_HTTP_PORT", "9000")
    monkeypatch.setenv("MCP_LOG_LEVEL", "DEBUG")

    # Disable .env file loading
    monkeypatch.setattr("src.config.settings.DoclingMCPConfig.model_config", {
        **DoclingMCPConfig.model_config,
        "env_file": None
    })

    config = DoclingMCPConfig()

    # Verify environment overrides
    assert config.redis.host == "custom-redis.local"
    assert config.redis.port == 6380
    assert config.session.ttl_hours == 48
    assert config.cache.enabled is False
    assert config.mcp.http_port == 9000
    assert config.mcp.log_level == "DEBUG"


def test_docling_mcp_config_type_coercion(clean_env, monkeypatch):
    """Test DoclingMCPConfig coerces string env vars to correct types."""
    # Set environment variables as strings
    monkeypatch.setenv("REDIS_PORT", "6379")  # string → int
    monkeypatch.setenv("CACHE_ENABLED", "true")  # string → bool
    monkeypatch.setenv("SESSION_TTL_HOURS", "24")  # string → int

    # Disable .env file loading
    monkeypatch.setattr("src.config.settings.DoclingMCPConfig.model_config", {
        **DoclingMCPConfig.model_config,
        "env_file": None
    })

    config = DoclingMCPConfig()

    # Verify types coerced correctly
    assert isinstance(config.redis.port, int)
    assert config.redis.port == 6379
    assert isinstance(config.cache.enabled, bool)
    assert config.cache.enabled is True
    assert isinstance(config.session.ttl_hours, int)
    assert config.session.ttl_hours == 24


def test_docling_mcp_config_nested_delimiter(clean_env, monkeypatch):
    """Test DoclingMCPConfig supports nested delimiter for environment variables."""
    # Set nested environment variables
    monkeypatch.setenv("LLM_ENTITY_EXTRACTION_MODEL", "llama3:8b")
    monkeypatch.setenv("PROCESSING_CONCURRENT_WORKERS", "8")

    # Disable .env file loading
    monkeypatch.setattr("src.config.settings.DoclingMCPConfig.model_config", {
        **DoclingMCPConfig.model_config,
        "env_file": None
    })

    config = DoclingMCPConfig()

    # Verify nested configuration parsed correctly
    assert config.llm.entity_extraction_model == "llama3:8b"
    assert config.processing.concurrent_workers == 8


# ============================================================================
# Error Handling Tests
# ============================================================================

def test_config_validation_error_clarity():
    """Test that validation errors provide clear, actionable messages."""
    with pytest.raises(ValidationError) as exc_info:
        RedisSettings(port=70000)

    error_message = str(exc_info.value)
    # Error should mention field name and constraint
    assert "port" in error_message.lower()
    assert "65535" in error_message


def test_config_unknown_field_rejected():
    """Test that unknown environment variables are rejected (extra='forbid')."""
    with pytest.raises(ValidationError) as exc_info:
        RedisSettings(unknown_field="value")

    error_message = str(exc_info.value)
    assert "extra" in error_message.lower() or "unexpected" in error_message.lower()
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/config/test_settings.py

# Set permissions (644)
sudo chmod 644 /opt/docling-mcp/tests/config/test_settings.py
```

### Step 4: Create pytest Configuration

```bash
# Create pytest.ini for test configuration
sudo tee /opt/docling-mcp/pytest.ini > /dev/null << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -v
    --strict-markers
    --tb=short
    --cov=src.config
    --cov-report=term-missing
    --cov-report=html:htmlcov
markers =
    unit: Unit tests for configuration validation
    integration: Integration tests for full config loading
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/pytest.ini
```

### Step 5: Run Configuration Tests

```bash
# Activate virtual environment
cd /opt/docling-mcp
source venv/bin/activate

# Run all configuration tests
pytest tests/config/test_settings.py -v

# Expected output: All tests PASSED

# Run with coverage report
pytest tests/config/test_settings.py --cov=src.config --cov-report=term-missing

# Deactivate venv
deactivate
```

## Validation

**Validation Commands:**

```bash
# Activate virtual environment
cd /opt/docling-mcp
source venv/bin/activate

# Test 1: Verify all tests pass
pytest tests/config/test_settings.py -v && echo "PASS: All tests passing" || echo "FAIL: Some tests failing"

# Test 2: Verify test coverage >= 90%
pytest tests/config/test_settings.py --cov=src.config --cov-report=term | grep "TOTAL" | awk '{if ($4 >= 90) print "PASS: Coverage >= 90%"; else print "FAIL: Coverage < 90%"}'

# Test 3: Verify default value tests
pytest tests/config/test_settings.py -k "test_redis_settings_defaults" -v && echo "PASS: Default tests working" || echo "FAIL: Default tests failing"

# Test 4: Verify validation tests
pytest tests/config/test_settings.py -k "validation" -v && echo "PASS: Validation tests working" || echo "FAIL: Validation tests failing"

# Test 5: Verify type coercion tests
pytest tests/config/test_settings.py -k "coercion" -v && echo "PASS: Type coercion tests working" || echo "FAIL: Type coercion tests failing"

# Test 6: Verify integration tests
pytest tests/config/test_settings.py -k "test_docling_mcp_config" -v && echo "PASS: Integration tests working" || echo "FAIL: Integration tests failing"

# Deactivate venv
deactivate
```

**Expected Outcomes:**
- All tests pass (100% success rate)
- Test coverage >= 90% for src.config module
- No test failures or errors
- Clear test output with verbose descriptions
- Coverage report generated in htmlcov/

## Notes

### Test Organization

Tests are organized by configuration class:
- **RedisSettings**: Connection pool, timeout, retry validation
- **SessionSettings**: TTL and extension cross-field validation
- **CacheSettings**: Size limits and TTL validation
- **QdrantSettings**: Connection pool and keepalive validation
- **LLMSettings**: URL validation, model pattern, temperature ranges
- **ProcessingSettings**: Path validation, worker count limits
- **MCPServerSettings**: Port ranges, log level literals
- **DoclingMCPConfig**: Integration tests for full configuration

### Test Coverage Strategy

**Unit Tests (per class):**
- Default value verification
- Custom value acceptance
- Field constraint validation (ranges, patterns)
- Type coercion (string → int, bool)
- Validation error messages

**Integration Tests (DoclingMCPConfig):**
- Default configuration loading
- Environment variable overrides
- Nested delimiter parsing
- Full configuration validation

### Why pytest for Configuration Testing

**Benefits:**
- Clear test discovery (`test_*.py` pattern)
- Comprehensive assertion introspection
- Fixture-based setup/teardown (clean_env)
- Parameterized testing support
- Coverage reporting integration
- Continuous integration friendly

### Validation Error Testing Strategy

Tests verify that invalid configurations:
1. Raise `ValidationError` exception
2. Include field name in error message
3. Include constraint value in error message
4. Provide actionable guidance for fixing

This ensures developers get clear feedback when configuration is invalid.

### Environment Variable Isolation

The `clean_env` fixture ensures:
- No environment variable pollution between tests
- Consistent test execution order independence
- Predictable default value testing
- Reliable environment override testing

### Coverage Reporting

Coverage report shows:
- Which lines of settings.py are tested
- Missing coverage areas (untested code paths)
- Percentage coverage per file
- HTML report for detailed visualization

Target: >= 90% coverage for configuration module

## References

- **Task 141**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-141-create-pydantic-settings-module.md`
- **pytest Documentation**: https://docs.pytest.org/
- **Pydantic Testing Guide**: https://docs.pydantic.dev/latest/concepts/validation/
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 10)

## Risk Assessment

**Risk**: Low
- No impact on production (test-only code)
- Tests validate configuration correctness
- Easily reversible (delete test files)
- Provides confidence in configuration module

**Mitigation**:
- Comprehensive test coverage (>= 90%)
- Environment isolation via fixtures
- Clear validation error testing
- Integration tests verify full configuration loading
