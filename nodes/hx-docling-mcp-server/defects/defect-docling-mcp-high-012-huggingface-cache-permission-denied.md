# Defect: HuggingFace Cache Permission Denied Due to systemd ProtectHome

**Defect ID**: defect-docling-mcp-high-012-huggingface-cache-permission-denied
**Severity**: HIGH
**Status**: IDENTIFIED
**Date Discovered**: 2025-12-04
**Discovered By**: julia-santos (Testing & Quality Specialist)
**Affected Component**: docling-mcp.service systemd unit
**Test Phase**: Full Test Suite Execution

---

## Summary

PDF and image conversion operations fail with `PermissionError: [Errno 13] Permission denied: '/home/docling-mcp@hx.dev.local/.cache/huggingface/token'` due to systemd `ProtectHome=true` security restriction blocking access to user home directory cache.

---

## Impact

**Severity Justification**: HIGH
- **Functionality Impact**: 4/19 functionality tests FAIL (PDF, scanned PDF with OCR, image OCR)
- **Test Coverage Impact**: 4/6 multimodal tests FAIL (digital PDF, scanned PDF, image OCR)
- **User Impact**: All PDF processing and OCR operations non-functional
- **Scope**: Affects core document processing capability for most common document format (PDF)

**Affected Tests**:
- TC-FUNC-001: Convert PDF document - FAIL
- TC-MULTI-001: Digital PDF processing - FAIL
- TC-MULTI-002: Scanned PDF with OCR - FAIL
- TC-MULTI-006: Image OCR processing - FAIL

---

## Root Cause Analysis

### Technical Root Cause

The systemd service unit (`/etc/systemd/system/docling-mcp.service`) contains:
```ini
ProtectHome=true
ReadWritePaths=/opt/docling-mcp/application /var/log/docling-mcp
```

`ProtectHome=true` makes `/home`, `/root`, and `/run/user` directories inaccessible (appear empty) to the service. The HuggingFace library attempts to access `/home/docling-mcp@hx.dev.local/.cache/huggingface/token` for model downloads, triggering permission denied error.

### Why This Occurred

1. Systemd service configured with strict security hardening (`ProtectHome=true`)
2. HuggingFace library defaults to `~/.cache/huggingface/` for model cache
3. Home directory cache path not added to `ReadWritePaths` exemption list
4. PDF processing requires HuggingFace models for layout analysis and OCR

### Evidence

**Error Message**:
```
PermissionError: [Errno 13] Permission denied: '/home/docling-mcp@hx.dev.local/.cache/huggingface/token'
```

**Service Configuration**:
```bash
$ systemctl cat docling-mcp.service | grep -i 'Protect\|ReadWrite'
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/docling-mcp/application /var/log/docling-mcp
```

**Test Results**:
```
Total Tests:   17
Passed:        11 (64.7%)
Failed:        4 (PDF/OCR related)
Blocked:       2 (dependent on PDF conversion)
```

---

## Reproduction Steps

1. Start docling-mcp.service with `ProtectHome=true` configuration
2. Initialize MCP session
3. Attempt to convert PDF document:
   ```bash
   curl -X POST http://localhost:8000/mcp \
     -H "mcp-session-id: <session>" \
     -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"convert_document","arguments":{"source":"/path/to/sample.pdf"}},"id":1}'
   ```
4. **Observe**: Permission denied error on HuggingFace cache access

---

## Solution

### Recommended Fix

Add HuggingFace cache directory to `ReadWritePaths` in systemd service unit:

**File**: `/etc/systemd/system/docling-mcp.service`

**Current**:
```ini
ReadWritePaths=/opt/docling-mcp/application /var/log/docling-mcp
```

**Corrected**:
```ini
ReadWritePaths=/opt/docling-mcp/application /var/log/docling-mcp /home/docling-mcp@hx.dev.local/.cache
```

**Apply**:
```bash
sudo systemctl daemon-reload
sudo systemctl restart docling-mcp.service
```

### Alternative Solution (Less Secure)

Set `TRANSFORMERS_CACHE` environment variable to redirect cache to `/opt/docling-mcp/`:

```ini
Environment="TRANSFORMERS_CACHE=/opt/docling-mcp/cache/huggingface"
```

**Rationale for Recommended Fix**:
- Maintains strict security hardening (`ProtectHome=true` remains enabled)
- Adds minimal exemption for HuggingFace cache only
- Follows principle of least privilege
- Standard HuggingFace cache location behavior preserved

---

## Verification Steps

After fix applied:

1. **Verify service starts**:
   ```bash
   systemctl status docling-mcp.service
   ```

2. **Test PDF conversion**:
   ```bash
   curl -X POST http://localhost:8000/mcp \
     -H "mcp-session-id: <session>" \
     -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"convert_document","arguments":{"source":"/opt/docling-mcp/tests/test-data/pdf/sample-digital.pdf"}},"id":1}'
   ```
   **Expected**: Document ID returned, no permission error

3. **Test OCR**:
   ```bash
   curl -X POST http://localhost:8000/mcp \
     -H "mcp-session-id: <session>" \
     -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"convert_document","arguments":{"source":"/opt/docling-mcp/tests/test-data/pdf/sample-scanned.pdf","ocr_enabled":true}},"id":2}'
   ```
   **Expected**: OCR text extracted, no permission error

4. **Re-run full test suite**:
   ```bash
   /tmp/test-docling-mcp-suite.sh
   ```
   **Expected**: TC-FUNC-001, TC-MULTI-001, TC-MULTI-002, TC-MULTI-006 → PASS

---

## Prevention

1. **Documentation**: Update deployment procedure to include HuggingFace cache path in `ReadWritePaths`
2. **Test Coverage**: Add systemd security restriction testing to deployment validation tests
3. **Service Template**: Update systemd service template to include HuggingFace cache path by default
4. **Integration Testing**: Add PDF/OCR tests to pre-deployment validation suite

---

## Related Information

**Related Tests**:
- TC-FUNC-001: Convert PDF document
- TC-MULTI-001: Digital PDF processing
- TC-MULTI-002: Scanned PDF with OCR
- TC-MULTI-006: Image OCR processing

**Configuration Files**:
- `/etc/systemd/system/docling-mcp.service`

**Documentation**:
- HuggingFace Transformers cache documentation: https://huggingface.co/docs/transformers/installation#cache-setup
- systemd security: https://www.freedesktop.org/software/systemd/man/systemd.exec.html#ProtectHome=

---

## Status History

- **2025-12-04**: Defect identified during full test suite execution (julia-santos)
- **2025-12-04**: Root cause analysis complete (systemd ProtectHome restriction)
- **2025-12-04**: Solution documented (add ReadWritePaths exemption)

---

**Assignee**: william-chen (Infrastructure Specialist)
**Priority**: HIGH (blocks operational promotion)
**Resolution**: Pending implementation and verification
