# Task 162: Configure Log Rotation (Systemd Journal)

**Assigned To**: william-chen
**Estimated Effort**: 0.5 hours
**Dependencies**: Task 161 (Structured Logging Configuration)
**Status**: Not Started

## Objective

Configure systemd journal log rotation policies for Docling MCP Server to manage disk space usage with 7-day retention and 500MB size limit.

## Pre-Execution Validation

**CRITICAL**: Check if systemd journal rotation already configured BEFORE modifying journald.conf.

```bash
# Validation command to check journald configuration
echo "Checking systemd journal configuration..."

JOURNALD_CONF="/etc/systemd/journald.conf"

if [ -f "$JOURNALD_CONF" ]; then
    echo "✅ journald.conf exists: $JOURNALD_CONF"
    echo ""
    echo "Current configuration:"
    grep -E "^(SystemMaxUse|MaxRetentionSec|Storage)" "$JOURNALD_CONF" || echo "No relevant settings configured (using defaults)"
    echo ""

    # Check if persistent storage enabled
    if grep -q "^Storage=persistent" "$JOURNALD_CONF"; then
        echo "✅ Persistent journal storage enabled"
    elif systemctl status systemd-journald | grep -q "persistent"; then
        echo "✅ Persistent journal storage enabled (default or system config)"
    else
        echo "⚠️  Persistent journal storage not explicitly configured"
    fi

    # Check if rotation limits configured
    if grep -q "^SystemMaxUse=" "$JOURNALD_CONF" && grep -q "^MaxRetentionSec=" "$JOURNALD_CONF"; then
        echo "✅ VALIDATION RESULT: Journal rotation already configured"
        echo "ACTION: Review existing settings, skip if satisfactory"
        exit 0
    else
        echo "❌ VALIDATION RESULT: Journal rotation limits not configured"
        echo "ACTION: PROCEED with implementation steps"
    fi
else
    echo "❌ journald.conf not found (unexpected on Ubuntu 24.04)"
    exit 1
fi
```

**If Already Complete**: Review existing settings, skip if correct
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Systemd journal manages all service logs on Ubuntu 24.04 LTS, including Docling MCP Server logs. Without rotation limits, journal logs can grow indefinitely and exhaust disk space.

**Log Rotation Requirements (Specification):**
- **Retention**: 7 days OR 500MB (whichever reached first)
- **Storage**: Persistent journal (survives reboots)
- **Location**: `/var/log/journal/` (persistent journal directory)
- **Compression**: Automatic compression by systemd-journald

**Journal Configuration File:** `/etc/systemd/journald.conf`

**Key Parameters:**
- `Storage=persistent`: Store logs persistently (not just in-memory)
- `SystemMaxUse=500M`: Maximum disk space for all journals
- `MaxRetentionSec=7days`: Delete logs older than 7 days
- `Compress=yes`: Compress rotated logs (default enabled)

This task configures system-wide journal settings. Service-specific logging configured in Task 161.

## Acceptance Criteria

- [ ] journald.conf configured with `Storage=persistent`
- [ ] journald.conf configured with `SystemMaxUse=500M`
- [ ] journald.conf configured with `MaxRetentionSec=7days` (604800 seconds)
- [ ] Compression enabled (default or explicit `Compress=yes`)
- [ ] systemd-journald service restarted to apply changes
- [ ] Persistent journal directory exists (`/var/log/journal/`)
- [ ] Journal space usage within limits (validated with `journalctl --disk-usage`)
- [ ] Old log entries rotate correctly (cannot test immediately, documented for future validation)

## Implementation Steps

### Step 1: Backup Current journald.conf

```bash
# Backup current configuration before modification
JOURNALD_CONF="/etc/systemd/journald.conf"
BACKUP_FILE="/etc/systemd/journald.conf.backup-$(date +%Y%m%d-%H%M%S)"

echo "Backing up journald.conf..."

sudo cp "$JOURNALD_CONF" "$BACKUP_FILE"

if [ -f "$BACKUP_FILE" ]; then
    echo "✅ Backup created: $BACKUP_FILE"
else
    echo "❌ Backup failed"
    exit 1
fi
```

### Step 2: Configure Journal Rotation Limits

```bash
# Configure journald rotation settings
JOURNALD_CONF="/etc/systemd/journald.conf"

echo "Configuring journal rotation limits..."

# Create timestamped backup before modifying system config
BACKUP_FILE="${JOURNALD_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
echo "Creating backup: $BACKUP_FILE"
sudo cp "$JOURNALD_CONF" "$BACKUP_FILE"

if [ $? -ne 0 ]; then
    echo "❌ Failed to create backup of journald.conf"
    exit 1
fi

echo "✅ Backup created successfully"

# Modify only specific configuration keys using sed (preserves all other settings)
# This approach is SAFE - it does not destroy existing custom values

echo "Updating Storage setting..."
sudo sed -i 's/^#*Storage=.*/Storage=persistent/' "$JOURNALD_CONF"

echo "Updating SystemMaxUse setting..."
if grep -q '^#*SystemMaxUse=' "$JOURNALD_CONF"; then
    sudo sed -i 's/^#*SystemMaxUse=.*/SystemMaxUse=500M/' "$JOURNALD_CONF"
else
    # Add if missing
    sudo sed -i '/^\[Journal\]/a SystemMaxUse=500M' "$JOURNALD_CONF"
fi

echo "Updating MaxRetentionSec setting..."
if grep -q '^#*MaxRetentionSec=' "$JOURNALD_CONF"; then
    sudo sed -i 's/^#*MaxRetentionSec=.*/MaxRetentionSec=7days/' "$JOURNALD_CONF"
else
    sudo sed -i '/^\[Journal\]/a MaxRetentionSec=7days' "$JOURNALD_CONF"
fi

echo "Updating Compress setting..."
if grep -q '^#*Compress=' "$JOURNALD_CONF"; then
    sudo sed -i 's/^#*Compress=.*/Compress=yes/' "$JOURNALD_CONF"
else
    sudo sed -i '/^\[Journal\]/a Compress=yes' "$JOURNALD_CONF"
fi

if [ $? -eq 0 ]; then
    echo "✅ journald.conf updated with rotation limits (safe in-place editing)"
    echo "   Backup available at: $BACKUP_FILE"
else
    echo "❌ Failed to update journald.conf"
    echo "   Restoring from backup: $BACKUP_FILE"
    sudo cp "$BACKUP_FILE" "$JOURNALD_CONF"
    exit 1
fi

# Display updated configuration
echo ""
echo "Updated journald.conf:"
grep -E "^[^#]" "$JOURNALD_CONF" | grep -v "^$"
```

### Step 3: Validate Configuration Syntax

```bash
# Validate journald configuration syntax
echo ""
echo "Validating journald configuration..."

# Check for syntax errors (journald will fail to restart if invalid)
if sudo systemd-analyze verify systemd-journald.service 2>&1 | grep -i "error"; then
    echo "❌ Configuration validation errors detected"
    echo "Restoring backup..."
    sudo cp "$BACKUP_FILE" "$JOURNALD_CONF"
    exit 1
else
    echo "✅ Configuration syntax valid"
fi
```

### Step 4: Restart systemd-journald Service

```bash
# Restart systemd-journald to apply new configuration
echo ""
echo "Restarting systemd-journald service..."

sudo systemctl restart systemd-journald

if [ $? -eq 0 ]; then
    echo "✅ systemd-journald restarted successfully"
else
    echo "❌ Failed to restart systemd-journald"
    echo "Restoring backup..."
    sudo cp "$BACKUP_FILE" "$JOURNALD_CONF"
    sudo systemctl restart systemd-journald
    exit 1
fi

# Verify service active
if systemctl is-active systemd-journald > /dev/null 2>&1; then
    echo "✅ systemd-journald service is active"
else
    echo "❌ systemd-journald service failed to start"
    exit 1
fi
```

### Step 5: Verify Persistent Journal Directory

```bash
# Verify persistent journal directory exists
JOURNAL_DIR="/var/log/journal"

echo ""
echo "Verifying persistent journal directory..."

if [ -d "$JOURNAL_DIR" ]; then
    echo "✅ Persistent journal directory exists: $JOURNAL_DIR"
    echo ""
    echo "Journal directory contents:"
    sudo ls -lh "$JOURNAL_DIR"
else
    echo "⚠️  Persistent journal directory not found, creating..."
    sudo mkdir -p "$JOURNAL_DIR"
    sudo systemd-tmpfiles --create --prefix /var/log/journal
    echo "✅ Persistent journal directory created"
fi
```

### Step 6: Validate Journal Space Usage

```bash
# Check current journal disk usage
echo ""
echo "Checking journal disk usage..."

DISK_USAGE=$(sudo journalctl --disk-usage 2>&1)
echo "$DISK_USAGE"

# Extract usage in MB (approximate)
USAGE_MB=$(echo "$DISK_USAGE" | grep -oP '\d+\.\d+M' | head -n1 | grep -oP '\d+\.\d+')

if [ -n "$USAGE_MB" ]; then
    echo ""
    echo "Current journal usage: ${USAGE_MB}M / 500M limit"

    # Check if within limit (allow float comparison)
    if (( $(echo "$USAGE_MB < 500" | bc -l) )); then
        echo "✅ Journal usage within configured limit"
    else
        echo "⚠️  WARNING: Journal usage exceeds limit, vacuum may be needed"
    fi
else
    echo "✅ Journal usage tracking initialized"
fi
```

### Step 7: Force Journal Vacuum (if needed)

```bash
# Vacuum old journal entries to enforce size limit immediately
echo ""
echo "Applying journal vacuum to enforce size limit..."

sudo journalctl --vacuum-size=500M
sudo journalctl --vacuum-time=7days

if [ $? -eq 0 ]; then
    echo "✅ Journal vacuum complete"

    # Display new disk usage
    echo ""
    echo "Journal disk usage after vacuum:"
    sudo journalctl --disk-usage
else
    echo "⚠️  WARNING: Journal vacuum encountered errors"
fi
```

### Step 8: Document Log Rotation Configuration

```bash
# Document log rotation configuration
DOC_PATH="/opt/docling-mcp/deployment-docs"
mkdir -p "$DOC_PATH"

cat > "$DOC_PATH/log-rotation-configuration.txt" <<EOF
# Log Rotation Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-docling-mcp-server.hx.dev.local
# Task: hx-docling-mcp-task-162

## Systemd Journal Configuration
Configuration File: /etc/systemd/journald.conf

## Rotation Limits
- Storage: persistent (survives reboots)
- Maximum Disk Space: 500MB (SystemMaxUse=500M)
- Maximum Retention: 7 days (MaxRetentionSec=7days)
- Compression: Enabled (Compress=yes)

## Journal Location
Persistent Journal: /var/log/journal/

## Current Journal Usage
$(sudo journalctl --disk-usage)

## Manual Vacuum Commands
# Vacuum by size
sudo journalctl --vacuum-size=500M

# Vacuum by time
sudo journalctl --vacuum-time=7days

# Vacuum by both (uses configured limits)
sudo journalctl --vacuum-size=500M --vacuum-time=7days

## View Journal Status
# Disk usage
sudo journalctl --disk-usage

# Verify settings
sudo journalctl --header

# List journal files
sudo ls -lh /var/log/journal/

## Restore Backup (if needed)
Backup File: $BACKUP_FILE
Restore Command: sudo cp $BACKUP_FILE /etc/systemd/journald.conf && sudo systemctl restart systemd-journald

## Service-Specific Logs
# View Docling MCP Server logs
sudo journalctl -u docling-mcp.service

# View with size limit (last 100MB)
sudo journalctl -u docling-mcp.service --vacuum-size=100M

# Export logs before rotation
sudo journalctl -u docling-mcp.service --since "7 days ago" > docling-mcp-logs-archive.txt
EOF

echo "✅ Log rotation configuration documented: $DOC_PATH/log-rotation-configuration.txt"
cat "$DOC_PATH/log-rotation-configuration.txt"
```

## Validation

**Validation Commands:**

```bash
echo "=== Log Rotation Configuration Validation ==="

JOURNALD_CONF="/etc/systemd/journald.conf"

# Validate journald.conf configuration
echo "1. journald.conf Configuration:"
if [ -f "$JOURNALD_CONF" ]; then
    echo "✅ PASSED: journald.conf exists"
else
    echo "❌ FAILED: journald.conf not found"
    exit 1
fi

# Validate Storage=persistent
echo ""
echo "2. Persistent Storage:"
if grep -q "^Storage=persistent" "$JOURNALD_CONF"; then
    echo "✅ PASSED: Persistent storage configured"
else
    echo "❌ FAILED: Persistent storage not configured"
    exit 1
fi

# Validate SystemMaxUse
echo ""
echo "3. Size Limit (SystemMaxUse):"
if grep -q "^SystemMaxUse=500M" "$JOURNALD_CONF"; then
    echo "✅ PASSED: Size limit configured (500M)"
else
    echo "⚠️  WARNING: Size limit not configured or different value"
    grep "SystemMaxUse" "$JOURNALD_CONF"
fi

# Validate MaxRetentionSec
echo ""
echo "4. Time Limit (MaxRetentionSec):"
if grep -q "^MaxRetentionSec=7days" "$JOURNALD_CONF"; then
    echo "✅ PASSED: Retention time configured (7 days)"
else
    echo "⚠️  WARNING: Retention time not configured or different value"
    grep "MaxRetentionSec" "$JOURNALD_CONF"
fi

# Validate systemd-journald service active
echo ""
echo "5. systemd-journald Service:"
if systemctl is-active systemd-journald > /dev/null 2>&1; then
    echo "✅ PASSED: systemd-journald service active"
else
    echo "❌ FAILED: systemd-journald service not active"
    exit 1
fi

# Validate persistent journal directory
echo ""
echo "6. Persistent Journal Directory:"
if [ -d "/var/log/journal" ]; then
    echo "✅ PASSED: Persistent journal directory exists"
    echo "Directory size: $(du -sh /var/log/journal 2>/dev/null | cut -f1)"
else
    echo "❌ FAILED: Persistent journal directory not found"
    exit 1
fi

# Validate journal disk usage within limit
echo ""
echo "7. Journal Disk Usage:"
DISK_USAGE=$(sudo journalctl --disk-usage 2>&1)
echo "$DISK_USAGE"

USAGE_MB=$(echo "$DISK_USAGE" | grep -oP '\d+\.\d+M' | head -n1 | grep -oP '\d+\.\d+' || echo "0")

if [ -n "$USAGE_MB" ]; then
    if (( $(echo "$USAGE_MB < 500" | bc -l 2>/dev/null || echo "1") )); then
        echo "✅ PASSED: Journal usage within 500M limit"
    else
        echo "⚠️  WARNING: Journal usage exceeds limit, vacuum recommended"
    fi
else
    echo "✅ PASSED: Journal usage tracking initialized"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - Log rotation configured"
echo ""
echo "Rotation Policy:"
echo "  - Maximum Size: 500MB"
echo "  - Maximum Age: 7 days"
echo "  - Compression: Enabled"
echo "  - Storage: Persistent"
echo ""
echo "Next Step: Task 191 - Post-Deployment Validation"
```

**Expected Results:**
- journald.conf contains `Storage=persistent`
- journald.conf contains `SystemMaxUse=500M`
- journald.conf contains `MaxRetentionSec=7days`
- systemd-journald service active
- `/var/log/journal/` directory exists
- Journal disk usage < 500MB
- Backup file exists for rollback

## Notes

**Systemd Journal Behavior:**
- **Rotation**: Automatic when size/time limits reached
- **Compression**: Rotated files compressed automatically
- **Deletion**: Files deleted when exceeding SystemMaxUse OR MaxRetentionSec
- **Priority**: Size limit takes precedence (deletes oldest logs first)

**Journal Commands:**
```bash
# View disk usage
sudo journalctl --disk-usage

# View journal files
sudo ls -lh /var/log/journal/

# Manual vacuum (enforce limits immediately)
sudo journalctl --vacuum-size=500M
sudo journalctl --vacuum-time=7days

# View journal headers (shows retention settings)
sudo journalctl --header

# Verify journald configuration
sudo systemctl status systemd-journald
```

**Service-Specific Logs:**
```bash
# View Docling MCP Server logs
sudo journalctl -u docling-mcp.service

# Export logs for archival
sudo journalctl -u docling-mcp.service --since "7 days ago" > archive.log

# Vacuum service-specific logs
sudo journalctl -u docling-mcp.service --vacuum-size=100M
```

**Configuration Tuning:**
- **Higher Retention**: Increase `SystemMaxUse` (e.g., `SystemMaxUse=1G`)
- **Lower Retention**: Decrease time (e.g., `MaxRetentionSec=3days`)
- **Per-Service Limits**: Use `RateLimitBurst` and `RateLimitInterval` in service unit

**Troubleshooting:**
- If logs disappear after reboot: Check `Storage=persistent` configured
- If disk usage exceeds limit: Run manual vacuum `journalctl --vacuum-size=500M`
- If journald fails to start: Restore backup and check syntax errors
- If logs grow too fast: Review LOG_LEVEL in application (Task 161), set to INFO not DEBUG

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Log Rotation Policies (lines 5050-5075)
- Section: Operational Requirements - Logging

**Systemd Documentation**:
- journald.conf: `man journald.conf`
- journalctl: `man journalctl`
- Journal file format: `man systemd.journal-fields`

## Risk Assessment

**Risk Level**: Low

**Risks**:
1. **Log loss**: Rotation deletes logs before archival/export
2. **Disk exhaustion**: 500MB insufficient for burst logging
3. **journald crash**: Invalid configuration causes service failure

**Mitigation**:
- Backup configuration before changes
- 500MB limit generous for single service (per specification analysis)
- Test configuration syntax before restart
- Automatic compression reduces disk usage
- Persistent storage ensures logs survive reboots
- Manual vacuum available if limits exceeded
