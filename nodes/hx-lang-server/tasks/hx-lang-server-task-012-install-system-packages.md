# Task 012: Install System Package Dependencies

**Task ID**: hx-lang-server-task-012
**Phase**: Pre-Deployment (System Dependencies)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 011 (Python Installation)
**Estimated Effort**: 45 minutes

---

## Objective

Install system-level package dependencies required for hx-lang-server including build tools, SSL libraries, and development headers for Python package compilation on Ubuntu 24.04 LTS.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 011 (Python Installation) completed
- [ ] Network connectivity to Ubuntu package repositories

---

## Pre-Execution Validation

**CRITICAL**: Check if system packages are already installed BEFORE running apt-get install.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check system packages
echo "Checking system package installation status..."

PACKAGES_TO_CHECK=(
    "build-essential"
    "libssl-dev"
    "libffi-dev"
    "libpq-dev"
    "git"
    "curl"
    "wget"
)

ALL_INSTALLED=true

for pkg in "${PACKAGES_TO_CHECK[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo "INSTALLED: $pkg"
    else
        echo "MISSING: $pkg"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    echo ""
    echo "VALIDATION RESULT: All system packages already installed"
    echo "ACTION: SKIP installation, proceed to validation section"
else
    echo ""
    echo "VALIDATION RESULT: Some packages missing"
    echo "ACTION: PROCEED with installation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Not Complete**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Update Package Repository Cache

```bash
# Update apt package cache
echo "Updating package repository cache..."
sudo apt-get update

if [ $? -eq 0 ]; then
    echo "APT cache updated successfully"
else
    echo "APT cache update failed"
    exit 1
fi
```

### Step 2: Install Build Tools and Compilers

```bash
# Install build-essential (gcc, g++, make)
echo "Installing build tools..."
sudo apt-get install -y build-essential

# Verify installation
gcc --version | head -n1
make --version | head -n1

if [ $? -eq 0 ]; then
    echo "Build tools installed successfully"
else
    echo "Build tools installation failed"
    exit 1
fi
```

### Step 3: Install SSL and Cryptographic Libraries

```bash
# Install SSL/TLS and cryptographic development libraries
echo "Installing SSL and cryptographic libraries..."
sudo apt-get install -y \
    libssl-dev \
    libffi-dev

# Verify libraries
dpkg -l | grep -E '(libssl-dev|libffi-dev)' | awk '{print $2, $3}'

if [ $? -eq 0 ]; then
    echo "SSL/cryptographic libraries installed successfully"
else
    echo "SSL/cryptographic libraries installation failed"
    exit 1
fi
```

### Step 4: Install PostgreSQL Development Libraries

```bash
# Install PostgreSQL client development libraries
# Required for psycopg[binary] compilation
echo "Installing PostgreSQL development libraries..."
sudo apt-get install -y libpq-dev

# Verify installation
pg_config --version || echo "pg_config not in PATH (acceptable)"
dpkg -l | grep libpq-dev

if [ $? -eq 0 ]; then
    echo "PostgreSQL development libraries installed successfully"
else
    echo "PostgreSQL development libraries installation failed"
    exit 1
fi
```

### Step 5: Install Network Utilities

```bash
# Install network utilities
echo "Installing network utilities..."
sudo apt-get install -y \
    curl \
    wget \
    git

# Verify installations
curl --version | head -n1
wget --version | head -n1
git --version

if [ $? -eq 0 ]; then
    echo "Network utilities installed successfully"
else
    echo "Network utilities installation failed"
    exit 1
fi
```

### Step 6: Install Additional Runtime Dependencies

```bash
# Install additional dependencies
echo "Installing additional runtime dependencies..."
sudo apt-get install -y \
    ca-certificates \
    gnupg

# Verify installations
dpkg -l | grep -E '(ca-certificates|gnupg)' | awk '{print $2, $3}'

if [ $? -eq 0 ]; then
    echo "Additional dependencies installed successfully"
else
    echo "Additional dependencies installation failed"
    exit 1
fi
```

### Step 7: Document Installed Packages

```bash
# Document installed packages for future reference
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/system-packages-inventory.txt" > /dev/null <<EOF
# System Package Inventory
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-012

## Build Tools
$(gcc --version | head -n1)
$(make --version | head -n1)

## SSL/Cryptographic Libraries
libssl-dev: $(dpkg -l | grep libssl-dev | awk '{print $3}')
libffi-dev: $(dpkg -l | grep libffi-dev | awk '{print $3}')

## PostgreSQL Development
libpq-dev: $(dpkg -l | grep libpq-dev | awk '{print $3}')

## Network Utilities
$(curl --version | head -n1)
$(wget --version | head -n1)
$(git --version)

## Certificates
ca-certificates: $(dpkg -l | grep ca-certificates | awk '{print $3}')

## Package List (Detailed)
$(dpkg -l | grep -E '(build-essential|libssl-dev|libffi-dev|libpq-dev|curl|wget|git|ca-certificates)')
EOF

echo "System packages documented: $DOC_DIR/system-packages-inventory.txt"
cat "$DOC_DIR/system-packages-inventory.txt"
```

---

## Deliverables

| Deliverable | Path/Package | Description |
|-------------|--------------|-------------|
| Build Tools | build-essential | GCC, G++, Make |
| SSL Libraries | libssl-dev | OpenSSL development headers |
| FFI Libraries | libffi-dev | Foreign Function Interface |
| PostgreSQL Dev | libpq-dev | PostgreSQL client development |
| Network Tools | curl, wget, git | Network utilities |
| Inventory Doc | /opt/hx-lang-server/deployment-docs/system-packages-inventory.txt | Package documentation |

---

## Verification

**Validation Commands:**

```bash
echo "=== System Package Installation Validation ==="

VALIDATION_PASSED=true

# Check 1: Build tools
echo "1. Build Tools:"
if command -v gcc > /dev/null 2>&1; then
    gcc --version | head -n1
    echo "PASSED: GCC available"
else
    echo "FAILED: GCC not found"
    VALIDATION_PASSED=false
fi

# Check 2: SSL libraries
echo ""
echo "2. SSL Libraries:"
if dpkg -l | grep -q "^ii  libssl-dev "; then
    dpkg -l | grep libssl-dev | awk '{print $2, $3}'
    echo "PASSED: libssl-dev installed"
else
    echo "FAILED: libssl-dev not installed"
    VALIDATION_PASSED=false
fi

# Check 3: FFI libraries
echo ""
echo "3. FFI Libraries:"
if dpkg -l | grep -q "^ii  libffi-dev "; then
    dpkg -l | grep libffi-dev | awk '{print $2, $3}'
    echo "PASSED: libffi-dev installed"
else
    echo "FAILED: libffi-dev not installed"
    VALIDATION_PASSED=false
fi

# Check 4: PostgreSQL development
echo ""
echo "4. PostgreSQL Development Libraries:"
if dpkg -l | grep -q "^ii  libpq-dev "; then
    dpkg -l | grep libpq-dev | awk '{print $2, $3}'
    echo "PASSED: libpq-dev installed"
else
    echo "FAILED: libpq-dev not installed"
    VALIDATION_PASSED=false
fi

# Check 5: Network utilities
echo ""
echo "5. Network Utilities:"
for cmd in curl wget git; do
    if command -v $cmd > /dev/null 2>&1; then
        echo "PASSED: $cmd available"
    else
        echo "FAILED: $cmd not found"
        VALIDATION_PASSED=false
    fi
done

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - System packages ready for hx-lang-server"
else
    echo "VALIDATION FAILED - Some packages missing or not accessible"
    exit 1
fi
```

**Expected Results:**
- GCC compiler available and shows version
- libssl-dev package installed with version number
- libffi-dev package installed with version number
- libpq-dev package installed with version number
- curl, wget, git commands all available

---

## Rollback Procedure

Remove installed packages if needed:

```bash
# Remove system packages (CAUTION: may affect other services)
# Only execute if absolutely necessary

# Remove individual packages
sudo apt-get remove --purge libpq-dev
sudo apt-get remove --purge libffi-dev
sudo apt-get remove --purge libssl-dev

# Note: Do NOT remove build-essential, curl, wget, git
# as these are commonly used by other system services

# Clean up orphaned dependencies
sudo apt-get autoremove
```

---

## Notes

**Package Dependencies:**
- **build-essential**: Required for compiling Python C extensions (psycopg, etc.)
- **libssl-dev**: Required for httpx, aiohttp TLS support
- **libffi-dev**: Required for cffi Python package (cryptography dependency)
- **libpq-dev**: Required for psycopg[binary] PostgreSQL driver

**Ubuntu 24.04 LTS Considerations:**
- Package versions are from Ubuntu 24.04 repositories
- All packages use system default versions (no third-party PPAs)
- Package compatibility verified with Python 3.12

**Security Considerations:**
- Use only official Ubuntu repositories
- ca-certificates ensures TLS verification works correctly
- All packages from trusted sources (Ubuntu archive)

**Space Requirements:**
- Estimated disk usage: ~200MB for all packages
- Includes header files for compilation

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Dependencies - Python Dependencies (lines 600-626)
- Section: Node Requirements - Resource Requirements (lines 127-131)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 2: System Dependencies (Task Range 011-020)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Package repository unavailable**: Network issues prevent package download
   - Mitigation: Pre-check network connectivity; verify apt-get update succeeds
2. **Package conflicts**: New packages conflict with existing installations
   - Mitigation: Use Ubuntu 24.04 default packages; apt handles dependencies
3. **Disk space insufficient**: Not enough space for packages
   - Mitigation: Pre-check disk space (50GB required per spec)

**Dependencies Blocked:**
- Task 013 (Create Virtual Environment) uses build tools for compilation
- Task 014 (Install Python Dependencies) requires libpq-dev, libssl-dev
