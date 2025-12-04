# Task 133: Configure Log Rotation

**Task ID**: hx-lang-server-task-133
**Phase**: Configuration (Logging & Monitoring)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 132 (Log Directory)
**Estimated Effort**: 30 minutes

---

## Objective

Configure log rotation for hx-lang-server using logrotate for file-based logs and systemd journal retention settings, ensuring logs do not consume excessive disk space.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 132 (Log Directory) completed
- [ ] Log directory exists at /var/log/hx-lang-server

---

## Pre-Execution Validation

**CRITICAL**: Check if log rotation is already configured BEFORE creating.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check log rotation configuration
LOGROTATE_CONF="/etc/logrotate.d/hx-lang-server"

echo "Checking log rotation configuration status..."

if [ -f "$LOGROTATE_CONF" ]; then
    echo "Logrotate configuration exists: $LOGROTATE_CONF"
    cat "$LOGROTATE_CONF"
    echo ""
    echo "VALIDATION RESULT: Log rotation already configured"
    echo "ACTION: Review existing configuration, skip if correct"
else
    echo "VALIDATION RESULT: Log rotation not configured"
    echo "ACTION: PROCEED with implementation steps"
fi

# Check journal retention
echo ""
echo "Systemd journal configuration:"
if [ -f "/etc/systemd/journald.conf.d/hx-lang-server.conf" ]; then
    cat "/etc/systemd/journald.conf.d/hx-lang-server.conf"
else
    echo "No custom journal configuration found"
fi
```

**If Already Configured**: Review existing configuration
**If Not Configured**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Create Logrotate Configuration

```bash
# Create logrotate configuration for hx-lang-server
LOGROTATE_CONF="/etc/logrotate.d/hx-lang-server"

echo "Creating logrotate configuration..."

sudo tee "$LOGROTATE_CONF" > /dev/null <<'EOF'
# Log rotation configuration for hx-lang-server
# Task: hx-lang-server-task-133
# Date: 2025-12-04

/var/log/hx-lang-server/*.log
/var/log/hx-lang-server/**/*.log {
    # Rotate daily
    daily

    # Keep 30 days of logs
    rotate 30

    # Compress old logs
    compress
    delaycompress

    # Don't error if log file is missing
    missingok

    # Don't rotate if empty
    notifempty

    # Create new log file with same permissions
    create 0640 hx-lang-server hx-lang-server

    # Use date extension
    dateext
    dateformat -%Y%m%d

    # Add .log extension to rotated files
    extension .log

    # Share rotation script for multiple log files
    sharedscripts

    # Signal service to reopen log files (if using file-based logging)
    postrotate
        # Send SIGHUP to reopen log files if service is running
        if systemctl is-active --quiet hx-lang-server.service; then
            systemctl kill -s HUP hx-lang-server.service 2>/dev/null || true
        fi
    endscript
}
EOF

echo "Logrotate configuration created: $LOGROTATE_CONF"
cat "$LOGROTATE_CONF"
```

### Step 2: Test Logrotate Configuration

```bash
# Test logrotate configuration syntax
LOGROTATE_CONF="/etc/logrotate.d/hx-lang-server"

echo "Testing logrotate configuration..."

# Dry run to check configuration
sudo logrotate -d "$LOGROTATE_CONF" 2>&1

if [ $? -eq 0 ]; then
    echo "Logrotate configuration syntax is valid"
else
    echo "WARNING: Logrotate configuration may have issues"
fi
```

### Step 3: Configure Systemd Journal Retention

**IMPORTANT**: This step adds retention settings specific to hx-lang-server without modifying the global journald.conf.

```bash
# Create journal configuration drop-in directory
JOURNAL_CONF_DIR="/etc/systemd/journald.conf.d"
JOURNAL_CONF="$JOURNAL_CONF_DIR/hx-lang-server.conf"

echo "Configuring systemd journal retention..."

# Create drop-in directory if it doesn't exist
sudo mkdir -p "$JOURNAL_CONF_DIR"

# Check current journal size
echo "Current journal disk usage:"
sudo journalctl --disk-usage

# Note: Drop-in files in journald.conf.d only add to global config
# They cannot filter by service unit
# Instead, we document the global retention policy

# Create documentation file (not actual journal config)
sudo tee "/opt/hx-lang-server/deployment-docs/journal-retention-policy.txt" > /dev/null <<'EOF'
# Systemd Journal Retention Policy for hx-lang-server
# Task: hx-lang-server-task-133
# Date: 2025-12-04

## Important Note
Systemd journal does NOT support per-service retention settings.
The journal retention applies globally to all services.

## Current Global Journal Settings
Location: /etc/systemd/journald.conf

Default Ubuntu 24.04 settings:
- SystemMaxUse: 10% of disk or 4GB max
- RuntimeMaxUse: 10% of memory
- MaxFileSec: 1month

## Recommended Settings for HX-Infrastructure
To modify global journal retention (affects ALL services):
Edit /etc/systemd/journald.conf and set:

[Journal]
SystemMaxUse=2G
SystemKeepFree=1G
MaxRetentionSec=7d
MaxFileSec=1day

Then run: sudo systemctl restart systemd-journald

## Viewing hx-lang-server Logs
# Real-time
sudo journalctl -u hx-lang-server.service -f

# Since boot
sudo journalctl -u hx-lang-server.service -b

# Last 7 days
sudo journalctl -u hx-lang-server.service --since "7 days ago"

# JSON format for parsing
sudo journalctl -u hx-lang-server.service -o json

## Manual Log Cleanup
# Vacuum logs older than 7 days
sudo journalctl --vacuum-time=7d

# Vacuum logs over 500MB
sudo journalctl --vacuum-size=500M

## Log Export
# Export hx-lang-server logs to file
sudo journalctl -u hx-lang-server.service --since "2025-12-01" > hx-lang-server-logs.txt
EOF

echo "Journal retention policy documented"
cat "/opt/hx-lang-server/deployment-docs/journal-retention-policy.txt"
```

### Step 4: Create Log Cleanup Script

```bash
# Create log cleanup script for manual maintenance
SCRIPT_PATH="/opt/hx-lang-server/scripts/cleanup-logs.sh"

echo "Creating log cleanup script..."

sudo mkdir -p "/opt/hx-lang-server/scripts"

sudo tee "$SCRIPT_PATH" > /dev/null <<'BASH'
#!/bin/bash
# Log Cleanup Script for hx-lang-server
# Task: hx-lang-server-task-133

LOG_DIR="/var/log/hx-lang-server"
RETENTION_DAYS=30

echo "=== hx-lang-server Log Cleanup ==="
echo "Date: $(date)"
echo "Retention: $RETENTION_DAYS days"
echo ""

# Show current disk usage
echo "Current log directory usage:"
du -sh "$LOG_DIR"
echo ""

# Find old log files
echo "Log files older than $RETENTION_DAYS days:"
find "$LOG_DIR" -type f -mtime +$RETENTION_DAYS -print

# Delete old log files (uncomment to enable)
# echo ""
# echo "Deleting old log files..."
# find "$LOG_DIR" -type f -mtime +$RETENTION_DAYS -delete

# Vacuum systemd journal
echo ""
echo "Systemd journal status:"
journalctl --disk-usage

echo ""
echo "To vacuum journal logs older than 7 days, run:"
echo "  sudo journalctl --vacuum-time=7d"

echo ""
echo "Cleanup complete"
BASH

# Set permissions
sudo chmod 755 "$SCRIPT_PATH"
sudo chown hx-lang-server "$SCRIPT_PATH" 2>/dev/null || true

echo "Log cleanup script created: $SCRIPT_PATH"
```

### Step 5: Create Systemd Timer for Log Cleanup (Optional)

```bash
# Create systemd timer for automated log cleanup
TIMER_UNIT="/etc/systemd/system/hx-lang-server-log-cleanup.timer"
SERVICE_UNIT="/etc/systemd/system/hx-lang-server-log-cleanup.service"

echo "Creating systemd timer for log cleanup..."

# Create service unit
sudo tee "$SERVICE_UNIT" > /dev/null <<'EOF'
[Unit]
Description=hx-lang-server Log Cleanup
After=hx-lang-server.service

[Service]
Type=oneshot
ExecStart=/opt/hx-lang-server/scripts/cleanup-logs.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create timer unit
sudo tee "$TIMER_UNIT" > /dev/null <<'EOF'
[Unit]
Description=Run hx-lang-server log cleanup weekly

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Note: Timer is NOT enabled by default - enable manually if needed
echo "Log cleanup timer created (not enabled)"
echo "To enable: sudo systemctl enable --now hx-lang-server-log-cleanup.timer"
```

### Step 6: Document Log Rotation Configuration

```bash
# Document log rotation configuration
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/log-rotation-configuration.txt" > /dev/null <<'EOF'
# Log Rotation Configuration
# Date: 2025-12-04
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-133

## Logrotate Configuration
Location: /etc/logrotate.d/hx-lang-server

Settings:
- Rotation: Daily
- Retention: 30 days
- Compression: Yes (gzip)
- Create new: 0640 hx-lang-server hx-lang-server

## Systemd Journal
Primary logs go to systemd journal.
Journal retention is controlled globally (not per-service).

View logs: sudo journalctl -u hx-lang-server.service

## Manual Commands

# Force log rotation
sudo logrotate -f /etc/logrotate.d/hx-lang-server

# Check logrotate status
sudo logrotate -d /etc/logrotate.d/hx-lang-server

# Check journal disk usage
sudo journalctl --disk-usage

# Vacuum journal (7 days)
sudo journalctl --vacuum-time=7d

# Vacuum journal (500MB)
sudo journalctl --vacuum-size=500M

## Cleanup Script
Location: /opt/hx-lang-server/scripts/cleanup-logs.sh

Run manually:
sudo /opt/hx-lang-server/scripts/cleanup-logs.sh

## Automated Cleanup Timer
Service: hx-lang-server-log-cleanup.service
Timer: hx-lang-server-log-cleanup.timer

Enable:
sudo systemctl enable --now hx-lang-server-log-cleanup.timer

Status:
sudo systemctl list-timers | grep hx-lang-server
EOF

echo "Log rotation documented: $DOC_DIR/log-rotation-configuration.txt"
cat "$DOC_DIR/log-rotation-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Logrotate Config | /etc/logrotate.d/hx-lang-server | Logrotate configuration |
| Cleanup Script | /opt/hx-lang-server/scripts/cleanup-logs.sh | Manual cleanup script |
| Timer Unit | /etc/systemd/system/hx-lang-server-log-cleanup.timer | Automated cleanup timer |
| Service Unit | /etc/systemd/system/hx-lang-server-log-cleanup.service | Cleanup service |
| Documentation | /opt/hx-lang-server/deployment-docs/log-rotation-configuration.txt | Configuration guide |

---

## Verification

**Validation Commands:**

```bash
echo "=== Log Rotation Validation ==="

VALIDATION_PASSED=true

# Check 1: Logrotate configuration exists
echo "1. Logrotate Configuration:"
if [ -f "/etc/logrotate.d/hx-lang-server" ]; then
    echo "PASSED: Logrotate configuration exists"
else
    echo "FAILED: Logrotate configuration not found"
    VALIDATION_PASSED=false
fi

# Check 2: Logrotate syntax valid
echo ""
echo "2. Logrotate Syntax:"
if sudo logrotate -d /etc/logrotate.d/hx-lang-server 2>&1 | grep -q "error"; then
    echo "FAILED: Logrotate configuration has errors"
    VALIDATION_PASSED=false
else
    echo "PASSED: Logrotate syntax valid"
fi

# Check 3: Cleanup script exists
echo ""
echo "3. Cleanup Script:"
if [ -x "/opt/hx-lang-server/scripts/cleanup-logs.sh" ]; then
    echo "PASSED: Cleanup script exists and is executable"
else
    echo "WARNING: Cleanup script not found or not executable"
fi

# Check 4: Timer unit exists
echo ""
echo "4. Systemd Timer:"
if [ -f "/etc/systemd/system/hx-lang-server-log-cleanup.timer" ]; then
    echo "PASSED: Timer unit exists"
else
    echo "WARNING: Timer unit not found"
fi

# Check 5: Journal disk usage
echo ""
echo "5. Journal Disk Usage:"
sudo journalctl --disk-usage

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Log rotation configured"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- Logrotate configuration exists at /etc/logrotate.d/hx-lang-server
- Logrotate dry-run shows no errors
- Cleanup script exists and is executable
- Timer unit files exist (not necessarily enabled)

---

## Rollback Procedure

Remove log rotation configuration if needed:

```bash
# Remove log rotation configuration
echo "Removing log rotation configuration..."

# Remove logrotate config
sudo rm -f /etc/logrotate.d/hx-lang-server

# Remove systemd timer (disable first if enabled)
sudo systemctl disable --now hx-lang-server-log-cleanup.timer 2>/dev/null || true
sudo rm -f /etc/systemd/system/hx-lang-server-log-cleanup.timer
sudo rm -f /etc/systemd/system/hx-lang-server-log-cleanup.service
sudo systemctl daemon-reload

# Remove cleanup script
sudo rm -f /opt/hx-lang-server/scripts/cleanup-logs.sh

echo "Log rotation configuration removed"
```

---

## Notes

**Primary Logging Strategy:**
- stdout/stderr -> systemd journal (primary)
- File-based logging via logrotate (secondary, if needed)

**Logrotate Behavior:**
- Daily rotation for active log files
- 30-day retention (configurable)
- Compressed archives save disk space
- postrotate sends SIGHUP for log file reopening

**Systemd Journal:**
- Cannot configure per-service retention
- Global settings in /etc/systemd/journald.conf
- Manual vacuum commands for cleanup

**Disk Space:**
- Log directory: Part of 50GB storage allocation
- Journal: Controlled by global SystemMaxUse setting

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Node Requirements - Storage (line 130)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 12: Logging & Monitoring (Task Range 131-140)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Disk full**: Logs not rotated, fill disk
   - Mitigation: Daily rotation, 30-day retention, compression
2. **Log loss**: Rotation deletes needed logs
   - Mitigation: 30-day retention sufficient for troubleshooting
3. **Service disruption**: SIGHUP causes issues
   - Mitigation: Signal only sent if service is active

**Dependencies Blocked:**
- Task 141+ (Service Deployment) benefits from log rotation
- Long-term operations require proper log management
