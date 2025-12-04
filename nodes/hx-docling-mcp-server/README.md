# hx-docling-mcp-server

**Node**: hx-docling-mcp-server.hx.dev.local  
**IP Address**: 192.168.10.217  
**Port**: 8000  
**Status**: ✅ OPERATIONAL  
**Operational Date**: 2025-12-04

---

## Overview

Document processing MCP (Model Context Protocol) server providing AI agents with document conversion, generation, and manipulation capabilities via the FastMCP framework. Integrates with Docling for multi-format document parsing, LiteLLM for LLM inference, Qdrant for vector storage, Redis for caching/sessions, and LiteRAG for knowledge graph extraction.

---

## Quick Start

```bash
# Check service status
ssh agent0@hx-docling-mcp-server.hx.dev.local 'systemctl status hx-docling-mcp'

# View logs
ssh agent0@hx-docling-mcp-server.hx.dev.local 'journalctl -u hx-docling-mcp -f'

# Health check
curl http://hx-docling-mcp-server.hx.dev.local:8000/health

# MCP tools list
curl http://hx-docling-mcp-server.hx.dev.local:8000/mcp/tools
```

---

## Integration Endpoints

| Service | Endpoint | Purpose |
|---------|----------|---------|
| LiteLLM | hx-litellm-server.hx.dev.local:4000 | LLM inference for entity/relationship extraction |
| Qdrant | hx-qdrant-server.hx.dev.local:6333 | Vector storage for embeddings |
| Redis | hx-redis-server.hx.dev.local:6379 | Session management and caching |
| LiteRAG | hx-literag-server.hx.dev.local:8080 | Knowledge graph extraction |

---

## MCP Tools

### Conversion Tools
- `convert_pdf` - Convert PDF documents to DoclingDocument
- `convert_docx` - Convert Word documents to DoclingDocument
- `convert_url` - Convert web pages to DoclingDocument

### Generation Tools
- `generate_knowledge_graph` - Extract entities and relationships
- `generate_title` - Generate document title
- `generate_toc` - Generate table of contents
- `generate_section` - Create document section
- `generate_heading` - Create heading element
- `generate_paragraph` - Create paragraph element
- `generate_list` - Create list element
- `generate_table` - Create table element
- `generate_image` - Insert image reference
- `generate_codeblock` - Create code block
- `generate_reference` - Create cross-reference

### Manipulation Tools
- `split_document` - Split document into sections
- `merge_documents` - Merge multiple documents
- `export_markdown` - Export to Markdown format
- `export_html` - Export to HTML format
- `export_json` - Export to JSON format

### System Tools
- `health_check` - Service health status

---

## Project Structure

```
nodes/hx-docling-mcp-server/
├── README.md                    # This file
├── charter/
│   └── charter.md              # Project charter (OPERATIONAL)
├── specification/
│   └── node-spec.md            # Service specification (IMPLEMENTED)
├── planning/
│   ├── plan.md                 # Deployment plan (COMPLETE)
│   ├── configuration-spec.md   # Configuration details (COMPLETE)
│   └── deployment-architecture.md  # Architecture design (COMPLETE)
├── deployment/
│   └── plan.md                 # Deployment procedures
├── tasks/                      # Task definitions and tracking
├── tests/
│   ├── test-plan.md           # Test plan (COMPLETE)
│   ├── test-execution-tracking.md  # Test results
│   └── test-suite/            # Test case definitions
├── defects/                    # Defect tracking
└── vault/                      # Ansible Vault credentials
```

---

## Key Documents

| Document | Location | Status |
|----------|----------|--------|
| Charter | `charter/charter.md` | ✅ OPERATIONAL |
| Specification | `specification/node-spec.md` | ✅ IMPLEMENTED |
| Deployment Plan | `planning/plan.md` | ✅ COMPLETE |
| Configuration | `planning/configuration-spec.md` | ✅ COMPLETE |
| Architecture | `planning/deployment-architecture.md` | ✅ COMPLETE |
| Test Plan | `tests/test-plan.md` | ✅ COMPLETE |
| Defect Summary | `defects/defect-summary-2025-12-01.md` | ✅ RESOLVED |

---

## Administration

```bash
# Start service
ssh agent0@hx-docling-mcp-server.hx.dev.local 'sudo systemctl start hx-docling-mcp'

# Stop service
ssh agent0@hx-docling-mcp-server.hx.dev.local 'sudo systemctl stop hx-docling-mcp'

# Restart service
ssh agent0@hx-docling-mcp-server.hx.dev.local 'sudo systemctl restart hx-docling-mcp'

# Enable on boot
ssh agent0@hx-docling-mcp-server.hx.dev.local 'sudo systemctl enable hx-docling-mcp'
```

---

## Related Documentation

- **HX-Infrastructure**: `/home/agent0/HX-Infrastructure/`
- **Node Inventory**: `/home/agent0/HX-Infrastructure/inventory/nodes.md`
- **Naming Standards**: `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`

---

**Last Updated**: 2025-12-04
