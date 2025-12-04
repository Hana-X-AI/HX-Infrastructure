# Task 131: Configure Structured Logging

**Task ID**: hx-lang-server-task-131
**Phase**: Configuration (Logging & Monitoring)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 015 (Core Python Dependencies - structlog), Task 101+ (FastAPI Application)
**Estimated Effort**: 1.5 hours

---

## Objective

Configure structured JSON logging for hx-lang-server using structlog with log sanitization (credential redaction, content truncation), systemd journal integration, and proper log levels for operational visibility.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 015 (Core Python Dependencies) completed - structlog installed
- [ ] Application code directory exists (/opt/hx-lang-server/src)
- [ ] Service account hx-lang-server exists

---

## Pre-Execution Validation

**CRITICAL**: Check if logging configuration already exists BEFORE implementing.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check logging configuration
LOGGING_CONFIG="/opt/hx-lang-server/src/config/logging_config.py"

echo "Checking logging configuration status..."

if [ -f "$LOGGING_CONFIG" ]; then
    echo "Logging configuration exists: $LOGGING_CONFIG"
    echo ""
    echo "Checking for structured logging components..."

    # Check for structlog usage
    if grep -q "structlog" "$LOGGING_CONFIG" 2>/dev/null; then
        echo "structlog configured"
    else
        echo "WARNING: structlog not detected in configuration"
    fi

    # Check for log sanitization
    if grep -qE "sanitize|redact" "$LOGGING_CONFIG" 2>/dev/null; then
        echo "Log sanitization configured"
    else
        echo "WARNING: Log sanitization not detected"
    fi

    echo ""
    echo "VALIDATION RESULT: Logging configuration exists"
    echo "ACTION: Review existing configuration, skip if satisfactory"
else
    echo "VALIDATION RESULT: Logging configuration does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Review existing configuration, skip if correct
**If Not Complete**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Create Configuration Directory

```bash
# Create configuration directory structure
APP_DIR="/opt/hx-lang-server"
CONFIG_DIR="$APP_DIR/src/config"

echo "Creating configuration directory..."

sudo mkdir -p "$CONFIG_DIR"

# Create __init__.py for Python package
sudo touch "$CONFIG_DIR/__init__.py"

# Set ownership
sudo chown -R hx-lang-server:hx-lang-server "$CONFIG_DIR" 2>/dev/null || \
    sudo chown -R hx-lang-server "$CONFIG_DIR" 2>/dev/null || true

echo "Configuration directory created: $CONFIG_DIR"
ls -la "$CONFIG_DIR"
```

### Step 2: Create Logging Configuration Module

```bash
# Create logging configuration module
APP_DIR="/opt/hx-lang-server"
LOGGING_CONFIG="$APP_DIR/src/config/logging_config.py"

echo "Creating logging configuration module..."

sudo tee "$LOGGING_CONFIG" > /dev/null <<'PYEOF'
"""
Logging Configuration for hx-lang-server
Structured JSON logging with sanitization and systemd journal integration.

Task: hx-lang-server-task-131
Date: 2025-12-04
"""

import logging
import sys
import re
from typing import Any, Dict, Optional
from datetime import datetime, timezone

import structlog
from structlog.types import EventDict, WrappedLogger


class LogSanitizer:
    """Sanitize sensitive data from log messages and context."""

    # Patterns for credential detection
    CREDENTIAL_PATTERNS = [
        re.compile(r'(api[_-]?key|token|password|secret|auth|credential)["\s:=]+([^\s"\']+)', re.IGNORECASE),
        re.compile(r'(Bearer)\s+([A-Za-z0-9\-._~+/]+=*)', re.IGNORECASE),
        re.compile(r'(Basic)\s+([A-Za-z0-9+/]+=*)', re.IGNORECASE),
        re.compile(r'(POSTGRES_PASSWORD|REDIS_PASSWORD|API_KEY)[=]([^\s]+)', re.IGNORECASE),
    ]

    # Maximum content length in logs
    MAX_CONTENT_LENGTH = 500

    # Keys that should always be redacted
    REDACT_KEYS = {
        'password', 'token', 'api_key', 'apikey', 'secret',
        'auth', 'credential', 'authorization', 'bearer',
        'postgres_password', 'redis_password',
    }

    # Keys that should be truncated
    TRUNCATE_KEYS = {
        'content', 'document_content', 'text', 'raw_content',
        'body', 'response_body', 'request_body', 'rag_context',
    }

    @classmethod
    def sanitize_message(cls, message: str) -> str:
        """Redact credentials from log message."""
        sanitized = message

        for pattern in cls.CREDENTIAL_PATTERNS:
            sanitized = pattern.sub(r'\1=***REDACTED***', sanitized)

        return sanitized

    @classmethod
    def sanitize_value(cls, key: str, value: Any) -> Any:
        """Sanitize a single value based on its key."""
        key_lower = key.lower()

        # Check if key should be redacted
        if any(redact_key in key_lower for redact_key in cls.REDACT_KEYS):
            return '***REDACTED***'

        # Check if value should be truncated
        if key_lower in cls.TRUNCATE_KEYS:
            if isinstance(value, str) and len(value) > cls.MAX_CONTENT_LENGTH:
                return f"{value[:cls.MAX_CONTENT_LENGTH]}... [truncated, total: {len(value)} chars]"

        # Recursively sanitize nested dicts
        if isinstance(value, dict):
            return cls.sanitize_context(value)

        # Recursively sanitize lists
        if isinstance(value, list):
            return [cls.sanitize_value(key, item) for item in value[:10]]  # Limit list length

        return value

    @classmethod
    def sanitize_context(cls, context: Dict[str, Any]) -> Dict[str, Any]:
        """Sanitize context dictionary."""
        return {key: cls.sanitize_value(key, value) for key, value in context.items()}


def sanitize_event(
    logger: WrappedLogger,
    method_name: str,
    event_dict: EventDict
) -> EventDict:
    """Structlog processor to sanitize event dictionary."""
    # Sanitize the event message
    if 'event' in event_dict:
        event_dict['event'] = LogSanitizer.sanitize_message(str(event_dict['event']))

    # Sanitize all other fields
    sanitized = {}
    for key, value in event_dict.items():
        if key == 'event':
            sanitized[key] = event_dict[key]  # Already sanitized above
        else:
            sanitized[key] = LogSanitizer.sanitize_value(key, value)

    return sanitized


def add_timestamp(
    logger: WrappedLogger,
    method_name: str,
    event_dict: EventDict
) -> EventDict:
    """Add ISO 8601 UTC timestamp to event."""
    event_dict['timestamp'] = datetime.now(timezone.utc).isoformat()
    return event_dict


def add_service_context(
    logger: WrappedLogger,
    method_name: str,
    event_dict: EventDict
) -> EventDict:
    """Add service-level context to event."""
    event_dict['service'] = 'hx-lang-server'
    event_dict['node'] = 'hx-lang-server.hx.dev.local'
    return event_dict


def configure_logging(
    log_level: str = "INFO",
    json_format: bool = True,
    add_service_info: bool = True,
) -> None:
    """
    Configure structured logging for hx-lang-server.

    Args:
        log_level: Logging level (DEBUG, INFO, WARN, ERROR)
        json_format: Output as JSON (True) or console format (False)
        add_service_info: Add service context to all logs
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

    # Configure standard library logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=level,
    )

    # Build processor chain
    processors = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        add_timestamp,
        sanitize_event,
    ]

    if add_service_info:
        processors.append(add_service_context)

    processors.extend([
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ])

    # Add final renderer
    if json_format:
        processors.append(structlog.processors.JSONRenderer())
    else:
        processors.append(structlog.dev.ConsoleRenderer(colors=True))

    # Configure structlog
    structlog.configure(
        processors=processors,
        wrapper_class=structlog.make_filtering_bound_logger(level),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # Log configuration complete
    logger = structlog.get_logger()
    logger.info(
        "logging_configured",
        log_level=log_level,
        json_format=json_format,
        add_service_info=add_service_info,
    )


def get_logger(name: Optional[str] = None) -> structlog.BoundLogger:
    """
    Get a logger instance.

    Args:
        name: Logger name (typically module name)

    Returns:
        Bound structlog logger
    """
    logger = structlog.get_logger()
    if name:
        logger = logger.bind(component=name)
    return logger
PYEOF

echo "Logging configuration module created: $LOGGING_CONFIG"
```

### Step 3: Create Config Package __init__.py

```bash
# Update __init__.py for config package
APP_DIR="/opt/hx-lang-server"
INIT_FILE="$APP_DIR/src/config/__init__.py"

echo "Creating config package __init__.py..."

sudo tee "$INIT_FILE" > /dev/null <<'PYEOF'
"""Configuration package for hx-lang-server."""

from .logging_config import configure_logging, get_logger, LogSanitizer

__all__ = ['configure_logging', 'get_logger', 'LogSanitizer']
PYEOF

echo "Config package __init__.py created"
```

### Step 4: Set Ownership and Permissions

```bash
# Set ownership and permissions
APP_DIR="/opt/hx-lang-server"

echo "Setting ownership and permissions..."

# Set ownership
sudo chown -R hx-lang-server:hx-lang-server "$APP_DIR/src/config" 2>/dev/null || \
    sudo chown -R hx-lang-server "$APP_DIR/src/config" 2>/dev/null || true

# Set permissions
sudo chmod 755 "$APP_DIR/src/config"
sudo chmod 644 "$APP_DIR/src/config"/*.py

ls -la "$APP_DIR/src/config"
echo "Ownership and permissions configured"
```

### Step 5: Test Logging Configuration

```bash
# Test logging configuration
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Testing logging configuration..."

"$VENV_PATH/bin/python" <<'PYEOF'
import sys
sys.path.insert(0, '/opt/hx-lang-server/src')

from config.logging_config import configure_logging, get_logger, LogSanitizer

# Configure logging
configure_logging(log_level='INFO', json_format=True)

# Get logger
logger = get_logger('test_module')

# Test different log levels
logger.debug("Debug message (should not appear at INFO level)")
logger.info("Info message", extra_field="test_value", count=42)
logger.warning("Warning message")
logger.error("Error message", error_code=500)

# Test credential sanitization
logger.info("Testing credential redaction", api_key="secret123", password="hunter2")

# Test content truncation
long_content = 'x' * 1000
logger.info("Testing content truncation", content=long_content)

# Test LogSanitizer directly
message = "Connection string: api_key=secret123 password=hunter2"
sanitized = LogSanitizer.sanitize_message(message)
print(f"\nSanitization test:")
print(f"Original: {message}")
print(f"Sanitized: {sanitized}")

# Verify credentials are redacted
if "secret123" not in sanitized and "hunter2" not in sanitized:
    print("\n*** Logging configuration test PASSED ***")
else:
    print("\n*** WARNING: Credentials not properly redacted ***")
    sys.exit(1)
PYEOF

if [ $? -eq 0 ]; then
    echo "Logging configuration test passed"
else
    echo "ERROR: Logging configuration test failed"
    exit 1
fi
```

### Step 6: Document Logging Configuration

```bash
# Document logging configuration
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/logging-configuration.txt" > /dev/null <<'EOF'
# Logging Configuration
# Date: 2025-12-04
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-131

## Logging Module
Location: /opt/hx-lang-server/src/config/logging_config.py
Library: structlog

## Log Format
Format: JSON (structured)
Output: stdout (captured by systemd journal)

## Log Levels
- DEBUG: Detailed diagnostics (agent state, LangGraph steps)
- INFO: Normal operations (agent invocations, completions)
- WARN: Degraded state (Ollama slow, LightRAG unavailable)
- ERROR: Failures (checkpoint errors, API failures)

## JSON Log Structure
{
  "timestamp": "2025-12-04T10:30:15.123456+00:00",
  "level": "info",
  "service": "hx-lang-server",
  "node": "hx-lang-server.hx.dev.local",
  "component": "supervisor_agent",
  "event": "agent_invocation_complete",
  "thread_id": "abc123",
  "query_type": "rag",
  "duration_ms": 3500
}

## Log Sanitization

### Credential Redaction
The following are automatically redacted:
- api_key, apikey, API_KEY
- password, PASSWORD
- token, TOKEN
- secret, SECRET
- auth, authorization
- bearer tokens
- POSTGRES_PASSWORD, REDIS_PASSWORD

### Content Truncation
Long content is truncated to 500 characters:
- content, document_content
- text, raw_content
- body, request_body, response_body
- rag_context

## Environment Variable
LOG_LEVEL=INFO (configured in .env)

## Usage in Application

```python
from config.logging_config import configure_logging, get_logger

# Configure at startup
configure_logging(log_level='INFO')

# Get logger in module
logger = get_logger(__name__)

# Log with context
logger.info("operation_complete",
    thread_id="abc123",
    duration_ms=100,
    status="success"
)
```

## View Logs

# Real-time logs
sudo journalctl -u hx-lang-server.service -f

# Last 100 lines
sudo journalctl -u hx-lang-server.service -n 100

# Filter by level (ERROR only)
sudo journalctl -u hx-lang-server.service -p err

# JSON formatted output
sudo journalctl -u hx-lang-server.service -o json-pretty

# Search for specific event
sudo journalctl -u hx-lang-server.service | grep "agent_invocation"
EOF

echo "Logging configuration documented: $DOC_DIR/logging-configuration.txt"
cat "$DOC_DIR/logging-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Logging Module | /opt/hx-lang-server/src/config/logging_config.py | structlog configuration |
| Config Package | /opt/hx-lang-server/src/config/__init__.py | Package exports |
| Documentation | /opt/hx-lang-server/deployment-docs/logging-configuration.txt | Usage guide |

---

## Verification

**Validation Commands:**

```bash
echo "=== Structured Logging Configuration Validation ==="

VENV_PATH="/opt/hx-lang-server/venv"
VALIDATION_PASSED=true

# Check 1: Logging module exists
echo "1. Logging Module:"
if [ -f "/opt/hx-lang-server/src/config/logging_config.py" ]; then
    echo "PASSED: Logging module exists"
else
    echo "FAILED: Logging module not found"
    VALIDATION_PASSED=false
fi

# Check 2: Module syntax valid
echo ""
echo "2. Module Syntax:"
if "$VENV_PATH/bin/python" -m py_compile /opt/hx-lang-server/src/config/logging_config.py 2>/dev/null; then
    echo "PASSED: Module syntax valid"
else
    echo "FAILED: Module syntax errors"
    VALIDATION_PASSED=false
fi

# Check 3: Imports work
echo ""
echo "3. Module Imports:"
if "$VENV_PATH/bin/python" -c "import sys; sys.path.insert(0, '/opt/hx-lang-server/src'); from config.logging_config import configure_logging, get_logger" 2>/dev/null; then
    echo "PASSED: Module imports successfully"
else
    echo "FAILED: Module import errors"
    VALIDATION_PASSED=false
fi

# Check 4: Credential sanitization
echo ""
echo "4. Credential Sanitization:"
"$VENV_PATH/bin/python" <<'PYEOF'
import sys
sys.path.insert(0, '/opt/hx-lang-server/src')
from config.logging_config import LogSanitizer

# Test credential redaction
message = "api_key=secret123 password=hunter2"
sanitized = LogSanitizer.sanitize_message(message)

if "secret123" not in sanitized and "hunter2" not in sanitized:
    print("PASSED: Credentials redacted")
else:
    print("FAILED: Credentials visible")
    sys.exit(1)
PYEOF

if [ $? -eq 0 ]; then
    echo "Credential sanitization working"
else
    VALIDATION_PASSED=false
fi

# Check 5: Content truncation
echo ""
echo "5. Content Truncation:"
"$VENV_PATH/bin/python" <<'PYEOF'
import sys
sys.path.insert(0, '/opt/hx-lang-server/src')
from config.logging_config import LogSanitizer

# Test content truncation
context = {'content': 'x' * 1000}
sanitized = LogSanitizer.sanitize_context(context)

if len(sanitized['content']) < 1000:
    print("PASSED: Content truncated")
else:
    print("FAILED: Content not truncated")
    sys.exit(1)
PYEOF

if [ $? -eq 0 ]; then
    echo "Content truncation working"
else
    VALIDATION_PASSED=false
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Structured logging configured"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- Logging module exists at specified path
- Module compiles without syntax errors
- Module imports successfully
- Credentials redacted from messages
- Long content truncated to 500 characters

---

## Rollback Procedure

Remove logging configuration if needed:

```bash
# Remove logging configuration
echo "Removing logging configuration..."

rm -f /opt/hx-lang-server/src/config/logging_config.py
rm -f /opt/hx-lang-server/src/config/__init__.py
rmdir /opt/hx-lang-server/src/config 2>/dev/null || true

echo "Logging configuration removed"
```

---

## Notes

**structlog vs standard logging:**
- structlog provides structured/contextual logging
- JSON output for machine parsing
- Context binding for request tracing
- Works with systemd journal

**Sanitization Rules:**
- Credentials: Redacted via pattern matching and key detection
- Content: Truncated to prevent log bloat
- Nested objects: Recursively sanitized

**Integration Points:**
- FastAPI: Configure at application startup
- LangGraph: Log agent state transitions
- Dependencies: Log connection health

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Monitoring & Observability - Logging (lines 773-789)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 12: Logging & Monitoring (Task Range 131-140)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Credential leakage**: Sensitive data logged in plain text
   - Mitigation: Comprehensive sanitization patterns
2. **Log flooding**: Excessive DEBUG logging
   - Mitigation: LOG_LEVEL=INFO by default
3. **Performance impact**: JSON formatting overhead
   - Mitigation: structlog optimized for performance

**Dependencies Blocked:**
- Task 141+ (Service Deployment) requires logging for troubleshooting
- All operational monitoring depends on structured logs
