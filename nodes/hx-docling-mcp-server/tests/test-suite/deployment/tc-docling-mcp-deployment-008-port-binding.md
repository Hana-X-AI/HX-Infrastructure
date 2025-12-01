# Test Case: Port Binding Validation

**Test ID**: tc-docling-mcp-deployment-008
**Test Area**: Deployment Validation  
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify service binds to correct ports (8000 HTTP, 8443 HTTPS if configured) and only to internal interface.

---

## Test Steps

### Step 1: Verify Port 8000 Listening

**Action**:
```bash
sudo netstat -tulpn | grep :8000
sudo lsof -i :8000
```

**Expected**: Port 8000 listening on 192.168.10.217 or 0.0.0.0

---

### Step 2: Verify No External Binding (if bound to internal IP)

**Action**:
```bash
# If configuration specifies internal-only binding to 192.168.10.217
netstat -tulpn | grep :8000 | grep "192.168.10.217" && echo "PASS: Bound to internal IP"
```

**Expected**: Service bound to 192.168.10.217 (internal network only)

---

### Step 3: Verify Port Accessibility

**Action**:
```bash
curl -s -o /dev/null -w "%{http_code}" http://192.168.10.217:8000/health
```

**Expected**: HTTP 200 or 503 (service responds)

---

## Pass/Fail Criteria

**PASS**: Port 8000 listening, accessible via HTTP

**FAIL**: Port not listening or not accessible

---

**Test Case Version**: 1.0
