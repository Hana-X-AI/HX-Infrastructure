# Task Framework: hx-lang-server

**Document Type:** Task Framework
**Version:** 1.0
**Date:** 2025-12-04
**Status:** DRAFT
**Specification Reference:** `/nodes/hx-lang-server/specification/node-spec.md` (APPROVED v2.1)

---

## Overview

This framework defines the task structure for deploying hx-lang-server as the central LangGraph orchestration hub for HX-Infrastructure.

**Target Server:** hx-lang-server.hx.dev.local (192.168.10.226)
**Technical Lead:** Sophia (LangGraph Orchestration SME)

---

## Work Streams Identified

Based on the approved specification, the following work streams have been identified:

### Work Stream 1: Identity & Infrastructure Setup (Frank Lucas)
**Task Range:** 001-010
- Service account creation in Samba AD
- DNS record registration
- Directory structure creation
- Ansible Vault credential storage

### Work Stream 2: System Dependencies (William Chen)
**Task Range:** 011-020
- Python 3.11+ installation and configuration
- System package dependencies
- Virtual environment setup
- systemd service configuration

### Work Stream 3: Core Framework Installation (Sophia)
**Task Range:** 021-030
- LangGraph v0.3.x installation
- LangChain installation
- langchain-ollama installation
- langchain-mcp-adapters installation

### Work Stream 4: PostgreSQL Integration (Trinity)
**Task Range:** 031-040
- Database creation on hx-postgres-server
- User provisioning with appropriate permissions
- langgraph-checkpoint-postgres configuration
- Connection parameter validation (autocommit, row_factory)

### Work Stream 5: Redis Integration (Sri)
**Task Range:** 041-050
- Redis connection pool configuration (50 connections)
- Session manager implementation
- Key namespace configuration (`hx-lang-server:` prefix)
- TTL strategy implementation

### Work Stream 6: LangGraph Agent Implementation (Sophia)
**Task Range:** 051-070
- Supervisor agent implementation
- RAG Agent worker implementation
- Code Agent worker implementation
- Tool Agent worker implementation
- State schema implementation (AgentState with schema_version)
- Query classifier implementation

### Work Stream 7: Ollama Integration (Jim)
**Task Range:** 071-080
- Ollama1 (general) connection configuration
- Ollama2 (code) connection configuration
- 64KB context size configuration for RAG/Code
- Model routing implementation

### Work Stream 8: LightRAG Integration (Andy)
**Task Range:** 081-090
- LightRAG HTTP client configuration
- Adaptive retrieval implementation
- Query mode support (local, global, hybrid, mix)

### Work Stream 9: MCP Client Integration (George)
**Task Range:** 091-100
- langchain-mcp-adapters configuration
- FastMCP gateway connection
- Tool namespace handling
- MCP v1.1 feature detection

### Work Stream 10: FastAPI Application (Bob)
**Task Range:** 101-120
- FastAPI application structure
- API endpoint implementation (/invoke, /stream, /health, /ready)
- Webhook callback system
- Pydantic models and validation
- OpenAPI documentation

### Work Stream 11: n8n Integration (Isabella) - Phase 2
**Task Range:** 121-130
- HTTP endpoint configuration for n8n
- Webhook callback registration
- Custom node requirements documentation

### Work Stream 12: Logging & Monitoring (William Chen)
**Task Range:** 131-140
- Structured logging with structlog
- Metrics implementation
- Health check endpoint validation

### Work Stream 13: Service Deployment (William Chen)
**Task Range:** 141-150
- systemd service unit creation
- Environment file configuration
- Service enablement and startup
- Service validation

### Work Stream 14: Testing & Validation (Julia Santos)
**Task Range:** 151-200
- Test suite generation (78 test cases)
- Deployment validation tests
- Functionality tests
- Integration tests
- Health check tests
- End-to-end tests

---

## Task Numbering Schema

```
hx-lang-server-task-XXX-<description>.md

Where XXX:
- 001-010: Identity & Infrastructure (Frank)
- 011-020: System Dependencies (William)
- 021-030: Core Framework (Sophia)
- 031-040: PostgreSQL Integration (Trinity)
- 041-050: Redis Integration (Sri)
- 051-070: LangGraph Agents (Sophia)
- 071-080: Ollama Integration (Jim)
- 081-090: LightRAG Integration (Andy)
- 091-100: MCP Integration (George)
- 101-120: FastAPI Application (Bob)
- 121-130: n8n Integration (Isabella)
- 131-140: Logging & Monitoring (William)
- 141-150: Service Deployment (William)
- 151-200: Testing & Validation (Julia)
```

---

## Phase Mapping

### Pre-Deployment Phase
- Work Streams 1-2 (Identity, System Dependencies)

### Installation Phase
- Work Streams 3-5 (Core Framework, PostgreSQL, Redis)

### Implementation Phase
- Work Streams 6-11 (Agents, Ollama, LightRAG, MCP, FastAPI, n8n)

### Configuration Phase
- Work Stream 12 (Logging & Monitoring)

### Deployment Phase
- Work Stream 13 (Service Deployment)

### Validation Phase
- Work Stream 14 (Testing & Validation)

---

## Parallel Execution Opportunities

The following work streams can execute in parallel:

**Parallel Group 1 (after prerequisites):**
- Work Stream 4 (PostgreSQL) [P]
- Work Stream 5 (Redis) [P]
- Work Stream 7 (Ollama) [P] - configuration only
- Work Stream 8 (LightRAG) [P] - configuration only

**Parallel Group 2 (after core framework):**
- Work Stream 9 (MCP) [P]
- Work Stream 10 (FastAPI) [P] - structure only

**Sequential Requirements:**
- Work Stream 1 → Work Stream 2 → Work Stream 3
- Work Stream 6 depends on: 3, 4, 5, 7, 8
- Work Stream 10 depends on: 6
- Work Stream 13 depends on: all implementation work streams
- Work Stream 14 depends on: 13

---

## Agent Assignments

| Agent | Work Streams | Task Count (Est.) |
|-------|--------------|-------------------|
| Frank Lucas | 1 | 6-8 tasks |
| William Chen | 2, 12, 13 | 15-20 tasks |
| Sophia | 3, 6 | 15-20 tasks |
| Trinity | 4 | 6-8 tasks |
| Sri | 5 | 6-8 tasks |
| Jim | 7 | 6-8 tasks |
| Andy | 8 | 6-8 tasks |
| George | 9 | 6-8 tasks |
| Bob | 10 | 12-15 tasks |
| Isabella | 11 | 6-8 tasks |
| Julia Santos | 14 | 78 test cases |

**Estimated Total Tasks:** 90-120 (excluding test cases)

---

## Dependencies from Specification

### External Service Dependencies (hostnames)
1. hx-postgres-server.hx.dev.local:5432 - Checkpoint persistence
2. hx-redis-server.hx.dev.local:6379 - Session caching
3. hx-ollama1-server.hx.dev.local:11434 - General LLM
4. hx-ollama2-server.hx.dev.local:11434 - Code LLM
5. hx-literag-server.hx.dev.local:8020 - RAG pipeline
6. hx-fastmcp-server.hx.dev.local:8000 - MCP gateway

### Python Dependencies (from spec)
- langgraph>=0.3.0
- langchain>=0.3.0
- langchain-ollama>=0.2.0
- langchain-mcp-adapters>=0.1.0
- langgraph-checkpoint-postgres>=2.0.0
- psycopg[binary]>=3.2.0
- redis>=5.0.0
- fastapi>=0.115.0
- uvicorn>=0.32.0
- pydantic>=2.9.0
- pydantic-settings>=2.6.0
- httpx>=0.27.0
- aiohttp>=3.10.0
- python-dotenv>=1.0.0
- structlog>=24.0.0

---

## Critical Path

```
Frank (Identity) → William (System) → Sophia (Framework)
    ↓
[Parallel: Trinity (Postgres), Sri (Redis), Jim (Ollama), Andy (LightRAG)]
    ↓
Sophia (Agents) + George (MCP)
    ↓
Bob (FastAPI) + Isabella (n8n)
    ↓
William (Logging & Service)
    ↓
Julia (Testing)
```

**Estimated Critical Path Duration:** 8-12 hours (parallel optimized)

---

## Next Steps

1. Agent Zero evaluates team membership (Phase 2)
2. Team members generate detailed tasks for their work streams (Phase 3)
3. Agent Zero synthesizes and sequences all tasks (Phase 4)
4. CAIO reviews and approves task breakdown (Phase 5)
5. Julia generates comprehensive test suite (Phase 6)
6. Post-approval updates (Phase 7)

---

**Framework Created By:** Agent Zero
**Date:** 2025-12-04
