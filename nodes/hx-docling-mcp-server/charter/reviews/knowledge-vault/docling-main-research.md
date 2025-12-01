# Docling Repository - Comprehensive Research Summary

## Executive Overview

Docling is a production-grade document processing SDK (v2.63.0 deployed) that converts diverse document formats into a unified DoclingDocument representation. It's designed for integration with AI workflows, particularly agentic applications through MCP (Model Context Protocol) servers. The architecture is modular, supporting multiple processing pipelines, backends, and optional extensions.

**Key Characteristics:**
- Python 3.9-3.13 compatible
- Supports 14+ input formats (PDF, DOCX, HTML, images, audio, etc.)
- Multiple export formats (Markdown, JSON, HTML, DocTags, plain text)
- Local-first architecture with optional remote service support
- AI-ready with VLM integration, OCR support, and structured extraction capabilities

---

## 1. DOCLING ARCHITECTURE & PROCESSING PIPELINE

### High-Level Architecture

```
Input Document → Format Detection → Backend Selection → Pipeline → DoclingDocument → Export
                                       ↓
                            Format-Specific Pipeline
                            (with configurable stages)
```

**Architecture Components:**

1. **DocumentConverter** (High-level API)
   - Main entry point for document conversion
   - Format auto-detection via MIME type and content analysis
   - Handles single and batch processing
   - Pipeline caching by options hash (thread-safe)
   - Pydantic v2 validation for type safety

2. **Backends** (Low-level format parsers)
   - Abstract interface: `AbstractDocumentBackend`
   - Format-specific implementations for each supported format
   - Two categories:
     - `DeclarativeDocumentBackend`: Direct conversion (HTML, Markdown, DOCX, etc.)
     - `PaginatedDocumentBackend`: Page-based (PDFs, images)
   - Backend lifecycle: validate → parse → unload

3. **Pipelines** (Processing orchestration)
   - **SimplePipeline**: Non-paginated formats (HTML, Markdown, DOCX)
   - **StandardPdfPipeline**: Core PDF processing pipeline
   - **ThreadedPdfPipeline**: Batched page processing with backpressure
   - **VlmPipeline**: Vision-language model-based conversion
   - **AsrPipeline**: Audio speech recognition
   - **ExtractionVlmPipeline**: Structured information extraction (beta)

4. **Models** (Processing stages)
   - PagePreprocessingModel (image scaling, rotation)
   - LayoutModel (Heron or EGRET variants for document structure)
   - OCRModel (multiple engines: EasyOCR, Tesseract, RapidOCR, OcrMac)
   - TableStructureModel (TableFormer for table recognition)
   - ReadingOrderModel (logical reading order determination)
   - CodeFormulaModel (code and LaTeX formula extraction)
   - PictureClassification/Description (vision models for images)
   - PageAssembleModel (final document assembly)

### Document Processing Flow (PDF Example)

```
1. Input Validation
   └─ Verify format, file size, page count against limits

2. Backend Processing (PyPdfium2)
   └─ Extract raw PDF structure, text, metadata

3. Pipeline Execution Stages:
   ├─ PagePreprocessing: Normalize pages
   ├─ OCR: Extract/replace text with optical character recognition
   ├─ LayoutModel: Identify document structure (headers, sections, etc.)
   ├─ TableStructureModel: Parse table cells and relationships
   ├─ CodeFormulaModel: Extract code blocks and formulas
   ├─ ReadingOrderModel: Determine logical reading sequence
   └─ PageAssemble: Build final DoclingDocument with hierarchy

4. Export
   └─ Markdown, JSON, HTML, DocTags, plain text
```

**Confidence Tracking:**
- Each extracted element has confidence scores
- Tracked during pipeline execution via `ConfidenceReport`
- Exportable in JSON serialization

---

## 2. SUPPORTED FORMATS & CAPABILITIES

### Input Formats (14 types)

| Category | Formats | Processing Type |
|----------|---------|-----------------|
| **Documents** | PDF, DOCX, PPTX, XLSX | Native parsing |
| **Markup** | HTML, XHTML, Markdown, AsciiDoc | DOM/AST parsing |
| **Images** | PNG, JPEG, TIFF, BMP, WebVTT, WEBP | Layout + OCR |
| **Audio** | WAV, MP3 | ASR (Whisper) |
| **Schema-specific** | USPTO XML, JATS XML, METS-GBS | Specialized parsers |
| **Serialized** | Docling JSON | Deserialization |

**Format Detection Mechanism:**
- Primary: MIME type detection (via `filetype` library)
- Secondary: File extension matching
- Tertiary: Content heuristics (CSV sniffer, XML DOCTYPE detection, HTML regex)
- Special handling for ZIP-based formats (DOCX, XLSX, PPTX)

### Output Formats (5 types)

| Format | Description | Use Case |
|--------|-------------|----------|
| **Markdown** | Standard Markdown with structure | Human reading, RAG |
| **HTML** | Standard or split-page variants | Web display |
| **JSON** | Lossless DoclingDocument serialization | Storage, transfer, further processing |
| **DocTags** | Custom markup preserving layout info | Efficient downstream processing |
| **Text** | Plain text without markup | Simple extraction |

### Processing Capability Matrix

| Capability | PDF | DOCX | HTML | Images | Others |
|-----------|-----|------|------|--------|--------|
| Structure Recognition | ✓ | ✓ | ✓ | ✓ (VLM) | Partial |
| Table Extraction | ✓ | ✓ | ✓ | ✓ (VLM) | Varies |
| OCR Support | ✓ | - | - | ✓ | Varies |
| Reading Order | ✓ | ✓ | ✓ | Partial | - |
| Code/Formula | ✓ | - | - | Partial | - |
| Bounding Boxes | ✓ | ✓ | Limited | ✓ | Limited |

---

## 3. CORE API & PROGRAMMATIC INTERFACE

### Main API Classes

**DocumentConverter** (Primary API)
```python
from docling.document_converter import DocumentConverter
from docling.datamodel.base_models import InputFormat

# Simple usage
converter = DocumentConverter()
result = converter.convert("file.pdf")  # or URL
document = result.document

# Batch processing
results = converter.convert_all([source1, source2, ...])
for result in results:
    if result.status == ConversionStatus.SUCCESS:
        document = result.document

# Configuration
from docling.datamodel.pipeline_options import PdfPipelineOptions
options = PdfPipelineOptions(do_ocr=True, do_table_structure=True)
converter = DocumentConverter(
    format_options={
        InputFormat.PDF: PdfFormatOption(pipeline_options=options)
    }
)
```

**Key Methods:**
- `convert(source, headers=None, raises_on_error=True, max_num_pages=inf, max_file_size=inf, page_range=(1,inf))` → ConversionResult
- `convert_all(iterable, ...)` → Iterator[ConversionResult]
- `convert_string(content, format, name)` → ConversionResult (Markdown/HTML only)
- `initialize_pipeline(format)` → None (explicit initialization for optimization)

**ConversionResult** (Output wrapper)
```python
class ConversionResult:
    input: InputDocument
    status: ConversionStatus  # SUCCESS, PARTIAL_SUCCESS, FAILURE, SKIPPED, PENDING, STARTED
    errors: List[ErrorItem]
    
    pages: List[Page]  # Per-page metadata
    document: DoclingDocument  # Main output
    
    timings: Dict[str, ProfilingItem]  # Performance metrics
    confidence: ConfidenceReport  # Quality metrics
```

**DoclingDocument** (Unified representation)
```python
from docling_core.types.doc import DoclingDocument

# Structure
document.texts: List[TextItem]  # Paragraphs, headers, equations, etc.
document.tables: List[TableItem]  # Extracted tables with structure
document.pictures: List[PictureItem]  # Images with metadata
document.key_value_items: List[KeyValueItem]  # Form fields

# Organization
document.body: NodeItem  # Main content hierarchy
document.furniture: NodeItem  # Headers, footers, navigation
document.groups: Set[NodeItem]  # Lists, nested structures

# Metadata
document.name: str
document.path: Optional[str]
document.page_count: int
```

**Export Methods** (on DoclingDocument)
```python
# Note: Signatures shown with key optional parameters (see API docs for complete signatures)

document.export_to_markdown(image_mode="embed|referenced")  # Returns: str

document.export_to_html()  # Returns: str

document.export_to_text(
    delim="\n\n",           # Delimiter between elements
    from_element=None,      # Start from specific element
    to_element=None,        # End at specific element
    labels=None             # Filter by labels
)  # Returns: str

document.export_to_dict(
    mode="json",            # Serialization mode
    by_alias=True,          # Use field aliases
    exclude_none=True,      # Exclude None values
    coord_precision=3,      # Coordinate decimal precision
    confid_precision=3      # Confidence decimal precision
)  # Returns: dict (JSON-serializable)

# For JSON string output, use:
import json
json_string = json.dumps(document.export_to_dict())

document.export_to_document_tokens()  # Returns: DocTags format (str)
```

### Key Data Models

**InputFormat Enum**
- DOCX, PPTX, HTML, IMAGE, PDF, ASCIIDOC, MD, CSV, XLSX
- XML_USPTO, XML_JATS, METS_GBS, JSON_DOCLING, AUDIO, VTT

**Page Range Control**
```python
# Tuple validation: start >= 1, end >= start
converter.convert(source, page_range=(1, 50))  # Pages 1-50
# Type: Annotated[Tuple[int, int], PlainValidator]
# Default: (1, sys.maxsize)
```

**DocumentStream** (For binary input)
```python
from docling.datamodel.base_models import DocumentStream
from io import BytesIO

stream = DocumentStream(name="document.pdf", stream=BytesIO(binary_data))
result = converter.convert(stream)
```

---

## 4. CONFIGURATION & PIPELINE OPTIONS

### PipelineOptions Class Hierarchy

```
BaseOptions
├── PipelineOptions
│   ├── ConvertPipelineOptions
│   │   ├── PaginatedPipelineOptions
│   │   │   ├── VlmPipelineOptions
│   │   │   └── PdfPipelineOptions
│   │   └── PipelineOptions (basic)
│   ├── AsrPipelineOptions
│   └── VlmExtractionPipelineOptions
```

### PdfPipelineOptions (Most common)

**Key Parameters:**
```python
do_table_structure: bool = True  # Enable TableFormer
do_ocr: bool = True  # OCR text extraction
do_code_enrichment: bool = False  # Code block OCR
do_formula_enrichment: bool = False  # Formula/LaTeX extraction
do_picture_classification: bool = False  # Image classification
do_picture_description: bool = False  # Image captioning via VLM

generate_page_images: bool = False  # Page screenshots
generate_picture_images: bool = False  # Extracted image crops
generate_parsed_pages: bool = False  # Raw parsing output

images_scale: float = 1.0  # Page image scaling factor

# OCR Configuration
ocr_options: OcrOptions = EasyOcrOptions(
    lang: List[str] = ["en"],
    force_full_page_ocr: bool = False,
    bitmap_area_threshold: float = 0.05  # % of page area
)

# Table Structure Options
table_structure_options: TableStructureOptions = {
    do_cell_matching: bool = True  # Match PDF cells vs predicted
    mode: TableFormerMode = "accurate"  # "fast" vs "accurate"
}

# Layout Model Selection
layout_options: LayoutOptions = {
    model_spec: LayoutModelConfig = DOCLING_LAYOUT_HERON  # or EGRET variants
}

# Resource Control
accelerator_options: AcceleratorOptions = {
    device: AcceleratorDevice = "auto"  # cpu, cuda, mps
}

# Advanced
force_backend_text: bool = False  # Use PDF text vs OCR
enable_remote_services: bool = False  # Opt-in for cloud services
artifacts_path: Optional[Path] = None  # Local model cache

document_timeout: Optional[float] = None  # Per-document timeout
```

### OCR Engine Options

**Available Engines:**
1. **EasyOcrOptions** (Default)
   - Languages configurable: `["en"]`, `["fr", "de", "es", "en"]`
   - Supports 80+ languages
   - GPU-capable

2. **RapidOcrOptions**
   - Fast, supports English/Chinese primarily
   - ONNX-based with multiple backends
   - Language parameter not yet supported

3. **TesseractOcrOptions** / **TesseractCliOcrOptions**
   - System dependency required
   - TESSDATA_PREFIX environment variable needed
   - Languages: `["fra", "deu", "spa", "eng"]`

4. **OcrMacOptions**
   - macOS only (10.15+)
   - Built-in Apple vision framework
   - Languages: `["fr-FR", "de-DE", "es-ES", "en-US"]`

### Layout Model Selection

**Options:**
- `DOCLING_LAYOUT_HERON` (NEW DEFAULT - fast & accurate)
- `DOCLING_LAYOUT_HERON_101` (Slightly updated)
- `DOCLING_LAYOUT_EGRET_LARGE` (High accuracy, slower)
- `DOCLING_LAYOUT_EGRET_MEDIUM` (Balance)
- `DOCLING_LAYOUT_EGRET_XLARGE` (Highest accuracy)
- `DOCLING_LAYOUT_V2` (Legacy)

### Vision Language Models (VLM)

**Local Models Available:**
- GraniteDocling-258M (IBM, DocTags output)
- SmolDocling-256M (OpenDS4SD, DocTags output)
- Granite-Vision (General vision tasks)
- Phi-4 Multimodal
- Qwen2.5-VL
- Pixtral-12B
- Gemma-3-12B

**Configuration Example:**
```python
from docling.datamodel.pipeline_options import VlmPipelineOptions
from docling.datamodel import vlm_model_specs

options = VlmPipelineOptions(
    vlm_options=vlm_model_specs.GRANITEDOCLING_TRANSFORMERS,
    # or custom:
    vlm_options=InlineVlmOptions(
        repo_id="ibm-granite/granite-docling-258M",
        inference_framework=InferenceFramework.TRANSFORMERS,
        transformers_model_type=TransformersModelType.AUTOMODEL_IMAGETEXTTOTEXT,
        supported_devices=[AcceleratorDevice.CUDA, AcceleratorDevice.CPU],
        scale=2.0,
        temperature=0.0,
        max_new_tokens=8192,
    )
)

# Remote API-based VLM
options = VlmPipelineOptions(
    vlm_options=ApiVlmOptions(
        url=AnyUrl("http://localhost:8000/v1/chat/completions"),
        headers={},
        timeout=20.0,
    )
)
```

---

## 5. INSTALLATION & SYSTEM REQUIREMENTS

### Core Requirements

**Python Version:** 3.9 - 3.13
**Platform Support:** Linux (x86_64, arm64), macOS (Intel & Apple Silicon), Windows

**Minimal Installation:**
```bash
pip install docling
```

**With all features:**
```bash
uv sync --all-extras  # Development
```

### Core Dependencies

**Always included:**
- pydantic (>=2.0.0)
- docling-core (>=2.48.2) - Core data models
- docling-parse (>=4.4.0) - PDF parsing backend
- docling-ibm-models (>=3.9.1) - Pre-trained models
- PyPDFium2 (>=4.30.0) - PDF rendering
- EasyOCR (>=1.7) - Default OCR engine
- PyTorch (via dependencies)
- Various image/document libraries (Pillow, python-docx, openpyxl, etc.)

### Optional Dependencies

**For OCR:**
```bash
pip install docling[tesserocr]  # System Tesseract required
pip install docling[ocrmac]  # macOS only
pip install docling[rapidocr]  # Fast OCR
```

**For VLM Support:**
```bash
pip install docling[vlm]
# On Apple Silicon (MLX):
# Requires mlx-vlm, transformers, accelerate
# On Linux/CUDA:
# Requires transformers, accelerate, vllm
```

**For Audio (ASR):**
```bash
pip install docling[asr]
# Includes openai-whisper
```

### System Dependencies

**Tesseract (if using TesseractOcrOptions):**
```bash
# macOS
brew install tesseract leptonica pkg-config

# Debian/Ubuntu
apt-get install tesseract-ocr tesseract-ocr-eng libtesseract-dev

# RHEL
dnf install tesseract tesseract-devel tesseract-langpack-eng

# Then set TESSDATA_PREFIX environment variable
export TESSDATA_PREFIX=/path/to/tessdata/
```

### Model Caching & Offline Use

**Default Cache Location:**
- `~/.cache/docling/` - Models directory
- Configurable via `DOCLING_CACHE_DIR`

**Prefetch Models:**
```bash
docling-tools models download
docling-tools models download-hf-repo ds4sd/SmolDocling-256M-preview
```

**Use Offline:**
```python
from docling.datamodel.pipeline_options import PdfPipelineOptions

options = PdfPipelineOptions(
    artifacts_path="/path/to/local/models"
)
converter = DocumentConverter(
    format_options={InputFormat.PDF: PdfFormatOption(pipeline_options=options)}
)
```

---

## 6. ADVANCED FEATURES & ENRICHMENT

### Picture Classification & Description

**Picture Classification:**
- Built-in model identifies document vs. natural images
- Configurable via `do_picture_classification`

**Picture Description (VLM-based):**
```python
from docling.datamodel.pipeline_options import (
    PictureDescriptionVlmOptions,
    PictureDescriptionApiOptions
)

# Local VLM
options = PdfPipelineOptions(
    do_picture_description=True,
    picture_description_options=PictureDescriptionVlmOptions(
        repo_id="HuggingFaceTB/SmolVLM-256M-Instruct",
        prompt="Describe this image in a few sentences.",
        generation_config={"max_new_tokens": 200}
    )
)

# Remote API
options.picture_description_options = PictureDescriptionApiOptions(
    url=AnyUrl("http://localhost:8000/v1/chat/completions"),
    prompt="Describe this image",
    timeout=20.0
)
```

### Code & Formula Enrichment

```python
options = PdfPipelineOptions(
    do_code_enrichment=True,  # Code block OCR
    do_formula_enrichment=True  # Extract LaTeX formulas
)
```

### Structured Information Extraction (Beta)

```python
from docling.document_extractor import DocumentExtractor
from docling.datamodel.extraction import ExtractionTemplateType

extractor = DocumentExtractor()
result = extractor.extract(
    source="document.pdf",
    template={
        "fields": [
            {"name": "invoice_number", "type": "string"},
            {"name": "amount", "type": "float"},
            {"name": "items", "type": "list"}
        ]
    }
)
```

### Custom Export & Serialization

**Markdown with options:**
```python
document.export_to_markdown(
    image_mode="embed"  # or "referenced"
)
```

**Custom JSON structure:**
```python
import json

doc_dict = document.model_dump(mode="json")
json_str = json.dumps(doc_dict)
```

**HTML with styling:**
```python
from docling_core.transforms.serializer.html import (
    HTMLDocSerializer, HTMLOutputStyle
)

serializer = HTMLDocSerializer(
    output_style=HTMLOutputStyle.DOCUMENT  # vs SIMPLE
)
html = serializer.serialize(document)
```

---

## 7. PERFORMANCE CHARACTERISTICS

### Processing Speed

**Benchmarks (Single page, MacBook M3 Max):**

| Pipeline | Model | Device | Time (seconds) |
|----------|-------|--------|----------------|
| StandardPDF | Heron (default) | CPU | ~2-3 |
| VLM | GraniteDocling | CPU | Variable |
| VLM | SmolDocling-MLX | MPS | ~6-7 |
| VLM | SmolDocling-TFM | CPU | ~102 |
| ASR | Whisper-tiny | CPU | ~5-10 |

**Factors Affecting Performance:**
- Document complexity (number of pages, tables, images)
- PDF quality (native text vs. scanned)
- Enabled enrichments (code, formula, descriptions)
- Hardware (CPU vs. GPU acceleration)
- Batch processing (page batching via ThreadedPdfPipeline)

### Memory Usage

**Approximate Requirements:**
- Base models: ~500MB (layout + table models)
- OCR engine: ~100-300MB (depending on language packs)
- VLM models: 500MB-4GB (model size dependent)
- Processing overhead: ~100-200MB per concurrent document

**Optimization Strategies:**
1. Use `generate_page_images=False` (default) to avoid storing images
2. Set `images_scale < 1.0` to reduce memory for large documents
3. Use `ThreadedPdfPipeline` with appropriate batch sizes
4. Configure `OMP_NUM_THREADS=1` for single-threaded use

### Concurrency & Batching

**DocumentConverter Configuration:**
```python
from docling.datamodel.settings import settings

# Batch processing settings
settings.perf.doc_batch_size = 1  # Docs per batch
settings.perf.doc_batch_concurrency = 1  # Parallel threads
settings.perf.page_batch_size = 4  # Pages per batch
settings.perf.elements_batch_size = 16  # Elements per batch
```

**ThreadedPdfPipeline for High Throughput:**
```python
from docling.datamodel.pipeline_options import ThreadedPdfPipelineOptions

options = ThreadedPdfPipelineOptions(
    ocr_batch_size=4,
    layout_batch_size=4,
    table_batch_size=4,
    batch_timeout_seconds=2.0,
    queue_max_size=100
)
```

---

## 8. INTEGRATION PATTERNS

### Pattern 1: Local File Processing

```python
from docling.document_converter import DocumentConverter

converter = DocumentConverter()
result = converter.convert("/path/to/document.pdf")

if result.status == ConversionStatus.SUCCESS:
    markdown = result.document.export_to_markdown()
    json_data = result.document.export_to_dict()
```

### Pattern 2: URL/Remote Document

```python
converter = DocumentConverter()

# Direct URL
result = converter.convert("https://example.com/document.pdf")

# With custom headers
result = converter.convert(
    "https://example.com/document.pdf",
    headers={"Authorization": "Bearer token"}
)
```

### Pattern 3: Stream-Based Processing

```python
from io import BytesIO
from docling.datamodel.base_models import DocumentStream

with open("document.pdf", "rb") as f:
    stream = DocumentStream(name="doc.pdf", stream=BytesIO(f.read()))
    result = converter.convert(stream)
```

### Pattern 4: Batch Processing with Error Handling

```python
sources = [
    "/path/to/doc1.pdf",
    "/path/to/doc2.pdf",
    "https://example.com/doc3.pdf"
]

for result in converter.convert_all(sources, raises_on_error=False):
    if result.status == ConversionStatus.SUCCESS:
        print(f"✓ {result.input.file}")
        # Process result.document
    elif result.status == ConversionStatus.PARTIAL_SUCCESS:
        print(f"⚠ {result.input.file} - Partial success")
    else:
        print(f"✗ {result.input.file} - {result.errors}")
```

### Pattern 5: Custom Pipeline Configuration

```python
from docling.datamodel.pipeline_options import PdfPipelineOptions
from docling.datamodel.base_models import InputFormat
from docling.document_converter import DocumentConverter, PdfFormatOption

# Scanned PDF optimization
pdf_options = PdfPipelineOptions(
    do_ocr=True,
    ocr_options=RapidOcrOptions(lang=["english"]),
    do_table_structure=True,
    do_formula_enrichment=True
)

converter = DocumentConverter(
    format_options={
        InputFormat.PDF: PdfFormatOption(pipeline_options=pdf_options)
    }
)

result = converter.convert("scanned_document.pdf")
```

### Pattern 6: MCP Server Integration (Agentic AI)

```python
# docling-mcp-server automatically exposes:
# - convert(path_or_url, options)
# - extract(path_or_url, template)
# - supported_formats()

# Configured in client (e.g., Claude Desktop):
{
  "mcpServers": {
    "docling": {
      "command": "uvx",
      "args": ["--from=docling-mcp", "docling-mcp-server"]
    }
  }
}
```

### Pattern 7: Export & Serialization Chain

```python
result = converter.convert("document.pdf")

# Export to multiple formats
markdown = result.document.export_to_markdown()
html = result.document.export_to_html()
json_data = result.document.export_to_dict()

# Custom serialization
from docling_core.transforms.serializer.html import HTMLDocSerializer

serializer = HTMLDocSerializer()
html_custom = serializer.serialize(result.document)

# Chunking for RAG
from docling.chunking import ChunkingPipeline

chunks = ChunkingPipeline().chunk(result.document)
for chunk in chunks:
    print(chunk.text)
```

---

## 9. INTEGRATION WITH EXTERNAL SERVICES

### Remote VLM Services (OpenAI-Compatible API)

```python
from docling.datamodel.pipeline_options_vlm_model import ApiVlmOptions
from docling.datamodel.pipeline_options import VlmPipelineOptions

options = VlmPipelineOptions(
    vlm_options=ApiVlmOptions(
        url=AnyUrl("http://localhost:8000/v1/chat/completions"),
        headers={"Authorization": "Bearer api-key"},
        timeout=60.0,
        concurrency=4
    )
)
```

**Supported Services:**
- vLLM (local or remote)
- Ollama (local inference)
- OpenAI API
- Any OpenAI-compatible endpoint

### Remote Services Opt-in

```python
# Explicitly enable remote services
options = PdfPipelineOptions(enable_remote_services=True)

# Without this, RemoteServiceNotAllowedError is raised
```

### OCR Cloud Services

Picture description via cloud APIs requires:
```python
options = PdfPipelineOptions(
    enable_remote_services=True,
    do_picture_description=True,
    picture_description_options=PictureDescriptionApiOptions(
        url=AnyUrl("https://api.example.com/vision"),
        timeout=30.0
    )
)
```

---

## 10. DEBUGGING & TROUBLESHOOTING

### Debug Settings

```python
from docling.datamodel.settings import settings

settings.debug.profile_pipeline_timings = True
settings.debug.visualize_layout = True
settings.debug.debug_output_path = "/tmp/docling_debug"

# For CPU-only operations
import os
os.environ["OMP_NUM_THREADS"] = "1"
```

### Result Inspection

```python
result = converter.convert("document.pdf")

# Execution timing
for stage, timing in result.timings.items():
    print(f"{stage}: {timing.elapsed_secs}s")

# Confidence scores
print(result.confidence.document_overall_confidence)

# Per-page metadata
for page in result.pages:
    print(f"Page {page.page_no}: {len(page.elements)} elements")

# Error diagnostics
if result.errors:
    for error in result.errors:
        print(f"{error.component_type}: {error.error_message}")
```

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Model download fails | Network issue | `docling-tools models download` in offline environment |
| OCR poor quality | Document quality | Increase `ocr_options.bitmap_area_threshold` |
| Slow processing | Large document | Use `page_range=(1,50)` or `ThreadedPdfPipeline` |
| Memory overflow | Too many images | Set `generate_page_images=False` |
| Table merge errors | PDF cell layout | Set `table_structure_options.do_cell_matching=False` |

---

## 11. QUALITY METRICS & CONFIDENCE

### Confidence Reporting

**ConversionResult.confidence:**
```python
class ConfidenceReport(BaseModel):
    document_overall_confidence: float  # 0-1 overall quality
    # Additional per-component metrics available
```

**Usage:**
```python
result = converter.convert("document.pdf")
if result.confidence.document_overall_confidence > 0.8:
    print("High confidence extraction")
else:
    print("Consider manual review")
```

### Validation Strategies

1. **Post-conversion validation:**
   - Check `ConversionStatus` enum
   - Review `errors` list
   - Inspect confidence scores

2. **Pre-processing:**
   - Set `max_num_pages`, `max_file_size` limits
   - Validate `page_range`

3. **Output validation:**
   - Export to multiple formats
   - Cross-reference table extraction
   - Verify image inclusion

---

## SUMMARY TABLE: KEY FINDINGS

| Aspect | Finding | Confidence |
|--------|---------|-----------|
| **Core Library Version** | 2.63.0 deployed | High |
| **Python Support** | 3.9-3.13 | High |
| **Input Formats** | 14+ (PDF, DOCX, HTML, images, audio, XML) | High |
| **Architecture** | Modular: Backend + Pipeline + Models | High |
| **Main API** | DocumentConverter with high-level interface | High |
| **Document Model** | DoclingDocument (unified, hierarchical, Pydantic-based) | High |
| **Export Formats** | Markdown, JSON, HTML, DocTags, Plain text | High |
| **VLM Support** | 8+ local models + remote API support | High |
| **OCR Engines** | 5 options (EasyOCR default + alternatives) | High |
| **Performance** | 2-3s per PDF page (varies by model/hardware) | Medium |
| **Concurrency** | ThreadedPdfPipeline for batching + thread pool support | High |
| **MCP Integration** | Native MCP server support for agentic AI | High |
| **Configuration** | Extensive PipelineOptions with sensible defaults | High |
| **Local Processing** | First-class support with optional remote services | High |
| **Quality Gates** | Confidence scores, error reporting, validation | High |

---

## RECOMMENDED PROGRAMMATIC USAGE FOR MCP INTEGRATION

```python
import sys
from io import BytesIO
from pathlib import Path
from typing import Union, Dict, List, Optional, Any

from docling.document_converter import DocumentConverter
from docling.datamodel.base_models import InputFormat, DocumentStream, ConversionStatus
from docling.datamodel.pipeline_options import PdfPipelineOptions
from docling.document_converter import PdfFormatOption

class DoclingWorker:
    """Wrapper for MCP integration"""
    
    def __init__(self, artifacts_path: Optional[str] = None):
        self.converter = DocumentConverter(
            format_options={
                InputFormat.PDF: PdfFormatOption(
                    pipeline_options=PdfPipelineOptions(
                        artifacts_path=artifacts_path,
                        do_ocr=True,
                        do_table_structure=True
                    )
                )
            }
        )
    
    def convert_document(
        self,
        source: Union[str, Path, bytes],
        output_format: str = "markdown",
        max_pages: Optional[int] = None
    ) -> Dict[str, Any]:
        """Convert document and return structured result"""
        
        try:
            # Handle different source types
            if isinstance(source, bytes):
                source = DocumentStream(name="document", stream=BytesIO(source))
            
            # Convert with error handling
            result = self.converter.convert(
                source,
                raises_on_error=False,
                max_num_pages=max_pages or sys.maxsize
            )
            
            # Return structured output
            return {
                "status": result.status.value,
                "content": self._export_document(result.document, output_format),
                "metadata": {
                    "pages": len(result.pages) if result.pages else 0,
                    "confidence": result.confidence.mean_grade if result.confidence else None,
                    "errors": [e.error_message for e in result.errors] if result.errors else []
                }
            }
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }
    
    def _export_document(self, doc, format: str) -> Union[str, Dict]:
        if format == "markdown":
            return doc.export_to_markdown()
        elif format == "json":
            return doc.export_to_dict()
        elif format == "html":
            return doc.export_to_html()
        else:
            return doc.export_to_text()
```

---

**Document Version:** Research Summary v1.0
**Last Updated:** November 2025
**Repository:** https://github.com/docling-project/docling
**License:** MIT
