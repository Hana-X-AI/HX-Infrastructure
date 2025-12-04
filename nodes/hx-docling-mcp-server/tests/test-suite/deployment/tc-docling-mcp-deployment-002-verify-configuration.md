# Test Case: Verify Configuration Files

**Test ID**: tc-docling-mcp-deployment-002
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify all configuration files are created, properly formatted, and contain required settings for Docling MCP Server operation.

---

## Prerequisites

- Task 008 (Configure Environment Files) executed
- Task 010 (Configure environment files - TBD) executed
- SSH access to hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)

---

## Test Coverage

**Requirements Covered**:
- DR-002: Configuration files created
- NFR-015: Service MUST use configuration management
- Plan Section: Configuration Specification (lines 427-595)

---

## Test Steps

### Step 1: Verify Primary Environment File

**Action**:
```bash
# Check .env file exists
test -f /etc/docling-mcp/.env && echo "PASS: .env exists" || echo "FAIL: .env missing"

# Check file permissions (must be 0600 for security)
stat -c "%a" /etc/docling-mcp/.env
test "$(stat -c '%a' /etc/docling-mcp/.env)" = "600" && echo "PASS: .env permissions correct" || echo "FAIL: .env permissions wrong"

# Verify required environment variables present
grep -q "SERVICE_NAME=docling-mcp" /etc/docling-mcp/.env && echo "PASS: SERVICE_NAME set"
grep -q "LITELLM_BASE_URL=http://hx-litellm-server.hx.dev.local:4000" /etc/docling-mcp/.env && echo "PASS: LITELLM_BASE_URL set"
grep -q "QDRANT_HOST=hx-qdrant-server.hx.dev.local" /etc/docling-mcp/.env && echo "PASS: QDRANT_HOST set"
grep -q "REDIS_HOST=hx-redis-server.hx.dev.local" /etc/docling-mcp/.env && echo "PASS: REDIS_HOST set"
```

**Expected Result**:
- File exists at `/etc/docling-mcp/.env`
- Permissions: 600 (owner read/write only)
- All required variables present

**Pass Criteria**: All checks PASS

---

### Step 2: Verify Ansible Vault Credentials File

**Action**:
```bash
# Check vault file exists
test -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml && echo "PASS: vault exists"

# Verify vault is encrypted (should show "Vault" in header)
head -1 /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/configuration/vault/credentials.yml | grep -q "ANSIBLE_VAULT" && echo "PASS: vault encrypted"
```

**Expected Result**:
- Vault file exists
- File is encrypted (starts with $ANSIBLE_VAULT)

**Pass Criteria**: Both checks PASS

---

### Step 3: Verify pytest Configuration

**Action**:
```bash
# Check pytest.ini exists
test -f /opt/docling-mcp/pytest.ini && echo "PASS: pytest.ini exists"

# Verify coverage threshold >=95%
grep -q "cov-fail-under=95" /opt/docling-mcp/pytest.ini && echo "PASS: coverage threshold set"
```

**Expected Result**:
- pytest.ini exists with coverage threshold >=95%

**Pass Criteria**: Coverage threshold configured correctly

---

### Step 4: Verify Logging Configuration

**Action**:
```bash
# Check logging config exists
test -f /etc/docling-mcp/logging.conf && echo "PASS: logging.conf exists"

# Verify log directory configured
grep -q "/var/log/docling-mcp" /etc/docling-mcp/logging.conf && echo "PASS: log directory configured"
```

**Expected Result**:
- logging.conf exists with correct log directory

**Pass Criteria**: Logging configured

---

## Pass/Fail Criteria

**PASS**: All configuration files present with correct permissions and required settings

**FAIL**: Any file missing or incorrectly configured

**BLOCKED**: Cannot access configuration directories

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-002-configuration-incomplete.md`, assign to william-chen

---

**Test Case Version**: 1.0
