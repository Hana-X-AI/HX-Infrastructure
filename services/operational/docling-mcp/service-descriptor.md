# docling-mcp Service Descriptor

**Service Name**: docling-mcp  
**Node**: hx-docling-mcp-server.hx.dev.local  
**IP Address**: 192.168.10.217  
**Port**: 8000  
**Status**: ✅ OPERATIONAL  
**Operational Date**: 2025-12-04

---

## Description

Document processing MCP (Model Context Protocol) server providing AI agents with document conversion, generation, and manipulation capabilities via the FastMCP framework.

---

## Service Details

| Property | Value |
|----------|-------|
| Service User | docling-mcp |
| Install Path | /opt/docling-mcp |
| Virtual Environment | /opt/docling-mcp/venv |
| Application Path | /opt/docling-mcp/application |
| Config File | /opt/docling-mcp/application/.env |
| Systemd Unit | docling-mcp.service |
| Log Location | journalctl -u docling-mcp |

---

## Dependencies

| Service | Endpoint | Purpose |
|---------|----------|---------|
| LiteLLM | hx-litellm-server.hx.dev.local:4000 | LLM inference |
| Qdrant | hx-qdrant-server.hx.dev.local:6333 | Vector storage |
| Redis | hx-redis-server.hx.dev.local:6379 | Session/cache |
| LiteRAG | hx-literag-server.hx.dev.local:8080 | Knowledge graph |

---

## Health Check

```bash
curl http://hx-docling-mcp-server.hx.dev.local:8000/health
```

---

## Related Documentation

- **Node Documentation**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/`
- **Charter**: `nodes/hx-docling-mcp-server/charter/charter.md`
- **Specification**: `nodes/hx-docling-mcp-server/specification/node-spec.md`

---

**Last Updated**: 2025-12-04
