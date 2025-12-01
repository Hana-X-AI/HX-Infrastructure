# Test Case: Systemd Service Unit Validation

**Test ID**: tc-docling-mcp-deployment-005
**Test Area**: Deployment Validation
**Priority**: CRITICAL
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify systemd service unit file is correctly configured with proper dependencies, restart policies, and security settings.

---

## Test Coverage

**Requirements Covered**:
- DR-004: Systemd service configured
- Plan Section: Systemd Service Unit (lines 517-556)

---

## Test Steps

### Step 1: Verify Unit File Exists and Loaded

**Action**:
```bash
test -f /etc/systemd/system/docling-mcp.service && echo "PASS: unit file exists"
systemctl cat docling-mcp.service
systemctl list-unit-files | grep docling-mcp
```

**Expected**: Unit file exists and loaded by systemd

---

### Step 2: Verify Unit File Content

**Action**:
```bash
# Check Description
grep -q "Description=Docling MCP Server" /etc/systemd/system/docling-mcp.service && echo "PASS: Description set"

# Check After directive (network-online.target ONLY per specification)
grep -q "After=network-online.target" /etc/systemd/system/docling-mcp.service && echo "PASS: After directive correct"

# Verify NO cross-node dependencies (specification line 4592)
grep -q "Requires=" /etc/systemd/system/docling-mcp.service && echo "FAIL: Requires directive found (should not exist)" || echo "PASS: No Requires directive"
```

**Expected**: Correct After directive, NO Requires directive

---

### Step 3: Verify Service Account Configuration

**Action**:
```bash
# Check User directive
grep -q "User=docling-mcp" /etc/systemd/system/docling-mcp.service && echo "PASS: User set"

# Check Group directive
grep -q "Group=domain users" /etc/systemd/system/docling-mcp.service && echo "PASS: Group set"
```

**Expected**: Service runs as docling-mcp@hx.dev.local (Samba AD account)

---

### Step 4: Verify Restart Policy

**Action**:
```bash
# Check Restart directive
grep -q "Restart=on-failure" /etc/systemd/system/docling-mcp.service && echo "PASS: Restart policy set"

# Check RestartSec
grep -q "RestartSec=10" /etc/systemd/system/docling-mcp.service && echo "PASS: RestartSec configured"
```

**Expected**: Restart on failure with 10-second delay

---

### Step 5: Verify Environment Configuration

**Action**:
```bash
# Check EnvironmentFile
grep -q "EnvironmentFile=/etc/docling-mcp/.env" /etc/systemd/system/docling-mcp.service && echo "PASS: EnvironmentFile set"

# Check WorkingDirectory
grep -q "WorkingDirectory=/opt/docling-mcp" /etc/systemd-mcp.service && echo "PASS: WorkingDirectory set"
```

**Expected**: Environment file and working directory configured

---

### Step 6: Verify Security Hardening

**Action**:
```bash
# Check security directives
grep -q "PrivateTmp=true" /etc/systemd/system/docling-mcp.service && echo "PASS: PrivateTmp enabled"
grep -q "NoNewPrivileges=true" /etc/systemd/system/docling-mcp.service && echo "PASS: NoNewPrivileges enabled"
grep -q "ProtectSystem=strict" /etc/systemd/system/docling-mcp.service && echo "PASS: ProtectSystem enabled"
```

**Expected**: Security hardening directives present

---

### Step 7: Verify Service Enabled

**Action**:
```bash
systemctl is-enabled docling-mcp.service
```

**Expected Result**: `enabled`

**Pass Criteria**: Service is enabled to start on boot

---

## Pass/Fail Criteria

**PASS**: All unit file directives correct, service enabled

**FAIL**: Any directive missing or incorrect, service not enabled

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-critical-005-systemd-misconfigured.md`

---

**Test Case Version**: 1.0
