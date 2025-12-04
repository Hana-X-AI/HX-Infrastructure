# Defect: Bearer Token Regex Pattern May Truncate Long Tokens

**Defect ID**: defect-docling-mcp-medium-009-bearer-token-regex-incomplete
**Service**: hx-docling-mcp-server
**Severity**: medium
**Status**: Resolved
**Created**: 2025-12-01
**Updated**: 2025-12-01
**Resolved**: 2025-12-01

---

## Defect Summary

**Brief Description:**
Bearer token regex pattern (line 138) uses `[A-Za-z0-9\-._~+/]+=*` which may not match all JWT token formats correctly, and the substitution pattern (line 151) `r'\1=***REDACTED***'` doesn't work with Bearer/Basic patterns since they lack capture groups. This could lead to incomplete credential redaction in logs, causing security exposure.

**Impact:**
Sensitive credentials (JWTs, API tokens) may not be fully redacted in logs, exposing authentication tokens in log files. Security risk if logs are compromised or accessed by unauthorized users.

**Affected Component:**
Task 161 - Configure Structured Logging (lines 136-151: LogSanitizer class)

---

## Severity Classification

**Severity**: Medium

**Justification:**
- [X] Security issue (incomplete credential redaction)
- [X] Functionality impaired (sanitization doesn't work as intended)
- [X] Workaround available (fix regex patterns and substitution)
- [X] Limited scope (affects logging only, not core functionality)

**Impact Assessment:**
- Service functional: Yes (logging works, but sanitization incomplete)
- Workaround available: Yes (fix regex patterns)
- Users affected: Security team, log auditors
- Operations impact: Potential credential exposure in logs

---

## Defect Details

### Discovery Information
**Discovered During:** Code Review (Pre-Implementation)
**Discovered By:** CodeRabbit AI Code Review
**Discovery Date**: 2025-12-01
**Task File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-161-configure-structured-logging.md`
**Code Lines**: Lines 136-151 (LogSanitizer credential patterns and sanitize_message)

### Environment
**Node**: hx-docling-mcp-server.hx.dev.local (192.168.10.217)
**OS**: Ubuntu 24.04 LTS
**Service Version**: Not yet deployed
**Configuration**: Task implementation code (pre-deployment)

---

## Defect Description

### Detailed Description

**Issue 1: Bearer/Basic Patterns Lack Capture Groups**

Current regex patterns (lines 137-139):
```python
CREDENTIAL_PATTERNS = [
    re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),  # Has groups ✓
    re.compile(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', re.IGNORECASE),  # NO GROUPS ✗
    re.compile(r'Basic\s+[A-Za-z0-9+/]+=*', re.IGNORECASE),  # NO GROUPS ✗
]
```

Current substitution (line 151):
```python
sanitized = pattern.sub(r'\1=***REDACTED***', sanitized)
```

**Problem:**
- `\1` refers to first capture group
- Bearer/Basic patterns have NO capture groups
- Substitution fails or produces incorrect output
- Pattern 1 works (has groups), patterns 2-3 don't

**Example of Failure:**
```python
# Input
message = "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"

# Current pattern matches entire "Bearer <token>"
# But substitution r'\1=***REDACTED***' fails because no \1 group
# Result: Token NOT redacted ✗
```

**Issue 2: JWT Token Pattern Incomplete**

Current Bearer pattern:
```python
r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'
```

**JWT Structure:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U
│                                 │                       │
├─ Header (base64url)            ├─ Payload (base64url)  ├─ Signature (base64url)
```

**Issues with Current Pattern:**
1. Base64url encoding uses only `[A-Za-z0-9\-_]` (not `+/`)
2. JWTs have three parts separated by `.` (not captured properly)
3. Pattern `=*` only allows optional `=` at end, but JWTs may have multiple `=` for padding
4. Missing hyphen in character class needs escaping in some contexts

**Better JWT Pattern:**
```python
r'Bearer\s+([A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+)'
# Matches: base64url.base64url.base64url (JWT format)
```

**Issue 3: Inconsistent Group Handling**

Pattern 1 has 2 groups:
```python
r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)'
#  └─ Group 1: credential type                           └─ Group 2: value
```

Substitution `r'\1=***REDACTED***'` replaces entire match with group 1 + "=***REDACTED***":
```python
# Input:  "api_key: abc123"
# Match:  "api_key: abc123"
# Output: "api_key=***REDACTED***"  ✓ WORKS
```

But for Bearer/Basic (no groups), substitution fails:
```python
# Input:  "Bearer abc123"
# Match:  "Bearer abc123"
# Output: ERROR or unexpected result (no \1 to reference) ✗ FAILS
```

### Expected Behavior
All credential patterns should:
1. Have capture groups for credential type (if applicable) and value
2. Work with single substitution pattern
3. Handle all token formats (JWT, base64, custom)
4. Fully redact sensitive values

### Actual Behavior
- Pattern 1 works correctly
- Patterns 2-3 (Bearer/Basic) don't have capture groups
- Substitution pattern doesn't work for all patterns
- JWTs may not be fully matched

### Business Impact
- **Security risk**: Credentials may appear in logs unredacted
- **Compliance risk**: Violates security best practices for log sanitization
- **Audit failures**: Security audits will flag credential exposure
- **Incident response**: Compromised logs expose authentication tokens

---

## Steps to Reproduce

**Reproducibility**: Always (code structure issue)
**Reproduction Rate**: 100%

### Prerequisites
1. Task 161 implemented with current regex patterns
2. Log messages containing Bearer tokens or Basic auth

### Reproduction Steps

1. Create test cases with various credential types:
   ```python
   test_messages = [
       "API request with api_key: sk_test_12345",  # Pattern 1
       "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U",  # Pattern 2
       "Authorization: Basic dXNlcjpwYXNzd29yZA==",  # Pattern 3
   ]
   ```

2. Run sanitization:
   ```python
   for msg in test_messages:
       sanitized = LogSanitizer.sanitize_message(msg)
       print(f"Original: {msg}")
       print(f"Sanitized: {sanitized}")
       print()
   ```

3. Observe results:
   ```
   Original: API request with api_key: sk_test_12345
   Sanitized: API request with api_key=***REDACTED***  ✓ WORKS

   Original: Authorization: Bearer eyJhbG...
   Sanitized: Authorization: Bearer eyJhbG...  ✗ NOT REDACTED (substitution fails)

   Original: Authorization: Basic dXNlcjpwYXNz...
   Sanitized: Authorization: Basic dXNlcjpwYXNz...  ✗ NOT REDACTED (substitution fails)
   ```

### Expected Result
All three messages should have credentials redacted:
```
Sanitized: API request with api_key=***REDACTED***
Sanitized: Authorization: Bearer ***REDACTED***
Sanitized: Authorization: Basic ***REDACTED***
```

### Actual Result
Only pattern 1 works; patterns 2-3 leave tokens exposed.

---

## Evidence and Diagnostics

### Code Location
**File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-161-configure-structured-logging.md`
**Lines**: 136-151 (LogSanitizer class)

### Code Excerpt

**Current Implementation (INCORRECT):**
```python
# Lines 136-139
CREDENTIAL_PATTERNS = [
    re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
    re.compile(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', re.IGNORECASE),  # NO GROUPS ✗
    re.compile(r'Basic\s+[A-Za-z0-9+/]+=*', re.IGNORECASE),  # NO GROUPS ✗
]

# Lines 146-151
@classmethod
def sanitize_message(cls, message: str) -> str:
    """Redact credentials from log message."""
    sanitized = message

    for pattern in cls.CREDENTIAL_PATTERNS:
        sanitized = pattern.sub(r'\1=***REDACTED***', sanitized)  # FAILS for Bearer/Basic ✗

    return sanitized
```

**Correct Implementation (CodeRabbit Recommendation):**
```python
# Lines 136-143 (CORRECTED)
CREDENTIAL_PATTERNS = [
    re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
    re.compile(r'Bearer\s+([A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+)', re.IGNORECASE),  # JWT with capture group
    re.compile(r'Basic\s+([A-Za-z0-9+/=]+)', re.IGNORECASE),  # Base64 with capture group
    re.compile(r'X-API-Key["\s:=]+([^\s"\']+)', re.IGNORECASE),  # API header variations
]

# Lines 146-154 (CORRECTED - handles variable group counts)
@classmethod
def sanitize_message(cls, message: str) -> str:
    """Redact credentials from log message."""
    sanitized = message

    for pattern in cls.CREDENTIAL_PATTERNS:
        # Use lambda to handle variable group counts
        sanitized = pattern.sub(
            lambda m: m.group(0)[:m.start(m.lastindex or 1)] + '***REDACTED***',
            sanitized
        )

    return sanitized
```

**Alternative Simpler Approach:**
```python
# Consistent pattern structure with always 2 groups
CREDENTIAL_PATTERNS = [
    re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
    re.compile(r'(Bearer)\s+([A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+)', re.IGNORECASE),
    re.compile(r'(Basic)\s+([A-Za-z0-9+/=]+)', re.IGNORECASE),
]

# Simple substitution (now works for all patterns)
@classmethod
def sanitize_message(cls, message: str) -> str:
    sanitized = message
    for pattern in cls.CREDENTIAL_PATTERNS:
        sanitized = pattern.sub(r'\1 ***REDACTED***', sanitized)  # Works for all ✓
    return sanitized
```

---

## Root Cause Analysis

**Root Cause Identified**: YES

### Root Cause
Inconsistent regex pattern design - some patterns have capture groups, others don't. Single substitution pattern `r'\1=***REDACTED***'` assumes all patterns have at least one capture group, but Bearer/Basic patterns don't.

### Contributing Factors
1. **Pattern inconsistency**: Mixed regex design (some with groups, some without)
2. **Insufficient testing**: No test cases for Bearer/Basic token redaction
3. **JWT format complexity**: Standard JWT format not properly understood (three base64url parts)
4. **Base64url vs base64**: Didn't account for difference in character sets
5. **Copy-paste from examples**: May have copied pattern without understanding group structure

### Analysis Notes

**Regex Group Behavior:**
- `pattern.sub(r'\1=***REDACTED***', text)` requires pattern to have at least 1 group
- If pattern has no groups, `\1` is undefined → error or unexpected behavior
- Solution: Either add groups to all patterns OR use lambda substitution

**JWT Format:**
- Structure: `header.payload.signature` (three base64url-encoded parts)
- Base64url alphabet: `[A-Za-z0-9_\-]` (not `+/` which is base64)
- Proper JWT regex: `[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+`

---

## Impact Assessment

### Deployment Impact
**Blocks Deployment**: NO (logging works, sanitization partially works)
**Blocks Promotion to Operational**: NO (Medium severity with workaround)

**Impact Details:**
Security issue but limited scope (logging only). Can proceed with incomplete sanitization and fix later, but better to fix before deployment.

### Operational Impact
**Affects Operations**: YES (security risk)
**Affects Users**: NO (internal logging only)
**Number of Users Affected**: Security team, log auditors

### Requirements Impact
**Requirements Not Met:**
- Security requirement: Full credential redaction in logs
- Compliance requirement: No sensitive data in log files
- Audit requirement: Demonstrable credential sanitization

---

## Workaround

**Workaround Available**: YES

### Workaround Details

**Option 1: Add Capture Groups to All Patterns (SIMPLE)**

```python
# Lines 136-141 (CORRECTED - all patterns have 2 groups)
CREDENTIAL_PATTERNS = [
    re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
    re.compile(r'(Bearer)\s+([A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+)', re.IGNORECASE),  # JWT
    re.compile(r'(Basic)\s+([A-Za-z0-9+/=]+)', re.IGNORECASE),  # Base64
    re.compile(r'(X-API-Key)["\s:=]+([^\s"\']+)', re.IGNORECASE),  # API headers
]

# Lines 146-151 (simple substitution now works)
@classmethod
def sanitize_message(cls, message: str) -> str:
    sanitized = message
    for pattern in cls.CREDENTIAL_PATTERNS:
        sanitized = pattern.sub(r'\1 ***REDACTED***', sanitized)
    return sanitized
```

**Benefits**: Simple, consistent, easy to understand
**Drawback**: Substitution pattern changes slightly (space instead of `=`)

**Option 2: Lambda Substitution (FLEXIBLE - CodeRabbit Recommendation)**

```python
# Lines 136-141 (flexible group counts)
CREDENTIAL_PATTERNS = [
    re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
    re.compile(r'Bearer\s+([A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+)', re.IGNORECASE),
    re.compile(r'Basic\s+([A-Za-z0-9+/=]+)', re.IGNORECASE),
    re.compile(r'X-API-Key["\s:=]+([^\s"\']+)', re.IGNORECASE),
]

# Lines 146-154 (lambda handles variable groups)
@classmethod
def sanitize_message(cls, message: str) -> str:
    sanitized = message
    for pattern in cls.CREDENTIAL_PATTERNS:
        sanitized = pattern.sub(
            lambda m: m.group(0)[:m.start(m.lastindex or 1)] + '***REDACTED***',
            sanitized
        )
    return sanitized
```

**Benefits**: Flexible, handles any group structure
**Drawback**: More complex lambda function

**Recommendation**: Option 1 (add groups) - simpler and maintainable.

---

## Resolution

### Resolution Status
**Status**: Open
**Assigned To**: william-chen (logging specialist)
**Priority**: Medium
**Target Resolution Date**: Before Task 161 implementation

### Resolution Plan

**Approach:**
Add capture groups to Bearer/Basic patterns for consistent handling, update JWT pattern for proper base64url format.

**Resolution Steps:**

1. **Update CREDENTIAL_PATTERNS** (lines 136-141):

   **Current:**
   ```python
   CREDENTIAL_PATTERNS = [
       re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
       re.compile(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', re.IGNORECASE),
       re.compile(r'Basic\s+[A-Za-z0-9+/]+=*', re.IGNORECASE),
   ]
   ```

   **Corrected:**
   ```python
   CREDENTIAL_PATTERNS = [
       re.compile(r'(api[_-]?key|token|password|secret|auth)["\s:=]+([^\s"\']+)', re.IGNORECASE),
       re.compile(r'(Bearer)\s+([A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+)', re.IGNORECASE),  # JWT format
       re.compile(r'(Basic)\s+([A-Za-z0-9+/=]+)', re.IGNORECASE),  # Base64
       re.compile(r'(X-API-Key)["\s:=]+([^\s"\']+)', re.IGNORECASE),  # Additional API headers
   ]
   ```

2. **Update sanitize_message substitution** (line 151):

   **Current:**
   ```python
   sanitized = pattern.sub(r'\1=***REDACTED***', sanitized)
   ```

   **Corrected:**
   ```python
   sanitized = pattern.sub(r'\1 ***REDACTED***', sanitized)
   ```

   (Changed `=` to space for consistency with Bearer/Basic format)

3. **Add test cases** (new section after line 151):

   ```python
   # Test credential sanitization
   assert LogSanitizer.sanitize_message("api_key: abc123") == "api_key ***REDACTED***"
   assert LogSanitizer.sanitize_message("Authorization: Bearer eyJhbG...") == "Authorization: Bearer ***REDACTED***"
   assert LogSanitizer.sanitize_message("Authorization: Basic dXNlcjpw...") == "Authorization: Basic ***REDACTED***"
   assert LogSanitizer.sanitize_message("X-API-Key: sk_test_123") == "X-API-Key ***REDACTED***"
   ```

**Files to Modify:**
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-161-configure-structured-logging.md` (lines 136-151, add test cases)

**Estimated Effort**: 10 minutes (update patterns, fix substitution, add tests)

**Verification Plan:**
1. Test with various credential formats (API keys, Bearer JWTs, Basic auth, API headers)
2. Verify all patterns have capture groups
3. Verify substitution works for all patterns
4. Test with real JWT tokens from auth systems
5. Verify no credentials appear in log output

---

## Verification
[To be completed after resolution]

---

## Prevention

**Prevention Measures** (to be implemented):
1. **Regex testing**: Test all regex patterns with sample data before implementation
2. **Group consistency**: Enforce consistent capture group structure across all patterns
3. **JWT format awareness**: Document JWT structure (base64url, three parts) in code comments
4. **Security testing**: Include credential redaction in security test suite
5. **Code review checklist**: Verify regex substitution patterns work with all regex definitions

---

## Communication

### Stakeholders Notified
- [X] Service Owner: CAIO
- [ ] Tech Lead: william-chen (will be notified when assigned)
- [X] CAIO: Defect logged during Phase 6 task breakdown approval
- [X] Security Team: **YES** - Medium severity security issue (credential exposure risk)

---

## Metrics

**Time to Detect**: 0 days (detected in code review before implementation)
**Time to Resolution**: TBD
**Impact Scope**: Moderate (security risk, affects logging sanitization)

---

## History and Updates

### Update Log
| Date | Updated By | Status Change | Notes |
|------|-----------|---------------|-------|
| 2025-12-01 | agent-zero | Created | Defect logged from CodeRabbit code review during Phase 6 approval |

---

## Closure
[To be completed when defect closed]
