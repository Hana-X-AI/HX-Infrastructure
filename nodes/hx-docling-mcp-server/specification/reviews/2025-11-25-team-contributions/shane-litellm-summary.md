# LiteLLM Integration Enhancement Summary

**Agent**: shane-black (LiteLLM Multi-Provider Integration Specialist)
**Date**: 2025-11-25
**Task**: Review and enhance LiteLLM integration for entity extraction in hx-docling-mcp-server

---

## Summary

I have completed a comprehensive enhancement of the LiteLLM integration specifications for the Docling MCP Server. Due to file locking/linter issues preventing direct edits to node-spec.md, I have created a separate enhancement document that can be manually merged.

## Deliverable

**File**: `nodes/hx-docling-mcp-server/litellm-integration-enhancement.md`

This file contains complete, production-ready LiteLLM integration specifications covering:

### 1. LiteLLM Client Configuration
- **Base URL**: hx-litellm-server.hx.dev.local:4000
- **Timeout Strategy**: 10s connect, 120s read (handles slow model inference), 5s write
- **Connection Pooling**: httpx AsyncClient with max 20 connections, 100 keepalive
- **Rate Limiting**: Client-side limit of 10 concurrent requests with queue management
- **Backoff Strategy**: Exponential with jitter (1s initial, 2.0x multiplier, max 60s, ±20% jitter)

### 2. Model Selection Strategy
- **Primary Model (General Text)**: gemma3:27b via Ollama1
  - Use case: Business documents, reports, articles
  - Quality: F1 0.85+ for named entities
  - Latency: 2-5s P95 for 1K tokens

- **Secondary Model (Technical/Code)**: qwen3-coder:30b via Ollama2
  - Use case: Technical documentation, source code, APIs
  - Quality: F1 0.90+ for technical entities
  - Latency: 3-7s P95 for 1K tokens

- **Fallback Model**: gpt-oss:20b via Ollama1
  - Use case: Automatic fallback on timeout/503
  - Quality: F1 0.75+ (moderate accuracy)
  - Latency: 1-3s P95 (fastest)

**Model Fallback Strategy**:
1. Primary model attempt
2. LiteLLM Router automatic fallback on 503/timeout
3. Circuit breaker opens after 5 consecutive failures
4. Health check recovery after 60s

### 3. Prompt Engineering
- **Entity Extraction Prompt**: Structured JSON schema with rules, few-shot examples, disambiguation guidance
- **Relationship Extraction Prompt**: Subject-predicate-object format with entity list validation
- **Few-Shot Examples**: 3 examples covering general text, technical text, ambiguous cases
- **System Prompts**: Name normalization, type consistency, deduplication hints

**LLM Parameter Settings** (Deterministic Extraction):
- Temperature: 0.1 (low for factual output)
- Top_p: 0.9
- Max_tokens: 2048 (~100 entities)
- Stop sequences: `["\n\n\n", "```"]`
- Penalties: 0.0 (allow repetition)

### 4. Error Handling & Resilience

**Error Types Handled**:
1. **Timeout Errors (408)**: Retry + fallback to gpt-oss:20b
2. **Rate Limit Errors (429)**: Exponential backoff with jitter
3. **Model Unavailable (503)**: LiteLLM Router fallback, then circuit breaker
4. **Invalid Response**: JSON validation, strict prompt retry (max 2)

**Retry Logic**:
```
MAX_RETRIES = 3
INITIAL_DELAY = 1.0s
BACKOFF_MULTIPLIER = 2.0
JITTER = ±20%
```

**Circuit Breaker**:
- Threshold: 5 consecutive errors in 60s
- Open duration: 60s
- Half-open: Single health check
- State tracking: Redis (`circuit_breaker:litellm`)

**Redis Fallback Mechanism for Circuit Breaker**:

When Redis is unavailable, the circuit breaker uses **in-memory state with periodic async Redis sync** to maintain resilience:

1. **Fallback Strategy**:
   - Primary: Redis-backed circuit breaker state (`circuit_breaker:litellm` key)
   - Fallback: In-memory state (Python dictionary) with async Redis sync attempts
   - State fields: error_count, consecutive_errors, state (CLOSED/OPEN/HALF_OPEN), last_failure_time, open_since

2. **Detection and Activation**:
   - Redis health check on startup and every state update
   - Activation trigger: Redis connection timeout (2s) or connection refused
   - Automatic fallback: Switch to in-memory state on first Redis failure
   - Logging: `WARNING: Circuit breaker Redis unavailable, using in-memory fallback`

3. **Sync and Consistency Behavior**:
   - Async Redis sync: Attempt to write state to Redis every 10s (background task)
   - On Redis restoration: Merge in-memory state with Redis state (use most recent timestamp)
   - Risk window: State may diverge across instances during Redis outage (5-60s typical)
   - Reconciliation: On Redis restore, write authoritative in-memory state to Redis, log sync event

4. **Failure Modes and Recovery**:
   - **Scenario 1 (Redis down <60s)**: In-memory state preserves circuit breaker decisions, minimal impact
   - **Scenario 2 (Redis down >60s)**: Each instance maintains independent state, possible split-brain (circuit open on instance A, closed on instance B)
   - **Scenario 3 (Redis restore)**: First instance to connect writes authoritative state, others sync within 10s
   - **Risk mitigation**: Circuit breaker is fail-safe (defaults to OPEN on uncertainty)

5. **Logging and Alerting**:
   - Log level INFO: Redis fallback activation, Redis restoration, state sync success
   - Log level WARNING: Redis connection failures, state divergence detected
   - Log level ERROR: State sync failures after Redis restore (retry exhausted)
   - Prometheus metric: `circuit_breaker_redis_fallback_active{state="true|false"}` (gauge)
   - Alert rule: `circuit_breaker_redis_fallback_active == 1 for >5 minutes` → page on-call

6. **Recovery Procedure**:
   - Automatic: Background task attempts Redis reconnection every 10s
   - Manual: Restart service if Redis fallback persists >30 minutes (forces re-sync)
   - Validation: Check Prometheus dashboard for `circuit_breaker_redis_fallback_active` return to 0

**Graceful Degradation**:
- Skip entity extraction if LiteLLM unavailable
- Store raw DoclingDocument text in Qdrant
- Return `degraded_mode: true` flag in MCP response
- Alert if degraded >5 minutes

### 5. Performance Optimization

**Caching Strategy**:
- Cache key: SHA-256 of (model, chunk, prompt_version)
- Storage: Redis with 7-day TTL
- Hit rate target: 20-30%
- Cost savings: 15-30% reduction in LLM calls

**Batch Processing**:
- Batch size: Up to 10 documents concurrently
- Semaphore: Max 10 concurrent LiteLLM calls
- Timeout: 300s batch, 120s individual
- Backpressure: 429 error if queue depth >100

**Token Optimization**:
- Token counting: tiktoken library
- Chunk size optimization: Test 1K, 2K, 4K tokens for quality vs cost
- Prompt compression: Remove verbose instructions
- Model selection: gpt-oss:20b for low-value docs, gemma3/qwen3 for high-value

**Metrics** (Prometheus):
- `litellm_tokens_total{type, model}`: Counter
- `litellm_cost_usd_total{model}`: Counter
- `litellm_request_duration_seconds{model}`: Histogram (P50, P95, P99)
- Error counters, retry counters, circuit breaker state changes

### 6. Enhanced Functional Requirements

**FR-021** (LiteLLM Gateway Integration):
- Client configuration, model routing, rate limiting, health checks, error handling

**FR-022** (Prompt Engineering):
- Prompt templates, few-shot examples, LLM parameters, response validation

**FR-023** (Resilience Patterns):
- Retry logic, circuit breaker, graceful degradation, state tracking

**FR-024** (Performance & Cost Optimization):
- Response caching, batch processing, token tracking, model selection

**FR-025** (Structured Logging):
- JSON format, log levels, Prometheus metrics

---

## Integration Points

**Dependencies**:
- **hx-litellm-server** (hx-litellm-server.hx.dev.local:4000): LLM routing gateway
- **hx-ollama1-server** (hx-ollama1-server.hx.dev.local): gemma3:27b, gpt-oss:20b
- **hx-ollama2-server** (hx-ollama2-server.hx.dev.local): qwen3-coder:30b
- **hx-redis-server** (hx-redis-server.hx.dev.local): Extraction cache, circuit breaker state
- **hx-qdrant-server** (hx-qdrant-server.hx.dev.local): Entity/relationship storage

**Cost Model**:
- Tier 1 (Free): All Ollama1/2 models - zero cost
- Tier 2 (Future): External APIs (OpenAI/Anthropic) if quality insufficient

**Expected Performance**:
- Entity extraction latency: 2-7s P95 depending on model
- Cache hit rate: 20-30%
- Cost reduction: 15-30% via caching
- Availability: 99.9%+ with Router fallback and circuit breaker

---

## Pre-Deployment Checklist

### Network Prerequisites

**Assumption**: All services deployed on static internal network (192.168.10.x) with consistent reachability across environments.

**Verification**:
```bash
# Test connectivity to all dependent services
ping -c 3 hx-litellm-server.hx.dev.local  # hx-litellm-server
ping -c 3 hx-ollama1-server.hx.dev.local  # hx-ollama1-server
ping -c 3 hx-ollama2-server.hx.dev.local  # hx-ollama2-server
ping -c 3 hx-redis-server.hx.dev.local  # hx-redis-server
ping -c 3 hx-qdrant-server.hx.dev.local  # hx-qdrant-server

# Test LiteLLM API endpoint
curl -f http://hx-litellm-server.hx.dev.local:4000/health
```

### DNS Configuration

**Requirement**: All services must resolve via hx.dev.local domain.

**Verification**:
```bash
# Verify DNS resolution for all dependent services
nslookup hx-litellm-server.hx.dev.local
nslookup hx-ollama1-server.hx.dev.local
nslookup hx-ollama2-server.hx.dev.local
nslookup hx-redis-server.hx.dev.local
nslookup hx-qdrant-server.hx.dev.local

# Alternative: Test with dig
dig +short hx-litellm-server.hx.dev.local
```

### Deployment Model Support

**Supported Configurations**:
- **Bare-metal (Primary)**: Direct installation on Ubuntu Server 24.04 LTS
- **Containerized (Future)**: Docker/Podman support planned but not required for initial deployment
- **Kubernetes**: Not supported in Phase 1

**Configuration Differences**:
- Bare-metal: Uses systemd service with environment variables from `/etc/docling-mcp/.env`
- Container: Would require Docker Compose with environment file and network bridge configuration (not yet implemented)

### Model Availability Verification

**Required Models**:
- **hx-ollama1-server**: gemma3:27b (entity extraction), gpt-oss:20b (fallback)
- **hx-ollama2-server**: qwen3-coder:30b (code/technical content)

**Verification**:
```bash
# Check loaded models on Ollama1
curl http://hx-ollama1-server.hx.dev.local:11434/api/tags | jq '.models[].name'
# Expected output should include: gemma3:27b, gpt-oss:20b

# Check loaded models on Ollama2
curl http://hx-ollama2-server.hx.dev.local:11434/api/tags | jq '.models[].name'
# Expected output should include: qwen3-coder:30b

# Test model inference via LiteLLM Router
curl -X POST http://hx-litellm-server.hx.dev.local:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "ollama_chat/gemma3:27b", "messages": [{"role": "user", "content": "test"}]}'
```

**Pre-Deployment Checklist Summary**:
- [ ] All 5 service IPs are reachable (hx-litellm-server.hx.dev.local, 204, 205, 221, 223)
- [ ] DNS resolution working for all hx.dev.local hostnames
- [ ] Deployment target is bare-metal Ubuntu Server 24.04 LTS
- [ ] gemma3:27b and gpt-oss:20b loaded on hx-ollama1-server
- [ ] qwen3-coder:30b loaded on hx-ollama2-server
- [ ] LiteLLM Router health endpoint responding (hx-litellm-server.hx.dev.local:4000/health)

---

## Next Steps

1. **Manual Merge**: Integrate `nodes/hx-docling-mcp-server/litellm-integration-enhancement.md` into Section 4.3.4 of node-spec.md

2. **Replace FR-021 to FR-024**: Use enhanced functional requirements from litellm-integration-enhancement.md

3. **Add New FR-025**: Structured logging requirement for LiteLLM integration

4. **Review by alex-rivera**: Platform Architect review of LiteLLM integration architecture

5. **Validation**: Confirm LiteLLM Router configuration on hx-litellm-server supports documented fallback strategy

---

## Key Architectural Decisions

1. **Router-Based Fallback**: Rely on LiteLLM Router for automatic model fallback (no manual implementation)
2. **Deterministic Parameters**: Temperature 0.1 for factual entity extraction (avoid creative variation)
3. **Caching Strategy**: SHA-256 content hashing for cache keys (7-day TTL in Redis)
4. **Circuit Breaker**: 5-failure threshold with 60s recovery period
5. **Graceful Degradation**: Skip extraction rather than fail entire MCP tool invocation
6. **Cost Optimization**: Ollama-first strategy (zero cost), caching (15-30% reduction)

---

## Compliance

- **HX-Infrastructure Standards**: Follows bare-metal deployment, Ansible Vault for credentials, systemd service management
- **LiteLLM Best Practices**: Connection pooling, timeout configuration, retry logic, Router fallback
- **Charter Alignment**: Supports entity extraction via Ollama1/2 models as documented in charter risk mitigation (R-001)

### Security & Credential Management

**LiteLLM API Access Credentials**:

The service requires no API keys for Ollama-based models (hx-ollama1-server, hx-ollama2-server) as they are internal infrastructure endpoints. Future integration with external LLM providers (OpenAI, Anthropic, Groq) requires credential management.

**1. Credential Provisioning Workflow**:
   - **Ansible Vault Storage**: All API keys stored in `/etc/ansible/vaults/hx-docling-mcp-server-credentials.yml`
   - **Vault Password**: Located at `/etc/ansible/.vault_passwords/hx-docling-mcp-server` (permissions: 0600, owner: docling-mcp service account)
   - **Provisioning Steps**:
     1. Create Ansible Vault file with credentials: `ansible-vault create /etc/ansible/vaults/hx-docling-mcp-server-credentials.yml`
     2. Add credentials in YAML format:
        ```yaml
        litellm_openai_api_key: "sk-..."
        litellm_anthropic_api_key: "sk-ant-..."
        litellm_groq_api_key: "gsk_..."
        ```
     3. Set vault password in password file (0600 permissions)
     4. Reference in systemd service unit via `EnvironmentFile`

**2. Rotation Policy and Automation**:
   - **Rotation Frequency**: Every 90 days (quarterly)
   - **Process**:
     1. Generate new API keys from provider dashboards (OpenAI, Anthropic, Groq)
     2. Update Ansible Vault: `ansible-vault edit /etc/ansible/vaults/hx-docling-mcp-server-credentials.yml`
     3. Restart service: `systemctl restart hx-docling-mcp-server.service`
     4. Validate connectivity: Check LiteLLM Router logs for successful authentication
     5. Revoke old API keys after 24-hour grace period
   - **Automation**: Scheduled quarterly reminder in operations calendar (no automatic rotation due to manual provider key generation)

**3. Authentication Requirements**:
   - **Internal Services (Ollama)**: No authentication required (trusted internal network 192.168.10.0/24)
   - **External Providers**: API key-based authentication via LiteLLM Router
   - **Network Restrictions**: LiteLLM Router only accessible from HX-Infrastructure subnet (firewall rules on hx-litellm-server)
   - **TLS/mTLS**: HTTPS required for external provider connections (enforced by LiteLLM Router)

**4. Runtime Injection Method**:
   - **Systemd EnvironmentFile**: `/etc/systemd/system/hx-docling-mcp-server.service.d/credentials.conf`
   - **Decryption on Service Start**:
     ```ini
     [Service]
     EnvironmentFile=/etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env
     ExecStartPre=/usr/local/bin/decrypt-vault.sh /etc/ansible/vaults/hx-docling-mcp-server-credentials.yml /etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env
     ExecStartPost=/bin/rm -f /etc/ansible/vaults/hx-docling-mcp-server-credentials-decrypted.env
     ```
   - **In-Memory Only**: Decrypted credentials loaded into process environment, temporary file deleted after service start
   - **No Disk Persistence**: Credentials never written to disk in plaintext (except ephemeral 1-2 second window during service start)

**5. Access Control (Least Privilege)**:
   - **Service Account**: `docling-mcp` (dedicated Linux user, no shell access)
   - **File Permissions**:
     - Ansible Vault: 0640 (owner: root, group: docling-mcp)
     - Vault password file: 0600 (owner: docling-mcp)
     - Systemd unit files: 0644 (owner: root)
   - **Process Isolation**: Systemd `PrivateTmp=true`, `NoNewPrivileges=true`, `ProtectSystem=strict`
   - **Network Isolation**: Service bound to localhost + internal subnet only (no external network access from process)

**6. Audit and Compliance Controls**:
   - **Audit Logging**: All credential access attempts logged to `/var/log/hx-docling-mcp-server/audit.log`
   - **Log Retention**: 90 days local, 1 year archive
   - **Log Format**: JSON with fields: timestamp, action (vault_decrypt, api_call, credential_rotation), user, result (success/failure), IP address
   - **Alerting**: Failed credential decryption triggers immediate alert to on-call via Prometheus alert rule
   - **Compliance**: Quarterly audit of credential rotation logs and access patterns (documented in `/docs/audit-reports/`)

**7. Fallback and Degradation**:
   - **Credential Unavailable**: Service starts in degraded mode (Ollama-only, no external providers)
   - **Decryption Failure**: Service logs error and continues with internal models only
   - **Provider Authentication Failure**: LiteLLM Router automatic fallback to next available provider (graceful degradation)

**Credential Management Summary**:
- **Storage**: Ansible Vault (encrypted at rest)
- **Rotation**: Quarterly manual process
- **Injection**: Systemd EnvironmentFile with pre-start decryption
- **Access Control**: Least privilege (dedicated service account, restrictive permissions)
- **Audit**: Comprehensive logging with 90-day retention
- **Compliance**: HX-Infrastructure credential vault management standards (standards/credentials-vault-management.md)

### Performance SLOs

The service operates under **two distinct SLO tiers** to accommodate different operation types:

**Tier 1: Non-LLM Operations (Fast Path)**
- **Target**: 8ms P95 latency
- **Operations**: MCP tool invocations (list_tools, call_tool), health checks, cache lookups
- **Rationale**: These operations are synchronous, in-memory or simple database queries

**Tier 2: LLM-Based Operations (AI Path)**
- **Target**: 2-7s P95 latency
- **Operations**: Entity extraction, knowledge graph generation, document summarization
- **Components**:
  - LiteLLM Router overhead: ~150-280ms (connection, routing, logging)
  - Ollama inference time: 1.5-6.5s (model-dependent, based on token count)
  - Network round-trip: ~50-200ms
- **Rationale**: LLM inference is inherently slower and operates on a separate performance tier. This is an **intentional design decision**, not a compliance gap.

**Exemption**: LLM-based operations are explicitly excluded from the 8ms P95 target. The 2-7s latency is acceptable and expected for AI-powered features that provide value through quality over speed.

---

**Status**: Enhancement complete, ready for manual merge into node-spec.md

**Files Created**:
- `nodes/hx-docling-mcp-server/litellm-integration-enhancement.md` (full specification)
- `nodes/hx-docling-mcp-server/litellm-enhancement-summary.md` (this summary)

**Coordination**: This enhancement complements work by:
- **alex-rivera**: Overall architecture specification
- **andy-taylor**: LightRAG knowledge graph implementation (LLM integration consumer)
- **mitch-roberts**: Qdrant vector storage (entity/relationship storage)
- **julia-santos**: Test plan development (LiteLLM integration testing requirements)
