# Task 034: Configure Logging

**Task ID**: hx-docling-mcp-task-034
**Category**: Configuration / Logging & Monitoring
**Assigned To**: william-chen (Infrastructure Specialist)
**Status**: PENDING
**Priority**: HIGH (Operational requirement)
**Created**: 2025-11-27
**Estimated Effort**: 1 hour

---

## Task Description

Configure comprehensive logging for Docling MCP Server including application logs, error logs, access logs, systemd journal integration, log rotation, and log aggregation. Implement structured JSON logging for machine-readable log analysis and monitoring integration.

---

## Prerequisites

- [ ] Task 002 complete (Samba AD service account created)
- [ ] Task 003 complete (System dependencies installed)
- [ ] Task 006 complete (Directory structure created: `/var/log/docling-mcp`)
- [ ] Task 008 complete (Environment files configured with LOG_* variables)
- [ ] Task 033 complete (Systemd service configured with StandardOutput/StandardError)
- [ ] `rsyslog` or `systemd-journald` operational for log management

---

## Acceptance Criteria

- [ ] Python logging configuration file created (`/etc/docling-mcp/logging.conf`)
- [ ] Log rotation configured via logrotate (`/etc/logrotate.d/docling-mcp`)
- [ ] Application log directory writable by service account
- [ ] Systemd journal integration verified
- [ ] Log formats configured (JSON structured logging)
- [ ] Log levels configured per module
- [ ] Log rotation tested and functional
- [ ] Log monitoring script created
- [ ] Logging documentation generated

---

## Detailed Procedure

### Step 1: Create Python Logging Configuration

**Create structured logging configuration for Python application**:

```bash
# Connect to hx-docling-mcp-server
ssh administrator@192.168.10.217

# Create Python logging configuration file
sudo tee /etc/docling-mcp/logging.conf > /dev/null <<'EOF'
[loggers]
keys=root,docling_mcp,fastmcp,docling,lightrag,uvicorn

[handlers]
keys=consoleHandler,fileHandler,errorHandler,accessHandler

[formatters]
keys=jsonFormatter,simpleFormatter

# ===== Loggers =====
[logger_root]
level=INFO
handlers=consoleHandler,fileHandler,errorHandler

[logger_docling_mcp]
level=INFO
handlers=consoleHandler,fileHandler,errorHandler
qualname=docling_mcp
propagate=0

[logger_fastmcp]
level=INFO
handlers=consoleHandler,fileHandler
qualname=fastmcp
propagate=0

[logger_docling]
level=INFO
handlers=consoleHandler,fileHandler
qualname=docling
propagate=0

[logger_lightrag]
level=INFO
handlers=consoleHandler,fileHandler
qualname=lightrag
propagate=0

[logger_uvicorn]
level=INFO
handlers=consoleHandler,accessHandler
qualname=uvicorn
propagate=0

# ===== Handlers =====
[handler_consoleHandler]
class=StreamHandler
level=INFO
formatter=jsonFormatter
args=(sys.stdout,)

[handler_fileHandler]
class=logging.handlers.RotatingFileHandler
level=INFO
formatter=jsonFormatter
args=('/var/log/docling-mcp/docling-mcp.log', 'a', 10485760, 30, 'utf-8')

[handler_errorHandler]
class=logging.handlers.RotatingFileHandler
level=ERROR
formatter=jsonFormatter
args=('/var/log/docling-mcp/error.log', 'a', 10485760, 30, 'utf-8')

[handler_accessHandler]
class=logging.handlers.RotatingFileHandler
level=INFO
formatter=jsonFormatter
args=('/var/log/docling-mcp/access.log', 'a', 10485760, 30, 'utf-8')

# ===== Formatters =====
[formatter_jsonFormatter]
class=pythonjsonlogger.jsonlogger.JsonFormatter
format=%(asctime)s %(name)s %(levelname)s %(message)s %(pathname)s %(lineno)d %(funcName)s

[formatter_simpleFormatter]
format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
datefmt=%Y-%m-%d %H:%M:%S
EOF

# Set ownership
sudo chown root:domain\ users@hx.dev.local /etc/docling-mcp/logging.conf

# Set permissions (640 - owner read/write, group read)
sudo chmod 640 /etc/docling-mcp/logging.conf

# Verify file created
cat /etc/docling-mcp/logging.conf
```

### Step 2: Create Logrotate Configuration

**Configure automatic log rotation to prevent disk space exhaustion**:

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/docling-mcp > /dev/null <<'EOF'
# Logrotate configuration for Docling MCP Server
# Rotate logs daily, keep 30 days of logs

/var/log/docling-mcp/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 docling-mcp@hx.dev.local domain\ users@hx.dev.local
    sharedscripts
    postrotate
        # Send SIGHUP to application to reopen log files
        systemctl reload docling-mcp.service > /dev/null 2>&1 || true
    endscript
}

# Error log - more aggressive rotation (larger file size threshold)
/var/log/docling-mcp/error.log {
    size 50M
    rotate 10
    compress
    delaycompress
    notifempty
    missingok
    create 0644 docling-mcp@hx.dev.local domain\ users@hx.dev.local
    postrotate
        systemctl reload docling-mcp.service > /dev/null 2>&1 || true
    endscript
}
EOF

# Set ownership
sudo chown root:root /etc/logrotate.d/docling-mcp

# Set permissions (644 - world readable)
sudo chmod 644 /etc/logrotate.d/docling-mcp

# Verify logrotate configuration syntax
sudo logrotate -d /etc/logrotate.d/docling-mcp
# Expected: No syntax errors
```

### Step 3: Create Log Directory Structure

**Ensure log directories exist with proper permissions**:

```bash
# Verify log directory exists (should be created in Task 006)
ls -la /var/log/docling-mcp

# Create archived subdirectory for rotated logs
sudo mkdir -p /var/log/docling-mcp/archived

# Set ownership on log directory
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/log/docling-mcp

# Set permissions
sudo chmod 755 /var/log/docling-mcp
sudo chmod 755 /var/log/docling-mcp/archived

# Create empty log files with proper ownership
sudo touch /var/log/docling-mcp/docling-mcp.log
sudo touch /var/log/docling-mcp/error.log
sudo touch /var/log/docling-mcp/access.log

# Set ownership on log files
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/log/docling-mcp/*.log

# Set permissions on log files (644 - owner read/write, group/world read)
sudo chmod 644 /var/log/docling-mcp/*.log

# Verify log files created
ls -la /var/log/docling-mcp/
# Expected: docling-mcp.log, error.log, access.log with service account ownership
```

### Step 4: Configure systemd Journal Integration

**Ensure systemd service logs to journal correctly**:

```bash
# Verify systemd service unit has logging directives
sudo cat /etc/systemd/system/docling-mcp.service | grep -A 2 "Standard"

# Expected output:
# StandardOutput=journal
# StandardError=journal

# If not present, add to systemd service unit (Task 033 should have configured this)
# StandardOutput=journal
# StandardError=journal

# Reload systemd daemon if changes made
sudo systemctl daemon-reload

# Test journal logging
sudo journalctl -u docling-mcp.service -n 10
# Expected: Recent log entries (if service has run)
```

### Step 5: Create Log Monitoring Script

**Create script to monitor log files for errors and issues**:

```bash
# Create log monitoring script
sudo tee /opt/docling-mcp/scripts/monitor-logs.sh > /dev/null <<'EOF'
#!/bin/bash
# Log Monitoring Script for Docling MCP Server
# Monitors logs for errors, warnings, and anomalies

set -e

LOG_DIR="/var/log/docling-mcp"
ERROR_LOG="$LOG_DIR/error.log"
APP_LOG="$LOG_DIR/docling-mcp.log"
ACCESS_LOG="$LOG_DIR/access.log"

echo "===== Docling MCP Server Log Monitoring ====="
echo "Monitoring Date: $(date)"
echo ""

# Function to count log entries
count_entries() {
    local log_file=$1
    local pattern=$2
    local description=$3

    if [ -f "$log_file" ]; then
        COUNT=$(grep -c "$pattern" "$log_file" 2>/dev/null || echo "0")
        echo "$description: $COUNT"
    else
        echo "$description: Log file not found"
    fi
}

# Check log file sizes
echo "===== Log File Sizes ====="
echo ""
du -h "$LOG_DIR"/*.log 2>/dev/null || echo "No log files found"

echo ""
echo "===== Error Log Analysis (Last 24 hours) ====="
echo ""

# Errors in last 24 hours
if [ -f "$ERROR_LOG" ]; then
    ERRORS_24H=$(find "$ERROR_LOG" -mtime -1 -exec wc -l {} \; 2>/dev/null | awk '{print $1}')
    echo "Total error entries (24h): ${ERRORS_24H:-0}"

    # Show last 10 errors
    echo ""
    echo "Last 10 errors:"
    tail -10 "$ERROR_LOG" 2>/dev/null || echo "No recent errors"
else
    echo "Error log file not found"
fi

echo ""
echo "===== Application Log Analysis ====="
echo ""

if [ -f "$APP_LOG" ]; then
    count_entries "$APP_LOG" "ERROR" "ERROR level entries"
    count_entries "$APP_LOG" "WARNING" "WARNING level entries"
    count_entries "$APP_LOG" "INFO" "INFO level entries"

    # Check for specific issues
    echo ""
    echo "Issue Detection:"
    count_entries "$APP_LOG" "ConnectionError" "Connection errors"
    count_entries "$APP_LOG" "Timeout" "Timeout events"
    count_entries "$APP_LOG" "Failed" "Failed operations"
    count_entries "$APP_LOG" "Exception" "Exceptions"
else
    echo "Application log file not found"
fi

echo ""
echo "===== Access Log Analysis ====="
echo ""

if [ -f "$ACCESS_LOG" ]; then
    count_entries "$ACCESS_LOG" "GET" "GET requests"
    count_entries "$ACCESS_LOG" "POST" "POST requests"
    count_entries "$ACCESS_LOG" "200" "200 OK responses"
    count_entries "$ACCESS_LOG" "500" "500 Internal Server errors"
    count_entries "$ACCESS_LOG" "404" "404 Not Found errors"
else
    echo "Access log file not found"
fi

echo ""
echo "===== Systemd Journal (Last 50 entries) ====="
echo ""
journalctl -u docling-mcp.service -n 50 --no-pager

echo ""
echo "===== Disk Space Check ====="
echo ""
df -h /var/log

echo ""
echo "===== Monitoring Complete ====="
EOF

# Make script executable
sudo chmod 755 /opt/docling-mcp/scripts/monitor-logs.sh

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/scripts/monitor-logs.sh

# Test monitoring script
sudo /opt/docling-mcp/scripts/monitor-logs.sh
```

### Step 6: Test Log Rotation

**Verify logrotate configuration works correctly**:

```bash
# Test logrotate in debug mode (dry run)
sudo logrotate -d -f /etc/logrotate.d/docling-mcp

# Expected: No errors, shows rotation plan

# Force rotation test (actually rotates logs)
sudo logrotate -f /etc/logrotate.d/docling-mcp

# Verify rotation occurred
ls -la /var/log/docling-mcp/
# Expected: Original logs plus .1.gz compressed rotated logs

# Check logrotate status
sudo cat /var/lib/logrotate/status | grep docling-mcp
# Expected: Shows last rotation date
```

### Step 7: Create Logging Validation Script

```bash
# Create validation script
sudo tee /opt/docling-mcp/scripts/validate-logging.sh > /dev/null <<'EOF'
#!/bin/bash
# Logging Configuration Validation Script

set -e

echo "===== Logging Configuration Validation ====="
echo ""

LOG_DIR="/var/log/docling-mcp"
LOG_CONFIG="/etc/docling-mcp/logging.conf"
LOGROTATE_CONFIG="/etc/logrotate.d/docling-mcp"

# Function to check file
check_file() {
    local file=$1
    local description=$2
    echo -n "Checking $description... "
    if [ -f "$file" ]; then
        echo "✓ EXISTS"
    else
        echo "✗ NOT FOUND"
        return 1
    fi
}

# Function to check directory
check_dir() {
    local dir=$1
    local description=$2
    echo -n "Checking $description... "
    if [ -d "$dir" ]; then
        echo "✓ EXISTS"
    else
        echo "✗ NOT FOUND"
        return 1
    fi
}

# Check configuration files
echo "===== Configuration Files ====="
echo ""
check_file "$LOG_CONFIG" "logging.conf"
check_file "$LOGROTATE_CONFIG" "logrotate config"

# Check log directory
echo ""
echo "===== Log Directories ====="
echo ""
check_dir "$LOG_DIR" "log directory"
check_dir "$LOG_DIR/archived" "archived directory"

# Check log files
echo ""
echo "===== Log Files ====="
echo ""
check_file "$LOG_DIR/docling-mcp.log" "main log"
check_file "$LOG_DIR/error.log" "error log"
check_file "$LOG_DIR/access.log" "access log"

# Check permissions
echo ""
echo "===== Permissions Check ====="
echo ""

# Log directory permissions
DIR_PERM=$(stat -c '%a' "$LOG_DIR")
echo -n "Log directory permissions... "
if [ "$DIR_PERM" = "755" ]; then
    echo "✓ CORRECT (755)"
else
    echo "⚠ WARNING: Expected 755, got $DIR_PERM"
fi

# Log file permissions
FILE_PERM=$(stat -c '%a' "$LOG_DIR/docling-mcp.log")
echo -n "Log file permissions... "
if [ "$FILE_PERM" = "644" ]; then
    echo "✓ CORRECT (644)"
else
    echo "⚠ WARNING: Expected 644, got $FILE_PERM"
fi

# Ownership check
echo ""
echo "===== Ownership Check ====="
echo ""
OWNER=$(stat -c '%U' "$LOG_DIR")
echo -n "Log directory owner... "
if [[ "$OWNER" == "docling-mcp@hx.dev.local" ]]; then
    echo "✓ CORRECT ($OWNER)"
else
    echo "✗ INCORRECT: Expected docling-mcp@hx.dev.local, got $OWNER"
fi

# Check logrotate syntax
echo ""
echo "===== Logrotate Syntax Check ====="
echo ""
if logrotate -d "$LOGROTATE_CONFIG" > /dev/null 2>&1; then
    echo "✓ Logrotate configuration valid"
else
    echo "✗ Logrotate configuration has errors"
fi

# Check disk space
echo ""
echo "===== Disk Space Check ====="
echo ""
AVAILABLE=$(df /var/log | tail -1 | awk '{print $4}')
if [ "$AVAILABLE" -gt 1048576 ]; then
    echo "✓ Adequate disk space (>1GB available)"
else
    echo "⚠ WARNING: Low disk space (<1GB available)"
fi

echo ""
echo "===== Validation Complete ====="
EOF

# Make script executable
sudo chmod 755 /opt/docling-mcp/scripts/validate-logging.sh

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/scripts/validate-logging.sh

# Run validation script
sudo /opt/docling-mcp/scripts/validate-logging.sh

# Verify script exit code
echo $?
# Expected: 0 (success)
```

### Step 8: Document Logging Configuration

```bash
# Create logging documentation
sudo tee /opt/docling-mcp/documentation/logging-config.txt > /dev/null <<EOF
Logging Configuration Documentation
====================================

Configuration Date: $(date)
Node: hx-docling-mcp-server (192.168.10.217)

Log Files:
---------
Main Application Log: /var/log/docling-mcp/docling-mcp.log
Error Log: /var/log/docling-mcp/error.log
Access Log: /var/log/docling-mcp/access.log
Systemd Journal: journalctl -u docling-mcp.service

Log Format:
----------
Format: JSON (structured logging)
Formatter: python-json-logger
Fields: timestamp, name, level, message, pathname, lineno, funcName

Log Levels:
----------
root: INFO
docling_mcp: INFO
fastmcp: INFO
docling: INFO
lightrag: INFO
uvicorn: INFO

Log Rotation:
------------
Frequency: Daily
Retention: 30 days
Compression: gzip
Max Size: 10MB per log file (50MB for error.log)
Archived Location: /var/log/docling-mcp/archived/

Logrotate Configuration:
-----------------------
Config File: /etc/logrotate.d/docling-mcp
Test Command: sudo logrotate -d /etc/logrotate.d/docling-mcp
Force Rotation: sudo logrotate -f /etc/logrotate.d/docling-mcp

Monitoring:
----------
Monitor Script: /opt/docling-mcp/scripts/monitor-logs.sh
Run: sudo /opt/docling-mcp/scripts/monitor-logs.sh
Checks: Error counts, warning counts, connection issues, disk space

Systemd Journal Integration:
---------------------------
View Logs: journalctl -u docling-mcp.service
Follow Logs: journalctl -u docling-mcp.service -f
Last 50 Entries: journalctl -u docling-mcp.service -n 50
Since Boot: journalctl -u docling-mcp.service -b

Troubleshooting:
---------------
Check Log File Ownership:
  ls -la /var/log/docling-mcp/

Check Log File Permissions:
  stat -c '%a' /var/log/docling-mcp/*.log

Test Log Writing:
  echo "Test entry" | sudo -u docling-mcp@hx.dev.local tee -a /var/log/docling-mcp/docling-mcp.log

Check Disk Space:
  df -h /var/log

View Recent Errors:
  tail -50 /var/log/docling-mcp/error.log

Configuration Last Updated: $(date)
Updated By: $(whoami)
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/documentation/logging-config.txt

# Display documentation
cat /opt/docling-mcp/documentation/logging-config.txt
```

---

## Validation

### Validation Commands

```bash
# 1. Verify logging configuration exists
test -f /etc/docling-mcp/logging.conf && echo "PASS: logging.conf exists" || echo "FAIL: logging.conf missing"

# 2. Verify logrotate configuration exists
test -f /etc/logrotate.d/docling-mcp && echo "PASS: logrotate config exists" || echo "FAIL: logrotate config missing"

# 3. Verify log directory writable by service account
sudo -u docling-mcp@hx.dev.local test -w /var/log/docling-mcp && echo "PASS: log directory writable" || echo "FAIL: log directory not writable"

# 4. Verify log files exist
test -f /var/log/docling-mcp/docling-mcp.log && test -f /var/log/docling-mcp/error.log && test -f /var/log/docling-mcp/access.log && echo "PASS: all log files exist" || echo "FAIL: log files missing"

# 5. Verify logrotate syntax
sudo logrotate -d /etc/logrotate.d/docling-mcp > /dev/null 2>&1 && echo "PASS: logrotate syntax valid" || echo "FAIL: logrotate syntax error"

# 6. Verify monitoring script exists
test -x /opt/docling-mcp/scripts/monitor-logs.sh && echo "PASS: monitoring script executable" || echo "FAIL: monitoring script missing"

# 7. Verify validation script exists
test -x /opt/docling-mcp/scripts/validate-logging.sh && echo "PASS: validation script executable" || echo "FAIL: validation script missing"

# 8. Run comprehensive logging validation
sudo /opt/docling-mcp/scripts/validate-logging.sh && echo "PASS: all logging checks passed" || echo "FAIL: validation failed"
```

### Success Criteria

- ✅ Python logging configuration created (`/etc/docling-mcp/logging.conf`)
- ✅ Logrotate configuration created (`/etc/logrotate.d/docling-mcp`)
- ✅ Log directory writable by service account
- ✅ All log files exist with proper ownership
- ✅ Log rotation tested and functional
- ✅ Systemd journal integration verified
- ✅ JSON structured logging configured
- ✅ Log monitoring script created and functional
- ✅ Validation script passes all checks
- ✅ Documentation generated

---

## Troubleshooting

### Issue: Permission Denied Writing Logs

**Symptom**: `PermissionError: [Errno 13] Permission denied: '/var/log/docling-mcp/docling-mcp.log'`

**Solution**:
```bash
# Fix ownership
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/log/docling-mcp

# Fix permissions
sudo chmod 755 /var/log/docling-mcp
sudo chmod 644 /var/log/docling-mcp/*.log

# Test writing
echo "Test entry" | sudo -u docling-mcp@hx.dev.local tee -a /var/log/docling-mcp/docling-mcp.log
```

### Issue: Logrotate Fails

**Symptom**: `error: <log file> does not exist -- won't try to dispose of it`

**Solution**:
```bash
# Create missing log files
sudo touch /var/log/docling-mcp/docling-mcp.log
sudo touch /var/log/docling-mcp/error.log
sudo touch /var/log/docling-mcp/access.log

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/log/docling-mcp/*.log

# Retry logrotate
sudo logrotate -f /etc/logrotate.d/docling-mcp
```

### Issue: Logs Not Appearing in Journal

**Symptom**: `journalctl -u docling-mcp.service` shows no logs

**Solution**:
```bash
# Verify systemd service unit has journal logging
sudo cat /etc/systemd/system/docling-mcp.service | grep StandardOutput

# Add if missing:
# StandardOutput=journal
# StandardError=journal

# Reload systemd
sudo systemctl daemon-reload

# Restart service
sudo systemctl restart docling-mcp.service

# Verify journal logging
journalctl -u docling-mcp.service -n 10
```

### Issue: Disk Space Full from Logs

**Symptom**: `/var/log` filesystem full

**Solution**:
```bash
# Check disk usage
du -sh /var/log/docling-mcp/*

# Force log rotation immediately
sudo logrotate -f /etc/logrotate.d/docling-mcp

# Manually compress old logs
sudo gzip /var/log/docling-mcp/*.log.*

# Clean old compressed logs (keep only 30 days)
find /var/log/docling-mcp -name "*.gz" -mtime +30 -delete

# Check disk space
df -h /var/log
```

---

## Rollback Procedure

**If logging configuration needs to be reset**:

```bash
# Remove logging configuration
sudo rm -f /etc/docling-mcp/logging.conf

# Remove logrotate configuration
sudo rm -f /etc/logrotate.d/docling-mcp

# Remove monitoring script
sudo rm -f /opt/docling-mcp/scripts/monitor-logs.sh

# Remove validation script
sudo rm -f /opt/docling-mcp/scripts/validate-logging.sh

# Remove documentation
sudo rm -f /opt/docling-mcp/documentation/logging-config.txt

# Optional: Clear log files (if needed)
# sudo rm -f /var/log/docling-mcp/*.log
# sudo rm -f /var/log/docling-mcp/*.log.*

# If needed, recreate from Step 1
```

---

## Dependencies

**Blocks**:
- Service operational readiness (logs required for troubleshooting)
- Monitoring implementation (logs required for monitoring)
- Operational promotion (logging is quality gate requirement)

**Depends On**:
- Task 002: Create Samba AD Service Account (log file ownership)
- Task 006: Create Directory Structure (`/var/log/docling-mcp`)
- Task 008: Configure Environment Files (LOG_* variables)
- Task 033: Configure Systemd Service (StandardOutput/StandardError directives)

---

## Notes

### Logging Best Practices

**Structured Logging (JSON)**:
- Machine-readable format for log aggregation
- Easy parsing for monitoring and alerting
- Consistent field structure across all log entries
- Supports complex data types

**Log Levels**:
- **DEBUG**: Detailed diagnostic information (not enabled by default)
- **INFO**: General informational messages
- **WARNING**: Warning messages for potential issues
- **ERROR**: Error messages for failures
- **CRITICAL**: Critical failures requiring immediate attention

**Log Rotation**:
- Daily rotation prevents single large log files
- 30-day retention balances disk space and historical analysis
- Compression reduces disk space usage (gzip)
- Automatic cleanup prevents manual intervention

### Performance Considerations

**Log File I/O**:
- Rotating file handlers prevent file system fragmentation
- Buffered writes reduce I/O overhead
- Asynchronous logging for high-throughput scenarios (future)

**Disk Space Management**:
- 10MB max per log file (30 rotations = ~300MB per log type)
- Total disk usage: ~1GB max for all logs
- Error log: 50MB max (less rotation, more retention)

### HX-Infrastructure Standards Compliance

- ✅ **Structured Logging**: JSON format for machine parsing
- ✅ **Centralized Logging**: All logs in `/var/log/docling-mcp`
- ✅ **Systemd Integration**: Journal logging for systemd management
- ✅ **Automatic Rotation**: Logrotate for space management
- ✅ **Service Account Ownership**: Logs owned by service account
- ✅ **Monitoring Scripts**: Operational monitoring capabilities

---

## References

- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 034)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Logging Configuration)
- **Environment File**: `/etc/docling-mcp/.env` (LOG_* variables)
- **Systemd Service**: `/etc/systemd/system/docling-mcp.service` (StandardOutput/StandardError)

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
