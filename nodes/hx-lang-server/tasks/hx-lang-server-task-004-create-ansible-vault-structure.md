# Task 004: Create Ansible Vault Structure

**Assigned To**: frank-lucas
**Estimated Effort**: 0.5 hours
**Dependencies**: Task 003 (Directory Structure Creation)
**Status**: Not Started
**Phase**: Pre-Deployment

## Objective

Create Ansible Vault structure and encrypted credentials file at `/opt/hx-lang-server/vault/credentials.yml` containing all sensitive configuration for the LangGraph Orchestration Server.

## Context

Ansible Vault provides encrypted credential storage for HX-Infrastructure services. While this is a development environment where encryption is optional, we follow the vault structure for consistency and operational readiness.

**Credentials to Store:**
- PostgreSQL database password (for langgraph-checkpoint-postgres)
- Redis connection URL (if authentication enabled in future)
- LiteLLM API key (for LLM integration)
- Service-specific secrets

**Vault Password Standard**: `Major8859!` (same as service account password)

## Prerequisites

- [ ] Task 003 completed (directory structure exists at `/opt/hx-lang-server/`)
- [ ] `vault/` directory created with 700 permissions
- [ ] Service account `hx-lang-server@hx.dev.local` exists
- [ ] SSH access to hx-lang-server.hx.dev.local as agent0

## Acceptance Criteria

- [ ] Vault directory structure created at `/opt/hx-lang-server/vault/`
- [ ] `credentials.yml` file created with all required credentials
- [ ] `README.md` created with vault access instructions
- [ ] `.vault-password` file created with vault password (for convenience)
- [ ] All vault files owned by `hx-lang-server@hx.dev.local`
- [ ] Vault files have restrictive permissions (600)
- [ ] Ansible vault can decrypt credentials.yml successfully

## Implementation Steps

### Step 1: SSH to Target Server

```bash
# Connect to hx-lang-server as agent0
ssh agent0@hx-lang-server.hx.dev.local
# Password: Major8859!
```

### Step 2: Create Vault Password File

```bash
# Create .vault-password file for convenient vault operations
echo 'Major8859!' | sudo tee /opt/hx-lang-server/vault/.vault-password > /dev/null

# Set restrictive permissions
sudo chmod 600 /opt/hx-lang-server/vault/.vault-password

# Set ownership to service account
sudo chown hx-lang-server@hx.dev.local:domain\ users@hx.dev.local /opt/hx-lang-server/vault/.vault-password

# Verify file created
ls -la /opt/hx-lang-server/vault/.vault-password
# Expected: -rw------- 1 hx-lang-server@hx.dev.local domain users@hx.dev.local ... .vault-password
```

### Step 3: Create Credentials YAML Template

```bash
# Create credentials.yml with all required secrets
sudo tee /opt/hx-lang-server/vault/credentials.yml > /dev/null <<'EOF'
---
# Ansible Vault - hx-lang-server Credentials
# Vault Password: Major8859!
# Created: $(date +%Y-%m-%d)
# Service: LangGraph Orchestration Server

# PostgreSQL Database Credentials
postgres_host: hx-postgres-server.hx.dev.local
postgres_port: 5432
postgres_db: hx_lang_server
postgres_user: hx_lang_server
postgres_password: Major8859!
postgres_connection_string: "postgresql://hx_lang_server:Major8859!@hx-postgres-server.hx.dev.local:5432/hx_lang_server"

# Redis Connection
redis_host: hx-redis-server.hx.dev.local
redis_port: 6379
redis_db: 0
redis_url: "redis://hx-redis-server.hx.dev.local:6379/0"
# Note: Redis is in DEV mode (no authentication required)

# LiteLLM Integration
litellm_url: http://hx-litellm-server.hx.dev.local:4000
litellm_api_key: eee2c3d2aba9be064c3e6f7de1893aff44a992d0af3726bf73ccd2672f804cdb

# Ollama Endpoints
ollama_general_url: http://hx-ollama1-server.hx.dev.local:11434
ollama_code_url: http://hx-ollama2-server.hx.dev.local:11434
ollama_general_model: gemma3:27b
ollama_code_model: qwen3-coder:30b

# LightRAG Integration
lightrag_url: http://hx-literag-server.hx.dev.local:8020

# FastMCP Gateway
fastmcp_url: http://hx-fastmcp-server.hx.dev.local:8000

# Service Configuration
service_name: hx-lang-server
service_port: 8100
service_host: 0.0.0.0
log_level: INFO

# Environment
environment: development
debug_mode: false
EOF
```

### Step 4: Set Credentials File Ownership and Permissions

```bash
# Set ownership to service account
sudo chown hx-lang-server@hx.dev.local:domain\ users@hx.dev.local /opt/hx-lang-server/vault/credentials.yml

# Set restrictive permissions (600 - owner read/write only)
sudo chmod 600 /opt/hx-lang-server/vault/credentials.yml

# Verify permissions
ls -la /opt/hx-lang-server/vault/credentials.yml
# Expected: -rw------- 1 hx-lang-server@hx.dev.local domain users@hx.dev.local ... credentials.yml
```

### Step 5: Encrypt Credentials with Ansible Vault (Optional)

```bash
# Encrypt credentials.yml (optional for dev environment)
# Uncomment and run if encryption desired:
# sudo ansible-vault encrypt /opt/hx-lang-server/vault/credentials.yml --vault-password-file=/opt/hx-lang-server/vault/.vault-password

# For dev environment, we keep credentials.yml unencrypted for convenience
# File permissions (600) provide sufficient protection
```

### Step 6: Create Vault README Documentation

```bash
# Create README with vault access instructions
sudo tee /opt/hx-lang-server/vault/README.md > /dev/null <<'EOF'
# hx-lang-server Ansible Vault

This directory contains encrypted credentials for the LangGraph Orchestration Server.

## Files

- `credentials.yml` - Encrypted credentials (PostgreSQL, Redis, API keys)
- `.vault-password` - Vault password for encryption/decryption
- `README.md` - This file

## Vault Password

**Password**: `Major8859!`

Stored in `.vault-password` file for convenient vault operations.

## Accessing Credentials

### View Credentials (if encrypted)

```bash
# Using password file
ansible-vault view /opt/hx-lang-server/vault/credentials.yml --vault-password-file=/opt/hx-lang-server/vault/.vault-password

# Using password prompt
ansible-vault view /opt/hx-lang-server/vault/credentials.yml
# Enter vault password: Major8859!
```

### Edit Credentials (if encrypted)

```bash
# Using password file
ansible-vault edit /opt/hx-lang-server/vault/credentials.yml --vault-password-file=/opt/hx-lang-server/vault/.vault-password

# Using password prompt
ansible-vault edit /opt/hx-lang-server/vault/credentials.yml
# Enter vault password: Major8859!
```

### Decrypt Credentials (if encrypted)

```bash
# Using password file
ansible-vault decrypt /opt/hx-lang-server/vault/credentials.yml --vault-password-file=/opt/hx-lang-server/vault/.vault-password

# Using password prompt
ansible-vault decrypt /opt/hx-lang-server/vault/credentials.yml
# Enter vault password: Major8859!
```

### Re-encrypt Credentials

```bash
# Using password file
ansible-vault encrypt /opt/hx-lang-server/vault/credentials.yml --vault-password-file=/opt/hx-lang-server/vault/.vault-password

# Using password prompt
ansible-vault encrypt /opt/hx-lang-server/vault/credentials.yml
# Enter vault password: Major8859!
```

## Development Environment Note

For development environment convenience, `credentials.yml` may be kept unencrypted. File permissions (600) provide sufficient protection for dev environment.

For production deployment, credentials MUST be encrypted with Ansible Vault.

## Credential Reference

See: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` for authoritative credential source.

## Security

- Vault directory: 700 permissions (owner access only)
- Credentials file: 600 permissions (owner read/write only)
- Password file: 600 permissions (owner read/write only)
- Owner: hx-lang-server@hx.dev.local (service account)

**DO NOT** commit vault password or unencrypted credentials to version control.
EOF

# Set README ownership and permissions
sudo chown hx-lang-server@hx.dev.local:domain\ users@hx.dev.local /opt/hx-lang-server/vault/README.md
sudo chmod 644 /opt/hx-lang-server/vault/README.md
```

### Step 7: Verify Service Account Access

```bash
# Switch to service account
sudo su - hx-lang-server@hx.dev.local

# Test read access to credentials
cat /opt/hx-lang-server/vault/credentials.yml | head -n 5
# Should display first 5 lines of credentials.yml

# Test read access to vault password
cat /opt/hx-lang-server/vault/.vault-password
# Should display: Major8859!

# Exit back to agent0
exit
```

## Validation

**Validation Commands (Run on hx-lang-server):**

```bash
# 1. Verify vault directory exists with correct permissions
test -d /opt/hx-lang-server/vault && echo "PASS: Vault directory exists" || echo "FAIL: Vault directory missing"
perm=$(stat -c "%a" /opt/hx-lang-server/vault)
[ "$perm" = "700" ] && echo "PASS: Vault directory permissions (700)" || echo "FAIL: Vault directory permissions ($perm)"

# 2. Verify credentials.yml exists with correct permissions
test -f /opt/hx-lang-server/vault/credentials.yml && echo "PASS: credentials.yml exists" || echo "FAIL: credentials.yml missing"
perm=$(stat -c "%a" /opt/hx-lang-server/vault/credentials.yml)
[ "$perm" = "600" ] && echo "PASS: credentials.yml permissions (600)" || echo "FAIL: credentials.yml permissions ($perm)"

# 3. Verify .vault-password exists with correct permissions
test -f /opt/hx-lang-server/vault/.vault-password && echo "PASS: .vault-password exists" || echo "FAIL: .vault-password missing"
perm=$(stat -c "%a" /opt/hx-lang-server/vault/.vault-password)
[ "$perm" = "600" ] && echo "PASS: .vault-password permissions (600)" || echo "FAIL: .vault-password permissions ($perm)"

# 4. Verify README.md exists
test -f /opt/hx-lang-server/vault/README.md && echo "PASS: README.md exists" || echo "FAIL: README.md missing"

# 5. Verify ownership
stat -c "%U" /opt/hx-lang-server/vault/credentials.yml | grep -q "hx-lang-server@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# 6. Verify vault password content
grep -q "Major8859!" /opt/hx-lang-server/vault/.vault-password && echo "PASS: Vault password correct" || echo "FAIL: Vault password incorrect"

# 7. Verify credentials contain required keys
for key in postgres_password postgres_connection_string redis_url litellm_api_key ollama_general_url; do
    grep -q "$key:" /opt/hx-lang-server/vault/credentials.yml && echo "PASS: $key found" || echo "FAIL: $key missing"
done

# 8. Test ansible-vault can read file (if encrypted)
# ansible-vault view /opt/hx-lang-server/vault/credentials.yml --vault-password-file=/opt/hx-lang-server/vault/.vault-password > /dev/null 2>&1 && echo "PASS: Ansible vault can decrypt" || echo "WARN: File not encrypted or vault error"
```

**Expected Outcomes:**
- All validation commands return "PASS" (or "WARN" for optional encryption)
- Vault structure complete
- All files have correct ownership and permissions
- Service account can read credentials

## Deliverables

1. Ansible Vault structure created at `/opt/hx-lang-server/vault/`
2. `credentials.yml` file with all required credentials
3. `.vault-password` file with vault password
4. `README.md` with vault access instructions
5. Validation output confirming all acceptance criteria met

## Rollback Procedure

**If vault creation fails or needs reversal:**

```bash
# SSH to hx-lang-server
ssh agent0@hx-lang-server.hx.dev.local
# Password: Major8859!

# Remove all vault contents
sudo rm -f /opt/hx-lang-server/vault/*

# Verify deletion
ls -la /opt/hx-lang-server/vault/
# Should show empty directory (only . and ..)
```

**WARNING**: Rollback will delete ALL vault contents. Only use during initial setup.

## Notes

### Standard Vault Password

**ALL Ansible Vault files use password**: `Major8859!`

This is HX-Infrastructure standard for development environment. Reference: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (AUTHORITATIVE)

### Credentials Source

All credentials in `credentials.yml` sourced from:
- **PostgreSQL password**: Standard service password `Major8859!`
- **LiteLLM API key**: From credentials.md (lines 522-524)
- **Redis**: DEV mode (no authentication)
- **Ollama, LightRAG, FastMCP**: No authentication required

Reference: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md`

### Encryption Optional for Dev

For development environment:
- Encryption is **optional** (file permissions provide sufficient protection)
- Vault structure maintained for consistency
- Production deployments **MUST** encrypt credentials

### Database User Provisioning

The PostgreSQL user `hx_lang_server` will be created by Trinity (PostgreSQL SME) in Work Stream 4. This task only stores the credentials; database provisioning happens later.

### Security Considerations

- Vault directory: 700 permissions (only service account can access)
- Credentials file: 600 permissions (only service account can read/write)
- Password file: 600 permissions (only service account can read/write)
- No world-readable vault contents
- Service account isolation (no sudo privileges)

### Troubleshooting

**Permission denied accessing vault:**
```bash
# Check vault directory permissions
ls -ld /opt/hx-lang-server/vault

# Check file permissions
ls -la /opt/hx-lang-server/vault/

# Verify service account ownership
stat -c "%U %G" /opt/hx-lang-server/vault/credentials.yml

# Reset permissions if needed
sudo chmod 700 /opt/hx-lang-server/vault
sudo chmod 600 /opt/hx-lang-server/vault/{credentials.yml,.vault-password}
```

**Ansible vault command not found:**
```bash
# Install ansible if missing
sudo apt update
sudo apt install -y ansible

# Verify installation
ansible-vault --version
```

**Credentials missing keys:**
```bash
# View current credentials
cat /opt/hx-lang-server/vault/credentials.yml

# Edit credentials as service account
sudo su - hx-lang-server@hx.dev.local
vi /opt/hx-lang-server/vault/credentials.yml
# Add missing keys, save, exit
```

## References

- **Credential Source**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (AUTHORITATIVE)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/charter/charter.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md` (Section: Configuration Management, Environment Variables)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- **Standards**: `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`

## Risk Assessment

**Risk**: Low
- Vault creation is non-disruptive
- No impact on operational services
- Easily reversible if issues occur
- No services running yet

**Mitigation**:
- Use standard vault password for consistency
- Verify file permissions before proceeding
- Document rollback procedure for easy reversal
- Test service account access after creation
