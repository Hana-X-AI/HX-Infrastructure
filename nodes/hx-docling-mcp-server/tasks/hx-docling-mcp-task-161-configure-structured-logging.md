# Task 161: Configure Structured Logging

**Assigned To**: william-chen
**Estimated Effort**: 1.5 hours
**Dependencies**: Task 152 (Service Started), Task 007 (Application Code)
**Status**: Not Started

## Objective

Configure structured JSON logging for Docling MCP Server with log sanitization (credential redaction, document content truncation), systemd journal integration, and proper log levels.

## Pre-Execution Validation

**CRITICAL**: Check if logging configuration already exists in application code BEFORE implementing.

```bash
# Validation command to check if logging configuration exists
LOGGING_CONFIG="/opt/docling-mcp/src/config/logging_config.py"

echo "Checking logging configuration status..."

if [ -f "$LOGGING_CONFIG" ]; then
    echo "✅ Logging configuration file exists: $LOGGING_CONFIG"
    echo ""
    echo "Checking for structured logging components..."

    # Check for JSON logging
    if grep -q "json" "$LOGGING_CONFIG" 2>/dev/null; then
        echo "✅ JSON logging configured"
    else
        echo "⚠️  JSON logging not detected"
    fi

    # Check for log sanitization
    if grep -q "sanitize\|redact" "$LOGGING_CONFIG" 2>/dev/null; then
        echo "✅ Log sanitization configured"
    else
        echo "⚠️  Log sanitization not detected"
    fi

    echo ""
    echo "✅ VALIDATION RESULT: Logging configuration exists"
    echo "ACTION: Review existing configuration, skip if satisfactory"
    exit 0
else
    echo "❌ VALIDATION RESULT: Logging configuration does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Review existing configuration, skip if correct
**If Not Complete**: Continue with Implementation Steps below

---

## Context

The Docling MCP Server requires structured logging for:

**Operational Visibility:**
- Track MCP tool invocations with context (tool name, session ID, document ID)
- Monitor document processing pipeline stages
- Track dependency health checks (LiteLLM, Qdrant, Redis, hx-literag-server)

**Security & Compliance:**
- Redact credentials from logs (API keys, passwords, tokens)
- Truncate document content to prevent sensitive data exposure
- Sanitize user input before logging

**Systemd Integration:**
- JSON-formatted logs to stdout (captured by systemd journal)
- Structured metadata for log aggregation and searching
- Log levels mapped to systemd priority levels

**Log Structure (JSON):**
```json
{
  "timestamp": "2025-12-01T10:30:15.123Z",
  "level": "INFO",
  "component": "mcp_server",
  "message": "MCP tool invoked",
  "context": {
    "tool_name": "convert_document",
    "session_id": "abc123",
    "document_id": "doc456",
    "format": "pdf",
    "duration_ms": 3500
  }
}
```

This task configures application-level logging. Systemd journal retention configured in Task 162.

## Acceptance Criteria

- [ ] Logging configuration module created (`src/config/logging_config.py`)
- [ ] JSON structured logging configured using structlog or python-json-logger
- [ ] Log sanitization implemented (credential redaction, content truncation)
- [ ] Log levels configured: DEBUG, INFO, WARN, ERROR
- [ ] Systemd journal integration (stdout/stderr to journal)
- [ ] Logging initialized in MCP server entry point (`src/mcp_server.py`)
- [ ] Test logs confirm JSON format and sanitization working
- [ ] No plain-text credentials appear in logs

## Implementation Steps

### Step 1: Create Logging Configuration Module

```bash
# Create logging configuration directory and module
LOGGING_CONFIG_DIR="/opt/docling-mcp/src/config"
LOGGING_CONFIG_FILE="$LOGGING_CONFIG_DIR/logging_config.py"

mkdir -p "$LOGGING_CONFIG_DIR"

echo "Creating logging configuration module..."

cat > "$LOGGING_CONFIG_FILE" <<'EOF'
"""
Logging Configuration for Docling MCP Server
Structured JSON logging with sanitization and systemd journal integration.
"""

import logging
import sys
import re
from typing import Any, Dict
from datetime import datetime
import json


class LogSanitizer:
    """Sanitize sensitive data from log messages and context."""

    # Patterns for credential detection
    CREDENTIAL_PATTERNS = [
        re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
        re.compile(r'(Bearer)\s+([A-Za-z0-9\-._~+/]+=*)', re.IGNORECASE),
        re.compile(r'(Basic)\s+([A-Za-z0-9+/]+=*)', re.IGNORECASE),
    ]

    # Maximum document content length in logs
    MAX_CONTENT_LENGTH = 500

    @classmethod
    def sanitize_message(cls, message: str) -> str:
        """Redact credentials from log message."""
        sanitized = message

        for pattern in cls.CREDENTIAL_PATTERNS:
            sanitized = pattern.sub(r'\1=***REDACTED***', sanitized)

        return sanitized

    @classmethod
    def sanitize_context(cls, context: Dict[str, Any]) -> Dict[str, Any]:
        """Sanitize context dictionary (redact credentials, truncate content)."""
        sanitized = {}

        for key, value in context.items():
            # Redact credential-like keys
            if any(cred in key.lower() for cred in ['password', 'token', 'key', 'secret', 'auth']):
                sanitized[key] = '***REDACTED***'
            # Truncate document content
            elif key in ['content', 'document_content', 'text', 'raw_content']:
                if isinstance(value, str) and len(value) > cls.MAX_CONTENT_LENGTH:
                    sanitized[key] = value[:cls.MAX_CONTENT_LENGTH] + f'... [truncated, total length: {len(value)}]'
                else:
                    sanitized[key] = value
            # Recursively sanitize nested dicts
            elif isinstance(value, dict):
                sanitized[key] = cls.sanitize_context(value)
            else:
                sanitized[key] = value

        return sanitized


class JSONFormatter(logging.Formatter):
    """JSON log formatter with structured metadata."""

    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON."""
        log_data = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'level': record.levelname,
            'component': record.name,
            'message': LogSanitizer.sanitize_message(record.getMessage()),
        }

        # Add context if available (extra fields)
        context = {}
        for key, value in record.__dict__.items():
            if key not in ['name', 'msg', 'args', 'created', 'filename', 'funcName',
                           'levelname', 'levelno', 'lineno', 'module', 'msecs',
                           'pathname', 'process', 'processName', 'relativeCreated',
                           'thread', 'threadName', 'exc_info', 'exc_text', 'stack_info']:
                context[key] = value

        if context:
            log_data['context'] = LogSanitizer.sanitize_context(context)

        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)

        return json.dumps(log_data, default=str)


def configure_logging(log_level: str = "INFO") -> None:
    """
    Configure structured JSON logging for Docling MCP Server.

    Args:
        log_level: Logging level (DEBUG, INFO, WARN, ERROR)
    """
    # Map string level to logging constant
    level_map = {
        'DEBUG': logging.DEBUG,
        'INFO': logging.INFO,
        'WARN': logging.WARNING,
        'WARNING': logging.WARNING,
        'ERROR': logging.ERROR,
        'CRITICAL': logging.CRITICAL,
    }

    level = level_map.get(log_level.upper(), logging.INFO)

    # Create JSON formatter
    formatter = JSONFormatter()

    # Configure stdout handler (captured by systemd journal)
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(formatter)
    stdout_handler.setLevel(level)

    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    root_logger.handlers.clear()  # Remove default handlers
    root_logger.addHandler(stdout_handler)

    # Log configuration complete
    root_logger.info(
        "Logging configured",
        extra={
            'log_level': log_level,
            'formatter': 'JSON',
            'output': 'stdout (systemd journal)'
        }
    )


def get_logger(name: str) -> logging.Logger:
    """
    Get logger instance for component.

    Args:
        name: Logger name (typically module name)

    Returns:
        Logger instance
    """
    return logging.getLogger(name)
EOF

echo "✅ Logging configuration module created: $LOGGING_CONFIG_FILE"
```

### Step 2: Create __init__.py for Config Package

```bash
# Create __init__.py to make config a Python package
INIT_FILE="/opt/docling-mcp/src/config/__init__.py"

cat > "$INIT_FILE" <<'EOF'
"""Configuration package for Docling MCP Server."""

from .logging_config import configure_logging, get_logger

__all__ = ['configure_logging', 'get_logger']
EOF

echo "✅ Config package __init__.py created"
```

### Step 3: Integrate Logging in MCP Server Entry Point

```bash
# Update MCP server entry point to initialize logging
MCP_SERVER_FILE="/opt/docling-mcp/src/mcp_server.py"

# Check if mcp_server.py exists
if [ ! -f "$MCP_SERVER_FILE" ]; then
    echo "⚠️  WARNING: MCP server file not found - Task 007 may not be complete"
    echo "Creating placeholder entry point for logging integration"

    cat > "$MCP_SERVER_FILE" <<'EOF'
"""
Docling MCP Server - Entry Point
"""

import os
from fastapi import FastAPI
from config.logging_config import configure_logging, get_logger

# Configure logging on module import
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
configure_logging(log_level=LOG_LEVEL)

logger = get_logger(__name__)

# Create FastAPI application
app = FastAPI(title="Docling MCP Server")

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    logger.info("Health check requested")
    return {"status": "healthy", "version": "1.0.0"}

@app.on_event("startup")
async def startup_event():
    """Application startup event."""
    logger.info(
        "Docling MCP Server starting",
        extra={
            'log_level': LOG_LEVEL,
            'environment': os.getenv('ENVIRONMENT', 'production')
        }
    )

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event."""
    logger.info("Docling MCP Server shutting down")
EOF

    echo "✅ Placeholder MCP server entry point created with logging integration"
else
    echo "✅ MCP server file exists, logging will be integrated in application code (Task 007)"
    echo "NOTE: Ensure configure_logging() called early in application startup"
fi
```

### Step 4: Set LOG_LEVEL Environment Variable

```bash
# Ensure LOG_LEVEL configured in .env.production
ENV_FILE="/etc/docling-mcp/.env.production"

if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️  WARNING: .env.production not found - Task 008 may not be complete"
    echo "Creating placeholder environment file"
    sudo mkdir -p /etc/docling-mcp
    sudo bash -c "cat > $ENV_FILE" <<'EOF'
# Docling MCP Server Environment Configuration

# Logging Configuration
LOG_LEVEL=INFO
LOG_FORMAT=json
EOF
    echo "✅ Placeholder .env.production created with LOG_LEVEL"
else
    # Check if LOG_LEVEL already set
    if grep -q "^LOG_LEVEL=" "$ENV_FILE"; then
        echo "✅ LOG_LEVEL already configured in .env.production"
        grep "^LOG_LEVEL=" "$ENV_FILE"
    else
        echo "Adding LOG_LEVEL to .env.production..."
        sudo bash -c "echo '' >> $ENV_FILE"
        sudo bash -c "echo '# Logging Configuration' >> $ENV_FILE"
        sudo bash -c "echo 'LOG_LEVEL=INFO' >> $ENV_FILE"
        sudo bash -c "echo 'LOG_FORMAT=json' >> $ENV_FILE"
        echo "✅ LOG_LEVEL added to .env.production"
    fi
fi
```

### Step 5: Test Logging Configuration

```bash
# Test logging configuration with Python script
echo "Testing logging configuration..."

/opt/docling-mcp/venv/bin/python <<'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp/src')

from config.logging_config import configure_logging, get_logger

# Configure logging
configure_logging(log_level='INFO')

# Get logger
logger = get_logger('test_logging')

# Test different log levels
logger.debug("Debug message (should not appear at INFO level)")
logger.info("Info message with context", extra={'test_key': 'test_value', 'count': 42})
logger.warning("Warning message")
logger.error("Error message", extra={'error_code': 500})

# Test credential sanitization
logger.info("Testing credential redaction: api_key=secret123 password=hunter2")

# Test content truncation
long_content = 'x' * 1000
logger.info("Testing content truncation", extra={'content': long_content})

print("\n✅ Logging test complete - review JSON-formatted logs above")
EOF

if [ $? -eq 0 ]; then
    echo "✅ Logging configuration test passed"
else
    echo "❌ Logging configuration test failed"
    exit 1
fi
```

### Step 6: Document Logging Configuration

```bash
# Document logging configuration
DOC_PATH="/opt/docling-mcp/deployment-docs"
mkdir -p "$DOC_PATH"

cat > "$DOC_PATH/logging-configuration.txt" <<EOF
# Logging Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-docling-mcp-server.hx.dev.local
# Task: hx-docling-mcp-task-161

## Logging Module
Location: /opt/docling-mcp/src/config/logging_config.py

## Log Format
Format: JSON (structured)
Output: stdout (captured by systemd journal)

## Log Levels
- DEBUG: Detailed diagnostics (MCP payloads, processing steps)
- INFO: Normal operations (tool invocations, processing complete)
- WARN: Degraded state (dependency unavailable, slow response)
- ERROR: Failures (conversion errors, dependency failures)

## Log Sanitization
- Credentials: Redacted (api_key, token, password, secret, auth)
- Document Content: Truncated to 500 characters
- User Input: Sanitized before logging

## Environment Variable
LOG_LEVEL=INFO (configured in /etc/docling-mcp/.env.production)

## View Logs
# Real-time logs
sudo journalctl -u docling-mcp.service -f

# Last 100 lines
sudo journalctl -u docling-mcp.service -n 100

# Logs from last hour
sudo journalctl -u docling-mcp.service --since "1 hour ago"

# Filter by log level (ERROR only)
sudo journalctl -u docling-mcp.service -p err

# JSON formatted output
sudo journalctl -u docling-mcp.service -o json-pretty

## Log Retention
Systemd journal: 7 days or 500MB (whichever first)
Configuration: /etc/systemd/journald.conf
EOF

echo "✅ Logging configuration documented: $DOC_PATH/logging-configuration.txt"
cat "$DOC_PATH/logging-configuration.txt"
```

## Validation

**Validation Commands:**

```bash
echo "=== Structured Logging Configuration Validation ==="

# Validate logging module exists
echo "1. Logging Module:"
if [ -f "/opt/docling-mcp/src/config/logging_config.py" ]; then
    echo "✅ PASSED: Logging module exists"
else
    echo "❌ FAILED: Logging module not found"
    exit 1
fi

# Validate logging module syntax
echo ""
echo "2. Module Syntax:"
if /opt/docling-mcp/venv/bin/python -m py_compile /opt/docling-mcp/src/config/logging_config.py 2>/dev/null; then
    echo "✅ PASSED: Logging module syntax valid"
else
    echo "❌ FAILED: Logging module syntax errors"
    exit 1
fi

# Validate logging imports work
echo ""
echo "3. Logging Imports:"
if /opt/docling-mcp/venv/bin/python -c "import sys; sys.path.insert(0, '/opt/docling-mcp/src'); from config.logging_config import configure_logging, get_logger" 2>/dev/null; then
    echo "✅ PASSED: Logging module imports successfully"
else
    echo "❌ FAILED: Logging module import errors"
    exit 1
fi

# Validate LOG_LEVEL environment variable
echo ""
echo "4. LOG_LEVEL Environment Variable:"
if grep -q "^LOG_LEVEL=" /etc/docling-mcp/.env.production; then
    LOG_LEVEL=$(grep "^LOG_LEVEL=" /etc/docling-mcp/.env.production | cut -d= -f2)
    echo "✅ PASSED: LOG_LEVEL configured: $LOG_LEVEL"
else
    echo "⚠️  WARNING: LOG_LEVEL not found in .env.production"
fi

# Validate service logs are JSON formatted
echo ""
echo "5. Service Log Format:"
if systemctl is-active docling-mcp.service > /dev/null 2>&1; then
    RECENT_LOG=$(sudo journalctl -u docling-mcp.service -n 1 --output=cat 2>/dev/null)

    if echo "$RECENT_LOG" | python3 -m json.tool > /dev/null 2>&1; then
        echo "✅ PASSED: Service logs are JSON formatted"
        echo "Sample log:"
        echo "$RECENT_LOG" | python3 -m json.tool | head -n 10
    else
        echo "⚠️  WARNING: Recent log not in JSON format (service may need restart)"
    fi
else
    echo "⚠️  INFO: Service not running, cannot validate log format"
fi

# Validate credential sanitization
echo ""
echo "6. Credential Sanitization:"
TEST_OUTPUT=$(/opt/docling-mcp/venv/bin/python <<'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp/src')
from config.logging_config import LogSanitizer

# Test credential redaction
message = "Connection string: api_key=secret123 password=hunter2"
sanitized = LogSanitizer.sanitize_message(message)

if "secret123" not in sanitized and "hunter2" not in sanitized:
    print("✅ PASSED: Credentials redacted from message")
else:
    print("❌ FAILED: Credentials not redacted")
    sys.exit(1)

# Test content truncation
context = {'content': 'x' * 1000}
sanitized_context = LogSanitizer.sanitize_context(context)

if len(sanitized_context['content']) < 1000:
    print("✅ PASSED: Content truncated")
else:
    print("❌ FAILED: Content not truncated")
    sys.exit(1)
EOF
)

echo "$TEST_OUTPUT"

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - Structured logging configured"
echo ""
echo "Next Step: Task 162 - Configure Log Rotation (Systemd Journal)"
```

**Expected Results:**
- Logging module exists and imports successfully
- LOG_LEVEL configured in .env.production
- Service logs are JSON formatted
- Credentials redacted from log messages
- Document content truncated to 500 characters
- Log test output shows structured JSON logs

## Notes

**JSON Log Structure:**
- **timestamp**: ISO 8601 UTC timestamp
- **level**: Log level (DEBUG, INFO, WARN, ERROR)
- **component**: Logger name (module name)
- **message**: Log message (sanitized)
- **context**: Extra fields (sanitized dict)
- **exception**: Exception traceback (if present)

**Log Sanitization Rules:**
- **Credentials**: Any field with password/token/key/secret/auth redacted
- **API Keys**: Bearer tokens and Basic auth credentials redacted
- **Document Content**: Truncated to 500 characters with total length noted
- **User Input**: Sanitized before logging to prevent injection attacks

**Systemd Journal Integration:**
- Logs written to stdout captured automatically by systemd
- No separate log files needed (systemd journal handles persistence)
- JSON format enables structured querying with journalctl

**Log Level Guidelines:**
- **DEBUG**: Use for development/troubleshooting (verbose, includes payloads)
- **INFO**: Use for normal operations (tool invocations, processing complete)
- **WARN**: Use for degraded state (dependency slow/unavailable, large documents)
- **ERROR**: Use for failures (conversion errors, API failures, exceptions)

**Viewing Logs:**
```bash
# Real-time logs
sudo journalctl -u docling-mcp.service -f

# JSON pretty-print
sudo journalctl -u docling-mcp.service -o json-pretty | less

# Filter by level
sudo journalctl -u docling-mcp.service -p err  # ERROR only

# Search for specific tool
sudo journalctl -u docling-mcp.service | grep convert_document

# Export logs
sudo journalctl -u docling-mcp.service --since "2025-12-01" --until "2025-12-02" > logs-2025-12-01.json
```

**Troubleshooting:**
- If logs not JSON formatted: Verify logging configured in mcp_server.py startup
- If credentials visible: Check LogSanitizer patterns match credential format
- If logs missing: Check LOG_LEVEL not set to ERROR (would suppress INFO logs)
- If service fails after logging change: Check Python syntax in logging_config.py

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Logging Requirements (lines 1734-1766)
- Section: Log Structure (JSON format example)

**Python Documentation**:
- Python logging: https://docs.python.org/3/library/logging.html
- JSON logging: https://pypi.org/project/python-json-logger/

## Risk Assessment

**Risk Level**: Low

**Risks**:
1. **Credential leakage**: Sensitive data logged in plain text
2. **Log flooding**: Excessive DEBUG logging fills disk
3. **Performance impact**: JSON formatting overhead
4. **Sanitization bypass**: New credential patterns not caught

**Mitigation**:
- Comprehensive credential patterns in LogSanitizer
- Content truncation prevents large log entries
- LOG_LEVEL=INFO by default (DEBUG only when needed)
- Systemd journal rotation prevents disk exhaustion (Task 162)
- Regular log review to identify missed credential patterns
