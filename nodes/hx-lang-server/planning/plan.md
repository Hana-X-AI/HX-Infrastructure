# Deployment Plan: hx-lang-server

**Document Type:** Deployment Plan
**Version:** 1.0
**Date:** 2025-12-04
**Status:** APPROVED
**Specification:** `/nodes/hx-lang-server/specification/node-spec.md` (APPROVED v2.1)
**Task Framework:** `/nodes/hx-lang-server/tasks/task-framework.md`

---

## Summary

Deploy hx-lang-server as the central LangGraph orchestration hub for HX-Infrastructure, providing:
- Multi-agent workflow coordination using LangGraph v0.3.x supervisor pattern
- Intelligent query routing across Ollama1 (general) and Ollama2 (code) servers
- RAG integration via LightRAG with 64KB context support
- MCP client integration for tool access via FastMCP gateway
- RESTful API via FastAPI with webhook support for n8n integration
- Durable state persistence via PostgreSQL checkpointing
- Ephemeral session caching via Redis

---

## Technical Context

| Attribute | Value |
|-----------|-------|
| **Service Type** | Agent Orchestration Platform |
| **Technology** | LangGraph v0.3.x, FastAPI, Python 3.11+ |
| **Target Node** | hx-lang-server.hx.dev.local (192.168.10.226) |
| **Node OS** | Ubuntu 24.04 LTS |
| **Installation Method** | pip (virtual environment) + systemd |
| **Port Requirements** | 8100 (API), 8101 (Health/Metrics) |
| **Storage Requirements** | 50GB (20GB application, 30GB logs/cache) |
| **Memory Requirements** | 16GB minimum (per spec) |
| **CPU Requirements** | 4 cores minimum (8 recommended) |
| **Network Requirements** | HX internal network only (192.168.10.0/24) |

---

## Constitution Check

### Documentation-First Requirements
- [x] Service spec.md is complete and reviewed (APPROVED v2.1)
- [x] All NEEDS CLARIFICATION resolved (4 CAIO decisions applied)
- [x] Deployment plan documented before execution

### Test-Driven Deployment Requirements
- [x] Test suite defined (78 test cases per Julia Santos)
- [ ] Tests will be written before deployment execution
- [ ] Service will remain non-operational until all tests pass

### Single Responsibility
- [x] Service has clear, focused purpose (agent orchestration)
- [x] Dependencies explicitly documented (6 external services)
- [x] No scope creep beyond spec requirements

### Quality Over Speed
- [x] Thorough planning prioritized over quick deployment
- [x] All edge cases considered (from 12 specialist reviews)
- [x] Rollback strategy defined

### Infrastructure Philosophy Compliance
- [x] Bare metal deployment (Ubuntu 24.04 LTS)
- [x] systemd service management
- [x] Manual procedures only (no Ansible playbooks)
- [x] Ansible Vault for credentials only
- [x] NO FIREWALL configuration

---

## Deployment Architecture

### Service Components

```
hx-lang-server.hx.dev.local (192.168.10.226)
├── /opt/hx-lang-server/
│   ├── venv/                    # Python virtual environment
│   ├── app/                     # Application code
│   │   ├── main.py              # FastAPI application
│   │   ├── config.py            # Pydantic settings
│   │   ├── agents/              # LangGraph agents
│   │   │   ├── supervisor.py    # Supervisor agent
│   │   │   ├── rag_agent.py     # RAG worker
│   │   │   ├── code_agent.py    # Code worker
│   │   │   └── tool_agent.py    # Tool worker
│   │   ├── services/            # Integration clients
│   │   │   ├── postgres.py      # Checkpoint client
│   │   │   ├── redis.py         # Session manager
│   │   │   ├── ollama.py        # LLM clients
│   │   │   ├── lightrag.py      # RAG client
│   │   │   └── mcp.py           # MCP client
│   │   ├── models/              # Pydantic models
│   │   └── utils/               # Utilities
│   ├── .env                     # Environment configuration
│   └── requirements.txt         # Python dependencies
├── /var/log/hx-lang-server/     # Log files
├── /etc/systemd/system/         # systemd service unit
└── Ansible Vault                # Credentials (postgres, etc.)
```

### Network Topology

```
┌──────────────────────────────────────────────────────────────┐
│                    hx-lang-server                             │
│                   192.168.10.226                              │
│                   Ports: 8100, 8101                           │
└───────────┬─────────────┬────────────┬────────────┬──────────┘
            │             │            │            │
            ▼             ▼            ▼            ▼
┌───────────────┐ ┌───────────────┐ ┌──────────┐ ┌──────────────┐
│ hx-postgres   │ │ hx-redis      │ │ Ollama   │ │ hx-fastmcp   │
│ 192.168.10.211│ │ 192.168.10.210│ │ Servers  │ │ Server       │
│ Port: 5432    │ │ Port: 6379    │ │ .204/205 │ │              │
└───────────────┘ └───────────────┘ └──────────┘ └──────────────┘
                                         │
                                         ▼
                                  ┌──────────────┐
                                  │ hx-literag   │
                                  │ .219:8020    │
                                  └──────────────┘
```

---

## Phased Delivery

### Phase 1: Core LangGraph + RAG
**Scope:**
- Supervisor agent with 3 workers (RAG, Code, Tool)
- PostgreSQL checkpoint persistence
- Redis session caching
- Multi-Ollama routing
- LightRAG integration
- Basic FastAPI endpoints

**Success Criteria:**
- SC-001 through SC-014 from specification

### Phase 2: n8n + MCP Integration
**Scope:**
- n8n HTTP integration
- Webhook callbacks
- Crawl4AI MCP tool invocation

**Success Criteria:**
- SC-015 through SC-017 from specification

---

## Work Stream Summary

| Work Stream | Owner | Tasks | Dependencies |
|-------------|-------|-------|--------------|
| 1. Identity & Infrastructure | Frank Lucas | 6-8 | None |
| 2. System Dependencies | William Chen | 8-10 | WS-1 |
| 3. Core Framework | Sophia | 6-8 | WS-2 |
| 4. PostgreSQL Integration | Trinity | 6-8 | WS-2 |
| 5. Redis Integration | Sri | 6-8 | WS-2 |
| 6. LangGraph Agents | Sophia | 12-15 | WS-3,4,5,7,8 |
| 7. Ollama Integration | Jim | 6-8 | WS-2 |
| 8. LightRAG Integration | Andy | 6-8 | WS-2 |
| 9. MCP Integration | George | 6-8 | WS-3 |
| 10. FastAPI Application | Bob | 12-15 | WS-6 |
| 11. n8n Integration | Isabella | 6-8 | WS-10 |
| 12. Logging & Monitoring | William Chen | 4-6 | WS-10 |
| 13. Service Deployment | William Chen | 4-6 | WS-12 |
| 14. Testing & Validation | Julia Santos | 78 tests | WS-13 |

**Total Estimated Tasks:** 90-120 + 78 test cases

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| LangGraph v0.3.x breaking changes | Medium | High | Test with v0.3.0 first, validate checkpoint compatibility |
| Ollama 64KB context not available | Low | High | Verify model configurations on ollama1/ollama2 before deployment |
| PostgreSQL connection pool exhaustion | Low | Medium | Configure pool size appropriately, implement connection retry |
| Redis connection failures | Low | Medium | Implement circuit breaker pattern |
| MCP protocol v1.1 incompatibility | Low | Medium | Implement feature detection fallback to v1.0 |
| Memory exhaustion under load | Medium | High | Validate 16GB sufficient with load testing |

---

## Rollback Strategy

### Rollback Triggers
- Critical test failures
- Service instability (>5% error rate)
- Resource exhaustion (memory >90%)
- Integration failures with dependencies

### Rollback Steps
1. Stop hx-lang-server service: `sudo systemctl stop hx-lang-server`
2. Disable service: `sudo systemctl disable hx-lang-server`
3. Archive configuration: `mv /opt/hx-lang-server /opt/hx-lang-server.rollback-$(date +%Y%m%d)`
4. Remove systemd unit: `sudo rm /etc/systemd/system/hx-lang-server.service`
5. Reload systemd: `sudo systemctl daemon-reload`
6. Verify rollback: Confirm service no longer running

### Rollback Time Estimate
- Full rollback: 15 minutes
- Partial rollback (config only): 5 minutes

---

## Progress Tracking

### Phase Status
- [x] Phase 0: Prerequisites validated
- [x] Phase 1: Task framework created
- [x] Phase 2: Team evaluated (10 specialists confirmed)
- [x] Phase 3: Team task generation (90 tasks from 10 specialists)
- [x] Phase 4: Task synthesis (task-synthesis.md created)
- [x] Phase 5: Test suite generation (78 test cases by Julia)
- [x] Phase 6: CAIO approval (2025-12-04)
- [x] Phase 7: Post-approval setup

### Gate Status
- [x] Specification approved (v2.1)
- [x] Constitution check passed
- [x] Task framework created
- [x] Task breakdown complete (90 tasks synthesized)
- [x] Test suite created (78 test cases)
- [x] Task breakdown approved by CAIO (2025-12-04)
- [x] Test suite approved by CAIO (2025-12-04)
- [x] Ready for execution

### Task Generation Summary
| Specialist | Work Stream | Tasks Generated |
|------------|-------------|-----------------|
| Frank Lucas | Identity & Infrastructure | 4 (001-004) |
| William Chen | System Dependencies | 6 (011-016) |
| Sophia | Core Framework | 6 (021-026) |
| Trinity | PostgreSQL | 6 (031-036) |
| Sri | Redis | 8 (041-048) |
| Sophia | LangGraph Agents | 11 (051-061) |
| Jim | Ollama | 8 (071-078) |
| Andy | LightRAG | 7 (081-087) |
| George | MCP Client | 7 (091-097) |
| Bob | FastAPI | 13 (101-113) |
| Isabella | n8n (Phase 2) | 7 (121-127) |
| William Chen | Logging | 3 (131-133) |
| William Chen | Service | 4 (141-144) |
| **Total** | **13 Work Streams** | **90 tasks** |

---

## Next Steps

1. **Execute Task Breakdown:** Begin with Work Stream 1 (Identity & Infrastructure)
2. **Follow Execution Sequence:** Prerequisites → Core Framework → Integration Layer → Agents → API → Service
3. **Run Tests:** Execute test suite after each phase completion
4. **Promote to Operational:** After all 78 tests pass

---

**Plan Created By:** Agent Zero
**Date:** 2025-12-04
**Last Updated:** 2025-12-04
**Approved By:** CAIO (2025-12-04)
**Status:** APPROVED - Ready for Execution
