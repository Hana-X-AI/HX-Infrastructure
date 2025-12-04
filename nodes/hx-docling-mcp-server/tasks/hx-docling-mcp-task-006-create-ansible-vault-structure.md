# Task 006: Create Ansible Vault Directory Structure

**Assigned To**: frank-lucas
**Estimated Effort**: 0.25 hours
**Dependencies**: Task 004 (ownership), Task 005 (permissions)
**Status**: Not Started

## Objective

Create Ansible Vault directory structure in `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/` for future credential storage following HX-Infrastructure credential management standards.

## Pre-Execution Validation

**CRITICAL**: Check if vault directory structure already exists BEFORE creating it.

```bash
# Check if vault directory and required files exist
if [ -d "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault" ] && \
   [ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/README.md" ] && \
   [ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml.example" ] && \
   [ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.gitignore" ]; then
    echo "✅ VALIDATION RESULT: Vault directory structure already exists"
    echo "Existing files:"
    ls -la /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/
    echo "ACTION: SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION RESULT: Vault directory structure incomplete or missing"
    echo "ACTION: PROCEED with vault directory creation"
fi
```

**If Vault Structure Exists**: Skip to Validation section

**If Vault Structure Does Not Exist**: Continue with Implementation Steps below

---

## Context

HX-Infrastructure uses Ansible Vault for encrypted credential storage in the repository. Each service has a dedicated `vault/` directory within its node directory containing:

- `credentials.yml` - Encrypted file with all service credentials
- `README.md` - Documentation on accessing vault contents
- `.gitignore` - Ensures vault password file is never committed

This task creates the directory structure and placeholder files. **Actual credential encryption occurs in Phase 2** (when service dependencies require credential storage). For Phase 1, the docling-mcp service uses:
- Standard service account password: `Major8859!` (from credentials.md)
- No Redis password (development mode, authentication disabled)
- LiteLLM API key stored in environment variable (Task 008)
- Qdrant without authentication (Phase 1)

**Vault Password**: `Major8859!` (HX-Infrastructure standard for all Ansible Vaults)

## Acceptance Criteria

- [ ] `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/` directory created
- [ ] Vault directory owned by `agent0:agent0` (repository ownership, not service account)
- [ ] Vault directory permissions set to 755 (readable by all for repository)
- [ ] Placeholder `README.md` created with vault access instructions
- [ ] Placeholder `credentials.yml.example` created showing expected structure
- [ ] `.gitignore` file created to prevent vault password file from being committed
- [ ] Directory structure validated

## Implementation Steps

### Step 1: Create Vault Directory in Repository

```bash
# Navigate to HX-Infrastructure repository
cd /home/agent0/HX-Infrastructure

# Create vault directory for hx-docling-mcp-server
mkdir -p nodes/hx-docling-mcp-server/vault

# Verify directory created
ls -ld nodes/hx-docling-mcp-server/vault/
# Expected: drwxr-xr-x agent0 agent0
```

### Step 2: Create Vault README Documentation

```bash
# Create README.md with vault access instructions
cat > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/README.md << 'EOF'
# Docling MCP Server - Ansible Vault Credentials

**Service**: Docling MCP Server
**Node**: hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)
**Vault Password**: Standard HX-Infrastructure vault password (see credentials.md)

## Vault Contents

This directory contains encrypted credentials for the Docling MCP Server service:

- `credentials.yml` - Encrypted credential store (Ansible Vault format)

## Accessing Vault Contents

### View Encrypted Credentials

```bash
# View vault contents (requires vault password)
ansible-vault view /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
# Enter vault password: Major8859!
```

### Edit Encrypted Credentials

```bash
# Edit vault file (requires vault password)
ansible-vault edit /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
# Enter vault password: Major8859!
```

### Decrypt Vault (Temporary)

```bash
# Decrypt to plaintext (for scripting/automation)
ansible-vault decrypt /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
# Enter vault password: Major8859!
# WARNING: File is now unencrypted - re-encrypt after use
```

### Re-encrypt Vault

```bash
# Re-encrypt after temporary decryption
ansible-vault encrypt /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
# Enter vault password: Major8859!
```

## Credential Reference

**Standard Passwords (from credentials.md)**:
- Service Account (`docling-mcp@hx.dev.local`): `Major8859!`
- Ansible Vault Password: `Major8859!`

**Service-Specific Credentials** (Phase 2 - when needed):
- Redis Password: (currently none - dev mode without authentication)
- LiteLLM API Key: `eee2c3d2aba9be064c3e6f7de1893aff44a992d0af3726bf73ccd2672f804cdb`
- Qdrant API Key: (currently none - Phase 1 without authentication)

## Vault File Structure

Expected structure of `credentials.yml` when created:

```yaml
---
# Docling MCP Server Credentials
# Encrypted with Ansible Vault (password: Major8859!)

# Service Account
service_account:
  username: "docling-mcp@hx.dev.local"
  password: "Major8859!"

# Redis Configuration (Phase 2 - currently no auth)
redis:
  host: "hx-redis-server.hx.dev.local"
  port: 6379
  password: ""  # Empty in development mode

# LiteLLM Gateway (Phase 2 - currently in .env)
litellm:
  api_base: "http://hx-litellm-server.hx.dev.local:4000"
  api_key: "eee2c3d2aba9be064c3e6f7de1893aff44a992d0af3726bf73ccd2672f804cdb"

# Qdrant Vector Database (Phase 2 - currently no auth)
qdrant:
  host: "hx-qdrant-server.hx.dev.local"
  port: 6333
  api_key: ""  # Empty in Phase 1

# LightRAG Server (Phase 2 - currently no auth)
lightrag:
  api_url: "http://hx-literag-server.hx.dev.local:8000"
  api_key: ""  # Empty in Phase 1
```

## Security Notes

- **Vault Password**: Use standard HX-Infrastructure vault password: `Major8859!`
- **Never Commit**: `.gitignore` prevents `vault-password.txt` from being committed
- **Development Environment**: Encryption is optional for dev environment (security through network isolation)
- **Production**: Would require strict vault password management and credential rotation

## References

- **Credentials Document**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md`
- **Vault Management**: `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`
EOF

# Verify README created
ls -l nodes/hx-docling-mcp-server/vault/README.md
```

### Step 3: Create Example Credentials File (Unencrypted Template)

```bash
# Create credentials.yml.example showing expected structure
cat > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml.example << 'EOF'
---
# Docling MCP Server Credentials - EXAMPLE (NOT ENCRYPTED)
# Copy to credentials.yml and encrypt with: ansible-vault encrypt credentials.yml
# Vault password: Major8859!

# Service Account
service_account:
  username: "docling-mcp@hx.dev.local"
  password: "Major8859!"

# Redis Configuration (Phase 2 - currently no auth)
redis:
  host: "hx-redis-server.hx.dev.local"
  port: 6379
  password: ""  # Empty in development mode

# LiteLLM Gateway
litellm:
  api_base: "http://hx-litellm-server.hx.dev.local:4000"
  api_key: "eee2c3d2aba9be064c3e6f7de1893aff44a992d0af3726bf73ccd2672f804cdb"

# Qdrant Vector Database (Phase 2 - currently no auth)
qdrant:
  host: "hx-qdrant-server.hx.dev.local"
  port: 6333
  api_key: ""  # Empty in Phase 1

# LightRAG Server (Phase 2 - currently no auth)
lightrag:
  api_url: "http://hx-literag-server.hx.dev.local:8000"
  api_key: ""  # Empty in Phase 1

# PostgreSQL Database (if used in Phase 2+)
postgres:
  host: "hx-postgres-server.hx.dev.local"
  port: 5432
  database: "docling_mcp"
  username: "svc-postgres"
  password: "Major8859!"
EOF

# Verify example file created
ls -l nodes/hx-docling-mcp-server/vault/credentials.yml.example
```

### Step 4: Create .gitignore for Vault Security

```bash
# Create .gitignore to prevent vault password file from being committed
cat > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.gitignore << 'EOF'
# Ansible Vault Password Files
vault-password.txt
.vault-password
vault-pass
.vault-pass

# Decrypted Credential Files (temporary decryption for editing)
credentials.yml.decrypted
*.decrypted

# Editor Temporary Files
*.swp
*.swo
*~
.*.sw?

# OS Generated Files
.DS_Store
Thumbs.db
EOF

# Verify .gitignore created
ls -l nodes/hx-docling-mcp-server/vault/.gitignore
```

### Step 5: Verify Vault Directory Structure

```bash
# List vault directory contents
ls -la nodes/hx-docling-mcp-server/vault/

# Expected output:
# -rw-r--r-- agent0 agent0 .gitignore
# -rw-r--r-- agent0 agent0 README.md
# -rw-r--r-- agent0 agent0 credentials.yml.example

# Verify directory ownership
stat -c '%U:%G %a %n' nodes/hx-docling-mcp-server/vault/

# Expected: agent0:agent0 755 nodes/hx-docling-mcp-server/vault/
```

### Step 6: (Optional) Create Placeholder Encrypted Vault

**NOTE**: This step is OPTIONAL for Phase 1. Actual credential encryption occurs in Phase 2 when needed.

```bash
# Copy example to credentials.yml
cp nodes/hx-docling-mcp-server/vault/credentials.yml.example \
   nodes/hx-docling-mcp-server/vault/credentials.yml

# Encrypt credentials.yml with Ansible Vault
ansible-vault encrypt nodes/hx-docling-mcp-server/vault/credentials.yml
# Enter vault password: Major8859!
# Confirm: Major8859!

# Verify encryption succeeded
file nodes/hx-docling-mcp-server/vault/credentials.yml
# Expected: ASCII text (Ansible Vault encrypted data)

# View encrypted contents to verify
ansible-vault view nodes/hx-docling-mcp-server/vault/credentials.yml
# Enter vault password: Major8859!
# Should display YAML content
```

## Validation

**Validation Commands:**

```bash
# 1. Verify vault directory exists
[ -d "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault" ] && echo "PASS: Vault directory exists" || echo "FAIL: Vault directory missing"

# 2. Verify README exists
[ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/README.md" ] && echo "PASS: README exists" || echo "FAIL: README missing"

# 3. Verify example credentials file exists
[ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml.example" ] && echo "PASS: Example credentials exist" || echo "FAIL: Example credentials missing"

# 4. Verify .gitignore exists
[ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.gitignore" ] && echo "PASS: .gitignore exists" || echo "FAIL: .gitignore missing"

# 5. Verify directory ownership (agent0:agent0 for repository)
stat -c '%U:%G' /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault | grep -q "agent0:agent0" && echo "PASS: Vault directory ownership correct" || echo "FAIL: Vault directory ownership incorrect"

# 6. Verify directory permissions (755 for repository access)
stat -c '%a' /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault | grep -q "755" && echo "PASS: Vault directory permissions correct" || echo "FAIL: Vault directory permissions incorrect"

# 7. (Optional) Verify credentials.yml is encrypted if created
if [ -f "/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml" ]; then
  head -n 1 /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml | grep -q '$ANSIBLE_VAULT' && echo "PASS: Credentials encrypted" || echo "FAIL: Credentials not encrypted"
else
  echo "INFO: credentials.yml not yet created (optional for Phase 1)"
fi

# 8. Verify .gitignore prevents vault password commit
grep -q "vault-password.txt" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.gitignore && echo "PASS: .gitignore protects vault password" || echo "FAIL: .gitignore missing vault password protection"
```

**Expected Outcomes:**
- All validation commands return "PASS" or "INFO"
- Vault directory exists in repository (not on target server)
- Directory owned by agent0 (repository ownership)
- Documentation files provide clear vault access instructions
- .gitignore prevents accidental credential exposure

## Notes

### Vault Directory Location

**Repository Location**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/`
- **Purpose**: Version-controlled credential storage
- **Ownership**: `agent0:agent0` (repository owner, NOT service account)
- **Encryption**: Ansible Vault encryption protects contents
- **Access**: Developers/operators access via `ansible-vault` commands

**Server Configuration Location**: `/etc/docling-mcp/vault/`
- **Purpose**: Runtime credential files on target server (if needed)
- **Ownership**: `root:docling-mcp@hx.dev.local`
- **Permissions**: 640 (root read-write, service read-only)
- **Deployment**: Credentials deployed from repository vault to server (Phase 2)

### Ansible Vault Workflow

**Phase 1 (Current)**: Structure only
- Vault directory created with documentation
- Example credentials provided
- Actual credential encryption deferred to Phase 2

**Phase 2**: Credential encryption and deployment
- Encrypt credentials with `ansible-vault encrypt credentials.yml`
- Deploy encrypted credentials to `/etc/docling-mcp/vault/` on server
- Application reads credentials via Ansible Vault decryption or environment variables

**Phase 3+**: Automation and rotation
- Ansible playbooks read encrypted credentials
- Automated deployment to target servers
- Credential rotation procedures documented

### Standard Vault Password

**HX-Infrastructure Standard**: `Major8859!`
- **Same password for ALL Ansible Vaults** in HX-Infrastructure
- Simplifies development environment operations
- Documented in `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md`

**Production Consideration**:
- Production would use unique vault passwords per service
- Stored in secure password manager (1Password, Bitwarden, etc.)
- Regular rotation policy (90 days recommended)

### Why Vault for Development?

**Question**: Why use Ansible Vault in development environment?

**Answer**: Practice for production patterns
- Establishes credential management habits
- Tests encryption/decryption workflows
- Enables secure credential sharing in team environments
- Prepares for production deployment

**Alternative**: Environment variables without encryption
- Acceptable for isolated development environment
- Used in Phase 1 (credentials in .env files)
- Vault provides migration path to production

### Credential Storage Strategy

**Phase 1 Approach** (Current):
- Service account password: From `credentials.md` (standard `Major8859!`)
- LiteLLM API key: In `.env` file (`/etc/docling-mcp/env/.env`)
- Redis: No authentication (development mode)
- Qdrant: No authentication (Phase 1)

**Phase 2+ Approach** (Future):
- All credentials: In Ansible Vault (`credentials.yml` encrypted)
- Application: Reads from vault or environment variables
- Deployment: Ansible playbook decrypts and deploys to `/etc/docling-mcp/vault/`

### Git Security

**.gitignore Protection**:
- Prevents `vault-password.txt` from being committed (would expose decryption key)
- Prevents decrypted temporary files from being committed
- Encrypted `credentials.yml` CAN be committed (Ansible Vault encrypted)

**Safe to Commit**:
- ✅ `credentials.yml` (Ansible Vault encrypted)
- ✅ `credentials.yml.example` (example template, no real secrets)
- ✅ `README.md` (documentation)
- ✅ `.gitignore` (security protection)

**NEVER Commit**:
- ❌ `vault-password.txt` (vault decryption password)
- ❌ `credentials.yml.decrypted` (plaintext credentials)
- ❌ `.env` files with real secrets (use `.env.example` instead)

### Troubleshooting

**If ansible-vault command not found**:
```bash
# Install Ansible
sudo apt update
sudo apt install ansible -y

# Verify installation
ansible-vault --version
```

**If vault encryption fails**:
```bash
# Check file exists
ls -l nodes/hx-docling-mcp-server/vault/credentials.yml

# Check file not already encrypted
head -n 1 nodes/hx-docling-mcp-server/vault/credentials.yml
# Should NOT start with $ANSIBLE_VAULT

# If already encrypted, decrypt first
ansible-vault decrypt nodes/hx-docling-mcp-server/vault/credentials.yml
# Then re-encrypt
ansible-vault encrypt nodes/hx-docling-mcp-server/vault/credentials.yml
```

**If vault password forgotten**:
- Standard password is `Major8859!` (documented in credentials.md)
- If different password was used by mistake, file cannot be decrypted
- Would need to re-create credentials.yml from example

## References

- **Credentials Document**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (line 20-46: Standard password policy)
- **Vault Management Standards**: `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- **Ansible Vault Documentation**: https://docs.ansible.com/ansible/latest/user_guide/vault.html

## Risk Assessment

**Risk**: Very Low
- Directory creation in repository (no server impact)
- No operational services affected
- Encryption is optional for Phase 1
- Changes are reversible

**Mitigation**:
- Use standard vault password for consistency
- .gitignore prevents password file commits
- Documentation provides clear access instructions
- Example file shows expected credential structure

**Rollback Procedure**:
```bash
# If vault directory needs to be removed
rm -rf /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault
# Safe - only removes repository directory, no server impact
```
