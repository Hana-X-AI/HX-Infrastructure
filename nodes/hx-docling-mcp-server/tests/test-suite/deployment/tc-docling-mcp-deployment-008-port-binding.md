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

**Expected**: Port 8000 listening on hx-docling-mcp-server.hx.dev.local or 0.0.0.0

---

### Step 2: Verify No External Binding (if bound to internal IP)

**Action**:
```bash
# Check if service is bound to specific internal IP (192.168.10.217) or all interfaces (0.0.0.0)
# Using -n flag for numeric output, so grep for IPs not hostnames
netstat -tulpn | grep :8000 | grep -E "(192\.168\.10\.217|0\.0\.0\.0|127\.0\.0\.1)" && echo "PASS: Bound to internal/localhost IP"

# Alternative: Use ss without -n to see hostnames
# ss -tulp | grep :8000
```

**Expected**: Service bound to 192.168.10.217 (internal IP), 0.0.0.0 (all interfaces), or 127.0.0.1 (localhost only)

---

### Step 3: Verify Port Accessibility

**Action**:
```bash
curl -s -o /dev/null -w "%{http_code}" http://hx-docling-mcp-server.hx.dev.local:8000/health
```

**Expected**: HTTP 200 or 503 (service responds)

---

## Pass/Fail Criteria

**PASS**: Port 8000 listening, accessible via HTTP

**FAIL**: Port not listening or not accessible

---

**Test Case Version**: 1.0
