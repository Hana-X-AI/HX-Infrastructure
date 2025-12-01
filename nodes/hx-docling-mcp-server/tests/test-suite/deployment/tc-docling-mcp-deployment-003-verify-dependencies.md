# Test Case: Verify System Dependencies

**Test ID**: tc-docling-mcp-deployment-003
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify all system-level dependencies (poppler-utils, tesseract-ocr, libmagic1, build-essential) are installed and functional.

---

## Test Coverage

**Requirements Covered**:
- DR-003: Dependencies installed
- Plan Section: Phase 2 - System Dependencies (Task 003)

---

## Test Steps

### Step 1: Verify poppler-utils (PDF Processing)

**Action**:
```bash
which pdftotext && echo "PASS: pdftotext installed"
pdftotext -v 2>&1 | head -1
```

**Expected**: poppler-utils installed, pdftotext available

---

### Step 2: Verify tesseract-ocr (OCR Engine)

**Action**:
```bash
which tesseract && echo "PASS: tesseract installed"
tesseract --version | head -1
```

**Expected**: Tesseract 5.x installed

---

### Step 3: Verify libmagic1 (MIME Detection)

**Action**:
```bash
dpkg -l | grep libmagic1 && echo "PASS: libmagic1 installed"
```

**Expected**: libmagic1 package installed

---

### Step 4: Verify build-essential (Compilation Tools)

**Action**:
```bash
gcc --version | head -1 && echo "PASS: gcc installed"
g++ --version | head -1 && echo "PASS: g++ installed"
make --version | head -1 && echo "PASS: make installed"
```

**Expected**: gcc, g++, make all available

---

## Pass/Fail Criteria

**PASS**: All 4 system dependencies installed and functional

**FAIL**: Any dependency missing or non-functional

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-critical-003-dependencies-missing.md`, assign to william-chen

---

**Test Case Version**: 1.0
