# Test Case: Resource Usage Validation

**Test ID**: tc-docling-mcp-health-002
**Test Area**: Health Check Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify service resource usage is within acceptable limits.

---

## Test Coverage

**Requirements Covered**:
- Plan Section: Resource Targets (lines 48-52)
- Charter: Resource allocation (CPU 2-4 cores, RAM 4-8GB)

---

## Test Steps

### Step 1: Check CPU Usage

**Action**:
```bash
# Get docling-mcp process CPU usage
top -b -n 1 | grep docling_mcp | awk '{print "CPU: " $9 "%"}'
ps aux | grep docling_mcp | grep -v grep | awk '{print "CPU: " $3 "%"}'
```

**Expected**: CPU usage < 400% (4 cores maximum)

**Pass Criteria**: CPU usage within limits

---

### Step 2: Check Memory Usage

**Action**:
```bash
# Get docling-mcp process memory usage
ps aux | grep docling_mcp | grep -v grep | awk '{print "MEM: " $4 "% (RSS: " $6 " KB)"}'

# Calculate actual memory in GB
ps aux | grep docling_mcp | grep -v grep | awk '{print $6/1024/1024 " GB"}'
```

**Expected**: Memory usage < 8GB

**Pass Criteria**: Memory within 8GB limit

---

### Step 3: Check Disk Usage

**Action**:
```bash
df -h /var/lib/docling-mcp | tail -1 | awk '{print "Data disk: " $5 " used"}'
df -h /var/log/docling-mcp | tail -1 | awk '{print "Log disk: " $5 " used"}'
```

**Expected**: Disk usage < 95% on all partitions

**Pass Criteria**: Adequate disk space available

---

## Pass/Fail Criteria

**PASS**: CPU < 400%, Memory < 8GB, Disk < 95%

**FAIL**: Any resource limit exceeded

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-health-002-resource-exceeded.md`

---

**Test Case Version**: 1.0
