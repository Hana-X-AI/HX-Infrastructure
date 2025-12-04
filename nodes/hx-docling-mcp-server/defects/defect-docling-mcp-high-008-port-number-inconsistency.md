# Defect: Port Number Inconsistency Across Documentation

**Defect ID**: defect-docling-mcp-high-008-port-number-inconsistency
**Service**: hx-docling-mcp-server
**Severity**: high
**Status**: Resolved
**Created**: 2025-12-01
**Updated**: 2025-12-01
**Resolved**: 2025-12-01

---

## Defect Summary

**Brief Description:**
Task 033 documentation references port **8052** for MCP server endpoints (lines 300, 343-349), while test-plan.md references port **8000** for health check and service endpoints (lines 243, 1123, 1203, 1226, 1276, 1396, 1883). This inconsistency will cause integration failures when clients attempt to connect to the wrong port.

**Impact:**
**SERVICE WILL NOT WORK** - Client configurations (Claude Desktop, LM Studio, custom HTTP clients) will fail to connect if configured with wrong port. Either port 8052 clients cannot reach port 8000 service, or port 8000 clients cannot reach port 8052 service. Blocks operational deployment.

**Affected Component:**
- Task 033 - Configure Transport Modes (lines 300, 314, 340, 343, 348 - all use port 8052)
- test-plan.md (lines 243, 1123, 1203, 1226, 1276, 1396, 1883 - all use port 8000)

---

## Severity Classification

**Severity**: High

**Justification:**
- [X] Service non-functional (clients cannot connect with wrong port)
- [X] Blocks operational deployment (integration tests will fail)
- [X] Requires coordination across multiple files (tasks + test plan)
- [X] User-facing impact (client configuration failures)

**Impact Assessment:**
- Service functional: **NO** (with inconsistent configuration)
- Workaround available: Manual port correction before deployment
- Users affected: **ALL** (any client trying to connect to MCP server)
- Operations impact: **CRITICAL** - service unreachable with wrong port configuration

---

## Defect Details

### Discovery Information
**Discovered During:** Code Review (Pre-Implementation)
**Discovered By:** CodeRabbit AI Code Review
**Discovery Date**: 2025-12-01
**Task File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-033-configure-transport-modes.md`
**Test File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md`
**Code Lines**: Task 033 (lines 300, 314, 340, 343, 348), test-plan.md (lines 243, 1123, 1203, 1226, 1276, 1396, 1883)

### Environment
**Node**: hx-docling-mcp-server.hx.dev.local (192.168.10.217)
**OS**: Ubuntu 24.04 LTS
**Service Version**: Not yet deployed
**Configuration**: Task implementation + test plan (pre-deployment)

---

## Defect Description

### Detailed Description

**Conflicting Port References:**

**Task 033 Uses Port 8052:**
```json
// Line 300-301
{
  "docling": {
    "url": "http://hx-docling-mcp-server.hx.dev.local:8052/sse",
```

```bash
# Line 314
http://hx-docling-mcp-server.hx.dev.local:8052
```

```bash
# Lines 340, 343, 348
curl http://hx-docling-mcp-server.hx.dev.local:8052/mcp/tools
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8052/mcp/invoke
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8052/mcp/invoke
```

**test-plan.md Uses Port 8000:**
```yaml
# Line 243
"service_port": 8000,
```

```bash
# Line 1123
curl -f http://hx-docling-mcp-server.hx.dev.local:8000/health | jq .
```

```bash
# Lines 1203, 1226, 1396
sudo netstat -tulpn | grep :8000
curl -f http://hx-docling-mcp-server.hx.dev.local:8000/health
netstat -tulpn | grep :8000
```

```markdown
# Line 1276
| Port released | netstat shows port 8000 available |
```

```markdown
# Line 1883
- **Coverage**: Port 8000 listening, internal interface only
```

**Critical Issue:**
One of these ports is wrong. Either:
1. Service runs on port 8000 → Task 033 client configs (port 8052) will fail to connect
2. Service runs on port 8052 → test-plan.md health checks (port 8000) will fail

### Expected Behavior
All documentation should reference the **same authoritative port** for the MCP server. Port number should be:
1. Defined in one canonical location (environment variable, config file)
2. Referenced consistently across all documentation
3. Validated during deployment testing

### Actual Behavior
Documentation has conflicting port numbers (8052 vs 8000), guaranteeing either:
- Client connectivity failures (wrong port in client configs)
- Test failures (wrong port in health checks)
- Deployment blocking issues

### Business Impact
**CRITICAL:**
- **Service unreachable** - Clients configured with wrong port cannot connect
- **Integration test failures** - Health checks and connectivity tests fail
- **Deployment blocked** - Cannot promote to operational with failing tests
- **User impact** - Claude Desktop, LM Studio, custom clients all fail to connect
- **Operations overhead** - Manual port correction required across all files

---

## Steps to Reproduce

**Reproducibility**: Always (documentation inconsistency)
**Reproduction Rate**: 100%

### Prerequisites
1. Service configured with port 8000 (per test-plan.md)
2. Client configured with port 8052 (per Task 033)

### Reproduction Steps

**Scenario 1: Service on Port 8000, Client on Port 8052**
1. Deploy MCP server on port 8000 (as per test-plan.md line 243)
2. Configure Claude Desktop with port 8052 (as per Task 033 line 300)
3. Attempt to connect Claude Desktop to MCP server
4. Observe connection failure:
   ```
   Failed to connect to http://hx-docling-mcp-server.hx.dev.local:8052/sse
   Connection refused (nothing listening on port 8052)
   ```

**Scenario 2: Service on Port 8052, Test on Port 8000**
1. Deploy MCP server on port 8052 (as per Task 033 documentation)
2. Run health check from test-plan.md line 1123:
   ```bash
   curl -f http://hx-docling-mcp-server.hx.dev.local:8000/health
   ```
3. Observe test failure:
   ```
   curl: (7) Failed to connect to hx-docling-mcp-server.hx.dev.local port 8000: Connection refused
   ```

### Expected Result
All documentation references same port, service deploys on that port, clients connect successfully, tests pass.

### Actual Result
Documentation conflicts cause either client connectivity failures or test failures (guaranteed failure regardless of port chosen).

---

## Evidence and Diagnostics

### Code Location

**Task 033**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-033-configure-transport-modes.md`
- Lines 300, 301, 314, 340, 343, 348 (all use **8052**)

**test-plan.md**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md`
- Lines 243, 1123, 1203, 1226, 1276, 1396, 1883 (all use **8000**)

### Code Excerpt

**Task 033 (Port 8052):**
```json
# LM Studio configuration (SSE) - Line 300-301
{
  "mcpServers": {
    "docling": {
      "url": "http://hx-docling-mcp-server.hx.dev.local:8052/sse",
```

**test-plan.md (Port 8000):**
```yaml
# Line 243
"service_port": 8000,
```

```bash
# Line 1123
curl -f http://hx-docling-mcp-server.hx.dev.local:8000/health | jq .
```

### Root Cause Evidence

**Possible Sources of Inconsistency:**
1. **Copy-paste error**: Port 8052 copied from example, port 8000 is actual default
2. **Different authors**: Task 033 and test-plan.md written by different agents without coordination
3. **Missing environment variable**: No `MCP_PORT` or `${SERVICE_PORT}` variable defined
4. **Template inconsistency**: Different templates used for task vs test documentation

**Need to Determine Authoritative Port:**
Search codebase for:
- Environment variable definitions (`.env`, `config.yaml`)
- Application code setting port (FastMCP initialization)
- Systemd service files (`--port` argument)
- Docker configurations (`EXPOSE` directive)

---

## Root Cause Analysis

**Root Cause Identified**: PARTIAL (need to determine authoritative port)

### Root Cause
Documentation inconsistency due to lack of:
1. **Single source of truth** for port number
2. **Variable substitution** in documentation (hardcoded ports instead of `${MCP_PORT}`)
3. **Cross-file validation** during task design
4. **Authoritative port declaration** in central configuration

### Contributing Factors
1. **Multiple documentation files**: Tasks and test plans maintained separately
2. **Hardcoded values**: Port numbers embedded directly instead of referencing variables
3. **No validation**: No automated check for port consistency across files
4. **Missing environment config**: No central `.env` file declaring `MCP_PORT=<value>`

### Analysis Notes

**Action Required: Determine Authoritative Port**

Need to search codebase for actual port configuration:

```bash
# Search for port definitions in application code
grep -r "8000\|8052" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/*.md | grep -i port

# Search for FastMCP server initialization
grep -r "FastMCP\|uvicorn.run\|app.run" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/*.md

# Search for environment variable definitions
grep -r "MCP_PORT\|SERVICE_PORT\|PORT=" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/
```

**Once authoritative port determined, update all references consistently.**

---

## Impact Assessment

### Deployment Impact
**Blocks Deployment**: **YES** (High severity - service non-functional)
**Blocks Promotion to Operational**: **YES**

**Impact Details:**
Service cannot be promoted to operational with port inconsistency. Either clients cannot connect or tests fail, both block deployment.

### Operational Impact
**Affects Operations**: **YES** (critical connectivity issue)
**Affects Users**: **YES** (all clients affected)
**Number of Users Affected**: **ALL** (any client attempting to connect)

### Requirements Impact
**Requirements Not Met:**
- Client connectivity (clients configured with wrong port cannot connect)
- Test validation (health checks fail with wrong port)
- Service availability (port mismatch prevents service access)

---

## Workaround

**Workaround Available**: YES (manual port correction)

### Workaround Details

**Step 1: Determine Authoritative Port**

Search codebase for actual port configuration:

```bash
# Check application code for server initialization
grep -rn "uvicorn\|FastMCP.*port\|app.run" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/

# Check for environment variable definitions
grep -rn "MCP_PORT\|SERVICE_PORT" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/

# Check systemd service files
grep -rn "ExecStart.*port" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/
```

**Step 2: Update All References to Authoritative Port**

**If authoritative port is 8000:**
Update Task 033 to use port 8000:
```bash
# Find all port 8052 references in Task 033
grep -n "8052" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-033-configure-transport-modes.md

# Replace all instances of 8052 with 8000 in Task 033
sed -i 's/:8052/:8000/g' /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-033-configure-transport-modes.md
```

**If authoritative port is 8052:**
Update test-plan.md to use port 8052:
```bash
# Find all port 8000 references in test-plan.md
grep -n "8000" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md

# Replace all instances of 8000 with 8052 in test-plan.md
sed -i 's/:8000/:8052/g' /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md
sed -i 's/8000/8052/g' /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md
```

**Step 3: Use Environment Variable for Future-Proofing**

Replace hardcoded ports with environment variable:

```bash
# In Task 033 (example)
- "url": "http://hx-docling-mcp-server.hx.dev.local:8052/sse"
+ "url": "http://hx-docling-mcp-server.hx.dev.local:${MCP_PORT}/sse"

# In test-plan.md
- curl -f http://hx-docling-mcp-server.hx.dev.local:8000/health
+ curl -f http://hx-docling-mcp-server.hx.dev.local:${MCP_PORT}/health
```

**Step 4: Define MCP_PORT in Central Configuration**

Add to `/etc/docling-mcp/env/.env`:
```bash
MCP_PORT=8000  # or 8052, whichever is authoritative
```

---

## Resolution

### Resolution Status
**Status**: Resolved
**Resolved By**: agent-zero
**Priority**: High
**Resolution Date**: 2025-12-01
**Resolution Time**: 5 minutes

### Resolution Plan

**Approach:**
1. Determine authoritative port number from application code/systemd service
2. Update all documentation to reference authoritative port
3. Replace hardcoded ports with environment variable references
4. Validate consistency across all files

**Resolution Steps:**

1. **Determine Authoritative Port** (george-kim responsibility):

   Search application code for actual port configuration:
   ```bash
   # Check Tasks 032, 033 for server initialization
   grep -rn "port.*=\|--port\|PORT" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-03*.md
   ```

   **Expected to find something like:**
   ```python
   # Task 032 - Start MCP Server
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

   OR

   ```python
   # Environment variable
   MCP_PORT=${MCP_PORT:-8000}
   ```

2. **Update Task 033 to Match Authoritative Port**:

   **If authoritative port is 8000**, update all references in Task 033:
   - Line 300-301: `8052` → `8000`
   - Line 314: `8052` → `8000`
   - Line 340: `8052` → `8000`
   - Line 343: `8052` → `8000`
   - Line 348: `8052` → `8000`

   **If authoritative port is 8052**, update all references in test-plan.md:
   - Line 243: `8000` → `8052`
   - Line 1123: `8000` → `8052`
   - Line 1203: `8000` → `8052`
   - Line 1226: `8000` → `8052`
   - Line 1276: `8000` → `8052`
   - Line 1396: `8000` → `8052`
   - Line 1883: `8000` → `8052`

3. **Replace Hardcoded Ports with Environment Variable** (future-proofing):

   Update Task 033 client configs to use variable:
   ```json
   // LM Studio config
   "url": "http://hx-docling-mcp-server.hx.dev.local:${MCP_PORT}/sse"
   ```

   Add note about environment variable:
   ```markdown
   **Note**: Replace `${MCP_PORT}` with actual port from `/etc/docling-mcp/env/.env` (default: 8000)
   ```

4. **Validate Port Consistency**:

   ```bash
   # After updates, verify all references consistent
   grep -rn "hx-docling-mcp-server.hx.dev.local:[0-9]" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/ | grep -v "8000"
   # Should return no results if 8000 is authoritative
   ```

**Files to Modify:**
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-033-configure-transport-modes.md` (lines 300, 314, 340, 343, 348)
- OR `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-plan.md` (lines 243, 1123, 1203, 1226, 1276, 1396, 1883)
- Potentially both files if environment variable approach used

**Estimated Effort**: 20 minutes (search for authoritative port, update all references, validate consistency)

**Verification Plan:**
1. Search all task files for port references → verify single port used
2. Search test-plan.md for port references → verify matches tasks
3. Test client configuration (dry run) → verify correct port
4. Test health check command → verify correct port
5. Grep entire repository for port references → verify 100% consistency

---

## Verification

**Resolution Implemented**: 2025-12-01

### Actions Taken

1. **Determined Authoritative Port**: Searched all task files and identified Task 142 (Configure Environment Files) defines `MCP_HTTP_PORT=8000` as the authoritative port configuration.

2. **Fixed Task 033**: Replaced all 17 occurrences of incorrect port `8052` with correct port `8000` in Task 033 (Configure Transport Modes).
   ```bash
   sed -i 's/8052/8000/g' /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-033-configure-transport-modes.md
   ```

3. **Verified Fix**:
   - Confirmed 0 occurrences of `8052` remaining in Task 033 ✓
   - Confirmed 17 occurrences of `8000` now present in Task 033 ✓
   - Port now consistent with Task 142 (authoritative source) ✓
   - Port now consistent with test-plan.md (lines 243, 1123, 1203, 1226, 1276, 1396, 1883) ✓

### Verification Results

**Port Consistency Achieved**:
- Task 033: Port 8000 ✓
- Task 142 (authoritative): Port 8000 ✓
- Task 173 (tests): Port 8000 ✓
- test-plan.md: Port 8000 ✓

**Impact**: Service will now be reachable on consistent port 8000 across all client configurations (Claude Desktop, LM Studio, custom HTTP clients).

---

## Prevention

**Prevention Measures** (to be implemented):
1. **Environment variables**: Use `${MCP_PORT}` instead of hardcoded ports in all documentation
2. **Central configuration**: Define all port numbers in single `.env` file
3. **Cross-file validation**: Automated check for port consistency across tasks and tests
4. **Code review checklist**: Verify port numbers match across all related files
5. **Template standardization**: Use consistent port variable references in all templates
6. **Documentation linting**: Add linter rule to detect hardcoded port numbers
7. **Coordination protocol**: Require multi-file review when port numbers mentioned

---

## Communication

### Stakeholders Notified
- [X] Service Owner: CAIO
- [ ] Tech Lead: george-kim (will be notified when assigned)
- [X] CAIO: Defect logged during Phase 6 task breakdown approval
- [X] Operations Team: **YES** - High severity defect blocks deployment

---

## Metrics

**Time to Detect**: 0 days (detected in code review before implementation)
**Time to Resolution**: 5 minutes
**Impact Scope**: **CRITICAL** - blocks service deployment, affects all clients (RESOLVED)

---

## History and Updates

### Update Log
| Date | Updated By | Status Change | Notes |
|------|-----------|---------------|-------|
| 2025-12-01 | agent-zero | Created | Defect logged from CodeRabbit code review during Phase 6 approval |
| 2025-12-01 | agent-zero | Open → Resolved | Fixed all 17 port references in Task 033 (8052→8000) |

---

## Closure

**Closure Date**: 2025-12-01
**Closed By**: agent-zero

**Resolution Summary**:
Defect successfully resolved by updating Task 033 to use correct port 8000 (17 occurrences changed from 8052). Port now consistent across all documentation (Task 033, Task 142, Task 173, test-plan.md).

**Verification**:
- ✓ No occurrences of port 8052 remaining in Task 033
- ✓ Port 8000 used consistently across all affected files
- ✓ Service will be reachable on port 8000 as configured in Task 142

**Lessons Learned**:
Use environment variables (`${MCP_PORT}`) instead of hardcoded port numbers to prevent inconsistencies across documentation.

**Status**: CLOSED
