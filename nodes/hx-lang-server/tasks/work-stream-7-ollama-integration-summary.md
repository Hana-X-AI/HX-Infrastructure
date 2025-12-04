# Work Stream 7: Ollama Integration Summary

**Work Stream:** 7 - Ollama Integration
**Task Range:** 071-080
**Assigned Agent:** Jim (Ollama SME)
**Date Created:** 2025-12-04
**Specification Reference:** `/nodes/hx-lang-server/specification/node-spec.md` (v2.1)

---

## Overview

Work Stream 7 implements Ollama integration for hx-lang-server, enabling multi-model routing based on query classification. The implementation routes general/RAG/tool queries to hx-ollama1-server (gemma3:27b) and code queries to hx-ollama2-server (qwen2.5-coder/qwen3-coder).

**Key CAIO Decision Applied:** 64KB context size for both RAG and Code operations.

---

## Tasks Created

| Task ID | Description | Status | Est. Time |
|---------|-------------|--------|-----------|
| 071 | Configure Ollama1 (general) connection | Not Started | 30 min |
| 072 | Configure Ollama2 (code) connection | Not Started | 30 min |
| 073 | Configure 64KB context for RAG operations | Not Started | 45 min |
| 074 | Configure 64KB context for Code operations | Not Started | 45 min |
| 075 | Implement model routing based on query classification | Not Started | 60 min |
| 076 | Implement connection health checks | Not Started | 45 min |
| 077 | Implement retry logic with backoff | Not Started | 45 min |
| 078 | Create integration tests for Ollama connectivity | Not Started | 60 min |

**Total Estimated Time:** 6 hours

---

## Ollama Routing Configuration

From Specification (Ollama Routing Table):

| Query Type | Target Server | Model | Min Context |
|------------|---------------|-------|-------------|
| general | hx-ollama1-server.hx.dev.local:11434 | gemma3:27b | 8KB |
| code | hx-ollama2-server.hx.dev.local:11434 | qwen2.5-coder:14b | 64KB |
| rag | hx-ollama1-server.hx.dev.local:11434 | gemma3:27b | 64KB |
| tool | hx-ollama1-server.hx.dev.local:11434 | gemma3:27b | 8KB |

---

## Dependencies

### Upstream Dependencies (Required Before This Work Stream)
- **Task 023:** Install langchain-ollama (Work Stream 3)
- **Task 052:** Query classifier implementation (Work Stream 6)

### Downstream Dependencies (Depend on This Work Stream)
- **Work Stream 6 (054, 055):** RAG Agent and Code Agent workers need Ollama connections
- **Work Stream 8 (081-090):** LightRAG integration uses RAG LLM
- **Work Stream 10 (101-120):** FastAPI health endpoint includes Ollama status

---

## Key Files to Create

### LLM Client Modules
- `/opt/hx-lang-server/app/llm/ollama_general.py` - General/RAG/Tool LLM client
- `/opt/hx-lang-server/app/llm/ollama_code.py` - Code LLM client
- `/opt/hx-lang-server/app/llm/ollama_router.py` - Query routing logic
- `/opt/hx-lang-server/app/llm/router_integration.py` - Classifier integration
- `/opt/hx-lang-server/app/llm/retry_config.py` - Retry and circuit breaker

### Health Check Module
- `/opt/hx-lang-server/app/health/ollama_health.py` - Ollama health checks

### Test Files
- `/opt/hx-lang-server/tests/integration/ollama/test_ollama_connection.py`
- `/opt/hx-lang-server/tests/integration/ollama/test_64kb_context.py`
- `/opt/hx-lang-server/tests/integration/ollama/test_model_routing.py`
- `/opt/hx-lang-server/tests/integration/ollama/test_health_checks.py`
- `/opt/hx-lang-server/tests/integration/ollama/test_retry_logic.py`

---

## Environment Variables

```bash
# Ollama General Configuration (hx-ollama1-server)
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b
OLLAMA_GENERAL_TIMEOUT=60

# Ollama Code Configuration (hx-ollama2-server)
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_CODE_MODEL=qwen2.5-coder:14b
OLLAMA_CODE_CONTEXT=65536
OLLAMA_CODE_TIMEOUT=120

# RAG Context Configuration (CAIO Decision: 64KB)
OLLAMA_RAG_CONTEXT_SIZE=65536
OLLAMA_RAG_MODEL=gemma3:27b
OLLAMA_RAG_TEMPERATURE=0.3

# Retry Configuration
OLLAMA_RETRY_MAX_ATTEMPTS=3
OLLAMA_RETRY_INITIAL_DELAY=1.0
OLLAMA_RETRY_MAX_DELAY=30.0

# Circuit Breaker Configuration
OLLAMA_CIRCUIT_FAILURE_THRESHOLD=5
OLLAMA_CIRCUIT_RESET_TIMEOUT=60

# Routing Configuration
OLLAMA_ROUTE_GENERAL_TO=hx-ollama1-server.hx.dev.local:11434
OLLAMA_ROUTE_CODE_TO=hx-ollama2-server.hx.dev.local:11434
OLLAMA_ROUTE_RAG_TO=hx-ollama1-server.hx.dev.local:11434
OLLAMA_ROUTE_TOOL_TO=hx-ollama1-server.hx.dev.local:11434
```

---

## Specification Requirements Addressed

| Requirement | Task | Description |
|-------------|------|-------------|
| FR-010 | 071 | Route general queries to hx-ollama1-server |
| FR-011 | 072 | Route code queries to hx-ollama2-server |
| FR-013 | 073, 074 | Validate 64KB context for RAG and Code |
| FR-003 | 075 | Route queries based on classification |
| FR-024 | 076 | Health check endpoint includes Ollama status |
| Operational | 077 | Retry with exponential backoff |

---

## Integration Test Coverage

| Category | Test Count | Test IDs |
|----------|------------|----------|
| Connection | 8 | TC-OLLAMA-001 to 008 |
| 64KB Context | 4 | TC-OLLAMA-009 to 012 |
| Routing | 7 | TC-OLLAMA-013 to 019 |
| Health | 4 | TC-OLLAMA-020 to 023 |
| Retry | 7 | TC-OLLAMA-024 to 030 |
| **Total** | **30** | |

---

## Verification Checklist

- [ ] DNS resolution works for both Ollama hostnames
- [ ] HTTP connectivity to both servers on port 11434
- [ ] gemma3:27b available on hx-ollama1-server
- [ ] Code model (qwen2.5-coder or qwen3-coder) available on hx-ollama2-server
- [ ] 64KB context accepted by both servers
- [ ] Query routing correctly maps to servers
- [ ] Health checks return accurate status
- [ ] Retry logic handles transient failures
- [ ] Circuit breaker opens on repeated failures
- [ ] All 30 integration tests pass

---

## Notes

1. **Hostname Usage:** All external service references use hostnames (e.g., hx-ollama1-server.hx.dev.local), not IP addresses, per HX-Infrastructure standards.

2. **Model Flexibility:** Tasks 072 and 074 accommodate either qwen2.5-coder:14b (specification) or qwen3-coder:30b (current deployment) through model override configuration.

3. **64KB Context:** CAIO decision requires 64KB context for both RAG (entity extraction) and Code (complex generation) operations. Tasks 073 and 074 validate and enforce this minimum.

4. **Circuit Breaker:** Prevents cascade failures by stopping requests to failing Ollama servers after 5 consecutive failures. Service degrades gracefully rather than timing out on every request.

5. **No Automation:** All tasks document manual procedures only, per HX-Infrastructure philosophy.

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
