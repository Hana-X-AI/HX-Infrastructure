# Task: Integrate Qdrant Storage for Knowledge Graph

**Task ID**: hx-docling-mcp-task-084-integrate-qdrant-storage
**Phase**: Development - Knowledge Graph Generation
**Work Stream**: 5 - Knowledge Graph Generation (LightRAG Integration)
**Status**: Not Started
**Assigned Agent**: andy-taylor (LightRAG SME) + mitch-harper (Qdrant SME coordination)
**Dependencies**:
- hx-docling-mcp-task-082-implement-entity-extraction-workflow (entities available)
- hx-docling-mcp-task-083-implement-relationship-extraction-workflow (relationships available)
- hx-qdrant-server operational at http://hx-qdrant-server.hx.dev.local:6333

**Estimated Time**: 150 minutes

---

## Objective

Create Qdrant integration module (`qdrant_knowledge_graph.py`) for storing entities and relationships in dual-collection architecture. Implement idempotent collection initialization, entity insertion with deduplication, relationship insertion with bidirectional linking, and graph query capabilities for knowledge graph statistics and traversal.

---

## Pre-Execution Validation

**Check if work already complete BEFORE executing steps:**

```bash
# Check if qdrant_knowledge_graph.py module exists
if [ -f "/opt/docling-mcp/src/qdrant_knowledge_graph.py" ]; then
    echo "✅ VALIDATION: Qdrant KG module exists - checking completeness..."

    # Verify key components present
    grep -q "class QdrantKnowledgeGraph" /opt/docling-mcp/src/qdrant_knowledge_graph.py && \
    grep -q "def initialize_collections" /opt/docling-mcp/src/qdrant_knowledge_graph.py && \
    grep -q "def insert_entities" /opt/docling-mcp/src/qdrant_knowledge_graph.py && \
    grep -q "def insert_relationships" /opt/docling-mcp/src/qdrant_knowledge_graph.py

    if [ $? -eq 0 ]; then
        echo "✅ VALIDATION: Qdrant KG module complete - SKIP task execution"
        exit 0
    else
        echo "⚠️  VALIDATION: Module incomplete - PROCEED with task"
    fi
else
    echo "❌ VALIDATION: Qdrant KG module does not exist - PROCEED with task"
fi

# Verify hx-qdrant-server is operational
curl -s -o /dev/null -w "%{http_code}" http://hx-qdrant-server.hx.dev.local:6333/
if [ $? -ne 0 ]; then
    echo "❌ BLOCKER: hx-qdrant-server not accessible - cannot proceed"
    exit 1
fi
```

**Validation Logic**:
- If `qdrant_knowledge_graph.py` exists with all required methods → SKIP execution
- If module missing or incomplete → PROCEED with implementation
- If hx-qdrant-server unavailable → BLOCK task (dependency failure)

---

## Prerequisites

- [x] Python 3.11 virtual environment at `/opt/docling-mcp/venv/`
- [x] Entity extraction module (`entity_extraction.py`) created (Task 082)
- [x] Relationship extraction module (`relationship_extraction.py`) created (Task 083)
- [x] qdrant-client library installed (Python Qdrant HTTP client)
- [x] hx-qdrant-server operational at http://hx-qdrant-server.hx.dev.local:6333
- [x] Source directory `/opt/docling-mcp/src/` exists

---

## Implementation Steps

### Step 1: Install Qdrant Client Library

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Install qdrant-client
pip install qdrant-client==1.7.0

# Verify installation
python -c "from qdrant_client import QdrantClient; print('✅ qdrant-client installed')"
```

### Step 2: Create Qdrant Knowledge Graph Module Structure

```bash
cat > /opt/docling-mcp/src/qdrant_knowledge_graph.py << 'EOF'
"""
Qdrant Knowledge Graph Storage for hx-docling-mcp-server

Dual-collection architecture for entity and relationship storage:
- hx_docling_mcp_entities: Entity collection (1024D bge-m3:567m vectors)
- hx_docling_mcp_relationships: Relationship collection (1024D vectors)

Key Features:
- Idempotent collection initialization (create if not exists)
- Entity insertion with semantic deduplication (>0.85 similarity)
- Relationship insertion with bidirectional linking
- Payload indexes for fast graph traversal (subject_entity_id, object_entity_id)
- Graph statistics and query capabilities

Architecture:
- Vector Storage: bge-m3:567m embeddings (1024 dimensions)
- Distance Metric: Cosine similarity
- HNSW Parameters: m=16, ef_construct=100
- Payload Indexes: entity_type, document_id, confidence, subject_entity_id, object_entity_id
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional, Tuple
from uuid import UUID
from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance,
    VectorParams,
    PointStruct,
    Filter,
    FieldCondition,
    MatchValue,
    Range,
    SearchRequest,
    CollectionInfo,
    PayloadSchemaType,
    CreateCollection,
    UpdateCollection
)

logger = logging.getLogger(__name__)

# Qdrant configuration
QDRANT_URL = "http://hx-qdrant-server.hx.dev.local:6333"
ENTITY_COLLECTION_NAME = "hx_docling_mcp_entities"
RELATIONSHIP_COLLECTION_NAME = "hx_docling_mcp_relationships"

# Vector configuration (bge-m3:567m embeddings)
VECTOR_SIZE = 1024
DISTANCE_METRIC = Distance.COSINE

# HNSW indexing parameters
HNSW_M = 16  # Balanced connectivity for 1024D vectors
HNSW_EF_CONSTRUCT = 100  # Moderate build quality for <1M entities

# Deduplication threshold
ENTITY_DEDUP_THRESHOLD = 0.85  # Entities with >0.85 cosine similarity are duplicates

EOF
```

### Step 3: Implement QdrantKnowledgeGraph Class with Collection Initialization

```bash
cat >> /opt/docling-mcp/src/qdrant_knowledge_graph.py << 'EOF'

# ============================================================================
# QdrantKnowledgeGraph Class
# ============================================================================

class QdrantKnowledgeGraph:
    """
    Qdrant-based knowledge graph storage and retrieval.

    Features:
    - Dual-collection architecture (entities + relationships)
    - Idempotent collection initialization
    - Entity deduplication via semantic similarity
    - Bidirectional relationship storage
    - Graph traversal queries
    """

    def __init__(
        self,
        qdrant_url: str = QDRANT_URL,
        entity_collection: str = ENTITY_COLLECTION_NAME,
        relationship_collection: str = RELATIONSHIP_COLLECTION_NAME
    ):
        """
        Initialize Qdrant knowledge graph client.

        Args:
            qdrant_url: Qdrant server endpoint
            entity_collection: Entity collection name
            relationship_collection: Relationship collection name
        """
        self.client = QdrantClient(url=qdrant_url, timeout=60.0)
        self.entity_collection = entity_collection
        self.relationship_collection = relationship_collection

        logger.info(
            f"QdrantKnowledgeGraph initialized: url={qdrant_url}, "
            f"entity_collection={entity_collection}, relationship_collection={relationship_collection}"
        )


    def initialize_collections(self):
        """
        Initialize Qdrant collections for entities and relationships.

        Idempotent operation: Creates collections only if they don't exist.

        Collection Configuration:
        - Entities: 1024D vectors (bge-m3:567m), Cosine distance, HNSW(m=16, ef_construct=100)
        - Relationships: 1024D vectors, Cosine distance, HNSW(m=16, ef_construct=100)

        Payload Indexes:
        - Entities: entity_type, document_id, confidence, mention_count
        - Relationships: subject_entity_id, object_entity_id, predicate, document_id, confidence

        Example:
            kg = QdrantKnowledgeGraph()
            kg.initialize_collections()
        """
        logger.info("Initializing Qdrant collections...")

        # Initialize entity collection
        if not self.client.collection_exists(self.entity_collection):
            logger.info(f"Creating entity collection: {self.entity_collection}")

            self.client.create_collection(
                collection_name=self.entity_collection,
                vectors_config=VectorParams(
                    size=VECTOR_SIZE,
                    distance=DISTANCE_METRIC,
                    hnsw_config={
                        "m": HNSW_M,
                        "ef_construct": HNSW_EF_CONSTRUCT
                    }
                )
            )

            # Create payload indexes for fast filtering
            self.client.create_payload_index(
                collection_name=self.entity_collection,
                field_name="entity_type",
                field_schema=PayloadSchemaType.KEYWORD
            )
            self.client.create_payload_index(
                collection_name=self.entity_collection,
                field_name="document_id",
                field_schema=PayloadSchemaType.KEYWORD
            )
            self.client.create_payload_index(
                collection_name=self.entity_collection,
                field_name="confidence",
                field_schema=PayloadSchemaType.FLOAT
            )
            self.client.create_payload_index(
                collection_name=self.entity_collection,
                field_name="mention_count",
                field_schema=PayloadSchemaType.INTEGER
            )

            logger.info(f"✅ Entity collection created: {self.entity_collection}")
        else:
            logger.info(f"✅ Entity collection already exists: {self.entity_collection}")

        # Initialize relationship collection
        if not self.client.collection_exists(self.relationship_collection):
            logger.info(f"Creating relationship collection: {self.relationship_collection}")

            self.client.create_collection(
                collection_name=self.relationship_collection,
                vectors_config=VectorParams(
                    size=VECTOR_SIZE,
                    distance=DISTANCE_METRIC,
                    hnsw_config={
                        "m": HNSW_M,
                        "ef_construct": HNSW_EF_CONSTRUCT
                    }
                )
            )

            # Create payload indexes for graph traversal
            self.client.create_payload_index(
                collection_name=self.relationship_collection,
                field_name="subject_entity_id",
                field_schema=PayloadSchemaType.KEYWORD  # CRITICAL for graph queries
            )
            self.client.create_payload_index(
                collection_name=self.relationship_collection,
                field_name="object_entity_id",
                field_schema=PayloadSchemaType.KEYWORD  # CRITICAL for graph queries
            )
            self.client.create_payload_index(
                collection_name=self.relationship_collection,
                field_name="predicate",
                field_schema=PayloadSchemaType.KEYWORD
            )
            self.client.create_payload_index(
                collection_name=self.relationship_collection,
                field_name="document_id",
                field_schema=PayloadSchemaType.KEYWORD
            )
            self.client.create_payload_index(
                collection_name=self.relationship_collection,
                field_name="confidence",
                field_schema=PayloadSchemaType.FLOAT
            )

            logger.info(f"✅ Relationship collection created: {self.relationship_collection}")
        else:
            logger.info(f"✅ Relationship collection already exists: {self.relationship_collection}")

        logger.info("Qdrant collection initialization complete")

EOF
```

### Step 4: Implement Entity Insertion with Deduplication

```bash
cat >> /opt/docling-mcp/src/qdrant_knowledge_graph.py << 'EOF'

    def insert_entities(
        self,
        entities: List[Dict[str, Any]],
        embeddings: List[List[float]]
    ) -> Tuple[int, int]:
        """
        Insert entities into Qdrant with semantic deduplication.

        Deduplication workflow:
        1. For each entity, search Qdrant for similar entities (>0.85 similarity)
        2. If duplicate found: Update existing entity (merge aliases, increment mention_count)
        3. If no duplicate: Insert as new entity

        Args:
            entities: List of entity dictionaries (from entity_extraction.py)
            embeddings: List of bge-m3:567m embeddings (1024D vectors, one per entity)

        Returns:
            Tuple of (inserted_count, updated_count)

        Example:
            inserted, updated = kg.insert_entities(
                entities=extracted_entities,
                embeddings=entity_embeddings
            )
            print(f"Inserted {inserted} new entities, updated {updated} existing entities")
        """
        if len(entities) != len(embeddings):
            raise ValueError(f"Entity count ({len(entities)}) != embedding count ({len(embeddings)})")

        logger.info(f"Inserting {len(entities)} entities with deduplication...")

        inserted_count = 0
        updated_count = 0

        points_to_insert = []

        for entity, embedding in zip(entities, embeddings):
            # Search for duplicate entities (semantic similarity >0.85)
            search_results = self.client.search(
                collection_name=self.entity_collection,
                query_vector=embedding,
                limit=1,
                score_threshold=ENTITY_DEDUP_THRESHOLD
            )

            if search_results and search_results[0].score >= ENTITY_DEDUP_THRESHOLD:
                # Duplicate found: Update existing entity
                existing_point = search_results[0]
                existing_payload = existing_point.payload

                # Merge aliases
                existing_aliases = set(existing_payload.get('aliases', []))
                new_aliases = set(entity.get('aliases', []))
                merged_aliases = sorted(list(existing_aliases.union(new_aliases)))

                # Increment mention count
                new_mention_count = existing_payload.get('mention_count', 1) + entity.get('mention_count', 1)

                # Keep max confidence
                new_confidence = max(existing_payload.get('confidence', 0.0), entity.get('confidence', 0.0))

                # Update payload
                updated_payload = existing_payload.copy()
                updated_payload['aliases'] = merged_aliases
                updated_payload['mention_count'] = new_mention_count
                updated_payload['confidence'] = new_confidence

                # Update point in Qdrant
                self.client.set_payload(
                    collection_name=self.entity_collection,
                    payload=updated_payload,
                    points=[existing_point.id]
                )

                updated_count += 1
                logger.debug(f"Updated duplicate entity: {entity['entity_name']} (similarity={search_results[0].score:.3f})")

            else:
                # No duplicate: Insert as new entity
                point = PointStruct(
                    id=entity['entity_id'],  # Use entity UUID as point ID
                    vector=embedding,
                    payload=entity
                )
                points_to_insert.append(point)
                inserted_count += 1

        # Batch insert new entities
        if points_to_insert:
            self.client.upsert(
                collection_name=self.entity_collection,
                points=points_to_insert
            )

        logger.info(f"Entity insertion complete: {inserted_count} inserted, {updated_count} updated")
        return (inserted_count, updated_count)

EOF
```

### Step 5: Implement Relationship Insertion

```bash
cat >> /opt/docling-mcp/src/qdrant_knowledge_graph.py << 'EOF'

    def insert_relationships(
        self,
        relationships: List[Dict[str, Any]],
        embeddings: List[List[float]]
    ) -> int:
        """
        Insert relationships into Qdrant.

        No deduplication (relationships are already validated in relationship_extraction.py).
        Bidirectional relationships handled upstream.

        Args:
            relationships: List of relationship dictionaries (from relationship_extraction.py)
            embeddings: List of relationship embeddings (1024D vectors)

        Returns:
            Number of relationships inserted

        Example:
            count = kg.insert_relationships(
                relationships=extracted_relationships,
                embeddings=relationship_embeddings
            )
            print(f"Inserted {count} relationships")
        """
        if len(relationships) != len(embeddings):
            raise ValueError(f"Relationship count ({len(relationships)}) != embedding count ({len(embeddings)})")

        logger.info(f"Inserting {len(relationships)} relationships...")

        points = []
        for rel, embedding in zip(relationships, embeddings):
            point = PointStruct(
                id=rel['relationship_id'],  # Use relationship UUID as point ID
                vector=embedding,
                payload=rel
            )
            points.append(point)

        # Batch insert relationships
        self.client.upsert(
            collection_name=self.relationship_collection,
            points=points
        )

        logger.info(f"Relationship insertion complete: {len(relationships)} inserted")
        return len(relationships)

EOF
```

### Step 6: Implement Graph Query Capabilities

```bash
cat >> /opt/docling-mcp/src/qdrant_knowledge_graph.py << 'EOF'

    def get_entity_statistics(
        self,
        document_id: Optional[str] = None,
        entity_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get entity statistics from knowledge graph.

        Args:
            document_id: Filter by document (None = all documents)
            entity_type: Filter by entity type (None = all types)

        Returns:
            Dictionary with entity statistics

        Example:
            stats = kg.get_entity_statistics(entity_type="Organization")
            print(f"Total organizations: {stats['total_count']}")
        """
        # Build filter
        filter_conditions = []
        if document_id:
            filter_conditions.append(FieldCondition(key="document_id", match=MatchValue(value=document_id)))
        if entity_type:
            filter_conditions.append(FieldCondition(key="entity_type", match=MatchValue(value=entity_type)))

        # Get collection info
        collection_info = self.client.get_collection(self.entity_collection)

        # Count entities (with filter if specified)
        if filter_conditions:
            filter_obj = Filter(must=filter_conditions)
            count_result = self.client.count(
                collection_name=self.entity_collection,
                count_filter=filter_obj
            )
            total_count = count_result.count
        else:
            total_count = collection_info.points_count

        return {
            'total_count': total_count,
            'collection_name': self.entity_collection,
            'vector_size': collection_info.config.params.vectors.size,
            'filter_applied': {
                'document_id': document_id,
                'entity_type': entity_type
            }
        }


    def get_relationship_statistics(
        self,
        document_id: Optional[str] = None,
        predicate: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get relationship statistics from knowledge graph.

        Args:
            document_id: Filter by document (None = all documents)
            predicate: Filter by predicate (None = all predicates)

        Returns:
            Dictionary with relationship statistics

        Example:
            stats = kg.get_relationship_statistics(predicate="works_for")
            print(f"Total employment relationships: {stats['total_count']}")
        """
        # Build filter
        filter_conditions = []
        if document_id:
            filter_conditions.append(FieldCondition(key="document_id", match=MatchValue(value=document_id)))
        if predicate:
            filter_conditions.append(FieldCondition(key="predicate", match=MatchValue(value=predicate)))

        # Get collection info
        collection_info = self.client.get_collection(self.relationship_collection)

        # Count relationships (with filter if specified)
        if filter_conditions:
            filter_obj = Filter(must=filter_conditions)
            count_result = self.client.count(
                collection_name=self.relationship_collection,
                count_filter=filter_obj
            )
            total_count = count_result.count
        else:
            total_count = collection_info.points_count

        return {
            'total_count': total_count,
            'collection_name': self.relationship_collection,
            'vector_size': collection_info.config.params.vectors.size,
            'filter_applied': {
                'document_id': document_id,
                'predicate': predicate
            }
        }


    def get_entity_relationships(
        self,
        entity_id: str,
        direction: str = "outgoing",
        predicate: Optional[str] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Get relationships for a specific entity (graph traversal).

        Args:
            entity_id: Entity UUID
            direction: "outgoing" (entity is subject), "incoming" (entity is object), "both"
            predicate: Filter by relationship type (None = all types)
            limit: Maximum relationships to return

        Returns:
            List of relationship payloads

        Example:
            # Get all "works_for" relationships where entity is subject
            rels = kg.get_entity_relationships(
                entity_id="alice-uuid",
                direction="outgoing",
                predicate="works_for"
            )
        """
        filter_conditions = []

        if direction == "outgoing":
            filter_conditions.append(FieldCondition(key="subject_entity_id", match=MatchValue(value=entity_id)))
        elif direction == "incoming":
            filter_conditions.append(FieldCondition(key="object_entity_id", match=MatchValue(value=entity_id)))
        elif direction == "both":
            # Query twice and merge results
            outgoing = self.get_entity_relationships(entity_id, "outgoing", predicate, limit)
            incoming = self.get_entity_relationships(entity_id, "incoming", predicate, limit)
            return outgoing + incoming
        else:
            raise ValueError(f"Invalid direction: {direction} (must be 'outgoing', 'incoming', or 'both')")

        if predicate:
            filter_conditions.append(FieldCondition(key="predicate", match=MatchValue(value=predicate)))

        filter_obj = Filter(must=filter_conditions)

        # Scroll through relationships (no vector search, just filter)
        results, _ = self.client.scroll(
            collection_name=self.relationship_collection,
            scroll_filter=filter_obj,
            limit=limit,
            with_payload=True,
            with_vectors=False
        )

        relationships = [point.payload for point in results]
        logger.info(f"Retrieved {len(relationships)} {direction} relationships for entity {entity_id}")

        return relationships

EOF
```

### Step 7: Set File Permissions and Ownership

```bash
# Set ownership to docling-mcp service account
chown docling-mcp:docling-mcp /opt/docling-mcp/src/qdrant_knowledge_graph.py

# Read-only for owner/group
chmod 640 /opt/docling-mcp/src/qdrant_knowledge_graph.py

echo "✅ Qdrant knowledge graph module created and secured"
```

---

## Verification

### Automated Verification

```bash
# Verify file exists with correct permissions
ls -l /opt/docling-mcp/src/qdrant_knowledge_graph.py
# Expected: -rw-r----- 1 docling-mcp docling-mcp [size] [date] qdrant_knowledge_graph.py

# Verify Python syntax
source /opt/docling-mcp/venv/bin/activate
python -m py_compile /opt/docling-mcp/src/qdrant_knowledge_graph.py
if [ $? -eq 0 ]; then
    echo "✅ Python syntax valid"
else
    echo "❌ Python syntax errors detected"
    exit 1
fi

# Verify module can be imported
python -c "from qdrant_knowledge_graph import QdrantKnowledgeGraph; print('✅ Import successful')"

# Test collection initialization (idempotent)
python << 'PYEOF'
from qdrant_knowledge_graph import QdrantKnowledgeGraph

kg = QdrantKnowledgeGraph()

# Initialize collections (should succeed or already exist)
try:
    kg.initialize_collections()
    print("✅ Collections initialized successfully")
except Exception as e:
    print(f"❌ Collection initialization failed: {str(e)[:200]}")
    exit(1)

# Verify collections exist
if kg.client.collection_exists("hx_docling_mcp_entities"):
    print("✅ Entity collection exists")
else:
    print("❌ Entity collection not found")
    exit(1)

if kg.client.collection_exists("hx_docling_mcp_relationships"):
    print("✅ Relationship collection exists")
else:
    print("❌ Relationship collection not found")
    exit(1)
PYEOF
```

### Manual Verification

- [ ] Module imports without errors
- [ ] `QdrantKnowledgeGraph` class instantiates successfully
- [ ] `initialize_collections()` method creates both collections
- [ ] Entity collection has payload indexes (entity_type, document_id, confidence, mention_count)
- [ ] Relationship collection has payload indexes (subject_entity_id, object_entity_id, predicate, document_id, confidence)
- [ ] `insert_entities()` method defined with deduplication
- [ ] `insert_relationships()` method defined
- [ ] `get_entity_statistics()` method defined
- [ ] `get_relationship_statistics()` method defined
- [ ] `get_entity_relationships()` method defined (graph traversal)
- [ ] File ownership: docling-mcp:docling-mcp
- [ ] File permissions: 640 (rw-r-----)

---

## Rollback

If task needs to be reverted:

```bash
# Remove qdrant_knowledge_graph.py module
rm -f /opt/docling-mcp/src/qdrant_knowledge_graph.py

# Optionally delete Qdrant collections (destructive)
python << 'PYEOF'
from qdrant_client import QdrantClient

client = QdrantClient(url="http://hx-qdrant-server.hx.dev.local:6333")

if client.collection_exists("hx_docling_mcp_entities"):
    client.delete_collection("hx_docling_mcp_entities")
    print("✅ Entity collection deleted")

if client.collection_exists("hx_docling_mcp_relationships"):
    client.delete_collection("hx_docling_mcp_relationships")
    print("✅ Relationship collection deleted")
PYEOF
```

---

## Integration Points

**Upstream Dependencies**:
- `entity_extraction.py` (Task 082) - Provides entities for storage
- `relationship_extraction.py` (Task 083) - Provides relationships for storage
- `hx-qdrant-server` operational at http://hx-qdrant-server.hx.dev.local:6333
- Embedding generation (Task 085) - Provides bge-m3:567m vectors

**Downstream Consumers**:
- MCP tool `generate_knowledge_graph` (stores entities/relationships in Qdrant)
- MCP tool `get_knowledge_graph_stats` (queries statistics)
- Graph traversal queries (find entity relationships)

**Configuration Requirements**:
- Environment variable: `QDRANT_URL` (default: http://hx-qdrant-server.hx.dev.local:6333)
- Environment variable: `ENTITY_COLLECTION_NAME` (default: hx_docling_mcp_entities)
- Environment variable: `RELATIONSHIP_COLLECTION_NAME` (default: hx_docling_mcp_relationships)
- Environment variable: `ENTITY_DEDUP_THRESHOLD` (default: 0.85)

---

## Notes

### Dual-Collection Architecture Benefits

**Why Two Collections?**

1. **Entity Collection** (hx_docling_mcp_entities):
   - Stores entity nodes (canonical names, aliases, attributes)
   - Vector search for entity deduplication (semantic similarity)
   - Fast entity lookup by ID, type, document

2. **Relationship Collection** (hx_docling_mcp_relationships):
   - Stores relationship edges (subject → predicate → object)
   - Graph traversal indexes (subject_entity_id, object_entity_id)
   - Supports bidirectional queries (A→B and B→A)

**Alternative: Single Collection with Payload Field?**
- ❌ Poor performance (mixed entity/relationship queries)
- ❌ Complex filtering (need to distinguish entities from relationships)
- ❌ Inefficient indexes (entity-specific vs relationship-specific fields)

### Entity Deduplication Strategy (Semantic Similarity)

**Algorithm**:
1. For each new entity, generate embedding (entity_name + context_snippet)
2. Search Qdrant for similar entities (cosine similarity >0.85)
3. If duplicate found:
   - Merge aliases (union of alias lists)
   - Increment mention_count (sum)
   - Keep max confidence score
   - Update existing entity payload
4. If no duplicate:
   - Insert as new entity with UUID

**Performance**:
- Vector search latency: <50ms per entity (HNSW index)
- Batch insertion: 100 entities in <5s (with deduplication)

**Accuracy**:
- 0.85 threshold balances precision vs recall
- Higher threshold (0.90): Fewer false positives, more duplicates missed
- Lower threshold (0.80): More false positives, better duplicate detection

### Graph Traversal Performance

**Query Patterns**:

1. **Outgoing Relationships** ("Who does Alice work for?"):
   ```python
   rels = kg.get_entity_relationships(
       entity_id="alice-uuid",
       direction="outgoing",
       predicate="works_for"
   )
   # Query: subject_entity_id = alice_uuid AND predicate = works_for
   # Index: subject_entity_id (keyword) → <50ms
   ```

2. **Incoming Relationships** ("Who works for IBM?"):
   ```python
   rels = kg.get_entity_relationships(
       entity_id="ibm-uuid",
       direction="incoming",
       predicate="works_for"
   )
   # Query: object_entity_id = ibm_uuid AND predicate = works_for
   # Index: object_entity_id (keyword) → <50ms
   ```

3. **Bidirectional** ("All relationships for Alice"):
   ```python
   rels = kg.get_entity_relationships(
       entity_id="alice-uuid",
       direction="both"
   )
   # Queries both outgoing and incoming, merges results
   # Latency: 2× single direction query (<100ms)
   ```

**Why Payload Indexes are CRITICAL**:
- Without indexes: Full collection scan (1M relationships → 10-20s query)
- With keyword indexes: Hash table lookup (<50ms query)
- Index overhead: ~10% storage increase, <1s build time per 100K relationships

### Testing Strategy

- **Unit Tests**: Test collection initialization (idempotent), entity deduplication (mock vectors)
- **Integration Tests**: Live Qdrant connectivity (TC-INT-006), entity insertion, relationship insertion
- **Performance Tests**: Measure insertion latency (100/1000/10000 entities), query latency (graph traversal)

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Version**: 1.0
