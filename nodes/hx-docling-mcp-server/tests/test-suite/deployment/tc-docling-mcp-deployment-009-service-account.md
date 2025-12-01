# Test Case: Service Account Validation

**Test ID**: tc-docling-mcp-deployment-009
**Test Area**: Deployment Validation
**Priority**: MEDIUM
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify Samba AD service account docling-mcp@hx.dev.local exists and is properly configured.

---

## Test Steps

### Step 1: Verify Account Exists in Samba AD

**Action**:
```bash
wbinfo -i docling-mcp@hx.dev.local
```

**Expected**: Account information returned

---

### Step 2: Verify Account Can Authenticate

**Action**:
```bash
sudo su - docling-mcp -c "whoami"
```

**Expected**: Successfully switches to docling-mcp account

---

### Step 3: Verify Account in Domain Users Group

**Action**:
```bash
groups docling-mcp
```

**Expected**: "domain users" in group list

---

## Pass/Fail Criteria

**PASS**: Account exists, can authenticate, in correct groups

**FAIL**: Account missing or misconfigured

---

**Test Case Version**: 1.0
