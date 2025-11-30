# DEFECT-062: Hardcoded Qdrant IP in James MCP Tools Example

**Severity**: MEDIUM
**Status**: CLOSED
**Created**: 2025-11-30
**Closed**: 2025-11-30
**Affects**: nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/james-mcp-tools.md

---

## Description

Example code in james-mcp-tools.md contains hardcoded Qdrant IP address `192.168.10.223` instead of using environment variable or hostname reference.

## Impact

- **Maintenance**: Hardcoded IPs create fragility when infrastructure changes
- **Portability**: Cannot deploy to different environments without code modification
- **Best Practices**: Violates HX-Infrastructure standards (use hostnames, not IPs)

## Root Cause

Example code written with specific IP instead of configurable reference.

## Location

File: `nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/james-mcp-tools.md`
Lines: ~210

**Before:**
```python
qdrant_config={
    "host": "192.168.10.223",
    "port": 6333,
    "collection_entities": "docling_entities",
    "collection_relationships": "docling_relationships"
}
```

## Resolution

**After:**
```python
qdrant_config={
    "host": os.getenv("QDRANT_HOST", "hx-qdrant-server.hx.dev.local"),
    "port": int(os.getenv("QDRANT_PORT", "6333")),
    "collection_entities": "docling_entities",
    "collection_relationships": "docling_relationships"
}
```

Changed to:
- Use `os.getenv("QDRANT_HOST", ...)` for configurable host
- Default to hostname `hx-qdrant-server.hx.dev.local` instead of IP
- Use `os.getenv("QDRANT_PORT", ...)` for configurable port
- Cast port to int since environment variables are strings

## Testing

- ✅ Verified no remaining hardcoded IPs in file
- ✅ Example code now follows HX-Infrastructure standards

## Prevention

- Code review checklist item: No hardcoded IP addresses in example code
- Use environment variables with hostname defaults
