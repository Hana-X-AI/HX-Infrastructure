# Task 007: Install Application Code

**Task ID**: hx-docling-mcp-task-007
**Category**: Installation / Application Deployment
**Assigned To**: james-dean (Docling MCP SME)
**Status**: COMPLETE
**Priority**: HIGH (Blocker for deployment)
**Created**: 2025-11-27
**Completed**: 2025-11-28
**Estimated Effort**: 30 minutes
**Actual Effort**: 30 minutes

---

## Task Description

Install Docling MCP Server application code into the `/opt/docling-mcp/application` directory. This includes downloading the application source code, setting up the application structure, and preparing the application for configuration and systemd service integration.

**Note**: This task assumes application code will be provided either via git repository clone or as a packaged distribution. The procedures cover both deployment methods.

---

## Prerequisites

- [ ] Task 002 complete (Samba AD service account created)
- [ ] Task 003 complete (System dependencies installed including git)
- [ ] Task 004 complete (Python 3.12 virtual environment created)
- [ ] Task 005 complete (Python dependencies installed in venv)
- [ ] Task 006 complete (Directory structure created: `/opt/docling-mcp/application`)
- [ ] Application source code available (git repository URL or packaged tarball)

---

## Acceptance Criteria

- [ ] Application code deployed to `/opt/docling-mcp/application`
- [ ] Application directory structure matches expected layout
- [ ] All application modules present and verified
- [ ] File ownership set to service account (`docling-mcp@hx.dev.local`)
- [ ] File permissions correct (755 for directories, 644 for files, 755 for scripts)
- [ ] Application entry point script functional
- [ ] Application version documented

---

## Detailed Procedure

### Deployment Method 1: Git Repository Clone (Recommended)

**Use this method if application code is in a git repository**:

```bash
# Connect to hx-docling-mcp-server
ssh administrator@192.168.10.217

# Navigate to deployment directory
cd /opt/docling-mcp

# Clone application repository (replace URL with actual repository)
# Example: git clone https://github.com/Hana-X-AI/docling-mcp-server.git application
sudo -u docling-mcp@hx.dev.local git clone <REPOSITORY_URL> application

# Verify clone successful
ls -la /opt/docling-mcp/application
# Expected: application files and directories

# Navigate to application directory
cd /opt/docling-mcp/application

# Checkout specific version/tag (if applicable)
sudo -u docling-mcp@hx.dev.local git checkout <VERSION_TAG>

# Verify git status
git status
# Expected: On branch main/master or specific tag

# Document current commit
git log -1 --oneline > /opt/docling-mcp/documentation/application-version.txt
```

### Deployment Method 2: Packaged Tarball/Zip

**Use this method if application code is distributed as a package**:

```bash
# Connect to hx-docling-mcp-server
ssh administrator@192.168.10.217

# Navigate to deployment directory
cd /opt/docling-mcp

# Download application package (example - replace with actual URL)
sudo -u docling-mcp@hx.dev.local wget <PACKAGE_URL> -O docling-mcp-server.tar.gz

# Verify download
file docling-mcp-server.tar.gz
# Expected: gzip compressed data

# Extract package to application directory
sudo -u docling-mcp@hx.dev.local tar -xzf docling-mcp-server.tar.gz -C /opt/docling-mcp
sudo -u docling-mcp@hx.dev.local mv /opt/docling-mcp/docling-mcp-server /opt/docling-mcp/application

# Clean up package file
rm docling-mcp-server.tar.gz

# Verify extraction
ls -la /opt/docling-mcp/application
# Expected: application files and directories
```

### Step 1: Verify Application Directory Structure

**Expected application structure**:

```bash
# Verify application structure
tree -L 2 /opt/docling-mcp/application 2>/dev/null || find /opt/docling-mcp/application -maxdepth 2

# Expected structure:
# /opt/docling-mcp/application/
# ├── docling_mcp/                  # Main application package
# │   ├── __init__.py
# │   ├── server.py                 # MCP server entry point
# │   ├── config.py                 # Configuration management
# │   ├── tools/                    # MCP tool implementations
# │   │   ├── conversion.py
# │   │   ├── generation.py
# │   │   └── manipulation.py
# │   ├── processing/               # Document processing modules
# │   │   ├── docling_processor.py
# │   │   └── lightrag_processor.py
# │   ├── integrations/             # External service integrations
# │   │   ├── litellm_client.py
# │   │   ├── qdrant_client.py
# │   │   └── redis_client.py
# │   └── utils/                    # Utility modules
# │       ├── logging.py
# │       └── validation.py
# ├── tests/                        # Test suite
# ├── scripts/                      # Utility scripts
# ├── README.md
# ├── pyproject.toml                # Package metadata (if using)
# └── setup.py                      # Installation script (if using)
```

### Step 2: Verify Core Application Files

```bash
# Check main package directory
test -d /opt/docling-mcp/application/docling_mcp && echo "PASS: Main package exists" || echo "FAIL: Main package missing"

# Check entry point
test -f /opt/docling-mcp/application/docling_mcp/server.py && echo "PASS: Server entry point exists" || echo "FAIL: Server entry point missing"

# Check configuration module
test -f /opt/docling-mcp/application/docling_mcp/config.py && echo "PASS: Config module exists" || echo "FAIL: Config module missing"

# Check tools directory
test -d /opt/docling-mcp/application/docling_mcp/tools && echo "PASS: Tools directory exists" || echo "FAIL: Tools directory missing"

# Check processing directory
test -d /opt/docling-mcp/application/docling_mcp/processing && echo "PASS: Processing directory exists" || echo "FAIL: Processing directory missing"

# Check integrations directory
test -d /opt/docling-mcp/application/docling_mcp/integrations && echo "PASS: Integrations directory exists" || echo "FAIL: Integrations directory missing"
```

### Step 3: Install Application as Python Package (Optional)

**If application has setup.py or pyproject.toml for package installation**:

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Navigate to application directory
cd /opt/docling-mcp/application

# Install application in editable mode
pip install -e .

# Verify installation
pip list | grep docling-mcp
# Expected: docling-mcp  <version>  /opt/docling-mcp/application

# Test import
python -c "import docling_mcp; print(f'Application module imported: {docling_mcp.__file__}')"
# Expected: Application module imported: /opt/docling-mcp/application/docling_mcp/__init__.py

# Deactivate venv
deactivate
```

### Step 4: Set File Ownership and Permissions

```bash
# Set ownership to service account
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application

# Verify ownership
ls -la /opt/docling-mcp/application
# Expected: docling-mcp@hx.dev.local domain users@hx.dev.local

# Set directory permissions (755)
sudo find /opt/docling-mcp/application -type d -exec chmod 755 {} \;

# Set file permissions (644 for regular files)
sudo find /opt/docling-mcp/application -type f -exec chmod 644 {} \;

# Set executable permissions for scripts
sudo find /opt/docling-mcp/application/scripts -type f -exec chmod 755 {} \; 2>/dev/null || true

# Verify permissions
ls -la /opt/docling-mcp/application/docling_mcp/server.py
# Expected: -rw-r--r-- ... server.py

ls -la /opt/docling-mcp/application/scripts/ 2>/dev/null || echo "No scripts directory"
# Expected: -rwxr-xr-x for script files
```

### Step 5: Create Application Entry Point Script

**Create convenience script for running application**:

```bash
# Create run script
sudo tee /opt/docling-mcp/bin/run-server.sh > /dev/null <<'EOF'
#!/bin/bash
# Docling MCP Server Entry Point
# This script runs the MCP server via systemd service

set -e

VENV_PATH="/opt/docling-mcp/venv"
APP_MODULE="docling_mcp.server"
ENV_FILE="/etc/docling-mcp/.env"

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Run MCP server
python -m "$APP_MODULE" "$@"
EOF

# Make script executable
sudo chmod 755 /opt/docling-mcp/bin/run-server.sh

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/bin/run-server.sh

# Verify script
cat /opt/docling-mcp/bin/run-server.sh
```

### Step 6: Verify Application Can Be Imported

```bash
# Test application import (within venv)
source /opt/docling-mcp/venv/bin/activate

# Test main module import
python -c "
import sys
sys.path.insert(0, '/opt/docling-mcp/application')
import docling_mcp
print(f'✓ Application module imported successfully')
print(f'  Location: {docling_mcp.__file__}')
"

# Test server module import
python -c "
import sys
sys.path.insert(0, '/opt/docling-mcp/application')
from docling_mcp import server
print(f'✓ Server module imported successfully')
"

# Test configuration module import
python -c "
import sys
sys.path.insert(0, '/opt/docling-mcp/application')
from docling_mcp import config
print(f'✓ Config module imported successfully')
"

# Deactivate venv
deactivate
```

### Step 7: Document Application Installation

```bash
# Create application installation documentation
sudo tee /opt/docling-mcp/documentation/application-installation.txt > /dev/null <<EOF
Application Installation Documentation
======================================

Installation Date: $(date)
Node: hx-docling-mcp-server (192.168.10.217)
Installed By: $(whoami)

Application Details:
-------------------
Location: /opt/docling-mcp/application
Deployment Method: [Git Clone / Tarball] # Update based on method used

Version Information:
-------------------
$(cat /opt/docling-mcp/documentation/application-version.txt 2>/dev/null || echo "Version: Not available")

Directory Structure:
-------------------
$(tree -L 2 /opt/docling-mcp/application 2>/dev/null || find /opt/docling-mcp/application -maxdepth 2 -type d)

File Count:
----------
Total Files: $(find /opt/docling-mcp/application -type f | wc -l)
Python Files: $(find /opt/docling-mcp/application -type f -name "*.py" | wc -l)

Ownership:
---------
$(ls -la /opt/docling-mcp/application | head -5)

Disk Usage:
----------
$(du -sh /opt/docling-mcp/application)

Entry Point:
-----------
Script: /opt/docling-mcp/bin/run-server.sh
Module: docling_mcp.server
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/documentation/application-installation.txt

# Display documentation
cat /opt/docling-mcp/documentation/application-installation.txt
```

---

## Validation

### Validation Commands

```bash
# 1. Verify application directory exists
test -d /opt/docling-mcp/application && echo "PASS: Application directory exists" || echo "FAIL: Application directory missing"

# 2. Verify main package exists
test -d /opt/docling-mcp/application/docling_mcp && echo "PASS: Main package exists" || echo "FAIL: Main package missing"

# 3. Verify server entry point exists
test -f /opt/docling-mcp/application/docling_mcp/server.py && echo "PASS: Server entry point exists" || echo "FAIL: Server entry point missing"

# 4. Verify ownership correct
OWNER=$(stat -c '%U' /opt/docling-mcp/application)
[ "$OWNER" = "docling-mcp@hx.dev.local" ] && echo "PASS: ownership correct" || echo "FAIL: ownership incorrect ($OWNER)"

# 5. Verify permissions
PERM=$(stat -c '%a' /opt/docling-mcp/application)
[ "$PERM" = "755" ] && echo "PASS: directory permissions correct" || echo "FAIL: directory permissions incorrect ($PERM)"

# 6. Verify application importable
source /opt/docling-mcp/venv/bin/activate
python -c "import sys; sys.path.insert(0, '/opt/docling-mcp/application'); import docling_mcp" && echo "PASS: application importable" || echo "FAIL: import error"
deactivate

# 7. Verify run script exists and executable
test -x /opt/docling-mcp/bin/run-server.sh && echo "PASS: run script executable" || echo "FAIL: run script missing or not executable"

# 8. Verify documentation created
test -f /opt/docling-mcp/documentation/application-installation.txt && echo "PASS: documentation created" || echo "FAIL: documentation missing"
```

### Success Criteria

- ✅ Application code deployed to `/opt/docling-mcp/application`
- ✅ Main package directory `docling_mcp` exists
- ✅ Server entry point `server.py` exists
- ✅ Tools, processing, integrations directories exist
- ✅ Ownership set to service account
- ✅ Permissions correct (755 for directories, 644 for files)
- ✅ Application importable in Python
- ✅ Run script created and executable
- ✅ Documentation generated

---

## Troubleshooting

### Issue: Git Clone Fails

**Symptom**: `fatal: repository '<URL>' not found`

**Solution**:
```bash
# Verify repository URL
curl -I <REPOSITORY_URL>

# If private repository, configure SSH key or credentials
ssh -T git@github.com  # Test GitHub access

# Use HTTPS with credentials if needed
git clone https://username:token@github.com/org/repo.git application

# Or use SSH URL
git clone git@github.com:org/repo.git application
```

### Issue: Import Error After Installation

**Symptom**: `ModuleNotFoundError: No module named 'docling_mcp'`

**Solution**:
```bash
# Verify application directory structure
ls -la /opt/docling-mcp/application/docling_mcp

# Check __init__.py exists
test -f /opt/docling-mcp/application/docling_mcp/__init__.py || touch /opt/docling-mcp/application/docling_mcp/__init__.py

# Verify PYTHONPATH or install as package
source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp/application
pip install -e .
deactivate
```

### Issue: Permission Denied

**Symptom**: `PermissionError: [Errno 13] Permission denied`

**Solution**:
```bash
# Fix ownership
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application

# Fix permissions
sudo find /opt/docling-mcp/application -type d -exec chmod 755 {} \;
sudo find /opt/docling-mcp/application -type f -exec chmod 644 {} \;

# Make run script executable
sudo chmod 755 /opt/docling-mcp/bin/run-server.sh
```

### Issue: Incomplete Application Files

**Symptom**: Expected files/directories missing

**Solution**:
```bash
# Re-download/re-clone application
cd /opt/docling-mcp
sudo rm -rf application

# Retry deployment method (git clone or tarball extraction)

# Verify completeness after re-deployment
find /opt/docling-mcp/application -type d | sort
```

---

## Rollback Procedure

**If application installation fails or needs removal**:

```bash
# Remove application directory
sudo rm -rf /opt/docling-mcp/application

# Verify removal
[ ! -d /opt/docling-mcp/application ] && echo "Application removed" || echo "ERROR: application still exists"

# Remove run script
sudo rm -f /opt/docling-mcp/bin/run-server.sh

# Remove documentation
sudo rm -f /opt/docling-mcp/documentation/application-installation.txt
sudo rm -f /opt/docling-mcp/documentation/application-version.txt

# Uninstall package if installed in venv
source /opt/docling-mcp/venv/bin/activate
pip uninstall docling-mcp -y 2>/dev/null || true
deactivate

# If needed, re-deploy from Step 1
```

---

## Dependencies

**Blocks**:
- Task 008: Configure Environment Files (application must exist for configuration)
- All configuration tasks (require application code)
- All testing tasks (require application code)

**Depends On**:
- Task 002: Create Samba AD Service Account (ownership)
- Task 003: Install System Dependencies (git for cloning)
- Task 004: Create Python Virtual Environment (venv for package installation)
- Task 005: Install Python Dependencies (dependencies for application)
- Task 006: Create Directory Structure (`/opt/docling-mcp/application` directory)

---

## Notes

### Application Code Source

**This task assumes application code will be provided via**:
- **Git Repository**: Preferred method for version control and updates
- **Packaged Distribution**: Tarball/zip for releases
- **Local Copy**: Manual deployment from development environment

**Update this task's deployment commands** with the actual repository URL or package download location.

### Application Structure Requirements

**Minimal required structure**:
```
docling_mcp/
├── __init__.py              # Package initialization
├── server.py                # MCP server entry point
├── config.py                # Configuration management
├── tools/                   # MCP tool implementations
├── processing/              # Document processing modules
└── integrations/            # External service integrations
```

### Development vs Production Deployment

**Development**:
- Use `pip install -e .` for editable installation
- Allows code changes without reinstallation
- Useful for testing and development

**Production**:
- Use `pip install .` for standard installation
- Creates compiled bytecode (.pyc files)
- More stable for production environments

**This task uses editable mode** for easier updates and configuration during deployment.

### HX-Infrastructure Standards Compliance

- ✅ **Bare-Metal Deployment**: Application deployed to filesystem (no containers)
- ✅ **Service Account Ownership**: All files owned by domain service account
- ✅ **Manual Procedures**: All commands documented for human execution
- ✅ **Version Control**: Git-based deployment for traceability
- ✅ **Filesystem Layout**: Standard `/opt/` application location

---

## References

- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 007)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Application Architecture)

---

**Task Completed By**: james-dean (Docling MCP SME)
**Date Completed**: 2025-11-28 18:01 UTC
**Verified By**: All validation checks passed (8/8)
