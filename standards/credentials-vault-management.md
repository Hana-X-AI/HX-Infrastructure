# Credentials and Vault Management Standards

**Document Type**: Standards - Security & Operations  
**Created**: 2025-11-15  
**Classification**: Internal - DO NOT COMMIT TO GITHUB  
**Status**: ✅ ACTIVE - Required for All Infrastructure Deployments  

---

## ⚠️ CRITICAL: Git Repository Exclusion

**THIS FILE MUST NOT BE COMMITTED TO GITHUB**

This file contains sensitive infrastructure patterns and vault management details that must remain private.

**Verify .gitignore includes**:
```gitignore
# Credentials and vault documentation
standards/credentials-vault-management.md
*credentials*
*vault-management*

# Vault files and passwords
.vault_password
vault_password
*.vault_pass
vault/
**/vault/

# Service-specific vaults
services/**/vault/
nodes/**/vault/

# Environment files
.env
.env.*
*.env

# Private keys and certificates
*.key
*.pem
*.crt
private/
secrets/
```

---

## Table of Contents

1. [Overview](#1-overview)
2. [Vault Architecture](#2-vault-architecture)
3. [Password Standards](#3-password-standards)
4. [Service Vault Structure](#4-service-vault-structure)
5. [Node Vault Structure](#5-node-vault-structure)
6. [Vault Operations](#6-vault-operations)
7. [Integration with Deployment](#7-integration-with-deployment)
8. [Security Considerations](#8-security-considerations)
9. [Quick Reference](#9-quick-reference)

---

## 1. Overview

### 1.1 Purpose

This document establishes credentials and vault management standards for HX Infrastructure. It defines how secrets are stored, managed, and deployed across all services and nodes.

**Key Principles**:
- **Service-Specific Vaults**: Each service has its own encrypted vault
- **Node-Specific Vaults**: Each node has vault for node-level secrets
- **Ansible Vault** for encryption
- **No Secrets in Git**: All vaults encrypted, vault passwords never committed
- **Consistent Patterns**: Same structure across all services

---

### 1.2 Scope

**Applies to**:
- All services in `services/operational/` and `services/non-operational/`
- All nodes in `nodes/`
- Service account credentials
- Database passwords
- API keys and tokens
- TLS certificates and keys
- Configuration secrets
- Integration credentials

**Does NOT apply to**:
- Personal user passwords (out of scope)
- External third-party service credentials (managed externally)

---

### 1.3 Critical Account Management Policy

**⚠️ NO LOCAL USER ACCOUNTS**

**MANDATORY REQUIREMENT**: All user accounts MUST be created in Samba Active Directory.

**Applies to**:
- All human user accounts
- All administrative accounts
- All interactive login accounts
- All domain-joined systems

**NEVER create local user accounts for**:
- SSH access
- System administration
- Service access
- Application access

**ONLY exception**: System service accounts (e.g., `root`, `nobody`, distro defaults)

**Enforcement**:
- All nodes are domain-joined to Samba AD
- User authentication via Samba AD
- No local user creation commands (`useradd`, `adduser`) except for service accounts
- All human users managed centrally in Samba AD

---

### 1.4 Knowledge Base References - 🔴 MUST READ

**⚠️ CRITICAL**: The following documents in `hx-knowledge/docs/` contain ACTUAL PASSWORDS and credentials for deployed infrastructure. These documents are git-ignored and must be consulted during all maintenance, deployments, and upgrades.

**Location**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/`

#### Required Reading Documents:

1. **📋 0.0.5.2.0-readme.md** - 🔴 MUST READ
   - Overview of credentials structure
   - Index of all stored credentials
   - Quick reference guide
   
2. **🔐 0.0.5.2.1-credentials.md** - 🔴 MUST READ
   - Actual passwords for all server nodes
   - Service account credentials
   - Administrative access credentials
   - Database passwords
   - API keys and tokens
   
3. **🔑 0.0.5.2.2-url-safe-password-pattern.md** - 🔴 MUST READ
   - Password generation patterns
   - URL-safe password standards
   - Password complexity requirements

**⚠️ Git Status**: These files are in `.gitignore` - they will NEVER be committed to GitHub

**🔒 Security**: These documents contain plaintext credentials and must:
- Remain in git-ignored directory
- Be consulted during all deployment activities
- Be updated when credentials change
- Never be copied to public locations
- Be backed up securely offline

**Usage During Deployment**:
```bash
# Before any deployment, review current credentials:
cd /home/agent0/HX-Infrastructure/hx-knowledge/docs/

# Read the index
cat 0.0.5.2.0-readme.md

# Get credentials for specific service/node
grep -A 10 "[service-name]" 0.0.5.2.1-credentials.md

# Understand password patterns
cat 0.0.5.2.2-url-safe-password-pattern.md
```

**Important Notes**:
- These are the SOURCE OF TRUTH for current credentials
- Vaults in `services/*/vault/` and `nodes/*/vault/` should mirror these credentials
- When credentials are rotated, update both the knowledge base docs AND the vaults
- Never store credentials anywhere else - single source of truth principle

---

## 2. Vault Architecture

### 2.1 Two-Level Vault System

**HX Infrastructure uses two levels of vaults**:

1. **Service Vaults**: Secrets specific to a service
   - Location: `services/[operational|non-operational]/[service]/vault/`
   - Contains: Service-specific credentials, API keys, integration secrets
   - One vault per service

2. **Node Vaults**: Secrets specific to a node
   - Location: `nodes/[node-name]/vault/`
   - Contains: Node SSH keys, system credentials, shared secrets
   - One vault per node

### 2.2 Vault Isolation

**Each vault is independent**:
- Separate encryption (can use different passwords if needed)
- Separate access control
- Separate lifecycle (rotate independently)
- No cross-vault dependencies

**Benefits**:
- Blast radius limitation (compromise one ≠ compromise all)
- Service-specific access control
- Independent credential rotation
- Clear ownership boundaries

---

## 3. Password Standards

### 3.1 Account Types and Management

**HX Infrastructure uses centralized identity management via Samba Active Directory.**

#### Account Types

**1. Service Accounts (Local)**
- Created locally on nodes
- Used for running services and applications
- Named: `svc-[service]`, `[service]-user`
- Examples: `svc-database`, `postgres`, `nginx`
- Management: Created with `useradd` or service installation
- Password pattern: [Service Pattern - no special chars]

**2. User Accounts (Samba AD)**
- Created in Samba Active Directory ONLY
- Used for human authentication and access
- Named: `[username]@hx.dev.local`
- Examples: `admin@hx.dev.local`, `developer@hx.dev.local`
- Management: Created with `samba-tool user create`
- Password pattern: [Admin Pattern - with complexity]

**3. System Accounts (Local - OS Managed)**
- Created by OS or package installation
- Used for system services
- Examples: `root`, `nobody`, `systemd-*`, `www-data`
- Management: Automatic (OS/package manager)
- Password: Usually locked (no password login)

#### Password Decision Matrix

```
Account For:          Create Where?    Tool                      Password Type
===============================================================================
Human Users          Samba AD          samba-tool user create    Admin Pattern
Administrators       Samba AD          samba-tool user create    Admin Pattern  
Service Accounts     Local (node)      useradd                   Service Pattern
System Accounts      OS/Package        Automatic                 Locked/None
```

### 3.2 Password Patterns

**Development Environment - Current Standards**:

#### Service Account Pattern (URL-Safe, No Special Chars)
```
[16-32 alphanumeric characters, no special chars]
Requirements:
- 16-32 characters
- Alphanumeric only: a-z, A-Z, 0-9
- No special characters (!@#$%^&*...)
- Mix of upper and lowercase
- Mix of letters and numbers

Example: Kp9mN2vR4xL8qW3y
```

**Why URL-Safe?**: Many services use credentials in URLs or API endpoints where special characters require escaping.

#### Admin/User Account Pattern (Complex)
```
[Minimum 12 characters with complexity]
Requirements:
- Minimum 12 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (@!#$%^&*)
- No dictionary words

Example: P@ssw0rd!2024#Hx
```

**Production Migration**: When moving to production, all passwords must be rotated to meet production complexity requirements.

---

## 4. Service Vault Structure

### 4.1 Service Vault Location

**Path**: `services/[operational|non-operational]/[service]/vault/`

**Files**:
```
services/operational/[service]/
└── vault/
    ├── secrets.yml          # Encrypted vault file
    ├── .vault_password      # Vault password (git-ignored)
    └── README.md            # Vault usage instructions
```

---

### 4.2 Service Vault Contents

**Standard secrets.yml structure**:

```yaml
---
# Service Vault: [service-name]
# Encrypted with: ansible-vault encrypt secrets.yml
# Last Updated: [DATE]

# Service Account Credentials
service_account_username: "svc-[service]"
service_account_password: "[URL-safe password]"

# Database Credentials
database_host: "localhost"
database_port: "5432"
database_name: "[service]_db"
database_username: "[service]_user"
database_password: "[URL-safe password]"
database_root_password: "[URL-safe password]"

# API Keys and Tokens
api_key: "[generated-key]"
api_secret: "[generated-secret]"
jwt_secret: "[random-string]"
encryption_key: "[base64-encoded-key]"

# External Integration Credentials
external_service_api_key: "[key]"
external_service_secret: "[secret]"
webhook_secret: "[secret]"

# TLS/SSL Certificates (if service-specific)
tls_certificate: "[base64-encoded-cert]"
tls_private_key: "[base64-encoded-key]"

# OAuth/OIDC Credentials
oauth_client_id: "[client-id]"
oauth_client_secret: "[secret]"
oidc_provider_url: "[url]"

# Email/SMTP Credentials (if needed)
smtp_host: "smtp.example.com"
smtp_port: "587"
smtp_username: "[email]"
smtp_password: "[password]"

# S3/Object Storage Credentials
s3_access_key: "[access-key]"
s3_secret_key: "[secret-key]"
s3_bucket: "[bucket-name]"

# Monitoring/Logging Credentials
logging_api_key: "[key]"
monitoring_token: "[token]"
```

---

### 4.3 Service Vault README Template

**Each vault should have a README.md**:

```markdown
# Vault: [Service Name]

## Quick Reference

- **Vault File**: `secrets.yml`
- **Encryption**: Ansible Vault
- **Last Updated**: [DATE]
- **Owner**: [Team/Person]

## Decrypting

```bash
ansible-vault view secrets.yml --vault-password-file .vault_password
```

## Editing

```bash
ansible-vault edit secrets.yml --vault-password-file .vault_password
```

## Re-encrypting

```bash
# After editing, ensure it's encrypted
ansible-vault encrypt secrets.yml --vault-password-file .vault_password
```

## Credentials Inventory

This vault contains:
- ✅ Service account credentials
- ✅ Database passwords
- ✅ API keys
- ✅ [Other credentials]

## Rotation Schedule

- Database passwords: Quarterly
- API keys: Semi-annually
- Service account: Annually

## Last Rotation

- Database: [DATE]
- API Keys: [DATE]
- Service Account: [DATE]
```

---

## 5. Node Vault Structure

### 5.1 Node Vault Location

**Path**: `nodes/[node-name]/vault/`

**Files**:
```
nodes/[node-name]/
└── vault/
    ├── secrets.yml          # Encrypted vault file
    ├── .vault_password      # Vault password (git-ignored)
    └── README.md            # Vault usage instructions
```

---

### 5.2 Node Vault Contents

**Standard secrets.yml structure**:

```yaml
---
# Node Vault: [node-name]
# Encrypted with: ansible-vault encrypt secrets.yml
# Last Updated: [DATE]

# Samba AD Domain Join (REQUIRED)
samba_domain: "hx.dev.local"
domain_join_user: "Administrator@hx.dev.local"
domain_join_password: "[admin password]"
domain_computer_account: "[node-name]$"

# Node System Credentials (Local service accounts only)
# NOTE: Human users are in Samba AD, not local accounts

# SSH Keys (for service accounts or automation)
ssh_private_key: |
  [private key content - base64 or raw]
ssh_public_key: "[public key]"
ssh_authorized_keys:
  - "[key1]"
  - "[key2]"

# System Service Account Credentials
system_service_account: "svc-[service]"
system_service_password: "[service password]"

# Shared Service Credentials (if node hosts multiple services)
shared_db_admin_password: "[password]"
shared_monitoring_api_key: "[key]"

# Node-Specific Certificates
node_tls_cert: "[base64]"
node_tls_key: "[base64]"

# Backup Credentials
backup_encryption_key: "[key]"
backup_remote_password: "[password]"

# Monitoring Credentials
monitoring_agent_key: "[key]"
alerting_webhook_secret: "[secret]"
```

**Important Notes**:
- **No local user passwords**: All human users authenticate via Samba AD
- **Domain join credentials**: Required for joining node to Samba AD
- **Service accounts only**: Only service account credentials stored here
- **SSH keys**: For automation/service accounts, not human users

---

## 6. Vault Operations

### 6.1 Creating a New Vault

**For a new service**:

```bash
# Navigate to service directory
cd services/non-operational/[service]

# Create vault directory
mkdir -p vault
cd vault

# Create vault password file (git-ignored)
echo "your-vault-password" > .vault_password
chmod 600 .vault_password

# Create secrets file
cat > secrets.yml << 'EOF'
---
# Service Vault: [service]
service_account_username: "svc-[service]"
service_account_password: "[password]"
database_password: "[password]"
# ... add all secrets
EOF

# Encrypt the vault
ansible-vault encrypt secrets.yml --vault-password-file .vault_password

# Verify encryption worked
file secrets.yml  # Should show "ASCII text" not readable content

# Create README
cat > README.md << 'EOF'
# Vault: [Service]
[Use template from section 4.3]
EOF
```

---

### 6.2 Viewing Vault Contents

```bash
# View encrypted file
ansible-vault view vault/secrets.yml --vault-password-file vault/.vault_password

# Alternative: decrypt temporarily
ansible-vault decrypt vault/secrets.yml --vault-password-file vault/.vault_password
cat vault/secrets.yml
# Remember to re-encrypt!
ansible-vault encrypt vault/secrets.yml --vault-password-file vault/.vault_password
```

---

### 6.3 Editing Vault Contents

```bash
# Recommended: Use ansible-vault edit (auto-encrypts on save)
ansible-vault edit vault/secrets.yml --vault-password-file vault/.vault_password

# Manual method (not recommended)
ansible-vault decrypt vault/secrets.yml --vault-password-file vault/.vault_password
vim vault/secrets.yml
ansible-vault encrypt vault/secrets.yml --vault-password-file vault/.vault_password
```

---

### 6.4 Rotating Vault Password

```bash
# Re-key the vault with new password
echo "new-vault-password" > vault/.vault_password.new

ansible-vault rekey vault/secrets.yml \
  --vault-password-file vault/.vault_password \
  --new-vault-password-file vault/.vault_password.new

# Replace old password file
mv vault/.vault_password.new vault/.vault_password
chmod 600 vault/.vault_password

# Verify
ansible-vault view vault/secrets.yml --vault-password-file vault/.vault_password
```

---

## 7. Integration with Deployment

### 7.1 Deployment Workflow with Vaults

**Deployment follows this pattern**:

1. **Pre-deployment**: Load vault secrets
2. **Installation**: Use vault variables for configuration
3. **Configuration**: Generate .env from vault
4. **Verification**: Test with vault-provided credentials
5. **Post-deployment**: Secure .env file

**Example deployment task**:

```yaml
---
- name: Deploy [service]
  hosts: [node]
  vars_files:
    - vault/secrets.yml
  
  tasks:
    - name: Create service user
      user:
        name: "{{ service_account_username }}"
        password: "{{ service_account_password | password_hash('sha512') }}"
        shell: /bin/bash
    
    - name: Generate configuration
      template:
        src: templates/config.j2
        dest: /etc/[service]/config.yml
        mode: '0600'
        owner: "{{ service_account_username }}"
    
    - name: Generate .env
      template:
        src: templates/env.j2
        dest: /opt/[service]/.env
        mode: '0600'
        owner: "{{ service_account_username }}"
```

---

### 7.2 Environment File Best Practices

**.env files generated on target nodes**:

**Security Requirements**:
- ✅ Permissions: `0600` (owner read/write only)
- ✅ Owner: Service account (not root)
- ✅ Location: Service directory (e.g., `/opt/[service]/.env`)
- ✅ Generated from vault (never manually created)
- ✅ Never committed to Git

**Ansible template ensures security**:
```yaml
- name: Generate .env file
  template:
    src: templates/env.j2
    dest: /opt/[service]/.env
    mode: '0600'
    owner: "{{ service_account_username }}"
    group: "{{ service_account_username }}"
    backup: yes  # Keep one backup
```

---

## 8. Security Considerations

### 8.1 Development vs. Production Context

**Development Environment (current)**:
- ✅ Standard passwords acceptable
- ✅ Single vault password per service acceptable
- ✅ Vault password in plaintext file acceptable
- ✅ Internal network only

**Production Environment (future)**:
- ❌ Requires unique complex passwords per service
- ❌ Requires separate vault passwords
- ❌ Requires vault password from secure store (HashiCorp Vault, AWS Secrets Manager)
- ❌ Requires MFA for vault access
- ❌ Requires audit logging

---

### 8.2 Vault File Protection

**Encrypted vaults are safe BUT**:
- ⚠️ Vault password files are plaintext (git-ignored)
- ⚠️ Anyone with node access can decrypt if password file present
- ⚠️ Generated .env files on nodes are plaintext

**Mitigations**:
- ✅ Restrict node access (SSH key auth only)
- ✅ Limit sudo access
- ✅ .env files have 600 permissions
- ✅ Regular credential rotation
- ✅ Vault passwords not in Git
- ✅ Service-specific vault isolation

---

### 8.3 Git Repository Safety

**What CAN be committed to Git**:
- ✅ Encrypted vault files (`vault/secrets.yml` after encryption)
- ✅ Vault README files
- ✅ Deployment playbooks (use variables, not values)
- ✅ Templates (.j2 files with `{{ variables }}`)
- ✅ This standards document structure (with [REDACTED] placeholders)

**What CANNOT be committed to Git**:
- ❌ Vault password files (`.vault_password`)
- ❌ Unencrypted vault files
- ❌ .env files (plaintext secrets)
- ❌ Private keys, certificates
- ❌ This file with actual passwords filled in

**Critical .gitignore entries**:
```gitignore
# Vault passwords
.vault_password
vault_password
*.vault_pass

# Service vaults
services/**/vault/.vault_password
services/**/vault/secrets.yml.bak

# Node vaults  
nodes/**/vault/.vault_password
nodes/**/vault/secrets.yml.bak

# Environment files
.env
.env.*
*.env

# Private keys
*.key
*.pem
private/

# Credentials documentation with actual passwords
standards/credentials-vault-management.md
```

---

### 8.4 Credential Rotation Schedule

**Development Environment**:
- Service accounts: Quarterly (every 3 months)
- Admin accounts: Semi-annually
- API keys: Annually
- Certificates: Before expiration
- Vault passwords: Annually

**Rotation Process**:
1. Update vault with new credentials
2. Re-encrypt vault if changing vault password
3. Re-run deployment to update .env
4. Verify service still operational
5. Document rotation in vault README

---

## 9. Quick Reference

### 9.1 Common Commands

```bash
# Create new vault
ansible-vault create secrets.yml --vault-password-file .vault_password

# View vault
ansible-vault view secrets.yml --vault-password-file .vault_password

# Edit vault
ansible-vault edit secrets.yml --vault-password-file .vault_password

# Encrypt file
ansible-vault encrypt secrets.yml --vault-password-file .vault_password

# Decrypt file
ansible-vault decrypt secrets.yml --vault-password-file .vault_password

# Change vault password
ansible-vault rekey secrets.yml \
  --vault-password-file .vault_password \
  --new-vault-password-file .vault_password.new
```

---

### 9.2 Vault Checklist

**Before Creating New Service**:
- [ ] Create service directory structure
- [ ] Create `vault/` directory
- [ ] Generate `.vault_password` (add to .gitignore)
- [ ] Create `secrets.yml` with all required credentials
- [ ] Encrypt `secrets.yml` with ansible-vault
- [ ] Create `vault/README.md` documenting vault contents
- [ ] Test decryption works
- [ ] Verify .vault_password is git-ignored
- [ ] Document rotation schedule

**Before Deployment**:
- [ ] Verify vault can be decrypted
- [ ] Confirm all required secrets present in vault
- [ ] Check credentials match knowledge base docs (hx-knowledge/docs/)
- [ ] Test vault variables in playbook
- [ ] Verify .env generation template
- [ ] Confirm file permissions in deployment tasks

---

### 9.3 Password Management Summary

**Account Creation Rules**:

| Account Type | Where Created | Tool | Example |
|-------------|--------------|------|---------|
| Human Users | Samba AD | `samba-tool user create` | user@hx.dev.local |
| Administrators | Samba AD | `samba-tool user create` | admin@hx.dev.local |
| Service Accounts | Local | `useradd` | svc-database |
| System Accounts | OS/Package | Automatic | root, systemd-* |

**Password Patterns**:

| Account Type | Pattern | Example |
|-------------|---------|---------|
| Service Account | URL-safe, 16-32 chars, alphanumeric | Kp9mN2vR4xL8qW3y |
| Admin/User | 12+ chars, complex | P@ssw0rd!2024#Hx |

**Vault Structure**:

| Vault Type | Location | Contains |
|-----------|----------|----------|
| Service Vault | `services/*/vault/` | Service credentials, API keys, DB passwords |
| Node Vault | `nodes/*/vault/` | Node SSH keys, Samba AD join, system credentials |

---

### 9.4 Critical Reminders

**🔴 MUST READ BEFORE ANY DEPLOYMENT**:
- Consult `hx-knowledge/docs/0.0.5.2.1-credentials.md` for current passwords
- All human users MUST be in Samba AD (NO local accounts)
- Vault password files MUST be in .gitignore
- Generated .env files MUST have 0600 permissions
- This credentials document MUST NOT be committed to GitHub

**🔒 Security Principles**:
1. **Centralized Identity**: All humans in Samba AD
2. **Service Isolation**: One vault per service
3. **Single Source of Truth**: Knowledge base docs contain actual credentials
4. **Encrypted at Rest**: All vaults encrypted with Ansible Vault
5. **Secure in Transit**: Use vault variables in deployment
6. **Git Safety**: Never commit secrets to repository

---

**END OF DOCUMENT**
