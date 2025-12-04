# Task 142: Configure Environment File

**Task ID**: hx-lang-server-task-142
**Phase**: Deployment (Service Configuration)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 141 (Systemd Service Unit), Task 003 (Directory Structure)
**Estimated Effort**: 45 minutes

---

## Objective

Create and configure the environment file (.env) for hx-lang-server with all required environment variables including service configuration, database connections, Ollama endpoints, and LightRAG integration settings.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 141 (Systemd Service Unit) completed
- [ ] Application directory /opt/hx-lang-server exists
- [ ] Credentials obtained from Ansible Vault (coordinate with Frank Lucas)

---

## Pre-Execution Validation

**CRITICAL**: Check if environment file already exists BEFORE creating.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check environment file status
ENV_FILE="/opt/hx-lang-server/.env"

echo "Checking environment file status..."

if [ -f "$ENV_FILE" ]; then
    echo "Environment file exists: $ENV_FILE"
    echo ""
    echo "Current environment variables (values redacted):"
    grep -E "^[A-Z_]+=" "$ENV_FILE" | sed 's/=.*/=***/' | head -20
    echo ""
    echo "VALIDATION RESULT: Environment file already exists"
    echo "ACTION: Review existing configuration, update if needed"
else
    echo "VALIDATION RESULT: Environment file does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Exists**: Review and update if needed
**If Not Exists**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Create Environment File

```bash
# Create environment file with template
ENV_FILE="/opt/hx-lang-server/.env"

echo "Creating environment file: $ENV_FILE"

sudo tee "$ENV_FILE" > /dev/null <<'EOF'
# hx-lang-server Environment Configuration
# Task: hx-lang-server-task-142
# Date: 2025-12-04
# Node: hx-lang-server.hx.dev.local (192.168.10.226)

# =============================================================================
# SERVICE CONFIGURATION
# =============================================================================
SERVICE_NAME=hx-lang-server
SERVICE_PORT=8100
HEALTH_PORT=8101
LOG_LEVEL=INFO
ENVIRONMENT=development

# =============================================================================
# POSTGRESQL CONFIGURATION (Checkpoint Persistence)
# =============================================================================
POSTGRES_HOST=hx-postgres-server.hx.dev.local
POSTGRES_PORT=5432
POSTGRES_DB=hx_lang_server
POSTGRES_USER=hx_lang_server
# POSTGRES_PASSWORD is retrieved from Ansible Vault
# Placeholder - replace with actual credential from vault
POSTGRES_PASSWORD=PLACEHOLDER_FROM_VAULT

# =============================================================================
# REDIS CONFIGURATION (Session Caching)
# =============================================================================
REDIS_URL=redis://hx-redis-server.hx.dev.local:6379/0
REDIS_MAX_CONNECTIONS=50
REDIS_SOCKET_TIMEOUT=5.0

# =============================================================================
# OLLAMA CONFIGURATION (LLM Integration)
# =============================================================================
# General LLM (queries, reasoning)
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b

# Code LLM (code generation, debugging)
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_CODE_MODEL=qwen3-coder:30b

# =============================================================================
# LIGHTRAG CONFIGURATION (RAG Pipeline)
# =============================================================================
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:8020
LIGHTRAG_TIMEOUT=60

# =============================================================================
# FASTMCP CONFIGURATION (MCP Gateway)
# =============================================================================
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000

# =============================================================================
# AGENT CONFIGURATION
# =============================================================================
MAX_RECURSION_DEPTH=25
CHECKPOINT_FREQUENCY=per_turn
SESSION_TTL_SECONDS=3600
QUERY_TIMEOUT_SECONDS=300
EOF

echo "Environment file template created"
```

### Step 2: Set File Ownership and Permissions

```bash
# Set secure ownership and permissions
ENV_FILE="/opt/hx-lang-server/.env"

echo "Setting environment file ownership and permissions..."

# Determine service account
if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
else
    SERVICE_USER="root"
fi

# Set ownership
sudo chown "$SERVICE_USER" "$ENV_FILE"

# Set permissions (owner read/write only - contains secrets)
sudo chmod 600 "$ENV_FILE"

# Verify
ls -la "$ENV_FILE"
echo "Environment file permissions set to 600 (owner read/write only)"
```

### Step 3: Retrieve Credentials from Ansible Vault

**IMPORTANT**: This step requires coordination with Frank Lucas (Security SME) to retrieve the actual PostgreSQL password from Ansible Vault.

```bash
# Instructions for retrieving credentials from Ansible Vault
echo "=== Credential Retrieval Instructions ==="
echo ""
echo "The POSTGRES_PASSWORD must be retrieved from Ansible Vault."
echo ""
echo "Coordinate with Frank Lucas (Security SME) to:"
echo "1. Access Ansible Vault on hx-ansible-server"
echo "2. Retrieve hx_lang_server PostgreSQL password"
echo "3. Update /opt/hx-lang-server/.env with actual password"
echo ""
echo "Manual update command:"
echo "  sudo sed -i 's/POSTGRES_PASSWORD=PLACEHOLDER_FROM_VAULT/POSTGRES_PASSWORD=actual_password/' /opt/hx-lang-server/.env"
echo ""
echo "Or use ansible-vault view to retrieve:"
echo "  ansible-vault view /path/to/credentials.yml --vault-password-file=/path/to/vault-pass"
```

### Step 4: Create Environment File Documentation

```bash
# Document environment variables
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/environment-variables.txt" > /dev/null <<'EOF'
# Environment Variables Documentation
# Date: 2025-12-04
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-142

## Environment File
Location: /opt/hx-lang-server/.env
Permissions: 600 (owner read/write only)
Owner: hx-lang-server service account

## Variable Reference

### Service Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| SERVICE_NAME | Service identifier | hx-lang-server |
| SERVICE_PORT | API port | 8100 |
| HEALTH_PORT | Health/metrics port | 8101 |
| LOG_LEVEL | Logging level | INFO |
| ENVIRONMENT | Deployment environment | development |

### PostgreSQL Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| POSTGRES_HOST | Database hostname | hx-postgres-server.hx.dev.local |
| POSTGRES_PORT | Database port | 5432 |
| POSTGRES_DB | Database name | hx_lang_server |
| POSTGRES_USER | Database user | hx_lang_server |
| POSTGRES_PASSWORD | Database password | (from Ansible Vault) |

### Redis Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| REDIS_URL | Redis connection URL | redis://hx-redis-server.hx.dev.local:6379/0 |
| REDIS_MAX_CONNECTIONS | Connection pool size | 50 |
| REDIS_SOCKET_TIMEOUT | Socket timeout | 5.0 |

### Ollama Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| OLLAMA_GENERAL_URL | General LLM endpoint | http://hx-ollama1-server.hx.dev.local:11434 |
| OLLAMA_GENERAL_MODEL | General model name | gemma3:27b |
| OLLAMA_CODE_URL | Code LLM endpoint | http://hx-ollama2-server.hx.dev.local:11434 |
| OLLAMA_CODE_MODEL | Code model name | qwen3-coder:30b |

### LightRAG Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| LIGHTRAG_URL | LightRAG API endpoint | http://hx-literag-server.hx.dev.local:8020 |
| LIGHTRAG_TIMEOUT | Request timeout | 60 |

### FastMCP Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| FASTMCP_URL | MCP gateway endpoint | http://hx-fastmcp-server.hx.dev.local:8000 |

### Agent Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| MAX_RECURSION_DEPTH | Max LangGraph iterations | 25 |
| CHECKPOINT_FREQUENCY | Checkpoint save frequency | per_turn |
| SESSION_TTL_SECONDS | Session timeout | 3600 |
| QUERY_TIMEOUT_SECONDS | Query timeout | 300 |

## Security Notes
- .env file contains sensitive credentials
- File permissions set to 600 (owner only)
- Never commit .env to version control
- PostgreSQL password from Ansible Vault only

## Credential Rotation
To rotate PostgreSQL password:
1. Update password in Ansible Vault
2. Update PostgreSQL user password
3. Update /opt/hx-lang-server/.env
4. Restart service: sudo systemctl restart hx-lang-server
EOF

echo "Environment documentation created: $DOC_DIR/environment-variables.txt"
```

### Step 5: Validate Environment File Syntax

```bash
# Validate environment file syntax
ENV_FILE="/opt/hx-lang-server/.env"
VENV_PATH="/opt/hx-lang-server/venv"

echo "Validating environment file syntax..."

# Check for syntax errors (valid KEY=VALUE format)
INVALID_LINES=$(grep -vE '^(#|$|[A-Za-z_][A-Za-z0-9_]*=)' "$ENV_FILE" | wc -l)

if [ "$INVALID_LINES" -eq 0 ]; then
    echo "Environment file syntax is valid"
else
    echo "WARNING: Found $INVALID_LINES potentially invalid lines"
    grep -vE '^(#|$|[A-Za-z_][A-Za-z0-9_]*=)' "$ENV_FILE"
fi

# Test loading with python-dotenv
"$VENV_PATH/bin/python" <<'PYEOF'
import sys
sys.path.insert(0, '/opt/hx-lang-server/src')

from dotenv import load_dotenv
import os

# Load environment file
load_dotenv('/opt/hx-lang-server/.env')

# Check required variables are set
required_vars = [
    'SERVICE_NAME',
    'SERVICE_PORT',
    'POSTGRES_HOST',
    'REDIS_URL',
    'OLLAMA_GENERAL_URL',
    'LIGHTRAG_URL',
]

missing = []
for var in required_vars:
    if not os.getenv(var):
        missing.append(var)

if missing:
    print(f"WARNING: Missing required variables: {', '.join(missing)}")
else:
    print("All required environment variables are set")

# Print loaded count (not values for security)
all_vars = [v for v in os.environ if v in [
    'SERVICE_NAME', 'SERVICE_PORT', 'POSTGRES_HOST', 'REDIS_URL',
    'OLLAMA_GENERAL_URL', 'LIGHTRAG_URL', 'LOG_LEVEL'
]]
print(f"Loaded {len(all_vars)} environment variables from .env")
PYEOF
```

### Step 6: Create .env.example Template

```bash
# Create .env.example for documentation (no secrets)
EXAMPLE_FILE="/opt/hx-lang-server/.env.example"

echo "Creating .env.example template..."

sudo tee "$EXAMPLE_FILE" > /dev/null <<'EOF'
# hx-lang-server Environment Configuration Template
# Copy to .env and update values

# Service Configuration
SERVICE_NAME=hx-lang-server
SERVICE_PORT=8100
HEALTH_PORT=8101
LOG_LEVEL=INFO
ENVIRONMENT=development

# PostgreSQL Configuration
POSTGRES_HOST=hx-postgres-server.hx.dev.local
POSTGRES_PORT=5432
POSTGRES_DB=hx_lang_server
POSTGRES_USER=hx_lang_server
POSTGRES_PASSWORD=your_password_here

# Redis Configuration
REDIS_URL=redis://hx-redis-server.hx.dev.local:6379/0
REDIS_MAX_CONNECTIONS=50
REDIS_SOCKET_TIMEOUT=5.0

# Ollama Configuration
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_CODE_MODEL=qwen3-coder:30b

# LightRAG Configuration
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:8020
LIGHTRAG_TIMEOUT=60

# FastMCP Configuration
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000

# Agent Configuration
MAX_RECURSION_DEPTH=25
CHECKPOINT_FREQUENCY=per_turn
SESSION_TTL_SECONDS=3600
QUERY_TIMEOUT_SECONDS=300
EOF

# Set permissions (readable by all - no secrets)
sudo chmod 644 "$EXAMPLE_FILE"

echo ".env.example template created"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Environment File | /opt/hx-lang-server/.env | Service configuration |
| Example Template | /opt/hx-lang-server/.env.example | Template for reference |
| Documentation | /opt/hx-lang-server/deployment-docs/environment-variables.txt | Variable documentation |

---

## Verification

**Validation Commands:**

```bash
echo "=== Environment File Validation ==="

ENV_FILE="/opt/hx-lang-server/.env"
VALIDATION_PASSED=true

# Check 1: File exists
echo "1. Environment File Existence:"
if [ -f "$ENV_FILE" ]; then
    echo "PASSED: Environment file exists"
else
    echo "FAILED: Environment file not found"
    VALIDATION_PASSED=false
fi

# Check 2: Permissions are secure
echo ""
echo "2. File Permissions:"
PERMS=$(stat -c "%a" "$ENV_FILE")
if [ "$PERMS" = "600" ]; then
    echo "PASSED: Permissions are 600 (secure)"
else
    echo "WARNING: Permissions are $PERMS (should be 600)"
fi

# Check 3: Required variables present
echo ""
echo "3. Required Variables:"
REQUIRED_VARS=(
    "SERVICE_NAME"
    "SERVICE_PORT"
    "POSTGRES_HOST"
    "POSTGRES_DB"
    "REDIS_URL"
    "OLLAMA_GENERAL_URL"
    "LIGHTRAG_URL"
)

for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "^${var}=" "$ENV_FILE"; then
        echo "PASSED: $var defined"
    else
        echo "FAILED: $var missing"
        VALIDATION_PASSED=false
    fi
done

# Check 4: Password placeholder check
echo ""
echo "4. Password Configuration:"
if grep -q "PLACEHOLDER_FROM_VAULT" "$ENV_FILE"; then
    echo "WARNING: POSTGRES_PASSWORD still contains placeholder"
    echo "ACTION REQUIRED: Update with actual password from Ansible Vault"
else
    echo "PASSED: Password placeholder has been replaced"
fi

# Check 5: Endpoint connectivity test
echo ""
echo "5. Endpoint Format Validation:"
ENDPOINTS=(
    "POSTGRES_HOST"
    "REDIS_URL"
    "OLLAMA_GENERAL_URL"
    "LIGHTRAG_URL"
    "FASTMCP_URL"
)

for endpoint in "${ENDPOINTS[@]}"; do
    VALUE=$(grep "^${endpoint}=" "$ENV_FILE" | cut -d= -f2)
    if [ -n "$VALUE" ]; then
        echo "PASSED: $endpoint = $VALUE"
    else
        echo "WARNING: $endpoint is empty"
    fi
done

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Environment file configured"
    echo ""
    if grep -q "PLACEHOLDER_FROM_VAULT" "$ENV_FILE"; then
        echo "IMPORTANT: Update POSTGRES_PASSWORD with actual credential from Ansible Vault"
    fi
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- Environment file exists at /opt/hx-lang-server/.env
- File permissions are 600 (owner read/write only)
- All required variables are defined
- Endpoint URLs are properly formatted
- Note: Password placeholder must be replaced with actual credential

---

## Rollback Procedure

Remove environment file if needed:

```bash
# Remove environment file
echo "Removing environment file..."

sudo rm -f /opt/hx-lang-server/.env
sudo rm -f /opt/hx-lang-server/.env.example

echo "Environment file removed"

# Note: Service will fail to start without .env file
# Recreate using .env.example as template
```

---

## Notes

**Security:**
- Environment file permissions are 600 (owner only)
- POSTGRES_PASSWORD must come from Ansible Vault
- Never commit .env file to version control
- .env.example can be committed (no secrets)

**Endpoint Configuration:**
- All endpoints use DNS hostnames (not IP addresses)
- DNS resolution handled by hx-dc-server
- Hostnames follow HX-Infrastructure naming convention

**Credential Management:**
- Coordinate with Frank Lucas for Ansible Vault access
- PostgreSQL credentials provisioned in Work Stream 4 (Trinity)
- Redis typically does not require authentication in dev environment

**Configuration Updates:**
- Modify .env and restart service
- No need to edit systemd unit file
- Service reads .env at startup

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Configuration Management - Environment Variables (lines 634-666)
- Section: Dependencies - External Services (lines 587-598)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 13: Service Deployment (Task Range 141-150)

---

## Risk Assessment

**Risk Level**: Medium (contains credentials)

**Risks:**
1. **Credential exposure**: .env file readable by unauthorized users
   - Mitigation: File permissions 600, owned by service account
2. **Placeholder left in production**: Service fails to connect to database
   - Mitigation: Validation warns about placeholder
3. **Wrong endpoint URLs**: Service cannot reach dependencies
   - Mitigation: Use DNS hostnames, validate format

**Dependencies Blocked:**
- Task 143 (Service Enablement) requires valid .env file
- Service cannot start without proper configuration
