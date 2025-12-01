# Task Dependency Matrix - hx-docling-mcp-server

**Date**: 2025-11-27
**Project**: Docling MCP Server Deployment
**Status**: Renumbering Complete - 22 Tasks Created
**Total Tasks**: 22 (with gaps for 13 TBD tasks = 35 total planned)

---

## Executive Summary

This document provides the complete dependency matrix for all deployment tasks, including blocking relationships, execution order, and parallelization opportunities.

**Key Metrics:**
- **Created Tasks**: 22 task files (Tasks 021-025 UPDATED 2025-12-01 for HTTP API architecture)
- **TBD Tasks**: 13 tasks (gaps in sequence)
- **Critical Path Length**: ~56 hours (sequential execution, reduced from ~61h after Tasks 021-025 rewrite)
- **Optimized Timeline**: ~39 hours (with parallelization, reduced from ~44h)
- **Parallel Execution Blocks**: 2 blocks (Block 1: Tasks 009-025 concurrent streams; Block 2: Tasks 027-028)

---

## Complete Task List (001-035)

### Phase 1: Pre-Deployment & Foundation (001-005)

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 001 | Install FastMCP Framework | james-rodriguez | CREATED | 1h |
| 002 | Create Samba AD Service Account | william-chen | CREATED | 15min |
| 003 | Install System Dependencies | william-chen | CREATED | 30min |
| 004 | Create Python Virtual Environment | TBD | NOT CREATED | 30min |
| 005 | Install Python Dependencies | TBD | NOT CREATED | 45min |

### Phase 2: Directory & Application Setup (006-008)

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 006 | Create Directory Structure | william-chen | CREATED | 20min |
| 007 | Install Application Code | TBD | NOT CREATED | 30min |
| 008 | Configure Environment Files | TBD | NOT CREATED | 30min |

### Phase 3: MCP Tools Registration (009-013) [PARALLEL]

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 009 | Register MCP Conversion Tools (3 tools) | james-rodriguez | CREATED | 2h |
| 010 | Register MCP Generation Tools - KG (3 tools) | james-rodriguez | CREATED | 2h |
| 011 | Register MCP Generation Tools - Doc Utils (8 tools) | james-rodriguez | NOT CREATED | 3h |
| 012 | Register MCP Manipulation Tools (5 tools) | james-rodriguez | NOT CREATED | 2h |
| 013 | Configure MCP HTTP Transport | james-rodriguez | CREATED | 1h |

### Phase 4: Docling Processing Implementation (014-020)

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 014 | Install Docling Library | albert-singh | CREATED | 1-2h |
| 015 | Configure Document Format Detection | albert-singh | CREATED | 2-3h |
| 016 | Configure Document Processing Backend Selection | albert-singh | CREATED | 2-3h |
| 017 | Implement Document Structure Preservation | albert-singh | CREATED | 4-5h |
| 018 | Integrate OCR Pipeline for Scanned Documents | albert-singh | CREATED | 3-4h |
| 019 | Implement DoclingDocument Pydantic Schema | albert-singh | CREATED | 3-4h |
| 020 | Integrate Docling Processing with MCP Tools | albert-singh | CREATED | 2-3h |

### Phase 5: LightRAG Knowledge Graph Implementation (021-025)

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 021 | Configure hx-literag-server HTTP Client Integration | andy-taylor | UPDATED | 2h |
| 022 | Configure Entity Extraction via HTTP API | andy-taylor | UPDATED | 2h |
| 023 | Configure Relationship Extraction via HTTP API | andy-taylor | UPDATED | 2h |
| 024 | Integrate Knowledge Graph Results with Qdrant | mitch-roberts | UPDATED | 2h |
| 025 | Configure Client-Side Entity Deduplication | andy-taylor | UPDATED | 2h |

### Phase 6: Integration Configuration (026-032)

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 026 | Configure LiteLLM Gateway Integration | shane-black | CREATED | 4-6h |
| 027 | Configure Qdrant Integration | TBD | NOT CREATED | 2h |
| 028 | Configure Redis Integration | TBD | NOT CREATED | 2h |
| 029 | Configure MCP SSE & stdio Transports | james-rodriguez | NOT CREATED | 2h |
| 030 | MCP Tool Schema Validation | james-rodriguez | NOT CREATED | 2h |
| 031 | Document Processing Pipeline Integration | james-rodriguez | NOT CREATED | 3h |
| 032 | Redis Session Management Integration | james-rodriguez | NOT CREATED | 2h |

### Phase 7: Service Management & Deployment (033-035)

| Task | Title | Owner | Status | Duration |
|------|-------|-------|--------|----------|
| 033 | Configure Systemd Service | william-chen | CREATED | 45min |
| 034 | Configure Logging | TBD | NOT CREATED | 1h |
| 035 | MCP Protocol Compliance Testing | james-rodriguez | CREATED | 2h |

---

## Dependency Matrix

### Task Dependencies (Blocks/Depends On)

| Task | Depends On | Blocks | Execution Group |
|------|-----------|--------|-----------------|
| 001 | NONE | 002-035 (all tasks) | Sequential |
| 002 | 001 | 003, 006, 033 | Sequential |
| 003 | 002 | 004-008 | Sequential |
| 004 | 003 | 005 | Sequential |
| 005 | 004 | 006-035 | Sequential |
| 006 | 002, 003, 005 | 007, 008 | Sequential |
| 007 | 006 | 008 | Sequential |
| 008 | 007 | 009-035 | Sequential |
| 009 | 001, 008 | 020, 035 | Parallel Block 1 |
| 010 | 001, 008 | 022, 035 | Parallel Block 1 |
| 011 | 001, 008 | 035 | Parallel Block 1 |
| 012 | 001, 008 | 035 | Parallel Block 1 |
| 013 | 001, 008 | 035 | Parallel Block 1 |
| 014 | 005 | 015-020 | Sequential |
| 015 | 014 | 016, 017 | Sequential |
| 016 | 014, 015 | 017, 018 | Sequential |
| 017 | 014, 015, 016 | 018, 019 | Sequential |
| 018 | 014, 016 | 019 | Sequential |
| 019 | 014, 015-018 | 020 | Sequential |
| 020 | 014-019, 009 | 035 | Sequential |
| 021 | 005 | 022-025 | Sequential |
| 022 | 021 | 023, 025 | Sequential |
| 023 | 022 | 024, 025 | Sequential |
| 024 | 022, 023 | 025 | Sequential |
| 025 | 021-024 | 031 | Sequential |
| 026 | 005, 008 | 027-035 | Sequential |
| 027 | 026 | 029-035 | Parallel Block 2 |
| 028 | 026 | 029-035 | Parallel Block 2 |
| 029 | 026, 027, 028 | 035 | Sequential |
| 030 | 026, 027, 028 | 035 | Sequential |
| 031 | 020, 025, 026 | 035 | Sequential |
| 032 | 026, 028 | 035 | Sequential |
| 033 | 001-032 | 035 | Sequential |
| 034 | 033 | 035 | Sequential |
| 035 | 009-013, 020, 033, 034 | NONE (final task) | Sequential |

---

## Critical Path Analysis

### Sequential Dependencies (MUST execute in order)

```
001 (FastMCP Install - 1h)
 ↓
002 (Samba AD Account - 15min)
 ↓
003 (System Dependencies - 30min)
 ↓
004 (Python venv - 30min)
 ↓
005 (Python deps - 45min)
 ↓
006 (Directory Structure - 20min)
 ↓
007 (Application Code - 30min)
 ↓
008 (Environment Files - 30min)
 ↓
┌─────────────────────────────────────────────┐
│ PARALLEL BLOCK 1 (after Task 008)          │
│ 009-013 [MCP Tools Registration]           │
│ Duration: 3h (longest task: 011)            │
│                                             │
│ Can run CONCURRENTLY with:                  │
│ 014-020 [Docling Processing]               │
│ Duration: 19h (sequential within block)     │
│                                             │
│ 021-025 [LightRAG]                          │
│ Duration: 12h (sequential within block)     │
└─────────────────────────────────────────────┘
 ↓
026 (LiteLLM Integration - 6h)
 ↓
┌─────────────────────────────────────────────┐
│ PARALLEL BLOCK 2 (after Task 026)          │
│ 027-028 [Qdrant, Redis Config]             │
│ Duration: 2h (can run concurrently)         │
└─────────────────────────────────────────────┘
 ↓
029-032 [MCP Integration Completion]
(Sequential: 2h + 2h + 3h + 2h = 9h)
 ↓
033 (Systemd Service - 45min)
 ↓
034 (Logging - 1h)
 ↓
035 (Protocol Compliance - 2h)
```

### Critical Path Timeline

**Sequential Execution (worst case):**
- Phase 1-2: 001-008 = 4.5h
- Phase 3-5 (sequential): 009-025 = 34h
- Phase 6-7: 026-035 = 22.75h
- **Total: ~61 hours**

**Optimized with Parallelization:**
- Phase 1-2: 001-008 = 4.5h
- **Parallel Block 1** (009-013 + 014-020 + 021-025 run concurrently):
  - Longest path: 014-020 (Docling) = 19h
- Phase 6: 026 = 6h
- **Parallel Block 2** (027-028 run concurrently): 2h
- Phase 6 completion: 029-032 = 9h
- Phase 7: 033-035 = 3.75h
- **Total: ~44 hours**

**Savings: 17 hours (28% reduction)**

---

## Execution Groups & Parallelization

### Group 1: Foundation (Sequential) - 4.5 hours
**Tasks**: 001-008
**Parallelization**: NONE
**Rationale**: Each task depends on prior completion

### Group 2: Core Implementation (Parallel) - 19 hours
**Tasks**: 009-025
**Parallelization**: HIGH
**Parallel Streams**:
1. **MCP Tools Stream** (009-013): 3h (can start immediately after 008)
2. **Docling Stream** (014-020): 19h (can start after 005)
3. **LightRAG Stream** (021-025): 12h (can start after 005)

**Coordination Points**:
- Task 020 requires Task 009 (MCP conversion tools)
- Task 010 provides tools for Task 022 (entity extraction)
- All streams must complete before 026

### Group 3: Integration (Mixed) - 17.75 hours
**Tasks**: 026-032
**Parallelization**: MEDIUM
**Sequential**: 026 (blocks everything)
**Parallel**: 027-028 (Qdrant + Redis config)
**Sequential**: 029-032 (final integration)

### Group 4: Deployment (Sequential) - 3.75 hours
**Tasks**: 033-035
**Parallelization**: NONE
**Rationale**: Final deployment steps must be sequential

---

## Blocking Relationships

### High-Impact Blockers (affects 10+ tasks)

| Task | Blocks Count | Critical Impact |
|------|--------------|-----------------|
| 001 | 34 tasks | **CRITICAL** - Foundation for all work |
| 005 | 30 tasks | **CRITICAL** - Python dependencies for all code |
| 008 | 27 tasks | **HIGH** - Environment config for all services |
| 026 | 9 tasks | **HIGH** - LiteLLM integration required for completion |

### Medium-Impact Blockers (affects 5-9 tasks)

| Task | Blocks Count | Impact |
|------|--------------|--------|
| 002 | 3 tasks | **MEDIUM** - Service account for ownership |
| 003 | 5 tasks | **MEDIUM** - System packages for installation |
| 014 | 6 tasks | **MEDIUM** - Docling library for processing |
| 021 | 4 tasks | **MEDIUM** - LightRAG framework for extraction |

### Low-Impact Blockers (affects 1-4 tasks)

**All other tasks** - Local dependencies within their implementation stream

---

## Risk Analysis

### Critical Path Risks

**Risk 1: Task 005 (Python Dependencies) Failure**
- **Impact**: Blocks 30 downstream tasks
- **Mitigation**: Test Python 3.11+ compatibility early, have fallback package versions documented
- **Probability**: LOW (standard Python packages)

**Risk 2: Task 014-020 (Docling Processing) Duration Overrun**
- **Impact**: Longest sequential chain (19h), delays entire project
- **Mitigation**: Allocate buffer time, prioritize critical path tasks, identify sub-tasks that can run in parallel
- **Probability**: MEDIUM (complex document processing logic)

**Risk 3: Task 026 (LiteLLM Integration) Complexity**
- **Impact**: Blocks 9 final integration tasks
- **Mitigation**: Early prototyping, circuit breaker pattern, fallback to direct Ollama calls
- **Probability**: MEDIUM (new integration pattern)

**Risk 4: Task Number Gaps (13 TBD tasks)**
- **Impact**: Cannot execute until owners assigned and tasks created
- **Mitigation**: Assign owners in Phase 5, create tasks before execution begins
- **Probability**: HIGH (currently unassigned)

---

## Execution Recommendations

### Week 1: Foundation + Parallel Implementation

**Days 1-2** (Sequential - 4.5h):
- Tasks 001-008: Foundation and setup

**Days 3-5** (Parallel - 19h):
- **Stream 1** (albert-singh): Tasks 014-020 (Docling) - CRITICAL PATH
- **Stream 2** (andy-taylor): Tasks 021-025 (LightRAG) - 12h
- **Stream 3** (james-rodriguez): Tasks 009-013 (MCP Tools) - 3h (finish early, help with integration)

### Week 2: Integration + Deployment

**Days 6-7** (Sequential - 6h):
- Task 026 (shane-black): LiteLLM integration

**Days 7-8** (Mixed - 11.75h):
- Tasks 027-028 (Parallel): Qdrant + Redis config
- Tasks 029-032 (Sequential): Final MCP integration

**Days 9-10** (Sequential - 3.75h):
- Tasks 033-035: Systemd service + compliance testing

### Recommended Team Allocation

| Agent | Primary Tasks | Backup Tasks | Estimated Load |
|-------|--------------|--------------|----------------|
| james-rodriguez | 009-013, 029-032 | 011, 012 (TBD) | 13h (week 1-2) |
| albert-singh | 014-020 | NONE | 19h (week 1) |
| andy-taylor | 021-025 | NONE | 12h (week 1) |
| shane-black | 026 | NONE | 6h (week 2) |
| william-chen | 002, 003, 006, 033 | 004, 005, 007, 008 (TBD) | 2h (week 1), 45min (week 2) |
| TBD | 004-005, 007-008, 011-012, 027-028, 034 | NONE | ~8h (needs assignment) |

---

## Quality Gates

### Phase Boundaries (MUST validate before proceeding)

**Gate 1: Foundation Complete** (after Task 008)
- All Python dependencies installed
- Directory structure created
- Environment files configured
- Service account operational
- **Validation**: Run `pytest /opt/docling-mcp/tests/test_foundation.py`

**Gate 2: Core Implementation Complete** (after Tasks 009-025)
- All MCP tools registered
- Docling processing functional
- LightRAG extraction operational
- **Validation**: Run all unit tests (pytest), verify >95% coverage

**Gate 3: Integration Complete** (after Task 032)
- LiteLLM integration working
- Qdrant + Redis configured
- MCP protocol validated
- **Validation**: Integration tests passing, end-to-end conversion test successful

**Gate 4: Deployment Ready** (after Task 035)
- Systemd service running
- Logging operational
- Protocol compliance validated
- **Validation**: Health checks passing, load test successful

---

## Coordination Points

### Cross-Agent Dependencies

**james-rodriguez → albert-singh**:
- Task 009 (Conversion Tools) → Task 020 (Docling MCP Integration)
- **Coordination**: james-rodriguez must complete MCP tool registration before albert-singh integrates Docling with MCP tools

**james-rodriguez → andy-taylor**:
- Task 010 (Generation Tools KG) → Task 022 (Entity Extraction)
- **Coordination**: Knowledge graph generation tools must be available for entity extraction integration

**andy-taylor → james-rodriguez**:
- Task 025 (Entity Deduplication) → Task 031 (Pipeline Integration)
- **Coordination**: Deduplication logic must be complete before final pipeline integration

**albert-singh + andy-taylor → shane-black**:
- Tasks 020 + 025 → Task 026 (LiteLLM Integration)
- **Coordination**: Both Docling and LightRAG must be functional before LiteLLM routing can be configured

**william-chen → ALL**:
- Task 002 (Service Account) → Tasks requiring file ownership
- Task 006 (Directory Structure) → Tasks requiring file paths
- Task 033 (Systemd Service) → ALL (final deployment)
- **Coordination**: william-chen provides infrastructure foundation for all technical work

---

## Artifact Locations

**Task Files**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/`
- 22 created: `hx-docling-mcp-task-{001,002,003,006,009,010,013,014-026,033,035}.md`
- 13 TBD: `hx-docling-mcp-task-{004,005,007,008,011,012,027-032,034}.md`

**Contribution Reviews**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/reviews/`
- `james-rodriguez-task-contribution.md`
- `albert-singh-task-contribution.md`
- `andy-taylor-task-contribution.md`
- `shane-black-task-contribution.md`
- `william-chen-task-contribution.md`

**Summary Documents**:
- `TASK-BREAKDOWN-SUMMARY.md` (renumbering plan)
- `TASK-DEPENDENCY-MATRIX.md` (this document)

---

## Next Steps

### Immediate (Phase 4 Completion)

1. ✅ Task renumbering - COMPLETE
2. ✅ Cross-reference updates - COMPLETE
3. ✅ Dependency matrix creation - COMPLETE
4. ⏳ Create consolidated task breakdown document - PENDING

### Phase 5: Clarification Questions to CAIO

1. **Assign TBD task owners**:
   - Tasks 004-005 (Python venv, dependencies) → Suggest: bob-chen or paul-warfield
   - Tasks 007-008 (Application code, environment files) → Suggest: bob-chen or george-kim
   - Tasks 011-012 (MCP doc utils, manipulation tools) → james-rodriguez (already documented)
   - Tasks 027-028 (Qdrant, Redis config) → Suggest: mitch-roberts (Qdrant), sri-patel (Redis)
   - Task 034 (Logging config) → Suggest: william-chen

2. **Approve task breakdown and renumbering**

3. **Approve execution timeline** (2-week plan with parallelization)

### Phase 7: Test Suite Generation (julia-santos)

After CAIO approval, julia-santos will generate comprehensive test suite ensuring 100% task coverage across all 35 tasks. Test suite task range (036-045) will be defined in a separate test planning document once the base task execution plan is approved.

---

**Status**: Phase 4 Synthesis IN PROGRESS
**Completion**: 80% (renumbering and dependencies done, awaiting consolidated breakdown)
**Approval Required**: CAIO approval for task breakdown, owner assignments, and execution timeline

**Generated By**: Agent Zero (agent-zero@hx.dev.local)
**Date**: 2025-11-27
**Version**: 1.0
