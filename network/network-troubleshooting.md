# HX-Infrastructure Network Troubleshooting Procedures

**Document Type**: Procedure - Network Operations  
**Created**: 2025-11-15  
**Status**: ACTIVE - Operational Procedures  
**Location**: `/home/agent0/HX-Infrastructure/network/network-troubleshooting.md`

---

## Document Purpose

This document provides systematic troubleshooting procedures for diagnosing and resolving network issues in HX-Infrastructure. It covers common failure scenarios, diagnostic steps, and resolution procedures for the production network.

**Prerequisites:**
- SSH access to hx-control-node (192.168.10.203)
- Basic understanding of HX-Infrastructure network topology
- Familiarity with Linux networking commands

**Related Documents:**
- `network/network-topology.md` - Complete network architecture
- `network/port-mapping.md` - Service port assignments (when created)
- `inventory/nodes.md` - Server inventory and status

---

## Table of Contents

1. [Systematic Diagnostic Approach](#systematic-diagnostic-approach)
2. [Layer-by-Layer Troubleshooting](#layer-by-layer-troubleshooting)
3. [Common Network Issues](#common-network-issues)
4. [Service-Specific Issues](#service-specific-issues)
5. [Emergency Procedures](#emergency-procedures)
6. [Diagnostic Tools Reference](#diagnostic-tools-reference)

---

## Systematic Diagnostic Approach

### Troubleshooting Methodology

Follow this systematic approach for all network issues:

**Step 1: Define the Problem**
- What is not working? (be specific)
- When did it start failing?
- What changed recently?
- Can you reproduce the issue?
- What is the expected behavior?
- What is the actual behavior?

**Step 2: Gather Information**
- Run network health check script: `/home/agent0/HX-Infrastructure/procedures/network-health-check.sh`
- Check server status in inventory
- Review recent changes in change log
- Check relevant service logs

**Step 3: Isolate the Layer**
- Use OSI model to narrow scope:
  1. Physical (network connectivity)
  2. Data Link (Ethernet, MAC addresses)
  3. Network (IP routing, ping)
  4. Transport (TCP/UDP ports)
  5. Application (service-specific)

**Step 4: Test Hypothesis**
- Form hypothesis about root cause
- Design test to validate hypothesis
- Execute test and document results
- Adjust hypothesis based on results

**Step 5: Implement Fix**
- Apply fix with minimal impact
- Validate fix resolves issue
- Document solution in change log
- Update relevant documentation

**Step 6: Prevent Recurrence**
- Add monitoring for similar issues
- Update documentation
- Consider automation improvements
- Share lessons learned

---

## Layer-by-Layer Troubleshooting

### Layer 1: Physical Connectivity

**Symptoms:**
- Server completely unreachable
- No network services responding
- Cannot ping server

**Diagnostic Steps:**

```bash
# 1. Check if server is reachable from control node
ping -c 3 <server-ip>

# 2. Check network interface status on target server (if accessible)
ssh <server> "ip link show"
ssh <server> "ip addr show"

# 3. Check routing table
ssh <server> "ip route show"

# 4. Check for physical link
ssh <server> "ethtool eth0"  # or appropriate interface
```

**Common Causes:**
- Interface down
- Network cable unplugged
- Switch port issue
- Wrong IP configuration

**Resolution:**
```bash
# Bring interface up
ssh <server> "sudo ip link set eth0 up"

# Restart networking service
ssh <server> "sudo systemctl restart networking"

# Verify gateway reachable
ssh <server> "ping -c 3 192.168.10.1"
```

---

### Layer 2: DNS Resolution

**Symptoms:**
- Cannot resolve hostnames (e.g., `hx-dc-server.hx.dev.local`)
- `nslookup` or `dig` queries fail
- Services fail with "hostname not found" errors

**Diagnostic Steps:**

```bash
# 1. Test DNS resolution from problem server
ssh <server> "nslookup hx-dc-server.hx.dev.local 192.168.10.200"

# 2. Check DNS configuration
ssh <server> "cat /etc/resolv.conf"

# 3. Test direct query to DNS server
ssh <server> "dig @192.168.10.200 hx-webui-server.hx.dev.local"

# 4. Test reverse DNS
ssh <server> "dig -x 192.168.10.227 @192.168.10.200"

# 5. Check if DNS server (hx-dc-server) is responding
ping -c 3 192.168.10.200
nc -zv 192.168.10.200 53
```

**Common Causes:**
- DNS server (hx-dc-server) down
- Wrong nameserver in /etc/resolv.conf
- DNS service not running on hx-dc-server
- Network path to DNS server blocked

**Resolution:**

```bash
# Fix /etc/resolv.conf
ssh <server> "sudo bash -c 'cat > /etc/resolv.conf << EOF
search hx.dev.local
nameserver 192.168.10.200
nameserver 192.168.10.1
options timeout:2 attempts:3
EOF'"

# Restart DNS resolution service
ssh <server> "sudo systemctl restart systemd-resolved"

# If DNS server is down, restart Samba DC on hx-dc-server
ssh hx-dc-server "sudo systemctl restart samba-ad-dc"
```

---

### Layer 3: Kerberos Authentication

**Symptoms:**
- Authentication failures
- "Clock skew too great" errors
- Cannot obtain Kerberos tickets
- SSO not working for applications

**Diagnostic Steps:**

```bash
# 1. Check time synchronization (CRITICAL for Kerberos)
ssh <server> "timedatectl status"

# 2. Test Kerberos ticket acquisition
ssh <server> "kinit admin@HX.DEV.LOCAL"
ssh <server> "klist"

# 3. Check Kerberos configuration
ssh <server> "cat /etc/krb5.conf"

# 4. Test KDC reachability
nc -zv hx-dc-server.hx.dev.local 88

# 5. Check service principals
ssh <server> "kvno HTTP/hx-webui-server.hx.dev.local@HX.DEV.LOCAL"

# 6. Verify time difference with DC
ssh <server> "date" && ssh hx-dc-server "date"
```

**Common Causes:**
- Time skew between server and DC (>5 minutes)
- KDC (hx-dc-server) unreachable
- Wrong realm configuration
- Missing or expired service principals
- NTP not configured

**Resolution:**

```bash
# Synchronize time with DC
ssh <server> "sudo ntpdate -u hx-dc-server.hx.dev.local"

# Configure NTP properly
ssh <server> "sudo bash -c 'cat > /etc/systemd/timesyncd.conf << EOF
[Time]
NTP=hx-dc-server.hx.dev.local 192.168.10.1
FallbackNTP=pool.ntp.org
EOF'"

ssh <server> "sudo systemctl restart systemd-timesyncd"
ssh <server> "sudo timedatectl set-ntp true"

# Verify time is now synchronized
ssh <server> "timedatectl status"

# Test Kerberos again
ssh <server> "kinit admin@HX.DEV.LOCAL"
```

---

### Layer 4: Port Connectivity

**Symptoms:**
- "Connection refused" errors
- Timeouts when connecting to services
- Specific services unreachable

**Diagnostic Steps:**

```bash
# 1. Check if port is open and listening
ssh <server> "sudo ss -tlnp | grep <port>"
ssh <server> "sudo netstat -tlnp | grep <port>"

# 2. Test connectivity from another server
nc -zv <target-server> <port>
telnet <target-server> <port>

# 3. Check firewall rules
ssh <server> "sudo iptables -L -n -v"
ssh <server> "sudo ufw status verbose"

# 4. Scan multiple ports
nmap -p 5432,6379,6333,11434 <target-server>

# 5. Check process binding
ssh <server> "sudo lsof -i :<port>"
```

**Common Service Ports:**
```
DNS:        53    (hx-dc-server)
Kerberos:   88    (hx-dc-server)
LDAP:       389, 636 (hx-dc-server)
HTTPS:      443   (hx-ssl-server)
PostgreSQL: 5432  (hx-postgres-server)
Redis:      6379  (hx-redis-server)
Redis UI:   8001  (hx-redis-server)
Qdrant:     6333, 6334 (hx-qdrant-server)
Qdrant UI:  3000  (hx-qdrant-ui-server)
Ollama:     11434 (hx-ollama1/2/3-server)
LiteLLM:    4000  (hx-litellm-server)
FastMCP:    8000  (hx-fastmcp-server)
n8n:        5678  (hx-n8n-server)
Open WebUI: 3000  (hx-webui-server)
```

**Common Causes:**
- Service not running
- Service listening on wrong interface (127.0.0.1 instead of 0.0.0.0)
- Firewall blocking port
- Port already in use by another process
- Service crashed

**Resolution:**

```bash
# Start service if not running
ssh <server> "sudo systemctl start <service>"
ssh <server> "sudo systemctl status <service>"

# Check service is listening on correct interface
ssh <server> "sudo ss -tlnp | grep <port>"
# Should show 0.0.0.0:<port> or :::<port>, NOT 127.0.0.1:<port>

# If firewall issue, allow port
ssh <server> "sudo ufw allow <port>/tcp"

# If port conflict, identify and stop conflicting process
ssh <server> "sudo lsof -i :<port>"
ssh <server> "sudo kill <pid>"

# Restart service
ssh <server> "sudo systemctl restart <service>"
```

---

### Layer 5: TLS/SSL Issues

**Symptoms:**
- Certificate errors in browsers
- "Certificate has expired" warnings
- "Certificate not trusted" errors
- HTTPS connections fail

**Diagnostic Steps:**

```bash
# 1. Check certificate details
echo | openssl s_client -connect <server>:443 -showcerts 2>/dev/null | \
  openssl x509 -noout -text

# 2. Check certificate expiration
echo | openssl s_client -connect <server>:443 2>/dev/null | \
  openssl x509 -noout -dates

# 3. Verify certificate chain
openssl s_client -connect <server>:443 -CAfile /path/to/ca.crt

# 4. Check certificate on server
ssh <server> "sudo openssl x509 -in /etc/ssl/hx/<cert>.crt -noout -text"

# 5. Verify CA certificate trust
ssh <server> "ls -la /usr/local/share/ca-certificates/"
ssh <server> "sudo update-ca-certificates --verbose"
```

**Common Causes:**
- Certificate expired
- Certificate not issued by trusted CA (hx-ca-server)
- Certificate for wrong hostname
- CA certificate not installed in trust store
- Certificate chain incomplete

**Resolution:**

```bash
# Request new certificate from hx-ca-server
ssh hx-ca-server "cd /var/ca && sudo ./issue-cert.sh <server-fqdn>"

# Install certificate on target server
scp hx-ca-server:/var/ca/certs/<server>.crt <server>:/tmp/
ssh <server> "sudo mv /tmp/<server>.crt /etc/ssl/hx/"

# Install CA certificate if not trusted
scp hx-ca-server:/var/ca/certs/ca.crt <server>:/tmp/
ssh <server> "sudo cp /tmp/ca.crt /usr/local/share/ca-certificates/hx-ca.crt"
ssh <server> "sudo update-ca-certificates"

# Restart service to pick up new certificate
ssh <server> "sudo systemctl restart <service>"
```

---

## Common Network Issues

### Issue 1: Server Cannot Reach Gateway

**Symptoms:**
```bash
$ ping 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
From 192.168.10.XXX icmp_seq=1 Destination Host Unreachable
```

**Diagnostic:**
```bash
# Check routing table
ip route show

# Check default gateway configuration
cat /etc/network/interfaces
# OR
cat /etc/netplan/*.yaml
```

**Expected Output:**
```
default via 192.168.10.1 dev eth0
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.XXX
```

**Resolution:**
```bash
# Add default route if missing
sudo ip route add default via 192.168.10.1

# Make permanent in /etc/network/interfaces
sudo bash -c 'cat >> /etc/network/interfaces << EOF

auto eth0
iface eth0 inet static
    address 192.168.10.XXX
    netmask 255.255.255.0
    gateway 192.168.10.1
    dns-nameservers 192.168.10.200 192.168.10.1
EOF'

# Restart networking
sudo systemctl restart networking
```

---

### Issue 2: Domain Controller (hx-dc-server) Down

**Symptoms:**
- Cannot resolve any *.hx.dev.local hostnames
- Kerberos authentication fails across all servers
- All domain-joined servers affected

**Diagnostic:**
```bash
# Test DC reachability
ping -c 3 192.168.10.200

# Test DNS service
nc -zv 192.168.10.200 53

# Test Kerberos service
nc -zv 192.168.10.200 88

# Test LDAP service
nc -zv 192.168.10.200 389
```

**Resolution:**
```bash
# SSH to DC server
ssh hx-dc-server.hx.dev.local  # Use IP if DNS down: ssh 192.168.10.200

# Check Samba AD DC status
sudo systemctl status samba-ad-dc

# Check service logs
sudo journalctl -u samba-ad-dc -n 100 --no-pager

# Restart Samba AD DC if stopped
sudo systemctl restart samba-ad-dc

# Verify services are listening
sudo ss -tlnp | grep -E '(53|88|389)'

# Test DNS after restart
nslookup hx-dc-server.hx.dev.local 192.168.10.200
```

**If DC Cannot Start:**
```bash
# Check disk space
df -h

# Check Samba configuration
sudo samba-tool domain level show

# Check for database issues
sudo samba-tool dbcheck

# Restore from backup if needed (see disaster recovery procedures)
```

---

### Issue 3: Service Cannot Connect to Database

**Symptoms:**
- Application errors: "could not connect to server"
- PostgreSQL connection timeouts
- Services cannot persist data

**Diagnostic:**
```bash
# Test PostgreSQL connectivity
nc -zv hx-postgres-server.hx.dev.local 5432

# Test from service server
ssh <service-server> "psql -h hx-postgres-server.hx.dev.local -U <user> -d <database> -c 'SELECT 1;'"

# Check PostgreSQL is running
ssh hx-postgres-server "sudo systemctl status postgresql"

# Check PostgreSQL listening
ssh hx-postgres-server "sudo ss -tlnp | grep 5432"

# Check PostgreSQL logs
ssh hx-postgres-server "sudo tail -50 /var/log/postgresql/postgresql-*.log"

# Check pg_hba.conf for access rules
ssh hx-postgres-server "sudo cat /etc/postgresql/*/main/pg_hba.conf | grep -v '^#' | grep -v '^$'"
```

**Common Causes:**
- PostgreSQL not running
- Listening only on 127.0.0.1 (not 0.0.0.0)
- pg_hba.conf not allowing connections from service server
- Wrong credentials
- Database does not exist

**Resolution:**
```bash
# Ensure PostgreSQL listening on all interfaces
ssh hx-postgres-server "sudo sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '*'/\" /etc/postgresql/*/main/postgresql.conf"

# Add access rule to pg_hba.conf
ssh hx-postgres-server "sudo bash -c 'echo \"host    all    all    192.168.10.0/24    md5\" >> /etc/postgresql/*/main/pg_hba.conf'"

# Restart PostgreSQL
ssh hx-postgres-server "sudo systemctl restart postgresql"

# Verify listening
ssh hx-postgres-server "sudo ss -tlnp | grep 5432"
# Should show: 0.0.0.0:5432 or :::5432

# Test connection again
ssh <service-server> "psql -h hx-postgres-server.hx.dev.local -U <user> -d <database> -c 'SELECT 1;'"
```

---

### Issue 4: MCP Gateway Not Routing to Services

**Symptoms:**
- MCP tools not available in applications
- FastMCP returns errors when calling downstream services
- Tool execution fails

**Diagnostic:**
```bash
# Check FastMCP server status
ssh hx-fastmcp-server "sudo systemctl status fastmcp"

# Check FastMCP logs
ssh hx-fastmcp-server "sudo journalctl -u fastmcp -n 50 --no-pager"

# Test FastMCP endpoint
curl -v http://hx-fastmcp-server.hx.dev.local:8000/health

# Check downstream MCP services
for service in hx-qmcp-server hx-crawl4ai-mcp-server hx-n8n-mcp-server; do
  echo "Testing $service..."
  nc -zv $service 8000 || echo "$service unreachable"
done

# Check FastMCP configuration
ssh hx-fastmcp-server "cat /etc/fastmcp/config.yml"
```

**Resolution:**
```bash
# Restart FastMCP
ssh hx-fastmcp-server "sudo systemctl restart fastmcp"

# Verify downstream services are operational
ssh hx-qmcp-server "sudo systemctl status qmcp"
ssh hx-crawl4ai-mcp-server "sudo systemctl status crawl4ai-mcp"
ssh hx-n8n-mcp-server "sudo systemctl status n8n-mcp"

# Check FastMCP can reach backends
ssh hx-fastmcp-server "nc -zv hx-qmcp-server 8000"

# Update FastMCP configuration if needed
ssh hx-fastmcp-server "sudo nano /etc/fastmcp/config.yml"
ssh hx-fastmcp-server "sudo systemctl restart fastmcp"
```

---

## Service-Specific Issues

### Open WebUI (hx-webui-server) Issues

**Common Problems:**

1. **Cannot access via HTTPS**
```bash
# Check reverse proxy (hx-ssl-server) configuration
ssh hx-ssl-server "sudo nginx -t"
ssh hx-ssl-server "sudo systemctl status nginx"

# Check Open WebUI is running
ssh hx-webui-server "sudo systemctl status openwebui"

# Check logs
ssh hx-webui-server "sudo journalctl -u openwebui -n 50"
```

2. **LLM responses not working**
```bash
# Verify LiteLLM connection
ssh hx-webui-server "curl http://hx-litellm-server.hx.dev.local:4000/health"

# Check Open WebUI configuration
ssh hx-webui-server "cat /etc/openwebui/config.env | grep LITELLM"

# Test Ollama servers directly
curl http://hx-ollama1-server.hx.dev.local:11434/api/tags
```

3. **Authentication fails**
```bash
# Check Kerberos configuration
ssh hx-webui-server "klist"
ssh hx-webui-server "kinit admin@HX.DEV.LOCAL"

# Check DC connectivity
nc -zv hx-dc-server.hx.dev.local 88
nc -zv hx-dc-server.hx.dev.local 389
```

---

### LiteLLM API Gateway Issues

**Common Problems:**

1. **Models not loading**
```bash
# Check LiteLLM configuration
ssh hx-litellm-server "cat /etc/litellm/config.yaml"

# Verify Ollama servers reachable
for i in 1 2 3; do
  curl http://hx-ollama${i}-server.hx.dev.local:11434/api/tags
done

# Restart LiteLLM
ssh hx-litellm-server "sudo systemctl restart litellm"

# Check logs
ssh hx-litellm-server "sudo tail -100 /var/log/litellm/litellm.log"
```

2. **API requests failing**
```bash
# Test LiteLLM health endpoint
curl http://hx-litellm-server.hx.dev.local:4000/health

# Test model list
curl http://hx-litellm-server.hx.dev.local:4000/models

# Check if service is listening
ssh hx-litellm-server "sudo ss -tlnp | grep 4000"
```

---

### Qdrant Vector Database Issues

**Common Problems:**

1. **Vector search not working**
```bash
# Check Qdrant server status
ssh hx-qdrant-server "sudo systemctl status qdrant"

# Test Qdrant API
curl http://hx-qdrant-server.hx.dev.local:6333/collections

# Check Qdrant logs
ssh hx-qdrant-server "sudo journalctl -u qdrant -n 50"

# Verify collections exist
curl http://hx-qdrant-server.hx.dev.local:6333/collections | jq
```

2. **QMCP server cannot connect**
```bash
# Check QMCP server status
ssh hx-qmcp-server "sudo systemctl status qmcp"

# Test connection to Qdrant
ssh hx-qmcp-server "curl http://hx-qdrant-server.hx.dev.local:6333/collections"

# Check QMCP configuration
ssh hx-qmcp-server "cat /etc/qmcp/config.yml"
```

---

## Emergency Procedures

### Emergency 1: Complete Network Outage

**If all servers unreachable:**

1. **Access control node directly** (console access or direct connection)
2. **Check network infrastructure:**
   ```bash
   ping 192.168.10.1  # Gateway
   ip link show       # Interface status
   ip route show      # Routing table
   ```
3. **Check switch/router** (physical infrastructure)
4. **Restart networking:**
   ```bash
   sudo systemctl restart networking
   ```
5. **Run full health check** once connectivity restored

---

### Emergency 2: Domain Controller Failure

**Critical - Affects all authentication:**

1. **Attempt to restart Samba AD DC:**
   ```bash
   ssh 192.168.10.200  # Use IP, DNS will be down
   sudo systemctl restart samba-ad-dc
   ```

2. **If restart fails, check disk space:**
   ```bash
   df -h
   # If disk full, clean up /var/log or other temporary files
   ```

3. **If database corruption:**
   ```bash
   sudo samba-tool dbcheck --fix
   ```

4. **Last resort - restore from backup:**
   ```bash
   # Stop Samba
   sudo systemctl stop samba-ad-dc
   
   # Restore from backup
   sudo tar -xzf /backup/samba-ad-dc-YYYY-MM-DD.tar.gz -C /
   
   # Start Samba
   sudo systemctl start samba-ad-dc
   ```

---

### Emergency 3: Certificate Authority Failure

**Affects all TLS services:**

1. **Check hx-ca-server status:**
   ```bash
   ssh hx-ca-server
   sudo systemctl status <ca-service>  # Whatever CA software is running
   ```

2. **Verify CA files intact:**
   ```bash
   ls -la /var/ca/private/ca.key
   ls -la /var/ca/certs/ca.crt
   ```

3. **If CA files corrupted, restore from backup:**
   ```bash
   sudo tar -xzf /backup/ca-YYYY-MM-DD.tar.gz -C /var/ca/
   ```

4. **Services may need certificate refresh** after CA restoration

---

## Diagnostic Tools Reference

### Essential Network Commands

```bash
# Connectivity testing
ping <host>                    # ICMP reachability
traceroute <host>              # Route tracing
mtr <host>                     # Combined ping/traceroute

# Port testing
nc -zv <host> <port>           # Test single port
nmap -p <ports> <host>         # Scan multiple ports
telnet <host> <port>           # Interactive port test

# DNS testing
nslookup <host> <dns-server>   # DNS lookup
dig @<dns-server> <host>       # Detailed DNS query
host <host>                    # Simple DNS lookup

# Interface/routing
ip addr show                   # Show IP addresses
ip link show                   # Show interfaces
ip route show                  # Show routing table
ss -tlnp                       # Show listening ports
netstat -tlnp                  # Alternative to ss

# TLS/SSL testing
openssl s_client -connect <host>:443  # Test TLS connection
openssl x509 -text -in <cert>         # Examine certificate

# Kerberos testing
kinit <principal>              # Get Kerberos ticket
klist                          # List tickets
kvno <service-principal>       # Test service principal
```

### Service Status Commands

```bash
# Systemd services
sudo systemctl status <service>        # Check status
sudo systemctl restart <service>       # Restart
sudo journalctl -u <service> -n 50    # View logs

# Process management
ps aux | grep <service>                # Find process
sudo lsof -i :<port>                   # See what's using port
sudo kill <pid>                        # Stop process

# Log viewing
sudo tail -f /var/log/<service>.log   # Follow logs
sudo journalctl -f                     # Follow all logs
sudo dmesg | tail -50                  # Kernel messages
```

---

## Escalation Path

When troubleshooting fails to resolve an issue:

1. **Document the issue thoroughly:**
   - Exact symptoms
   - Steps taken
   - Error messages (exact text)
   - Results of diagnostic commands

2. **Create defect report:**
   - Use `templates/defect-template.md`
   - Severity: critical (infrastructure down) to low (cosmetic)

3. **Escalate to infrastructure team:**
   - Include all documentation
   - Include output from network-health-check.sh
   - Provide timeline of issue

4. **For emergency outages:**
   - Immediately notify team
   - Begin emergency procedures
   - Document all actions taken

---

## Document Maintenance

**Update Triggers:**
- New common issues discovered
- New services deployed
- Network topology changes
- New diagnostic tools added

**Related Scripts:**
- `procedures/network-health-check.sh` - Automated diagnostic script

**Version**: 1.0  
**Last Updated**: 2025-11-15  
**Maintained By**: HX-Infrastructure Team

---

*This troubleshooting guide provides systematic approaches to diagnosing and resolving network issues. Always document your findings and update procedures based on lessons learned.*
