# Task 002: Install System Dependencies

**Task ID**: hx-docling-mcp-task-002
**Category**: Pre-Deployment / System Packages
**Assigned To**: william-chen (Infrastructure Specialist)
**Status**: PENDING
**Priority**: HIGH (Blocker for deployment)
**Created**: 2025-11-27
**Estimated Effort**: 30 minutes

---

## Task Description

Install all required system packages on hx-docling-mcp-server (192.168.10.217) for Docling MCP Server deployment. This includes Python 3.11+, document processing libraries (poppler, tesseract), build tools, and system utilities required for bare-metal deployment.

---

## Prerequisites

- [ ] Node hx-docling-mcp-server (192.168.10.217) accessible via SSH
- [ ] Ubuntu 24.04 LTS installed on node
- [ ] Internet connectivity available for package downloads (or internal mirror configured)
- [ ] sudo access available for package installation
- [ ] Task 001 complete (service account created)

---

## Acceptance Criteria

- [ ] All system packages installed successfully
- [ ] Python 3.11+ installed and verified
- [ ] Document processing dependencies installed (poppler-utils, tesseract-ocr, libmagic1)
- [ ] Build tools installed (build-essential, gcc, g++, make)
- [ ] Package versions meet minimum requirements
- [ ] No package installation errors or conflicts
- [ ] System reboot NOT required (all packages runtime-installable)

---

## Detailed Procedure

### Step 1: Connect to Node

```bash
# Connect to hx-docling-mcp-server
ssh administrator@192.168.10.217

# Verify Ubuntu version
lsb_release -a
# Expected: Ubuntu 24.04.x LTS

# Check current disk space
df -h /
# Ensure >10GB available
```

### Step 2: System Update (Always First)

```bash
# Update package lists
sudo apt-get update

# Upgrade existing packages
sudo apt-get upgrade -y

# Verify no errors
echo $?
# Expected: 0 (success)
```

### Step 3: Install Build Tools

**Install compilation tools required for Python package compilation**:

```bash
# Install build-essential (gcc, g++, make)
sudo apt-get install -y build-essential

# Install pkg-config
sudo apt-get install -y pkg-config

# Verify gcc version (minimum: 11.0 for C++17 support)
gcc_version=$(gcc -dumpversion | cut -d. -f1)
if [ "$gcc_version" -lt 11 ]; then
    echo "ERROR: gcc version $gcc_version is below minimum required (11.0)"
    echo "Ubuntu 24.04 should provide gcc 13.x by default"
    exit 1
fi
echo "✓ gcc version $(gcc --version | head -n1) meets requirements"

# Verify make version (minimum: 4.3)
make_version=$(make --version | head -n1 | grep -oP '\d+\.\d+' | head -n1)
if [ "$(echo "$make_version < 4.3" | bc)" -eq 1 ]; then
    echo "ERROR: make version $make_version is below minimum required (4.3)"
    exit 1
fi
echo "✓ make version $make_version meets requirements"
```

**Alternative Source (if needed)**:
- Ubuntu 24.04 LTS provides gcc 13.x by default
- If older Ubuntu version, use: `sudo apt-get install -y gcc-11 g++-11`

### Step 4: Install Python 3.11+ Runtime

```bash
# Check if Python 3.11+ is available in default repos
apt-cache policy python3.11 | grep -q "Candidate" || {
    echo "Python 3.11 not found in default repos, adding deadsnakes PPA..."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
}

# Install Python 3.11
sudo apt-get install -y python3.11

# Install Python virtual environment support
sudo apt-get install -y python3.11-venv

# Install Python development headers
sudo apt-get install -y python3.11-dev

# Install pip
sudo apt-get install -y python3-pip

# IMMEDIATE VERSION VERIFICATION (minimum: 3.11.0)
python_version=$(python3.11 --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -n1)
python_major=$(echo "$python_version" | cut -d. -f1)
python_minor=$(echo "$python_version" | cut -d. -f2)

if [ "$python_major" -lt 3 ] || { [ "$python_major" -eq 3 ] && [ "$python_minor" -lt 11 ]; }; then
    echo "ERROR: Python version $python_version is below minimum required (3.11.0)"
    echo "Required by: docling~=2.25, FastMCP"
    exit 1
fi
echo "✓ Python version $python_version meets requirements (>= 3.11.0)"

# Verify pip version (minimum: 20.0 for modern features)
pip_version=$(python3.11 -m pip --version 2>&1 | grep -oP '\d+\.\d+' | head -n1)
if [ "$(echo "$pip_version < 20.0" | bc)" -eq 1 ]; then
    echo "ERROR: pip version $pip_version is below minimum required (20.0)"
    echo "Upgrading pip..."
    python3.11 -m pip install --upgrade pip
fi
echo "✓ pip version $(python3.11 -m pip --version | grep -oP '\d+\.\d+\.\d+' | head -n1)"

# Verify venv module availability
if ! python3.11 -m venv --help > /dev/null 2>&1; then
    echo "ERROR: python3.11-venv module not available"
    echo "Ensure python3.11-venv package is installed"
    exit 1
fi
echo "✓ venv module available"
```

**Alternative Source**:
- **Ubuntu 24.04 LTS**: Python 3.11 available in default repos
- **Ubuntu 22.04 LTS**: Use deadsnakes PPA (automated above)
  ```bash
  sudo add-apt-repository ppa:deadsnakes/ppa
  sudo apt-get update
  sudo apt-get install python3.11 python3.11-venv python3.11-dev
  ```
- **Building from source** (last resort, ~20 min):
  ```bash
  wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
  tar -xf Python-3.11.9.tgz && cd Python-3.11.9
  ./configure --enable-optimizations
  make -j$(nproc) && sudo make altinstall
  ```

### Step 5: Install Document Processing Dependencies

**Install PDF, OCR, and image processing libraries**:

```bash
# Poppler utilities (PDF rendering)
sudo apt-get install -y poppler-utils

# IMMEDIATE VERIFICATION: poppler-utils (minimum: 23.0)
poppler_version=$(pdftotext -v 2>&1 | grep -oP 'pdftotext version \K\d+\.\d+' | head -n1)
if [ -z "$poppler_version" ]; then
    poppler_version=$(pdfinfo -v 2>&1 | grep -oP 'pdfinfo version \K\d+\.\d+' | head -n1)
fi
if [ "$(echo "$poppler_version < 23.0" | bc)" -eq 1 ]; then
    echo "ERROR: poppler-utils version $poppler_version is below minimum required (23.0)"
    echo "Ubuntu 24.04 should provide poppler 23.x or higher"
    echo "Alternative: Build from source or use newer Ubuntu release"
    exit 1
fi
echo "✓ poppler-utils version $poppler_version meets requirements (>= 23.0)"

# Tesseract OCR engine
sudo apt-get install -y tesseract-ocr

# Tesseract English language data
sudo apt-get install -y tesseract-ocr-eng

# IMMEDIATE VERIFICATION: tesseract (minimum: 5.0)
tesseract_version=$(tesseract --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' | head -n1)
tesseract_major=$(echo "$tesseract_version" | cut -d. -f1)
if [ "$tesseract_major" -lt 5 ]; then
    echo "ERROR: tesseract version $tesseract_version is below minimum required (5.0)"
    echo "Ubuntu 24.04 should provide tesseract 5.x"
    echo "Alternative: Build from source or enable notesalexp PPA"
    exit 1
fi
echo "✓ tesseract version $tesseract_version meets requirements (>= 5.0)"

# libmagic (MIME type detection)
sudo apt-get install -y libmagic1 libmagic-dev

# IMMEDIATE VERIFICATION: libmagic (minimum: 5.0)
file_version=$(file --version 2>&1 | head -n1 | grep -oP 'file-\K\d+\.\d+' | head -n1)
if [ "$(echo "$file_version < 5.0" | bc)" -eq 1 ]; then
    echo "ERROR: file/libmagic version $file_version is below minimum required (5.0)"
    exit 1
fi
echo "✓ libmagic version $file_version meets requirements (>= 5.0)"
```

**Alternative Sources**:
- **poppler-utils < 23.0**:
  - Ubuntu 24.04 LTS includes poppler 24.x (sufficient)
  - If older: Build from source (https://poppler.freedesktop.org/releases/)
  ```bash
  # Building poppler from source (requires cmake)
  wget https://poppler.freedesktop.org/poppler-24.02.0.tar.xz
  tar -xf poppler-24.02.0.tar.xz && cd poppler-24.02.0
  mkdir build && cd build
  cmake .. && make -j$(nproc) && sudo make install
  ```

- **tesseract < 5.0**:
  - Ubuntu 24.04 LTS includes tesseract 5.3.x (sufficient)
  - Alternative PPA for Ubuntu 22.04:
  ```bash
  sudo add-apt-repository ppa:alex-p/tesseract-ocr5
  sudo apt-get update
  sudo apt-get install tesseract-ocr
  ```
  - Build from source: https://github.com/tesseract-ocr/tesseract/wiki/Compiling

### Step 6: Install Image Processing Dependencies

```bash
# PNG library
sudo apt-get install -y libpng-dev

# JPEG library
sudo apt-get install -y libjpeg-dev

# TIFF library
sudo apt-get install -y libtiff-dev

# Verify libraries installed
dpkg -l | grep -E "(libpng|libjpeg|libtiff)"
# Expected: All packages shown as installed (ii status)
```

### Step 7: Install System Utilities

```bash
# Install curl
sudo apt-get install -y curl

# IMMEDIATE VERIFICATION: curl (minimum: 7.0 for modern TLS)
curl_version=$(curl --version | head -n1 | grep -oP 'curl \K\d+\.\d+' | head -n1)
if [ "$(echo "$curl_version < 7.0" | bc)" -eq 1 ]; then
    echo "ERROR: curl version $curl_version is below minimum required (7.0)"
    exit 1
fi
echo "✓ curl version $curl_version meets requirements"

# Install wget
sudo apt-get install -y wget

# IMMEDIATE VERIFICATION: wget (minimum: 1.20)
wget_version=$(wget --version | head -n1 | grep -oP 'Wget \K\d+\.\d+' | head -n1)
if [ "$(echo "$wget_version < 1.20" | bc)" -eq 1 ]; then
    echo "ERROR: wget version $wget_version is below minimum required (1.20)"
    exit 1
fi
echo "✓ wget version $wget_version meets requirements"

# Install git
sudo apt-get install -y git

# IMMEDIATE VERIFICATION: git (minimum: 2.25 for modern features)
git_version=$(git --version | grep -oP '\d+\.\d+' | head -n1)
if [ "$(echo "$git_version < 2.25" | bc)" -eq 1 ]; then
    echo "WARNING: git version $git_version is below recommended (2.25)"
    echo "Git will work but consider upgrading for better performance"
fi
echo "✓ git version $git_version installed"

# Install vim (utility, no version requirement)
sudo apt-get install -y vim

# Install htop (utility, no version requirement)
sudo apt-get install -y htop

# Install net-tools (utility, no version requirement)
sudo apt-get install -y net-tools
```

**Alternative Sources**:
- **git < 2.25**: Use official Git PPA
  ```bash
  sudo add-apt-repository ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install git
  ```
- Ubuntu 24.04 LTS provides all utilities at sufficient versions

### Step 8: Verify All Packages Installed

**Create verification script**:

```bash
# Create package verification script
cat > /tmp/verify-packages.sh <<'EOF'
#!/bin/bash
# Package Verification Script for Docling MCP Server

echo "===== System Package Verification ====="
echo ""

# Function to check package
check_package() {
    local package=$1
    local command=$2
    echo -n "Checking $package... "
    if dpkg -l | grep -q "^ii  $package"; then
        echo "✓ INSTALLED"
        if [ -n "$command" ]; then
            echo "  Version: $($command 2>&1 | head -1)"
        fi
    else
        echo "✗ NOT INSTALLED"
        return 1
    fi
}

# Function to check command
check_command() {
    local name=$1
    local command=$2
    echo -n "Checking $name... "
    if command -v $command &> /dev/null; then
        echo "✓ AVAILABLE"
        echo "  Version: $($command --version 2>&1 | head -1)"
    else
        echo "✗ NOT AVAILABLE"
        return 1
    fi
}

# Check packages
check_package "build-essential" "gcc --version"
check_package "python3.11" "python3.11 --version"
check_package "python3.11-venv"
check_package "python3.11-dev"
check_package "poppler-utils" "pdftotext -v"
check_package "tesseract-ocr" "tesseract --version"
check_package "tesseract-ocr-eng"
check_package "libmagic1" "file --version"
check_package "libpng-dev"
check_package "libjpeg-dev"
check_package "libtiff-dev"
check_package "curl" "curl --version"
check_package "wget" "wget --version"
check_package "git" "git --version"
check_package "vim" "vim --version"
check_package "htop"
check_package "net-tools"

echo ""
echo "===== Command Verification ====="
echo ""

check_command "gcc" "gcc"
check_command "make" "make"
check_command "python3.11" "python3.11"
check_command "pip" "python3.11 -m pip"
check_command "pdftotext" "pdftotext"
check_command "tesseract" "tesseract"
check_command "file" "file"
check_command "curl" "curl"
check_command "wget" "wget"
check_command "git" "git"

echo ""
echo "===== Verification Complete ====="
EOF

chmod +x /tmp/verify-packages.sh
/tmp/verify-packages.sh

# Verify script exit code
echo $?
# Expected: 0 (all checks passed)
```

### Step 9: Package Version Matrix Documentation

**Document installed package versions**:

```bash
# Create package version report
cat > /tmp/package-versions.txt <<EOF
Package Version Report: Docling MCP Server
Generated: $(date)
Node: hx-docling-mcp-server (192.168.10.217)
OS: $(lsb_release -d | cut -f2)

Core System Packages:
- build-essential: $(dpkg -l | grep build-essential | awk '{print $3}')
- gcc: $(gcc --version | head -1)
- make: $(make --version | head -1)

Python Packages:
- python3.11: $(python3.11 --version)
- python3.11-venv: $(dpkg -l | grep python3.11-venv | awk '{print $3}')
- python3.11-dev: $(dpkg -l | grep python3.11-dev | awk '{print $3}')
- pip: $(python3.11 -m pip --version)

Document Processing Packages:
- poppler-utils: $(dpkg -l | grep poppler-utils | awk '{print $3}')
- tesseract-ocr: $(tesseract --version | head -1)
- libmagic1: $(dpkg -l | grep libmagic1 | awk '{print $3}')

Image Processing Packages:
- libpng-dev: $(dpkg -l | grep libpng-dev | awk '{print $3}')
- libjpeg-dev: $(dpkg -l | grep libjpeg-dev | awk '{print $3}')
- libtiff-dev: $(dpkg -l | grep libtiff-dev | awk '{print $3}')

System Utilities:
- curl: $(curl --version | head -1)
- wget: $(wget --version | head -1)
- git: $(git --version)
- vim: $(vim --version | head -1)
- htop: $(dpkg -l | grep ^ii.*htop | awk '{print $3}')
- net-tools: $(dpkg -l | grep net-tools | awk '{print $3}')

Installation Date: $(date)
Installed By: $(whoami)
EOF

cat /tmp/package-versions.txt

# Copy to deployment documentation
sudo mkdir -p /opt/docling-mcp/documentation
sudo cp /tmp/package-versions.txt /opt/docling-mcp/documentation/system-packages.txt
```

---

## Validation

### Validation Commands

```bash
# 1. Verify all packages installed
dpkg -l | grep -E "(build-essential|python3.11|poppler-utils|tesseract-ocr|libmagic1|libpng-dev|libjpeg-dev|curl|wget|git)" | wc -l
# Expected: 15+ packages

# 2. Verify Python 3.11
python3.11 --version
# Expected: Python 3.11.x

# 3. Verify venv module
python3.11 -m venv --help | head -1
# Expected: usage: venv...

# 4. Verify poppler
pdftotext -v 2>&1 | head -1
# Expected: pdftotext version 23.x

# 5. Verify tesseract
tesseract --version 2>&1 | head -1
# Expected: tesseract 5.x

# 6. Verify libmagic
file --version
# Expected: file-5.x

# 7. Verify gcc
gcc --version | head -1
# Expected: gcc (Ubuntu 13.x)

# 8. Verify disk space remaining
df -h / | tail -1 | awk '{print $4}'
# Expected: >8GB available
```

### Success Criteria

- ✅ All 18 core packages installed
- ✅ Python 3.11.x verified
- ✅ All document processing libraries verified
- ✅ All build tools verified
- ✅ Disk space >8GB remaining
- ✅ No package installation errors
- ✅ Package version report generated

---

## Troubleshooting

### Issue: Package Not Found

**Symptom**: `E: Unable to locate package python3.11`

**Solution**:
```bash
# Add deadsnakes PPA for Python 3.11 (if not in Ubuntu 24.04 repos)
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
```

### Issue: Insufficient Disk Space

**Symptom**: `E: You don't have enough free space in /var/cache/apt/archives/`

**Solution**:
```bash
# Clean apt cache
sudo apt-get clean

# Remove old kernels
sudo apt-get autoremove -y

# Verify space
df -h /
```

### Issue: Package Installation Fails

**Symptom**: `E: Failed to fetch...`

**Solution**:
```bash
# Try different mirror
sudo sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list

# Update and retry
sudo apt-get update
sudo apt-get install -y <package-name>
```

---

## Rollback Procedure

**If installation causes issues**:

```bash
# Remove all installed packages
sudo apt-get remove -y build-essential python3.11 python3.11-venv python3.11-dev \
  poppler-utils tesseract-ocr tesseract-ocr-eng libmagic1 libmagic-dev \
  libpng-dev libjpeg-dev libtiff-dev curl wget git vim htop net-tools

# Autoremove dependencies
sudo apt-get autoremove -y

# Clean cache
sudo apt-get clean
```

---

## Dependencies

**Blocks**:
- Task 003: Create Python virtual environment (requires python3.11-venv)
- Task 004: Install Python dependencies (requires build tools for compilation)
- Task 005: Create service directory structure (requires system ready)

**Depends On**:
- Task 001: Create Samba AD service account (service account ready for ownership)
- Node accessibility (SSH connectivity)
- Internet connectivity (package downloads)

---

## Notes

### Package Installation Order Rationale

1. **System update first**: Ensures all existing packages up-to-date
2. **Build tools second**: Required for Python package compilation
3. **Python runtime third**: Core dependency for application
4. **Document processing fourth**: Application-specific libraries
5. **Utilities last**: Supporting tools

### Minimum Package Versions (Enforced at Install)

| Package | Minimum Version | Enforcement | Rationale |
|---------|----------------|-------------|-----------|-------|
| python3.11 | 3.11.0 | ✓ Automatic check with error exit | Required by docling~=2.25, FastMCP |
| poppler-utils | 23.0 | ✓ Automatic check with error exit | Modern PDF rendering support |
| tesseract-ocr | 5.0 | ✓ Automatic check with error exit | Improved OCR accuracy |
| libmagic1 | 5.0 | ✓ Automatic check with error exit | MIME type detection |
| gcc | 11.0 | ✓ Automatic check with error exit | C++17 support for Python extensions |
| curl | 7.0 | ✓ Automatic check with error exit | Modern TLS/HTTPS support |
| wget | 1.20 | ✓ Automatic check with error exit | Secure downloads |
| git | 2.25 | ⚠ Warning only | Enhanced performance (recommended) |

**Enforcement Mechanism**: Each critical package installation is immediately followed by version parsing and comparison. If version is below minimum, script exits with error code 1 and displays remediation options (PPA, backport, or build from source).

### HX-Infrastructure Standards Compliance

- ✅ **Bare-Metal Deployment**: No Docker packages installed
- ✅ **Manual Procedures**: All commands documented for human execution
- ✅ **No Automation**: No apt scripts, manual package installation
- ✅ **System Packages Only**: No third-party repositories (except deadsnakes if needed)

---

## References

- **Configuration Spec**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/configuration-spec.md` (Section 2: System Packages)
- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 002)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
