# Task 001: Create Samba Active Directory Service Account

**Assigned To**: frank-lucas
**Estimated Effort**: 0.5 hours
**Dependencies**: None
**Status**: Not Started

## Objective

Create domain-integrated service account `docling-mcp@hx.dev.local` in Samba Active Directory for running the Docling MCP Server service.

## Context

All HX-Infrastructure services use domain-integrated service accounts created via Samba Active Directory (NOT local useradd). This ensures:
- Account availability across all domain-joined servers via SSSD replication
- Centralized identity management through hx-dc-server
- Kerberos authentication support
- Consistent UID/GID assignment from domain pool

**Critical**: Service accounts MUST be created via `samba-tool` on hx-dc-server (192.168.10.200), never via local account tools.

## Pre-Execution Validation

**CRITICAL**: Check if service account already exists BEFORE creating it to prevent duplication.

```bash
# Connect to hx-dc-server and check if account exists
ssh root@hx-dc-server.hx.dev.local "samba-tool user show docling-mcp 2>/dev/null"

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ VALIDATION RESULT: Service account 'docling-mcp' already exists"
    echo "ACTION: SKIP task execution - validate account properties instead"
    echo "NEXT: Verify password with: smbclient -L //hx-dc-server.hx.dev.local -U docling-mcp%Major8859!"
    exit 0
else
    echo "❌ VALIDATION RESULT: Service account 'docling-mcp' does NOT exist"
    echo "ACTION: PROCEED with service account creation"
fi
```

**If Account Exists**: Skip to Validation section, verify password and properties match requirements

**If Account Does Not Exist**: Continue with Implementation Steps below

---

## Acceptance Criteria

- [ ] Service account `docling-mcp@hx.dev.local` created via samba-tool on hx-dc-server
- [ ] Account password set to standard password: `Major8859!`
- [ ] Account description: "Docling MCP Server Service Account - Samba LDAP/DC"
- [ ] Account configured with home directory: `"/home/docling-mcp@hx.dev.local"`
- [ ] Account configured with login shell: `/bin/bash`
- [ ] Account replication verified via SSSD across domain-joined servers
- [ ] Account verification successful on hx-docling-mcp-server (192.168.10.217)

## Implementation Steps

### Step 1: SSH to Domain Controller

```bash
# Connect to hx-dc-server as agent0
ssh agent0@hx-dc-server.hx.dev.local
# Password: Major8859!

# Become root for samba-tool operations
sudo -i
```

### Step 2: Create Domain Service Account via samba-tool

```bash
# Create docling-mcp service account with standard password
samba-tool user create docling-mcp 'Major8859!' \
  --description='Docling MCP Server Service Account - Samba LDAP/DC' \
  --home-directory="/home/docling-mcp@hx.dev.local" \
  --login-shell=/bin/bash \
  --use-username-as-cn

# Expected output:
# User 'docling-mcp' created successfully
```

### Step 3: Verify Account Creation on Domain Controller

```bash
# Show account details
samba-tool user show docling-mcp

# Verify account via wbinfo
wbinfo -i docling-mcp@hx.dev.local

# Expected output includes:
# - dn: CN=docling-mcp,CN=Users,DC=hx,DC=dev,DC=local
# - sAMAccountName: docling-mcp
# - UID: 1114201XXX (auto-assigned by Samba DC)
# - GID: 1114200513 (Domain Users)
```

### Step 4: Verify Account Replication to Target Server

```bash
# SSH to hx-docling-mcp-server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Verify account resolution via id
id docling-mcp@hx.dev.local
# Expected: uid=1114201XXX(docling-mcp@hx.dev.local) gid=1114200513(domain users@hx.dev.local)

# Verify account resolution via getent
getent passwd docling-mcp@hx.dev.local
# Expected: docling-mcp@hx.dev.local:*:1114201XXX:1114200513::/home/docling-mcp@hx.dev.local:/bin/bash

# Verify account resolution via wbinfo
wbinfo -i docling-mcp@hx.dev.local
# Expected: docling-mcp@hx.dev.local:*:1114201XXX:1114200513::/home/docling-mcp@hx.dev.local:/bin/bash
```

### Step 5: Test Authentication (Optional)

```bash
# Test SSH login with service account (optional verification)
ssh docling-mcp@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!
# Should succeed and create home directory automatically

# Verify home directory created
ls -la "/home/docling-mcp@hx.dev.local"
# Should show home directory owned by docling-mcp@hx.dev.local

# Exit back to agent0
exit
```

## Validation

**Validation Commands (Run on hx-docling-mcp-server):**

```bash
# 1. Verify account exists with domain UID
id docling-mcp@hx.dev.local | grep -q "1114" && echo "PASS: Domain UID assigned" || echo "FAIL: Domain UID not found"

# 2. Verify account has correct home directory
getent passwd docling-mcp@hx.dev.local | grep -q "/home/docling-mcp@hx.dev.local" && echo "PASS: Home directory correct" || echo "FAIL: Home directory incorrect"

# 3. Verify account has correct shell
getent passwd docling-mcp@hx.dev.local | grep -q "/bin/bash" && echo "PASS: Shell correct" || echo "FAIL: Shell incorrect"

# 4. Verify account authentication (optional)
su - docling-mcp@hx.dev.local -c "whoami" && echo "PASS: Authentication works" || echo "FAIL: Authentication failed"
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Account UID starts with 1114 (domain-assigned)
- Account available immediately on all domain-joined servers via SSSD
- Account can authenticate with standard password `Major8859!`

## Notes

### Standard Password Policy

**ALL service accounts use password**: `Major8859!`

This is HX-Infrastructure standard for development environment. Reference: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (AUTHORITATIVE)

### Why Samba AD vs Local Account

**Domain-Integrated (samba-tool) Advantages:**
- Account replicates to all domain-joined servers automatically
- Centralized identity management
- Kerberos authentication support
- Consistent UID/GID allocation
- No manual account creation on each server

**Local Account (useradd) Disadvantages:**
- Must create account manually on each server
- UID/GID conflicts across servers
- No Kerberos support
- No centralized management

### Account Naming Convention

Format: `<service-name>@hx.dev.local`
- Service name: `docling-mcp` (lowercase, hyphen-separated)
- Domain suffix: `@hx.dev.local` (required for domain accounts)
- Full UPN: `docling-mcp@hx.dev.local`

### Security Considerations

- Service account runs with non-root privileges (security best practice)
- Account uses standard password (acceptable for dev environment)
- Account has no sudo privileges by default (principle of least privilege)
- Account home directory created on first login with proper permissions (700)

### Troubleshooting

**If account not found on target server:**
```bash
# Restart SSSD to force replication
sudo systemctl restart sssd

# Wait 10 seconds, then retry
sleep 10
id docling-mcp@hx.dev.local
```

**If UID starts with 1000 instead of 1114:**
- Account was created locally, not via Samba AD
- Delete local account: `sudo userdel -r docling-mcp`
- Recreate via samba-tool on hx-dc-server

**If authentication fails:**
- Verify password: `Major8859!` (case-sensitive)
- Verify domain joined: `sudo realm list` (should show `configured: kerberos-member`)
- Verify SSSD running: `sudo systemctl status sssd`

## References

- **Credential Source**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (lines 20-46, 965-1021)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 3.2: User and Group Management)
- **Naming Conventions**: `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`

## Risk Assessment

**Risk**: Low
- Routine service account creation following established pattern
- No impact on operational services
- Easily reversible if issues occur

**Mitigation**:
- Use standard password for consistency
- Verify replication before proceeding to next tasks
- Test authentication before service deployment
