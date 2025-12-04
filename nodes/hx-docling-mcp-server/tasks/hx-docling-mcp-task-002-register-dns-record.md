# Task 002: Register DNS A Record

**Assigned To**: frank-lucas
**Estimated Effort**: 0.25 hours
**Dependencies**: None
**Status**: Not Started

## Objective

Register DNS A record `hx-docling-mcp-server.hx.dev.local` → `192.168.10.217` in the hx.dev.local DNS zone to enable hostname-based service discovery.

## Context

HX-Infrastructure uses hostname-based service discovery (NOT IP addresses) for all service integrations. DNS records MUST be created before service deployment to ensure:
- Services can resolve hostnames via DNS lookups
- Integration configurations use portable hostnames (not hardcoded IPs)
- Services survive IP address changes without reconfiguration
- Compliance with HX-Infrastructure naming standards

DNS records are managed via `samba-tool dns` on hx-dc-server (192.168.10.200), which serves as the authoritative DNS server for hx.dev.local domain.

## Credential Management

**SECURITY REQUIREMENT**: This task requires authentication credentials that MUST be stored securely.

### Required Credentials

1. **SSH Authentication**: SSH key-based authentication (preferred) or agent0 user password
2. **Domain Administrator**: Samba AD administrator password for DNS modifications

### Credential Setup

**Option 1: Environment Variables (Recommended)**

```bash
# Create credentials file (DO NOT COMMIT TO GIT)
cat > ~/.hx-credentials << 'EOF'
# HX-Infrastructure Credentials
# WARNING: Keep this file secure (chmod 600)
export SSH_AGENT0_PASSWORD="your-ssh-password-here"
export DNS_ADMIN_PASSWORD="your-admin-password-here"
EOF

# Secure the credentials file
chmod 600 ~/.hx-credentials

# Source credentials before running commands
source ~/.hx-credentials
```

**Option 2: SSH Key Authentication (Most Secure)**

```bash
# Generate SSH key if not exists
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_hx

# Copy public key to target servers
ssh-copy-id -i ~/.ssh/id_ed25519_hx.pub agent0@hx-dc-server.hx.dev.local
ssh-copy-id -i ~/.ssh/id_ed25519_hx.pub agent0@hx-docling-mcp-server.hx.dev.local

# Test passwordless authentication
ssh -i ~/.ssh/id_ed25519_hx agent0@hx-dc-server.hx.dev.local "echo 'SSH key auth working'"
```

**Option 3: Credential Reference File**

Refer to `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` for centralized credential storage (ensure this file is gitignored).

### Security Notes

- ⚠️ **NEVER commit credentials to Git**: Add `.hx-credentials` to `.gitignore`
- ⚠️ **Rotate exposed credentials immediately**: If credentials were committed, rotate them via `samba-tool user setpassword`
- ✅ **Use SSH keys when possible**: Eliminates password storage
- ✅ **Restrict file permissions**: `chmod 600` on credential files
- ✅ **Use credential managers**: Consider HashiCorp Vault or pass for production

## Pre-Execution Validation

**CRITICAL**: Check if DNS A record already exists BEFORE creating it.

```bash
# Query DNS for existing A record
nslookup hx-docling-mcp-server.hx.dev.local hx-dc-server.hx.dev.local

# Check if resolves to correct IP
if nslookup hx-docling-mcp-server.hx.dev.local hx-dc-server.hx.dev.local | grep -q "192.168.10.217"; then
    echo "✅ VALIDATION RESULT: DNS A record already exists and resolves correctly"
    echo "ACTION: SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION RESULT: DNS A record does NOT exist or resolves incorrectly"
    echo "ACTION: PROCEED with DNS registration"
fi
```

**If DNS Record Exists**: Skip to Validation section

**If DNS Record Does Not Exist**: Continue with Implementation Steps below

---

## Acceptance Criteria

- [ ] DNS A record created: `hx-docling-mcp-server.hx.dev.local` → `192.168.10.217`
- [ ] DNS resolution verified via `nslookup` from multiple servers
- [ ] Forward DNS lookup returns correct IP: 192.168.10.217
- [ ] Reverse DNS lookup configured (optional but recommended)
- [ ] DNS record persistent across hx-dc-server reboots
- [ ] DNS resolution working from hx-docling-mcp-server itself

## Implementation Steps

### Step 1: SSH to Domain Controller

```bash
# Source credentials (if using password auth)
source ~/.hx-credentials

# Connect to hx-dc-server as agent0
# Option 1: SSH key authentication (recommended)
ssh -i ~/.ssh/id_ed25519_hx agent0@hx-dc-server.hx.dev.local

# Option 2: Password authentication (requires sshpass and sourced credentials)
# sshpass -p "${SSH_AGENT0_PASSWORD}" ssh agent0@hx-dc-server.hx.dev.local
```

### Step 2: Add DNS A Record

```bash
# Source credentials if not already loaded
source ~/.hx-credentials

# Add A record for hx-docling-mcp-server using environment variable
echo "${DNS_ADMIN_PASSWORD}" | sudo samba-tool dns add localhost hx.dev.local hx-docling-mcp-server A 192.168.10.217 -U administrator --password="${DNS_ADMIN_PASSWORD}"

# Expected output:
# Record added successfully
```

### Step 3: Verify DNS Record on Domain Controller

```bash
# Query DNS record directly using environment variable
sudo samba-tool dns query localhost hx.dev.local hx-docling-mcp-server A -U administrator --password="${DNS_ADMIN_PASSWORD}"

# Expected output:
#   Name=, Records=1, Children=0
#     A: 192.168.10.217 (flags=f0, serial=110, ttl=900)

# Alternative verification with nslookup
nslookup hx-docling-mcp-server.hx.dev.local localhost
# Expected output:
# Server:         localhost
# Address:        127.0.0.1#53
#
# Name:   hx-docling-mcp-server.hx.dev.local
# Address: 192.168.10.217
```

### Step 4: Verify DNS Resolution from Target Server

```bash
# SSH to hx-docling-mcp-server using key authentication
ssh -i ~/.ssh/id_ed25519_hx agent0@hx-docling-mcp-server.hx.dev.local

# Or with password (requires sshpass and sourced credentials)
# sshpass -p "${SSH_AGENT0_PASSWORD}" ssh agent0@hx-docling-mcp-server.hx.dev.local

# Test DNS resolution via nslookup
nslookup hx-docling-mcp-server.hx.dev.local
# Expected output:
# Server:         192.168.10.200
# Address:        192.168.10.200#53
#
# Name:   hx-docling-mcp-server.hx.dev.local
# Address: 192.168.10.217

# Test DNS resolution via dig (detailed output)
dig hx-docling-mcp-server.hx.dev.local

# Test DNS resolution via ping
ping -c 3 hx-docling-mcp-server.hx.dev.local
# Should show: PING hx-docling-mcp-server.hx.dev.local (192.168.10.217)
```

### Step 5: Verify DNS Resolution from Other Servers (Spot Check)

```bash
# Test from hx-litellm-server (dependency integration test)
ssh agent0@hx-litellm-server.hx.dev.local
nslookup hx-docling-mcp-server.hx.dev.local
# Should resolve to 192.168.10.217

# Test from hx-qdrant-server (dependency integration test)
ssh agent0@hx-qdrant-server.hx.dev.local
nslookup hx-docling-mcp-server.hx.dev.local
# Should resolve to 192.168.10.217
```

### Step 6: Add Reverse DNS Record (Optional but Recommended)

```bash
# SSH back to hx-dc-server
ssh -i ~/.ssh/id_ed25519_hx agent0@hx-dc-server.hx.dev.local

# Add PTR record for reverse DNS (10.168.192.in-addr.arpa zone) using environment variable
sudo samba-tool dns add localhost 10.168.192.in-addr.arpa 217 PTR hx-docling-mcp-server.hx.dev.local. -U administrator --password="${DNS_ADMIN_PASSWORD}"

# Verify reverse DNS
nslookup 192.168.10.217
# Expected output:
# Server:         192.168.10.200
# Address:        192.168.10.200#53
#
# 217.10.168.192.in-addr.arpa     name = hx-docling-mcp-server.hx.dev.local.
```

## Validation

**Validation Commands (Run on hx-docling-mcp-server):**

```bash
# 1. Verify forward DNS resolution
nslookup hx-docling-mcp-server.hx.dev.local | grep -q "192.168.10.217" && echo "PASS: Forward DNS works" || echo "FAIL: Forward DNS broken"

# 2. Verify DNS resolution via ping
ping -c 1 hx-docling-mcp-server.hx.dev.local > /dev/null 2>&1 && echo "PASS: Ping resolves hostname" || echo "FAIL: Ping cannot resolve hostname"

# 3. Verify DNS resolution via dig
dig +short hx-docling-mcp-server.hx.dev.local | grep -q "192.168.10.217" && echo "PASS: Dig resolves correctly" || echo "FAIL: Dig resolution failed"

# 4. Verify reverse DNS (optional)
nslookup 192.168.10.217 | grep -q "hx-docling-mcp-server.hx.dev.local" && echo "PASS: Reverse DNS works" || echo "INFO: Reverse DNS not configured (optional)"
```

**Expected Outcomes:**
- Forward DNS resolves `hx-docling-mcp-server.hx.dev.local` → `192.168.10.217`
- DNS resolution works from hx-docling-mcp-server itself
- DNS resolution works from dependency servers (hx-litellm-server, hx-qdrant-server, hx-redis-server)
- Reverse DNS resolves `192.168.10.217` → `hx-docling-mcp-server.hx.dev.local` (optional)

## Notes

### Why DNS Before Deployment

**Critical Requirement**: DNS records MUST exist before service deployment because:
- Service configuration files use hostnames (e.g., `LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000`)
- Integration tests will fail if hostnames don't resolve
- Dependency health checks use hostname-based URLs
- IP address changes don't require service reconfiguration if DNS is used

**Anti-Pattern**: Hardcoding IP addresses in configuration
- ❌ `LITELLM_API_BASE=http://192.168.10.212:4000` (brittle, requires reconfiguration on IP change)
- ✅ `LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000` (portable, survives IP changes)

### DNS Record Details

**Record Type**: A (Address Record)
- Maps hostname to IPv4 address
- TTL: 900 seconds (15 minutes) - Samba default
- Flags: f0 (standard dynamic DNS record)

**Reverse DNS (PTR)**: Optional but recommended
- Enables reverse lookups (IP → hostname)
- Useful for logging and debugging
- Required for some security tools and monitoring

### HX-Infrastructure Naming Convention

**Format**: `hx-<service>-server.hx.dev.local`
- Prefix: `hx-` (HX-Infrastructure namespace)
- Service: `docling-mcp` (service identifier)
- Suffix: `-server` (node type)
- Domain: `hx.dev.local` (internal domain)

**Full FQDN**: `hx-docling-mcp-server.hx.dev.local`

### DNS Infrastructure

**Primary DNS Server**: hx-dc-server (192.168.10.200)
- Samba AD integrated DNS
- Authoritative for hx.dev.local zone
- Supports dynamic updates (via samba-tool dns)

**DNS Clients**: All HX-Infrastructure servers
- DNS resolver: hx-dc-server (192.168.10.200) via /etc/resolv.conf
- SSSD integration: Automatic DNS updates on realm join

### Troubleshooting

**If DNS resolution fails:**
```bash
# Check DNS server is running on hx-dc-server
ssh agent0@hx-dc-server.hx.dev.local
sudo systemctl status samba-ad-dc
# Should be active (running)

# Check /etc/resolv.conf on target server
cat /etc/resolv.conf
# Should contain: nameserver 192.168.10.200

# Flush local DNS cache and retry
sudo systemd-resolve --flush-caches
nslookup hx-docling-mcp-server.hx.dev.local
```

**If DNS record not persisting:**
- Samba AD DNS stores records in `/var/lib/samba/private/dns.tdb`
- Records are persistent across reboots
- If record disappears, check Samba AD replication health

**If wrong IP returned:**
```bash
# Check for duplicate DNS records
sudo samba-tool dns query localhost hx.dev.local hx-docling-mcp-server ALL -U administrator
# Should show only one A record with correct IP

# Delete incorrect record if duplicate exists
sudo samba-tool dns delete localhost hx.dev.local hx-docling-mcp-server A <wrong-ip> -U administrator
```

## References

- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md` (Section: Node Assignment)
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 3.1: Node Requirements)
- **Naming Conventions**: `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
- **Credentials**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (Secure credential storage - never commit plaintext passwords)

## Security Remediation

**⚠️ CRITICAL: Exposed Credentials in Git History**

This file previously contained plaintext passwords committed to Git:
- `Major8859!` (agent0 SSH password)
- `Major3059!` (Domain Administrator password)

**Required Actions:**

1. **Rotate Compromised Credentials Immediately**:
```bash
# SSH to hx-dc-server
ssh -i ~/.ssh/id_ed25519_hx agent0@hx-dc-server.hx.dev.local

# Rotate Administrator password
sudo samba-tool user setpassword administrator
# Enter new password and store securely in ~/.hx-credentials

# Update agent0 password on all servers
echo 'agent0:NEW_PASSWORD' | sudo chpasswd
```

2. **Add Credential Files to .gitignore**:
```bash
# Add to root .gitignore
echo ".hx-credentials" >> /home/agent0/HX-Infrastructure/.gitignore
echo "hx-knowledge/docs/*credentials*.md" >> /home/agent0/HX-Infrastructure/.gitignore
```

3. **Purge Credentials from Git History** (if needed):
```bash
# Use git-filter-repo or BFG Repo-Cleaner
git filter-repo --path hx-docling-mcp-task-002-register-dns-record.md --invert-paths
# OR use BFG
# bfg --replace-text passwords.txt
```

4. **Verify .gitignore Coverage**:
```bash
# Test credential file is ignored
touch ~/.hx-credentials
git status | grep -q ".hx-credentials" && echo "⚠️ FAIL: Credentials not ignored" || echo "✅ PASS: Credentials ignored"
```

## Risk Assessment

**Risk**: Low (DNS operations) / High (exposed credentials - now remediated)
- DNS record creation is non-destructive
- No impact on operational services
- Easily reversible if incorrect
- **Security risk mitigated**: Hardcoded passwords replaced with environment variables

**Mitigation**:
- Verify DNS resolution immediately after creation
- Test from multiple servers
- Confirm correct IP before proceeding to deployment
- Document DNS record for future reference
- **Use SSH keys and environment variables for all authentication**
- **Rotate any credentials that were previously committed to Git**

**Rollback Procedure**:
```bash
# Source credentials
source ~/.hx-credentials

# If DNS record needs to be removed
sudo samba-tool dns delete localhost hx.dev.local hx-docling-mcp-server A 192.168.10.217 -U administrator --password="${DNS_ADMIN_PASSWORD}"
```
