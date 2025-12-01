# Test Case: File Permissions and Ownership

**Test ID**: tc-docling-mcp-deployment-007
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify all files and directories have correct ownership and permissions per security requirements.

---

## Test Coverage

**Requirements Covered**:
- DR-005: Filesystem layout correct
- NFR-013: Service MUST NOT log sensitive data

---

## Test Steps

### Step 1: Verify Application Directory Ownership

**Action**:
```bash
ls -ld /opt/docling-mcp
stat -c "%U:%G %a" /opt/docling-mcp
```

**Expected**: Owner: docling-mcp@hx.dev.local or docling-mcp-local, Permissions: 755

---

### Step 2: Verify .env File Permissions (Security Critical)

**Action**:
```bash
stat -c "%a %U" /etc/docling-mcp/.env
test "$(stat -c '%a' /etc/docling-mcp/.env)" = "600" && echo "PASS: .env is 600" || echo "FAIL: .env permissions wrong"
```

**Expected**: Permissions 600 (owner read/write only), owned by docling-mcp

**Pass Criteria**: MUST be 600, MUST NOT be world-readable

---

### Step 3: Verify Data Directory Writability

**Action**:
```bash
sudo -u docling-mcp touch /var/lib/docling-mcp/cache/test-write.tmp
sudo -u docling-mcp rm /var/lib/docling-mcp/cache/test-write.tmp
```

**Expected**: Service account can write to cache directory

---

### Step 4: Verify Log Directory Writability

**Action**:
```bash
sudo -u docling-mcp touch /var/log/docling-mcp/test-write.log
sudo -u docling-mcp rm /var/log/docling-mcp/test-write.log
```

**Expected**: Service account can write to log directory

---

## Pass/Fail Criteria

**PASS**: All ownership correct, .env file is 600, service account can write to data/log directories

**FAIL**: Any permission or ownership incorrect

**CRITICAL FAIL**: .env file is world-readable (creates security vulnerability)

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-007-permissions-incorrect.md`
**IF CRITICAL FAIL**: Create `defect-docling-mcp-critical-007-env-exposed.md` (security issue)

---

**Test Case Version**: 1.0
