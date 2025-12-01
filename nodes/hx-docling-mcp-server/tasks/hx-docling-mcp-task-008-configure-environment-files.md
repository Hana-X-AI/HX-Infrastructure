# Task 008: Configure Environment Files

**Task ID**: hx-docling-mcp-task-008
**Category**: Configuration / Environment Setup
**Assigned To**: william-chen (Infrastructure Specialist)
**Status**: PENDING
**Priority**: HIGH (Blocker for deployment)
**Created**: 2025-11-27
**Estimated Effort**: 30 minutes

---

## Task Description

Create and configure environment files (`.env`) for Docling MCP Server with all required configuration parameters for service operation, external service integration (LiteLLM, Qdrant, Redis), and MCP protocol configuration. All sensitive credentials will be stored in Ansible Vault with references in the `.env` file.

---

## Prerequisites

- [ ] Task 002 complete (Samba AD service account created with credentials in Ansible Vault)
- [ ] Task 003 complete (System dependencies installed)
- [ ] Task 004 complete (Python virtual environment created)
- [ ] Task 005 complete (Python dependencies installed)
- [ ] Task 006 complete (Directory structure created: `/etc/docling-mcp`)
- [ ] Task 007 complete (Application code installed)
- [ ] Ansible Vault credentials file exists: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml`
- [ ] External service endpoints accessible (LiteLLM, Qdrant, Redis)

---

## Acceptance Criteria

- [ ] Main `.env` file created at `/etc/docling-mcp/.env`
- [ ] `.env.template` file created with placeholder values for documentation
- [ ] All required environment variables configured
- [ ] Credentials loaded from Ansible Vault (NO plain text credentials in `.env`)
- [ ] File ownership set to root (config files must be protected)
- [ ] File permissions set to 640 (owner read/write, group read, no world access)
- [ ] Environment file validation script passes all checks
- [ ] Configuration documentation generated

---

## Detailed Procedure

### Step 1: Review Ansible Vault Credentials

```bash
# Connect to hx-docling-mcp-server
ssh administrator@192.168.10.217

# Verify Ansible Vault file exists
ls -la /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
# Expected: Encrypted file exists

# View Ansible Vault contents (to extract credentials for .env)
ansible-vault view \
  /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml \
  --vault-password-file /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password

# Expected output:
# ---
# samba_account: "docling-mcp@hx.dev.local"
# samba_password: "[SEE VAULT: vault/credentials.yml]"
# litellm_api_key: "<api_key_value>"
# redis_password: "<redis_password_if_enabled>"
# mcp_api_keys: [...]
```

### Step 2: Create Environment File Template

**Create `.env.template` for documentation (NO sensitive values)**:

```bash
# Create template file
sudo tee /etc/docling-mcp/.env.template > /dev/null <<'EOF'
# Docling MCP Server Environment Configuration Template
# This is a TEMPLATE file - copy to .env and replace placeholders
# NEVER commit .env to git - contains sensitive credentials
# Created: 2025-11-27

# ===== Service Configuration =====
SERVICE_NAME=docling-mcp
SERVICE_HOST=192.168.10.217
SERVICE_PORT=8000
SERVICE_HTTPS_PORT=8443
ENVIRONMENT=production

# ===== MCP Protocol Configuration =====
MCP_TRANSPORTS=http,sse,stdio
MCP_HTTP_ENABLED=true
MCP_SSE_ENABLED=true
MCP_STDIO_ENABLED=true

# ===== Python Environment =====
LOG_LEVEL=INFO
DEBUG=false
PYTHONUNBUFFERED=1

# ===== LiteLLM Gateway Integration =====
LITELLM_BASE_URL=http://192.168.10.212:4000
LITELLM_API_KEY=<from_ansible_vault>
LITELLM_TIMEOUT=120

# LLM Model Routing
LITELLM_ENTITY_EXTRACTION_MODEL=ollama/gemma3:27b
LITELLM_FALLBACK_MODEL=ollama/gpt-oss:20b
LITELLM_DOCLING_MODEL=ollama/granite-docling:258m

# ===== Qdrant Vector Database =====
QDRANT_HOST=192.168.10.207
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334
QDRANT_COLLECTION_PREFIX=docling_mcp_
QDRANT_TIMEOUT=60

# ===== Redis Session Management =====
REDIS_HOST=192.168.10.210
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=<from_ansible_vault_if_auth_enabled>
REDIS_SESSION_TTL=3600
REDIS_POOL_SIZE=10

# ===== Docling Configuration =====
DOCLING_CACHE_DIR=/var/lib/docling-mcp/cache
DOCLING_WORKING_DIR=/var/lib/docling-mcp/workspace
DOCLING_MAX_FILE_SIZE_MB=100
DOCLING_SUPPORTED_FORMATS=pdf,docx,pptx,xlsx,html,png,jpg

# ===== LightRAG Knowledge Graph =====
LIGHTRAG_WORKING_DIR=/var/lib/docling-mcp/lightrag
LIGHTRAG_STORAGE_BACKEND=qdrant
LIGHTRAG_ENTITY_EXTRACTION_LLM=litellm/ollama/gemma3:27b
LIGHTRAG_MIN_ENTITY_LENGTH=3
LIGHTRAG_MAX_ENTITIES_PER_DOC=500

# ===== Logging Configuration =====
LOG_FILE=/var/log/docling-mcp/docling-mcp.log
ERROR_LOG_FILE=/var/log/docling-mcp/error.log
ACCESS_LOG_FILE=/var/log/docling-mcp/access.log
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=30
LOG_FORMAT=json
EOF

# Set ownership to root (config files protected)
sudo chown root:root /etc/docling-mcp/.env.template

# Set permissions (644 - world readable template)
sudo chmod 644 /etc/docling-mcp/.env.template

# Verify template created
cat /etc/docling-mcp/.env.template
```

### Step 3: Create Production Environment File

**Create `.env` with actual values from Ansible Vault**:

```bash
# Extract credentials from Ansible Vault using robust Python YAML parser
VAULT_FILE="/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml"
VAULT_PASS="/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password"

# Extract with Python YAML parser (handles spaces, quotes, special chars)
SAMBA_PASSWORD=$(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS" 2>/dev/null | \
  python3 -c "import sys, yaml; data = yaml.safe_load(sys.stdin); print(data.get('samba_password', ''))")

LITELLM_API_KEY=$(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS" 2>/dev/null | \
  python3 -c "import sys, yaml; data = yaml.safe_load(sys.stdin); print(data.get('litellm_api_key', ''))")

REDIS_PASSWORD=$(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS" 2>/dev/null | \
  python3 -c "import sys, yaml; data = yaml.safe_load(sys.stdin); print(data.get('redis_password', ''))")

# Validation: Ensure critical credentials extracted successfully
if [ -z "$SAMBA_PASSWORD" ]; then
    echo "ERROR: Failed to extract samba_password from vault at $VAULT_FILE"
    echo "Verify vault file exists and contains 'samba_password' key"
    exit 1
fi

if [ -z "$LITELLM_API_KEY" ]; then
    echo "WARNING: litellm_api_key not found in vault (may be optional)"
fi

if [ -z "$REDIS_PASSWORD" ]; then
    echo "WARNING: redis_password not found in vault (may be optional)"
fi

# Create production .env file
sudo tee /etc/docling-mcp/.env > /dev/null <<EOF
# Docling MCP Server Environment Configuration
# Generated: $(date)
# Node: hx-docling-mcp-server (192.168.10.217)
# WARNING: Contains sensitive credentials - DO NOT commit to git

# ===== Service Configuration =====
SERVICE_NAME=docling-mcp
SERVICE_HOST=192.168.10.217
SERVICE_PORT=8000
SERVICE_HTTPS_PORT=8443
ENVIRONMENT=production

# ===== MCP Protocol Configuration =====
MCP_TRANSPORTS=http,sse,stdio
MCP_HTTP_ENABLED=true
MCP_SSE_ENABLED=true
MCP_STDIO_ENABLED=true

# ===== Python Environment =====
LOG_LEVEL=INFO
DEBUG=false
PYTHONUNBUFFERED=1

# ===== LiteLLM Gateway Integration =====
LITELLM_BASE_URL=http://192.168.10.212:4000
LITELLM_API_KEY=${LITELLM_API_KEY:-}
LITELLM_TIMEOUT=120

# LLM Model Routing
LITELLM_ENTITY_EXTRACTION_MODEL=ollama/gemma3:27b
LITELLM_FALLBACK_MODEL=ollama/gpt-oss:20b
LITELLM_DOCLING_MODEL=ollama/granite-docling:258m

# ===== Qdrant Vector Database =====
QDRANT_HOST=192.168.10.207
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334
QDRANT_COLLECTION_PREFIX=docling_mcp_
QDRANT_TIMEOUT=60

# ===== Redis Session Management =====
REDIS_HOST=192.168.10.210
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=${REDIS_PASSWORD:-}
REDIS_SESSION_TTL=3600
REDIS_POOL_SIZE=10

# ===== Docling Configuration =====
DOCLING_CACHE_DIR=/var/lib/docling-mcp/cache
DOCLING_WORKING_DIR=/var/lib/docling-mcp/workspace
DOCLING_MAX_FILE_SIZE_MB=100
DOCLING_SUPPORTED_FORMATS=pdf,docx,pptx,xlsx,html,png,jpg

# ===== LightRAG Knowledge Graph =====
LIGHTRAG_WORKING_DIR=/var/lib/docling-mcp/lightrag
LIGHTRAG_STORAGE_BACKEND=qdrant
LIGHTRAG_ENTITY_EXTRACTION_LLM=litellm/ollama/gemma3:27b
LIGHTRAG_MIN_ENTITY_LENGTH=3
LIGHTRAG_MAX_ENTITIES_PER_DOC=500

# ===== Logging Configuration =====
LOG_FILE=/var/log/docling-mcp/docling-mcp.log
ERROR_LOG_FILE=/var/log/docling-mcp/error.log
ACCESS_LOG_FILE=/var/log/docling-mcp/access.log
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=30
LOG_FORMAT=json
EOF

# Set ownership to root (only root and service can read)
sudo chown root:domain\ users@hx.dev.local /etc/docling-mcp/.env

# Set permissions (640 - owner read/write, group read, no world access)
sudo chmod 640 /etc/docling-mcp/.env

# Verify file created
ls -la /etc/docling-mcp/.env
# Expected: -rw-r----- root domain users@hx.dev.local .env
```

### Step 4: Verify Environment File Syntax

```bash
# Test .env file can be sourced
sudo bash -c 'set -a; source /etc/docling-mcp/.env; set +a; echo "✓ .env file syntax valid"'

# Verify critical variables set
sudo bash -c 'source /etc/docling-mcp/.env; test -n "$SERVICE_NAME" && echo "✓ SERVICE_NAME set" || echo "✗ SERVICE_NAME missing"'
sudo bash -c 'source /etc/docling-mcp/.env; test -n "$LITELLM_BASE_URL" && echo "✓ LITELLM_BASE_URL set" || echo "✗ LITELLM_BASE_URL missing"'
sudo bash -c 'source /etc/docling-mcp/.env; test -n "$QDRANT_HOST" && echo "✓ QDRANT_HOST set" || echo "✗ QDRANT_HOST missing"'
sudo bash -c 'source /etc/docling-mcp/.env; test -n "$REDIS_HOST" && echo "✓ REDIS_HOST set" || echo "✗ REDIS_HOST missing"'

# Count environment variables
sudo bash -c 'source /etc/docling-mcp/.env; env | grep -E "(SERVICE_|MCP_|LITELLM_|QDRANT_|REDIS_|DOCLING_|LIGHTRAG_|LOG_)" | wc -l'
# Expected: 30+ environment variables
```

### Step 5: Create Environment Validation Script

```bash
# Create validation script
sudo tee /opt/docling-mcp/scripts/validate-environment.sh > /dev/null <<'EOF'
#!/bin/bash
# Environment Configuration Validation Script

set -e

echo "===== Environment Configuration Validation ====="
echo ""

ENV_FILE="/etc/docling-mcp/.env"

# Check .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "✗ FAIL: .env file not found at $ENV_FILE"
    exit 1
fi
echo "✓ .env file exists"

# Check permissions
PERMS=$(stat -c '%a' "$ENV_FILE")
if [ "$PERMS" = "640" ]; then
    echo "✓ .env permissions correct (640)"
else
    echo "✗ WARNING: .env permissions incorrect (expected 640, got $PERMS)"
fi

# Load environment variables
set -a
source "$ENV_FILE"
set +a

echo ""
echo "===== Required Variables Check ====="
echo ""

# Function to check variable
check_var() {
    local var_name=$1
    local var_value=${!var_name}
    echo -n "Checking $var_name... "
    if [ -n "$var_value" ]; then
        echo "✓ SET"
    else
        echo "✗ NOT SET"
        return 1
    fi
}

# Check all required variables
check_var "SERVICE_NAME"
check_var "SERVICE_HOST"
check_var "SERVICE_PORT"
check_var "LITELLM_BASE_URL"
check_var "QDRANT_HOST"
check_var "QDRANT_PORT"
check_var "REDIS_HOST"
check_var "REDIS_PORT"
check_var "DOCLING_CACHE_DIR"
check_var "DOCLING_WORKING_DIR"
check_var "LIGHTRAG_WORKING_DIR"
check_var "LOG_FILE"

echo ""
echo "===== Path Validation ====="
echo ""

# Check directories exist
check_dir() {
    local dir=$1
    echo -n "Checking directory $dir... "
    if [ -d "$dir" ]; then
        echo "✓ EXISTS"
    else
        echo "✗ NOT FOUND"
        return 1
    fi
}

check_dir "$DOCLING_CACHE_DIR"
check_dir "$DOCLING_WORKING_DIR"
check_dir "$LIGHTRAG_WORKING_DIR"
check_dir "$(dirname $LOG_FILE)"

echo ""
echo "===== External Service Connectivity ====="
echo ""

# Check LiteLLM connectivity
echo -n "Checking LiteLLM Gateway... "
if curl -f -s -o /dev/null --max-time 5 "${LITELLM_BASE_URL}/health" 2>/dev/null; then
    echo "✓ REACHABLE"
else
    echo "✗ UNREACHABLE"
fi

# Check Qdrant connectivity
echo -n "Checking Qdrant... "
if curl -f -s -o /dev/null --max-time 5 "http://${QDRANT_HOST}:${QDRANT_PORT}/healthz" 2>/dev/null; then
    echo "✓ REACHABLE"
else
    echo "✗ UNREACHABLE"
fi

# Check Redis connectivity (basic TCP check)
echo -n "Checking Redis... "
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${REDIS_HOST}/${REDIS_PORT}" 2>/dev/null; then
    echo "✓ REACHABLE"
else
    echo "✗ UNREACHABLE"
fi

echo ""
echo "===== Validation Complete ====="
EOF

# Make script executable
sudo chmod 755 /opt/docling-mcp/scripts/validate-environment.sh

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/scripts/validate-environment.sh

# Run validation script
sudo /opt/docling-mcp/scripts/validate-environment.sh

# Verify script exit code
echo $?
# Expected: 0 (success)
```

### Step 6: Create Environment Documentation

```bash
# Create configuration documentation (WITHOUT sensitive values)
sudo tee /opt/docling-mcp/documentation/environment-config.txt > /dev/null <<EOF
Environment Configuration Documentation
=======================================

Configuration Date: $(date)
Node: hx-docling-mcp-server (192.168.10.217)

Environment Files:
-----------------
Production: /etc/docling-mcp/.env (640 permissions, contains credentials)
Template: /etc/docling-mcp/.env.template (644 permissions, documentation only)

Configuration Variables:
-----------------------
SERVICE_NAME: docling-mcp
SERVICE_HOST: 192.168.10.217
SERVICE_PORT: 8000
ENVIRONMENT: production

External Service Endpoints:
---------------------------
LiteLLM Gateway: http://192.168.10.212:4000
Qdrant Vector DB: http://192.168.10.207:6333
Redis Cache: redis://192.168.10.210:6379/0

LLM Model Configuration:
------------------------
Entity Extraction: ollama/gemma3:27b
Fallback Model: ollama/gpt-oss:20b
Docling Processing: ollama/granite-docling:258m

Directory Paths:
---------------
Docling Cache: /var/lib/docling-mcp/cache
Docling Workspace: /var/lib/docling-mcp/workspace
LightRAG Working Dir: /var/lib/docling-mcp/lightrag

Logging Configuration:
---------------------
Main Log: /var/log/docling-mcp/docling-mcp.log
Error Log: /var/log/docling-mcp/error.log
Access Log: /var/log/docling-mcp/access.log
Log Format: json
Max Log Size: 10MB
Backup Count: 30 days

Credential Management:
---------------------
All sensitive credentials stored in Ansible Vault:
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml

NO credentials stored in plain text in .env file.
Credentials loaded from Ansible Vault during configuration.

Configuration Last Updated: $(date)
Updated By: $(whoami)
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/documentation/environment-config.txt

# Display documentation
cat /opt/docling-mcp/documentation/environment-config.txt
```

---

## Validation

### Validation Commands

```bash
# 1. Verify .env file exists
test -f /etc/docling-mcp/.env && echo "PASS: .env exists" || echo "FAIL: .env missing"

# 2. Verify .env.template exists
test -f /etc/docling-mcp/.env.template && echo "PASS: template exists" || echo "FAIL: template missing"

# 3. Verify .env permissions (640)
PERMS=$(stat -c '%a' /etc/docling-mcp/.env)
[ "$PERMS" = "640" ] && echo "PASS: permissions correct (640)" || echo "FAIL: permissions incorrect ($PERMS)"

# 4. Verify .env ownership (root)
OWNER=$(stat -c '%U' /etc/docling-mcp/.env)
[ "$OWNER" = "root" ] && echo "PASS: ownership correct (root)" || echo "FAIL: ownership incorrect ($OWNER)"

# 5. Verify .env syntax valid
sudo bash -c 'set -a; source /etc/docling-mcp/.env; set +a' && echo "PASS: syntax valid" || echo "FAIL: syntax error"

# 6. Verify critical variables set
sudo bash -c 'source /etc/docling-mcp/.env; [ -n "$SERVICE_NAME" ] && [ -n "$LITELLM_BASE_URL" ] && [ -n "$QDRANT_HOST" ]' && echo "PASS: critical vars set" || echo "FAIL: missing critical vars"

# 7. Verify validation script exists
test -x /opt/docling-mcp/scripts/validate-environment.sh && echo "PASS: validation script executable" || echo "FAIL: validation script missing"

# 8. Run comprehensive validation
sudo /opt/docling-mcp/scripts/validate-environment.sh && echo "PASS: all environment checks passed" || echo "FAIL: validation failed"
```

### Success Criteria

- ✅ `.env` file created at `/etc/docling-mcp/.env`
- ✅ `.env.template` file created for documentation
- ✅ All 30+ environment variables configured
- ✅ Credentials loaded from Ansible Vault (NO plain text)
- ✅ File ownership set to root
- ✅ File permissions set to 640
- ✅ .env file syntax valid (can be sourced)
- ✅ External service endpoints reachable
- ✅ All required directories exist
- ✅ Validation script passes all checks
- ✅ Documentation generated

---

## Troubleshooting

### Issue: Ansible Vault Decryption Fails

**Symptom**: `ERROR! Decryption failed`

**Solution**:
```bash
# Verify vault password file exists
ls -la /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password

# Verify vault password file permissions
chmod 600 /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password

# Test decryption
ansible-vault view \
  /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml \
  --vault-password-file /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password
```

### Issue: Environment Variable Not Set

**Symptom**: Variable empty when sourced

**Solution**:
```bash
# Check .env file syntax
cat /etc/docling-mcp/.env | grep <VARIABLE_NAME>

# Ensure no spaces around = sign
# CORRECT: VAR=value
# WRONG: VAR = value

# Edit .env file and fix syntax
sudo vim /etc/docling-mcp/.env
```

### Issue: External Service Unreachable

**Symptom**: Validation script shows service unreachable

**Solution**:
```bash
# Test connectivity manually
curl -v http://192.168.10.212:4000/health  # LiteLLM
curl -v http://192.168.10.207:6333/healthz  # Qdrant
redis-cli -h 192.168.10.210 ping  # Redis

# Check service status on target nodes
ssh administrator@192.168.10.212 systemctl status litellm
ssh administrator@192.168.10.207 systemctl status qdrant
ssh administrator@192.168.10.210 systemctl status redis

# Verify network connectivity
ping -c 3 192.168.10.212
ping -c 3 192.168.10.207
ping -c 3 192.168.10.210
```

### Issue: Permission Denied Reading .env

**Symptom**: `PermissionError: [Errno 13] Permission denied: '/etc/docling-mcp/.env'`

**Solution**:
```bash
# Service account must be in group that can read .env
# Verify service account group membership
id docling-mcp@hx.dev.local

# Ensure .env group is domain users
sudo chown root:domain\ users@hx.dev.local /etc/docling-mcp/.env

# Ensure permissions allow group read
sudo chmod 640 /etc/docling-mcp/.env
```

---

## Rollback Procedure

**If environment configuration needs to be reset**:

```bash
# Backup current .env file
sudo cp /etc/docling-mcp/.env /etc/docling-mcp/.env.backup.$(date +%Y%m%d-%H%M%S)

# Remove .env file
sudo rm /etc/docling-mcp/.env

# Remove .env.template
sudo rm /etc/docling-mcp/.env.template

# Remove validation script
sudo rm -f /opt/docling-mcp/scripts/validate-environment.sh

# Remove documentation
sudo rm -f /opt/docling-mcp/documentation/environment-config.txt

# If needed, recreate from Step 2 (using template)
```

---

## Dependencies

**Blocks**:
- Task 033: Configure Systemd Service (systemd needs .env file via EnvironmentFile directive)
- All application tasks (application requires configuration)
- All testing tasks (tests require configuration)

**Depends On**:
- Task 002: Create Samba AD Service Account (Ansible Vault credentials)
- Task 006: Create Directory Structure (`/etc/docling-mcp` directory)
- Task 007: Install Application Code (application must exist)

---

## Notes

### Security Best Practices

**Credential Management**:
- ✅ All sensitive credentials in Ansible Vault ONLY
- ✅ NO plain text credentials in .env file
- ✅ .env file permissions 640 (owner read/write, group read, no world)
- ✅ .env file owned by root (not service account)
- ✅ Service account in group that can read .env

**File Permissions**:
- `/etc/docling-mcp/.env`: 640 (root:domain users@hx.dev.local)
- `/etc/docling-mcp/.env.template`: 644 (world readable - no secrets)

### Environment Variable Categories

**Service Configuration** (5 variables):
- SERVICE_NAME, SERVICE_HOST, SERVICE_PORT, SERVICE_HTTPS_PORT, ENVIRONMENT

**MCP Protocol** (4 variables):
- MCP_TRANSPORTS, MCP_HTTP_ENABLED, MCP_SSE_ENABLED, MCP_STDIO_ENABLED

**LiteLLM Integration** (6 variables):
- LITELLM_BASE_URL, LITELLM_API_KEY, LITELLM_TIMEOUT, LITELLM_*_MODEL (3)

**Qdrant Integration** (5 variables):
- QDRANT_HOST, QDRANT_PORT, QDRANT_GRPC_PORT, QDRANT_COLLECTION_PREFIX, QDRANT_TIMEOUT

**Redis Integration** (6 variables):
- REDIS_HOST, REDIS_PORT, REDIS_DB, REDIS_PASSWORD, REDIS_SESSION_TTL, REDIS_POOL_SIZE

**Docling Configuration** (4 variables):
- DOCLING_CACHE_DIR, DOCLING_WORKING_DIR, DOCLING_MAX_FILE_SIZE_MB, DOCLING_SUPPORTED_FORMATS

**LightRAG Configuration** (5 variables):
- LIGHTRAG_WORKING_DIR, LIGHTRAG_STORAGE_BACKEND, LIGHTRAG_ENTITY_EXTRACTION_LLM, LIGHTRAG_MIN_ENTITY_LENGTH, LIGHTRAG_MAX_ENTITIES_PER_DOC

**Logging Configuration** (6 variables):
- LOG_FILE, ERROR_LOG_FILE, ACCESS_LOG_FILE, LOG_MAX_BYTES, LOG_BACKUP_COUNT, LOG_FORMAT, LOG_LEVEL

**Total**: 35+ environment variables

### HX-Infrastructure Standards Compliance

- ✅ **Ansible Vault for Credentials**: All secrets in vault, NOT in .env
- ✅ **Protected Configuration Files**: Root ownership, restricted permissions
- ✅ **Manual Procedures**: All commands documented for human execution
- ✅ **Documentation-First**: Template file for reference, documentation generated
- ✅ **Validation Scripts**: Comprehensive validation before service startup

---

## References

- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 008, Configuration Spec)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md` (Integration Points)
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Configuration)
- **Ansible Vault**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml`
- **Credentials Standard**: `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
