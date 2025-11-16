/home/agent0/HX-Infrastructure/
│
├── constitution.md                          ✅ EXISTS (needs review/finalization)
├── README.md                                ❌ MISSING - Phase 1
├── action-plan-v2.1.md                     🆕 NEEDS MOVE from outputs
├── .gitignore                               ⚠️  VERIFY - Critical security
│
├── .claude/                                 ❌ MISSING - Phase 1
│   ├── deploy.md
│   ├── configure.md
│   └── verify.md
│
├── hx-agents/                               ⚠️  NEEDS DIRECTORY
│   ├── hx-agent-inventory.md               ✅ EXISTS (move here)
│   ├── hx-knowledge-vault-catalog.md       ✅ EXISTS (move here)
│   ├── hx-orchestration-guide.md           ✅ EXISTS (move here)
│   └── hx-orchestration-quick-ref.md       ❌ MISSING - Phase 1
│
├── hx-knowledge/                            ❌ MISSING - Phase 1
│   ├── repos/                               (55 repositories)
│   └── docs/
│       └── credentials/                     (from credentials-vault-management.md)
│
├── standards/                               ⚠️  NEEDS DIRECTORY
│   ├── naming-conventions.md               ✅ EXISTS (move here)
│   ├── architecture-standards.md           ✅ EXISTS (move here)
│   ├── credentials-vault-management.md     ✅ EXISTS (move here)
│   ├── documentation-requirements.md       ✅ EXISTS (move here)
│   ├── deployment-requirements.md          ✅ EXISTS (move here)
│   └── testing-requirements.md             ✅ EXISTS (move here)
│
├── templates/                               ⚠️  NEEDS DIRECTORY
│   ├── node-template.md                    ✅ EXISTS (move here)
│   ├── project-charter-template.md         🆕 NEEDS MOVE from outputs
│   ├── service-spec-template.md            ✅ EXISTS (move here)
│   ├── service-plan-template.md            ✅ EXISTS (move here)
│   ├── service-tasks-template.md           ✅ EXISTS (move here)
│   ├── service-architecture-template.md    🆕 NEEDS MOVE from outputs
│   ├── poc-template.md                     ✅ EXISTS (move here)
│   └── testing/                            ⚠️  NEEDS SUBDIRECTORY
│       ├── test-plan-template.md           ✅ EXISTS (move here)
│       ├── test-case-template.md           ✅ EXISTS (move here)
│       ├── test-execution-template.md      ✅ EXISTS (move here)
│       ├── defect-template.md              ✅ EXISTS (move here)
│       └── test-suite-index-template.md    ✅ EXISTS (move here)
│
├── inventory/                               ❌ MISSING - Phase 2
│   ├── nodes.md                            🆕 NEEDS MOVE from uploads
│   ├── services.md                         ❌ MISSING
│   └── network-topology.md                 ❌ MISSING
│
├── nodes/                                   ❌ MISSING - Phase 5
│   ├── hx-dc-server/
│   │   ├── node-spec.md
│   │   ├── services-deployed.md
│   │   └── configuration/
│   ├── hx-ca-server/
│   ├── hx-ssl-server/
│   ├── hx-control-node/
│   ├── hx-ollama1-server/
│   ├── hx-ollama2-server/
│   ├── hx-ollama3-server/
│   ├── hx-litellm-server/
│   ├── hx-postgres-server/
│   ├── hx-redis-server/
│   ├── hx-qdrant-server/
│   ├── hx-qdrant-ui-server/
│   ├── hx-qmcp-server/
│   ├── hx-fastmcp-server/
│   ├── hx-n8n-mcp-server/
│   ├── hx-n8n-server/
│   ├── hx-docling-server/
│   ├── hx-crawl4ai-mcp-server/
│   ├── hx-crawl4ai-server/
│   ├── hx-literag-server/
│   └── hx-webui-server/
│       ├── node-spec.md
│       ├── services-deployed.md
│       └── configuration/
│
├── services/                                ❌ MISSING - Phases 6-7
│   ├── operational/
│   │   ├── samba-dc/
│   │   │   ├── charter.md
│   │   │   ├── spec.md
│   │   │   ├── deployment/
│   │   │   │   └── architecture.md
│   │   │   ├── plan.md
│   │   │   ├── tasks/
│   │   │   └── tests/
│   │   ├── internal-ca/
│   │   ├── reverse-proxy/
│   │   ├── ansible-automation/
│   │   ├── ollama-primary/
│   │   ├── ollama-code/
│   │   ├── ollama-embeddings/
│   │   ├── litellm-gateway/
│   │   ├── postgresql/
│   │   ├── redis/
│   │   ├── qdrant/
│   │   ├── qdrant-ui/
│   │   ├── qdrant-mcp/
│   │   ├── fastmcp/
│   │   ├── n8n-mcp/
│   │   ├── n8n-workflows/
│   │   ├── docling/
│   │   ├── crawl4ai-mcp/
│   │   ├── crawl4ai/
│   │   ├── literag/
│   │   └── open-webui/
│   │       ├── charter.md
│   │       ├── spec.md
│   │       ├── deployment/
│   │       │   └── architecture.md
│   │       ├── plan.md
│   │       ├── tasks/
│   │       └── tests/
│   │           ├── test-plan.md
│   │           └── test-suite/
│   │               ├── deployment/
│   │               ├── functionality/
│   │               ├── integration/
│   │               └── health-check/
│   └── non-operational/
│       ├── hx-agui/
│       ├── hx-metric-server/
│       ├── hx-lang-server/
│       ├── hx-dev-server/
│       ├── hx-docling-mcp/
│       └── hx-demo-server/
│
├── network/                                 ❌ MISSING - Phase 2
│   ├── topology.md
│   ├── port-mapping.md
│   └── connectivity.md
│
└── procedures/                              ❌ MISSING - Phase 3
    ├── node-provisioning.md
    ├── service-deployment.md
    ├── test-execution.md
    ├── defect-management.md
    ├── service-promotion.md
    └── troubleshooting.md