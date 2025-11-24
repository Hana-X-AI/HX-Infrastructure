# HX-Infrastructure Knowledge Vault Catalog

**Document Location:** `/home/agent0/HX-Infrastructure/hx-agents/hx-knowledge-vault-catalog.md`  
**Knowledge Vault Location:** `/home/agent0/HX-Infrastructure/hx-knowledge/repos/`  
**Purpose:** Repository of documentation, source code, and reference materials for all HX-Infrastructure agents  
**Maintained By:** Infrastructure Team  
**Last Updated:** November 15, 2025

---

## Knowledge Organization

The knowledge vault contains documentation and source code for all technologies used in the HX-Infrastructure platform. This catalog helps agents quickly find relevant information when executing infrastructure and development tasks.

**Total Repositories:** 55

---

## Layer 1: Identity & Trust Resources

### Authentication & Directory Services

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `ansible-devel` | Ansible Development | amanda | Configuration automation documentation and development resources |
| `nginx` | Nginx | frank | Reverse proxy documentation, SSL/TLS configuration |
| `nginx-master` | Nginx Source | frank | Web server source code, proxy patterns, security configurations |

**Use when:** Setting up domain authentication, SSL certificates, web proxies, reverse proxy configurations

---

## Layer 2: Model & Inference Resources

### LLM Models & Frameworks

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `ollama-main` | Ollama | patricia | Local LLM deployment and management framework |
| `litellm-main` | LiteLLM | maya | LLM gateway, routing, proxy for multiple model providers |
| `langgraph-main` | LangGraph | laura | Graph-based agent orchestration and workflow framework |
| `langchain` | LangChain | laura | Legacy chain-based patterns (reference/migration) |
| `langchain-docs` | LangChain Docs | laura | Migration reference documentation from chains to graphs |

**Use when:** Deploying LLM infrastructure, building agent workflows, model routing, multi-model orchestration

---

## Layer 3: Data Plane Resources

### Databases & Caching

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `postgres-master` | PostgreSQL | quinn | Relational database source, deployment patterns, optimization |
| `redis-unstable` | Redis | samuel | In-memory caching, session storage, pub/sub messaging |
| `qdrant-master` | Qdrant | robert | Vector database source code for semantic search |
| `qdrant-client-master` | Qdrant Client | robert | Vector DB client library and integration patterns |
| `qdrant-web-ui` | Qdrant UI | sarah | Web interface for Qdrant vector database management |
| `prisma-main` | Prisma ORM | Multiple | Database ORM, schema management, and migrations |

**Use when:** Setting up databases, implementing caching strategies, vector storage for RAG, data persistence

---

## Layer 4: Agentic & Toolchain Resources

### MCP Servers & Workers

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `fastmcp-main` | FastMCP | george | MCP gateway implementation and server framework |
| `mcp-server-qdrant-master` | Qdrant MCP | kevin | MCP server for Qdrant vector database integration |
| `n8n-mcp-main` | N8N MCP | olivia | N8N workflow automation MCP integration |
| `mcp-crawl4ai-rag` | Crawl4ai MCP | David | Web scraping MCP server for RAG pipelines |
| `docling-mcp` | Docling MCP | eric | Document processing and parsing MCP server |
| `magic-mcp` | Magic MCP | Multiple | MCP utilities, helpers, and common patterns |
| `shield_mcp_complete` | Shield MCP | Multiple | MCP security patterns and protection mechanisms |

### RAG & Document Processing

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `crawl4ai-main` | Crawl4ai | Diana | Web scraping and intelligent data extraction |
| `docling-main` | Docling | elena | Document parsing, processing, and structure extraction |
| `LightRAG-main` | LightRAG | marcus | Knowledge graph-based RAG system implementation |

### Agentic Patterns & Frameworks

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `agentic-design-patterns-docs-main` | Design Patterns | agent-zero | Agent architecture patterns and best practices |
| `ottomator-agents-main` | Ottomator | Multiple | Multi-agent orchestration examples and patterns |
| `Skill_Seekers-development` | Skill Seekers | Multiple | Agent skill discovery and capability matching patterns |

**Use when:** Building RAG pipelines, MCP integrations, multi-agent systems, document processing workflows

---

## Layer 5: Application Resources

### Frontend Frameworks

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `next.js` | Next.js (Stable) | victor | React framework stable release, production patterns |
| `next.js-canary` | Next.js (Canary) | victor | Next.js bleeding edge features and experimental APIs |
| `tailwindcss` | Tailwind CSS | victor | Utility-first CSS framework for rapid UI development |
| `primitives` | Radix Primitives | hannah | Unstyled, accessible UI component primitives |
| `ui-main` | UI Components | Multiple | Shared UI component library and design system |
| `solid-principles` | Solid.js | brian | Reactive UI framework with fine-grained reactivity |
| `zustand-main` | Zustand | Multiple | Lightweight state management for React applications |

### Generative UI & AI Interfaces

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `CopilotKit-main` | CopilotKit | hannah | AI copilot UI components and integration patterns |
| `ag-ui-main` | AG-UI | brian | Agentic UI framework for AI-powered interfaces |
| `crayon` | Crayon SDK | Multiple | Generative UI framework for building agentic interfaces beyond text |
| `examples` | Examples Collection | Multiple | Example projects demonstrating AI agent framework integrations and Generative UI use cases |

### UI Extensions & Tools

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `21st-extension` | 21st Extension | Multiple | Browser extension patterns and AI integration examples |
| `spec-kit-main` | Spec Kit | Multiple | Design specifications toolkit and documentation patterns |
| `thesys` | Thesys | Multiple | Thesys framework integration documentation |

### Backend & API

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `fastapi` | FastAPI Docs | fatima | API framework documentation and best practices |
| `fastapi-master` | FastAPI Source | fatima | Python async API framework source code |
| `n8n-master` | N8N | omar | Workflow automation platform source code |
| `n8n-docs` | N8N Docs | omar | N8N workflow automation documentation and examples |
| `open-webui-main` | Open WebUI | paul | LLM web interface and chat UI implementation |

### Validation & Data

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `pydantic-main` | Pydantic | Multiple | Python data validation using type annotations |
| `zod-main` | Zod | Multiple | TypeScript-first schema validation library |

### Runtime & Core

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `node` | Node.js | Multiple | Node.js runtime documentation and core modules |
| `pythondotorg` | Python.org | Multiple | Official Python language documentation and resources |

**Use when:** Building web applications, APIs, user interfaces, generative UI, AI-powered interfaces

---

## Layer 6: Integration & Testing Resources

### CI/CD & Testing

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `cypress` | Cypress | julia | End-to-end testing framework for web applications |
| `pytest` | Pytest | julia | Python testing framework and fixtures |

### Infrastructure & Deployment

| Directory | Technology | Primary Agent(s) | Purpose |
|-----------|-----------|------------------|---------|
| `docker-install-master` | Docker Install | yasmin | Docker installation guides and setup scripts |
| `compose-main` | Docker Compose | yasmin | Multi-container orchestration and service definitions |
| `cli-master` | CLI Tools | Multiple | Command-line interface patterns and CLI development |

**Use when:** Setting up testing, CI/CD pipelines, containerization, deployment automation

---

## Quick Lookup: "Need Info About X?"

### By Technology Type

**Authentication/Security:**
- `ansible-devel`, `nginx`, `nginx-master`

**LLMs & AI:**
- `ollama-main`, `litellm-main`, `langgraph-main`, `langchain`, `langchain-docs`

**Databases:**
- `postgres-master`, `redis-unstable`, `qdrant-master`, `qdrant-client-master`, `qdrant-web-ui`

**MCP Ecosystem:**
- `fastmcp-main`, `mcp-server-qdrant-master`, `n8n-mcp-main`, `mcp-crawl4ai-rag`, `docling-mcp`, `magic-mcp`, `shield_mcp_complete`

**RAG & Documents:**
- `crawl4ai-main`, `docling-main`, `LightRAG-main`

**Frontend:**
- `next.js`, `next.js-canary`, `tailwindcss`, `CopilotKit-main`, `ag-ui-main`, `open-webui-main`, `crayon`, `examples`

**Backend/API:**
- `fastapi`, `fastapi-master`, `n8n-master`, `n8n-docs`

**Agent Patterns:**
- `agentic-design-patterns-docs-main`, `ottomator-agents-main`, `Skill_Seekers-development`

**Testing:**
- `cypress`, `pytest`

**Infrastructure:**
- `docker-install-master`, `compose-main`, `ansible-devel`

**Runtime/Core:**
- `node`, `pythondotorg`

**Generative UI:**
- `crayon`, `CopilotKit-main`, `ag-ui-main`, `examples`

---

## Usage Patterns for Agents

### When Working on Infrastructure Tasks:

1. **Identify required technology** from task requirements
2. **Find relevant documentation** in this catalog
3. **Navigate to repository** at `/home/agent0/HX-Infrastructure/hx-knowledge/repos/<directory>`
4. **Reference specific documentation** when implementing solutions

### Example Usage:

```
Task: "Deploy a LangGraph-based agent with Qdrant vector storage"

Required Knowledge:
1. LangGraph = /home/agent0/HX-Infrastructure/hx-knowledge/repos/langgraph-main
2. Qdrant = /home/agent0/HX-Infrastructure/hx-knowledge/repos/qdrant-master
3. MCP Integration = /home/agent0/HX-Infrastructure/hx-knowledge/repos/fastmcp-main
4. Deployment = /home/agent0/HX-Infrastructure/hx-knowledge/repos/docker-install-master

Reference these repos during implementation for architecture patterns and best practices.
```

---

## Maintenance Guidelines

### Adding New Knowledge

When adding new documentation to `/home/agent0/HX-Infrastructure/hx-knowledge/repos/`:

1. **Clone repository** to knowledge vault:
   ```bash
   cd /home/agent0/HX-Infrastructure/hx-knowledge/repos/
   git clone <repo-url> <directory-name>
   ```

2. **Update this catalog** with:
   - Directory name
   - Technology/project name
   - Primary responsible agent(s)
   - Purpose/use case
   - Layer assignment

3. **Notify relevant agents** if it affects their domain

4. **Commit catalog changes** to HX-Infrastructure repository

### Keeping Knowledge Current

**Monthly:**
- [ ] Review all `*-main`, `*-master` repositories for updates
- [ ] Update repositories: `cd <repo> && git pull`
- [ ] Note any breaking changes in agent profiles

**Quarterly:**
- [ ] Archive deprecated documentation
- [ ] Add new technologies as adopted
- [ ] Reorganize if layer structure changes
- [ ] Verify all repositories still relevant

**On Technology Migration:**
- [ ] Keep old docs as "legacy reference" (e.g., `langchain`)
- [ ] Add new docs (e.g., `langgraph-main`)
- [ ] Update agent profiles to prefer new over old
- [ ] Document migration path

---

## File Structure Conventions

### Directory Naming Standards

- `<project>-main` → Main branch of active project
- `<project>-master` → Master branch (legacy naming convention)
- `<project>-devel` → Development branch
- `<project>` → Stable release or official documentation

### Path Structure
```
/home/agent0/HX-Infrastructure/
├── hx-agents/                      # Agent-related documentation
│   └── hx-knowledge-vault-catalog.md    ← THIS DOCUMENT
├── hx-knowledge/
│   ├── repos/                      # All repository clones
│   │   ├── layer-1-*/             # Identity & Trust
│   │   ├── layer-2-*/             # Model & Inference
│   │   ├── layer-3-*/             # Data Plane
│   │   ├── layer-4-*/             # Agentic & Toolchain
│   │   ├── layer-5-*/             # Application
│   │   └── layer-6-*/             # Integration & Testing
│   └── docs/                       # HX-specific documentation
│       ├── 0.0.5.2.0-readme.md
│       ├── 0.0.5.2.1-credentials.md
│       └── 0.0.5.2.2-url-safe-password-pattern.md
├── constitution.md
├── standards/
├── templates/
├── services/
└── nodes/
```

**Note:** Repositories are currently in flat structure. Layer-based subdirectories may be implemented in future for better organization.

---

## Knowledge Vault Statistics

**Total Repositories:** 55

**Coverage by Layer:**
- **Layer 1** (Identity & Trust): 3 repositories
- **Layer 2** (Model & Inference): 5 repositories
- **Layer 3** (Data Plane): 6 repositories
- **Layer 4** (Agentic & Toolchain): 13 repositories
- **Layer 5** (Application): 23 repositories
- **Layer 6** (Integration & Testing): 5 repositories

**Languages Represented:**
- Python: 24 projects
- TypeScript/JavaScript: 22 projects
- Go: 3 projects
- Mixed/Other: 6 projects

**Update Frequency:**
- Active (monthly updates): 38 repositories
- Stable (quarterly updates): 12 repositories
- Reference (rarely updated): 5 repositories

---

## Agent-Specific Knowledge Profiles

### Layer 1: Identity & Trust

**frank** (Samba DC / Identity)
- **Primary:** `nginx`, `nginx-master`, `ansible-devel`
- **Purpose:** SSL/TLS certificates, reverse proxy, identity infrastructure

**william** (Ubuntu Systems)
- **Primary:** `ansible-devel`, `docker-install-master`
- **Purpose:** System configuration, OS management

**yasmin** (Docker)
- **Primary:** `docker-install-master`, `compose-main`
- **Purpose:** Container orchestration, deployment

---

### Layer 2: Model & Inference

**laura** (LangGraph)
- **Primary:** `langgraph-main`
- **Secondary:** `langchain`, `langchain-docs`, `agentic-design-patterns-docs-main`
- **Purpose:** Graph-based orchestration, migration from chains

**patricia** (Ollama)
- **Primary:** `ollama-main`
- **Secondary:** `litellm-main`
- **Purpose:** LLM deployment, model management

**maya** (LiteLLM)
- **Primary:** `litellm-main`
- **Secondary:** `ollama-main`
- **Purpose:** Multi-model routing, LLM gateway

---

### Layer 3: Data Plane

**quinn** (PostgreSQL)
- **Primary:** `postgres-master`
- **Secondary:** `prisma-main`
- **Purpose:** Relational database deployment, optimization

**samuel** (Redis)
- **Primary:** `redis-unstable`
- **Purpose:** Caching, session storage, pub/sub

**robert** (Qdrant)
- **Primary:** `qdrant-master`, `qdrant-client-master`
- **Secondary:** `qdrant-web-ui`, `mcp-server-qdrant-master`
- **Purpose:** Vector database, semantic search

**sarah** (Qdrant UI)
- **Primary:** `qdrant-web-ui`
- **Secondary:** `qdrant-master`
- **Purpose:** Vector database management interface

---

### Layer 4: Agentic & Toolchain

**george** (FastMCP)
- **Primary:** `fastmcp-main`
- **Secondary:** `magic-mcp`, `shield_mcp_complete`
- **Purpose:** MCP gateway, security patterns

**kevin** (MCP Servers)
- **Primary:** `mcp-server-qdrant-master`
- **Secondary:** `fastmcp-main`
- **Purpose:** Qdrant MCP server implementation

**olivia** (N8N MCP)
- **Primary:** `n8n-mcp-main`
- **Secondary:** `n8n-master`, `n8n-docs`
- **Purpose:** N8N workflow MCP integration

**David** (Crawl4ai)
- **Primary:** `crawl4ai-main`
- **Secondary:** `mcp-crawl4ai-rag`
- **Purpose:** Web scraping, MCP integration

**Diana** (Crawl4ai)
- **Primary:** `crawl4ai-main`
- **Secondary:** `mcp-crawl4ai-rag`, `docling-main`
- **Purpose:** Data extraction, RAG pipelines

**elena** (Docling)
- **Primary:** `docling-main`
- **Secondary:** `docling-mcp`
- **Purpose:** Document processing, parsing

**eric** (Docling MCP)
- **Primary:** `docling-mcp`
- **Secondary:** `docling-main`
- **Purpose:** Document processing MCP server

**marcus** (LightRAG)
- **Primary:** `LightRAG-main`
- **Secondary:** `qdrant-master`, `crawl4ai-main`, `docling-main`
- **Purpose:** Knowledge graph RAG, semantic retrieval

---

### Layer 5: Application

**victor** (Next.js)
- **Primary:** `next.js-canary`, `next.js`, `tailwindcss`
- **Secondary:** `ui-main`, `primitives`, `zustand-main`
- **Purpose:** Frontend development, React applications

**hannah** (CopilotKit)
- **Primary:** `CopilotKit-main`
- **Secondary:** `open-webui-main`, `primitives`, `crayon`, `examples`
- **Purpose:** AI-powered UI components, generative interfaces

**brian** (UI Frameworks)
- **Primary:** `solid-principles`, `ag-ui-main`
- **Secondary:** `ui-main`, `crayon`
- **Purpose:** Reactive UI, agentic interfaces

**fatima** (FastAPI)
- **Primary:** `fastapi-master`, `fastapi`
- **Secondary:** `pydantic-main`
- **Purpose:** API development, async Python

**omar** (N8N)
- **Primary:** `n8n-master`, `n8n-docs`
- **Secondary:** `n8n-mcp-main`
- **Purpose:** Workflow automation, orchestration

**paul** (Open WebUI)
- **Primary:** `open-webui-main`
- **Secondary:** `ollama-main`, `litellm-main`
- **Purpose:** LLM web interfaces

---

### Layer 6: Integration & Testing

**julia** (Testing)
- **Primary:** `cypress`, `pytest`
- **Purpose:** E2E testing, Python testing

**amanda** (Ansible)
- **Primary:** `ansible-devel`
- **Purpose:** Configuration automation, deployment

**nathan** (Monitoring)
- **Secondary:** `open-webui-main`, `qdrant-web-ui`
- **Purpose:** System monitoring, observability

---

### Specialist Agents (Multiple Layers)

**agent-zero** (Orchestration)
- **Primary:** `agentic-design-patterns-docs-main`, `ottomator-agents-main`
- **Purpose:** Agent coordination, design patterns

**Additional Agents:**
- `alex`, `carlos`, `clint`, `code-reviewer`, `context-manager`, `debugger`, `deepak`
- `deployment-engineer`, `isaac`, `mcp-backend-engineer`, `neo`, `ringo`, `technical-researcher`
- `test-automator`, `trinity`

**Note:** Agent profiles are maintained in `/home/agent0/HX-Infrastructure/x-agents/` directory. Refer to individual agent files for complete capabilities and knowledge requirements.

---

## Quick Commands

### Search Knowledge Vault

```bash
# Find documentation about a technology
find /home/agent0/HX-Infrastructure/hx-knowledge/repos -name "*keyword*" -type d

# Search within documentation
grep -r "search term" /home/agent0/HX-Infrastructure/hx-knowledge/repos/

# List all README files
find /home/agent0/HX-Infrastructure/hx-knowledge/repos -name "README.md" -exec echo {} \;

# Search for specific file types
find /home/agent0/HX-Infrastructure/hx-knowledge/repos -name "*.md" | grep -i "docker"
```

### Update All Knowledge

```bash
# Update all git repositories
cd /home/agent0/HX-Infrastructure/hx-knowledge/repos
for dir in */; do
  if [ -d "$dir/.git" ]; then
    echo "Updating $(basename $dir)..."
    (cd "$dir" && git pull)
  fi
done
```

### Check Knowledge Status

```bash
# Show last update time for each repository
for dir in /home/agent0/HX-Infrastructure/hx-knowledge/repos/*/; do
  echo "$(basename $dir): $(stat -c %y $dir | cut -d' ' -f1)"
done | sort -k2
```

### Repository Statistics

```bash
# Count total repositories
ls -1 /home/agent0/HX-Infrastructure/hx-knowledge/repos | wc -l

# List repositories by last modified
ls -lt /home/agent0/HX-Infrastructure/hx-knowledge/repos

# Check repository sizes
du -sh /home/agent0/HX-Infrastructure/hx-knowledge/repos/* | sort -h
```

---

## Integration with HX-Infrastructure

### Relationship with Other Documentation

**This catalog integrates with:**
- **Constitution** (`constitution.md`) - Defines principles for knowledge management
- **Documentation Standards** (`standards/documentation-requirements.md`) - How to document knowledge
- **Architecture Standards** (`standards/architecture-standards.md`) - References to framework patterns
- **Agent Profiles** (`/home/agent0/HX-Infrastructure/x-agents/*.md`) - Agent-specific knowledge requirements
- **Service Specs** (`services/*/spec.md`) - Technology stack references
- **Credentials Documentation** (`hx-knowledge/docs/0.0.5.2.1-credentials.md`) - Infrastructure credentials (🔴 MUST READ)

---

## Related Documents

- **HX-Infrastructure Constitution:** `/home/agent0/HX-Infrastructure/constitution.md`
- **Agent Profiles Directory:** `/home/agent0/HX-Infrastructure/x-agents/`
- **Naming Conventions:** `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
- **Architecture Standards:** `/home/agent0/HX-Infrastructure/standards/architecture-standards.md`
- **Credentials Documentation:** `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (🔴 MUST READ)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-15 | Initial HX-Infrastructure catalog created from Hana-X migration | Infrastructure Team |
| | | - Updated all paths to HX-Infrastructure structure | |
| | | - Document location: hx-agents/hx-knowledge-vault-catalog.md | |
| | | - Knowledge vault: hx-knowledge/repos/ | |
| | | - Added 6 missing repositories (crayon, examples, n8n-docs, next.js, node, pythondotorg) | |
| | | - Verified all 55 repositories documented | |
| | | - Updated agent references to current HX-Infrastructure agents | |

---

**Document Type:** Infrastructure - Agent Knowledge Management  
**Classification:** Internal  
**Status:** ✅ ACTIVE - Primary knowledge reference for all agents  
**Maintained By:** Infrastructure Team  
**Last Review:** November 15, 2025  
**Next Review:** February 15, 2026 (Quarterly)

---

*This catalog serves as the authoritative index for all knowledge resources available to HX-Infrastructure agents. All agents should consult this catalog when seeking documentation or reference materials for their work.*
