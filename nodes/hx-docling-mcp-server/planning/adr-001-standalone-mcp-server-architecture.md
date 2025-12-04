# ADR-001: Standalone MCP Server Architecture for hx-docling-mcp-server

**Status:** ACCEPTED
**Date:** 2025-12-01
**Architect:** alex-rivera (Platform Architect)
**Context:** Task Breakdown Workflow Phase 3 - Architectural Conflict Resolution
**Decision Driver:** Agent Zero orchestration discovered architectural ambiguity requiring clarification

---

## Context

During Phase 3 (Task Breakdown Workflow) for hx-docling-mcp-server deployment, Agent Zero identified a critical architectural conflict requiring platform architect decision:

**THE CONFLICT:**

Should hx-docling-mcp-server:
- **Option A**: Install its OWN FastMCP framework and run as **standalone MCP server**?
- **Option B**: Be a **downstream backend service** that hx-fastmcp-server proxies to, WITHOUT installing FastMCP?

**Evidence Supporting Each Option:**

**For Option B (Integration/Proxy Pattern):**
- `/inventory/nodes.md` line 280 lists hx-docling-mcp-server as "Backend MCP Services" for hx-fastmcp-server
- hx-fastmcp-server role: "Compose and proxy downstream MCP services within single Python application"
- Other MCP services listed alongside: hx-qmcp-server, hx-crawl4ai-mcp-server, hx-n8n-mcp-server
- Suggests integration pattern where hx-fastmcp-server acts as MCP gateway

**For Option A (Standalone Pattern):**
- Specification (8,126 lines) extensively documents FastMCP framework installation and configuration
- Tasks 031-036 define complete FastMCP server setup with HTTP/SSE/stdio transports
- Specification lines 1960-1974 describe "FastMCP Server Initialization" with full transport configuration
- Architecture review (alex-rivera-architecture-review.md) validates standalone MCP server design
- Specification line 32: "standalone document processing service that exposes advanced document parsing...through the Model Context Protocol"

**Discovery Context:**
- Generated tasks (james-rodriguez, Work Stream 3) include:
  - Task 031: Install FastMCP framework on hx-docling-mcp-server
  - Task 032: Initialize FastMCP server with health_check tool
  - Task 033: Configure HTTP, SSE, stdio transports
- This affects Work Streams 3-10 (all application code tasks)
- Potential impact: 40+ generated task files may require revision

---

## Decision

**OPTION A: STANDALONE MCP SERVER ARCHITECTURE**

hx-docling-mcp-server will:
1. Install its OWN FastMCP framework (v0.2+)
2. Run as a STANDALONE MCP server with full transport support (HTTP/SSE/stdio)
3. Expose 19 MCP tools directly to AI agent clients
4. Operate INDEPENDENTLY from hx-fastmcp-server

This decision is based on specification intent, charter scope, and multi-server architecture patterns already established in HX-Infrastructure.

---

## Rationale

### 1. Specification Intent is Unambiguous

The specification (8,126 lines) clearly defines a **standalone MCP server**:

**Specification Line 32 (Executive Summary):**
> "The Docling MCP Server is a **standalone document processing service** that exposes advanced document parsing, knowledge graph generation, and RAG pipeline capabilities through the Model Context Protocol (MCP)."

**Specification Lines 1959-1974 (FastMCP Server Initialization):**
```markdown
#### FastMCP Server Initialization
- **Framework Version**: FastMCP >=0.2 with MCP protocol 1.0 compliance
- **Server Instance**: Created via `mcp = FastMCP("docling-mcp-server", version="1.0.0")`
- **Transport Configuration**:
  - **HTTP Transport** (Primary): Uvicorn ASGI server on `0.0.0.0:8000`
  - **SSE Transport**: Server-Sent Events on `/mcp/sse` for streaming responses
  - **stdio Transport**: JSON-RPC over stdin/stdout for CLI integration
```

**Specification Line 2525 (Architecture):**
> "**1. FastMCP Server** (MCP Protocol Layer)
> - **Purpose**: MCP protocol compliance and transport handling
> - **Responsibilities**: Tool discovery, schema generation, request validation, multi-transport handling (HTTP/SSE/stdio), response serialization"

This is NOT the architecture of a downstream backend service. This is a complete, standalone MCP server implementation.

### 2. Architecture Review Validation

Architecture review by alex-rivera (alex-rivera-architecture-review.md, 2025-11-27) **APPROVED** the standalone MCP server design:

**Lines 68-105 (Architecture Alignment Validation):**
> "✅ PASS: Overall Architecture Design
>
> **Assessment:** The deployment plan demonstrates EXCELLENT architectural thinking:
>
> 1. **Phased Approach** (8 phases: Research → Architecture → Planning → Generation → Execution → Validation → Promotion → Closeout)
> 2. **Technology Stack Validation**
>    - FastMCP framework confirmed production-ready for MCP protocol
>    - Docling ~2.25 embedded library option validated (in-process, not worker API)"

The architecture review found ZERO violations related to FastMCP installation or standalone server architecture. All violations were infrastructure philosophy issues (firewalls, systemd dependencies), NOT architectural pattern issues.

### 3. Multi-Server Architecture Pattern Precedent

HX-Infrastructure already establishes pattern of **multiple specialized MCP servers** operating independently:

**From `/inventory/nodes.md`:**

**hx-qmcp-server:**
- Role: "Qdrant Model Context Protocol (MCP) Server"
- Responsibilities: "Connect AI agents to Qdrant vector database...Expose Qdrant's vector search capabilities through standardized MCP interface"
- Integration: "MCP Gateway: hx-fastmcp-server"

**hx-crawl4ai-mcp-server:**
- Role: "Crawl4AI MCP Endpoint"
- Responsibilities: "Provide controlled web scraping capabilities through MCP for AI agents"
- Integration: "MCP Gateway: hx-fastmcp-server"

**hx-n8n-mcp-server:**
- Role: "n8n Model Context Protocol (MCP) Server"
- Responsibilities: "Bridge between LLMs and n8n workflows...Enable agents to leverage n8n's visual, low-code automation for real-world task execution"
- Integration: Referenced in hx-fastmcp-server backend services list

**Pattern Analysis:**
- Each MCP server is OPERATIONAL on its own dedicated node
- Each has its own IP address and DNS name
- Each implements MCP protocol independently
- hx-fastmcp-server can "compose and proxy" these servers, but they are ALSO operational standalone

### 4. Two-Server Docling Architecture is Intentional

Specification lines 49-109 explicitly define **two independent Docling servers**:

**hx-docling-server (hx-docling-server.hx.dev.local):**
- Status: ✅ Operational
- Role: "Document Processing Worker"
- Interface: "Direct HTTP REST API"
- Clients: "Internal services requiring direct document processing"

**hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local):**
- Status: ⬜ Planned
- Role: "MCP Protocol Gateway"
- Interface: "Model Context Protocol (MCP) with HTTP/SSE/stdio transports"
- Clients: "AI agents (Claude Desktop, LM Studio, custom MCP clients)"

**Specification Line 90:**
> "**No backend integration**: hx-docling-mcp-server does NOT call hx-docling-server as a backend"

**Specification Line 91:**
> "**Independent processing**: Each server has its own Docling installation and processing pipeline"

This explicitly rejects a backend/proxy architecture between the two Docling servers. If the specification rejects backend integration with hx-docling-server (a Docling-specialized service), it certainly doesn't intend backend integration with hx-fastmcp-server.

### 5. hx-fastmcp-server Role is "Compose and Proxy" (Optional)

**From `/inventory/nodes.md` line 273:**
> "**Compose and proxy** downstream MCP services within single Python application"

**Key word: "compose"** - This suggests hx-fastmcp-server can AGGREGATE multiple standalone MCP servers into a unified interface for clients that want a single entry point.

**This does NOT require downstream services to be non-MCP backends.** The pattern is:

```
AI Agent → hx-fastmcp-server (MCP Gateway) → Multiple Standalone MCP Servers
                                            ↓
                                    - hx-qmcp-server (MCP)
                                    - hx-docling-mcp-server (MCP)
                                    - hx-crawl4ai-mcp-server (MCP)
                                    - hx-n8n-mcp-server (MCP)
```

Each downstream service is a FULL MCP SERVER that can operate independently. hx-fastmcp-server provides optional aggregation/routing for clients that want unified access.

**Evidence:** hx-qmcp-server, hx-crawl4ai-mcp-server, hx-n8n-mcp-server are all listed as OPERATIONAL nodes with their own IPs. They are NOT just backend APIs - they are operational MCP servers.

### 6. Specification Scope and Charter Intent

**Charter lines 33-36:**
> "Transform document processing capabilities by providing **standardized MCP protocol access** to advanced document parsing, knowledge graph generation, and RAG pipeline integration"

**Charter Success Criteria (line 66):**
> "**MCP Server Operational**: FastMCP server deployed to hx-docling-mcp-server.hx.dev.local, accessible via HTTP/SSE/stdio transports, all 19 MCP tools discoverable by AI agents"

The charter explicitly requires a **FastMCP server** deployed to the node. This is unambiguous.

---

## Alternatives Considered

### Alternative 1: Backend HTTP API for hx-fastmcp-server Integration

**Description:**
- hx-docling-mcp-server installs Docling library but NOT FastMCP
- Exposes HTTP REST API for document processing
- hx-fastmcp-server wraps these APIs as MCP tools

**Rejected Because:**
1. **Contradicts specification** - 8,126 lines document FastMCP server, not HTTP API
2. **Contradicts charter success criteria** - Charter requires "FastMCP server deployed"
3. **Violates architecture review approval** - alex-rivera approved standalone MCP server design
4. **Breaks multi-client access** - Specification requires stdio transport for Claude Desktop, SSE for progress updates, HTTP for web clients. Backend API pattern cannot support this.
5. **No specification for this architecture** - Would require complete specification rewrite

### Alternative 2: Dual-Mode Server (MCP + HTTP API)

**Description:**
- Install FastMCP AND expose non-MCP HTTP API
- Support both standalone MCP clients and hx-fastmcp-server integration

**Rejected Because:**
1. **Unnecessary complexity** - No requirement for non-MCP HTTP API
2. **Violates Single Responsibility Principle** - Service should serve ONE protocol interface
3. **Specification doesn't define HTTP API** - Only MCP protocol documented
4. **Maintenance burden** - Two interfaces to maintain for same functionality

---

## Consequences

### Positive Consequences

1. **✅ Specification Compliance**: Implementation matches 8,126-line specification exactly
2. **✅ Charter Success Criteria Met**: FastMCP server deployed as required
3. **✅ Architecture Review Approved**: Aligns with alex-rivera's approved design
4. **✅ Multi-Client Support**: Can serve Claude Desktop (stdio), web apps (HTTP), streaming clients (SSE) directly
5. **✅ Operational Independence**: Can start/stop/restart without affecting hx-fastmcp-server
6. **✅ Follows Established Pattern**: Matches hx-qmcp-server, hx-crawl4ai-mcp-server, hx-n8n-mcp-server architecture
7. **✅ Direct Client Access**: AI agents can connect directly without gateway if desired
8. **✅ Future Composability**: hx-fastmcp-server CAN aggregate this server later if needed (optional integration)

### Negative Consequences

1. **❌ Potential Duplication with hx-fastmcp-server**: If hx-fastmcp-server already exposes some Docling tools, there may be overlap (ACCEPTABLE - specialization vs general gateway)
2. **❌ More Complex Client Configuration**: Clients must configure multiple MCP servers instead of single gateway (ACCEPTABLE - gateway aggregation is optional, not required)

### Neutral Consequences

1. **⚪ Integration with hx-fastmcp-server Deferred**: Composability can be implemented in future phase if needed
2. **⚪ Task Generation Validated**: Current tasks 031-036 are CORRECT and require NO revision

---

## Implementation Guidance

### For Task Generation (Phase 3)

**VALIDATION:** Current task framework is CORRECT. Proceed with task generation as planned.

**Work Stream 3 (james-rodriguez) - MCP Server Application Code:**
- ✅ Task 031: Install FastMCP framework - **CORRECT, proceed**
- ✅ Task 032: Initialize FastMCP server with health_check tool - **CORRECT, proceed**
- ✅ Task 033: Configure HTTP, SSE, stdio transports - **CORRECT, proceed**
- ✅ Tasks 034-036: Register 19 MCP tools - **CORRECT, proceed**

**No task revisions required.** All 40+ generated tasks are architecturally valid.

### For Specification

**NO SPECIFICATION CHANGES REQUIRED.**

The specification already correctly documents standalone MCP server architecture. The ambiguity was in infrastructure inventory documentation, not specification.

### For Infrastructure Inventory Documentation

**CLARIFICATION RECOMMENDED (not required for deployment):**

Update `/home/agent0/HX-Infrastructure/inventory/nodes.md` line 280 to clarify relationship:

**Current:**
```
- Backend MCP Services: hx-qmcp-server, hx-docling-mcp-server (when operational), hx-crawl4ai-mcp-server, hx-n8n-mcp-server
```

**Recommended:**
```
- Composable MCP Services: hx-qmcp-server, hx-docling-mcp-server (when operational), hx-crawl4ai-mcp-server, hx-n8n-mcp-server
  (Note: Each is a standalone MCP server; hx-fastmcp-server can optionally aggregate these for unified client access)
```

**Why "Composable" instead of "Backend":**
- "Backend" implies they are NOT full MCP servers (incorrect)
- "Composable" indicates they CAN be composed by hx-fastmcp-server (correct, optional)
- Clarifies that each service is operational independently

### For hx-fastmcp-server Integration (Future)

**When hx-fastmcp-server composition is implemented:**

1. **Pattern:** hx-fastmcp-server will use FastMCP client library to connect to hx-docling-mcp-server as a downstream MCP server
2. **Protocol:** MCP-to-MCP communication (NOT HTTP API to MCP wrapper)
3. **Transport:** Likely stdio or HTTP transport
4. **Tool Namespace:** hx-fastmcp-server may prefix tools (e.g., `docling.convert_document_to_markdown`)
5. **Discovery:** hx-fastmcp-server dynamically discovers hx-docling-mcp-server's 19 tools via MCP protocol
6. **Aggregation:** hx-fastmcp-server exposes aggregated toolset to clients as single MCP endpoint

**This is MCP server composition, NOT backend API integration.**

---

## References

### Primary Documents

1. **Specification:** `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
   - Lines 32-36: Standalone MCP server definition
   - Lines 1959-1974: FastMCP server initialization
   - Lines 49-109: Two-server Docling architecture
   - Lines 2525-2532: FastMCP server architecture layer

2. **Charter:** `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
   - Lines 33-36: Project purpose
   - Line 66: Success criteria requiring FastMCP deployment

3. **Architecture Review:** `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/reviews/alex-rivera-architecture-review.md`
   - Lines 68-105: Architecture design approval
   - No violations found related to standalone MCP server pattern

4. **Infrastructure Inventory:** `/home/agent0/HX-Infrastructure/inventory/nodes.md`
   - Lines 267-285: hx-fastmcp-server role and integration points
   - Lines 246-260: hx-qmcp-server (operational MCP server precedent)
   - Lines 367-381: hx-crawl4ai-mcp-server (operational MCP server precedent)

5. **Task Framework:** `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md`
   - Lines 81-106: Work Stream 3 (MCP Server Application Code)
   - Tasks 031-036: FastMCP installation and configuration

### Related ADRs

- None (this is ADR-001 for hx-docling-mcp-server)

### Knowledge Vault Research

- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastmcp-main/` - FastMCP framework research
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/docling-mcp/` - MCP server implementation research

---

## Decision Authority

**Architect:** alex-rivera (Platform Architect)
**Coordination:**
- ✅ Aligns with charter (approved 2025-11-25)
- ✅ Aligns with specification (approved 2025-11-26)
- ✅ Aligns with architecture review (approved 2025-11-27)
- ✅ Follows HX-Infrastructure multi-server MCP pattern
- ✅ No conflicts with william-chen (Infrastructure), frank-lucas (Security), julia-santos (Testing)

**Escalation:** NONE REQUIRED - Decision is unambiguous based on existing approved documentation

**CAIO Notification:** Informational only (no strategic architecture change)

---

## Status Summary

**Decision:** STANDALONE MCP SERVER ARCHITECTURE (Option A)

**Impact on Phase 3:**
- ✅ NO task revisions required
- ✅ Current task framework is architecturally correct
- ✅ Proceed with task generation as planned
- ✅ Work Stream 3 tasks 031-036 are valid

**Next Actions:**
1. ✅ Document this ADR (COMPLETE)
2. ✅ Notify Agent Zero: Proceed with Phase 3 task generation without modifications
3. ✅ Optional: Update inventory documentation to clarify "composable" vs "backend" terminology (non-blocking)
4. ✅ Future: Document hx-fastmcp-server composition pattern in separate ADR when implemented

**Resolution:** ARCHITECTURAL CONFLICT RESOLVED

---

**ADR Created:** 2025-12-01
**Author:** alex-rivera (Platform Architect)
**Status:** ACCEPTED
**Review:** Self-approved (platform architect authority for architecture decisions)
**Distribution:** Agent Zero, james-rodriguez, william-chen, julia-santos, frank-lucas
