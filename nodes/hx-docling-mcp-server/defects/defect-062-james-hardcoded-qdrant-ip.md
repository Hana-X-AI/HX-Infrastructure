# DEFECT-062: Hardcoded Qdrant IP in James MCP Tools Example

**Severity**: MEDIUM
**Status**: CLOSED
**Created**: 2025-11-30
**Closed**: 2025-11-30
**Affects**: nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/james-mcp-tools.md

---

## Description

Example code in james-mcp-tools.md contains hardcoded Qdrant hostname `hx-qdrant-server.hx.dev.local` instead of using environment variable or configurable reference. While this is a hostname (not an IP address), it should still be configurable via environment variables for flexibility across different deployments.

## Impact

- **Maintenance**: Hardcoded hostnames create fragility when infrastructure changes or different environments use alternate service names
- **Portability**: Cannot deploy to different environments without code modification
- **Best Practices**: Violates HX-Infrastructure standards (use configurable environment variables with sensible defaults)

## Root Cause

Example code written with hardcoded hostname instead of configurable environment variable reference.

## Location

File: `nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/james-mcp-tools.md`
Lines: ~210

**Before:**
```python
qdrant_config={
    "host": "hx-qdrant-server.hx.dev.local",
    "port": 6333,
    "collection_entities": "hx_docling_mcp_entities",
    "collection_relationships": "hx_docling_mcp_relationships"
}
```

## Resolution

**After:**
```python
qdrant_config={
    "host": os.getenv("QDRANT_HOST", "hx-qdrant-server.hx.dev.local"),
    "port": int(os.getenv("QDRANT_PORT", "6333")),
    "collection_entities": "hx_docling_mcp_entities",
    "collection_relationships": "hx_docling_mcp_relationships"
}
```

Changed to:
- Use `os.getenv("QDRANT_HOST", ...)` for configurable host
- Default to hostname `hx-qdrant-server.hx.dev.local` instead of IP
- Use `os.getenv("QDRANT_PORT", ...)` for configurable port
- Cast port to int since environment variables are strings

## Testing

- ✅ Verified no remaining hardcoded hostnames in file
- ✅ Example code now follows HX-Infrastructure standards

## Prevention

- Code review checklist item: No hardcoded hostnames or connection strings in example code
- Use environment variables with sensible hostname defaults
