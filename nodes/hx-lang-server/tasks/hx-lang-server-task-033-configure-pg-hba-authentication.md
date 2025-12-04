# Task: Configure pg_hba.conf for hx-lang-server Access

**Task ID**: hx-lang-server-task-033-configure-pg-hba-authentication
**Phase**: Installation (Work Stream 4: PostgreSQL Integration)
**Assigned To**: Trinity (PostgreSQL DBA)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-032 (user creation)
**Estimated Time**: 15 minutes

---

## Objective

Configure PostgreSQL host-based authentication (pg_hba.conf) to allow hx-lang-server.hx.dev.local (192.168.10.226) to connect to the hx_lang_server database using SCRAM-SHA-256 authentication. This ensures secure authentication while maintaining internal network trust model.

---

## Prerequisites

- [ ] PostgreSQL user `hx_lang_server` exists (task-032 complete)
- [ ] Database `hx_lang_server` exists (task-031 complete)
- [ ] hx-lang-server.hx.dev.local has IP address 192.168.10.226
- [ ] PostgreSQL server configuration file accessible at `/etc/postgresql/16/main/pg_hba.conf`
- [ ] Root or sudo access to hx-postgres-server.hx.dev.local

---

## Steps

### 1. Backup Current pg_hba.conf

```bash
# SSH to hx-postgres-server.hx.dev.local
ssh root@hx-postgres-server.hx.dev.local

# Backup current configuration
sudo cp /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf.backup-$(date +%Y%m%d-%H%M%S)

# Verify backup created
ls -lh /etc/postgresql/16/main/pg_hba.conf.backup-*
```

### 2. Add hx-lang-server Access Rule

```bash
# Add entry for hx-lang-server access
sudo tee -a /etc/postgresql/16/main/pg_hba.conf <<EOF

# hx-lang-server access (added $(date +%Y-%m-%d))
# Allow hx-lang-server.hx.dev.local to connect to hx_lang_server database
host    hx_lang_server    hx_lang_server    192.168.10.226/32    scram-sha-256
EOF
```

**Entry Explanation**:
- `host`: TCP/IP connection (not local socket)
- `hx_lang_server`: Database name (first column)
- `hx_lang_server`: Username (second column)
- `192.168.10.226/32`: hx-lang-server.hx.dev.local IP address (single host)
- `scram-sha-256`: Strongest password authentication available in PostgreSQL 16

### 3. Verify pg_hba.conf Syntax

```bash
# Check for syntax errors (PostgreSQL provides no built-in validator, manual review required)
sudo tail -5 /etc/postgresql/16/main/pg_hba.conf

# Expected output should show new entry with correct formatting
```

### 4. Reload PostgreSQL Configuration

```bash
# Reload configuration without restarting server (connections preserved)
sudo systemctl reload postgresql@16-main

# Verify reload succeeded
sudo systemctl status postgresql@16-main | grep "active (running)"

# Check PostgreSQL logs for configuration reload
sudo tail -20 /var/log/postgresql/postgresql-16-main.log | grep -i "received sighup"
```

Expected log output:
```
2025-12-04 12:34:56 UTC [12345]: [1-1] LOG:  received SIGHUP, reloading configuration files
2025-12-04 12:34:56 UTC [12345]: [2-1] LOG:  parameter "password_encryption" changed to "scram-sha-256"
```

### 5. Test Connection from hx-lang-server

```bash
# SSH to hx-lang-server.hx.dev.local
ssh hx-lang-server@hx-lang-server.hx.dev.local

# Test connection with password authentication
# Replace ${PASSWORD} with actual password from Ansible Vault
export PGPASSWORD="${PASSWORD}"
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c "SELECT current_user, inet_server_addr(), inet_server_port();"

# Expected output:
#   current_user   | inet_server_addr | inet_server_port
# -----------------+------------------+------------------
#  hx_lang_server  | 192.168.10.XXX   | 5432

unset PGPASSWORD
```

### 6. Test Connection Denial from Other Hosts

```bash
# Attempt connection from different host (should fail)
# Example: from hx-dev-server.hx.dev.local (192.168.10.222)
ssh root@hx-dev-server.hx.dev.local
export PGPASSWORD="${PASSWORD}"
psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c "SELECT 1;"

# Expected error:
# psql: error: connection to server at "hx-postgres-server.hx.dev.local" (192.168.10.XXX), port 5432 failed: FATAL:  no pg_hba.conf entry for host "192.168.10.222", user "hx_lang_server", database "hx_lang_server", SSL off

unset PGPASSWORD
```

---

## Deliverables

- [ ] pg_hba.conf backup created with timestamp
- [ ] New entry added for hx-lang-server access (192.168.10.226/32)
- [ ] SCRAM-SHA-256 authentication method configured
- [ ] PostgreSQL configuration reloaded without restart
- [ ] Connection test succeeds from hx-lang-server.hx.dev.local
- [ ] Connection test fails from unauthorized hosts (security verification)

---

## Verification

```bash
# Comprehensive verification script
ssh root@hx-postgres-server.hx.dev.local

# 1. Verify pg_hba.conf entry exists
echo "=== pg_hba.conf Entry ==="
sudo grep "hx-lang-server" /etc/postgresql/16/main/pg_hba.conf

# 2. Verify PostgreSQL is running
echo "=== PostgreSQL Status ==="
sudo systemctl is-active postgresql@16-main

# 3. Verify connection from hx-lang-server works
echo "=== Connection Test ==="
ssh hx-lang-server@hx-lang-server.hx.dev.local "export PGPASSWORD='${PASSWORD}'; psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c 'SELECT current_user, inet_client_addr();'"

# 4. Check authentication method in logs
echo "=== Authentication Logs ==="
sudo tail -50 /var/log/postgresql/postgresql-16-main.log | grep "hx_lang_server" | grep -E "authentication|connection"
```

**Pass Criteria**:
- [ ] pg_hba.conf contains entry: `host hx_lang_server hx_lang_server 192.168.10.226/32 scram-sha-256`
- [ ] PostgreSQL status is `active (running)`
- [ ] Connection from hx-lang-server.hx.dev.local succeeds with SCRAM-SHA-256
- [ ] Connection from other hosts fails with "no pg_hba.conf entry" error
- [ ] PostgreSQL logs show successful authentication for hx_lang_server user

---

## Rollback

```bash
# SSH to hx-postgres-server.hx.dev.local
ssh root@hx-postgres-server.hx.dev.local

# Restore original pg_hba.conf from backup
LATEST_BACKUP=$(ls -t /etc/postgresql/16/main/pg_hba.conf.backup-* | head -1)
sudo cp "${LATEST_BACKUP}" /etc/postgresql/16/main/pg_hba.conf

# Reload configuration
sudo systemctl reload postgresql@16-main

# Verify rollback
sudo tail -10 /etc/postgresql/16/main/pg_hba.conf
sudo systemctl status postgresql@16-main
```

---

## Notes

- **Authentication Method**: SCRAM-SHA-256 is the strongest password authentication available in PostgreSQL 16 (stronger than MD5, stronger than SCRAM-SHA-1)
- **IP Address Restriction**: /32 suffix restricts access to single IP (192.168.10.226 only)
- **No SSL Required**: Development environment, internal network trust model (no firewall, trusted 192.168.10.0/24 network)
- **Order Matters**: pg_hba.conf is processed top-to-bottom; first matching entry wins. Our entry should be after any more specific rules but before generic "reject all" rules
- **Reload vs Restart**: `systemctl reload` preserves existing connections, only new connections use new rules. `systemctl restart` would disconnect all clients
- **Connection Pooling**: Not applicable (pgBouncer not in use per CAIO decision); direct PostgreSQL connections

---

## Security Considerations

- ✅ **Least Privilege Network Access**: Only hx-lang-server.hx.dev.local can connect (192.168.10.226/32)
- ✅ **Strong Authentication**: SCRAM-SHA-256 prevents password sniffing and replay attacks
- ✅ **User-Database Binding**: hx_lang_server user can only access hx_lang_server database
- ✅ **No Trust Authentication**: Never use `trust` method for network connections (only local socket if required)
- ✅ **Audit Trail**: All connection attempts logged in PostgreSQL logs
- ⚠️ **No SSL/TLS**: Acceptable for development environment internal network only

---

## Related Tasks

- **Depends On**: hx-lang-server-task-032 (user creation)
- **Prerequisite For**: hx-lang-server-task-035 (connection testing)
- **Related**: hx-lang-server-task-031 (database creation)

---

**Created By**: Trinity (PostgreSQL DBA)
**Date**: 2025-12-04
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration"
