# Test Case: LightRAG Knowledge Graph Engine Integration

**Test ID**: tc-docling-mcp-integration-004
**Test Area**: Integration Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify LightRAG knowledge graph engine integration for entity extraction and Qdrant storage.

---

## Test Coverage

**Requirements Covered**:
- FR-011: Integrate LightRAG for entity extraction and relationship modeling
- FR-013: Extract structured entities
- FR-014: Extract relationships
- Charter SC-003: Knowledge Graph via LightRAG

---

## Test Steps

### Step 1: Verify LightRAG Installation

**Action**:
```bash
/opt/docling-mcp/venv/bin/python -c "import lightrag; print('LightRAG version:', lightrag.__version__)"
```

**Expected**: LightRAG imports successfully

---

### Step 2: Test Entity Extraction

**Action**:
```bash
# Invoke generate_knowledge_graph tool (which uses LightRAG)
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "generate_knowledge_graph",
      "arguments": {
        "source": "/opt/docling-mcp/tests/test-data/sample-document.pdf"
      }
    },
    "id": 1
  }'
```

**Expected**: Entities extracted and returned

---

### Step 3: Verify Entities Stored in Qdrant

**Action**:
```bash
# Query Qdrant for entities
curl -X POST http://hx-qdrant-server.hx.dev.local:6333/collections/docling_mcp_entities/points/scroll \
  -H "Content-Type: application/json" \
  -d '{"limit": 10}'
```

**Expected**: Entities from document stored in Qdrant

**Pass Criteria**: Entity extraction works, storage in Qdrant successful

---

## Pass/Fail Criteria

**PASS**: LightRAG functional, entities extracted and stored

**FAIL**: LightRAG errors, extraction fails, or storage fails

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-int-004-lightrag-failed.md`

---

**Test Case Version**: 1.0
