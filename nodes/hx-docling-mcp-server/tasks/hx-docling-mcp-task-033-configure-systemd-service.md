# Task 010: Configure Systemd Service

**Task ID**: hx-docling-mcp-task-033
**Category**: Installation / Service Management
**Assigned To**: william-chen (Infrastructure Specialist)
**Status**: PENDING
**Priority**: CRITICAL (Core service deployment)
**Created**: 2025-11-27
**Estimated Effort**: 45 minutes

---

## Task Description

Create and configure production-grade systemd service unit file for Docling MCP Server with comprehensive security hardening, resource limits, automatic restart policies, and pre-start validation checks. This systemd service will manage the MCP server process lifecycle with proper dependency handling and operational reliability.

---

## Prerequisites

- [ ] Task 004 complete (Samba AD service account created)
- [ ] Task 005 complete (System dependencies installed)
- [ ] Task 006 complete (Python virtual environment created)
- [ ] Task 007 complete (Python dependencies installed)
- [ ] Task 008 complete (Directory structure created)
- [ ] Task 009 complete (Application code installed)
- [ ] Environment file `/etc/docling-mcp/.env` created (from configuration tasks)
- [ ] LiteLLM Gateway operational (192.168.10.212:4000)

---

## Acceptance Criteria

- [ ] Systemd unit file created at `/etc/systemd/system/docling-mcp.service`
- [ ] Service dependencies configured correctly (network-online.target ONLY)
- [ ] Security hardening directives applied (15 directives minimum)
- [ ] Resource limits configured (CPU 400%, Memory 8GB)
- [ ] Pre-start validation checks implemented (6 checks minimum)
- [ ] Restart policy configured (on-failure, 3 attempts, 10s delay)
- [ ] Service enabled for automatic startup
- [ ] Service starts successfully
- [ ] Service passes all validation checks
- [ ] Service logs to systemd journal correctly

---

## Detailed Procedure

### Step 1: Create Systemd Unit File

**Create complete systemd service unit**:

```bash
# Create systemd service unit file
sudo cat > /etc/systemd/system/docling-mcp.service <<'EOF'
[Unit]
Description=Docling MCP Server - Document Processing Gateway
Documentation=https://github.com/Hana-X-AI/HX-Infrastructure/nodes/hx-docling-mcp-server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=docling-mcp@hx.dev.local
Group=domain users@hx.dev.local

# Working directory
WorkingDirectory=/opt/docling-mcp

# Environment configuration
Environment="PATH=/opt/docling-mcp/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=/opt/docling-mcp/application"
Environment="PYTHONUNBUFFERED=1"
EnvironmentFile=/etc/docling-mcp/.env

# Pre-start validation checks (inline commands only - NO separate scripts)
# Check 1: LITELLM_BASE_URL must be set (BLOCKING - exits 1)
ExecStartPre=/bin/bash -c 'test -n "$LITELLM_BASE_URL" || (echo "ERROR: LITELLM_BASE_URL not set" >&2 && exit 1)'
# Check 2: LiteLLM health check (NON-BLOCKING - logs warning only, allows retry via RestartSec)
ExecStartPre=/bin/bash -c 'curl -f -s -m 5 http://192.168.10.212:4000/health || echo "WARNING: LiteLLM health check failed - service will retry connection" >&2'
# Check 3: .env file must be readable (BLOCKING - exits 1)
ExecStartPre=/bin/bash -c 'test -r /etc/docling-mcp/.env || (echo "ERROR: .env file not readable" >&2 && exit 1)'
ExecStartPre=/bin/bash -c 'df_output=$(df /var/lib/docling-mcp | tail -1 | awk "{print \\$4}"); test "$df_output" -gt 1048576 || (echo "ERROR: Insufficient disk space (<1GB)" >&2 && exit 1)'
ExecStartPre=/bin/bash -c 'test -d /opt/docling-mcp/venv || (echo "ERROR: Virtual environment not found" >&2 && exit 1)'
ExecStartPre=/bin/bash -c 'test -x /opt/docling-mcp/venv/bin/python || (echo "ERROR: Python interpreter not executable" >&2 && exit 1)'

# Start command
ExecStart=/opt/docling-mcp/venv/bin/python -m docling_mcp.server

# Reload signal (HUP for graceful reload)
ExecReload=/bin/kill -HUP $MAINPID

# Restart policy
Restart=on-failure
RestartSec=10
StartLimitBurst=3
StartLimitIntervalSec=60

# Output configuration
StandardOutput=journal
StandardError=journal
SyslogIdentifier=docling-mcp

# Security hardening
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/docling-mcp /var/log/docling-mcp
ReadOnlyPaths=/etc/docling-mcp
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=true
LockPersonality=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
PrivateMounts=true

# Resource limits
CPUQuota=400%
MemoryMax=8G
MemoryHigh=6G
TasksMax=256
LimitNOFILE=65536
LimitNPROC=512

# Timeout configuration
TimeoutStartSec=60s
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
EOF

# Verify file created
test -f /etc/systemd/system/docling-mcp.service && echo "Service unit file created"

# Verify file contents
cat /etc/systemd/system/docling-mcp.service
```

### Step 2: Set File Permissions

```bash
# Set correct permissions on service unit file
sudo chmod 644 /etc/systemd/system/docling-mcp.service

# Verify permissions
stat -c "%a %n" /etc/systemd/system/docling-mcp.service
# Expected: 644 /etc/systemd/system/docling-mcp.service

# Verify ownership
stat -c "%U:%G %n" /etc/systemd/system/docling-mcp.service
# Expected: root:root /etc/systemd/system/docling-mcp.service
```

### Step 3: Reload Systemd Daemon

```bash
# Reload systemd to recognize new service unit
sudo systemctl daemon-reload

# Verify no errors
echo $?
# Expected: 0

# Verify service unit recognized
systemctl list-unit-files | grep docling-mcp
# Expected: docling-mcp.service

# Check service status (should show "loaded" but not running yet)
systemctl status docling-mcp.service
# Expected: Loaded: loaded (/etc/systemd/system/docling-mcp.service; disabled; ...)
```

### Step 4: Enable Service for Automatic Startup

```bash
# Enable service (start on boot)
sudo systemctl enable docling-mcp.service

# Verify enabled
systemctl is-enabled docling-mcp.service
# Expected: enabled

# List dependencies
systemctl list-dependencies docling-mcp.service
# Expected:
# docling-mcp.service
# ● ├─network-online.target
# ● └─system.slice
```

### Step 5: Pre-Start Validation

**Validate pre-start checks before attempting start**:

```bash
# Test pre-start check 1: LITELLM_BASE_URL set
source /etc/docling-mcp/.env
test -n "$LITELLM_BASE_URL" && echo "✓ LITELLM_BASE_URL set" || echo "✗ LITELLM_BASE_URL not set"

# Test pre-start check 2: LiteLLM health check
curl -f -s -m 5 http://192.168.10.212:4000/health && echo "✓ LiteLLM healthy" || echo "✗ LiteLLM health check failed"

# Test pre-start check 3: .env file readable
test -r /etc/docling-mcp/.env && echo "✓ .env readable" || echo "✗ .env not readable"

# Test pre-start check 4: Disk space check
df_output=$(df /var/lib/docling-mcp | tail -1 | awk '{print $4}')
test "$df_output" -gt 1048576 && echo "✓ Disk space sufficient" || echo "✗ Insufficient disk space"

# Test pre-start check 5: Virtual environment exists
test -d /opt/docling-mcp/venv && echo "✓ Virtual environment exists" || echo "✗ Virtual environment not found"

# Test pre-start check 6: Python interpreter executable
test -x /opt/docling-mcp/venv/bin/python && echo "✓ Python executable" || echo "✗ Python not executable"

# All checks must pass before proceeding
```

### Step 6: Start Service

**Start the Docling MCP Server service**:

```bash
# Start service
sudo systemctl start docling-mcp.service

# Check start status
echo $?
# Expected: 0 (successful start)

# View service status
sudo systemctl status docling-mcp.service
# Expected: Active: active (running)

# Verify process running
ps aux | grep "[d]ocling_mcp.server"
# Expected: Service process visible

# Check listening port
sudo netstat -tulpn | grep :8000
# Expected: Port 8000 listening (MCP HTTP endpoint)
```

### Step 7: Monitor Service Logs

**Monitor systemd journal logs**:

```bash
# View service logs (last 50 lines)
sudo journalctl -u docling-mcp.service -n 50 --no-pager

# Follow logs in real-time
sudo journalctl -u docling-mcp.service -f

# Check for errors
sudo journalctl -u docling-mcp.service -p err --no-pager

# Check for warnings
sudo journalctl -u docling-mcp.service -p warning --no-pager
```

### Step 8: Test Service Restart Policy

**Verify automatic restart on failure**:

```bash
# Get service PID
SERVICE_PID=$(systemctl show docling-mcp.service -p MainPID --value)
echo "Service PID: $SERVICE_PID"

# Kill process to trigger restart
sudo kill -9 $SERVICE_PID

# Wait 10 seconds (RestartSec)
sleep 10

# Check service restarted
sudo systemctl status docling-mcp.service
# Expected: Active: active (running) - new PID

# Verify new PID different
NEW_PID=$(systemctl show docling-mcp.service -p MainPID --value)
echo "New PID: $NEW_PID"
test "$SERVICE_PID" != "$NEW_PID" && echo "✓ Service restarted" || echo "✗ Service did not restart"
```

### Step 9: Test Graceful Reload

**Test graceful reload (HUP signal)**:

```bash
# Reload service configuration (graceful)
sudo systemctl reload docling-mcp.service

# Verify service still running
sudo systemctl status docling-mcp.service
# Expected: Active: active (running) - same PID

# Check logs for reload message
sudo journalctl -u docling-mcp.service -n 20 --no-pager | grep -i reload
```

### Step 10: Document Service Configuration

**Create service documentation**:

```bash
# Create service configuration documentation
cat > /tmp/systemd-service-config.txt <<EOF
Systemd Service Configuration: Docling MCP Server
Generated: $(date)
Node: hx-docling-mcp-server (192.168.10.217)

Service Unit File: /etc/systemd/system/docling-mcp.service

Service Identity:
- Service Name: docling-mcp.service
- Description: Docling MCP Server - Document Processing Gateway
- User: docling-mcp@hx.dev.local
- Group: domain users@hx.dev.local
- Working Directory: /opt/docling-mcp

Dependencies:
- After: network-online.target
- Wants: network-online.target
- NO Requires: (application handles service dependencies with retry logic)

Environment:
- PATH: /opt/docling-mcp/venv/bin:/usr/local/bin:/usr/bin:/bin
- PYTHONPATH: /opt/docling-mcp/application
- PYTHONUNBUFFERED: 1
- EnvironmentFile: /etc/docling-mcp/.env

Pre-Start Validation Checks (6 checks):
1. LITELLM_BASE_URL environment variable set
2. LiteLLM Gateway health check (http://192.168.10.212:4000/health)
3. .env file readable
4. Disk space >1GB available
5. Virtual environment exists
6. Python interpreter executable

Start Command:
/opt/docling-mcp/venv/bin/python -m docling_mcp.server

Restart Policy:
- Restart: on-failure
- RestartSec: 10 seconds
- StartLimitBurst: 3 attempts
- StartLimitIntervalSec: 60 seconds

Security Hardening (15 directives):
- PrivateTmp=true
- NoNewPrivileges=true
- ProtectSystem=strict
- ProtectHome=true
- ReadWritePaths=/var/lib/docling-mcp /var/log/docling-mcp
- ReadOnlyPaths=/etc/docling-mcp
- ProtectKernelTunables=true
- ProtectKernelModules=true
- ProtectControlGroups=true
- RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
- RestrictNamespaces=true
- LockPersonality=true
- RestrictRealtime=true
- RestrictSUIDSGID=true
- RemoveIPC=true
- PrivateMounts=true

Resource Limits:
- CPUQuota: 400% (4 cores maximum)
- MemoryMax: 8GB
- MemoryHigh: 6GB (soft limit)
- TasksMax: 256
- LimitNOFILE: 65536 (file descriptors)
- LimitNPROC: 512 (processes)

Timeout Configuration:
- TimeoutStartSec: 60s
- TimeoutStopSec: 30s

Output:
- StandardOutput: journal
- StandardError: journal
- SyslogIdentifier: docling-mcp

Install Target:
- WantedBy: multi-user.target

Created: $(date)
Created By: $(whoami)
EOF

# Generate final documentation using systemctl cat (simpler and more reliable)
sudo systemctl cat docling-mcp.service > /tmp/systemd-service-config-final.txt

cat /tmp/systemd-service-config-final.txt

# Copy to documentation with proper ownership
sudo cp /tmp/systemd-service-config-final.txt /opt/docling-mcp/documentation/systemd-service.txt
sudo chown docling-mcp /opt/docling-mcp/documentation/systemd-service.txt
sudo chgrp 'domain users' /opt/docling-mcp/documentation/systemd-service.txt
```

---

## Validation

### Validation Commands

```bash
# 1. Verify service unit file exists
test -f /etc/systemd/system/docling-mcp.service && echo "✓ Service unit file exists" || echo "✗ Service unit file NOT found"

# 2. Verify service enabled
systemctl is-enabled docling-mcp.service
# Expected: enabled

# 3. Verify service running
systemctl is-active docling-mcp.service
# Expected: active

# 4. Verify service status
sudo systemctl status docling-mcp.service
# Expected: Active: active (running)

# 5. Verify process running
pgrep -f "docling_mcp.server"
# Expected: Process ID

# 6. Verify port listening
sudo netstat -tulpn | grep :8000
# Expected: Python process listening on port 8000

# 7. Check systemd dependencies
systemctl list-dependencies docling-mcp.service | grep network-online
# Expected: network-online.target present

# 8. Verify no errors in journal
sudo journalctl -u docling-mcp.service -p err --since "10 minutes ago" | wc -l
# Expected: 0 (no errors)

# 9. Test reload
sudo systemctl reload docling-mcp.service && echo "✓ Reload successful" || echo "✗ Reload failed"

# 10. Verify resource limits applied
systemctl show docling-mcp.service -p CPUQuota -p MemoryMax
# Expected: CPUQuota=400%, MemoryMax=8G
```

### Success Criteria

- ✅ Service unit file exists and valid
- ✅ Service enabled for automatic startup
- ✅ Service running (active)
- ✅ Port 8000 listening
- ✅ No errors in journal logs
- ✅ Pre-start checks passing
- ✅ Restart policy working (automatic restart on failure)
- ✅ Resource limits applied
- ✅ Security hardening directives active

---

## Troubleshooting

### Issue: Service Fails to Start

**Symptom**: `systemctl start docling-mcp.service` returns exit code 1

**Diagnosis**:
```bash
# Check service status
sudo systemctl status docling-mcp.service

# View full logs
sudo journalctl -u docling-mcp.service -n 100 --no-pager

# Check which pre-start check failed
sudo systemctl cat docling-mcp.service | grep ExecStartPre
```

**Common Causes**:
1. **LiteLLM health check fails**: Verify LiteLLM operational: `curl http://192.168.10.212:4000/health`
2. **.env file not readable**: Check permissions: `ls -la /etc/docling-mcp/.env`
3. **Insufficient disk space**: Check space: `df -h /var/lib/docling-mcp`
4. **Virtual environment missing**: Verify venv: `ls -la /opt/docling-mcp/venv`

### Issue: Service Starts But Crashes

**Symptom**: Service starts, then immediately exits

**Diagnosis**:
```bash
# View service logs
sudo journalctl -u docling-mcp.service -f

# Check Python errors
sudo journalctl -u docling-mcp.service | grep -i "traceback\|error"

# Test Python module directly
sudo -u docling-mcp@hx.dev.local /opt/docling-mcp/venv/bin/python -m docling_mcp.server
```

**Common Causes**:
1. **Missing Python dependencies**: Verify requirements installed
2. **Configuration error**: Check /etc/docling-mcp/.env syntax
3. **Port already in use**: Check `netstat -tulpn | grep :8000`

### Issue: Service Won't Restart Automatically

**Symptom**: Service dies and doesn't restart

**Diagnosis**:
```bash
# Check restart limit
systemctl show docling-mcp.service -p NRestarts
# If >= 3, service hit restart limit

# Reset restart limit
sudo systemctl reset-failed docling-mcp.service

# Check logs for persistent failure cause
sudo journalctl -u docling-mcp.service -p err --no-pager
```

---

## Rollback Procedure

**If service configuration fails or needs removal**:

```bash
# Stop service
sudo systemctl stop docling-mcp.service

# Disable service
sudo systemctl disable docling-mcp.service

# Remove service unit file
sudo rm /etc/systemd/system/docling-mcp.service

# Reload systemd daemon
sudo systemctl daemon-reload

# Reset any failed states
sudo systemctl reset-failed

# Verify service removed
systemctl list-unit-files | grep docling-mcp
# Expected: No output
```

---

## Dependencies

**Blocks**:
- Task 028: Run deployment validation tests (service must be running)
- All functional tests (service operational required)
- Operational promotion (service must pass all quality gates)

**Depends On**:
- Task 004: Create Samba AD service account
- Task 005: Install system dependencies
- Task 006: Create directory structure
- Task 007: Install Python dependencies
- Task 009: Install application code
- Environment file configured (.env)
- LiteLLM Gateway operational

---

## Notes

### HX-Infrastructure Systemd Standards

**CRITICAL Systemd Dependency Policy** (from deployment-requirements.md):
- ✅ **NO `Requires=` directives** - Never use hard dependencies
- ✅ **Use `After=` and `Wants=` only** - For ordering, not hard dependencies
- ✅ **Network dependency ONLY**: `network-online.target` (NOT other services)
- ✅ **Application-level retry logic**: Service handles external dependencies with retry

**Rationale**: Cross-node systemd dependencies cause cascading failures. All external service dependencies (LiteLLM, Qdrant, Redis) handled at application level with retry logic.

### Pre-Start Validation Policy

**Six Pre-Start Checks (ExecStartPre directives)**:

| Check # | Validation | Type | Failure Behavior | Rationale |
|---------|------------|------|------------------|-----------|
| 1 | LITELLM_BASE_URL set | BLOCKING | Exit 1 (startup fails) | Configuration required for initialization |
| 2 | LiteLLM health check | NON-BLOCKING | Log warning only | Allows restart policy to handle transient outages |
| 3 | .env file readable | BLOCKING | Exit 1 (startup fails) | Configuration file access required |
| 4 | Disk space >1GB | BLOCKING | Exit 1 (startup fails) | Prevents disk full errors during operation |
| 5 | Virtual environment exists | BLOCKING | Exit 1 (startup fails) | Python environment required |
| 6 | Python interpreter executable | BLOCKING | Exit 1 (startup fails) | Runtime executable required |

**LiteLLM Health Check Design (Check #2)**:

The LiteLLM health check (line 78) is intentionally **NON-BLOCKING** to allow the service to start even when LiteLLM is temporarily unavailable:

- **Implementation**: `curl ... || echo "WARNING: ..."` (no exit 1)
- **Startup Behavior**: Service proceeds to start even if LiteLLM is down
- **Recovery Mechanism**: Application-level retry logic handles connection failures
- **Restart Policy Support**: If application fails due to LiteLLM unavailability, systemd will retry:
  - RestartSec=10s (10-second delay between attempts)
  - StartLimitBurst=3 (3 attempts allowed)
  - StartLimitIntervalSec=60s (within 60-second window)

**Transient Outage Handling**:

1. **LiteLLM down at startup**: Health check logs WARNING, service starts, application retries connection
2. **LiteLLM down briefly**: Application retry logic handles reconnection (no systemd intervention)
3. **LiteLLM down persistently**: Application may fail, systemd restarts service (3 attempts over 60s window)
4. **LiteLLM returns**: Next retry succeeds, service becomes operational

**Trade-offs**:
- ✅ **Pro**: Service doesn't fail immediately if LiteLLM is restarting
- ✅ **Pro**: Restart policy provides multiple recovery opportunities (30s total: 0s, 10s, 20s)
- ⚠️ **Con**: Service may start but be non-functional until LiteLLM available
- ⚠️ **Con**: Logs will show warnings during LiteLLM outages

**Alternatives Considered**:
- **Blocking health check** (exit 1): Rejected - creates soft hard dependency, violates HX-Infrastructure standards
- **Delayed retry in ExecStartPre**: Rejected - systemd restart policy provides better retry mechanism
- **No health check**: Rejected - loses visibility into LiteLLM availability at startup

**Recommended Monitoring**:
- Monitor both services independently: `systemctl status docling-mcp.service litellm-gateway.service`
- Check logs for LiteLLM connection warnings: `journalctl -u docling-mcp.service -grep "LiteLLM"`
- Verify end-to-end functionality with deployment validation tests (Task 028)

### Security Hardening Explanation

| Directive | Purpose | Impact |
|-----------|---------|--------|
| `PrivateTmp=true` | Isolate /tmp directory | Prevents tmpfile attacks |
| `NoNewPrivileges=true` | Prevent privilege escalation | No setuid/setgid execution |
| `ProtectSystem=strict` | Read-only filesystem | Only ReadWritePaths writable |
| `ProtectHome=true` | Deny /home access | Service can't access user files |
| `ProtectKernelTunables=true` | Deny /proc/sys access | Prevents kernel tuning |
| `RestrictAddressFamilies` | Limit network families | TCP/UDP/Unix sockets only |
| `RestrictNamespaces=true` | Prevent namespace creation | Enhanced isolation |

### Resource Limit Rationale

- **CPUQuota=400%**: Maximum 4 cores (document processing CPU-intensive)
- **MemoryMax=8GB**: Hard limit (protects other services)
- **MemoryHigh=6GB**: Soft limit (triggers memory pressure)
- **LimitNOFILE=65536**: High file descriptor limit (many concurrent connections)
- **LimitNPROC=512**: Process limit (thread pool + workers)

---

## References

- **Configuration Spec**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/configuration-spec.md` (Section 5: Systemd Service Configuration)
- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 012)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
- **Standards**: `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
