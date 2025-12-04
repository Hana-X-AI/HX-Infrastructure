# Task 142: Create Environment Configuration File

**Assigned To**: paul-warfield
**Estimated Effort**: 1.0 hours
**Dependencies**: Task 006 (Directory Structure), Task 141 (Pydantic Settings Module)
**Status**: Not Started

## Objective

Create the environment variable configuration file (`/etc/docling-mcp/env/.env`) with production-ready defaults for all required and optional configuration settings, following the Pydantic settings schema defined in Task 141.

## Pre-Execution Validation

**CRITICAL**: Check if environment file already exists BEFORE creating it to prevent overwriting production configuration.

```bash
# Check if .env file exists
if [ -f "/etc/docling-mcp/env/.env" ]; then
    echo "✅ VALIDATION RESULT: Environment file already exists"
    echo "ACTION: SKIP task execution - validate existing configuration instead"

    # Check file ownership and permissions
    ls -la /etc/docling-mcp/env/.env

    # Verify file contains required variables
    grep -q "REDIS_HOST" /etc/docling-mcp/env/.env && \
    grep -q "QDRANT_HOST" /etc/docling-mcp/env/.env && \
    grep -q "LLM_LITELLM_API_BASE" /etc/docling-mcp/env/.env

    if [ $? -eq 0 ]; then
        echo "✅ Environment file contains required variables - task complete"
        exit 0
    else
        echo "⚠️ Environment file exists but missing required variables - may need updating"
        exit 1
    fi
else
    echo "❌ VALIDATION RESULT: Environment file does NOT exist"
    echo "ACTION: PROCEED with environment file creation"
fi
```

**If File Exists with Required Variables**: Skip to Validation section
**If File Does Not Exist**: Continue with Implementation Steps below

---

## Context

The environment file (`/etc/docling-mcp/env/.env`) provides production configuration values loaded by Pydantic BaseSettings. This file:
- Contains all required and optional environment variables
- Uses hostname-based service discovery (NOT IP addresses)
- Provides sensible defaults for all settings
- Is loaded automatically by DoclingMCPConfig via SettingsConfigDict
- Can be overridden by system environment variables (systemd)
- Must NOT be committed to git (contains sensitive configuration)

The file follows HX-Infrastructure standards:
- Hostname-based endpoints (hx-redis-server.hx.dev.local)
- No hardcoded IP addresses
- No firewall configuration (all firewalls disabled)
- Manual procedures only (no automation scripts)

## Acceptance Criteria

- [ ] Environment file created at `/etc/docling-mcp/env/.env`
- [ ] File ownership: `docling-mcp@hx.dev.local:domain users@hx.dev.local`
- [ ] File permissions: `640` (owner read/write, group read, no world access)
- [ ] Redis configuration variables with hx-redis-server.hx.dev.local hostname
- [ ] Qdrant configuration variables with hx-qdrant-server.hx.dev.local hostname
- [ ] LiteLLM configuration with hx-litellm-server.hx.dev.local hostname
- [ ] LightRAG configuration with hx-literag-server.hx.dev.local hostname
- [ ] Session management TTL configuration
- [ ] Cache configuration with TTL settings
- [ ] Processing limits configuration
- [ ] MCP server transport configuration
- [ ] Logging configuration (JSON format, INFO level)
- [ ] All hostnames use .hx.dev.local domain (NO IP addresses)
- [ ] File validates successfully with Pydantic settings module

## Implementation Steps

### Step 1: Create Environment Directory

```bash
# SSH to target server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create environment directory if not exists
sudo mkdir -p /etc/docling-mcp/env

# Set ownership to service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /etc/docling-mcp/env

# Verify directory created
ls -la /etc/docling-mcp/
# Expected: env/ directory owned by docling-mcp@hx.dev.local
```

### Step 2: Create Environment Configuration File

```bash
# Create .env file with production defaults
sudo tee /etc/docling-mcp/env/.env > /dev/null << 'EOF'
# Docling MCP Server Environment Configuration
# Generated: 2025-12-01
# DO NOT COMMIT THIS FILE TO GIT

# =============================================================================
# Redis Configuration
# =============================================================================
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
# REDIS_PASSWORD=  # Optional - load from Ansible Vault if authentication enabled

REDIS_CONNECTION_POOL_SIZE=10
REDIS_CONNECTION_TIMEOUT_SECONDS=5
REDIS_OPERATION_TIMEOUT_SECONDS=10
REDIS_RETRY_ATTEMPTS=3
REDIS_HEALTH_CHECK_INTERVAL_SECONDS=30

# =============================================================================
# Session Management Configuration
# =============================================================================
SESSION_TTL_HOURS=24
SESSION_TTL_EXTENSION_HOURS=4

# =============================================================================
# Cache Configuration
# =============================================================================
CACHE_ENABLED=true
CACHE_TTL_HOURS=24
CACHE_MAX_DOCUMENT_SIZE_MB=5
CACHE_METADATA_TTL_HOURS=168
CACHE_ENTITY_TTL_HOURS=24
CACHE_DOCLING_TTL_HOURS=24

# =============================================================================
# Qdrant Vector Database Configuration
# =============================================================================
QDRANT_HOST=hx-qdrant-server.hx.dev.local
QDRANT_PORT=6333
# QDRANT_API_KEY=  # Optional - load from Ansible Vault if authentication enabled

QDRANT_CONNECTION_POOL_MAX=10
QDRANT_KEEPALIVE_SECONDS=60
QDRANT_RETRY_ATTEMPTS=3

# =============================================================================
# LLM Configuration (LiteLLM Gateway)
# =============================================================================
LLM_LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000
LLM_LIGHTRAG_API_URL=http://hx-literag-server.hx.dev.local:8000
LLM_ENTITY_EXTRACTION_MODEL=gemma3:27b
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=2048
LLM_TIMEOUT_SECONDS=60

# =============================================================================
# Document Processing Configuration
# =============================================================================
PROCESSING_DOCUMENT_MAX_SIZE_MB=500
PROCESSING_CONCURRENT_WORKERS=4
PROCESSING_DOCLING_CACHE_DIR=/var/lib/docling-mcp/cache

# =============================================================================
# MCP Server Transport Configuration
# =============================================================================
MCP_HTTP_PORT=8000
MCP_SSE_ENABLED=true
MCP_STDIO_ENABLED=true

# =============================================================================
# Logging Configuration
# =============================================================================
MCP_LOG_LEVEL=INFO
MCP_LOG_FORMAT=json

# =============================================================================
# Notes:
# - All hostnames use .hx.dev.local domain (internal DNS)
# - No IP addresses (hostname-based service discovery)
# - Secrets (passwords, API keys) loaded from Ansible Vault at runtime
# - Override any value by setting environment variable in systemd service
# =============================================================================
EOF

# Set ownership to service account
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /etc/docling-mcp/env/.env

# Set permissions (640 - owner read/write, group read, no world access)
sudo chmod 640 /etc/docling-mcp/env/.env

# Verify file created with correct permissions
ls -la /etc/docling-mcp/env/.env
# Expected: -rw-r----- 1 docling-mcp@hx.dev.local domain users@hx.dev.local ... .env
```

### Step 3: Create Environment Template for Documentation

```bash
# Create .env.template for documentation (safe to commit to git)
sudo tee /etc/docling-mcp/env/.env.template > /dev/null << 'EOF'
# Docling MCP Server Environment Configuration Template
# Copy this to .env and customize for your deployment

# Redis Configuration
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
REDIS_CONNECTION_POOL_SIZE=10
REDIS_CONNECTION_TIMEOUT_SECONDS=5
REDIS_OPERATION_TIMEOUT_SECONDS=10
REDIS_RETRY_ATTEMPTS=3
REDIS_HEALTH_CHECK_INTERVAL_SECONDS=30

# Session Management
SESSION_TTL_HOURS=24
SESSION_TTL_EXTENSION_HOURS=4

# Cache Configuration
CACHE_ENABLED=true
CACHE_TTL_HOURS=24
CACHE_MAX_DOCUMENT_SIZE_MB=5
CACHE_METADATA_TTL_HOURS=168
CACHE_ENTITY_TTL_HOURS=24
CACHE_DOCLING_TTL_HOURS=24

# Qdrant Configuration
QDRANT_HOST=hx-qdrant-server.hx.dev.local
QDRANT_PORT=6333
QDRANT_CONNECTION_POOL_MAX=10
QDRANT_KEEPALIVE_SECONDS=60
QDRANT_RETRY_ATTEMPTS=3

# LLM Configuration
LLM_LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000
LLM_LIGHTRAG_API_URL=http://hx-literag-server.hx.dev.local:8000
LLM_ENTITY_EXTRACTION_MODEL=gemma3:27b
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=2048
LLM_TIMEOUT_SECONDS=60

# Document Processing
PROCESSING_DOCUMENT_MAX_SIZE_MB=500
PROCESSING_CONCURRENT_WORKERS=4
PROCESSING_DOCLING_CACHE_DIR=/var/lib/docling-mcp/cache

# MCP Server
MCP_HTTP_PORT=8000
MCP_SSE_ENABLED=true
MCP_STDIO_ENABLED=true
MCP_LOG_LEVEL=INFO
MCP_LOG_FORMAT=json
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /etc/docling-mcp/env/.env.template

# Set permissions (644 - readable by all)
sudo chmod 644 /etc/docling-mcp/env/.env.template
```

### Step 4: Verify Environment Variables Parse Correctly

```bash
# Activate virtual environment
cd /opt/docling-mcp
source venv/bin/activate

# Test configuration loading from .env file
python3 << 'PYEOF'
from src.config.settings import DoclingMCPConfig

# Load configuration from .env file
config = DoclingMCPConfig()

# Verify all settings loaded correctly
print("Configuration Validation Results:")
print("=" * 60)
print(f"Redis Host: {config.redis.host}")
print(f"Redis Port: {config.redis.port}")
print(f"Qdrant Host: {config.qdrant.host}")
print(f"Qdrant Port: {config.qdrant.port}")
print(f"LiteLLM API: {config.llm.litellm_api_base}")
print(f"LightRAG API: {config.llm.lightrag_api_url}")
print(f"Entity Model: {config.llm.entity_extraction_model}")
print(f"Session TTL: {config.session.ttl_hours} hours")
print(f"Cache Enabled: {config.cache.enabled}")
print(f"Document Max Size: {config.processing.document_max_size_mb} MB")
print(f"Concurrent Workers: {config.processing.concurrent_workers}")
print(f"MCP HTTP Port: {config.mcp.http_port}")
print(f"MCP SSE Enabled: {config.mcp.sse_enabled}")
print(f"Log Level: {config.mcp.log_level}")
print(f"Log Format: {config.mcp.log_format}")
print("=" * 60)
print("✅ All configuration values loaded successfully")
PYEOF

# Deactivate venv
deactivate
```

## Validation

**Validation Commands:**

```bash
# Test 1: Verify .env file exists with correct ownership
ls -la /etc/docling-mcp/env/.env | grep "docling-mcp@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# Test 2: Verify file permissions (640)
stat -c "%a" /etc/docling-mcp/env/.env | grep -q "640" && echo "PASS: Permissions correct" || echo "FAIL: Permissions incorrect"

# Test 3: Verify all required Redis variables present
grep -q "REDIS_HOST=hx-redis-server.hx.dev.local" /etc/docling-mcp/env/.env && echo "PASS: Redis host configured" || echo "FAIL: Redis host missing"

# Test 4: Verify all required Qdrant variables present
grep -q "QDRANT_HOST=hx-qdrant-server.hx.dev.local" /etc/docling-mcp/env/.env && echo "PASS: Qdrant host configured" || echo "FAIL: Qdrant host missing"

# Test 5: Verify LiteLLM API base URL configured
grep -q "LLM_LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000" /etc/docling-mcp/env/.env && echo "PASS: LiteLLM API configured" || echo "FAIL: LiteLLM API missing"

# Test 6: Verify LightRAG API URL configured
grep -q "LLM_LIGHTRAG_API_URL=http://hx-literag-server.hx.dev.local:8000" /etc/docling-mcp/env/.env && echo "PASS: LightRAG API configured" || echo "FAIL: LightRAG API missing"

# Test 7: Verify no IP addresses in configuration (hostname-based only)
! grep -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /etc/docling-mcp/env/.env && echo "PASS: No IP addresses (hostname-based)" || echo "FAIL: Found IP addresses"

# Test 8: Verify Pydantic can load and validate configuration
cd /opt/docling-mcp
source venv/bin/activate
python3 -c "from src.config.settings import DoclingMCPConfig; config = DoclingMCPConfig(); print(f'Config valid: Redis={config.redis.host}, Qdrant={config.qdrant.host}')" && echo "PASS: Pydantic validation successful" || echo "FAIL: Pydantic validation failed"
deactivate
```

**Expected Outcomes:**
- All 8 validation tests return "PASS"
- File ownership: docling-mcp@hx.dev.local
- File permissions: 640 (owner read/write, group read)
- All hostnames use .hx.dev.local domain
- No IP addresses in configuration
- Pydantic successfully loads and validates configuration

## Notes

### Environment Variable Naming Convention

**Nested Configuration Syntax:**
- Top-level group prefix: `REDIS_`, `QDRANT_`, `LLM_`, `CACHE_`, `SESSION_`, `PROCESSING_`, `MCP_`
- Nested fields use underscore delimiter: `REDIS_CONNECTION_POOL_SIZE`, `LLM_LITELLM_API_BASE`
- Boolean values: lowercase `true`/`false` (Pydantic auto-converts)
- Integer values: plain numbers (Pydantic auto-converts from string)

**Examples:**
```bash
REDIS_HOST=hx-redis-server.hx.dev.local  # → config.redis.host
CACHE_ENABLED=true                        # → config.cache.enabled
SESSION_TTL_HOURS=24                      # → config.session.ttl_hours
LLM_LITELLM_API_BASE=http://...          # → config.llm.litellm_api_base
```

### Override Priority

Configuration values can be overridden in this order (highest priority first):
1. **System environment variables** (set in systemd service or shell)
2. **Environment file** (`/etc/docling-mcp/env/.env`)
3. **Default values** (in Pydantic Field() definitions)

This allows systemd service to override .env values for production deployment.

### Security Best Practices

**Secrets Management:**
- `.env` file contains NO secrets by default (password fields commented out)
- Secrets injected at runtime via systemd EnvironmentFile
- Ansible Vault decrypts secrets into temporary file
- systemd loads decrypted secrets as environment variables
- `.env` file permissions: 640 (no world access)
- `.env` file MUST NOT be committed to git (add to .gitignore)

**Template File:**
- `.env.template` is SAFE to commit (contains no secrets)
- Used for documentation and deployment automation
- Developers copy template to `.env` and customize

### Hostname-Based Configuration

**ALL service endpoints use hostnames:**
- Redis: `hx-redis-server.hx.dev.local:6379`
- Qdrant: `hx-qdrant-server.hx.dev.local:6333`
- LiteLLM: `hx-litellm-server.hx.dev.local:4000`
- LightRAG: `hx-literag-server.hx.dev.local:8000`

**Benefits:**
- DNS-based service discovery
- IP changes don't break configuration
- Works across network topology changes
- Consistent with HX-Infrastructure standards

### Configuration Validation

Pydantic validates all settings at startup:
- **Type validation**: Automatic (string → int, string → bool)
- **Range validation**: Field constraints (ge, le)
- **Pattern validation**: StringConstraints regex patterns
- **URL validation**: HttpUrl type ensures valid URLs
- **Cross-field validation**: Custom validators (@field_validator)

If validation fails, service exits with status code 1 and logs detailed error.

### Why .env File Location

**Rationale for `/etc/docling-mcp/env/.env`:**
- Standard location for system service configuration
- Separated from application code (`/opt/docling-mcp/`)
- Accessible to systemd service (no permission issues)
- Easy to backup/restore independently
- Follows Linux FHS (Filesystem Hierarchy Standard)

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Lines 959-976: Environment Variables)
- **Task 141**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-141-create-pydantic-settings-module.md`
- **Pydantic Settings**: https://docs.pydantic.dev/latest/concepts/pydantic_settings/
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 10)

## Risk Assessment

**Risk**: Low
- Standard environment file creation
- No impact on existing services
- Easily reversible (delete file)
- Validation prevents misconfiguration

**Mitigation**:
- Pre-execution validation checks for existing file
- Permissions restrict access (640)
- Template file documents all options
- Pydantic validation catches errors at startup
