# Test Case: Verify Service Starts Successfully

**Test ID**: tc-docling-mcp-deployment-004
**Test Area**: Deployment Validation
**Priority**: CRITICAL
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify the Docling MCP Server starts successfully via systemd and enters active/running state.

---

## Test Coverage

**Requirements Covered**:
- DR-004: Systemd service configured
- NFR-009: Service MUST auto-restart on crash via systemd

---

## Test Steps

### Step 1: Start Service

**Action**:
```bash
sudo systemctl start docling-mcp.service
sleep 5  # Allow startup time
```

---

### Step 2: Verify Service Status

**Action**:
```bash
systemctl status docling-mcp.service
systemctl is-active docling-mcp.service
```

**Expected Result**:
```
● docling-mcp.service - Docling MCP Server
   Loaded: loaded
   Active: active (running)
   Main PID: [process_id]
```

**Pass Criteria**: Status shows "active (running)"

---

### Step 3: Verify Process Running

**Action**:
```bash
ps aux | grep "docling_mcp.server" | grep -v grep
pgrep -f "docling_mcp"
```

**Expected**: Process running with correct command line

---

### Step 4: Verify Port Listening

**Action**:
```bash
sudo netstat -tulpn | grep :8000
curl -s http://192.168.10.217:8000/health
```

**Expected**: Port 8000 listening, health endpoint responds

---

## Pass/Fail Criteria

**PASS**: Service active, process running, port 8000 listening

**FAIL**: Service fails to start or exits immediately

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-critical-004-service-start-failure.md`, assign to william-chen

---

**Test Case Version**: 1.0
