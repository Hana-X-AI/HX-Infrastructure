# Credentials and Vault Management Standards
## Security Standards for HX-Infrastructure Credential and Vault Management

**Document Type:** Standard - Security & Credential Management (HIGHLY SENSITIVE)
**Version:** 1.1
**Date:** 2025-11-21
**Status:** ✅ APPROVED - CRITICAL SECURITY STANDARD - Required for All Deployments
**Location:** `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`
**Previous Version:** 1.0 → 1.1 (comprehensive metadata, infrastructure integration, procedure alignment)
**Classification:** 🔴 INTERNAL - DO NOT COMMIT TO GITHUB - CONTAINS SENSITIVE PATTERNS

---

## Document Purpose

This document establishes credentials and vault management standards for HX-Infrastructure, defining how secrets are stored, managed, and deployed across all services and nodes. This is a CRITICAL SECURITY document that must be protected.

### Target Audience
- **Frank Lucas (Security Specialist):** PRIMARY OWNER for security architecture and credential management
- **William Chen (Infrastructure Specialist):** Vault implementation and deployment integration
- **Agent Zero (CC):** Validates vault configuration during all 6 lifecycle phases
- **All Service Developers:** Must implement vault configuration following these standards
- **All Infrastructure Engineers:** Must manage credentials securely

### Scope
- Ansible Vault architecture and configuration
- Service vault structure and management
- Node vault structure and management
- Password standards and patterns
- Credential rotation procedures
- Git repository safety for secrets
- Integration with deployment procedures

### Authority
**Mandatory for all service deployments.** No service may be deployed without proper vault configuration. Credential management compliance is validated throughout all 6 lifecycle phases.

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

### 2.1 Centralized Ansible Vault Password

**⚠️ CRITICAL: Ansible Vault Configuration**

**🔴 SECURITY NOTICE**: The actual vault password must NEVER be committed to Git. Store it securely offline.

**Centralized Vault Password**: `[REDACTED - See secure offline documentation]`

**Location**: Centralized vault password file must be stored on secured admin hosts only:
- Example path: `/srv/ansible/.vault_password` (not tracked in Git)
- Backup required in secure offline location (encrypted, access-controlled)
- **NEVER commit the password file or actual password value to any repository**

**Backup Requirements for Password File**:
- ✅ Weekly backup of password file (encrypted)
- ✅ Store backups in secure offline location with access logging
- ✅ Verify backup integrity monthly
- ✅ Document backup location in **private, git-ignored runbook only**
- ✅ Encrypt backup media/archives with separate encryption key
- ✅ Maintain 3 generations of backups (weekly rotation)

**Usage**:
```bash
# All vault operations reference password file (never expose actual password)
ansible-vault view secrets.yml --vault-password-file /srv/ansible/.vault_password
ansible-vault edit secrets.yml --vault-password-file /srv/ansible/.vault_password
ansible-vault encrypt secrets.yml --vault-password-file /srv/ansible/.vault_password
```

**Security Notes**:
- This password protects all service and node vault files
- File permissions: `chmod 600 /srv/ansible/.vault_password`
- Owner: `root:root` or dedicated ansible automation user only
- **CRITICAL**: Actual password value stored in secure offline documentation (not in Git)
- Operational details documented in private runbook under `hx-knowledge/docs/` (git-ignored)

---

### 2.2 Two-Level Vault System

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

**Manual deployment pattern (allowed):**

```bash
# 1) Extract service user credentials from vault
usr=$(ansible-vault view services/[service]/vault/secrets.yml \
  --vault-password-file=/srv/ansible/.vault_password | \
  awk '/service_account_username:/{print $2}')

pwd=$(ansible-vault view services/[service]/vault/secrets.yml \
  --vault-password-file=/srv/ansible/.vault_password | \
  awk '/service_account_password:/{print $2}')

# 2) Create service user
sudo useradd -m -s /bin/bash "$usr"
echo "$usr:$pwd" | sudo chpasswd

# 3) Generate config from template (manual envsubst or sed)
export SERVICE_USER="$usr"
envsubst < templates/config.j2 > /tmp/config.yml
sudo install -m 0600 -o "$usr" /tmp/config.yml /etc/[service]/config.yml

# 4) Create .env with proper permissions
sudo install -m 0600 -o "$usr" /dev/null /opt/[service]/.env
echo "DB_PASSWORD=$pwd" | sudo tee -a /opt/[service]/.env > /dev/null

# 5) Verify permissions
ls -la /etc/[service]/config.yml /opt/[service]/.env
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

## Infrastructure Philosophy Integration

Credential management aligns with HX-Infrastructure deployment philosophy:

### Ansible Vault Philosophy

**From deployment-requirements.md (authoritative source):**
- ✅ **Ansible Vault ONLY:** All credentials stored in Ansible Vault (no alternative secret stores)
- ✅ **No Ansible Playbooks:** Vault used for storage ONLY, not for automation deployment
- ✅ **Manual Procedures:** Vault content extracted manually during deployment procedures
- ✅ **Systemd Integration:** Credentials from vault used in systemd unit files and .env files
- ✅ **Bare Metal Deployment:** Vault passwords stored on bare metal nodes (file-based)

**Ansible Usage Scope (Explicitly Allowed/Forbidden):**
- ✅ **ALLOWED:** `ansible-vault` CLI for encrypt/decrypt/view/edit operations
- ✅ **ALLOWED:** `ansible-vault view` to extract credentials during manual procedures
- ✅ **ALLOWED:** Vault file storage in repository (encrypted YAML files)
- ✅ **ALLOWED:** hx-control-node for centralized vault management
- ✅ **ALLOWED:** Inventory files for host tracking (documentation only, no automation)
- ❌ **FORBIDDEN:** `ansible-playbook` - No playbook execution for deployment
- ❌ **FORBIDDEN:** Ansible roles - No automation frameworks
- ❌ **FORBIDDEN:** `ansible` ad-hoc commands - No remote execution automation
- ❌ **FORBIDDEN:** `ansible-console` - No interactive automation
- ℹ️ **RATIONALE:** Ansible Vault = **storage tool only**. Manual deployment procedures maintain operational control and knowledge retention

### Vault Usage Pattern

**Correct Usage (Manual):**
```bash
# Extract credentials from vault manually
ansible-vault view services/[service]/vault/secrets.yml \
  --vault-password-file=/srv/ansible/.vault_password > /tmp/secrets.yml

# Manually create .env file from vault content
export DB_PASSWORD=$(grep db_password /tmp/secrets.yml | cut -d' ' -f2)
echo "DB_PASSWORD=$DB_PASSWORD" > /opt/service/.env
```

**Incorrect Usage (Automation - NOT ALLOWED):**
```bash
# ❌ DO NOT USE: Ansible playbook automation
ansible-playbook deploy.yml --vault-password-file .vault_password
```

### Procedure Alignment

Credential management is integrated across all 6 lifecycle phases:

**Phase 0 (Project Initiation):**
- Initial feasibility includes credential requirements assessment
- Service account naming planned
- Vault structure planned

**Phase 2 (Specification Development):**
- spec.md documents credential requirements
- plan.md documents vault structure
- Vault creation planned in deployment tasks

**Phase 3 (Task Breakdown & Testing):**
- Task files include vault creation tasks
- Task files include credential generation tasks
- Task files include .env file creation from vault
- No Ansible playbook tasks (manual procedures only)

**Phase 4 (Task Execution):**
- Vault created following vault structure standards
- Credentials generated following password patterns
- Vault encrypted with centralized vault password
- Credentials extracted manually for deployment

**Phase 5 (Project Closeout):**
- Vault documented in service README
- Credential rotation schedule documented
- Vault backup procedures validated

---

## Related Documents

### Standards
- **`/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`** - Infrastructure philosophy AUTHORITATIVE source, Ansible Vault philosophy
- **`/home/agent0/HX-Infrastructure/standards/architecture-standards.md`** - Security architecture requirements
- **`/home/agent0/HX-Infrastructure/standards/documentation-requirements.md`** - Vault documentation requirements
- **`/home/agent0/HX-Infrastructure/standards/naming-conventions.md`** - Service account naming conventions

### Procedures (Lifecycle Integration)
- **`/home/agent0/HX-Infrastructure/procedures/node-deployment-workflow.md`** - Phase 0: Project initiation with credential planning
- **`/home/agent0/HX-Infrastructure/procedures/spec-workflow.md`** - Phase 2: Credential requirements specification
- **`/home/agent0/HX-Infrastructure/procedures/task-workflow.md`** - Phase 3: Vault creation task breakdown
- **`/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md`** - Phase 4: Manual vault operations during deployment

### Knowledge Base Documents (🔴 CRITICAL - CONTAINS ACTUAL PASSWORDS)
- **`/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.0-readme.md`** - 🔴 MUST READ - Credentials index
- **`/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md`** - 🔴 MUST READ - Actual passwords SOURCE OF TRUTH
- **`/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.2-url-safe-password-pattern.md`** - 🔴 MUST READ - Password patterns

### Commands
- **`/cc-agent-zero-orchestrator`** - Validates vault configuration across all phases
- **`/cc-frank-security-specialist`** - Security architecture and credential management PRIMARY OWNER
- **`/cc-william-infra-specialist`** - Vault implementation validation

### Governance Documents
- **`/home/agent0/HX-Infrastructure/constitution.md`** - Security and compliance principles
- **`.gitignore`** - Vault password and credential exclusion patterns

### Agent Profiles
- **Frank Lucas (Security Specialist):** PRIMARY OWNER for security architecture, credential management, vault standards
- **William Chen (Infrastructure Specialist):** Vault implementation and deployment integration
- **Agent Zero (CC):** STATEFUL orchestrator validating vault configuration across all 5 phases

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-15 | Initial credential and vault management standards with comprehensive vault structure | 894 lines | HX-Infrastructure Team + Frank Lucas |
| 1.1 | 2025-11-21 | Added comprehensive metadata, infrastructure philosophy integration (Ansible Vault only, no playbooks), procedure alignment, expanded related documents, version history, document maintenance | +150 lines (est.) | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added comprehensive document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose section emphasizing CRITICAL SECURITY STANDARD
- Added Infrastructure Philosophy Integration section (Ansible Vault ONLY, no playbooks, manual procedures)
- Added Vault Usage Pattern section (correct manual usage vs incorrect automation)
- Added Procedure Alignment section (vault management across all 5 phases)
- Expanded related documents section with comprehensive standards, procedures, knowledge base, commands, governance, agents
- Added version history table (this table)
- Added document maintenance section
- Maintained 100% backward compatibility with v1.0

**Backward Compatibility:** 100% - All v1.0 credential and vault requirements unchanged, only infrastructure philosophy explicit documentation and metadata enhancements added

---

## Document Maintenance

### Update Triggers
This document should be updated when:
- Infrastructure philosophy credential requirements change
- New vault structure patterns emerge
- Password standards updated
- Credential rotation policies change
- New security tools integrated (future: HashiCorp Vault, cloud secret managers)
- Knowledge base credential documentation structure changes
- Samba AD authentication changes
- Git safety patterns updated

### Review Frequency
- **Quarterly Review:** Frank Lucas reviews credential management effectiveness and security posture
- **Post-Incident Review:** After security incidents, review credential management procedures
- **Annual Security Audit:** Comprehensive review of vault passwords, credential rotation, access controls
- **Continuous Monitoring:** Agent Zero validates vault configuration in all deployments

### Compliance Enforcement
- **Phase 2:** Agent Zero validates vault structure in spec.md and plan.md
- **Phase 3:** Agent Zero validates vault creation tasks follow manual procedure patterns (no ansible-playbook usage)
- **Phase 4:** Frank Lucas validates vault encryption and credential security during deployment
- **Phase 5:** CAIO validates complete vault documentation before operational promotion
- **Blocking Issue:** Missing or improperly configured vault PREVENTS operational promotion

**Ansible Usage Enforcement:**
- ✅ **Vault CLI usage validated:** All procedures use `ansible-vault` commands for encrypt/decrypt/view/edit
- ❌ **Playbook usage blocked:** Any `ansible-playbook`, `ansible`, or `ansible-console` commands in deployment procedures FAIL validation
- ✅ **Manual extraction required:** All vault content extraction must be manual bash procedures, not automated playbooks
- ✅ **hx-control-node allowed:** Centralized vault management on control node (storage/editing only, no automation execution)

### Change Control
- Changes to vault password standards require Frank Lucas security review
- Changes to vault structure require template updates
- Changes to Ansible Vault usage require infrastructure philosophy review
- All changes maintain 100% backward compatibility or include migration procedures for existing vaults
- Version increments: Minor for enhancements, Major for breaking changes (requires security justification)

### Security Maintenance
- **Vault Password Rotation:** Annually or after security incident
- **Credential Rotation:** Quarterly for service accounts, semi-annually for admin accounts
- **Access Review:** Quarterly review of who has access to vault passwords
- **Backup Verification:** Monthly verification of /srv/ansible/ backups
- **Git Safety Audit:** Quarterly audit of .gitignore effectiveness

---

**END OF DOCUMENT**
**Version:** 1.1
**Last Updated:** 2025-11-21
**Security Classification:** 🔴 INTERNAL - DO NOT COMMIT TO GITHUB
