# Task 145: Document Configuration Management

**Assigned To**: paul-warfield
**Estimated Effort**: 1.0 hours
**Dependencies**: Task 141-144 (All configuration tasks)
**Status**: Not Started

## Objective

Create comprehensive documentation for configuration management covering environment variables, Pydantic settings schema, configuration file structure, secrets management, and operational procedures for configuration updates and troubleshooting.

## Pre-Execution Validation

**CRITICAL**: Check if configuration documentation already exists BEFORE creating it.

```bash
# Check if configuration documentation exists
if [ -f "/opt/docling-mcp/docs/configuration.md" ]; then
    echo "✅ VALIDATION RESULT: Configuration documentation already exists"
    echo "ACTION: SKIP task execution - validate existing documentation"

    # Verify documentation contains required sections
    grep -q "Environment Variables" /opt/docling-mcp/docs/configuration.md && \
    grep -q "Pydantic Settings" /opt/docling-mcp/docs/configuration.md && \
    grep -q "Secrets Management" /opt/docling-mcp/docs/configuration.md

    if [ $? -eq 0 ]; then
        echo "✅ Documentation contains required sections - task complete"
        exit 0
    else
        echo "⚠️ Documentation exists but missing sections - may need updating"
        exit 1
    fi
else
    echo "❌ VALIDATION RESULT: Configuration documentation does NOT exist"
    echo "ACTION: PROCEED with documentation creation"
fi
```

**If Documentation Exists with Required Sections**: Skip to Validation section
**If Documentation Does Not Exist**: Continue with Implementation Steps below

---

## Context

Configuration documentation provides operational guidance for:
- Understanding environment variable naming and structure
- Customizing configuration for different deployments
- Managing secrets via Ansible Vault
- Troubleshooting configuration validation errors
- Updating configuration without downtime
- Monitoring configuration health

This documentation is essential for:
- Operators deploying the service
- Developers modifying configuration schema
- SREs troubleshooting configuration issues
- Security team auditing secrets management

## Acceptance Criteria

- [ ] Documentation directory created at `/opt/docling-mcp/docs/`
- [ ] Configuration documentation file: `configuration.md`
- [ ] Environment variables reference table with descriptions
- [ ] Pydantic settings schema documentation
- [ ] Configuration file structure and location
- [ ] Secrets management procedures (Ansible Vault integration)
- [ ] Configuration validation examples
- [ ] Troubleshooting guide for common configuration errors
- [ ] Operational procedures for configuration updates
- [ ] Examples for all configuration scenarios
- [ ] Cross-references to related documentation

## Implementation Steps

### Step 1: Create Documentation Directory

```bash
# SSH to target server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create docs directory
sudo mkdir -p /opt/docling-mcp/docs

# Set ownership to service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/docs

# Verify directory created
ls -la /opt/docling-mcp/docs/
```

### Step 2: Create Configuration Documentation

```bash
# Create comprehensive configuration documentation
sudo tee /opt/docling-mcp/docs/configuration.md > /dev/null << 'EOF'
# Docling MCP Server Configuration Management

**Version**: 1.0.0
**Last Updated**: 2025-12-01
**Maintainer**: paul-warfield (Pydantic SME)

---

## Table of Contents

1. [Overview](#overview)
2. [Environment Variables Reference](#environment-variables-reference)
3. [Pydantic Settings Schema](#pydantic-settings-schema)
4. [Configuration Files](#configuration-files)
5. [Secrets Management](#secrets-management)
6. [Configuration Validation](#configuration-validation)
7. [Operational Procedures](#operational-procedures)
8. [Troubleshooting](#troubleshooting)
9. [Examples](#examples)

---

## Overview

### Configuration Loading

Docling MCP Server uses **Pydantic V2 BaseSettings** for configuration management with automatic validation. Configuration is loaded from multiple sources in this priority order (highest to lowest):

1. **System Environment Variables** (set in systemd service or shell)
2. **Environment File** (`/etc/docling-mcp/env/.env`)
3. **Default Values** (defined in Pydantic Field() definitions)

### Configuration Architecture

```
DoclingMCPConfig (Master Configuration)
├── RedisSettings (Connection pool, sessions)
├── SessionSettings (TTL configuration)
├── CacheSettings (Performance optimization)
├── QdrantSettings (Vector database)
├── LLMSettings (LiteLLM & LightRAG)
├── ProcessingSettings (Document processing)
└── MCPServerSettings (Transport, logging)
```

### Key Features

- **Type Safety**: Automatic type coercion (string → int, bool)
- **Validation**: Field constraints, cross-field validation
- **Fail Fast**: Invalid configuration prevents service startup
- **Sanitized Logging**: Secrets never logged
- **Environment Override**: System env vars override .env file

---

## Environment Variables Reference

### Redis Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `REDIS_HOST` | string | `hx-redis-server.hx.dev.local` | hostname | Redis server hostname |
| `REDIS_PORT` | int | `6379` | 1-65535 | Redis server port |
| `REDIS_PASSWORD` | string | `None` | - | Redis auth password (optional) |
| `REDIS_CONNECTION_POOL_SIZE` | int | `10` | 1-100 | Max connection pool size |
| `REDIS_CONNECTION_TIMEOUT_SECONDS` | int | `5` | 1-30 | Connection timeout |
| `REDIS_OPERATION_TIMEOUT_SECONDS` | int | `10` | 1-60 | Read/write timeout |
| `REDIS_RETRY_ATTEMPTS` | int | `3` | 0-10 | Retry attempts |
| `REDIS_HEALTH_CHECK_INTERVAL_SECONDS` | int | `30` | 5-300 | Health check interval |

### Session Management Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `SESSION_TTL_HOURS` | int | `24` | 1-168 | Session TTL (max 7 days) |
| `SESSION_TTL_EXTENSION_HOURS` | int | `4` | 1-48 | TTL extension increment |

**Validation Rule**: `SESSION_TTL_EXTENSION_HOURS` must be ≤ `SESSION_TTL_HOURS`

### Cache Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `CACHE_ENABLED` | bool | `true` | true/false | Enable Redis caching |
| `CACHE_TTL_HOURS` | int | `24` | 1-168 | Default cache TTL |
| `CACHE_MAX_DOCUMENT_SIZE_MB` | int | `5` | 1-100 | Max cached document size |
| `CACHE_METADATA_TTL_HOURS` | int | `168` | 1-720 | Metadata cache TTL (7 days) |
| `CACHE_ENTITY_TTL_HOURS` | int | `24` | 1-168 | Entity extraction cache TTL |
| `CACHE_DOCLING_TTL_HOURS` | int | `24` | 1-168 | DoclingDocument cache TTL |

### Qdrant Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `QDRANT_HOST` | string | `hx-qdrant-server.hx.dev.local` | hostname | Qdrant server hostname |
| `QDRANT_PORT` | int | `6333` | 1-65535 | Qdrant HTTP API port |
| `QDRANT_API_KEY` | string | `None` | - | Qdrant API key (optional) |
| `QDRANT_CONNECTION_POOL_MAX` | int | `10` | 1-50 | HTTP connection pool size |
| `QDRANT_KEEPALIVE_SECONDS` | int | `60` | 10-300 | Connection keep-alive timeout |
| `QDRANT_RETRY_ATTEMPTS` | int | `3` | 0-10 | Retry attempts |

### LLM Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `LLM_LITELLM_API_BASE` | HttpUrl | `http://hx-litellm-server.hx.dev.local:4000` | URL | LiteLLM gateway base URL |
| `LLM_LIGHTRAG_API_URL` | HttpUrl | `http://hx-literag-server.hx.dev.local:8000` | URL | LightRAG server API URL |
| `LLM_ENTITY_EXTRACTION_MODEL` | string | `gemma3:27b` | pattern: `^[a-z0-9:-]+$` | LLM model for entity extraction |
| `LLM_TEMPERATURE` | float | `0.1` | 0.0-2.0 | LLM sampling temperature |
| `LLM_MAX_TOKENS` | int | `2048` | 128-8192 | Max LLM response tokens |
| `LLM_TIMEOUT_SECONDS` | int | `60` | 10-300 | LLM API request timeout |

**Model Pattern**: Lowercase alphanumeric with hyphens/colons only

### Processing Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `PROCESSING_DOCUMENT_MAX_SIZE_MB` | int | `500` | 1-2000 | Max document size |
| `PROCESSING_CONCURRENT_WORKERS` | int | `4` | 1-20 | Concurrent processing workers |
| `PROCESSING_DOCLING_CACHE_DIR` | Path | `/var/lib/docling-mcp/cache` | absolute path | Document cache directory |

**Validation Rule**: `PROCESSING_DOCLING_CACHE_DIR` must be absolute path

### MCP Server Configuration

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `MCP_HTTP_PORT` | int | `8000` | 1024-65535 | MCP HTTP listen port |
| `MCP_SSE_ENABLED` | bool | `true` | true/false | Enable SSE transport |
| `MCP_STDIO_ENABLED` | bool | `true` | true/false | Enable stdio transport |
| `MCP_LOG_LEVEL` | Literal | `INFO` | DEBUG/INFO/WARN/ERROR | Logging verbosity |
| `MCP_LOG_FORMAT` | Literal | `json` | json/text | Log output format |

---

## Pydantic Settings Schema

### Module Location

**Source Code**: `/opt/docling-mcp/src/config/settings.py`

### Configuration Classes

#### DoclingMCPConfig (Master)

```python
from src.config.settings import DoclingMCPConfig

config = DoclingMCPConfig.load_config()

# Access nested settings
redis = config.redis
qdrant = config.qdrant
llm = config.llm
```

#### Nested Settings Classes

```python
# Redis settings
config.redis.host              # "hx-redis-server.hx.dev.local"
config.redis.port              # 6379
config.redis.connection_pool_size  # 10

# Session settings
config.session.ttl_hours       # 24
config.session.ttl_extension_hours  # 4

# Cache settings
config.cache.enabled           # True
config.cache.ttl_hours         # 24

# Qdrant settings
config.qdrant.host            # "hx-qdrant-server.hx.dev.local"
config.qdrant.port            # 6333

# LLM settings
config.llm.litellm_api_base   # HttpUrl("http://hx-litellm-server...")
config.llm.entity_extraction_model  # "gemma3:27b"

# Processing settings
config.processing.document_max_size_mb  # 500
config.processing.concurrent_workers    # 4

# MCP server settings
config.mcp.http_port          # 8000
config.mcp.log_level          # "INFO"
```

### Validation Features

**Field Validators**:
- `SessionSettings.ttl_extension_hours`: Must be ≤ `ttl_hours`
- `ProcessingSettings.docling_cache_dir`: Must be absolute path
- `ProcessingSettings.concurrent_workers`: Warning if > 10

**Type Validation**:
- Port numbers: 1-65535 range
- URLs: Valid HTTP/HTTPS format
- Model names: Pattern `^[a-z0-9:-]+$`
- Log levels: Literal["DEBUG", "INFO", "WARN", "ERROR"]

---

## Configuration Files

### Primary Configuration File

**Location**: `/etc/docling-mcp/env/.env`

**Ownership**: `docling-mcp@hx.dev.local:domain users@hx.dev.local`

**Permissions**: `640` (owner read/write, group read, no world access)

**Format**: `KEY=VALUE` pairs, one per line

**Example**:
```env
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
SESSION_TTL_HOURS=24
CACHE_ENABLED=true
MCP_HTTP_PORT=8000
MCP_LOG_LEVEL=INFO
```

**Important**: DO NOT commit `.env` file to git (add to `.gitignore`)

### Template File

**Location**: `/etc/docling-mcp/env/.env.template`

**Purpose**: Documentation and deployment reference (safe to commit)

**Usage**:
```bash
# Copy template to .env
cp /etc/docling-mcp/env/.env.template /etc/docling-mcp/env/.env

# Customize values
nano /etc/docling-mcp/env/.env
```

---

## Secrets Management

### Ansible Vault Integration

**Secrets Stored in Ansible Vault**:
- `REDIS_PASSWORD` (if Redis authentication enabled)
- `QDRANT_API_KEY` (if Qdrant authentication enabled)
- Any future API keys or credentials

**Vault Locations**:
```
/etc/ansible/vaults/
├── hx-docling-mcp-server-credentials.yml  # Encrypted
└── hx-docling-mcp-server-credentials-decrypted.env  # Runtime only
```

### Runtime Injection

**Systemd Service Configuration**:
```ini
[Service]
EnvironmentFile=/etc/docling-mcp/env/.env
EnvironmentFile=/etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env
```

**Decryption Procedure** (manual - run before service start):
```bash
# Decrypt Ansible Vault to temporary .env file
ansible-vault decrypt \
  /etc/ansible/vaults/hx-docling-mcp-server-credentials.yml \
  --output=/etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env \
  --vault-password-file=/etc/ansible/.vault_pass

# Set restrictive permissions
chmod 600 /etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env

# Start service (systemd loads decrypted secrets)
sudo systemctl start docling-mcp.service
```

### Security Best Practices

**DO**:
- Store secrets in Ansible Vault (encrypted)
- Use restrictive file permissions (600/640)
- Rotate secrets every 90 days
- Audit secret access logs

**DON'T**:
- Commit secrets to git
- Log secrets (Pydantic sanitizes automatically)
- Store secrets in plain text .env file
- Share secrets via insecure channels

---

## Configuration Validation

### Startup Validation

Configuration validation happens **automatically at service startup**:

```python
# In mcp_server.py
config = DoclingMCPConfig.load_config()
# If validation fails, service exits with code 1
```

**Validation Checks**:
1. Required environment variables present
2. Type validation (string → int, bool)
3. Field constraints (ranges, patterns)
4. Cross-field validation (TTL extension ≤ TTL)
5. URL format validation (HttpUrl)

### Manual Validation

**Test configuration without starting service**:
```bash
cd /opt/docling-mcp
source venv/bin/activate

python3 << 'EOF'
from src.config.settings import DoclingMCPConfig

try:
    config = DoclingMCPConfig.load_config()
    print("✅ Configuration valid")
    print(f"Redis: {config.redis.host}:{config.redis.port}")
    print(f"MCP Port: {config.mcp.http_port}")
except Exception as e:
    print(f"❌ Configuration validation failed: {e}")
EOF

deactivate
```

### Validation Error Examples

**Port out of range**:
```
ValidationError: 1 validation error for RedisSettings
port
  Input should be less than or equal to 65535 [type=less_than_equal, input_value=70000]
```

**Invalid model name**:
```
ValidationError: 1 validation error for LLMSettings
entity_extraction_model
  String should match pattern '^[a-z0-9:-]+$' [type=string_pattern_mismatch, input_value='GPT-4']
```

**TTL extension exceeds TTL**:
```
ValidationError: 1 validation error for SessionSettings
ttl_extension_hours
  ttl_extension_hours (20) cannot exceed ttl_hours (10) [type=value_error]
```

---

## Operational Procedures

### Update Configuration (No Downtime)

**Procedure**:
```bash
# 1. Edit .env file
sudo nano /etc/docling-mcp/env/.env

# 2. Validate configuration (don't start service yet)
cd /opt/docling-mcp
source venv/bin/activate
python3 -c "from src.config.settings import DoclingMCPConfig; DoclingMCPConfig.load_config(); print('Valid')"
deactivate

# 3. Restart service (if validation passed)
sudo systemctl restart docling-mcp.service

# 4. Verify service started successfully
sudo systemctl status docling-mcp.service

# 5. Check logs for configuration summary
sudo journalctl -u docling-mcp.service -n 50 --no-pager
```

### Override Configuration Temporarily

**For testing/debugging** (does not persist):
```bash
# Stop service
sudo systemctl stop docling-mcp.service

# Start with environment override
sudo MCP_LOG_LEVEL=DEBUG MCP_HTTP_PORT=9000 systemctl start docling-mcp.service

# Restart to revert to .env configuration
sudo systemctl restart docling-mcp.service
```

### View Current Configuration

```bash
# From health check endpoint
curl -s http://hx-docling-mcp-server.hx.dev.local:8000/health | jq '.configuration'

# Expected output:
# {
#   "cache_enabled": true,
#   "concurrent_workers": 4,
#   "log_level": "INFO"
# }
```

---

## Troubleshooting

### Service Won't Start

**Symptom**: `systemctl status docling-mcp.service` shows failed state

**Diagnosis**:
```bash
# Check logs for configuration validation errors
sudo journalctl -u docling-mcp.service -n 50 --no-pager | grep -i "validation\|error"
```

**Common Causes**:
1. Invalid environment variable value (out of range, wrong type)
2. Missing .env file
3. Syntax error in .env file (missing quotes, invalid format)
4. Cross-field validation failure (TTL extension > TTL)

**Solution**:
```bash
# Validate configuration manually
cd /opt/docling-mcp
source venv/bin/activate
python3 -c "from src.config.settings import DoclingMCPConfig; DoclingMCPConfig.load_config()"
# Read error message, fix .env file, retry
```

### Configuration Changes Not Taking Effect

**Symptom**: Updated .env file but service behavior unchanged

**Diagnosis**:
```bash
# Check if systemd environment override exists
systemctl show docling-mcp.service | grep Environment
```

**Cause**: System environment variables override .env file

**Solution**:
```bash
# Remove systemd environment overrides
sudo systemctl edit docling-mcp.service --drop-in=override
# Delete [Service] Environment=... lines
sudo systemctl daemon-reload
sudo systemctl restart docling-mcp.service
```

### Secrets Not Loading

**Symptom**: Service starts but Redis/Qdrant authentication fails

**Diagnosis**:
```bash
# Check if decrypted secrets file exists
ls -la /etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env

# Verify systemd loads secrets file
systemctl show docling-mcp.service | grep EnvironmentFile
```

**Solution**:
```bash
# Decrypt Ansible Vault secrets
ansible-vault decrypt \
  /etc/ansible/vaults/hx-docling-mcp-server-credentials.yml \
  --output=/etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env

chmod 600 /etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env

# Restart service
sudo systemctl restart docling-mcp.service
```

---

## Examples

### Example 1: Development Configuration

```env
# /etc/docling-mcp/env/.env (development)

# Verbose logging for debugging
MCP_LOG_LEVEL=DEBUG
MCP_LOG_FORMAT=text

# Disable caching for testing
CACHE_ENABLED=false

# Lower limits for local testing
PROCESSING_DOCUMENT_MAX_SIZE_MB=100
PROCESSING_CONCURRENT_WORKERS=2

# Local dependencies
REDIS_HOST=localhost
QDRANT_HOST=localhost
```

### Example 2: Production Configuration

```env
# /etc/docling-mcp/env/.env (production)

# Production logging
MCP_LOG_LEVEL=INFO
MCP_LOG_FORMAT=json

# Enable caching for performance
CACHE_ENABLED=true
CACHE_TTL_HOURS=24

# Production limits
PROCESSING_DOCUMENT_MAX_SIZE_MB=500
PROCESSING_CONCURRENT_WORKERS=8

# Production dependencies (hostname-based)
REDIS_HOST=hx-redis-server.hx.dev.local
QDRANT_HOST=hx-qdrant-server.hx.dev.local
LLM_LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000
LLM_LIGHTRAG_API_URL=http://hx-literag-server.hx.dev.local:8000
```

### Example 3: High-Volume Configuration

```env
# /etc/docling-mcp/env/.env (high-volume processing)

# Increased connection pools
REDIS_CONNECTION_POOL_SIZE=50
QDRANT_CONNECTION_POOL_MAX=30

# Increased concurrency
PROCESSING_CONCURRENT_WORKERS=16

# Increased timeouts
REDIS_OPERATION_TIMEOUT_SECONDS=30
LLM_TIMEOUT_SECONDS=120

# Extended cache TTLs
CACHE_METADATA_TTL_HOURS=720  # 30 days
CACHE_ENTITY_TTL_HOURS=168    # 7 days
```

---

## Related Documentation

- **Pydantic Settings Module**: `/opt/docling-mcp/src/config/settings.py`
- **Environment File Template**: `/etc/docling-mcp/env/.env.template`
- **Systemd Service**: `/etc/systemd/system/docling-mcp.service`
- **Ansible Vault**: `/etc/ansible/vaults/`
- **HX-Infrastructure Standards**: `/home/agent0/HX-Infrastructure/standards/`

---

**Document Version**: 1.0.0
**Maintainer**: paul-warfield (Pydantic SME)
**Last Review**: 2025-12-01
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/docs/configuration.md

# Set permissions (644 - readable by all)
sudo chmod 644 /opt/docling-mcp/docs/configuration.md
```

## Validation

**Validation Commands:**

```bash
# Test 1: Verify documentation file exists
test -f /opt/docling-mcp/docs/configuration.md && echo "PASS: Documentation file exists" || echo "FAIL: Documentation missing"

# Test 2: Verify documentation contains all required sections
for section in "Environment Variables" "Pydantic Settings" "Configuration Files" "Secrets Management" "Troubleshooting"; do
    grep -q "$section" /opt/docling-mcp/docs/configuration.md && echo "PASS: Section '$section' found" || echo "FAIL: Section '$section' missing"
done

# Test 3: Verify environment variable reference table exists
grep -q "| Variable | Type | Default |" /opt/docling-mcp/docs/configuration.md && echo "PASS: Environment variable table found" || echo "FAIL: Table missing"

# Test 4: Verify examples section exists
grep -q "Example 1: Development Configuration" /opt/docling-mcp/docs/configuration.md && echo "PASS: Examples found" || echo "FAIL: Examples missing"

# Test 5: Verify operational procedures documented
grep -q "Update Configuration (No Downtime)" /opt/docling-mcp/docs/configuration.md && echo "PASS: Operational procedures found" || echo "FAIL: Procedures missing"

# Test 6: Verify file ownership correct
ls -la /opt/docling-mcp/docs/configuration.md | grep "docling-mcp@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# Test 7: Verify file is readable
test -r /opt/docling-mcp/docs/configuration.md && echo "PASS: Documentation readable" || echo "FAIL: Documentation not readable"
```

**Expected Outcomes:**
- All 7 validation tests return "PASS"
- Documentation file exists and is readable
- All required sections present
- Environment variable reference table included
- Examples and troubleshooting guides complete
- Proper ownership and permissions

## Notes

### Documentation Structure

**Comprehensive Coverage:**
- Reference documentation (environment variables, schema)
- Operational procedures (configuration updates, validation)
- Troubleshooting guides (common errors, solutions)
- Examples (development, production, high-volume)

**Target Audiences:**
- **Operators**: Deployment and operational procedures
- **Developers**: Schema reference and integration patterns
- **SREs**: Troubleshooting and monitoring
- **Security**: Secrets management and best practices

### Markdown Format Benefits

**Why Markdown:**
- Human-readable plain text
- Renderable in web browsers, IDE viewers
- Version control friendly (git diff works well)
- Easy to maintain and update
- Supports tables, code blocks, links

### Living Documentation

**Update Triggers:**
- Configuration schema changes (add/remove fields)
- Validation rule changes
- Operational procedure updates
- Troubleshooting knowledge capture

**Maintenance Responsibility**: paul-warfield (Pydantic SME)

### Cross-References

Documentation links to:
- Source code (`/opt/docling-mcp/src/config/settings.py`)
- Configuration files (`/etc/docling-mcp/env/.env`)
- Systemd service (`/etc/systemd/system/docling-mcp.service`)
- Related HX-Infrastructure standards

This provides complete traceability from documentation to implementation.

## References

- **Task 141**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-141-create-pydantic-settings-module.md`
- **Task 142**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-142-create-environment-file.md`
- **Task 143**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-143-implement-configuration-validation-tests.md`
- **Task 144**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-144-integrate-config-with-mcp-server.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`

## Risk Assessment

**Risk**: Low
- Documentation-only task (no code changes)
- No impact on operational services
- Easily updatable if errors found

**Mitigation**:
- Comprehensive coverage of all configuration aspects
- Examples for common scenarios
- Troubleshooting section for common issues
- Cross-references for complete context
