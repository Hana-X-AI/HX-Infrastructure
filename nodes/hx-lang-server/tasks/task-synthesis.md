# Task Synthesis: hx-lang-server

**Document Type:** Task Synthesis & Sequencing
**Version:** 1.0
**Date:** 2025-12-04
**Status:** APPROVED (2025-12-04)
**Specification Reference:** `/nodes/hx-lang-server/specification/node-spec.md` (APPROVED v2.1)

---

## Executive Summary

Agent Zero has synthesized **90 tasks** from **10 specialist contributions** across **13 work streams** for the hx-lang-server deployment. All tasks have been validated, sequenced, and dependency-mapped for execution readiness.

---

## Task Statistics

| Metric | Value |
|--------|-------|
| **Total Tasks** | 90 |
| **Work Streams** | 13 |
| **Specialists** | 10 |
| **Critical Path Tasks** | 24 |
| **Parallelizable Groups** | 4 |
| **Estimated Execution Time** | 40-50 hours |

---

## Task Inventory by Work Stream

### Work Stream 1: Identity & Infrastructure (Frank Lucas)
**Task Range:** 001-004 | **Count:** 4

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 001 | Create service account in Samba AD | None | P1 |
| 002 | Register DNS record | 001 | P1 |
| 003 | Create directory structure | 002 | P1 |
| 004 | Create Ansible Vault structure | 003 | P1 |

### Work Stream 2: System Dependencies (William Chen)
**Task Range:** 011-016 | **Count:** 6

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 011 | Verify Python installation | 004 | P1 |
| 012 | Install system packages | 011 | P1 |
| 013 | Create virtual environment | 012 | P1 |
| 014 | Configure pip | 013 | P1 |
| 015 | Install core Python dependencies | 014 | P1 |
| 016 | Install database client dependencies | 015 | P1 |

### Work Stream 3: Core Framework Installation (Sophia)
**Task Range:** 021-026 | **Count:** 6

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 021 | Install LangGraph framework | 016 | P1 |
| 022 | Install LangChain core | 021 | P1 |
| 023 | Install langchain-ollama | 022 | P1 |
| 024 | Install langchain-mcp-adapters | 023 | P1 |
| 025 | Install HTTP client packages | 024 | P1 |
| 026 | Verify core dependencies | 025 | P1 |

### Work Stream 4: PostgreSQL Integration (Trinity)
**Task Range:** 031-036 | **Count:** 6

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 031 | Create database hx-lang-server | 016 | P2 |
| 032 | Create database user | 031 | P2 |
| 033 | Configure pg_hba authentication | 032 | P2 |
| 034 | Create LangGraph checkpoint schema | 033 | P2 |
| 035 | Configure checkpoint connection | 034 | P2 |
| 036 | Verify checkpoint tables | 035 | P2 |

### Work Stream 5: Redis Integration (Sri)
**Task Range:** 041-048 | **Count:** 8

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 041 | Configure Redis connection pool | 016 | P2 |
| 042 | Implement session manager | 041 | P2 |
| 043 | Configure Redis key namespace | 042 | P2 |
| 044 | Implement TTL strategy | 043 | P2 |
| 045 | Implement LLM response cache | 044 | P2 |
| 046 | Implement rate limiting | 045 | P2 |
| 047 | Implement graceful degradation | 046 | P2 |
| 048 | Test Redis integration | 047 | P2 |

### Work Stream 6: LangGraph Agent Implementation (Sophia)
**Task Range:** 051-061 | **Count:** 11

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 051 | Implement agent state schema | 026, 036, 048 | P1 |
| 052 | Implement query classifier | 051 | P1 |
| 053 | Implement supervisor agent | 052 | P1 |
| 054 | Implement RAG agent worker | 053, 087 | P1 |
| 055 | Implement code agent worker | 053, 078 | P1 |
| 056 | Implement tool agent worker | 053, 097 | P1 |
| 057 | Implement general agent worker | 053, 078 | P1 |
| 058 | Register workers with supervisor | 054-057 | P1 |
| 059 | Implement graph compilation | 058 | P1 |
| 060 | Implement human-in-loop | 059 | P2 |
| 061 | Verify agent implementation | 059 | P1 |

### Work Stream 7: Ollama Integration (Jim)
**Task Range:** 071-078 | **Count:** 8

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 071 | Configure Ollama1 general connection | 026 | P2 |
| 072 | Configure Ollama2 code connection | 026 | P2 |
| 073 | Configure 64KB context for RAG | 071 | P2 |
| 074 | Configure 64KB context for Code | 072 | P2 |
| 075 | Implement model routing | 073, 074 | P2 |
| 076 | Implement connection health checks | 075 | P2 |
| 077 | Implement retry logic | 076 | P2 |
| 078 | Create Ollama integration tests | 077 | P2 |

### Work Stream 8: LightRAG Integration (Andy)
**Task Range:** 081-087 | **Count:** 7

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 081 | Configure LightRAG HTTP client | 026 | P2 |
| 082 | Implement adaptive retrieval | 081 | P2 |
| 083 | Configure query modes | 082 | P2 |
| 084 | Configure 64KB context handling | 083 | P2 |
| 085 | Implement document ingestion | 084 | P2 |
| 086 | Implement response caching | 085, 048 | P2 |
| 087 | Create LightRAG integration tests | 086 | P2 |

### Work Stream 9: MCP Client Integration (George)
**Task Range:** 091-097 | **Count:** 7

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 091 | Configure langchain-mcp-adapters client | 024 | P2 |
| 092 | Configure FastMCP gateway connection | 091 | P2 |
| 093 | Implement tool namespace handling | 092 | P2 |
| 094 | Implement MCP v1.1 feature detection | 093 | P2 |
| 095 | Implement v1.0 fallback mechanism | 094 | P2 |
| 096 | Configure tool discovery/registration | 095 | P2 |
| 097 | Create MCP integration tests | 096 | P2 |

### Work Stream 10: FastAPI Application (Bob)
**Task Range:** 101-113 | **Count:** 13

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 101 | Create FastAPI application structure | 026 | P1 |
| 102 | Implement application factory | 101 | P1 |
| 103 | Implement Pydantic config | 102 | P1 |
| 104 | Create Pydantic models | 103 | P1 |
| 105 | Implement /invoke endpoint | 104, 061 | P1 |
| 106 | Implement /stream endpoint | 105 | P1 |
| 107 | Implement session endpoints | 106 | P1 |
| 108 | Implement /health endpoint | 107 | P1 |
| 109 | Implement /ready endpoint | 108 | P1 |
| 110 | Implement /metrics endpoint | 109 | P2 |
| 111 | Configure CORS/security middleware | 110 | P2 |
| 112 | Configure OpenAPI documentation | 111 | P2 |
| 113 | Create API integration tests | 112 | P1 |

### Work Stream 11: n8n Integration (Isabella) - Phase 2
**Task Range:** 121-127 | **Count:** 7

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 121 | Configure HTTP endpoint for n8n | 113 | P3 |
| 122 | Implement async status polling | 121 | P3 |
| 123 | Document n8n custom node requirements | 122 | P3 |
| 124 | Create OpenAPI spec for n8n | 123 | P3 |
| 125 | Create n8n workflow examples | 124 | P3 |
| 126 | Test n8n integration | 125 | P3 |
| 127 | n8n integration complete | 126 | P3 |

### Work Stream 12: Logging & Monitoring (William Chen)
**Task Range:** 131-133 | **Count:** 3

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 131 | Configure structured logging | 113 | P1 |
| 132 | Create log directory | 131 | P1 |
| 133 | Configure log rotation | 132 | P1 |

### Work Stream 13: Service Deployment (William Chen)
**Task Range:** 141-144 | **Count:** 4

| Task ID | Description | Dependencies | Priority |
|---------|-------------|--------------|----------|
| 141 | Create systemd service unit | 133 | P1 |
| 142 | Configure environment file | 141 | P1 |
| 143 | Enable and start service | 142 | P1 |
| 144 | Validate service health | 143 | P1 |

---

## Execution Sequence

### Phase A: Prerequisites (Sequential)
```
001 → 002 → 003 → 004 → 011 → 012 → 013 → 014 → 015 → 016
```
**Tasks:** 10 | **Estimated:** 4-5 hours

### Phase B: Core Framework (Sequential)
```
021 → 022 → 023 → 024 → 025 → 026
```
**Tasks:** 6 | **Estimated:** 2-3 hours

### Phase C: Integration Layer (Parallel)

**Group C1: PostgreSQL** (Trinity)
```
031 → 032 → 033 → 034 → 035 → 036
```

**Group C2: Redis** (Sri)
```
041 → 042 → 043 → 044 → 045 → 046 → 047 → 048
```

**Group C3: Ollama** (Jim)
```
071 → 072 → 073 → 074 → 075 → 076 → 077 → 078
```

**Group C4: LightRAG** (Andy)
```
081 → 082 → 083 → 084 → 085 → 086 → 087
```

**Group C5: MCP** (George)
```
091 → 092 → 093 → 094 → 095 → 096 → 097
```

**Tasks:** 36 | **Estimated:** 12-15 hours (parallel)

### Phase D: Agent Implementation (Sequential after C)
```
051 → 052 → 053 → [054, 055, 056, 057] → 058 → 059 → 060 → 061
```
**Tasks:** 11 | **Estimated:** 8-10 hours

### Phase E: FastAPI Application (Sequential after D)
```
101 → 102 → 103 → 104 → 105 → 106 → 107 → 108 → 109 → 110 → 111 → 112 → 113
```
**Tasks:** 13 | **Estimated:** 6-8 hours

### Phase F: Service Deployment (Sequential after E)
```
131 → 132 → 133 → 141 → 142 → 143 → 144
```
**Tasks:** 7 | **Estimated:** 3-4 hours

### Phase G: n8n Integration (Phase 2 - After F)
```
121 → 122 → 123 → 124 → 125 → 126 → 127
```
**Tasks:** 7 | **Estimated:** 5-6 hours

---

## Critical Path

```
001 → 002 → 003 → 004 → 011 → 012 → 013 → 014 → 015 → 016 →
021 → 022 → 023 → 024 → 025 → 026 →
[031-036 || 041-048 || 071-078 || 081-087 || 091-097] →
051 → 052 → 053 → 058 → 059 → 061 →
101 → 102 → 103 → 104 → 105 → 106 → 107 → 108 → 109 →
131 → 132 → 133 → 141 → 142 → 143 → 144
```

**Critical Path Length:** 24 tasks (excluding parallel groups)
**Critical Path Duration:** 25-30 hours

---

## Dependency Matrix

### Key Dependencies

| Dependent Task | Requires |
|----------------|----------|
| 051 (State Schema) | 026, 036, 048 (framework + DB + Redis) |
| 054 (RAG Agent) | 053, 087 (supervisor + LightRAG tests) |
| 055 (Code Agent) | 053, 078 (supervisor + Ollama tests) |
| 056 (Tool Agent) | 053, 097 (supervisor + MCP tests) |
| 057 (General Agent) | 053, 078 (supervisor + Ollama tests) |
| 086 (Response Cache) | 085, 048 (ingestion + Redis tests) |
| 105 (Invoke Endpoint) | 104, 061 (models + agent verification) |

### Blocking Tasks (Critical)

These tasks block multiple downstream work:
1. **Task 026** (Verify core dependencies) - Blocks WS 6, 7, 8, 9, 10
2. **Task 048** (Redis tests) - Blocks WS 6, 8
3. **Task 053** (Supervisor agent) - Blocks all worker agents
4. **Task 061** (Agent verification) - Blocks FastAPI /invoke
5. **Task 113** (API tests) - Blocks WS 11, 12, 13

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Parallel groups finishing at different times | Medium | Daily sync, buffer time |
| LangGraph v0.3.x API changes | High | Pin version, test early |
| Integration test failures | Medium | Mock services for isolated testing |
| Resource contention (concurrent dev) | Low | Assign non-overlapping tasks |

---

## Quality Gates

### Gate 1: Prerequisites Complete
- [x] Service account created
- [x] DNS record registered
- [x] Directory structure created
- [x] Virtual environment ready
- [x] All dependencies installed

### Gate 2: Integration Layer Complete
- [ ] PostgreSQL checkpoint functional
- [ ] Redis session manager functional
- [ ] Ollama routing functional
- [ ] LightRAG client functional
- [ ] MCP client functional

### Gate 3: Agent Layer Complete
- [ ] State schema implemented
- [ ] Query classifier functional
- [ ] Supervisor agent functional
- [ ] All worker agents functional
- [ ] Graph compilation verified

### Gate 4: API Layer Complete
- [ ] All endpoints implemented
- [ ] Health checks passing
- [ ] Integration tests passing

### Gate 5: Service Operational
- [ ] systemd service running
- [ ] Logs collecting
- [ ] Metrics exposed
- [ ] Health check passing

---

## Next Steps

1. **Phase 5:** Julia Santos generates test suite (78 test cases)
2. **Phase 6:** CAIO reviews and approves task breakdown
3. **Phase 7:** Post-approval setup and execution readiness

---

**Synthesized By:** Agent Zero
**Date:** 2025-12-04
**Status:** Ready for Phase 5 (Test Suite Generation)
