# DEFECT-063: Absolute Path and Hardcoded IPs in Shane LiteLLM Integration

**Severity**: LOW
**Status**: CLOSED
**Created**: 2025-11-30
**Closed**: 2025-11-30
**Affects**: nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/shane-litellm-integration.md

---

## Description

Shane's LiteLLM integration specification contains:
1. Absolute path reference that should be repository-relative
2. Multiple hardcoded IP addresses in documentation text

## Impact

- **Portability**: Absolute paths break when repository relocated
- **Consistency**: Should use hostnames instead of IPs per HX standards
- **Maintainability**: Infrastructure changes require documentation updates

## Root Cause

Documentation written with absolute paths and IP addresses instead of relative references and hostnames.

## Issues Found

### Issue 1: Absolute Path (Line 175)
**Before:**
```markdown
- Create `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/benchmarks/litellm-models-benchmark-results.md`
```

**After:**
```markdown
- Create `nodes/hx-docling-mcp-server/benchmarks/litellm-models-benchmark-results.md`
```

### Issue 2: Hardcoded IPs in Documentation (Lines 37, 42, 47, 79, 95, 108, 122, 135)
**Before:**
- `via Ollama1 (192.168.10.204)`
- `via Ollama2 (192.168.10.205)`
- `Ollama1 server (192.168.10.204)`
- `Ollama2 server (192.168.10.205)`

**After:**
- `via hx-ollama1-server`
- `via hx-ollama2-server`
- `hx-ollama1-server`
- `hx-ollama2-server`

## Resolution

Used sed to replace all occurrences:
```bash
sed -i \
  -e 's|/home/agent0/HX-Infrastructure/nodes/|nodes/|' \
  -e 's|Ollama1 server (192\.168\.10\.204)|hx-ollama1-server|g' \
  -e 's|Ollama2 server (192\.168\.10\.205)|hx-ollama2-server|g' \
  -e 's|Ollama1 (192\.168\.10\.204)|hx-ollama1-server|g' \
  -e 's|Ollama2 (192\.168\.10\.205)|hx-ollama2-server|g' \
  shane-litellm-integration.md
```

## Testing

- ✅ Verified no remaining absolute paths
- ✅ Verified no remaining hardcoded IPs
- ✅ Hostnames used consistently

## Prevention

- Use repository-relative paths in all documentation
- Reference servers by hostname, not IP
- Code review checklist: Check for absolute paths and hardcoded IPs
