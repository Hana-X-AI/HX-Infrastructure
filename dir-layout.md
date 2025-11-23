# HX-Infrastructure Directory Layout

**Last Updated**: 2025-11-23  
**Purpose**: Complete directory structure reference for HX-Infrastructure repository

---

## Directory Structure

```
/home/agent0/HX-Infrastructure/
│
├── hx-agents/                           ← Agent Documentation
│   ├── hx-agent-inventory.md            ← All 45 agents inventory
│   ├── hx-knowledge-vault-catalog.md    ← Knowledge repository catalog
│   ├── hx-orchestration-guide.md        ← Agent Zero orchestration guide
│   ├── hx-orchestration-quick-ref.md    ← Quick reference
│   └── README.md                        ← Agent documentation index
│
├── inventory/                           ← Infrastructure Inventories
│   ├── nodes.md                         ← Node inventory
│   └── README.md                        ← Inventory index
│
├── network/                             ← Network Documentation
│   ├── network-topology.md              ← Network topology
│   ├── network-troubleshooting.md       ← Troubleshooting guide
│   └── README.md                        ← Network documentation index
│
├── nodes/                               ← Server Node Configurations (21 nodes)
│   ├── hx-ca-server/                    ← Internal CA server
│   ├── hx-control-node/                 ← Ansible control node
│   ├── hx-crawl4ai-mcp-server/          ← Crawl4AI MCP server
│   ├── hx-crawl4ai-server/              ← Crawl4AI worker server
│   ├── hx-dc-server/                    ← Samba domain controller
│   ├── hx-docling-server/               ← Docling worker server
│   ├── hx-fastmcp-server/               ← FastMCP gateway server
│   ├── hx-litellm-server/               ← LiteLLM gateway server
│   ├── hx-literag-server/               ← LiteRAG server
│   ├── hx-n8n-mcp-server/               ← N8N MCP server
│   ├── hx-n8n-server/                   ← N8N workflow server
│   ├── hx-ollama1-server/               ← Ollama primary server
│   ├── hx-ollama2-server/               ← Ollama code server
│   ├── hx-ollama3-server/               ← Ollama embeddings server
│   ├── hx-postgres-server/              ← PostgreSQL database server
│   ├── hx-qdrant-server/                ← Qdrant vector database server
│   ├── hx-qdrant-ui-server/             ← Qdrant UI server
│   ├── hx-qmcp-server/                  ← Qdrant MCP server
│   ├── hx-redis-server/                 ← Redis cache server
│   ├── hx-ssl-server/                   ← Reverse proxy server
│   └── hx-webui-server/                 ← Open WebUI server
│
├── procedures/                          ← Workflows & Processes
│   ├── examples/                        ← Example applications
│   ├── charter-workflow.md              ← Charter creation process
│   ├── context-loading-process.md       ← Context loading process
│   ├── core-project-team.md             ← Core team structure
│   ├── network-health-check.sh          ← Network health check script
│   ├── node-deployment-workflow.md      ← Node deployment process
│   ├── project-closeout-workflow.md     ← Project closeout process
│   ├── spec-workflow.md                 ← Specification development
│   ├── task-execution-workflow.md       ← Task execution process
│   ├── task-workflow.md                 ← Task workflow process
│   └── testing-knowledge-research-process.md  ← Research process
│
├── services/                            ← Service Configurations
│   ├── non-operational/                 ← Non-operational services (6)
│   │   ├── hx-agui/                     ← AG-UI service
│   │   ├── hx-demo-server/              ← Demo server
│   │   ├── hx-dev-server/               ← Development server
│   │   ├── hx-docling-mcp/              ← Docling MCP service
│   │   ├── hx-lang-server/              ← Language server
│   │   └── hx-metric-server/            ← Metrics server
│   └── operational/                     ← Operational services (21)
│       ├── ansible-automation/          ← Ansible automation
│       ├── crawl4ai/                    ← Crawl4AI worker
│       ├── crawl4ai-mcp/                ← Crawl4AI MCP
│       ├── docling/                     ← Docling worker
│       ├── fastmcp/                     ← FastMCP gateway
│       ├── internal-ca/                 ← Internal CA
│       ├── litellm-gateway/             ← LiteLLM gateway
│       ├── literag/                     ← LiteRAG service
│       ├── n8n-mcp/                     ← N8N MCP
│       ├── n8n-workflows/               ← N8N workflows
│       ├── ollama-code/                 ← Ollama code models
│       ├── ollama-embeddings/           ← Ollama embeddings
│       ├── ollama-primary/              ← Ollama primary models
│       ├── open-webui/                  ← Open WebUI
│       ├── postgresql/                  ← PostgreSQL database
│       ├── qdrant/                      ← Qdrant vector DB
│       ├── qdrant-mcp/                  ← Qdrant MCP
│       ├── qdrant-ui/                   ← Qdrant UI
│       ├── redis/                       ← Redis cache
│       ├── reverse-proxy/               ← Reverse proxy
│       └── samba-dc/                    ← Samba domain controller
│
├── standards/                           ← Governance Standards
│   ├── architecture-standards.md        ← Architecture standards
│   ├── credentials-vault-management.md  ← Vault management (git-ignored)
│   ├── deployment-requirements.md       ← Deployment requirements
│   ├── documentation-requirements.md    ← Documentation requirements
│   ├── naming-conventions.md            ← Naming conventions
│   ├── testing-requirements.md          ← Testing requirements
│   └── utility-development-standards.md ← Utility development standards
│
├── templates/                           ← Fill-in Templates
│   ├── testing/                         ← Testing templates
│   │   ├── defect-template.md           ← Defect report template
│   │   ├── test-case-template.md        ← Test case template
│   │   ├── test-execution-template.md   ← Test execution template
│   │   ├── test-plan-template.md        ← Test plan template
│   │   └── test-suite-index-template.md ← Test suite index template
│   ├── charter-questions-template.md    ← Charter questions template
│   ├── charter-template.md              ← Charter template
│   ├── knowledge-vault-research-template.md  ← Research template
│   ├── node-deployment-plan-template.md ← Deployment plan template
│   ├── node-template.md                 ← Node template
│   ├── poc-template.md                  ← POC template
│   ├── raidd-log-template.md            ← RAIDD log template
│   ├── README.md                        ← Templates index
│   ├── research-findings-template.md    ← Research findings template
│   ├── service-architecture-template.md ← Service architecture template
│   ├── service-plan-template.md         ← Service plan template
│   ├── service-spec-template.md         ← Service specification template
│   └── service-tasks-template.md        ← Service tasks template
│
├── CLAUDE.md                            ← Claude project context
├── command-quick-reference.md           ← Command quick reference
├── constitution.md                      ← Project constitution
├── dir-layout.md                        ← This file - directory structure
├── .gitignore                           ← Git ignore rules
└── README.md                            ← Project README
```

---

## Git-Ignored Directories

The following directories exist locally but are excluded from version control:

- **hx-knowledge/** - Knowledge vault with 58 repositories
  - **hx-knowledge/repos/** - Cloned repositories (docling, litellm, LightLLM, svelte, shadcn-ui, mcp-crawl4ai-rag, etc.)
  - **hx-knowledge/docs/** - Documentation files
- **x-agents/** - 34 agent profile copies (local working copies)
- **x-archive/** - Archived files and old agent profiles
- **x-claude/** - Claude workspace files and standards reviews
- **x-files/** - Temporary files
- All directories/files starting with `x-*` pattern

---

## Directory Counts

- **Nodes**: 21 server configurations
- **Operational Services**: 21 services
- **Non-operational Services**: 6 services
- **Standards**: 7 documents
- **Templates**: 13 main + 5 testing templates = 18 total
- **Procedures**: 10 workflow documents + 1 examples directory
- **Agent Docs**: 5 documents
- **Knowledge Repos**: 58 repositories
- **Agent Profiles**: 34 local copies (x-agents/)

---

## File Naming Conventions

- Node directories: `hx-{service}-server/`
- Service directories: `{service-name}/` (lowercase with hyphens)
- Markdown files: `{descriptive-name}.md` (lowercase with hyphens)
- Templates: `{type}-template.md`
- Standards: `{topic}-standards.md` or `{topic}-requirements.md`

---

## Repository Information

- **Repository**: <https://github.com/Hana-X-AI/HX-Infrastructure>
- **Branch**: main
- **Owner**: Hana-X-AI
- **Last Structure Update**: 2025-11-23
