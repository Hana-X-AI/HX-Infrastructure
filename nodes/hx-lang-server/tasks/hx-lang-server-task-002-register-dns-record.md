# Task 002: Register DNS Record

**Assigned To**: frank-lucas
**Estimated Effort**: 0.25 hours
**Dependencies**: None (can run in parallel with Task 001)
**Status**: Not Started
**Phase**: Pre-Deployment

## Objective

Create DNS A record for `hx-lang-server.hx.dev.local` pointing to `192.168.10.226` in the hx.dev.local DNS zone managed by hx-dc-server.

## Context

DNS records must be created BEFORE service deployment to ensure hostname resolution is available when the service starts. All DNS records for hx.dev.local are managed by Samba DNS on hx-dc-server (192.168.10.200).

**Why DNS is Critical:**
- FastAPI service binds to hostname-based configuration
- Integration points reference hostname (not IP)
- Health checks use DNS resolution
- Certificate validation requires valid DNS records

## Pre-Execution Validation

**CRITICAL**: Check if DNS record already exists BEFORE creating it to prevent duplication or conflicts.

```bash
# Test DNS resolution from any domain-joined server
nslookup hx-lang-server.hx.dev.local

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ VALIDATION RESULT: DNS record 'hx-lang-server.hx.dev.local' already exists"
    echo "ACTION: Verify IP address matches 192.168.10.226"
    nslookup hx-lang-server.hx.dev.local | grep -A1 "Name:" | grep "Address:"
    exit 0
else
    echo "❌ VALIDATION RESULT: DNS record 'hx-lang-server.hx.dev.local' does NOT exist"
    echo "ACTION: PROCEED with DNS record creation"
fi
```

**If Record Exists**: Verify IP address matches specification (192.168.10.226)

**If Record Does Not Exist**: Continue with Implementation Steps below

---

## Acceptance Criteria

- [ ] DNS A record created: `hx-lang-server.hx.dev.local` → `192.168.10.226`
- [ ] DNS resolution verified from hx-dc-server
- [ ] DNS resolution verified from hx-lang-server
- [ ] DNS resolution verified from at least 2 other domain-joined servers
- [ ] Reverse DNS (PTR) resolution working (optional but recommended)
- [ ] ping test successful to hostname from multiple servers

## Implementation Steps

### Step 1: SSH to Domain Controller

```bash
# Connect to hx-dc-server as agent0
ssh agent0@hx-dc-server.hx.dev.local
# Password: Major8859!

# Become root for DNS operations
sudo -i
```

### Step 2: Create DNS A Record

```bash
# Add A record for hx-lang-server
samba-tool dns add localhost hx.dev.local hx-lang-server A 192.168.10.226 -U administrator
# Password when prompted: Major3059!

# Expected output:
# Record added successfully
```

### Step 3: Verify DNS Record on Domain Controller

```bash
# Query DNS record directly on DC
samba-tool dns query localhost hx.dev.local hx-lang-server A -U administrator
# Password when prompted: Major3059!

# Expected output:
# Name=, Records=1, Children=0
#   A: 192.168.10.226 (flags=f0, serial=110, ttl=900)

# Test resolution with nslookup
nslookup hx-lang-server.hx.dev.local
# Expected output:
# Server:		127.0.0.1
# Address:	127.0.0.1#53
#
# Name:	hx-lang-server.hx.dev.local
# Address: 192.168.10.226
```

### Step 4: Verify DNS Resolution from Target Server

```bash
# SSH to hx-lang-server
ssh agent0@hx-lang-server.hx.dev.local
# Password: Major8859!

# Test DNS resolution with nslookup
nslookup hx-lang-server.hx.dev.local
# Expected: Address: 192.168.10.226

# Test DNS resolution with dig
dig hx-lang-server.hx.dev.local +short
# Expected: 192.168.10.226

# Test ICMP ping
ping -c 3 hx-lang-server.hx.dev.local
# Expected: 3 packets transmitted, 3 received, 0% packet loss
```

### Step 5: Verify DNS Resolution from Multiple Servers

```bash
# Test from hx-postgres-server (external dependency)
ssh agent0@hx-postgres-server.hx.dev.local "nslookup hx-lang-server.hx.dev.local"
# Expected: Address: 192.168.10.226

# Test from hx-redis-server (external dependency)
ssh agent0@hx-redis-server.hx.dev.local "nslookup hx-lang-server.hx.dev.local"
# Expected: Address: 192.168.10.226

# Test from hx-ollama1-server (external dependency)
ssh agent0@hx-ollama1-server.hx.dev.local "nslookup hx-lang-server.hx.dev.local"
# Expected: Address: 192.168.10.226
```

### Step 6: Create Reverse DNS Record (Optional but Recommended)

```bash
# SSH to hx-dc-server
ssh agent0@hx-dc-server.hx.dev.local
sudo -i

# Add PTR record for reverse DNS
samba-tool dns add localhost 10.168.192.in-addr.arpa 226 PTR hx-lang-server.hx.dev.local -U administrator
# Password when prompted: Major3059!

# Verify reverse DNS
nslookup 192.168.10.226
# Expected: 226.10.168.192.in-addr.arpa	name = hx-lang-server.hx.dev.local.
```

## Validation

**Validation Commands (Run from hx-lang-server):**

```bash
# 1. Verify forward DNS resolution (A record)
nslookup hx-lang-server.hx.dev.local | grep -q "192.168.10.226" && echo "PASS: Forward DNS resolution" || echo "FAIL: Forward DNS failed"

# 2. Verify ping connectivity
ping -c 1 hx-lang-server.hx.dev.local > /dev/null 2>&1 && echo "PASS: Ping successful" || echo "FAIL: Ping failed"

# 3. Verify dig resolution
dig hx-lang-server.hx.dev.local +short | grep -q "192.168.10.226" && echo "PASS: Dig resolution" || echo "FAIL: Dig resolution failed"

# 4. Verify hostname command
hostname -f | grep -q "hx-lang-server.hx.dev.local" && echo "PASS: Hostname FQDN correct" || echo "WARN: Hostname FQDN not set"

# 5. Verify reverse DNS (optional)
nslookup 192.168.10.226 | grep -q "hx-lang-server.hx.dev.local" && echo "PASS: Reverse DNS" || echo "WARN: Reverse DNS not configured"
```

**Expected Outcomes:**
- All validation commands return "PASS" (or "WARN" for optional checks)
- DNS resolution works from multiple servers
- Ping connectivity confirmed
- Hostname FQDN matches DNS record

## Deliverables

1. DNS A record created: `hx-lang-server.hx.dev.local` → `192.168.10.226`
2. DNS resolution verified from at least 3 servers
3. Validation output confirming all acceptance criteria met
4. Reverse DNS record created (optional)

## Rollback Procedure

**If DNS record creation fails or needs reversal:**

```bash
# SSH to hx-dc-server
ssh agent0@hx-dc-server.hx.dev.local
sudo -i

# Delete A record
samba-tool dns delete localhost hx.dev.local hx-lang-server A 192.168.10.226 -U administrator
# Password: Major3059!

# Verify deletion
nslookup hx-lang-server.hx.dev.local 2>&1 | grep -q "server can't find" && echo "A record deleted successfully"

# Delete PTR record (if created)
samba-tool dns delete localhost 10.168.192.in-addr.arpa 226 PTR hx-lang-server.hx.dev.local -U administrator
# Password: Major3059!

# Verify PTR deletion
nslookup 192.168.10.226 2>&1 | grep -q "server can't find" && echo "PTR record deleted successfully"
```

## Notes

### DNS Propagation

- DNS changes are immediate within Samba DNS (no propagation delay)
- SSSD cache may take 30-60 seconds to update on clients
- Force SSSD cache clear if needed: `sudo systemctl restart sssd`

### DNS Record Types

**A Record (Address Record):**
- Maps hostname → IP address
- Type: Forward DNS
- Example: hx-lang-server.hx.dev.local → 192.168.10.226

**PTR Record (Pointer Record):**
- Maps IP address → hostname
- Type: Reverse DNS
- Example: 192.168.10.226 → hx-lang-server.hx.dev.local
- Optional but recommended for logging and security

### Administrator Password

DNS modifications require Domain Administrator credentials:
- Username: `Administrator` (or `administrator`)
- Password: `Major3059!` (different from standard service password)
- Reference: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (lines 128-151)

### DNS Zone Structure

```
hx.dev.local (forward zone)
  ├── hx-dc-server.hx.dev.local → 192.168.10.200
  ├── hx-postgres-server.hx.dev.local → 192.168.10.209
  ├── hx-redis-server.hx.dev.local → 192.168.10.210
  ├── hx-lang-server.hx.dev.local → 192.168.10.226 (NEW)
  └── [other records...]

10.168.192.in-addr.arpa (reverse zone)
  ├── 200 → hx-dc-server.hx.dev.local
  ├── 209 → hx-postgres-server.hx.dev.local
  ├── 210 → hx-redis-server.hx.dev.local
  ├── 226 → hx-lang-server.hx.dev.local (NEW - optional)
  └── [other records...]
```

### Troubleshooting

**DNS resolution fails:**
```bash
# Check DNS server reachable
ping -c 3 hx-dc-server.hx.dev.local

# Check DNS configuration on client
cat /etc/resolv.conf | grep nameserver
# Should include: nameserver 192.168.10.200

# Check Samba DNS service running
ssh agent0@hx-dc-server.hx.dev.local "sudo systemctl status samba-ad-dc"

# Force DNS cache flush
sudo systemd-resolve --flush-caches
sudo systemctl restart systemd-resolved
```

**Record exists but wrong IP:**
```bash
# Delete incorrect record first
samba-tool dns delete localhost hx.dev.local hx-lang-server A <old-ip> -U administrator

# Then add correct record
samba-tool dns add localhost hx.dev.local hx-lang-server A 192.168.10.226 -U administrator
```

**Permission denied errors:**
- Verify using Domain Administrator credentials (not agent0)
- Username: `administrator` or `Administrator`
- Password: `Major3059!` (not `Major8859!`)

## References

- **Credential Source**: `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (lines 128-151 for Administrator password)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/charter/charter.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md` (Section: Node Requirements, Target Node)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`

## Risk Assessment

**Risk**: Low
- DNS record creation is non-disruptive
- No impact on operational services
- Easily reversible if issues occur

**Mitigation**:
- Verify record does not conflict before creation
- Test resolution from multiple servers
- Document rollback procedure
