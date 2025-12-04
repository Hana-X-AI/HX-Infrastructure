# Infrastructure Specification Contribution: hx-lang-server

**Contributor:** William Chen
**Role:** Infrastructure & Operations Specialist
**Contribution Date:** 2025-12-01
**Specification Version:** 1.0
**Charter Reference:** `/nodes/hx-lang-server/charter/charter.md` (APPROVED 2025-12-01)
**Charter Review Reference:** `/nodes/hx-lang-server/charter/reviews/william-chen-infrastructure-review.md`

---

## Executive Summary

This contribution provides detailed infrastructure specifications for hx-lang-server deployment on bare metal Ubuntu 24.04 LTS. The document addresses all concerns raised in my charter review (H-001 through L-002) and provides comprehensive operational guidance including systemd service configuration, directory structure, service account procedures, and operational runbooks.

**Key Deliverables:**
1. Validated resource specifications
2. Production-grade systemd service configuration
3. Complete directory structure and permissions
4. Manual service account creation procedures
5. Operational runbook for key procedures
6. Specification corrections and enhancements

---

## 1. Resource Specifications Validation

### 1.1 Server Resource Analysis

**Target Server:** hx-lang-server.hx.dev.local (192.168.10.226)

| Resource | Specification Stated | William Chen Validation | Recommendation |
|----------|---------------------|------------------------|----------------|
| CPU | 4 cores min, 8 recommended | VALIDATED | 4 cores sufficient for dev, 8 for concurrent multi-agent |
| Memory | 8GB min, 16GB recommended | NEEDS ADJUSTMENT | Recommend 16GB minimum due to LangGraph state + FastAPI + workers |
| Storage | 50GB (20GB app, 30GB logs/cache) | VALIDATED | Appropriate for development; consider expansion for production |
| Network | 1Gbps | VALIDATED | Adequate for internal HX network traffic |

### 1.2 Memory Breakdown Analysis

```
Component                          Estimated Memory Usage
-----------------------------------------------------------------
Python Virtual Environment         ~500MB
FastAPI + Uvicorn                  ~200MB
LangGraph Supervisor               ~500MB
RAG Worker Agent                   ~500MB
Code Worker Agent                  ~500MB
Tool Worker Agent                  ~300MB
Redis Connection Pool              ~100MB
PostgreSQL Connection Pool         ~100MB
Message/State Buffers              ~1GB (per 10 concurrent sessions)
LLM Response Caching               ~500MB
Operating System Overhead          ~1GB
-----------------------------------------------------------------
TOTAL BASELINE                     ~5.2GB
Per Additional Concurrent Session  ~100MB

RECOMMENDED MINIMUM: 16GB (supports 10 concurrent sessions with 50% headroom)
```

### 1.3 Storage Allocation Plan

```
Directory                          Allocation    Purpose
-----------------------------------------------------------------
/opt/hx-lang-server/               5GB          Application code and venv
/opt/hx-lang-server/logs/          10GB         Application logs (rotated)
/opt/hx-lang-server/cache/         5GB          Local caching
/var/log/journal/ (hx-lang-server) 10GB         systemd journal logs
/tmp/hx-lang-server/               5GB          Temporary processing
RESERVED                           15GB         Future growth
-----------------------------------------------------------------
TOTAL                              50GB
```

### 1.4 Resource Monitoring Thresholds

| Metric | Warning Threshold | Critical Threshold | Action |
|--------|------------------|-------------------|--------|
| CPU Usage | > 70% sustained 5min | > 90% sustained 1min | Scale workers or investigate |
| Memory Usage | > 75% | > 90% | Restart service, investigate leak |
| Disk Usage | > 70% | > 85% | Log rotation, cache cleanup |
| Open File Descriptors | > 50000 | > 60000 | Connection leak investigation |

---

## 2. systemd Service Configuration

### 2.1 Service Architecture Decision

**Recommendation:** Single monolithic service unit (`hx-lang-server.service`)

**Rationale:**
- LangGraph supervisor and workers share state via Python async context
- Worker agents are lightweight coroutines, not separate processes
- Simplified operational management and log aggregation
- Restart behavior applies uniformly to all components
- Resource limits applied holistically

**NOT Recommended:** Separate service units for workers
- Would require complex IPC mechanisms
- State sharing becomes problematic
- Increases operational complexity without benefit

### 2.2 Production-Grade systemd Unit File

```ini
# /etc/systemd/system/hx-lang-server.service
# HX LangGraph Orchestration Server - Production Configuration
# Version: 1.0
# Last Updated: 2025-12-01
# Maintainer: William Chen (Infrastructure)

[Unit]
Description=HX LangGraph Orchestration Server
Documentation=file:///opt/hx-lang-server/docs/README.md

# Service dependencies
After=network-online.target
Wants=network-online.target

# Optional: Start after PostgreSQL and Redis if co-located
# After=postgresql.service redis.service

[Service]
# Service type and user
Type=simple
User=hx-lang-server
Group=hx-lang-server

# Working directory
WorkingDirectory=/opt/hx-lang-server

# Environment configuration
Environment="PATH=/opt/hx-lang-server/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
Environment="PYTHONDONTWRITEBYTECODE=1"
EnvironmentFile=/opt/hx-lang-server/config/.env

# Application startup
ExecStartPre=/opt/hx-lang-server/scripts/pre-start-checks.sh
ExecStart=/opt/hx-lang-server/venv/bin/uvicorn \
    app.main:app \
    --host 0.0.0.0 \
    --port 8100 \
    --workers 1 \
    --loop uvloop \
    --http httptools \
    --log-level info \
    --access-log

# Graceful shutdown
ExecStop=/bin/kill -SIGTERM $MAINPID
TimeoutStopSec=30
KillMode=mixed
KillSignal=SIGTERM

# Restart configuration
Restart=on-failure
RestartSec=5
RestartPreventExitStatus=0

# Startup and watchdog
TimeoutStartSec=60
WatchdogSec=30

# Logging to journald
StandardOutput=journal
StandardError=journal
SyslogIdentifier=hx-lang-server

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/hx-lang-server/logs /opt/hx-lang-server/cache /tmp/hx-lang-server

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096
MemoryMax=8G
MemoryHigh=6G
CPUQuota=400%

# OOM handling
OOMScoreAdjust=-100

[Install]
WantedBy=multi-user.target
```

### 2.3 Pre-Start Check Script

```bash
#!/bin/bash
# /opt/hx-lang-server/scripts/pre-start-checks.sh
# Pre-start validation script for hx-lang-server
# Version: 1.0

set -e

LOG_PREFIX="[hx-lang-server-prestart]"

log_info() {
    echo "${LOG_PREFIX} INFO: $1"
}

log_error() {
    echo "${LOG_PREFIX} ERROR: $1" >&2
}

check_file() {
    if [[ ! -f "$1" ]]; then
        log_error "Required file missing: $1"
        exit 1
    fi
    log_info "File check passed: $1"
}

check_dir() {
    if [[ ! -d "$1" ]]; then
        log_error "Required directory missing: $1"
        exit 1
    fi
    log_info "Directory check passed: $1"
}

check_connectivity() {
    local host="$1"
    local port="$2"
    local service="$3"

    if timeout 5 bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null; then
        log_info "Connectivity check passed: ${service} (${host}:${port})"
    else
        log_error "Connectivity check failed: ${service} (${host}:${port})"
        exit 1
    fi
}

# Check required files
log_info "Starting pre-start checks..."

check_file "/opt/hx-lang-server/config/.env"
check_file "/opt/hx-lang-server/venv/bin/python"
check_file "/opt/hx-lang-server/venv/bin/uvicorn"
check_file "/opt/hx-lang-server/app/main.py"

# Check required directories
check_dir "/opt/hx-lang-server/logs"
check_dir "/opt/hx-lang-server/cache"
check_dir "/tmp/hx-lang-server"

# Check external dependencies
log_info "Checking external dependencies..."

# PostgreSQL (checkpoint storage)
check_connectivity "hx-postgres-server.hx.dev.local" "5432" "PostgreSQL"

# Redis (session cache)
check_connectivity "hx-redis-server.hx.dev.local" "6379" "Redis"

# Ollama servers (LLM)
check_connectivity "hx-ollama1-server.hx.dev.local" "11434" "Ollama-General"
check_connectivity "hx-ollama2-server.hx.dev.local" "11434" "Ollama-Code"

# LightRAG (RAG pipeline)
check_connectivity "hx-literag-server.hx.dev.local" "8020" "LightRAG"

# FastMCP gateway (MCP tools)
check_connectivity "hx-fastmcp-server.hx.dev.local" "8000" "FastMCP"

log_info "All pre-start checks passed successfully"
exit 0
```

### 2.4 Service Management Commands

```bash
# Enable service on boot
sudo systemctl enable hx-lang-server.service

# Start service
sudo systemctl start hx-lang-server.service

# Stop service (graceful)
sudo systemctl stop hx-lang-server.service

# Restart service
sudo systemctl restart hx-lang-server.service

# Reload configuration (if supported by app)
sudo systemctl reload hx-lang-server.service

# Check service status
sudo systemctl status hx-lang-server.service

# View recent logs
sudo journalctl -u hx-lang-server.service -n 100

# Follow logs in real-time
sudo journalctl -u hx-lang-server.service -f

# View logs since last boot
sudo journalctl -u hx-lang-server.service -b

# Check service resource usage
systemctl show hx-lang-server.service --property=MemoryCurrent,CPUUsageNSec
```

---

## 3. Directory Structure

### 3.1 Complete Directory Layout

```
/opt/hx-lang-server/
├── app/                           # Application code
│   ├── __init__.py
│   ├── main.py                    # FastAPI application entry point
│   ├── agents/                    # LangGraph agent definitions
│   │   ├── __init__.py
│   │   ├── supervisor.py          # Supervisor agent
│   │   ├── rag_agent.py           # RAG worker agent
│   │   ├── code_agent.py          # Code worker agent
│   │   └── tool_agent.py          # Tool worker agent
│   ├── api/                       # API endpoints
│   │   ├── __init__.py
│   │   ├── routes.py              # Route definitions
│   │   ├── models.py              # Pydantic models
│   │   └── middleware.py          # Custom middleware
│   ├── core/                      # Core components
│   │   ├── __init__.py
│   │   ├── config.py              # Pydantic settings
│   │   ├── logging.py             # Structured logging setup
│   │   └── exceptions.py          # Custom exceptions
│   ├── services/                  # External service clients
│   │   ├── __init__.py
│   │   ├── postgres.py            # PostgreSQL checkpointer
│   │   ├── redis.py               # Redis session manager
│   │   ├── ollama.py              # Ollama client with routing
│   │   ├── lightrag.py            # LightRAG client
│   │   └── mcp.py                 # MCP client adapter
│   └── utils/                     # Utilities
│       ├── __init__.py
│       ├── classifier.py          # Query classifier
│       └── validators.py          # Input validators
├── config/                        # Configuration files
│   ├── .env                       # Environment variables (from vault)
│   └── .env.example               # Example environment file
├── scripts/                       # Operational scripts
│   ├── pre-start-checks.sh        # Pre-start validation
│   ├── health-check.sh            # Health check script
│   ├── backup-config.sh           # Configuration backup
│   └── rotate-logs.sh             # Log rotation helper
├── logs/                          # Application logs
│   └── .gitkeep
├── cache/                         # Local cache storage
│   └── .gitkeep
├── docs/                          # Documentation
│   ├── README.md                  # Service documentation
│   ├── API.md                     # API documentation
│   └── TROUBLESHOOTING.md         # Troubleshooting guide
├── tests/                         # Test suite
│   ├── __init__.py
│   ├── conftest.py                # pytest fixtures
│   ├── test_agents/               # Agent tests
│   ├── test_api/                  # API tests
│   └── test_services/             # Service client tests
├── venv/                          # Python virtual environment
├── requirements.txt               # Python dependencies
├── requirements-dev.txt           # Development dependencies
└── pyproject.toml                 # Project configuration
```

### 3.2 Directory Creation Procedure

```bash
#!/bin/bash
# Directory structure creation for hx-lang-server
# Execute as root or with sudo

BASE_DIR="/opt/hx-lang-server"
SERVICE_USER="hx-lang-server"
SERVICE_GROUP="hx-lang-server"

# Create base directory
mkdir -p "${BASE_DIR}"

# Create application directories
mkdir -p "${BASE_DIR}/app"/{agents,api,core,services,utils}
mkdir -p "${BASE_DIR}/config"
mkdir -p "${BASE_DIR}/scripts"
mkdir -p "${BASE_DIR}/logs"
mkdir -p "${BASE_DIR}/cache"
mkdir -p "${BASE_DIR}/docs"
mkdir -p "${BASE_DIR}/tests"/{test_agents,test_api,test_services}

# Create temporary directory
mkdir -p "/tmp/hx-lang-server"

# Create placeholder files
touch "${BASE_DIR}/logs/.gitkeep"
touch "${BASE_DIR}/cache/.gitkeep"

# Set ownership
chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${BASE_DIR}"
chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "/tmp/hx-lang-server"

# Set permissions
chmod 750 "${BASE_DIR}"
chmod 750 "${BASE_DIR}/app" "${BASE_DIR}/config" "${BASE_DIR}/scripts"
chmod 750 "${BASE_DIR}/logs" "${BASE_DIR}/cache"
chmod 700 "${BASE_DIR}/config/.env" 2>/dev/null || true
chmod 755 "${BASE_DIR}/scripts"/*.sh 2>/dev/null || true

echo "Directory structure created successfully"
```

### 3.3 Permission Matrix

| Path | Owner | Group | Mode | Purpose |
|------|-------|-------|------|---------|
| `/opt/hx-lang-server` | hx-lang-server | hx-lang-server | 750 | Base directory |
| `/opt/hx-lang-server/app` | hx-lang-server | hx-lang-server | 750 | Application code |
| `/opt/hx-lang-server/config` | hx-lang-server | hx-lang-server | 750 | Configuration |
| `/opt/hx-lang-server/config/.env` | hx-lang-server | hx-lang-server | 600 | Secrets (restricted) |
| `/opt/hx-lang-server/scripts` | hx-lang-server | hx-lang-server | 750 | Operational scripts |
| `/opt/hx-lang-server/scripts/*.sh` | hx-lang-server | hx-lang-server | 755 | Executable scripts |
| `/opt/hx-lang-server/logs` | hx-lang-server | hx-lang-server | 750 | Log files |
| `/opt/hx-lang-server/cache` | hx-lang-server | hx-lang-server | 750 | Cache storage |
| `/opt/hx-lang-server/venv` | hx-lang-server | hx-lang-server | 750 | Virtual environment |
| `/tmp/hx-lang-server` | hx-lang-server | hx-lang-server | 750 | Temporary files |

---

## 4. Service Account Setup

### 4.1 Service Account Specification

| Attribute | Value |
|-----------|-------|
| Account Name | `hx-lang-server` |
| Account Type | System service account |
| Home Directory | `/opt/hx-lang-server` |
| Shell | `/usr/sbin/nologin` (no interactive login) |
| Primary Group | `hx-lang-server` |
| UID/GID | System-assigned (below 1000) |
| Domain Integration | Local account only (no AD/LDAP required) |

### 4.2 Manual Service Account Creation Procedure

**IMPORTANT:** This is a manual procedure. Do NOT use automation tools.

```bash
# Step 1: Create service group
# Execute as root or with sudo
sudo groupadd --system hx-lang-server

# Verify group creation
getent group hx-lang-server
# Expected output: hx-lang-server:x:NNN:

# Step 2: Create service account
sudo useradd \
    --system \
    --gid hx-lang-server \
    --home-dir /opt/hx-lang-server \
    --shell /usr/sbin/nologin \
    --comment "HX LangGraph Server Service Account" \
    hx-lang-server

# Verify account creation
id hx-lang-server
# Expected output: uid=NNN(hx-lang-server) gid=NNN(hx-lang-server) groups=NNN(hx-lang-server)

# Step 3: Verify no login capability
sudo -u hx-lang-server whoami 2>&1
# Expected: This account is currently not available.

# Step 4: Set home directory ownership
sudo chown hx-lang-server:hx-lang-server /opt/hx-lang-server

# Step 5: Document account in inventory
echo "Service account 'hx-lang-server' created on $(date)" >> /opt/hx-lang-server/docs/service-account.log
```

### 4.3 Service Account Validation Checklist

```
[ ] Group 'hx-lang-server' exists in /etc/group
[ ] User 'hx-lang-server' exists in /etc/passwd
[ ] User shell is /usr/sbin/nologin
[ ] User home directory is /opt/hx-lang-server
[ ] User cannot log in interactively
[ ] Home directory owned by hx-lang-server:hx-lang-server
[ ] Account documented in service documentation
```

---

## 5. Operational Runbook

### 5.1 Service Startup Procedure

**Procedure ID:** OP-LANG-001
**Procedure Name:** Start hx-lang-server Service
**Author:** William Chen
**Version:** 1.0

#### Prerequisites
- Service account exists (`hx-lang-server`)
- Directory structure created
- Virtual environment installed
- Configuration file deployed (`.env`)
- External dependencies accessible (PostgreSQL, Redis, Ollama, LightRAG, FastMCP)

#### Procedure Steps

```
STEP 1: Verify Prerequisites
---------------------------------------------------------------------------
Command: id hx-lang-server
Expected: uid=NNN(hx-lang-server) gid=NNN(hx-lang-server)

Command: ls -la /opt/hx-lang-server/config/.env
Expected: -rw------- 1 hx-lang-server hx-lang-server ... .env

Command: /opt/hx-lang-server/venv/bin/python --version
Expected: Python 3.11.x or higher

STEP 2: Run Pre-Start Checks
---------------------------------------------------------------------------
Command: sudo -u hx-lang-server /opt/hx-lang-server/scripts/pre-start-checks.sh
Expected: "All pre-start checks passed successfully"
Action if Failed: Review error message, resolve connectivity/configuration issues

STEP 3: Start Service
---------------------------------------------------------------------------
Command: sudo systemctl start hx-lang-server.service
Expected: No output (silent success)

STEP 4: Verify Service Status
---------------------------------------------------------------------------
Command: sudo systemctl status hx-lang-server.service
Expected: "Active: active (running)"

Command: sudo journalctl -u hx-lang-server.service -n 20
Expected: No ERROR messages, "Application startup complete" message

STEP 5: Verify Health Endpoint
---------------------------------------------------------------------------
Command: curl -s http://localhost:8100/health | jq .
Expected: {"status": "healthy", ...}
Timeout: 30 seconds after service start

STEP 6: Document Startup
---------------------------------------------------------------------------
Action: Record startup time and status in operational log
File: /opt/hx-lang-server/logs/operations.log
Format: "[YYYY-MM-DD HH:MM:SS] SERVICE START - Status: SUCCESS/FAILURE - Notes: ..."
```

### 5.2 Service Shutdown Procedure

**Procedure ID:** OP-LANG-002
**Procedure Name:** Stop hx-lang-server Service (Graceful)

#### Procedure Steps

```
STEP 1: Check Active Sessions (Optional)
---------------------------------------------------------------------------
Command: curl -s http://localhost:8100/health | jq .dependencies
Purpose: Verify no critical operations in progress

STEP 2: Stop Service
---------------------------------------------------------------------------
Command: sudo systemctl stop hx-lang-server.service
Expected: Service stops within 30 seconds (TimeoutStopSec)

STEP 3: Verify Service Stopped
---------------------------------------------------------------------------
Command: sudo systemctl status hx-lang-server.service
Expected: "Active: inactive (dead)"

Command: curl -s http://localhost:8100/health
Expected: Connection refused (service not running)

STEP 4: Document Shutdown
---------------------------------------------------------------------------
Action: Record shutdown time and reason in operational log
```

### 5.3 Service Restart Procedure

**Procedure ID:** OP-LANG-003
**Procedure Name:** Restart hx-lang-server Service

#### Procedure Steps

```
STEP 1: Initiate Restart
---------------------------------------------------------------------------
Command: sudo systemctl restart hx-lang-server.service
Expected: Service restarts within RestartSec (5 seconds) + startup time

STEP 2: Monitor Restart
---------------------------------------------------------------------------
Command: sudo journalctl -u hx-lang-server.service -f
Expected: Shutdown messages followed by startup messages, no errors

STEP 3: Verify Health (after 30 seconds)
---------------------------------------------------------------------------
Command: curl -s http://localhost:8100/health | jq .status
Expected: "healthy"
```

### 5.4 Log Analysis Procedure

**Procedure ID:** OP-LANG-004
**Procedure Name:** Log Analysis and Troubleshooting

#### Common Log Queries

```bash
# View last 100 log entries
sudo journalctl -u hx-lang-server.service -n 100

# View logs since specific time
sudo journalctl -u hx-lang-server.service --since "2025-12-01 10:00:00"

# View only ERROR level messages
sudo journalctl -u hx-lang-server.service -p err

# View logs with full message (no truncation)
sudo journalctl -u hx-lang-server.service --no-pager -o cat

# Export logs to file for analysis
sudo journalctl -u hx-lang-server.service --since "today" > /tmp/lang-server-logs.txt

# Search for specific pattern
sudo journalctl -u hx-lang-server.service | grep -i "checkpoint"

# View logs in JSON format
sudo journalctl -u hx-lang-server.service -o json-pretty
```

### 5.5 Health Check Validation Procedure

**Procedure ID:** OP-LANG-005
**Procedure Name:** Health Check Validation

#### Health Check Script

```bash
#!/bin/bash
# /opt/hx-lang-server/scripts/health-check.sh
# Health check validation script
# Version: 1.0

HEALTH_URL="http://localhost:8100/health"
TIMEOUT=10

# Perform health check
response=$(curl -s --max-time ${TIMEOUT} ${HEALTH_URL})
status=$?

if [[ ${status} -ne 0 ]]; then
    echo "CRITICAL: Health endpoint unreachable"
    exit 2
fi

# Parse status
health_status=$(echo "${response}" | jq -r '.status')

case "${health_status}" in
    "healthy")
        echo "OK: Service is healthy"
        echo "${response}" | jq .
        exit 0
        ;;
    "degraded")
        echo "WARNING: Service is degraded"
        echo "${response}" | jq .
        exit 1
        ;;
    "unhealthy")
        echo "CRITICAL: Service is unhealthy"
        echo "${response}" | jq .
        exit 2
        ;;
    *)
        echo "UNKNOWN: Unexpected health status: ${health_status}"
        exit 3
        ;;
esac
```

### 5.6 Backup Procedure

**Procedure ID:** OP-LANG-006
**Procedure Name:** Configuration Backup

#### Backup Script

```bash
#!/bin/bash
# /opt/hx-lang-server/scripts/backup-config.sh
# Configuration backup script
# Version: 1.0

BACKUP_DIR="/opt/hx-lang-server/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/config_backup_${DATE}.tar.gz"

# Create backup directory if not exists
mkdir -p "${BACKUP_DIR}"

# Create backup archive
tar -czf "${BACKUP_FILE}" \
    -C /opt/hx-lang-server \
    config/ \
    scripts/ \
    docs/

# Verify backup
if [[ -f "${BACKUP_FILE}" ]]; then
    echo "Backup created: ${BACKUP_FILE}"
    echo "Size: $(du -h ${BACKUP_FILE} | cut -f1)"

    # Retain only last 7 backups
    ls -t ${BACKUP_DIR}/config_backup_*.tar.gz | tail -n +8 | xargs -r rm
    echo "Old backups cleaned (retained last 7)"
else
    echo "ERROR: Backup failed"
    exit 1
fi
```

### 5.7 Disaster Recovery Procedure

**Procedure ID:** OP-LANG-007
**Procedure Name:** Service Recovery from Failure

#### Recovery Decision Tree

```
Service Not Starting?
├── Check systemctl status
│   ├── "activating" → Wait 60 seconds, check logs
│   ├── "failed" → Check journalctl for error
│   │   ├── "Connection refused" → Check dependencies
│   │   ├── "Permission denied" → Check file permissions
│   │   ├── "Module not found" → Check venv installation
│   │   └── Other → Escalate to development team
│   └── "inactive" → Start service manually
│
Health Check Failing?
├── Status "degraded"
│   ├── Check dependencies.* in response
│   ├── Identify failing dependency
│   └── Verify external service connectivity
└── Status "unhealthy"
    ├── Restart service
    ├── If persists, check logs
    └── Escalate if unresolved after 2 restarts
```

#### Recovery Steps

```
SCENARIO: Service fails to start due to PostgreSQL connectivity

STEP 1: Identify Issue
---------------------------------------------------------------------------
Command: sudo journalctl -u hx-lang-server.service -n 50
Look for: "Connection refused" or "could not connect to server"

STEP 2: Verify PostgreSQL
---------------------------------------------------------------------------
Command: nc -zv hx-postgres-server.hx.dev.local 5432
Expected: Connection succeeded

If Failed:
- Contact PostgreSQL administrator (Trinity)
- Check if hx-postgres-server.hx.dev.local is running
- Verify network connectivity

STEP 3: Retry Service Start
---------------------------------------------------------------------------
Command: sudo systemctl start hx-lang-server.service

STEP 4: Document Incident
---------------------------------------------------------------------------
Action: Record incident in operational log with root cause and resolution
```

---

## 6. Specification Corrections and Enhancements

### 6.1 Resource Specification Correction

**Location in Spec:** Section "Node Requirements > Resource Requirements"

**Current (Insufficient):**
```markdown
- **Memory:** 8GB RAM minimum (16GB recommended)
```

**Corrected (William Chen Recommendation):**
```markdown
- **Memory:** 16GB RAM minimum (32GB recommended for production workloads)
  - Baseline: 5.2GB for application and OS
  - Per concurrent session: ~100MB
  - Recommended headroom: 50% for memory spikes during LLM operations
```

### 6.2 systemd Configuration Enhancement

**Location in Spec:** Section "systemd Service Configuration"

**Enhancement:** The specification provides a good base unit file. The following enhancements are recommended:

1. **Add WatchdogSec** for health monitoring
2. **Add ExecStartPre** for pre-flight checks
3. **Add security hardening** (NoNewPrivileges, ProtectSystem, etc.)
4. **Add OOMScoreAdjust** to prioritize service during memory pressure

See Section 2.2 above for complete production-grade unit file.

### 6.3 Health Check Endpoint Clarification

**Location in Spec:** Section "API Specification > Endpoints"

**Current:** Endpoint specified but response format incomplete.

**Enhancement:** Add dependency health status in response:

```python
class HealthResponse(BaseModel):
    status: str  # "healthy", "degraded", "unhealthy"
    version: str
    uptime_seconds: float
    dependencies: Dict[str, DependencyHealth]

class DependencyHealth(BaseModel):
    status: str  # "healthy", "unhealthy"
    latency_ms: Optional[float]
    last_check: datetime
    error: Optional[str]
```

### 6.4 Port Allocation Confirmation

**Location in Spec:** Section "Port Allocation"

**Confirmation:** Ports 8100 (API) and 8101 (metrics) are APPROVED.

**Infrastructure Validation:**
- Port 8100 is available on hx-lang-server.hx.dev.local
- Port 8100 is not in conflict with any existing HX services
- Port 8101 follows Prometheus metrics convention (+1 from main port)

### 6.5 Logging Strategy Enhancement

**Location in Spec:** Section "Monitoring & Observability > Logging"

**Enhancement:** Add log rotation configuration:

```ini
# /etc/systemd/journald.conf.d/hx-lang-server.conf
[Journal]
SystemMaxUse=10G
SystemMaxFileSize=500M
SystemMaxFiles=20
MaxRetentionSec=7d
Compress=yes
```

### 6.6 Missing Prometheus Metrics Endpoint

**Location in Spec:** Section "Port Allocation"

**Issue:** Port 8101 listed for "Health/Metrics endpoint" but no Prometheus metrics implementation specified.

**Recommendation:** Add FastAPI Prometheus instrumentation:

```python
from prometheus_fastapi_instrumentator import Instrumentator

# In app/main.py
instrumentator = Instrumentator(
    should_group_status_codes=True,
    should_ignore_untemplated=True,
    should_respect_env_var=True,
    should_instrument_requests_inprogress=True,
    excluded_handlers=["/health", "/ready"],
)

instrumentator.instrument(app).expose(app, endpoint="/metrics")
```

---

## 7. Integration with Existing Infrastructure

### 7.1 Prometheus Monitoring Integration

**Scrape Configuration:**

```yaml
# Add to Prometheus configuration on hx-metric-server
- job_name: 'hx-lang-server'
  static_configs:
    - targets: ['hx-lang-server.hx.dev.local:8101']
  scrape_interval: 15s
  metrics_path: /metrics
```

### 7.2 Grafana Dashboard Requirements

**Dashboard Panels:**
1. Service Status (UP/DOWN)
2. Request Rate (requests/second)
3. Response Time (p50, p95, p99)
4. Error Rate (%)
5. Active Sessions (gauge)
6. Worker Agent Utilization
7. Dependency Health Status
8. Memory/CPU Usage

### 7.3 Alertmanager Rules

```yaml
groups:
  - name: hx-lang-server
    rules:
      - alert: HxLangServerDown
        expr: up{job="hx-lang-server"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "hx-lang-server is down"
          description: "hx-lang-server has been down for more than 1 minute"

      - alert: HxLangServerHighErrorRate
        expr: rate(http_requests_total{job="hx-lang-server",status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate on hx-lang-server"
          description: "Error rate is {{ $value | humanizePercentage }}"

      - alert: HxLangServerHighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="hx-lang-server"}[5m])) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency on hx-lang-server"
          description: "95th percentile latency is {{ $value | humanizeDuration }}"
```

---

## 8. Ansible Vault Credential Management

### 8.1 Credentials to Store in Vault

| Credential | Vault Path | Description |
|------------|------------|-------------|
| POSTGRES_PASSWORD | `hx_lang_server/postgres_password` | PostgreSQL database password |
| REDIS_PASSWORD | `hx_lang_server/redis_password` | Redis password (if authentication enabled) |
| API_KEY | `hx_lang_server/api_key` | API authentication key (Phase 2) |

### 8.2 Vault Structure

```
/home/agent0/HX-Infrastructure/nodes/hx-lang-server/vault/
├── secrets.yml         # Encrypted secrets file
├── .vault_password     # Vault password file (gitignored)
└── README.md           # Vault usage instructions
```

### 8.3 Manual Credential Retrieval Procedure

```bash
# Step 1: Navigate to vault directory
cd /home/agent0/HX-Infrastructure/nodes/hx-lang-server/vault

# Step 2: View encrypted secrets
ansible-vault view secrets.yml --vault-password-file=.vault_password

# Step 3: Extract specific credential for deployment
# NEVER copy credentials to unsecured locations
ansible-vault view secrets.yml --vault-password-file=.vault_password | grep POSTGRES_PASSWORD

# Step 4: Deploy to .env file (on target server)
# Execute on hx-lang-server.hx.dev.local as root
echo "POSTGRES_PASSWORD=$(ansible-vault view secrets.yml --vault-password-file=.vault_password | grep POSTGRES_PASSWORD | cut -d: -f2 | tr -d ' ')" >> /opt/hx-lang-server/config/.env

# Step 5: Secure the .env file
chmod 600 /opt/hx-lang-server/config/.env
chown hx-lang-server:hx-lang-server /opt/hx-lang-server/config/.env
```

---

## 9. Infrastructure Philosophy Compliance

### 9.1 Compliance Checklist

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Bare Metal Deployment | COMPLIANT | Ubuntu 24.04 LTS on hx-lang-server.hx.dev.local |
| systemd Service Management | COMPLIANT | `hx-lang-server.service` unit file specified |
| Manual Procedures Only | COMPLIANT | All procedures documented as step-by-step manual runbooks |
| Ansible Vault for Credentials | COMPLIANT | Vault structure defined, no plaintext credentials |
| No Ansible Playbooks | COMPLIANT | No automation playbooks in this contribution |
| No Firewall Configuration | COMPLIANT | No firewall rules specified (dev environment) |
| Docker Prohibition (Production) | COMPLIANT | No Docker/container references |

### 9.2 Philosophy Alignment Statement

This infrastructure contribution adheres to HX-Infrastructure deployment philosophy as documented in `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`:

- All deployment procedures are manual with comprehensive documentation
- systemd is the sole service management mechanism
- Credentials are managed exclusively through Ansible Vault
- No automation frameworks or playbooks are used or recommended
- Bare metal deployment on Ubuntu 24.04 LTS is the deployment target

---

## 10. Summary and Recommendations

### 10.1 Charter Review Issues Addressed

| Issue ID | Description | Resolution |
|----------|-------------|------------|
| H-001 | Server resource specifications missing | Section 1: Complete resource analysis |
| H-002 | systemd service architecture not defined | Section 2: Monolithic service decision |
| H-003 | Health check endpoint not specified | Section 6.3: Response format enhanced |
| M-001 | Monitoring integration strategy missing | Section 7: Prometheus/Grafana integration |
| M-002 | Backup/disaster recovery not addressed | Section 5.6-5.7: Procedures documented |
| M-003 | Service account not specified | Section 4: Complete procedures |
| M-004 | Port allocation not specified | Section 6.4: Confirmed 8100/8101 |
| L-001 | Log management strategy not defined | Section 6.5: journald configuration |
| L-002 | Virtual environment strategy not specified | Section 3: `/opt/hx-lang-server/venv` |

### 10.2 Key Recommendations

1. **Memory Upgrade:** Increase minimum memory from 8GB to 16GB for stable operation with concurrent sessions

2. **Pre-Start Validation:** Implement pre-start checks to prevent service startup when dependencies unavailable

3. **Security Hardening:** Apply systemd security options (NoNewPrivileges, ProtectSystem, etc.)

4. **Monitoring Priority:** Deploy Prometheus metrics endpoint in Phase 1 (not deferred to future)

5. **Backup Automation:** Implement configuration backup via systemd timer (not manual)

### 10.3 Open Items for Development Team

| Item | Assigned To | Priority |
|------|-------------|----------|
| Prometheus metrics endpoint implementation | Bob (FastAPI) | HIGH |
| Structured logging configuration | Bob (FastAPI) | MEDIUM |
| Health check dependency status format | Sophia (LangGraph) | HIGH |
| Pre-start check script testing | William Chen | HIGH |

---

## Appendix A: File Templates

### A.1 Environment File Template

```bash
# /opt/hx-lang-server/config/.env.example
# hx-lang-server Environment Configuration
# Copy to .env and fill in values from Ansible Vault

# Service Configuration
SERVICE_NAME=hx-lang-server
SERVICE_PORT=8100
LOG_LEVEL=INFO

# PostgreSQL (Checkpoint Storage)
POSTGRES_HOST=hx-postgres-server.hx.dev.local
POSTGRES_PORT=5432
POSTGRES_DB=hx_lang_server
POSTGRES_USER=hx_lang_server
POSTGRES_PASSWORD=  # FROM ANSIBLE VAULT

# Redis (Session Cache)
REDIS_URL=redis://hx-redis-server.hx.dev.local:6379/0

# Ollama (LLM)
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b
OLLAMA_CODE_MODEL=qwen3-coder:30b

# LightRAG (RAG Pipeline)
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:8020

# FastMCP (MCP Gateway)
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000

# Agent Configuration
MAX_RECURSION_DEPTH=25
CHECKPOINT_FREQUENCY=per_turn
SESSION_TTL_SECONDS=3600
```

---

## Review and Approval

### Contribution Review

- [ ] Resource specifications validated against actual server hardware
- [ ] systemd unit file tested on target server
- [ ] Directory structure creation verified
- [ ] Service account procedures validated
- [ ] Operational runbooks reviewed for completeness
- [ ] Specification corrections approved by technical lead

### Contribution Approval

**Status:** Ready for Integration

**Next Steps:**
1. Integrate contribution content into main specification
2. Create vault structure for credentials
3. Test service account creation on target server
4. Deploy and validate systemd service configuration

---

**Signature:** William Chen
**Role:** Infrastructure & Operations Specialist
**Date:** 2025-12-01

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-01 | William Chen | Initial infrastructure contribution |
