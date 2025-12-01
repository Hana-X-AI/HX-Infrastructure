# Node-Spec.md Synthesis Plan
**Date:** 2025-11-25
**Architect:** alex-rivera
**Purpose:** Integration roadmap for 12 specialist contributions into unified specification

---

## Current State Analysis

**Current node-spec.md**: 5,022 lines
- Base specification created by alex-rivera (1,365 lines initial)
- Inline edits integrated from 7 specialists:
  - julia-santos: Testing strategy (63 test cases)
  - frank-lucas: Security requirements (threat model, firewall)
  - william-chen: Infrastructure deployment (systemd, disaster recovery)
  - sri-patel: Redis session management
  - george-kim: FastMCP protocol implementation
  - mitch-roberts: Qdrant collection schemas
  - paul-warfield: Pydantic validation throughout

**Enhancement Documents Requiring Integration** (5 documents, ~3,500 total lines):

1. **andy-taylor** - `lightrag-knowledge-extraction-enhancement.md` (797 lines)
2. **shane-black** - `litellm-integration-enhancement.md` (294 lines)
3. **james-rodriguez** - `mcp-tools-enhancement.md` (1,001 lines)
4. **albert-singh** - `ALBERT-DOCLING-PROCESSING-ENHANCEMENT.md` (1,270 lines)
5. **marcus-johnson** - `/tmp/lightrag-enhancements.md` (311 lines)

**Estimated Final Size**: 7,500-8,000 lines

---

## Integration Mapping

### Section 4.3.2: LightRAG Knowledge Engine (Current: Lines 2458-2700)

**Current Content** (~240 lines):
- Basic component description
- Qdrant collection architecture (EntityPayload schema from mitch-roberts/paul-warfield)
- High-level responsibilities

**Integration Requirements**:

#### 1. Insert andy-taylor Enhancement (after line ~2470)
**Source**: `lightrag-knowledge-extraction-enhancement.md`
**Content Sections**:
- §1: Entity Extraction Pipeline (lines 23-256)
  - Document chunking strategy (4096 tokens, 512 overlap)
  - Entity types (10 configurable)
  - LLM extraction prompts with few-shot examples
  - Model selection (gemma3:27b, qwen3-coder:30b, gpt-oss:20b)
  - LLM API configuration
  - Response parsing & validation (Pydantic schemas)

- §2: Relationship Extraction (lines 265-370)
  - Relationship types (10 configurable)
  - LLM relationship prompts
  - Validation layers

- §3: Entity Deduplication Strategy (lines 379-480)
  - Hybrid string + vector similarity (0.85 threshold)
  - Jaro-Winkler + Cosine similarity
  - 5-phase deduplication algorithm
  - Performance optimization

- §4: LLM Integration Patterns (lines 489-520)
  - Task-specific model routing
  - Prompt engineering best practices
  - Error handling strategies

- §5: Graph Construction Workflow (lines 529-650)
  - 5-phase workflow (ingestion → chunking → extraction → deduplication → storage)
  - Progress tracking
  - Quality metrics

- §6: Configuration Requirements (lines 659-684)
  - Environment variables
  - Redis keys

- §7: Pydantic Schemas (lines 693-736)
  - Entity and Relationship schemas

**Integration Point**: After current Qdrant collection schemas, before next component

#### 2. Insert marcus-johnson Enhancement (after andy-taylor)
**Source**: `/tmp/lightrag-enhancements.md`
**Content Sections**:
- LightRAG Configuration and Tuning (lines 8-125)
  - Document chunking configuration
  - Entity deduplication configuration
  - Embedding generation configuration
  - LLM configuration
  - Entity/relationship taxonomies

- Knowledge Graph Query Capabilities (lines 129-221)
  - Entity search (semantic, exact, fuzzy, attribute filtering)
  - Relationship traversal (1-hop, multi-hop, shortest path)
  - Subgraph extraction
  - Graph analytics (centrality, clustering, PageRank)
  - Hybrid query modes

- Performance Optimization and Benchmarking (lines 225-263)
  - Batch entity extraction
  - Incremental graph updates
  - Query optimization
  - Memory management
  - Caching strategy

- Quality Validation and Metrics (lines 267-311)
  - Entity extraction quality (precision, recall, F1)
  - Relationship extraction quality
  - Graph coherence metrics
  - Monitoring and alerting

**Integration Point**: Immediately after andy-taylor enhancement

#### 3. Insert albert-singh Enhancement (before LightRAG sections)
**Source**: `ALBERT-DOCLING-PROCESSING-ENHANCEMENT.md`
**Content Sections**:
- §1: Format Detection Pipeline (lines 9-256)
  - Magic number detection
  - Office ZIP disambiguation
  - MIME type detection
  - Extension-based detection
  - Corrupted file validation

- §2: Backend Selection Strategy (lines 260-422)
  - PDF backend selection (pypdfium2, pdfplumber, OCR)
  - DOCX/PPTX/XLSX/HTML/Image backends

- §3: Structure Preservation Specifications (lines 427-691)
  - Heading detection and hierarchy
  - Table structure extraction
  - List detection
  - Code block detection
  - Image extraction
  - Footnote and citation extraction

- §4: OCR Integration (lines 695-893)
  - EasyOCR pipeline
  - Image preprocessing
  - OCR configuration and performance

- §5: DoclingDocument JSON Schema (lines 897-1075)
  - Complete Pydantic schema definition
  - Serialization for MCP transport
  - Schema versioning

- §6: Error Handling and Recovery (lines 1079-1230)
  - Corrupted file recovery
  - Unsupported format fallback
  - Large file handling (streaming)
  - Memory management
  - Timeout handling

**Integration Point**: Create new subsection "**2. Docling Processor** (Document Conversion)" before "**3. LightRAG Knowledge Engine**", insert albert-singh content there

---

### Section 4.3.4: Integration Manager - LiteLLM (Current: Lines ~2700+)

**Current Content**: Basic integration component description

**Integration Requirements**:

#### 4. Replace/Enhance with shane-black Content
**Source**: `litellm-integration-enhancement.md`
**Content Sections**:
- LiteLLM Client Configuration (lines 23-72)
- Model Selection Strategy (lines 36-60)
- Model Fallback Strategy (lines 53-57)
- Model Performance Characteristics (lines 59-61)
- Cost Optimization (lines 64-71)
- Prompt Engineering for Entity Extraction (lines 74-145)
- LLM Parameter Settings (lines 141-147)
- Error Handling & Resilience (lines 149-224)
  - LiteLLM error types (timeout, rate limit, unavailable, invalid response)
  - Retry logic with exponential backoff
  - Circuit breaker
  - Graceful degradation
  - Error logging and alerting
- Performance Optimization (lines 228-260)
  - Batch processing
  - Parallel requests
  - Response caching
  - Token usage tracking
- Enhanced FR-021 to FR-024 (lines 262-294)

**Integration Point**: Replace current Integration Manager component description, incorporate enhanced FRs into Requirements section

---

### Section 4.2: MCP Tools Specification (Current: Lines ~3487+)

**Current Content**: Tool schema examples (convert_document, generate_knowledge_graph)

**Integration Requirements**:

#### 5. Expand with james-rodriguez Content
**Source**: `mcp-tools-enhancement.md`
**Content Sections**:
- PART 1: Conversion Tools (3 tools)
  - Tool 1: convert_document (lines 25-350) - Detailed spec with Docling integration
  - Tool 2: convert_document_to_markdown (lines 42-50 reference) - Markdown conversion rules
  - Tool 3: batch_convert (lines 53-68 reference) - Parallel batch processing

- PART 2: Generation Tools (11 tools)
  - Tool 4: generate_knowledge_graph (lines 74-430) - Complete LightRAG workflow
  - Tool 5: extract_entities (lines 434-552) - NER only
  - Tools 6-14: Brief specifications (lines 556-614)

- PART 3: Manipulation Tools (5 tools)
  - Tool 15: merge_documents (lines 618-678)
  - Tool 16: split_document (lines 682-738)
  - Tool 17: search_document (lines 742-790)
  - Tool 18: annotate_document (lines 794-838)
  - Tool 19: export_document (lines 842-893)

- Implementation Patterns Summary (lines 897-968)
  - Common patterns (input validation, caching, error handling, progress reporting)
  - Docling integration best practices
  - Testing strategy summary

**Integration Point**: Replace current tool schema examples with comprehensive 19-tool specifications

---

## Integration Strategy

### Phase 1: Component Architecture Enhancements (Sections 4.3.2, 4.3.4)

**Step 1**: Insert albert-singh Docling Processor content
- Create new subsection "**2. Docling Processor**" before current "**3. LightRAG Knowledge Engine**"
- Insert all 6 sections from albert-singh enhancement
- Verify no conflicts with existing Docling references

**Step 2**: Enhance LightRAG Knowledge Engine section
- Keep existing Qdrant collection schemas (mitch-roberts/paul-warfield)
- Insert andy-taylor enhancement sections after collection schemas
- Insert marcus-johnson enhancement sections after andy-taylor
- Update section numbering if needed

**Step 3**: Enhance Integration Manager - LiteLLM section
- Replace current basic description with shane-black comprehensive content
- Keep existing integration context
- Add new subsections for error handling, performance, resilience

### Phase 2: MCP Tools Specification (Section 4.2)

**Step 4**: Replace tool examples with comprehensive specifications
- Keep current MCP protocol compliance context
- Replace example schemas with james-rodriguez 19-tool specifications
- Organize into 3 parts (Conversion, Generation, Manipulation)
- Add implementation patterns summary

### Phase 3: Cross-Reference Updates

**Step 5**: Update Functional Requirements cross-references
- FR-005 to FR-010: Point to albert-singh Docling sections
- FR-011 to FR-017: Point to andy-taylor/marcus-johnson LightRAG sections
- FR-021 to FR-024: Replace with shane-black enhanced FRs
- FR-002: Update with james-rodriguez tool details

### Phase 4: Metadata and Validation

**Step 6**: Update document metadata
- Status: "Draft (Awaiting Review)" → "Draft (Team Review Complete)"
- Contributors: Add all 12 specialist agents
- Update specification version history

**Step 7**: Final quality validation
- Check for duplicate content
- Verify consistent terminology (entity vs Entity, relationship vs Relationship)
- Validate all cross-references
- Run document-quality-checklist.md review

---

## Conflict Resolution Strategy

### Potential Conflicts

1. **Entity Types**: andy-taylor defines 10 types, marcus-johnson defines extensible taxonomy
   - **Resolution**: Use andy-taylor's 10 default types, add marcus-johnson's extended/custom types as "Phase 2" capability

2. **Embedding Model**: andy-taylor specifies bge-m3:567m, existing spec has same
   - **Resolution**: No conflict, keep consistent

3. **Deduplication Threshold**: andy-taylor uses 0.85 (hybrid), marcus-johnson uses 0.85 (semantic)
   - **Resolution**: Clarify andy-taylor is hybrid (string + vector), marcus-johnson is configuration default

4. **Docling Backend**: albert-singh has detailed backend selection, existing spec has basic
   - **Resolution**: Replace basic with albert-singh detailed specifications

5. **Tool Schemas**: james-rodriguez has detailed schemas, existing has examples
   - **Resolution**: Expand examples into full specifications from james-rodriguez

### Terminology Standardization

- **Entity**: Capitalized when referring to type (e.g., "Entity type: Person")
- **entity**: Lowercase when referring to instance (e.g., "extract entities from document")
- **Knowledge Graph**: Capitalized (proper noun for system component)
- **knowledge graph**: Lowercase when generic term
- **DoclingDocument**: Always PascalCase (class name)
- **Qdrant**: Always capitalized (product name)
- **LightRAG**: Always PascalCase (framework name)

---

## Estimated Timeline

1. **Component Architecture Integration** (albert, andy, marcus): 2-3 hours
2. **LiteLLM Integration** (shane): 30 minutes
3. **MCP Tools Specification** (james): 1 hour
4. **Cross-Reference Updates**: 30 minutes
5. **Metadata and Quality Review**: 30 minutes

**Total**: 4.5-5.5 hours of focused synthesis work

---

## Success Criteria

- ✅ All 5 enhancement documents fully integrated (no content loss)
- ✅ No duplicate content (deduplication where overlap exists)
- ✅ Consistent terminology throughout
- ✅ All cross-references updated and validated
- ✅ Document metadata reflects 12 contributors
- ✅ Final size 7,500-8,000 lines (current 5,022 + enhancements ~2,500-3,000)
- ✅ Passes document-quality-checklist.md review
- ✅ Ready for Phase 5 (Clarification Questions)

---

## Next Actions

1. Execute Phase 1 (Component Architecture) - albert-singh first
2. Execute Phase 1 continued - andy-taylor + marcus-johnson
3. Execute Phase 2 (LiteLLM) - shane-black
4. Execute Phase 3 (MCP Tools) - james-rodriguez
5. Execute Phase 4 (Cross-References)
6. Execute Phase 5 (Metadata & Quality)
7. Final review and handoff for Phase 5 clarification questions

