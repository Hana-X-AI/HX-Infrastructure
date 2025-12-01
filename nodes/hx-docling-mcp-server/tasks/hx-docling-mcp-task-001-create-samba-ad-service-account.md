# Task 001: Create Samba AD Service Account

**Task ID**: hx-docling-mcp-task-001
**Category**: Pre-Deployment / Identity & Access
**Assigned To**: frank-lucas (Security Specialist - Samba AD integration)
**Status**: PENDING
**Priority**: HIGH (Blocker for deployment)
**Created**: 2025-11-27
**Estimated Effort**: 15 minutes

---

## Task Description

Create Samba AD service account `docling-mcp@hx.dev.local` with standard HX-Infrastructure service account configuration. This account will be used by the systemd service to run the Docling MCP Server process with proper domain authentication and file access permissions.

---

## Prerequisites

- [ ] Samba AD Domain Controllers operational (hx-dc1-server, hx-dc2-server)
- [ ] Administrator credentials available for AD account creation
- [ ] Computer account `docling-mcp$` created in Servers/Infrastructure OU
- [ ] DNS A record `hx-docling-mcp-server.hx.dev.local` → `192.168.10.217` configured

---

## Acceptance Criteria

- [ ] Service account `docling-mcp@hx.dev.local` created in Samba AD
- [ ] Password stored in Ansible Vault at `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml`
- [ ] Account added to `domain users@hx.dev.local` group
- [ ] Account enabled and replicated across DC1 and DC2
- [ ] Account verification successful via `wbinfo -i docling-mcp@hx.dev.local`

---

## Detailed Procedure

### Step 1: Create Service Account in Samba AD

**Coordinate with**: frank-lucas (Security Specialist)

**Commands to execute on Domain Controller** (hx-dc1-server):

```bash
# Connect to DC1
ssh administrator@hx-dc1-server.hx.dev.local

# Create service account
# Note: Password retrieved from Ansible Vault (vault/credentials.yml)
samba-tool user create docling-mcp@hx.dev.local "<PASSWORD_FROM_VAULT>" \
  --description="Docling MCP Server Service Account" \
  --must-change-at-next-login=no \
  --password-never-expires=yes

# Add to domain users group
samba-tool group addmembers "domain users" docling-mcp

# Set account properties
samba-tool user setexpiry docling-mcp --noexpiry

# Verify account creation
samba-tool user show docling-mcp
```

**Expected Output**:
```
dn: CN=docling-mcp,CN=Users,DC=hx,DC=dev,DC=local
cn: docling-mcp
samAccountName: docling-mcp
userPrincipalName: docling-mcp@hx.dev.local
memberOf: CN=domain users,CN=Users,DC=hx,DC=dev,DC=local
accountExpires: 9223372036854775807
userAccountControl: 66048
```

### Step 2: Verify Account Replication

**Verify replication to DC2**:

```bash
# Connect to DC2
ssh administrator@hx-dc2-server.hx.dev.local

# Verify account replicated
samba-tool user show docling-mcp

# Verify group membership
samba-tool group listmembers "domain users" | grep docling-mcp
```

**Expected Output**: Account details match DC1

### Step 3: Test Account Authentication

**From hx-docling-mcp-server node**:

```bash
# Verify account resolution via SSSD (if configured)
id docling-mcp@hx.dev.local

# Expected output:
# uid=123456(docling-mcp@hx.dev.local) gid=10513(domain users@hx.dev.local)

# Verify account via wbinfo
wbinfo -i docling-mcp@hx.dev.local

# Expected output:
# docling-mcp@hx.dev.local:*:123456:10513::/home/docling-mcp@hx.dev.local:/bin/bash

# Test Kerberos authentication
kinit docling-mcp@hx.dev.local
# Password: <retrieve from vault/credentials.yml>

# Verify ticket
klist

# Expected output:
# Ticket cache: FILE:/tmp/krb5cc_1000
# Default principal: docling-mcp@HX.DEV.LOCAL
# Valid starting     Expires            Service principal
# ...
```

### Step 4: Store Credentials in Ansible Vault

**Create Ansible Vault file**:

```bash
# Create vault directory
mkdir -p /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault

# Create credentials file
cat > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml <<'EOF'
---
# Ansible Vault encrypted credentials for Docling MCP Server
# Service Account Credentials

samba_account: "docling-mcp@hx.dev.local"
samba_password: "<ENCRYPTED_PASSWORD>"  # Encrypted by ansible-vault
samba_domain: "hx.dev.local"

# Account Details
account_created: "2025-11-27"
account_purpose: "Docling MCP Server systemd service account"
group_membership:
  - "domain users@hx.dev.local"

# Password Policy
password_never_expires: true
must_change_at_next_login: false
account_expires: never
EOF

# Create vault password file (store securely)
echo "your_vault_password_here" > /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password
chmod 600 /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password

# Encrypt credentials file
ansible-vault encrypt \
  /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml \
  --vault-password-file /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password

# Verify encryption
file /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
# Expected: ASCII text (encrypted)

# Test decryption
ansible-vault view \
  /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml \
  --vault-password-file /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password
```

### Step 5: Update Inventory Documentation

**Update node specification** with service account details:

```bash
# Edit node specification (if exists)
# /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/node-spec.md

# Add service account section:
## Service Account
- **Account**: docling-mcp@hx.dev.local
- **Group**: domain users@hx.dev.local
- **Purpose**: Docling MCP Server systemd service
- **Password Management**: Ansible Vault
- **Created**: 2025-11-27
```

---

## Validation

### Validation Commands

```bash
# 1. Verify account exists in AD
samba-tool user show docling-mcp

# 2. Verify account resolution
id docling-mcp@hx.dev.local

# 3. Verify wbinfo resolution
wbinfo -i docling-mcp@hx.dev.local

# 4. Test authentication
echo "[SEE VAULT: vault/credentials.yml]" | kinit docling-mcp@hx.dev.local

# 5. Verify Ansible Vault
ansible-vault view \
  /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml \
  --vault-password-file /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password
```

### Success Criteria

- ✅ Account `docling-mcp@hx.dev.local` exists in AD
- ✅ Account resolves via `id` command
- ✅ Account resolves via `wbinfo`
- ✅ Authentication successful with `kinit`
- ✅ Credentials encrypted in Ansible Vault
- ✅ Vault decryption successful

---

## Rollback Procedure

**If account creation fails or needs removal**:

```bash
# Remove service account
samba-tool user delete docling-mcp

# Remove Ansible Vault files
rm -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/credentials.yml
rm -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault/.vault_password
rmdir /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/vault
```

---

## Dependencies

**Blocks**:
- Task 005: Install system dependencies (needs service account for ownership)
- Task 007: Set file ownership and permissions (requires service account)
- Task 010: Configure systemd service (User= directive requires account)

**Depends On**:
- Samba AD Domain Controllers operational
- DNS A record configured
- Computer account created

---

## Notes

### Samba AD Integration

**Standard HX-Infrastructure Service Account Configuration**:
- Password: Stored in Ansible Vault (`vault/credentials.yml`)
- Password never expires: YES
- Account never expires: YES
- Must change at next login: NO
- Group membership: `domain users@hx.dev.local`

### SSSD Integration (Optional)

If SSSD not configured on hx-docling-mcp-server, **fallback to local account**:

```bash
# Create local service account as fallback
sudo useradd -r -s /bin/bash -d /opt/docling-mcp -m docling-mcp-local

# Update systemd service to use local account:
# User=docling-mcp-local
# Group=docling-mcp-local
```

### Security Considerations

- ✅ Credentials never stored in plain text (Ansible Vault only)
- ✅ Vault password file permissions: 600 (owner read/write only)
- ✅ Service account has no interactive login (service use only)
- ✅ Account limited to systemd service execution (no shell access)

---

## References

- **Configuration Spec**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/configuration-spec.md` (Section 8: Samba AD Integration)
- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 004)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
- **Standards**: `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
