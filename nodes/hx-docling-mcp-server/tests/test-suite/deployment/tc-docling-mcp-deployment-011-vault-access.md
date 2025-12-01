# Test Case: Ansible Vault Access Validation

**Test ID**: tc-docling-mcp-deployment-011
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify Ansible Vault credentials file is accessible and contains required secrets.

---

## Test Coverage

**Requirements Covered**:
- DR-006: Ansible Vault accessible
- NFR-012: Service MUST store credentials in Ansible Vault

---

## Test Steps

### Step 1: Verify Vault File Exists and Encrypted

**Action**:
```bash
test -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml && echo "PASS: vault file exists"
head -1 /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml | grep -q "\$ANSIBLE_VAULT" && echo "PASS: vault encrypted"
```

**Expected**: File exists and is Ansible Vault encrypted

---

### Step 2: Verify Vault Password File Exists

**Action**:
```bash
test -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/.vault_password && echo "PASS: vault password file exists"
stat -c "%a" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/.vault_password
```

**Expected**: Password file exists with 600 permissions

---

### Step 3: Verify Vault Can Be Decrypted

**Action**:
```bash
ansible-vault view /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml \
  --vault-password-file=/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/.vault_password | head -5
```

**Expected**: Vault decrypts successfully, shows YAML content

---

### Step 4: Verify Required Secrets Present

**Action**:
```bash
ansible-vault view /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml \
  --vault-password-file=/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/.vault_password | \
  grep -q "litellm_api_key" && echo "PASS: litellm_api_key present"
  
ansible-vault view /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml \
  --vault-password-file=/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/.vault_password | \
  grep -q "samba_account" && echo "PASS: samba_account present"
```

**Expected**: Required secrets (litellm_api_key, redis_password if auth enabled, samba_account) present

---

## Pass/Fail Criteria

**PASS**: Vault file encrypted, accessible, contains all required secrets

**FAIL**: Vault missing, cannot decrypt, or secrets missing

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-011-vault-inaccessible.md`

---

**Test Case Version**: 1.0
