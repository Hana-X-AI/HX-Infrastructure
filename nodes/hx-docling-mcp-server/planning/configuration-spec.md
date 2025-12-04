# Configuration Specification: Docling MCP Server

**Project**: hx-docling-mcp-server | **Date**: 2025-11-27 (Created), 2025-12-04 (Operational) | **Version**: 1.0
**Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
**Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md`
**Architecture**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/deployment-architecture.md`
**Status**: ✅ COMPLETE - Configuration Applied, Service OPERATIONAL

---

## Table of Contents

1. [Server Configuration](#1-server-configuration)
2. [System Packages](#2-system-packages)
3. [Python Environment](#3-python-environment)
4. [Directory Structure](#4-directory-structure)
5. [Systemd Service Configuration](#5-systemd-service-configuration)
6. [Environment Variables](#6-environment-variables)
7. [Logging Configuration](#7-logging-configuration)
8. [Samba AD Integration](#8-samba-ad-integration)
9. [Network Configuration](#9-network-configuration)
10. [Storage Configuration](#10-storage-configuration)
11. [Integration Configuration](#11-integration-configuration)
12. [Monitoring and Health Checks](#12-monitoring-and-health-checks)

---

## 1. Server Configuration

### 1.1 Server Identity

**Hostname**: `hx-docling-mcp-server.hx.dev.local`
**IP Address**: `hx-docling-mcp-server.hx.dev.local` (static, assigned from HX-Infrastructure internal network)
**Domain**: `hx.dev.local` (Samba AD domain)

### 1.2 Operating System

**OS**: Ubuntu 24.04 LTS (bare-metal installation, NO Docker)
**Kernel**: Linux 5.15+ (Ubuntu default kernel)
**Architecture**: x86_64 (64-bit)

**Installation Type**: Bare-metal server deployment
- No virtualization layer
- No container runtime (Docker prohibited for production per HX-Infrastructure standards)
- Direct OS installation on physical hardware

### 1.3 Hardware Requirements

**CPU**:
- Minimum: 2 cores
- Recommended: 4 cores
- Rationale: Document processing is CPU-intensive (PDF parsing, OCR, docling library)

**RAM**:
- Minimum: 4GB
- Recommended: 8GB
- Rationale: Docling library loads documents into memory, LightRAG processing, Python runtime overhead

**Disk**:
- Total Required: 10GB minimum
- Breakdown:
  - `/opt/docling-mcp/`: 500MB (application code + Python virtual environment)
  - `/var/lib/docling-mcp/`: 5GB (cache, working directory for document processing)
  - `/var/log/docling-mcp/`: 1GB (logs with rotation, 10-file retention)
  - `/etc/docling-mcp/`: 10MB (configuration files, .env)
  - System overhead: 3GB (OS, system packages, dependencies)

**Network**:
- Interface: Internal network interface (192.168.10.0/24)
- Speed: 1 Gbps minimum (standard internal network)
- IPv4: Required
- IPv6: Not required (HX-Infrastructure uses IPv4 only)

### 1.4 Network Configuration

**IP Assignment**:
```bash
# Static IP configuration
# /etc/netplan/01-netcfg.yaml

network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:  # Interface name (verify with: ip link show)
      addresses:
        - 192.168.10.217/24  # Static IPv4 address in CIDR notation
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses:
          - 192.168.10.200   # Primary DNS (hx-dc-server)
        search:
          - hx.dev.local
```

**DNS Configuration**:
- Primary DNS: 192.168.10.200 (hx-dc-server - Samba AD DC)
- Search domain: hx.dev.local

**Note**: Secondary DNS (hx-dc2-server) not yet deployed in infrastructure. Add when available.

**Validation**: After applying changes, validate with:
```bash
# Test configuration
sudo netplan try

# Apply if successful
sudo netplan apply

# Verify connectivity
ping -c 3 192.168.10.1     # Gateway
ping -c 3 192.168.10.200   # DNS server
nslookup hx-docling-mcp-server.hx.dev.local 192.168.10.200
```

**Hostname Resolution**:
```bash
# /etc/hosts
127.0.0.1       localhost
hx-docling-mcp-server.hx.dev.local  hx-docling-mcp-server.hx.dev.local hx-docling-mcp-server

# IPv6 (disabled)
# ::1 localhost ip6-localhost ip6-loopback
```

### 1.5 Firewall Configuration

**Firewall Status**: DISABLED (per HX-Infrastructure standard)

**Rationale**: All HX-Infrastructure nodes operate on isolated internal network (192.168.10.0/24) with network-level isolation. No firewalls configured on individual nodes.

**What WOULD be needed if firewall enabled** (documentation only):
```bash
# Inbound rules (REFERENCE ONLY - NOT CONFIGURED)
# Port 8000/tcp  - MCP HTTP endpoint (from internal network)
# Port 8443/tcp  - MCP HTTPS endpoint (optional, if TLS configured)
# Port 22/tcp    - SSH management (from admin workstation)

# Example ufw rules (NOT APPLIED):
# sudo ufw allow from 192.168.10.0/24 to any port 8000 proto tcp
# sudo ufw allow from 192.168.10.0/24 to any port 8443 proto tcp
# sudo ufw allow from hx-control-node.hx.dev.local to any port 22 proto tcp
```

---

## 2. System Packages

### 2.1 Core System Packages

**Package Installation Order** (manual apt-get installation):

```bash
# 1. System update (always first)
sudo apt-get update
sudo apt-get upgrade -y

# 2. Build tools (required for Python package compilation)
sudo apt-get install -y build-essential
sudo apt-get install -y gcc g++ make
sudo apt-get install -y pkg-config

# 3. Python 3.11+ runtime
sudo apt-get install -y python3.11
sudo apt-get install -y python3.11-venv
sudo apt-get install -y python3.11-dev
sudo apt-get install -y python3-pip

# 4. Document processing dependencies
sudo apt-get install -y poppler-utils        # PDF rendering (pypdfium2 backend)
sudo apt-get install -y tesseract-ocr        # OCR engine for scanned PDFs/images
sudo apt-get install -y tesseract-ocr-eng    # English language data
sudo apt-get install -y libmagic1            # MIME type detection
sudo apt-get install -y libmagic-dev         # MIME type detection (development headers)

# 5. Image processing dependencies
sudo apt-get install -y libpng-dev
sudo apt-get install -y libjpeg-dev
sudo apt-get install -y libtiff-dev

# 6. System utilities
sudo apt-get install -y curl
sudo apt-get install -y wget
sudo apt-get install -y git
sudo apt-get install -y vim
sudo apt-get install -y htop
sudo apt-get install -y net-tools

# 7. Systemd (already installed on Ubuntu 24.04)
# No additional installation needed
```

### 2.2 Package Version Verification

**After installation, verify package versions**:

```bash
# Python version (must be 3.11 or higher)
python3.11 --version
# Expected: Python 3.11.x

# Poppler version
pdftotext -v
# Expected: pdftotext version 23.x or higher

# Tesseract version
tesseract --version
# Expected: tesseract 5.x or higher

# libmagic version
file --version
# Expected: file-5.x
```

### 2.3 System Package Dependencies Matrix

| Package | Version | Purpose | Required By |
|---------|---------|---------|-------------|
| python3.11 | 3.11+ | Python runtime | FastMCP, docling, LightRAG |
| python3.11-venv | 3.11+ | Virtual environment | Isolated Python environment |
| python3.11-dev | 3.11+ | Python development headers | Compiling Python C extensions |
| build-essential | 12.x | Compilation tools (gcc, make) | Python package compilation |
| poppler-utils | 23.x+ | PDF rendering toolkit | docling PDF processing |
| tesseract-ocr | 5.x+ | OCR engine | docling image/scanned PDF processing |
| libmagic1 | 5.x | MIME type detection | docling format detection |
| libpng-dev | 1.6+ | PNG image processing | PIL/Pillow image operations |
| libjpeg-dev | 8+ | JPEG image processing | PIL/Pillow image operations |

---

## 3. Python Environment

### 3.1 Virtual Environment Setup

**Virtual Environment Location**: `/opt/docling-mcp/venv`

**Creation Commands** (manual procedure):

```bash
# Create application directory
sudo mkdir -p /opt/docling-mcp
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp

# Create Python virtual environment
sudo -u docling-mcp@hx.dev.local python3.11 -m venv /opt/docling-mcp/venv

# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel
```

### 3.2 Python Dependencies

**Requirements File**: `/opt/docling-mcp/requirements.txt`

```txt
# MCP Protocol Framework
fastmcp==0.5.0

# Document Processing
docling~=2.25.0
docling-core>=1.0.0
docling-parse>=1.0.0

# Knowledge Graph Framework
lightrag==0.2.0
lightrag-kg>=0.1.0

# Vector Database Client
qdrant-client==1.7.3

# Redis Client
redis[hiredis]==5.0.1
redis-py-cluster==2.1.3

# LLM Integration
litellm==1.20.0

# Data Validation
pydantic~=2.10.0
pydantic-settings==2.1.0

# Async HTTP Client
aiohttp==3.9.1
aiofiles==23.2.1

# Image Processing
Pillow==10.1.0
pytesseract==0.3.10

# Document Format Support
python-docx==1.1.0
python-pptx==0.6.23
openpyxl==3.1.2
beautifulsoup4==4.12.2
lxml==4.9.3

# PDF Processing
pypdfium2==4.25.0

# MIME Type Detection
python-magic==0.4.27

# Retry Logic
tenacity==8.2.3

# Utilities
python-dotenv==1.0.0
pyyaml==6.0.1
click==8.1.7

# Logging
structlog==24.1.0
python-json-logger==2.0.7

# Monitoring (Optional - Phase 2)
prometheus-client==0.19.0

# Testing (for deployment validation)
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
```

**Installation Commands** (manual procedure):

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Install dependencies
pip install -r /opt/docling-mcp/requirements.txt

# Verify installation
pip list
pip check  # Verify no dependency conflicts
```

### 3.3 Python Package Verification

**After installation, verify critical packages**:

```bash
# Activate venv
source /opt/docling-mcp/venv/bin/activate

# Verify FastMCP
python -c "import fastmcp; print(fastmcp.__version__)"
# Expected: 0.5.0

# Verify docling
python -c "import docling; print(docling.__version__)"
# Expected: 2.25.x

# Verify LightRAG
python -c "import lightrag; print(lightrag.__version__)"
# Expected: 0.2.0

# Verify Qdrant client
python -c "import qdrant_client; print(qdrant_client.__version__)"
# Expected: 1.7.3

# Verify Redis client
python -c "import redis; print(redis.__version__)"
# Expected: 5.0.1

# Verify LiteLLM
python -c "import litellm; print(litellm.__version__)"
# Expected: 1.20.0
```

---

## 4. Directory Structure

### 4.1 Complete Directory Tree

```
/opt/docling-mcp/                           # Application root
├── venv/                                   # Python virtual environment
│   ├── bin/
│   │   ├── python                          # Python interpreter
│   │   ├── pip                             # Package installer
│   │   └── activate                        # Activation script
│   ├── lib/
│   │   └── python3.11/
│   │       └── site-packages/              # Installed packages
│   └── pyvenv.cfg
├── application/                            # Application code
│   ├── docling_mcp/
│   │   ├── __init__.py
│   │   ├── server.py                       # Main server entry point
│   │   ├── tools/                          # MCP tool implementations
│   │   │   ├── conversion.py               # Conversion tools (3 tools)
│   │   │   ├── generation.py               # Generation tools (11 tools)
│   │   │   └── manipulation.py             # Manipulation tools (5 tools)
│   │   ├── processors/
│   │   │   ├── docling_processor.py        # Docling library integration
│   │   │   ├── lightrag_processor.py       # LightRAG integration
│   │   │   └── ocr_processor.py            # OCR processing
│   │   ├── clients/
│   │   │   ├── litellm_client.py           # LiteLLM client
│   │   │   ├── qdrant_client.py            # Qdrant client
│   │   │   └── redis_client.py             # Redis client
│   │   ├── utils/
│   │   │   ├── config.py                   # Configuration loader
│   │   │   ├── logging.py                  # Logging setup
│   │   │   └── validators.py               # Input validation
│   │   └── models/
│   │       ├── docling_document.py         # DoclingDocument models
│   │       └── knowledge_graph.py          # Knowledge graph models
│   ├── config.py                           # Application configuration
│   └── requirements.txt                    # Python dependencies
├── backups/                                # Manual backup directory
│   └── config/                             # Configuration backups
└── vault/                                  # Ansible Vault (symlink)
    -> /home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/

/etc/docling-mcp/                           # Configuration directory
├── .env                                    # Environment variables (secrets)
├── .env.template                           # Template for .env (no secrets)
├── logging.conf                            # Logging configuration
└── certs/                                  # SSL/TLS certificates (optional)
    ├── server.crt                          # Server certificate
    └── server.key                          # Private key

/var/lib/docling-mcp/                       # Data directory
├── cache/                                  # Docling cache
├── workspace/                              # Document processing workspace
└── lightrag/                               # LightRAG working directory
    ├── entities/                           # Entity storage
    ├── relations/                          # Relationship storage
    └── indices/                            # Index files

/var/log/docling-mcp/                       # Log directory
├── docling-mcp.log                         # Main application log
├── error.log                               # Error-level logs
├── access.log                              # MCP request/response log
└── archived/                               # Rotated logs (gzip compressed)
```

### 4.2 Directory Creation Commands

**Manual directory creation procedure**:

```bash
# Application directory
sudo mkdir -p /opt/docling-mcp/{application,backups/config,vault}

# Configuration directory
sudo mkdir -p /etc/docling-mcp/certs

# Data directory
sudo mkdir -p /var/lib/docling-mcp/{cache,workspace,lightrag/{entities,relations,indices}}

# Log directory
sudo mkdir -p /var/log/docling-mcp/archived
```

### 4.3 File Ownership and Permissions

**Ownership** (Samba AD service account):
- User: `docling-mcp@hx.dev.local`
- Group: `domain users@hx.dev.local`

**Permission Commands** (manual procedure):

```bash
# Application directory (read/write for service account)
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp
sudo chmod 755 /opt/docling-mcp
sudo chmod 755 /opt/docling-mcp/application

# Set permissions for all Python files recursively (find-based)
sudo find /opt/docling-mcp/application -type f -name '*.py' -exec chmod 644 {} +

# Set permissions for all directories recursively (ensure executable bit)
sudo find /opt/docling-mcp/application -type d -exec chmod 755 {} +

# Set permissions for virtualenv bin scripts (keep executable)
sudo chmod 755 /opt/docling-mcp/venv/bin/*

# Configuration directory (read-only for service, write for admin)
sudo chown -R root:docling-mcp@hx.dev.local /etc/docling-mcp
sudo chmod 750 /etc/docling-mcp
sudo chmod 640 /etc/docling-mcp/.env          # Secrets file (read-only)
sudo chmod 644 /etc/docling-mcp/.env.template
sudo chmod 644 /etc/docling-mcp/logging.conf
sudo chmod 700 /etc/docling-mcp/certs         # Certificate directory (restricted)
sudo chmod 600 /etc/docling-mcp/certs/server.key  # Private key (highly restricted)
sudo chmod 644 /etc/docling-mcp/certs/server.crt

# Data directory (read/write for service account)
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/lib/docling-mcp
sudo chmod 755 /var/lib/docling-mcp
sudo chmod 755 /var/lib/docling-mcp/{cache,workspace,lightrag}

# Log directory (read/write for service account)
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/log/docling-mcp
sudo chmod 755 /var/log/docling-mcp
sudo chmod 644 /var/log/docling-mcp/*.log
```

**Permission Matrix**:

| Path | Owner | Group | Permissions | Rationale |
|------|-------|-------|-------------|-----------|
| `/opt/docling-mcp/` | docling-mcp@hx.dev.local | domain users@hx.dev.local | 755 (rwxr-xr-x) | Service needs read/execute |
| `/opt/docling-mcp/venv/` | docling-mcp@hx.dev.local | domain users@hx.dev.local | 755 | Virtual environment execution |
| `/etc/docling-mcp/` | root | docling-mcp@hx.dev.local | 750 (rwxr-x---) | Admin write, service read |
| `/etc/docling-mcp/.env` | root | docling-mcp@hx.dev.local | 640 (rw-r-----) | Secrets file (restricted) |
| `/etc/docling-mcp/certs/server.key` | root | root | 600 (rw-------) | Private key (highly restricted) |
| `/var/lib/docling-mcp/` | docling-mcp@hx.dev.local | domain users@hx.dev.local | 755 | Service needs read/write |
| `/var/log/docling-mcp/` | docling-mcp@hx.dev.local | domain users@hx.dev.local | 755 | Service needs write for logs |

---

## 5. Systemd Service Configuration

### 5.1 Systemd Unit File

**File Location**: `/etc/systemd/system/docling-mcp.service`

**Complete Unit File**:

```ini
[Unit]
Description=Docling MCP Server - Document Processing Gateway
Documentation=https://github.com/Hana-X-AI/HX-Infrastructure/nodes/hx-docling-mcp-server
After=network-online.target
Wants=network-online.target
StartLimitBurst=3
StartLimitIntervalSec=60

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
ExecStartPre=/bin/bash -c 'test -n "$LITELLM_BASE_URL" || (echo "ERROR: LITELLM_BASE_URL not set" && exit 1)'
ExecStartPre=/usr/bin/curl -f -s -m 5 http://hx-litellm-server.hx.dev.local:4000/health || (echo "ERROR: LiteLLM health check failed" && exit 1)
ExecStartPre=/bin/bash -c 'test -r /etc/docling-mcp/.env || (echo "ERROR: .env file not readable" && exit 1)'
ExecStartPre=/bin/bash -c 'test $(df /var/lib/docling-mcp | tail -1 | awk "{print \\$4}") -gt 1048576 || (echo "ERROR: Insufficient disk space (<1GB)" && exit 1)'
ExecStartPre=/bin/bash -c 'test -d /opt/docling-mcp/venv || (echo "ERROR: Virtual environment not found" && exit 1)'
ExecStartPre=/bin/bash -c 'test -x /opt/docling-mcp/venv/bin/python || (echo "ERROR: Python interpreter not executable" && exit 1)'

# Start command
ExecStart=/opt/docling-mcp/venv/bin/python -m docling_mcp.server

# Reload signal (HUP for graceful reload)
ExecReload=/bin/kill -HUP $MAINPID

# Restart policy
Restart=on-failure
RestartSec=10

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
```

**Architecture Note: Samba AD Integration with Group Name Spaces**:

The systemd `Group=domain users@hx.dev.local` directive uses a Samba AD group name containing spaces. This is a deliberate architectural decision for HX-Infrastructure:

**Rationale**:
- **Centralized identity management**: All services use Samba AD authentication
- **Consistent access control**: AD group membership controls service permissions
- **No local user proliferation**: Avoids creating separate local users per service

**Technical Considerations**:
- **Systemd compatibility**: systemd properly handles group names with spaces (tested and verified)
- **Logrotate limitation**: The `logrotate` utility cannot parse group names with spaces in the `create` directive. Solution: Use local `docling-mcp` group for log file ownership (AD user added to local group)
- **File ownership**: Use quotes when setting ownership via `chown`: `chown 'docling-mcp@hx.dev.local:domain users@hx.dev.local'`

**Alternative Considered**: Using dedicated local service users/groups (e.g., `docling-mcp:docling-mcp`) would eliminate the space issue but would require:
- Creating local users on every server
- Managing separate permissions outside AD
- Loss of centralized access control

**Decision**: Continue using Samba AD integration with workarounds for tools that don't support spaces (e.g., logrotate uses local group).

### 5.2 Service Dependencies

**CRITICAL: HX-Infrastructure Systemd Dependency Policy**:
- **NO `Requires=` directives** (per deployment-requirements.md standards)
- **Use `After=` and `Wants=` only** for ordering, NOT hard dependencies
- **Application-level dependency checks** with retry logic (not systemd-level)

**Network Dependency**:
```ini
After=network-online.target
Wants=network-online.target
```

**Rationale**: Docling MCP Server only requires network connectivity. All external service dependencies (LiteLLM, Qdrant, Redis) are checked at application runtime with retry logic.

**NO cross-node systemd dependencies**:
- LiteLLM (hx-litellm-server): Application-level retry
- Qdrant (hx-qdrant-server): Application-level retry
- Redis (hx-redis-server): Application-level retry

### 5.3 Restart Policies

**Restart Configuration**:
```ini
Restart=on-failure
RestartSec=10
StartLimitBurst=3
StartLimitIntervalSec=60
```

**Restart Behavior**:
- **on-failure**: Restart only if process exits with non-zero status
- **RestartSec**: Wait 10 seconds before restart attempt
- **StartLimitBurst**: Maximum 3 restart attempts
- **StartLimitIntervalSec**: Reset restart counter after 60 seconds

**Failure Scenarios**:
1. **Dependency failure** (LiteLLM/Qdrant/Redis unavailable):
   - Pre-start check fails (ExecStartPre)
   - systemd waits 10 seconds, retries (up to 3 attempts)
   - If still failing after 3 attempts, service enters failed state
   - Manual intervention required

2. **Application crash**:
   - Process exits with non-zero status
   - systemd automatically restarts (up to 3 attempts)
   - If crash persists, service enters failed state

3. **Graceful shutdown**:
   - SIGTERM signal sent to process
   - Process has 30 seconds to complete in-flight requests (TimeoutStopSec)
   - If process doesn't exit, SIGKILL sent
   - No restart (intentional shutdown)

### 5.4 Security Hardening

**Security Directives Explained**:

| Directive | Value | Purpose |
|-----------|-------|---------|
| `PrivateTmp=true` | Enabled | Isolate /tmp directory (prevent tmpfile attacks) |
| `NoNewPrivileges=true` | Enabled | Prevent privilege escalation |
| `ProtectSystem=strict` | Enabled | Read-only filesystem except ReadWritePaths |
| `ProtectHome=true` | Enabled | Deny access to /home directories |
| `ReadWritePaths` | `/var/lib/docling-mcp /var/log/docling-mcp` | Allow writes only to data/log dirs |
| `ReadOnlyPaths` | `/etc/docling-mcp` | Configuration read-only for service |
| `ProtectKernelTunables=true` | Enabled | Deny access to /proc/sys, /sys |
| `ProtectKernelModules=true` | Enabled | Deny kernel module loading |
| `ProtectControlGroups=true` | Enabled | Deny cgroup modifications |
| `RestrictAddressFamilies` | AF_INET, AF_INET6, AF_UNIX | Allow only network sockets (TCP/UDP/Unix) |
| `RestrictNamespaces=true` | Enabled | Deny namespace creation |
| `LockPersonality=true` | Enabled | Prevent personality changes |
| `RestrictRealtime=true` | Enabled | Deny realtime scheduling |
| `RestrictSUIDSGID=true` | Enabled | Deny setuid/setgid execution |
| `RemoveIPC=true` | Enabled | Remove IPC objects on service stop |

### 5.5 Service Management Commands

**Installation and Management** (manual procedure):

```bash
# 1. Install systemd unit file
sudo cp docling-mcp.service /etc/systemd/system/docling-mcp.service
sudo chmod 644 /etc/systemd/system/docling-mcp.service

# 2. Reload systemd daemon
sudo systemctl daemon-reload

# 3. Enable service (start on boot)
sudo systemctl enable docling-mcp.service

# 4. Start service
sudo systemctl start docling-mcp.service

# 5. Verify service status
sudo systemctl status docling-mcp.service

# 6. View service logs
sudo journalctl -u docling-mcp.service -f

# 7. View recent logs
sudo journalctl -u docling-mcp.service -n 100 --no-pager

# 8. Reload configuration (graceful reload)
sudo systemctl reload docling-mcp.service

# 9. Restart service (full restart)
sudo systemctl restart docling-mcp.service

# 10. Stop service
sudo systemctl stop docling-mcp.service

# 11. Disable service (prevent start on boot)
sudo systemctl disable docling-mcp.service

# 12. Check service dependencies
sudo systemctl list-dependencies docling-mcp.service

# 13. View service resource usage
sudo systemctl status docling-mcp.service
```

---

## 6. Environment Variables

### 6.1 Environment File (.env)

**File Location**: `/etc/docling-mcp/.env`

**Complete Environment Configuration**:

```bash
# /etc/docling-mcp/.env
# Docling MCP Server Environment Configuration
# DO NOT commit this file to git - contains secrets

# =============================================================================
# Service Identity
# =============================================================================
SERVICE_NAME=docling-mcp
SERVICE_HOST=hx-docling-mcp-server.hx.dev.local
SERVICE_PORT=8000
SERVICE_HTTPS_PORT=8443

# =============================================================================
# MCP Protocol Configuration
# =============================================================================
MCP_TRANSPORTS=http,sse,stdio
MCP_HTTP_ENABLED=true
MCP_SSE_ENABLED=true
MCP_STDIO_ENABLED=true
MCP_HTTP_BIND=hx-docling-mcp-server.hx.dev.local
MCP_HTTP_PORT=8000

# =============================================================================
# Python Environment
# =============================================================================
PYTHON_ENV=production
LOG_LEVEL=INFO
DEBUG=false
PYTHONUNBUFFERED=1

# =============================================================================
# LiteLLM Gateway Configuration
# =============================================================================
LITELLM_BASE_URL=http://hx-litellm-server.hx.dev.local:4000
LITELLM_API_KEY=<from_ansible_vault>
LITELLM_TIMEOUT=120
LITELLM_MAX_RETRIES=3
LITELLM_RETRY_DELAY=2

# Model Routing (via LiteLLM)
LITELLM_ENTITY_EXTRACTION_MODEL=ollama/gemma3:27b
LITELLM_FALLBACK_MODEL=ollama/gpt-oss:20b
LITELLM_DOCLING_MODEL=ollama/granite-docling:258m
LITELLM_EMBEDDING_MODEL=ollama/bge-m3:567m

# =============================================================================
# Qdrant Vector Database Configuration
# =============================================================================
QDRANT_HOST=hx-qdrant-server.hx.dev.local
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334
QDRANT_COLLECTION_PREFIX=docling_mcp_
QDRANT_TIMEOUT=60
QDRANT_MAX_RETRIES=3
QDRANT_RETRY_DELAY=2

# Qdrant Collection Configuration
QDRANT_EMBEDDING_DIM=1024
QDRANT_DISTANCE_METRIC=Cosine
QDRANT_SHARD_NUMBER=2
QDRANT_REPLICATION_FACTOR=1

# =============================================================================
# Redis Cache Configuration
# =============================================================================
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=<from_ansible_vault>
REDIS_SESSION_TTL=3600
REDIS_DOCUMENT_TTL=3600
REDIS_POOL_SIZE=10
REDIS_MAX_RETRIES=3
REDIS_RETRY_DELAY=1

# =============================================================================
# Docling Library Configuration
# =============================================================================
DOCLING_CACHE_DIR=/var/lib/docling-mcp/cache
DOCLING_WORKING_DIR=/var/lib/docling-mcp/workspace
DOCLING_MAX_FILE_SIZE_MB=100
DOCLING_SUPPORTED_FORMATS=pdf,docx,pptx,xlsx,html,png,jpg,jpeg
DOCLING_OCR_ENABLED=true
DOCLING_LAYOUT_ANALYSIS=true

# =============================================================================
# LightRAG Knowledge Graph Configuration
# =============================================================================
LIGHTRAG_WORKING_DIR=/var/lib/docling-mcp/lightrag
LIGHTRAG_STORAGE_BACKEND=qdrant
LIGHTRAG_ENTITY_EXTRACTION_LLM=litellm/ollama/gemma3:27b
LIGHTRAG_MIN_ENTITY_LENGTH=3
LIGHTRAG_MAX_ENTITIES_PER_DOC=500
LIGHTRAG_CONFIDENCE_THRESHOLD=0.7

# =============================================================================
# Concurrency Configuration
# =============================================================================
MAX_CONCURRENT_REQUESTS=10
THREAD_POOL_SIZE=4
CONNECTION_POOL_SIZE_LITELLM=20
CONNECTION_POOL_SIZE_QDRANT=10
CONNECTION_POOL_SIZE_REDIS=10

# =============================================================================
# Rate Limiting Configuration
# =============================================================================
RATE_LIMIT_DEFAULT=100
RATE_LIMIT_HEAVY=10
RATE_LIMIT_WINDOW=60

# =============================================================================
# Caching Configuration
# =============================================================================
MEMORY_CACHE_SIZE_MB=128
MEMORY_CACHE_MAX_ITEMS=50
CACHE_TTL_DOCUMENTS=3600
CACHE_TTL_SESSIONS=3600
CACHE_TTL_RATELIMIT=60

# =============================================================================
# Logging Configuration
# =============================================================================
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_FILE_MAIN=/var/log/docling-mcp/docling-mcp.log
LOG_FILE_ERROR=/var/log/docling-mcp/error.log
LOG_FILE_ACCESS=/var/log/docling-mcp/access.log
LOG_ROTATION_SIZE_MB=100
LOG_ROTATION_COUNT=30
LOG_COMPRESSION=gzip

# =============================================================================
# Health Check Configuration
# =============================================================================
HEALTH_CHECK_ENABLED=true
HEALTH_CHECK_INTERVAL=30
HEALTH_CHECK_TIMEOUT=10

# =============================================================================
# Security Configuration (Phase 2)
# =============================================================================
# TLS_ENABLED=false
# TLS_CERT_FILE=/etc/docling-mcp/certs/server.crt
# TLS_KEY_FILE=/etc/docling-mcp/certs/server.key
# OAUTH_ENABLED=false

# =============================================================================
# Samba AD Service Account (from Ansible Vault)
# =============================================================================
SAMBA_ACCOUNT=<from_ansible_vault>
SAMBA_PASSWORD=<from_ansible_vault>
```

### 6.2 Environment File Template (.env.template)

**File Location**: `/etc/docling-mcp/.env.template`

**Template (no secrets)**:

```bash
# /etc/docling-mcp/.env.template
# Docling MCP Server Environment Configuration Template
# Copy to .env and fill in actual values from Ansible Vault

# Service Identity
SERVICE_NAME=docling-mcp
SERVICE_HOST=hx-docling-mcp-server.hx.dev.local
SERVICE_PORT=8000

# LiteLLM Gateway
LITELLM_BASE_URL=http://hx-litellm-server.hx.dev.local:4000
LITELLM_API_KEY=<INSERT_FROM_VAULT>

# Qdrant Vector Database
QDRANT_HOST=hx-qdrant-server.hx.dev.local
QDRANT_PORT=6333

# Redis Cache
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
REDIS_PASSWORD=<INSERT_FROM_VAULT_IF_AUTH_ENABLED>

# Samba AD Service Account
SAMBA_ACCOUNT=<INSERT_FROM_VAULT>
SAMBA_PASSWORD=<INSERT_FROM_VAULT>

# See full .env for all available configuration options
```

### 6.3 Configuration Validation

**Pre-Start Validation** (systemd ExecStartPre):

```bash
# Validation checks (inline in systemd unit file)

# 1. Check required environment variables set
ExecStartPre=/bin/bash -c 'test -n "$LITELLM_BASE_URL"'
ExecStartPre=/bin/bash -c 'test -n "$QDRANT_HOST"'
ExecStartPre=/bin/bash -c 'test -n "$REDIS_HOST"'

# 2. Check LiteLLM health
ExecStartPre=/usr/bin/curl -f -s -m 5 http://hx-litellm-server.hx.dev.local:4000/health

# 3. Check .env file readable
ExecStartPre=/bin/bash -c 'test -r /etc/docling-mcp/.env'

# 4. Check disk space (>1GB free)
ExecStartPre=/bin/bash -c 'test $(df /var/lib/docling-mcp | tail -1 | awk "{print \$4}") -gt 1048576'

# 5. Check virtual environment exists
ExecStartPre=/bin/bash -c 'test -d /opt/docling-mcp/venv'

# 6. Check Python interpreter executable
ExecStartPre=/bin/bash -c 'test -x /opt/docling-mcp/venv/bin/python'
```

**Application Runtime Validation** (in application code):

```python
# Application-level configuration validation
# docling_mcp/utils/config.py

import os
import sys
from typing import Optional

class ConfigurationError(Exception):
    """Configuration validation error."""
    pass

def validate_configuration():
    """
    Validate all required configuration settings.

    Raises:
        ConfigurationError: If any required setting is missing or invalid
    """
    required_vars = [
        "LITELLM_BASE_URL",
        "QDRANT_HOST",
        "REDIS_HOST",
        "SERVICE_PORT",
        "DOCLING_CACHE_DIR",
        "LIGHTRAG_WORKING_DIR"
    ]

    missing = []
    for var in required_vars:
        if not os.getenv(var):
            missing.append(var)

    if missing:
        raise ConfigurationError(
            f"Missing required environment variables: {', '.join(missing)}"
        )

    # Validate numeric values
    try:
        port = int(os.getenv("SERVICE_PORT", "8000"))
        if port < 1024 or port > 65535:
            raise ConfigurationError(f"Invalid SERVICE_PORT: {port} (must be 1024-65535)")
    except ValueError:
        raise ConfigurationError(f"Invalid SERVICE_PORT: must be integer")

    # Validate paths exist
    for path_var in ["DOCLING_CACHE_DIR", "LIGHTRAG_WORKING_DIR"]:
        path = os.getenv(path_var)
        if not os.path.isdir(path):
            raise ConfigurationError(f"{path_var} directory does not exist: {path}")

    return True
```

---

## 7. Logging Configuration

### 7.1 Log File Locations

**Log Directory**: `/var/log/docling-mcp/`

**Log Files**:
1. **docling-mcp.log**: Main application log (INFO level, all components)
2. **error.log**: Error-level logs only (ERROR, CRITICAL)
3. **access.log**: MCP request/response logs (HTTP access logging)
4. **archived/**: Rotated logs (gzip compressed)

### 7.2 Logging Configuration File

**File Location**: `/etc/docling-mcp/logging.conf`

**Python Logging Configuration** (INI format):

```ini
# /etc/docling-mcp/logging.conf
# Docling MCP Server Logging Configuration

[loggers]
keys=root,docling_mcp,fastmcp,docling,lightrag,access

[handlers]
keys=console,file_main,file_error,file_access

[formatters]
keys=json,standard

# =============================================================================
# Loggers
# =============================================================================

[logger_root]
level=INFO
handlers=console,file_main,file_error

[logger_docling_mcp]
level=INFO
handlers=file_main,file_error
qualName=docling_mcp
propagate=0

[logger_fastmcp]
level=INFO
handlers=file_main
qualName=fastmcp
propagate=0

[logger_docling]
level=INFO
handlers=file_main
qualName=docling
propagate=0

[logger_lightrag]
level=INFO
handlers=file_main
qualName=lightrag
propagate=0

[logger_access]
level=INFO
handlers=file_access
qualName=access
propagate=0

# =============================================================================
# Handlers
# =============================================================================

[handler_console]
class=StreamHandler
level=INFO
formatter=standard
args=(sys.stdout,)

[handler_file_main]
class=logging.handlers.RotatingFileHandler
level=INFO
formatter=json
args=('/var/log/docling-mcp/docling-mcp.log', 'a', 104857600, 30, 'utf-8')

[handler_file_error]
class=logging.handlers.RotatingFileHandler
level=ERROR
formatter=json
args=('/var/log/docling-mcp/error.log', 'a', 104857600, 30, 'utf-8')

[handler_file_access]
class=logging.handlers.RotatingFileHandler
level=INFO
formatter=json
args=('/var/log/docling-mcp/access.log', 'a', 104857600, 30, 'utf-8')

# =============================================================================
# Formatters
# =============================================================================

[formatter_json]
class=pythonjsonlogger.jsonlogger.JsonFormatter
format=%(asctime)s %(name)s %(levelname)s %(message)s

[formatter_standard]
format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
datefmt=%Y-%m-%d %H:%M:%S
```

### 7.3 Log Rotation Policy

**Rotation Configuration**:
- **Rotation Trigger**: File size reaches 100MB
- **Retention**: Keep 10 rotated log files
- **Compression**: gzip compression after rotation
- **Total Storage**: ~1GB maximum (100MB × 10 files)

**Logrotate Configuration** (optional, for system-level rotation):

**File Location**: `/etc/logrotate.d/docling-mcp`

```
/var/log/docling-mcp/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 docling-mcp docling-mcp
    sharedscripts
    postrotate
        /bin/systemctl reload docling-mcp.service > /dev/null 2>/dev/null || true
    endscript
}
```

**Note**: The `create` directive uses `docling-mcp docling-mcp` (local user and group) instead of AD account with spaces. The local `docling-mcp` group should be created during service account setup and the AD user `docling-mcp@hx.dev.local` added to it. This avoids logrotate parsing issues with group names containing spaces.

### 7.4 Log Levels and Components

**Log Level Hierarchy**:
- **DEBUG**: Detailed diagnostic information (disabled in production)
- **INFO**: General informational messages (default)
- **WARNING**: Warning messages for potential issues
- **ERROR**: Error messages for recoverable failures
- **CRITICAL**: Critical errors requiring immediate attention

**Component Logging**:

| Component | Logger Name | Default Level | Purpose |
|-----------|-------------|---------------|---------|
| Main Application | docling_mcp | INFO | Application lifecycle, request processing |
| FastMCP Framework | fastmcp | INFO | MCP protocol handling, tool registration |
| Docling Library | docling | INFO | Document conversion, format detection |
| LightRAG Engine | lightrag | INFO | Knowledge graph construction, entity extraction |
| LiteLLM Client | litellm | WARNING | LLM API calls (verbose, reduce noise) |
| Qdrant Client | qdrant_client | WARNING | Vector database operations |
| Redis Client | redis | WARNING | Cache operations |
| Access Logger | access | INFO | HTTP request/response logging |

### 7.5 Structured Logging (JSON Format)

**Log Entry Format** (JSON):

```json
{
  "asctime": "2025-11-27 14:30:45,123",
  "name": "docling_mcp.tools.conversion",
  "levelname": "INFO",
  "message": "PDF conversion completed",
  "document_id": "doc-12345",
  "source": "https://example.com/document.pdf",
  "pages": 25,
  "duration_ms": 3421,
  "process_id": 12345,
  "thread_id": "MainThread"
}
```

**Benefits of JSON Logging**:
- Machine-parseable for log aggregation tools
- Structured fields for filtering and querying
- Preserves data types (integers, booleans, etc.)
- Compatible with log analysis platforms (Elasticsearch, Splunk, etc.)

---

## 8. Samba AD Integration

### 8.1 Service Account Configuration

**Service Account**: `docling-mcp@hx.dev.local`
**Password**: `<SEE_CREDENTIALS_FILE>` (See `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` for standard password - Internal - Highly Sensitive)
**Group Membership**: `domain users@hx.dev.local`

**Account Status**: CREATED (confirmed in status-report.md)

### 8.2 Computer Account

**Computer Account**: `docling-mcp$` (created by Frank Lucas, Security Specialist)
**Domain**: hx.dev.local
**OU**: Servers/Infrastructure (Samba AD organizational unit)

### 8.3 DNS A Record

**DNS Configuration**:
- **Hostname**: hx-docling-mcp-server.hx.dev.local
- **IP Address**: hx-docling-mcp-server.hx.dev.local
- **Record Type**: A (IPv4 address)
- **Managed By**: Samba AD DNS (hx-dc1-server, hx-dc2-server)

**DNS Verification** (manual procedure):

```bash
# Forward lookup
nslookup hx-docling-mcp-server.hx.dev.local

# Expected output:
# Server:         hx-dc-server.hx.dev.local
# Address:        hx-dc-server.hx.dev.local#53
#
# Name:   hx-docling-mcp-server.hx.dev.local
# Address: hx-docling-mcp-server.hx.dev.local

# Reverse lookup
nslookup hx-docling-mcp-server.hx.dev.local

# Expected output:
# Server:         hx-dc-server.hx.dev.local
# Address:        hx-dc-server.hx.dev.local#53
#
# 217.10.168.192.in-addr.arpa     name = hx-docling-mcp-server.hx.dev.local.
```

### 8.4 SSSD Integration (Samba AD Authentication)

**SSSD Configuration** (for Samba AD service account usage in systemd):

**File Location**: `/etc/sssd/sssd.conf`

```ini
[sssd]
domains = hx.dev.local
config_file_version = 2
services = nss, pam

[domain/hx.dev.local]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = HX.DEV.LOCAL
realmd_tags = manages-system joined-with-samba
id_provider = ad
fallback_homedir = /home/%u@%d
ad_domain = hx.dev.local
use_fully_qualified_names = True
ldap_id_mapping = True
access_provider = ad
```

**SSSD Service** (manual procedure):

```bash
# Install SSSD packages
sudo apt-get install -y sssd sssd-tools realmd adcli

# Join domain (if not already joined)
sudo realm join --user=Administrator hx.dev.local

# Enable and start SSSD
sudo systemctl enable sssd
sudo systemctl start sssd

# Verify service account resolution
id docling-mcp@hx.dev.local

# Expected output:
# uid=123456(docling-mcp@hx.dev.local) gid=10513(domain users@hx.dev.local) groups=10513(domain users@hx.dev.local)
```

**Alternative (Local Account Fallback)**:

If SSSD not configured or domain account resolution fails:

```bash
# Create local service account
sudo useradd -r -s /bin/bash -d /opt/docling-mcp -m docling-mcp-local

# Update systemd unit file to use local account
# User=docling-mcp-local
# Group=docling-mcp-local
```

### 8.5 SSL/TLS Certificates (Optional - Phase 2)

**Certificate Configuration** (optional for HTTPS on port 8443):

**Certificate Source**: hx-ca-server (internal CA) - coordinate with Frank Lucas

**Certificate Files**:
- **Server Certificate**: `/etc/docling-mcp/certs/server.crt`
- **Private Key**: `/etc/docling-mcp/certs/server.key`
- **CA Certificate**: `/etc/docling-mcp/certs/ca.crt`

**Certificate Request** (manual procedure - coordinate with Frank Lucas):

```bash
# Generate private key
sudo openssl genrsa -out /etc/docling-mcp/certs/server.key 2048

# Generate CSR (Certificate Signing Request)
sudo openssl req -new -key /etc/docling-mcp/certs/server.key \
  -out /etc/docling-mcp/certs/server.csr \
  -subj "/CN=hx-docling-mcp-server.hx.dev.local/O=HX Infrastructure/C=US"

# Submit CSR to Frank Lucas for signing by hx-ca-server
# Receive signed server.crt and ca.crt

# Install certificates
sudo chmod 600 /etc/docling-mcp/certs/server.key
sudo chmod 644 /etc/docling-mcp/certs/server.crt
sudo chmod 644 /etc/docling-mcp/certs/ca.crt
```

---

## 9. Network Configuration

### 9.1 Listen Address and Ports

**HTTP MCP Endpoint** (primary):
- **Protocol**: HTTP
- **IP**: hx-docling-mcp-server.hx.dev.local
- **Port**: 8000
- **Bind**: Internal interface only (NOT 0.0.0.0)

**HTTPS MCP Endpoint** (optional):
- **Protocol**: HTTPS (TLS)
- **IP**: hx-docling-mcp-server.hx.dev.local
- **Port**: 8443
- **Bind**: Internal interface only

**stdio Transport**:
- **Protocol**: Process I/O (stdin/stdout)
- **No network binding** (in-process communication)

### 9.2 Firewall Rules

**Firewall Status**: DISABLED (per HX-Infrastructure standard)

**Required Rules (if firewall enabled)** (documentation only):

```bash
# Inbound (REFERENCE ONLY - NOT CONFIGURED)
# Allow MCP HTTP from internal network
sudo ufw allow from 192.168.10.0/24 to hx-docling-mcp-server.hx.dev.local port 8000 proto tcp comment "Docling MCP HTTP"

# Allow MCP HTTPS from internal network (if TLS enabled)
sudo ufw allow from 192.168.10.0/24 to hx-docling-mcp-server.hx.dev.local port 8443 proto tcp comment "Docling MCP HTTPS"

# Allow SSH from admin workstation
sudo ufw allow from hx-control-node.hx.dev.local to hx-docling-mcp-server.hx.dev.local port 22 proto tcp comment "SSH management"

# Outbound (REFERENCE ONLY - NOT CONFIGURED)
# Allow connections to LiteLLM
sudo ufw allow out to hx-litellm-server.hx.dev.local port 4000 proto tcp comment "LiteLLM Gateway"

# Allow connections to Qdrant
sudo ufw allow out to hx-qdrant-server.hx.dev.local port 6333 proto tcp comment "Qdrant HTTP"
sudo ufw allow out to hx-qdrant-server.hx.dev.local port 6334 proto tcp comment "Qdrant gRPC"

# Allow connections to Redis
sudo ufw allow out to hx-redis-server.hx.dev.local port 6379 proto tcp comment "Redis"
```

### 9.3 Network Interface Configuration

**Interface Binding**:
```python
# Application configuration (binding to specific interface)
# docling_mcp/server.py

mcp = FastMCP("docling-mcp-server")

# Bind to internal interface only (NOT 0.0.0.0)
mcp.add_transport(
    "http",
    host="hx-docling-mcp-server.hx.dev.local",  # Specific IP, not 0.0.0.0
    port=8000
)

# Optional HTTPS transport
if os.getenv("TLS_ENABLED") == "true":
    mcp.add_transport(
        "https",
        host="hx-docling-mcp-server.hx.dev.local",
        port=8443,
        ssl_certfile="/etc/docling-mcp/certs/server.crt",
        ssl_keyfile="/etc/docling-mcp/certs/server.key"
    )
```

### 9.4 DNS Resolution Requirements

**Forward Resolution**:
- **hx-docling-mcp-server.hx.dev.local** → hx-docling-mcp-server.hx.dev.local

**Dependency Resolution** (must resolve correctly):
- **hx-litellm-server.hx.dev.local** → hx-litellm-server.hx.dev.local
- **hx-qdrant-server.hx.dev.local** → hx-qdrant-server.hx.dev.local
- **hx-redis-server.hx.dev.local** → hx-redis-server.hx.dev.local

**DNS Verification** (manual procedure):

```bash
# Verify own hostname
nslookup hx-docling-mcp-server.hx.dev.local
# Expected: hx-docling-mcp-server.hx.dev.local

# Verify LiteLLM resolution
nslookup hx-litellm-server.hx.dev.local
# Expected: hx-litellm-server.hx.dev.local

# Verify Qdrant resolution
nslookup hx-qdrant-server.hx.dev.local
# Expected: hx-qdrant-server.hx.dev.local

# Verify Redis resolution
nslookup hx-redis-server.hx.dev.local
# Expected: hx-redis-server.hx.dev.local
```

---

## 10. Storage Configuration

### 10.1 Disk Space Requirements

**Total Disk Space**: 10GB minimum

**Directory Allocations**:

| Directory | Size | Purpose | Growth Rate |
|-----------|------|---------|-------------|
| `/opt/docling-mcp/` | 500MB | Application + venv | Static (no growth) |
| `/var/lib/docling-mcp/cache/` | 3GB | Docling cache | Moderate (cache rotation) |
| `/var/lib/docling-mcp/workspace/` | 2GB | Document processing | High (clear periodically) |
| `/var/log/docling-mcp/` | 1GB | Logs | Moderate (rotation daily) |
| `/etc/docling-mcp/` | 10MB | Configuration | Static |

### 10.2 Mount Points

**Standard Filesystem** (no special mounts required):
- All directories on root filesystem (`/`)
- No separate partitions needed
- No NFS or network storage

**Disk Space Monitoring** (manual procedure):

```bash
# Check overall disk space
df -h /

# Check directory usage
du -sh /opt/docling-mcp
du -sh /var/lib/docling-mcp
du -sh /var/log/docling-mcp

# Monitor cache directory growth
watch -n 60 'du -sh /var/lib/docling-mcp/cache'
```

### 10.3 Backup Configuration

**Backup Strategy**: Manual daily backup procedure (NO automated backup per HX-Infrastructure standards)

**Backup Scope**:
1. **Configuration Files** (MUST backup):
   - `/etc/docling-mcp/.env` (contains secrets)
   - `/etc/docling-mcp/logging.conf`
   - `/etc/systemd/system/docling-mcp.service`

2. **Application Code** (optional backup):
   - `/opt/docling-mcp/application/` (can rebuild from source)

3. **Data Directories** (NO backup):
   - `/var/lib/docling-mcp/cache/` (ephemeral cache data)
   - `/var/lib/docling-mcp/workspace/` (temporary processing data)
   - `/var/lib/docling-mcp/lightrag/` (derived knowledge graphs, stored in Qdrant)

**Manual Backup Procedure**:

```bash
# Daily manual backup (execute before configuration changes)
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/docling-mcp/backups/config/${BACKUP_DATE}

# Create backup directory
sudo mkdir -p ${BACKUP_DIR}

# Backup configuration files
sudo cp /etc/docling-mcp/.env ${BACKUP_DIR}/
sudo cp /etc/docling-mcp/logging.conf ${BACKUP_DIR}/
sudo cp /etc/systemd/system/docling-mcp.service ${BACKUP_DIR}/

# Backup application code (optional)
sudo tar czf ${BACKUP_DIR}/application.tar.gz -C /opt/docling-mcp/application .

# Verify backup
ls -lh ${BACKUP_DIR}

# Cleanup old backups (keep 10 most recent)
cd /opt/docling-mcp/backups/config
ls -t | tail -n +11 | xargs -r sudo rm -rf
```

**Restoration Procedure**:

```bash
# Restore from backup (manual procedure)
RESTORE_DATE=20251127
BACKUP_DIR=/opt/docling-mcp/backups/config/${RESTORE_DATE}

# Stop service
sudo systemctl stop docling-mcp.service

# Restore configuration files
sudo cp ${BACKUP_DIR}/.env /etc/docling-mcp/.env
sudo cp ${BACKUP_DIR}/logging.conf /etc/docling-mcp/logging.conf
sudo cp ${BACKUP_DIR}/docling-mcp.service /etc/systemd/system/docling-mcp.service

# Restore application code (if backed up)
sudo tar xzf ${BACKUP_DIR}/application.tar.gz -C /opt/docling-mcp/application

# Reload systemd and restart service
sudo systemctl daemon-reload
sudo systemctl start docling-mcp.service

# Verify service status
sudo systemctl status docling-mcp.service
```

### 10.4 Data Retention Policies

**Cache Data Retention**:
- **Docling Cache** (`/var/lib/docling-mcp/cache/`): 7 days
- **Working Directory** (`/var/lib/docling-mcp/workspace/`): 1 day
- **Redis Cache**: 1 hour TTL (automatic expiration)

**Log Retention**:
- **Active Logs**: Current log files (docling-mcp.log, error.log, access.log)
- **Rotated Logs**: 30 days (30 rotated files × 100MB each)
- **Total Log Storage**: ~3GB maximum

**Manual Cache Cleanup Procedure**:

```bash
# Daily cache cleanup (manual procedure)
# Clear workspace directory (temporary processing files)
sudo find /var/lib/docling-mcp/workspace -type f -mtime +1 -delete

# Clear old cache files (>7 days)
sudo find /var/lib/docling-mcp/cache -type f -mtime +7 -delete

# Verify cleanup
du -sh /var/lib/docling-mcp/workspace
du -sh /var/lib/docling-mcp/cache
```

---

## 11. Integration Configuration

### 11.1 LiteLLM Gateway Integration

**Service**: hx-litellm-server
**Node**: hx-litellm-server.hx.dev.local
**Port**: 4000
**Protocol**: HTTP (OpenAI-compatible API)

**Connection Configuration**:

```bash
# Environment variables (.env)
LITELLM_BASE_URL=http://hx-litellm-server.hx.dev.local:4000
LITELLM_API_KEY=<from_ansible_vault>
LITELLM_TIMEOUT=120
LITELLM_MAX_RETRIES=3
LITELLM_RETRY_DELAY=2
```

**Model Routing Configuration**:

```bash
# LLM models (via LiteLLM Gateway routing)

# Entity Extraction (primary)
LITELLM_ENTITY_EXTRACTION_MODEL=ollama/gemma3:27b
# Route: LiteLLM → hx-ollama1-server:11434 → gemma3:27b

# Entity Extraction (fallback)
LITELLM_FALLBACK_MODEL=ollama/gpt-oss:20b
# Route: LiteLLM → hx-ollama1-server:11434 → gpt-oss:20b

# Docling Processing (NOT used for entity extraction - too small)
LITELLM_DOCLING_MODEL=ollama/granite-docling:258m
# Route: LiteLLM → hx-ollama3-server:11434 → granite-docling:258m

# Embedding Model
LITELLM_EMBEDDING_MODEL=ollama/bge-m3:567m
# Route: LiteLLM → hx-ollama3-server:11434 → bge-m3:567m
```

**Health Check Configuration**:

```bash
# LiteLLM health endpoint
LITELLM_HEALTH_URL=http://hx-litellm-server.hx.dev.local:4000/health

# Pre-start validation (systemd ExecStartPre)
ExecStartPre=/usr/bin/curl -f -s -m 5 http://hx-litellm-server.hx.dev.local:4000/health
```

**Retry Logic** (application-level):

```python
# LiteLLM client retry configuration
# docling_mcp/clients/litellm_client.py

from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

class LiteLLMClient:
    """LiteLLM client with retry logic."""

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError))
    )
    async def call_llm(self, model: str, prompt: str) -> str:
        """
        Call LLM via LiteLLM Gateway with retry logic.

        Retry Strategy:
        - Max attempts: 3
        - Backoff: 1s, 2s, 4s (exponential)
        - Retry on: ConnectionError, TimeoutError
        - Fail fast on: 4xx client errors
        """
        pass
```

### 11.2 Qdrant Vector Database Integration

**Service**: hx-qdrant-server
**Node**: hx-qdrant-server.hx.dev.local
**Port**: 6333 (HTTP), 6334 (gRPC)
**Protocol**: HTTP/gRPC

**Connection Configuration**:

```bash
# Environment variables (.env)
QDRANT_HOST=hx-qdrant-server.hx.dev.local
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334
QDRANT_COLLECTION_PREFIX=docling_mcp_
QDRANT_TIMEOUT=60
QDRANT_MAX_RETRIES=3
QDRANT_RETRY_DELAY=2
```

**Collection Configuration**:

```bash
# Qdrant collection settings
QDRANT_EMBEDDING_DIM=1024       # bge-m3 embedding dimension
QDRANT_DISTANCE_METRIC=Cosine   # Cosine similarity
QDRANT_SHARD_NUMBER=2           # Sharding for scalability
QDRANT_REPLICATION_FACTOR=1     # Single-node (no replication)
```

**Collection Names**:
- `docling_mcp_entities`: Entity vectors (fine-grained retrieval)
- `docling_mcp_relations`: Relationship vectors
- `docling_mcp_themes`: High-level theme vectors (coarse-grained retrieval)

**Health Check** (manual procedure):

```bash
# Verify Qdrant accessible
curl -f http://hx-qdrant-server.hx.dev.local:6333/health

# List collections
curl http://hx-qdrant-server.hx.dev.local:6333/collections

# Check collection info
curl http://hx-qdrant-server.hx.dev.local:6333/collections/docling_mcp_entities
```

### 11.3 Redis Integration

**Service**: hx-redis-server
**Node**: hx-redis-server.hx.dev.local
**Port**: 6379
**Protocol**: TCP (Redis protocol)

**Connection Configuration**:

```bash
# Environment variables (.env)
REDIS_HOST=hx-redis-server.hx.dev.local
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=<from_ansible_vault>  # If authentication enabled
REDIS_SESSION_TTL=3600
REDIS_DOCUMENT_TTL=3600
REDIS_POOL_SIZE=10
REDIS_MAX_RETRIES=3
REDIS_RETRY_DELAY=1
```

**Redis Data Structures**:

```bash
# Session data (key pattern: session:{session_id})
SET session:abc123 '{"user_id": "client1", "active_documents": ["doc1", "doc2"]}'
EXPIRE session:abc123 3600

# Document cache (key pattern: doc:{document_id})
SET doc:12345 '{"id": "12345", "format": "pdf", "content": {...}}'
EXPIRE doc:12345 3600

# Rate limiting (key pattern: ratelimit:{client_id}:{tool_name})
INCR ratelimit:client1:convert_pdf
EXPIRE ratelimit:client1:convert_pdf 60
```

**Health Check** (manual procedure):

```bash
# Verify Redis accessible
redis-cli -h hx-redis-server.hx.dev.local -p 6379 ping
# Expected: PONG

# Check Redis info
redis-cli -h hx-redis-server.hx.dev.local -p 6379 info

# Test key operations
redis-cli -h hx-redis-server.hx.dev.local -p 6379 SET test:key "test value"
redis-cli -h hx-redis-server.hx.dev.local -p 6379 GET test:key
redis-cli -h hx-redis-server.hx.dev.local -p 6379 DEL test:key
```

### 11.4 MCP Client Integration

**MCP Protocol Endpoints**:

**HTTP Transport**:
```bash
# MCP HTTP endpoint
URL: http://hx-docling-mcp-server.hx.dev.local:8000/mcp
Method: POST
Content-Type: application/json

# Example request
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 1
  }'
```

**SSE Transport** (Server-Sent Events):
```bash
# MCP SSE endpoint (streaming)
URL: http://hx-docling-mcp-server.hx.dev.local:8000/mcp/sse
```

**stdio Transport** (process communication):
```bash
# Launch MCP server in stdio mode
/opt/docling-mcp/venv/bin/python -m docling_mcp.server --transport stdio
```

---

## 12. Monitoring and Health Checks

### 12.1 Health Check Endpoint

**Health Endpoint**: `http://hx-docling-mcp-server.hx.dev.local:8000/health`

**Health Check Response**:

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "dependencies": {
    "litellm": {
      "status": "healthy",
      "latency_ms": 5
    },
    "qdrant": {
      "status": "healthy",
      "latency_ms": 3
    },
    "redis": {
      "status": "healthy",
      "latency_ms": 1
    }
  },
  "resources": {
    "cpu_percent": 25.5,
    "memory_percent": 45.2,
    "disk_percent": 30.1
  }
}
```

**Health Check Commands** (manual procedure):

```bash
# Check service health
curl -f http://hx-docling-mcp-server.hx.dev.local:8000/health

# Verbose health check
curl -v http://hx-docling-mcp-server.hx.dev.local:8000/health | jq

# Monitor health continuously
watch -n 5 'curl -s http://hx-docling-mcp-server.hx.dev.local:8000/health | jq .status'
```

### 12.2 Prometheus Metrics (Phase 2)

**Metrics Endpoint**: `http://hx-docling-mcp-server.hx.dev.local:8000/metrics` (optional, Phase 2)

**Example Metrics**:
```
# HELP mcp_requests_total Total MCP requests
# TYPE mcp_requests_total counter
mcp_requests_total{tool="convert_pdf",status="success"} 1234

# HELP mcp_request_duration_seconds MCP request duration
# TYPE mcp_request_duration_seconds histogram
mcp_request_duration_seconds_bucket{tool="convert_pdf",le="1.0"} 500
mcp_request_duration_seconds_bucket{tool="convert_pdf",le="5.0"} 950
mcp_request_duration_seconds_sum{tool="convert_pdf"} 2500
mcp_request_duration_seconds_count{tool="convert_pdf"} 1000
```

### 12.3 Resource Monitoring

**System Resource Checks** (manual procedure):

```bash
# CPU usage
top -bn1 | grep "docling-mcp" | awk '{print $9}'

# Memory usage
ps aux | grep "docling-mcp" | awk '{print $4}'

# Disk space
df -h /var/lib/docling-mcp

# Network connections
sudo netstat -tulpn | grep 8000

# Systemd resource usage
sudo systemctl status docling-mcp.service
```

### 12.4 Log Monitoring

**Log Monitoring Commands** (manual procedure):

```bash
# Tail main log
sudo tail -f /var/log/docling-mcp/docling-mcp.log

# Tail error log
sudo tail -f /var/log/docling-mcp/error.log

# Follow systemd journal
sudo journalctl -u docling-mcp.service -f

# Search for errors
sudo grep -i error /var/log/docling-mcp/error.log

# Count error occurrences
sudo grep -c "ERROR" /var/log/docling-mcp/docling-mcp.log

# Monitor log file growth
watch -n 60 'ls -lh /var/log/docling-mcp/*.log'
```

---

## Summary

This configuration specification provides complete system configuration for bare-metal deployment of the Docling MCP Server on Ubuntu 24.04 LTS. All configurations follow HX-Infrastructure standards:

**✅ Bare-Metal Deployment**: No Docker, systemd service management
**✅ Manual Procedures**: All deployment steps documented for human execution
**✅ Samba AD Integration**: Service account `docling-mcp@hx.dev.local`
**✅ Ansible Vault Secrets**: All credentials encrypted in Ansible Vault
**✅ Network Isolation**: Internal network only (192.168.10.0/24), firewall DISABLED
**✅ Systemd Best Practices**: NO `Requires=`, inline `ExecStartPre` only
**✅ Security Hardening**: Comprehensive systemd security directives
**✅ Resource Limits**: CPU, memory, disk quotas enforced via systemd

**Next Steps**:
1. Julia Santos creates `test-plan.md` with comprehensive test strategy
2. Deployment team executes manual deployment procedures
3. Operations team validates configuration and health checks

---

**Document Version**: 1.0
**Created By**: william-chen (Infrastructure & Operations Specialist)
**Date**: 2025-11-27
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
**Based On**: HX-Infrastructure deployment standards, bare-metal deployment philosophy
