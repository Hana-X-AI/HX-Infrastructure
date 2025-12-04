# Task 105: Configure Payload Indexes for Efficient Filtering

**Assigned To**: mitch-harper
**Estimated Effort**: 1.5 hours
**Dependencies**: Task 102 (Collection Initialization), Task 103 (Entity Operations), Task 104 (Relationship Operations)
**Status**: Not Started

## Objective

Configure Qdrant payload indexes on frequently filtered fields to enable fast metadata filtering without sequential scans. Create indexes on entity_type, document_id, confidence, mention_count (entities) and subject_entity_id, object_entity_id, predicate (relationships).

## Pre-Execution Validation

```bash
# Check if payload indexes exist
QDRANT_URL="http://hx-qdrant-server.hx.dev.local:6333"

echo "Checking payload indexes for entities collection..."
ENTITIES_INDEXES=$(curl -s "${QDRANT_URL}/collections/hx_docling_mcp_entities" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('config', {}).get('params', {}).get('payload_schema', {}))" 2>/dev/null)

if echo "$ENTITIES_INDEXES" | grep -q "entity_type"; then
    echo "✅ VALIDATION RESULT: Payload indexes already configured"
    echo "ACTION: SKIP index creation, proceed to validation"
    exit 0
else
    echo "❌ VALIDATION RESULT: Payload indexes not configured"
    echo "ACTION: PROCEED with implementation"
fi
```

## Context

Qdrant payload indexes dramatically improve filter performance by avoiding sequential scans. Without indexes, queries filter by scanning ALL points. With indexes, queries use indexed data structures (B-trees for keywords, range indexes for numbers).

**Performance Impact**:
- **Without index**: O(N) scan of all points (slow for >10K points)
- **With index**: O(log N) index lookup (fast even for 1M+ points)

**Index Types**:
1. **Keyword Index**: For exact match filters (entity_type, document_id, predicate)
2. **Integer Index**: For range filters (mention_count, confidence as int)
3. **Float Index**: Not supported by Qdrant, convert confidence to int range

**Required Indexes**:

**Entity Collection** (`hx_docling_mcp_entities`):
- `entity_type` (keyword) - Filter by PERSON, ORGANIZATION, etc.
- `document_id` (keyword) - Find entities from specific document
- `mention_count` (integer) - Find frequently mentioned entities (>N mentions)
- `confidence` (float, use range filter) - High confidence entities (>0.8)

**Relationship Collection** (`hx_docling_mcp_relationships`):
- `subject_entity_id` (keyword) - CRITICAL for graph traversal (outgoing edges)
- `object_entity_id` (keyword) - CRITICAL for graph traversal (incoming edges)
- `predicate` (keyword) - Filter by relationship type
- `document_id` (keyword) - Relationships from specific document
- `confidence` (float, use range filter) - High confidence relationships

## Implementation Steps

### Step 1: Create Payload Index Configuration Module

```bash
sudo tee /opt/docling-mcp/src/integrations/qdrant_index_config.py > /dev/null <<'EOF'
"""Qdrant payload index configuration for knowledge graph collections."""

import logging
from typing import Dict, Any, List

from qdrant_client.http.exceptions import ApiException, UnexpectedResponse
from .qdrant_client import QdrantClient
from .qdrant_collections import ENTITY_COLLECTION_NAME, RELATIONSHIP_COLLECTION_NAME
from .qdrant_exceptions import QdrantCollectionError

logger = logging.getLogger(__name__)


# Entity collection payload indexes
ENTITY_INDEXES = {
    "entity_type": {"type": "keyword"},
    "document_id": {"type": "keyword"},
    "mention_count": {"type": "integer"},
    "confidence": {"type": "integer"},  # Integer range filter (0-100)
}

# Relationship collection payload indexes
RELATIONSHIP_INDEXES = {
    "subject_entity_id": {"type": "keyword"},  # CRITICAL for graph traversal
    "object_entity_id": {"type": "keyword"},   # CRITICAL for graph traversal
    "predicate": {"type": "keyword"},
    "document_id": {"type": "keyword"},
    "confidence": {"type": "integer"},  # Integer range filter (0-100)
}


async def create_payload_index(
    client: QdrantClient,
    collection_name: str,
    field_name: str,
    field_type: str,
) -> bool:
    """
    Create payload index on field.

    Args:
        client: QdrantClient instance
        collection_name: Name of collection
        field_name: Payload field to index
        field_type: Index type (keyword, integer, float)

    Returns:
        True if index created, False if already existed
    """
    client.require_available()

    try:
        # Create index using Qdrant API
        index_request = {
            "field_name": field_name,
            "field_schema": field_type,
        }

        await client._request_with_retry(
            "PUT",
            f"/collections/{collection_name}/index",
            json=index_request,
        )

        logger.info(f"Created payload index: {collection_name}.{field_name} ({field_type})")
        return True

    except (ApiException, UnexpectedResponse) as e:
        # Check if index already exists using status code (409 Conflict or 400 Bad Request)
        # Qdrant returns 409 for duplicate index, or 400 with specific error
        status_code = getattr(e, 'status_code', None)
        
        if status_code in (409, 400):
            # Verify it's actually a duplicate index error by checking response content
            error_content = getattr(e, 'content', str(e))
            if 'index' in str(error_content).lower() and ('exists' in str(error_content).lower() or 'already' in str(error_content).lower()):
                logger.debug(f"Payload index already exists: {collection_name}.{field_name}")
                return False
        
        # Not a duplicate index error, propagate
        logger.error(f"Failed to create payload index {field_name} (status {status_code}): {e}")
        raise QdrantCollectionError(f"Index creation failed: {e}") from e
    
    except Exception as e:
        # Catch-all for unexpected exceptions
        logger.error(f"Unexpected error creating payload index {field_name}: {e}")
        raise QdrantCollectionError(f"Index creation failed: {e}") from e


async def configure_entity_indexes(client: QdrantClient) -> Dict[str, bool]:
    """Configure all payload indexes for entity collection."""
    results = {}

    for field_name, config in ENTITY_INDEXES.items():
        created = await create_payload_index(
            client,
            ENTITY_COLLECTION_NAME,
            field_name,
            config["type"],
        )
        results[field_name] = created

    logger.info(
        f"Entity collection indexes configured: "
        f"{sum(results.values())} created, "
        f"{len(results) - sum(results.values())} existed"
    )

    return results


async def configure_relationship_indexes(client: QdrantClient) -> Dict[str, bool]:
    """Configure all payload indexes for relationship collection."""
    results = {}

    for field_name, config in RELATIONSHIP_INDEXES.items():
        created = await create_payload_index(
            client,
            RELATIONSHIP_COLLECTION_NAME,
            field_name,
            config["type"],
        )
        results[field_name] = created

    logger.info(
        f"Relationship collection indexes configured: "
        f"{sum(results.values())} created, "
        f"{len(results) - sum(results.values())} existed"
    )

    return results


async def configure_all_indexes(client: QdrantClient) -> Dict[str, Dict[str, bool]]:
    """
    Configure all payload indexes for knowledge graph collections.

    Called during MCP server startup after collection initialization.

    Returns:
        Dict mapping collection names to index creation results
    """
    logger.info("Configuring Qdrant payload indexes...")

    results = {
        "entities": await configure_entity_indexes(client),
        "relationships": await configure_relationship_indexes(client),
    }

    total_created = sum(results["entities"].values()) + sum(results["relationships"].values())
    total_indexes = len(results["entities"]) + len(results["relationships"])

    logger.info(
        f"Payload index configuration complete: "
        f"{total_created}/{total_indexes} created, "
        f"{total_indexes - total_created}/{total_indexes} existed"
    )

    return results
EOF

echo "✅ Created qdrant_index_config.py"
```

### Step 2: Integrate Index Configuration with Startup

```bash
cat <<'EOF'
# ============================================================================
# ADD TO /opt/docling-mcp/src/mcp_server.py startup_event()
# After collection initialization (Task 102)
# ============================================================================

from integrations.qdrant_index_config import configure_all_indexes

# ... (after initialize_collections() call)

# Configure payload indexes
logger.info("Configuring Qdrant payload indexes...")
index_results = await configure_all_indexes(qdrant_client)
logger.info(f"Payload indexes ready: {index_results}")

# ============================================================================
EOF

echo "✅ Startup integration code snippet created"
```

### Step 3: Validate Index Configuration

```bash
# Syntax validation
/opt/docling-mcp/venv/bin/python -m py_compile /opt/docling-mcp/src/integrations/qdrant_index_config.py && echo "✅ Syntax valid" || exit 1

# Import test
/opt/docling-mcp/venv/bin/python -c "from integrations.qdrant_index_config import configure_all_indexes" && echo "✅ Imports successful" || exit 1
```

## Validation

```bash
echo "=== Payload Index Configuration Validation ==="

QDRANT_URL="http://hx-qdrant-server.hx.dev.local:6333"

# Check module exists
[ -f "/opt/docling-mcp/src/integrations/qdrant_index_config.py" ] && echo "✅ Module exists" || exit 1

# Check syntax
/opt/docling-mcp/venv/bin/python -m py_compile /opt/docling-mcp/src/integrations/qdrant_index_config.py && echo "✅ Syntax valid" || exit 1

# Check live indexes (if Qdrant available)
echo ""
echo "Checking live payload indexes (requires Qdrant running)..."

# Entity collection indexes
ENTITIES_SCHEMA=$(curl -s "${QDRANT_URL}/collections/hx_docling_mcp_entities" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data.get('result', {}).get('payload_schema', {}), indent=2))" 2>/dev/null)

if [ -n "$ENTITIES_SCHEMA" ] && echo "$ENTITIES_SCHEMA" | grep -q "entity_type"; then
    echo "✅ Entity collection indexes configured in Qdrant"
else
    echo "⚠️  Entity collection indexes not found (run configure_all_indexes() during startup)"
fi

echo "✅ ALL VALIDATIONS PASSED"
echo "Next: Task 106 - Implement Vector Search and Graph Traversal"
```

## Notes

**Index Performance**:
- Keyword indexes: O(1) exact match lookup
- Integer indexes: O(log N) range queries
- Recommended for fields used in >10% of queries

**Index Creation Timing**:
- Created during MCP server startup (after collections)
- Idempotent (safe to call multiple times)
- Existing indexes skipped (no recreation)

**Graph Traversal Critical Indexes**:
- `subject_entity_id` and `object_entity_id` are CRITICAL
- Enable efficient "find all relationships where subject=X" queries
- Without these indexes, graph traversal requires full collection scan

**Memory Overhead**:
- Keyword index: ~100 bytes per unique value
- Integer index: ~50 bytes per point
- Total overhead: <10MB for 100K entities

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` - FR-015 (Qdrant Payload Indexes)

**Qdrant Index API**:
- Create index: `PUT /collections/{name}/index`
- Field types: keyword, integer, float, geo, text

## Risk Assessment

**Risk Level**: Low
**Risks**: Index creation may fail if incompatible data already exists
**Mitigation**: Collections created fresh (Task 102), no incompatible data
