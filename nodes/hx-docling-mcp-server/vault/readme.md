# Ansible Vault Credentials

## Overview

This directory contains Ansible Vault encrypted credentials for hx-docling-mcp-server (192.168.10.217).

## Files

| File | Purpose | Status |
|------|---------|--------|
| `credentials.yml` | Encrypted service account credentials | ✅ Encrypted with Ansible Vault AES256 |
| `.vault_password` | Vault decryption password | ⚠️ Git-ignored, server-only file |

## Credentials Structure

The `credentials.yml` file contains:

```yaml
samba_account: "docling-mcp@hx.dev.local"
samba_password: "[ENCRYPTED]"
samba_domain: "hx.dev.local"
account_created: "2025-11-27"
account_purpose: "Docling MCP Server systemd service account"
group_membership:
  - "domain users@hx.dev.local"
password_never_expires: true
must_change_at_next_login: false
account_expires: never
```

## Usage

### View Credentials (Local)

```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server
ansible-vault view vault/credentials.yml --vault-password-file=vault/.vault_password
```

### View Credentials (Server)

```bash
# On hx-docling-mcp-server (192.168.10.217)
sudo cat /opt/docling-mcp/vault/.vault_password  # View vault password
# Ansible-vault not installed on server - application reads password file directly
```

### Edit Credentials

```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server
ansible-vault edit vault/credentials.yml --vault-password-file=vault/.vault_password
```

### Re-encrypt with New Password

```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server
ansible-vault rekey vault/credentials.yml --vault-password-file=vault/.vault_password --new-vault-password-file=/path/to/new/password
```

## Security

- **Vault Password**: Standard HX-Infrastructure password (documented in credentials standards)
- **File Permissions**: 600 (read/write owner only)
- **Owner**: `docling-mcp:domain users` on server
- **Git**: `.vault_password` is git-ignored (never committed to repository)
- **Encryption**: AES256 via Ansible Vault 1.1

## Deployment

### Initial Deployment

```bash
# Copy vault password to server (one-time)
scp vault/.vault_password agent0@192.168.10.217:/tmp/.vault_password_temp
ssh agent0@192.168.10.217 'sudo mv /tmp/.vault_password_temp /opt/docling-mcp/vault/.vault_password && sudo chown docling-mcp:domain\ users /opt/docling-mcp/vault/.vault_password && sudo chmod 600 /opt/docling-mcp/vault/.vault_password'

# Copy encrypted credentials
scp vault/credentials.yml agent0@192.168.10.217:/tmp/credentials.yml_temp
ssh agent0@192.168.10.217 'sudo mv /tmp/credentials.yml_temp /opt/docling-mcp/vault/credentials.yml && sudo chown docling-mcp:domain\ users /opt/docling-mcp/vault/credentials.yml && sudo chmod 600 /opt/docling-mcp/vault/credentials.yml'
```

### Update Credentials

```bash
# Edit credentials locally
ansible-vault edit vault/credentials.yml --vault-password-file=vault/.vault_password

# Deploy updated file
scp vault/credentials.yml agent0@192.168.10.217:/tmp/credentials.yml_new
ssh agent0@192.168.10.217 'sudo mv /tmp/credentials.yml_new /opt/docling-mcp/vault/credentials.yml && sudo chown docling-mcp:domain\ users /opt/docling-mcp/vault/credentials.yml && sudo chmod 600 /opt/docling-mcp/vault/credentials.yml'
```

## Troubleshooting

### Decryption Fails

```bash
# Verify vault password is correct
cat vault/.vault_password
# Should contain: Major8859!

# Try decrypting with explicit password
echo "Major8859!" | ansible-vault view vault/credentials.yml --vault-password-file=/dev/stdin
```

### Permission Denied

```bash
# On server, check file permissions
ssh agent0@192.168.10.217 'sudo ls -la /opt/docling-mcp/vault/'
# Should show: -rw------- docling-mcp domain users

# Fix permissions if needed
ssh agent0@192.168.10.217 'sudo chown docling-mcp:domain\ users /opt/docling-mcp/vault/.vault_password /opt/docling-mcp/vault/credentials.yml && sudo chmod 600 /opt/docling-mcp/vault/.vault_password /opt/docling-mcp/vault/credentials.yml'
```

## References

- **Credentials Standards**: `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md`
- **Service Account**: Created via TASK-001 (Create Samba AD Service Account)
- **Server Location**: `hx-docling-mcp-server.hx.dev.local` (192.168.10.217)
- **Vault Location**: `/opt/docling-mcp/vault/`

---

**Last Updated**: 2025-11-30
**Maintainer**: HX-Infrastructure Team
