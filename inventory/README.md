# HX-Infrastructure Inventory

**Purpose:** Authoritative current-state documentation of all infrastructure resources
**Status:** ACTIVE - Production infrastructure baseline
**Last Updated:** 2025-11-21

---

## Directory Purpose

The `inventory/` directory maintains authoritative, current-state documentation of all physical and logical infrastructure resources in the HX-Infrastructure platform. This is **NOT** design documentation - it is a living snapshot of **what actually exists** in production.

### Key Characteristics

**Current State Documentation:**
- ✅ Reflects actual deployed infrastructure
- ✅ Updated as infrastructure changes
- ✅ Authoritative source of truth for operational systems
- ✅ Production values, not templates or examples

**Maintenance:**
- Updated within 24 hours of infrastructure changes
- Weekly review cycle (or upon significant changes)
- Version controlled with change history
- Aligned with network topology and architecture standards

---

## Inventory Documents

### nodes.md
**File:** `/home/agent0/HX-Infrastructure/inventory/nodes.md`
**Size:** 897 lines (33 KB)
**Version:** 2.0
**Last Updated:** 2025-11-15
**Status:** ✅ ACTIVE - Authoritative Infrastructure Baseline

**Purpose:**
Comprehensive inventory of all 30 server nodes in HX-Infrastructure, including:
- Server capabilities and responsibilities
- Operational status (Operational, In Progress, Planned, Reserved)
- Network configuration (IP addresses, ports, hostnames)
- Integration points with other services
- Validation status and deployment dates
- Data paths and storage locations

**Content Sections:**
1. **Identity, Trust, and Control (4 nodes)**
   - hx-dc-server (192.168.10.200) - Domain Controller & Authentication Hub
   - hx-ca-server (192.168.10.201) - Internal Certificate Authority
   - hx-ssl-server (192.168.10.202) - Reverse Proxy / TLS Termination
   - hx-control-node (192.168.10.203) - Ansible Control Plane

2. **Model Serving and Inference Mesh (4 nodes)**
   - hx-ollama1-server (192.168.10.204) - Primary LLM serving
   - hx-ollama2-server (192.168.10.205) - Code-focused model serving
   - hx-ollama3-server (192.168.10.206) - Embeddings host & prompt-enhancement
   - hx-litellm-server (192.168.10.212) - Unified LLM API Gateway

3. **Data Plane: Structured, Cache, and Vectors (5 nodes)**
   - hx-postgres-server (192.168.10.209) - System-of-Record Relational Database
   - hx-redis-server (192.168.10.210) - Redis Cache Server with Web UI
   - hx-qdrant-server (192.168.10.207) - Vector Database
   - hx-qdrant-ui-server (192.168.10.208) - Qdrant Web UI
   - hx-qmcp-server (192.168.10.211) - Qdrant Model Context Protocol Server

4. **Agentic + Toolchain (10 nodes)**
   - hx-fastmcp-server (192.168.10.213) - High-throughput MCP server + gateway
   - hx-n8n-mcp-server (192.168.10.214) - n8n Model Context Protocol Server
   - hx-n8n-server (192.168.10.215) - Workflow Automation Platform
   - hx-docling-server (192.168.10.216) - Docling Worker Node
   - hx-docling-mcp-server (192.168.10.217) - Docling MCP Endpoint (Planned)
   - hx-crawl4ai-mcp-server (192.168.10.218) - Crawl4AI MCP Endpoint
   - hx-crawl4ai-server (192.168.10.219) - Crawl4AI Worker Node
   - hx-literag-server (192.168.10.220) - LightRAG Server
   - hx-coderabbit-server (192.168.10.228) - CodeRabbit MCP Server (Reserved)
   - hx-shadcn-server (192.168.10.229) - Shadcn MCP Server (Planned)

5. **Application and User-Facing Layers (4 nodes)**
   - hx-webui-server (192.168.10.227) - Open WebUI for Chat/Agent UX
   - hx-agui-server (192.168.10.221) - AG-UI Application Server (Planned)
   - hx-dev-server (192.168.10.222) - Development Environment (Planned)
   - hx-demo-server (192.168.10.223) - Demo Environment (In Progress)

6. **Integration, Coordination, and Observability (3 nodes)**
   - hx-cc-server (192.168.10.224) - Claude Code Systems Integrator & Knowledge Hub
   - hx-metric-server (192.168.10.225) - Metrics and Telemetry Collection (Planned)
   - hx-lang-server (192.168.10.226) - LangGraph Server (Planned)

**Status Legend:**
- ✅ **Operational** (21 nodes) - Deployed, tested, and validated for production use
- 🛠️ **In Progress** (1 node) - Deployed but not yet fully validated/configured
- ⬜ **Planned** (5 nodes) - To be deployed (design complete, awaiting implementation)
- ⚠️ **Reserved** (2 nodes) - IP allocated, not yet deployed

**Key Features:**
- Complete traceability to architecture documentation
- Integration point mapping across all services
- Change log with deployment history
- Pending changes tracking
- Host file reference (production DNS configuration)
- Maintenance guidelines and update triggers

**Alignment:**
Aligns with HX-Infrastructure core documents:
- `network/topology.md` - IP allocations and zones match exactly
- `standards/architecture-standards.md` - Service patterns comply
- `standards/documentation-requirements.md` - Format follows standards
- `standards/testing-requirements.md` - Validation status reflects test-driven deployment

---

## Deployment Statistics (Current State)

**Total Servers:** 30 nodes allocated

**Operational Status Breakdown:**
- **Operational (✅):** 21 nodes (70%)
- **In Progress (🛠️):** 1 node (3%)
- **Planned (⬜):** 5 nodes (17%)
- **Reserved (⚠️):** 2 nodes (7%)
- **Network Infrastructure:** 1 gateway (not counted in server total)

**Service Category Distribution:**

| Category | Nodes | Operational | In Progress | Planned | Reserved |
|----------|-------|-------------|-------------|---------|----------|
| Identity & Control | 4 | 4 | 0 | 0 | 0 |
| Model & Inference | 4 | 4 | 0 | 0 | 0 |
| Data Plane | 5 | 5 | 0 | 0 | 0 |
| Agentic & Toolchain | 10 | 6 | 0 | 2 | 2 |
| Application Layer | 4 | 1 | 1 | 2 | 0 |
| Integration & Governance | 3 | 1 | 0 | 2 | 0 |
| **Totals** | **30** | **21** | **1** | **5** | **2** |

---

## How to Use This Inventory

### For Infrastructure Planning
1. **Check current capacity**: Review operational nodes to understand available services
2. **Identify gaps**: Review planned/reserved nodes to understand deployment pipeline
3. **Plan integrations**: Use integration points to understand service dependencies
4. **Resource allocation**: Use category distribution to balance workloads

### For Deployment Operations
1. **Pre-deployment**: Verify node not already deployed (avoid IP conflicts)
2. **During deployment**: Update document within 24 hours of status change
3. **Post-deployment**: Document validation status, integration points, data paths
4. **Operational handoff**: Ensure all sections complete before promoting to operational

### For Troubleshooting
1. **Service lookup**: Find server by service name or IP address
2. **Integration mapping**: Trace dependencies between services
3. **Status verification**: Confirm operational status before depending on service
4. **Data path resolution**: Locate configuration and data directories

### For Documentation
1. **Authoritative reference**: Use as single source of truth for infrastructure state
2. **Architecture alignment**: Cross-reference with topology and standards
3. **Change tracking**: Review change log for recent infrastructure modifications
4. **Maintenance scheduling**: Use pending changes table to plan future work

---

## Update Procedures

### When to Update

This inventory MUST be updated when:
- ✅ New servers deployed to infrastructure
- ✅ Server status changes (operational → in-progress → planned)
- ✅ IP address changes occur
- ✅ Service roles or responsibilities change
- ✅ Integration points are modified
- ✅ New capabilities are added to servers
- ✅ Servers are decommissioned

### Update Timeline
- **Critical changes** (IP, status, decommission): Within 4 hours
- **Standard changes** (capabilities, integration): Within 24 hours
- **Documentation improvements**: Next weekly review cycle

### Update Process
1. **Make change in production**: Deploy/configure infrastructure
2. **Update nodes.md**: Reflect actual production state
3. **Update change log**: Document what changed and when
4. **Update version history**: Increment version if significant
5. **Review related docs**: Update topology/standards if needed
6. **Commit with context**: Clear commit message explaining change

---

## Integration with Other Documentation

### Network Documentation
- **network/topology.md**: IP allocations must match nodes.md exactly
- **network/port-mapping.md**: Service ports documented in both locations
- **nodes/<node-name>/**: Individual node specifications provide deeper detail

### Standards Documentation
- **standards/architecture-standards.md**: Node designs comply with patterns
- **standards/naming-conventions.md**: Server names follow standards
- **standards/deployment-requirements.md**: Deployment validation follows standards
- **standards/testing-requirements.md**: Validation status reflects test results

### Agent Documentation
- **hx-agents/hx-agent-inventory.md**: 45 agents map to infrastructure services
- **hx-agents/hx-orchestration-guide.md**: Multi-agent coordination uses these nodes
- **.claude/commands/**: Orchestration commands reference these servers

### Project Planning
- **action-plan-v2-updated.md**: Deployment roadmap aligns with planned nodes
- **constitution.md**: Infrastructure principles reflected in node design
- **README.md**: High-level overview references this inventory

---

## Inventory Design Principles

### Authoritative Current State
- **Single source of truth**: All operational infrastructure documented
- **Production values only**: No templates, examples, or hypotheticals
- **Validated information**: All statuses reflect actual validation
- **Timely updates**: Changes reflected within 24 hours

### Comprehensive Documentation
- **Complete coverage**: All 30 nodes documented
- **Integration mapping**: All service dependencies documented
- **Status transparency**: Clear operational/planned/reserved distinction
- **Change tracking**: Full history of infrastructure evolution

### Operational Focus
- **Operator-centric**: Information needed for day-to-day operations
- **Troubleshooting support**: Integration points enable dependency tracing
- **Deployment guidance**: Status and validation inform deployment planning
- **Maintenance support**: Data paths and configuration locations documented

### Architecture Alignment
- **Standards compliance**: All nodes follow architecture standards
- **Topology alignment**: IP allocations match network topology exactly
- **Testing alignment**: Validation status reflects testing requirements
- **Documentation standards**: Format follows documentation requirements

---

## Future Inventory Expansion

### Planned Inventory Documents

**compute-resources.md** (Future)
- CPU/Memory/Storage per node
- Resource utilization metrics
- Capacity planning data
- Hardware specifications

**network-inventory.md** (Future)
- VLAN configurations
- Security zones and firewall rules
- DNS zone files
- Certificate inventory

**service-inventory.md** (Future)
- Systemd service units per node
- Service dependencies and ordering
- Service health checks
- Service ownership (which agent maintains)

**backup-inventory.md** (Future)
- Backup schedules per node
- WAL archiving configurations
- Snapshot strategies (Qdrant, Redis)
- Recovery procedures

**credentials-inventory.md** (Future - Sensitive)
- Ansible Vault references per node
- Certificate locations and expiration dates
- Service account mappings
- SSH key deployments

### Inventory Automation (Future)

**Potential Automation:**
- Automatic inventory collection via Ansible facts
- Status validation via health checks
- Drift detection (inventory vs. actual state)
- Automatic change log generation

**However:**
HX-Infrastructure philosophy emphasizes **manual procedures** over automation. Any inventory automation must:
- Be read-only (no automatic infrastructure changes)
- Complement (not replace) manual documentation
- Require human validation before updates
- Preserve manual change tracking and approval

---

## Maintenance Guidelines

### Weekly Review Checklist

**Infrastructure Validation:**
- [ ] All operational nodes still operational?
- [ ] Any status changes (operational → in-progress → planned)?
- [ ] New nodes deployed this week?
- [ ] Any nodes decommissioned?

**Documentation Validation:**
- [ ] Change log complete for week?
- [ ] Pending changes table current?
- [ ] Integration points accurate?
- [ ] Data paths verified?

**Alignment Validation:**
- [ ] Inventory matches network topology?
- [ ] Node specifications align with inventory?
- [ ] Architecture standards reflected?
- [ ] Agent documentation aligned?

**Quality Checks:**
- [ ] No stale information (>30 days old)?
- [ ] All status legends used correctly?
- [ ] Version history updated if changed?
- [ ] Related documents cross-referenced?

### Document Health Indicators

**Healthy Inventory:**
- ✅ Updated within last 7 days
- ✅ Change log has entries for recent deployments
- ✅ All operational nodes have validation status
- ✅ Pending changes table reflects active work
- ✅ Alignment with topology verified

**Unhealthy Inventory:**
- ❌ Not updated in >14 days
- ❌ Change log missing recent deployments
- ❌ Operational nodes lack validation details
- ❌ Pending changes table outdated
- ❌ Drift from network topology

---

## Related Documentation

### HX-Infrastructure Core
- `constitution.md` - Project principles and philosophy
- `README.md` - Repository overview and navigation
- `action-plan-v2-updated.md` - Project roadmap and deployment status

### Network and Infrastructure
- `network/topology.md` - Network architecture and IP allocations (v1.1.1)
- `network/port-mapping.md` - Service port assignments (when created)
- `nodes/<node-name>/node-spec.md` - Individual node specifications (when created)

### Standards
- `standards/naming-conventions.md` - Server naming standards
- `standards/architecture-standards.md` - Architecture guidelines
- `standards/documentation-requirements.md` - Documentation standards
- `standards/testing-requirements.md` - Testing and validation requirements
- `standards/deployment-requirements.md` - Deployment procedures

### Agent Documentation
- `hx-agents/hx-agent-inventory.md` - 45 agents and capabilities
- `hx-agents/hx-orchestration-guide.md` - Multi-agent workflows
- `hx-agents/hx-knowledge-vault-catalog.md` - Knowledge vault structure
- `CLAUDE.md` - Agent Zero orchestration instructions

### Command Documentation
- `.claude/commands/workflows/` - Project lifecycle workflows reference this inventory
- `.claude/commands/agents/` - Agent orchestration commands use these nodes
- `.claude/commands/utilities/` - Utility commands operate on this infrastructure

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-21 | Initial inventory directory README | HX-Infrastructure Team |

---

## Document Metadata

**Document Type:** Directory Documentation - Inventory Overview
**Status:** ACTIVE - Authoritative Reference
**Maintained By:** HX-Infrastructure Team
**Review Frequency:** Monthly (or when inventory documents updated)
**Last Review:** 2025-11-21
**Next Review:** 2025-12-21

---

*The inventory directory maintains authoritative current-state documentation of all HX-Infrastructure resources. It serves as the single source of truth for what actually exists in production. All infrastructure operators and automation must treat this inventory as the definitive reference for operational systems.*
