# Task 126: Configure LiteLLM Environment Variables

**Assigned To**: shane-black
**Estimated Effort**: 1 hour
**Dependencies**: Task 008 (Environment file configuration)
**Status**: Not Started

## Objective

Configure environment variables in `/etc/docling-mcp/env/.env` for LiteLLM integration including base URL, API key (optional), timeout settings, rate limiting, and caching parameters.

## Pre-Execution Validation

**CRITICAL**: Check if LiteLLM environment variables already configured BEFORE adding them to prevent duplication.

```bash
# Check if LiteLLM configuration exists in .env
if grep -q "LITELLM_API_BASE" /etc/docling-mcp/env/.env 2>/dev/null; then
    echo "✅ VALIDATION RESULT: LiteLLM environment variables already configured"
    echo "ACTION: SKIP task execution - validate configuration values instead"
    echo "NEXT: Verify base URL and timeout settings"
    exit 0
else
    echo "❌ VALIDATION RESULT: LiteLLM environment variables NOT configured"
    echo "ACTION: PROCEED with environment variable configuration"
fi
```

**If Variables Exist**: Skip to Validation section, verify configuration correctness

**If Variables Do Not Exist**: Continue with Implementation Steps below

---

## Context

The LiteLLM integration requires several environment variables to configure:

1. **Base URL**: LiteLLM server endpoint (hx-litellm-server.hx.dev.local:4000)
2. **API Key**: Optional for Ollama models, required for external providers (OpenAI, Anthropic)
3. **Timeout Settings**: Connect, read, write timeouts for HTTP requests
4. **Rate Limiting**: Maximum concurrent requests to prevent overwhelming LiteLLM Router
5. **Caching**: Cache TTL in days, cache enable/disable flag
6. **Circuit Breaker**: Failure threshold, recovery timeout

These variables are loaded by Pydantic configuration classes (Task 141) and consumed by LiteLLMClient (Task 121).

## Acceptance Criteria

- [ ] Environment variables added to `/etc/docling-mcp/env/.env`
- [ ] `LITELLM_API_BASE` set to `http://hx-litellm-server.hx.dev.local:4000`
- [ ] `LITELLM_API_KEY` commented out (optional, not required for Ollama)
- [ ] Timeout variables: `LITELLM_TIMEOUT_CONNECT`, `LITELLM_TIMEOUT_READ`, `LITELLM_TIMEOUT_WRITE`
- [ ] Rate limit variable: `LITELLM_RATE_LIMIT_CONCURRENT`
- [ ] Caching variables: `LITELLM_CACHE_ENABLED`, `LITELLM_CACHE_TTL_DAYS`
- [ ] Circuit breaker variables: `LITELLM_CIRCUIT_BREAKER_THRESHOLD`, `LITELLM_CIRCUIT_BREAKER_TIMEOUT`
- [ ] Variables documented with inline comments explaining purpose and valid values
- [ ] File ownership and permissions: `docling-mcp@hx.dev.local:domain users@hx.dev.local`, `0640`

## Implementation Steps

### Step 1: Backup Existing .env File

```bash
# Backup current .env file
sudo cp /etc/docling-mcp/env/.env /etc/docling-mcp/env/.env.bak-litellm

# Verify backup created
ls -la /etc/docling-mcp/env/.env.bak-litellm
```

### Step 2: Add LiteLLM Environment Variables

```bash
# Append LiteLLM configuration section to .env file
sudo -u docling-mcp@hx.dev.local tee -a /etc/docling-mcp/env/.env > /dev/null << 'EOF'

# ============================================================================
# LiteLLM Integration Configuration
# ============================================================================
# LiteLLM gateway provides unified LLM API access with automatic model routing
# and fallback across Ollama1/2/3 servers for entity extraction tasks.
#
# Integration Point: hx-litellm-server.hx.dev.local:4000
# Models: gemma3:27b (general), qwen3-coder:30b (technical), gpt-oss:20b (fallback)
# ============================================================================

# LiteLLM Server Base URL
# Purpose: HTTP endpoint for LiteLLM gateway (OpenAI-compatible API)
# Default: http://hx-litellm-server.hx.dev.local:4000
# Valid Values: HTTP/HTTPS URL with port
LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000

# LiteLLM API Key (Optional)
# Purpose: Authentication for external LLM providers (OpenAI, Anthropic, Groq)
# Default: None (not required for Ollama models)
# Valid Values: API key string (e.g., sk-... for OpenAI)
# Note: Uncomment and set value when using external providers
# LITELLM_API_KEY=

# HTTP Timeout Configuration
# Purpose: Prevent indefinite hangs on slow model inference or network issues
# Connect Timeout: Time to establish TCP connection (seconds)
LITELLM_TIMEOUT_CONNECT=10

# Read Timeout: Time to wait for response body (seconds, allows for slow LLM inference)
LITELLM_TIMEOUT_READ=120

# Write Timeout: Time to send request body (seconds)
LITELLM_TIMEOUT_WRITE=5

# Rate Limiting Configuration
# Purpose: Prevent overwhelming LiteLLM Router with too many concurrent requests
# Valid Values: 1-100 (recommended: 10 for single instance, 5 for multi-instance)
LITELLM_RATE_LIMIT_CONCURRENT=10

# Response Caching Configuration
# Purpose: Cache entity extraction results in Redis to reduce API costs 15-30%
# Cache Enabled: true/false flag to enable/disable caching layer
LITELLM_CACHE_ENABLED=true

# Cache TTL: Time-to-live in days (7 days balances hit rate vs freshness)
# Valid Values: 1-30 days
LITELLM_CACHE_TTL_DAYS=7

# Circuit Breaker Configuration
# Purpose: Fail-fast when LiteLLM server experiences sustained failures
# Failure Threshold: Number of consecutive failures before opening circuit
# Valid Values: 3-10 (recommended: 5)
LITELLM_CIRCUIT_BREAKER_THRESHOLD=5

# Recovery Timeout: Seconds to wait before attempting recovery from OPEN state
# Valid Values: 30-300 seconds (recommended: 60)
LITELLM_CIRCUIT_BREAKER_TIMEOUT=60

# Model Routing Configuration
# Purpose: Override default model selection for entity extraction tasks
# Uncomment to override defaults (defaults defined in model_router.py)
# LITELLM_GENERAL_PRIMARY_MODEL=ollama_chat/gemma3:27b
# LITELLM_GENERAL_FALLBACK_MODEL=ollama_chat/gpt-oss:20b
# LITELLM_TECHNICAL_PRIMARY_MODEL=ollama_chat/qwen3-coder:30b
# LITELLM_TECHNICAL_FALLBACK_MODEL=ollama_chat/gemma3:27b

# LLM Parameter Configuration
# Purpose: Control entity extraction quality and determinism
# Temperature: Sampling temperature (0.0-2.0, lower = more deterministic)
# Valid Values: 0.0-2.0 (recommended: 0.1 for factual entity extraction)
LITELLM_TEMPERATURE=0.1

# Top-P: Nucleus sampling parameter (0.0-1.0)
# Valid Values: 0.0-1.0 (recommended: 0.9)
LITELLM_TOP_P=0.9

# Max Tokens: Maximum tokens to generate (limits response length)
# Valid Values: 512-8192 (recommended: 2048 for ~100 entities)
LITELLM_MAX_TOKENS=2048

EOF
```

### Step 3: Verify Environment Variable Syntax

```bash
# Check for syntax errors in .env file (should return exit code 0)
source /etc/docling-mcp/env/.env && echo "✅ .env file syntax valid" || echo "❌ .env file syntax error"

# Verify specific variables set correctly
source /etc/docling-mcp/env/.env && echo "LITELLM_API_BASE=${LITELLM_API_BASE}"
source /etc/docling-mcp/env/.env && echo "LITELLM_CACHE_ENABLED=${LITELLM_CACHE_ENABLED}"
source /etc/docling-mcp/env/.env && echo "LITELLM_CIRCUIT_BREAKER_THRESHOLD=${LITELLM_CIRCUIT_BREAKER_THRESHOLD}"
```

### Step 4: Verify File Ownership and Permissions

```bash
# Verify ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /etc/docling-mcp/env/.env

# Set permissions (0640 = owner read/write, group read, no world access)
sudo chmod 0640 /etc/docling-mcp/env/.env

# Verify permissions
ls -la /etc/docling-mcp/env/.env
# Expected output: -rw-r----- 1 docling-mcp@hx.dev.local domain users@hx.dev.local ... .env
```

### Step 5: Test Environment Variable Loading in Python

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test loading environment variables
python3 << 'EOF'
import os
from pathlib import Path

# Load .env file
env_file = Path("/etc/docling-mcp/env/.env")
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

# Verify LiteLLM variables loaded
required_vars = [
    "LITELLM_API_BASE",
    "LITELLM_TIMEOUT_CONNECT",
    "LITELLM_TIMEOUT_READ",
    "LITELLM_CACHE_ENABLED",
    "LITELLM_CIRCUIT_BREAKER_THRESHOLD",
]

for var in required_vars:
    value = os.getenv(var)
    assert value is not None, f"Missing required variable: {var}"
    print(f"✅ {var}={value}")

print("\n✅ All LiteLLM environment variables loaded successfully")
EOF

# Deactivate venv
deactivate
```

## Validation

**Validation Commands:**

```bash
# 1. Verify .env file exists
test -f /etc/docling-mcp/env/.env && echo "PASS: .env file exists" || echo "FAIL: .env file missing"

# 2. Verify LITELLM_API_BASE configured
grep -q "^LITELLM_API_BASE=" /etc/docling-mcp/env/.env && echo "PASS: Base URL configured" || echo "FAIL: Base URL missing"

# 3. Verify hostname used (not IP address)
grep "^LITELLM_API_BASE=" /etc/docling-mcp/env/.env | grep -q "hx-litellm-server.hx.dev.local" && echo "PASS: Hostname-based URL" || echo "FAIL: IP address used"

# 4. Verify timeout variables present
grep -q "^LITELLM_TIMEOUT_CONNECT=" /etc/docling-mcp/env/.env && grep -q "^LITELLM_TIMEOUT_READ=" /etc/docling-mcp/env/.env && echo "PASS: Timeout variables configured" || echo "FAIL: Timeout variables missing"

# 5. Verify caching variables present
grep -q "^LITELLM_CACHE_ENABLED=" /etc/docling-mcp/env/.env && grep -q "^LITELLM_CACHE_TTL_DAYS=" /etc/docling-mcp/env/.env && echo "PASS: Caching variables configured" || echo "FAIL: Caching variables missing"

# 6. Verify circuit breaker variables present
grep -q "^LITELLM_CIRCUIT_BREAKER_THRESHOLD=" /etc/docling-mcp/env/.env && grep -q "^LITELLM_CIRCUIT_BREAKER_TIMEOUT=" /etc/docling-mcp/env/.env && echo "PASS: Circuit breaker variables configured" || echo "FAIL: Circuit breaker variables missing"

# 7. Verify file ownership
stat -c '%U:%G' /etc/docling-mcp/env/.env | grep -q "docling-mcp@hx.dev.local:domain users@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# 8. Verify file permissions
stat -c '%a' /etc/docling-mcp/env/.env | grep -q "640" && echo "PASS: Permissions correct (0640)" || echo "FAIL: Permissions incorrect"

# 9. Verify no syntax errors
bash -c "source /etc/docling-mcp/env/.env 2>&1" | grep -q -v "error" && echo "PASS: No syntax errors" || echo "FAIL: Syntax error in .env"

# 10. Verify API key commented out (optional)
grep "^# LITELLM_API_KEY=" /etc/docling-mcp/env/.env && echo "PASS: API key commented out (optional)" || grep -q "^LITELLM_API_KEY=$" /etc/docling-mcp/env/.env && echo "PASS: API key empty (optional)" || echo "INFO: API key set (for external providers)"
```

**Expected Outcomes:**
- All validation commands return "PASS" or "INFO"
- LITELLM_API_BASE uses hostname (hx-litellm-server.hx.dev.local) not IP address
- Timeout, caching, circuit breaker, and rate limiting variables configured
- File permissions 0640 (owner read/write, group read, no world access)
- No syntax errors when sourcing .env file

## Notes

### Timeout Configuration Rationale

**Connect Timeout (10s)**:
- Time to establish TCP connection to hx-litellm-server
- 10s allows for DNS resolution + TCP handshake + TLS negotiation
- Typical: 100-500ms, 10s provides safety margin

**Read Timeout (120s)**:
- Time to wait for LLM response (includes model inference time)
- Ollama model inference: 1.5-6.5s typical, 120s handles P99.9 (cold start, high load)
- Too short: Premature timeout on slow requests
- Too long: Indefinite hangs on stuck requests

**Write Timeout (5s)**:
- Time to send request body to server
- Request body is small (<5KB for entity extraction prompt)
- 5s is generous for local network

### Rate Limiting Strategy

**Concurrent Request Limit (10)**:
- Prevents overwhelming LiteLLM Router with too many in-flight requests
- LiteLLM Router has rate limits per model (configured on hx-litellm-server)
- Client-side rate limiting prevents hitting Router limits

**Single vs Multi-Instance**:
- Single instance: 10 concurrent requests safe
- Multi-instance (3 instances): 5 concurrent per instance = 15 total (within Router limits)

**Backpressure**: When limit reached, additional requests queue in asyncio semaphore

### Cache TTL Selection

**7 Days Balances**:
- **Hit Rate**: Longer TTL = higher hit rate (documents re-processed within window)
- **Freshness**: Shorter TTL = fresher results (prompt updates, model changes)
- **Memory**: Longer TTL = more cached entries (Redis memory usage)

**Typical Scenarios**:
- Document templates (contracts, forms): High hit rate, 7-day window appropriate
- One-off documents: No hit rate benefit, cache expires before re-use
- Repeated processing: Hit rate depends on processing frequency vs TTL

**Override**: Set `LITELLM_CACHE_TTL_DAYS=30` for higher hit rate (accept staleness risk)

### Circuit Breaker Thresholds

**Failure Threshold (5)**:
- Number of consecutive failures before circuit opens
- Too low (3): False positives on transient errors
- Too high (10): Slow detection of sustained failures
- 5 balances sensitivity vs false positives

**Recovery Timeout (60s)**:
- Time to wait before testing recovery (OPEN → HALF_OPEN transition)
- Too short (10s): Premature recovery attempts during service restart
- Too long (300s): Slow recovery after transient issue resolved
- 60s allows service restart to complete

### LLM Parameter Configuration

**Temperature (0.1)**:
- Controls randomness in LLM output
- 0.0 = deterministic (same input → same output)
- 2.0 = highly random (creative text generation)
- 0.1 = low randomness (factual entity extraction, slight variation for robustness)

**Top-P (0.9)**:
- Nucleus sampling: sample from top 90% probability mass
- Reduces likelihood of low-probability (nonsensical) tokens
- 0.9 is standard for factual tasks

**Max Tokens (2048)**:
- Limits response length
- Entity extraction for 1-page document: ~50 entities × ~40 tokens = 2,000 tokens
- 2048 provides safety margin
- Longer responses truncated (but unlikely for entity extraction)

### Hostname vs IP Address

**ALWAYS use hostname**: `hx-litellm-server.hx.dev.local`

**NEVER use IP address**: `192.168.10.212` (INCORRECT)

**Rationale**:
- DNS allows service migration without config changes
- IP addresses may change during infrastructure updates
- Hostnames enable load balancing and failover
- HX-Infrastructure standard: all services use DNS hostnames

### API Key Security

**Optional for Ollama**: Internal Ollama models require no authentication

**Required for External Providers**: OpenAI, Anthropic, Groq require API keys

**Security**:
- API keys stored in Ansible Vault (Task 001)
- Environment variable populated from Vault at service start
- .env file has 0640 permissions (not world-readable)
- systemd EnvironmentFile directive loads variables securely

**Future**: Implement API key rotation (90-day cycle, Task 141 enhancement)

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 4.3.4: LiteLLM Integration)
- **LiteLLM Enhancement**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/shane-litellm-summary.md`
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 8)
- **Task 008**: Environment file configuration (dependency)
- **Task 141**: Pydantic configuration management (consumer of these variables)

## Risk Assessment

**Risk**: Low
- Environment variable configuration is straightforward
- Default values are production-tested
- Missing variables cause clear error messages at startup
- .env file permissions prevent unauthorized access

**Mitigation**:
- Inline documentation explains each variable purpose
- Validation steps verify configuration correctness
- Backup created before modifications
- Hostname-based URLs prevent IP address hardcoding
- Commented optional variables (API key) prevent accidental commits
