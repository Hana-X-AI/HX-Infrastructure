# Test Case: Qdrant Vector Database Connection

**Test ID**: tc-docling-mcp-integration-002
**Test Area**: Integration Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify Qdrant vector database connection and collection access for knowledge graph storage.

---

## Test Coverage

**Requirements Covered**:
- FR-022: Integrate with Qdrant (hx-qdrant-server:6333)
- FR-015: Store knowledge graphs in Qdrant
- Charter SC-004: Qdrant Integration

---

## Test Steps

### Step 1: Verify Qdrant Connection

**Action**:
```bash
curl -s http://hx-qdrant-server.hx.dev.local:6333/health
curl -s http://hx-qdrant-server.hx.dev.local:6333/collections
```

**Expected**: Qdrant responds with healthy status

---

### Step 2: Verify Collection Creation

**Action**:
```bash
# Check for docling_mcp collections
curl -s http://hx-qdrant-server.hx.dev.local:6333/collections | jq '.result.collections[] | select(.name | contains("docling_mcp"))'
```

**Expected**: docling_mcp_entities and docling_mcp_relationships collections exist (or can be created)

---

### Step 3: Test Vector Upsert

**Action**:
```bash
# Test upsert operation
curl -X PUT http://hx-qdrant-server.hx.dev.local:6333/collections/docling_mcp_entities/points \
  -H "Content-Type: application/json" \
  -d '{
    "points": [{
      "id": "test-entity-001",
      "vector": [0.1, 0.2, 0.3, ...],
      "payload": {"entity_type": "test", "name": "Test Entity"}
    }]
  }'
```

**Expected**: Upsert successful, no errors

---

## Pass/Fail Criteria

**PASS**: Qdrant reachable, collections accessible, upsert functional

**FAIL**: Cannot connect to Qdrant or operations fail

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-int-002-qdrant-unavailable.md`

---

**Test Case Version**: 1.0
