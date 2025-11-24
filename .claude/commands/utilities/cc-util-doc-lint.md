---
document: cc-util-doc-lint
version: 1.2
date: 2025-11-24
status: APPROVED
type: utility-command
description: Documentation linting utility for validating documentation compliance, checking formatting standards, verifying semantic XML structure, detecting content quality issues, and providing automated remediation guidance
applies_to: all_workflows, all_orchestrations, documentation_quality, compliance_validation, standards_enforcement
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-doc-lint.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Documentation Linting Utility - Automated Documentation Validation
**Version:** 1.2
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Updated to v2.1 metadata format with location field)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Provide automated documentation validation checking structure compliance, formatting standards, semantic XML correctness, content quality, and metadata completeness with actionable remediation guidance
</metadata>

<objective>
**Purpose:** Establish systematic documentation validation that enforces documentation standards automatically, catches quality issues early, ensures consistency across project documentation, validates semantic XML structure, and provides clear remediation guidance for non-compliant documentation.

**Utility Capabilities:**
- Validate markdown structure and formatting compliance
- Check semantic XML tag usage and nesting correctness
- Verify metadata completeness and accuracy
- Detect content quality issues (incomplete sections, placeholder text)
- Validate cross-references and internal links
- Check documentation naming conventions
- Enforce documentation templates adherence
- Generate linting reports with severity levels (error, warning, info)
- Provide automated remediation guidance for issues found
- Support batch linting across multiple documents
- Track documentation quality metrics over time

**When to Use This Utility:**
- Before registering artifacts to ensure documentation compliance
- During artifact status transitions (Draft → Review → Approved)
- As part of quality gate validation for documentation deliverables
- Before phase transitions requiring documentation approval
- During documentation reviews to identify issues systematically
- When updating documentation standards to validate existing docs
- In CI/CD pipelines for automated documentation quality checks
- During project closeout to validate final documentation compliance
</objective>

<utility_overview>
**Core Function:**
This utility validates documentation by applying configurable linting rules, checking structure and formatting, validating semantic XML tags, assessing content quality, and generating detailed reports with issue severity levels and remediation guidance.

**Documentation Linting Process:**
1. **Select Documents** - Identify documents to validate
2. **Apply Linting Rules** - Execute validation rules against documents
3. **Check Structure** - Verify required sections present and properly formatted
4. **Validate Semantic XML** - Check XML tags usage, nesting, completeness
5. **Assess Content Quality** - Detect placeholders, incomplete content, quality issues
6. **Verify Metadata** - Validate YAML frontmatter and metadata sections
7. **Check Cross-References** - Verify internal links and artifact references
8. **Classify Issues** - Assign severity levels (error, warning, info)
9. **Generate Report** - Create detailed linting report with findings
10. **Provide Remediation** - Include specific guidance for fixing each issue

**Key Principle:** Automated documentation validation catches issues early, enforces consistency, and maintains documentation quality throughout project lifecycle.
</utility_overview>

<state_management>
**State Management Pattern:**

This utility is **stateless** - the cc-util-doc-lint.md file contains instructions and validation rules only.

**State artifacts** are created by following these instructions:
- **Linting Reports:** `/projects/{project-name}/doc-lint/reports/lint-report-{doc-name}-YYYYMMDD.md` (persistent)
- **Quality Metrics:** `/projects/{project-name}/doc-lint/metrics.md` (persistent, trend tracking)
- **Batch Results:** `/projects/{project-name}/doc-lint/batch-results-YYYYMMDD.md` (periodic)
- **Standards Compliance:** `/projects/{project-name}/doc-lint/compliance-summary.md` (persistent, updated)

These state artifacts are:
- Created during first linting execution
- Updated after each linting run
- Persistent across sessions
- Project-specific (one doc-lint directory per project)

**Distinction:**
- **Utility** = Stateless instructions + validation rules (this document)
- **Artifacts** = Stateful files created per project (reports, metrics, compliance summaries)

**Quality Metrics Evolution:**
Documentation quality metrics track over time:
- Charter phase: Initial documentation quality baseline established
- Spec phase: Technical documentation quality tracked
- Execution phase: Code documentation and runbooks quality monitored
- Closeout phase: Final documentation compliance verification

This evolution demonstrates documentation quality improvement trajectory and supports process refinement.
</state_management>

<validation_rules>
**Rule Categories:**

**Structure Validation Rules:**

**STRUCT-001: Required Sections Present**
- **Description:** Document must contain all required sections for its type
- **Severity:** Error
- **Check:** Verify required section headings exist
- **Example:** Charter documents require: Objectives, Scope, Stakeholders, Constraints, Success Criteria
- **Remediation:** Add missing required sections using appropriate template

**STRUCT-002: Section Order Correct**
- **Description:** Sections must appear in standard order
- **Severity:** Warning
- **Check:** Verify section sequence matches template
- **Example:** Metadata → Objective → Overview → Procedures → Examples
- **Remediation:** Reorder sections to match standard template sequence

**STRUCT-003: Heading Hierarchy Valid**
- **Description:** Heading levels must follow proper hierarchy (no skipped levels)
- **Severity:** Error
- **Check:** Verify H1 → H2 → H3 progression, no H1 → H3 skips
- **Remediation:** Adjust heading levels to maintain proper hierarchy

**STRUCT-004: Minimum Content Length**
- **Description:** Sections must contain minimum meaningful content
- **Severity:** Warning
- **Check:** Sections with < 50 characters flagged as potentially incomplete
- **Remediation:** Expand section with substantive content or mark as intentionally brief

**Formatting Validation Rules:**

**FORMAT-001: Markdown Syntax Correct**
- **Description:** Valid markdown syntax throughout document
- **Severity:** Error
- **Check:** Detect malformed lists, broken links, invalid code blocks
- **Remediation:** Fix markdown syntax errors per standard markdown spec

**FORMAT-002: Code Block Language Specified**
- **Description:** Code blocks must specify language for syntax highlighting
- **Severity:** Warning
- **Check:** Detect ``` without language specifier
- **Remediation:** Add language identifier: ```python, ```bash, ```yaml

**FORMAT-003: List Formatting Consistent**
- **Description:** Lists use consistent markers (-, *, or numbers)
- **Severity:** Info
- **Check:** Mixed list markers within same list
- **Remediation:** Standardize on single list marker type per list

**FORMAT-004: Link Format Valid**
- **Description:** Links follow markdown link syntax [text](url)
- **Severity:** Error
- **Check:** Detect malformed links, broken references
- **Remediation:** Fix link syntax to [descriptive text](valid-url)

**Semantic XML Validation Rules:**

**XML-001: Valid XML Tags**
- **Description:** Only approved semantic XML tags used
- **Severity:** Error
- **Check:** All XML tags match approved tag list
- **Approved Tags:** `<metadata>`, `<metadata_footer>`, `<objective>`, `<procedure>`, `<example>`, `<template>`, `<critical_reminders>`, `<validation_checklist>`, `<validation_checklists>`, `<related_documents>`, `<notes>`, `<inputs>`, `<outputs>`, `<description>`, `<duration>`, `<actions>`, `<state_management>`, `<quality_gate>`, `<quality_gates>`, `<rationale>`, `<integration_convention>`, `<usage_examples>`, `<visual_diagrams>`, `<decision_tree>`, `<conflict_resolution>`, etc.
- **Remediation:** Replace invalid tags with approved semantic XML tags

**XML-002: Tag Nesting Correct**
- **Description:** XML tags properly nested and closed
- **Severity:** Error
- **Check:** Opening tags have matching closing tags, proper nesting
- **Remediation:** Fix tag nesting and ensure all tags properly closed

**XML-003: Required Attributes Present**
- **Description:** Tags requiring attributes have them specified
- **Severity:** Error
- **Check:** Tags like `<procedure>` require `name` attribute
- **Remediation:** Add required attributes to XML tags

**XML-004: Tag Content Not Empty**
- **Description:** XML tags must contain meaningful content
- **Severity:** Warning
- **Check:** XML tags with no content or only whitespace
- **Remediation:** Add content to XML tags or remove empty tags

**Content Quality Rules:**

**CONTENT-001: No Placeholder Text**
- **Description:** Placeholder text must be replaced with actual content
- **Severity:** Error
- **Check:** Detect [TODO], [TBD], [PLACEHOLDER], {placeholder}, XXX, etc.
- **Remediation:** Replace placeholder text with actual content

**CONTENT-002: No Lorem Ipsum**
- **Description:** Lorem ipsum filler text must be removed
- **Severity:** Error
- **Check:** Detect "lorem ipsum" text patterns
- **Remediation:** Replace with actual content

**CONTENT-003: Consistent Terminology**
- **Description:** Key terms used consistently throughout document
- **Severity:** Info
- **Check:** Detect term variations (e.g., "artifact" vs "deliverable" vs "output")
- **Remediation:** Standardize on single term for each concept

**CONTENT-004: Acronyms Defined**
- **Description:** Acronyms defined on first use
- **Severity:** Warning
- **Check:** Detect undefined acronyms in text
- **Remediation:** Define acronym on first use: "RAIDD (Risks, Assumptions, Issues, Dependencies, Decisions)"

**Metadata Validation Rules:**

**META-001: YAML Frontmatter Present**
- **Description:** Document includes YAML frontmatter with required fields
- **Severity:** Error
- **Check:** Valid YAML between --- delimiters at document start
- **Required Fields:** workflow, version, date, status, type, description
- **Remediation:** Add YAML frontmatter with required fields

**META-002: Metadata Header Present**
- **Description:** Document includes `<metadata>` section after frontmatter
- **Severity:** Error
- **Check:** `<metadata>` tag present with required fields
- **Required Fields:** Workflow, Version, Date, Status, Type, Purpose
- **Remediation:** Add `<metadata>` section with required fields

**META-003: Metadata Footer Present**
- **Description:** Document includes `<metadata_footer>` at end
- **Severity:** Warning
- **Check:** `<metadata_footer>` tag present at document end
- **Remediation:** Add `<metadata_footer>` section with version, status, compliance notes

**META-004: Version Numbers Valid**
- **Description:** Version numbers follow semantic versioning (X.Y or X.Y.Z)
- **Severity:** Error
- **Check:** Version format matches X.Y or X.Y.Z pattern
- **Remediation:** Use semantic versioning: 1.0, 1.1, 2.0

**Cross-Reference Validation Rules:**

**REF-001: Internal Links Valid**
- **Description:** Internal document links reference existing sections
- **Severity:** Error
- **Check:** Links to #section-name resolve to actual headings
- **Remediation:** Fix internal links to reference valid section anchors

**REF-002: Artifact References Valid**
- **Description:** Referenced artifacts exist in artifact registry
- **Severity:** Warning
- **Check:** ARTIFACT-XXX references match registered artifacts
- **Remediation:** Verify artifact IDs or register missing artifacts

**REF-003: File Paths Correct**
- **Description:** Referenced file paths are valid and accessible
- **Severity:** Warning
- **Check:** File paths in documentation point to existing files
- **Remediation:** Correct file paths or create referenced files

**REF-004: External Links Active**
- **Description:** External URLs are accessible (optional check)
- **Severity:** Info
- **Check:** HTTP/HTTPS URLs return successful response
- **Remediation:** Update or remove broken external links

**Naming Convention Rules:**

**NAME-001: Lowercase with Hyphens**
- **Description:** File names use lowercase with hyphens (kebab-case)
- **Severity:** Error
- **Check:** File name matches pattern: [a-z0-9-]+\.md
- **Invalid:** Charter_Document.md, CharterDocument.md, charter document.md
- **Valid:** charter-document.md
- **Remediation:** Rename file to lowercase with hyphens

**NAME-002: Descriptive File Names**
- **Description:** File names are descriptive of content
- **Severity:** Info
- **Check:** File name length > 10 characters (not overly abbreviated)
- **Remediation:** Use descriptive file names, avoid excessive abbreviation

**NAME-003: Standard Extensions**
- **Description:** Documentation uses standard file extensions
- **Severity:** Error
- **Check:** Extensions match: .md, .yaml, .json
- **Remediation:** Use standard extensions for documentation files

**Template Adherence Rules:**

**TEMPLATE-001: Template Sections Present**
- **Description:** Document follows standard template for its type
- **Severity:** Warning
- **Check:** Required template sections present
- **Remediation:** Add missing template sections or justify omission

**TEMPLATE-002: Section Content Complete**
- **Description:** Template sections contain complete information
- **Severity:** Warning
- **Check:** Template sections not empty or with minimal content
- **Remediation:** Complete template sections with required information

**Infrastructure Documentation Rules:**

**INFRA-001: Systemd Unit File Documentation Present**
- **Description:** Deployment documentation must document systemd service unit files
- **Severity:** Error (for HX-Infrastructure deployment docs)
- **Check:** Deployment docs include systemd unit file section or reference
- **Applicable To:** Service deployment documentation, runbooks
- **Remediation:** Add section documenting systemd service unit file location, configuration, enable/start commands
- **Example:** "Service managed via systemd unit: /etc/systemd/system/postgres.service. Enable: sudo systemctl enable postgres. Start: sudo systemctl start postgres."

**INFRA-002: Bare Metal Installation Steps**
- **Description:** Deployment documentation must specify bare metal (native) installation
- **Severity:** Error (for HX-Infrastructure production/staging docs)
- **Check:** Deployment docs specify Ubuntu 24 bare metal server, native package installation
- **Invalid:** Docker container deployment instructions (except for hx-dev-server)
- **Remediation:** Document native package installation (apt install), configuration file locations, systemd service setup
- **Exception:** Docker deployment allowed only for hx-dev-server (see inventory/nodes.md) for project isolation

**INFRA-003: Manual Procedure Documentation**
- **Description:** Deployment procedures must be manual step-by-step instructions
- **Severity:** Warning (for HX-Infrastructure)
- **Check:** Deployment docs provide manual commands, not automation scripts
- **Invalid:** "Run ansible-playbook deploy.yml", "Execute deploy.sh script"
- **Valid:** Step-by-step manual commands with verification steps
- **Remediation:** Replace automation references with explicit manual procedure steps

**INFRA-004: Ansible Vault Credentials Reference**
- **Description:** Credentials documentation must reference Ansible Vault (no inline secrets)
- **Severity:** Error (security violation)
- **Check:** Documentation references vault for credentials, no passwords/keys in docs
- **Invalid:** "Password: mypassword123", "API Key: sk-abc123"
- **Valid:** "Credentials stored in Ansible Vault: secrets/postgres-vault.yml"
- **Remediation:** Remove inline credentials, reference Ansible Vault location

**INFRA-005: Docker Production Deployment Prohibition**
- **Description:** Production/staging deployment docs must not use Docker (except dev server)
- **Severity:** Error (for HX-Infrastructure)
- **Check:** Deployment docs for production/staging do not reference Docker
- **Exception:** hx-dev-server (see inventory/nodes.md) may use Docker for project isolation
- **Invalid:** "docker-compose up" for production services
- **Valid:** Native systemd service deployment
- **Remediation:** Replace Docker deployment with bare metal systemd service deployment
</validation_rules>

<linting_procedures>
  <procedure name="Lint Single Document">
  **Purpose:** Validate single documentation file against all linting rules
  
  **Linting Process:**
  
  1. **Load Document**
     - Read document content
     - Identify document type (charter, spec, ADR, runbook, etc.)
     - Determine applicable validation rules
  
  2. **Parse Document Structure**
     - Extract YAML frontmatter
     - Parse markdown structure (headings, sections)
     - Identify XML tags and attributes
     - Extract metadata sections
  
  3. **Apply Structure Rules**
     - Check required sections present (STRUCT-001)
     - Verify section order (STRUCT-002)
     - Validate heading hierarchy (STRUCT-003)
     - Check minimum content length (STRUCT-004)
  
  4. **Apply Formatting Rules**
     - Validate markdown syntax (FORMAT-001)
     - Check code block languages (FORMAT-002)
     - Verify list consistency (FORMAT-003)
     - Validate link formats (FORMAT-004)
  
  5. **Apply Semantic XML Rules**
     - Check valid XML tags (XML-001)
     - Verify tag nesting (XML-002)
     - Validate required attributes (XML-003)
     - Check tag content (XML-004)
  
  6. **Apply Content Quality Rules**
     - Detect placeholder text (CONTENT-001)
     - Check for lorem ipsum (CONTENT-002)
     - Assess terminology consistency (CONTENT-003)
     - Verify acronym definitions (CONTENT-004)
  
  7. **Apply Metadata Rules**
     - Check YAML frontmatter (META-001)
     - Verify metadata header (META-002)
     - Check metadata footer (META-003)
     - Validate version numbers (META-004)
  
  8. **Apply Cross-Reference Rules**
     - Validate internal links (REF-001)
     - Check artifact references (REF-002)
     - Verify file paths (REF-003)
     - Test external links (REF-004) [optional]
  
  9. **Apply Naming Rules**
     - Check file name format (NAME-001)
     - Assess name descriptiveness (NAME-002)
     - Verify standard extensions (NAME-003)
  
  10. **Apply Template Rules**
      - Check template sections (TEMPLATE-001)
      - Verify section completeness (TEMPLATE-002)

  11. **Apply Infrastructure Rules** (for HX-Infrastructure deployment docs)
      - Check systemd documentation (INFRA-001)
      - Verify bare metal installation (INFRA-002)
      - Validate manual procedures (INFRA-003)
      - Check Ansible Vault references (INFRA-004)
      - Verify no Docker production references (INFRA-005)

  12. **Classify Issues**
      - Group findings by severity (Error, Warning, Info)
      - Count issues by category
      - Calculate overall quality score

  13. **Generate Linting Report**
      - Document-level summary
      - Issues by severity and category
      - Specific issue details with line numbers
      - Remediation guidance for each issue
      - Quality score and compliance status
  
  **Outputs:**
  - Linting report for document
  - Issue count by severity
  - Quality score (0-100)
  - Compliance status (Compliant/Non-compliant)
  - Remediation action list
  </procedure>

  <procedure name="Batch Lint Documents">
  **Purpose:** Validate multiple documents in batch operation
  
  **Batch Linting Process:**
  
  1. **Identify Document Set**
     - All documents in project
     - Documents by type (charters, specs, ADRs)
     - Documents by phase (charter, spec, execution)
     - Custom document selection
  
  2. **Lint Each Document**
     - Execute "Lint Single Document" for each
     - Aggregate results across documents
  
  3. **Calculate Aggregate Metrics**
     - Total documents linted
     - Total issues found (by severity)
     - Average quality score
     - Compliance rate (% documents compliant)
  
  4. **Identify Problem Documents**
     - Documents with error-level issues
     - Documents with lowest quality scores
     - Documents requiring immediate attention
  
  5. **Generate Batch Report**
     - Summary of batch linting results
     - Per-document quality scores
     - Issue distribution across documents
     - Priority remediation list
     - Compliance dashboard
  
  6. **Track Quality Trends**
     - Compare to previous batch results
     - Identify improving/declining quality
     - Update quality metrics history
  
  **Outputs:**
  - Batch linting report
  - Per-document summaries
  - Aggregate quality metrics
  - Trend analysis
  - Priority remediation list
  </procedure>

  <procedure name="Generate Remediation Guidance">
  **Purpose:** Provide specific, actionable guidance for fixing linting issues
  
  **Remediation Process:**
  
  1. **For Each Issue Found:**
     - Issue description
     - Severity level
     - Specific location (line number, section)
     - Rule violated
     - Current state (what's wrong)
     - Expected state (what's correct)
     - Remediation steps (how to fix)
     - Example of correct format
  
  2. **Prioritize Remediation:**
     - Errors first (blocking issues)
     - Warnings second (quality issues)
     - Info last (suggestions)
  
  3. **Group Related Issues:**
     - Multiple instances of same issue
     - Issues in same section
     - Issues requiring similar fixes
  
  4. **Provide Examples:**
     - Show incorrect format
     - Show correct format
     - Include context
  
  5. **Estimate Effort:**
     - Quick fixes (< 5 minutes per issue)
     - Moderate fixes (5-15 minutes per issue)
     - Significant rework (> 15 minutes per issue)
  
  **Remediation Guidance Format:**
  ```
  ISSUE: [Issue description]
  ══════════════════════════════════════════════════════════════════════
  Severity: [Error|Warning|Info]
  Rule: [RULE-ID] - [Rule name]
  Location: Line X, Section "[Section name]"
  
  CURRENT STATE:
  [Show what's currently wrong]
  
  EXPECTED STATE:
  [Show what's correct]
  
  REMEDIATION STEPS:
  1. [Step 1]
  2. [Step 2]
  3. [Step 3]
  
  EXAMPLE:
  Incorrect: [Example of wrong format]
  Correct: [Example of right format]
  
  ESTIMATED EFFORT: [Quick|Moderate|Significant]
  ```
  
  **Outputs:**
  - Detailed remediation guidance for each issue
  - Prioritized fix list
  - Effort estimates
  - Fix examples
  </procedure>

  <procedure name="Calculate Quality Score">
  **Purpose:** Compute documentation quality score based on linting results
  
  **Scoring Algorithm:**
  
  1. **Start with Base Score:** 100 points
  
  2. **Deduct for Errors:**
     - Each Error-level issue: -5 points
     - Errors are blocking quality issues
  
  3. **Deduct for Warnings:**
     - Each Warning-level issue: -2 points
     - Warnings are quality concerns
  
  4. **Deduct for Info:**
     - Each Info-level issue: -0.5 points
     - Info items are suggestions
  
  5. **Calculate Final Score:**
     - Score = 100 - (Errors × 5) - (Warnings × 2) - (Info × 0.5)
     - Minimum score: 0
     - Maximum score: 100
  
  6. **Assign Quality Grade:**
     - 90-100: Excellent (A)
     - 80-89: Good (B)
     - 70-79: Acceptable (C)
     - 60-69: Needs Improvement (D)
     - < 60: Poor (F)
  
  7. **Determine Compliance Status:**
     - Compliant: No Error-level issues (score ≥ 70)
     - Non-compliant: Has Error-level issues or score < 70
  
  **Outputs:**
  - Numeric quality score (0-100)
  - Letter grade (A-F)
  - Compliance status (Compliant/Non-compliant)
  - Issue breakdown contributing to score
  </procedure>

  <procedure name="Track Quality Metrics">
  **Purpose:** Monitor documentation quality over time
  
  **Metrics Tracking Process:**
  
  1. **Capture Metrics Per Linting Run:**
     - Date of linting
     - Documents linted
     - Total issues found (by severity)
     - Average quality score
     - Compliance rate
  
  2. **Store Historical Data:**
     - Append metrics to history file
     - Maintain time-series data
  
  3. **Calculate Trends:**
     - Quality score trend (improving/stable/declining)
     - Issue count trend
     - Compliance rate trend
  
  4. **Identify Patterns:**
     - Most common issue types
     - Documents frequently non-compliant
     - Improvement velocity
  
  5. **Generate Metrics Dashboard:**
     - Current quality snapshot
     - Historical trends (30/60/90 days)
     - Comparison to targets
     - Recommendations for improvement
  
  **Metrics Dashboard Format:**
  ```
  DOCUMENTATION QUALITY METRICS
  ══════════════════════════════════════════════════════════════════════
  Last Updated: YYYY-MM-DD
  
  CURRENT QUALITY:
  Average Quality Score: XX.X (Grade: [A-F])
  Compliant Documents: X of Y (Z%)
  Total Issues: A (Errors: B, Warnings: C, Info: D)
  
  TRENDS (30 Days):
  Quality Score: [Improving ↑ | Stable → | Declining ↓]
  Compliance Rate: [Improving ↑ | Stable → | Declining ↓]
  
  MOST COMMON ISSUES:
  1. [RULE-ID]: [Count] occurrences
  2. [RULE-ID]: [Count] occurrences
  3. [RULE-ID]: [Count] occurrences
  
  RECOMMENDATIONS:
  - [Recommendation 1 based on trends]
  - [Recommendation 2 based on patterns]
  ```
  
  **Outputs:**
  - Updated metrics history
  - Metrics dashboard
  - Trend analysis
  - Improvement recommendations
  </procedure>
</linting_procedures>

<integration_with_workflows>
**Workflow Integration Points:**

Documentation linting integrates at key validation points:

**Charter Workflow:**
- Phase 2 (Draft): Lint charter document before review
- Phase 3 (Review): Validate compliance before stakeholder distribution
- Phase 4 (Approval): Ensure charter compliant before registration

**Spec Workflow:**
- Phase 2 (Draft): Lint specification and ADRs during development
- Phase 3 (Review): Validate technical documentation compliance
- Phase 4 (Approval): Verify all documentation meets standards

**Task Workflow:**
- Phase 1 (Breakdown): Lint task breakdown document
- Phase 3 (Approval): Validate test suite documentation

**Execution Workflow:**
- Phase 2 (Work): Lint code documentation, runbooks, configs
- Phase 3 (Validation): Validate test documentation
- Phase 4 (Integration): Ensure deployment documentation compliant

**Closeout Workflow:**
- Phase 2 (Documentation): Batch lint all project documentation
- Phase 4 (Formal Closeout): Validate final documentation package compliance

**Artifact Registration:**
Before artifact registration, lint document to ensure compliance, preventing non-compliant artifacts from entering registry.

**Quality Gates:**
Include documentation linting as validation step in quality gates requiring documentation deliverables.
</integration_with_workflows>

<integration_convention>
**How Commands Invoke This Utility:**

This section documents how workflow commands (Set 1) invoke the documentation linting utility. Invocation uses instructional reference pattern with document path and validation requirements.

**From Workflow Commands (Set 1):**
Before artifact registration or status transitions, commands invoke doc linting:

**Example from cc-charter-workflow.md Phase 2:**
"Use cc-util-doc-lint to validate charter document. Lint document:
/projects/auth-system/charter/charter-v1.0.md. Check structure, formatting,
metadata completeness. Generate linting report. Status: Draft requires minimum
score 70 for review transition."

**Example from cc-task-execution-workflow.md Phase 2:**
"Use cc-util-doc-lint to validate runbook documentation. Lint:
/projects/auth-system/runbooks/deployment-runbook.md. Verify required sections,
validate code blocks, check cross-references. Must be compliant before
artifact registration."

**Example from cc-closeout-workflow.md Phase 2:**
"Use cc-util-doc-lint to batch lint all project documentation. Include all
artifacts: charters, specs, ADRs, runbooks, test plans. Generate compliance
report. All documents must achieve compliant status before project closeout."

**From Artifact Tracker (Utility Integration):**
Before artifact registration or status update:

**Example from artifact registration:**
"Before registering ARTIFACT-025 (Test Plan), use cc-util-doc-lint to validate
compliance. Linting score ≥ 70 required for registration. Document remediation
issues if non-compliant."

**Required Inputs:**
1. **Document Path** - File path to document(s) to lint
2. **Document Type** - Charter, spec, ADR, runbook, test plan (determines applicable rules)
3. **Validation Mode** - Single document or batch
4. **Severity Threshold** - Minimum severity to report (Error, Warning, Info)
5. **Project Name** - For report organization
6. **Target Score** - Minimum quality score required (default: 70)
7. **Rule Set** - All rules or subset (structure, formatting, XML, content, metadata)

**Expected Outputs:**

1. **Linting Report** (Primary Output)
   - Format: Structured markdown with issues by severity
   - Location: `/projects/{project-name}/doc-lint/reports/lint-report-{doc-name}-YYYYMMDD.md`
   - Contents: Summary, issues by category/severity, remediation guidance, quality score

2. **Quality Score** (Immediate Feedback)
   - Format: Numeric score (0-100) and grade (A-F)
   - Compliance status (Compliant/Non-compliant)
   - Used for artifact registration decisions

3. **Batch Report** (Multiple Documents)
   - Format: Aggregate results across documents
   - Location: `/projects/{project-name}/doc-lint/batch-results-YYYYMMDD.md`
   - Contents: Per-document scores, aggregate metrics, priority remediation

4. **Quality Metrics Update** (Trend Tracking)
   - Format: Time-series metrics data
   - Location: `/projects/{project-name}/doc-lint/metrics.md` (appended)
   - Contents: Linting run date, scores, issue counts, trends

5. **Compliance Summary** (Project-Wide Status)
   - Format: Compliance dashboard
   - Location: `/projects/{project-name}/doc-lint/compliance-summary.md` (updated)
   - Contents: Overall compliance rate, document status, recommendations

**State Management:**

**Stateless Component:**
- cc-util-doc-lint.md utility file (this document)
- Instructions for linting procedures
- Validation rules and remediation guidance
- No state maintained in utility itself

**Stateful Artifacts:**
- Linting reports: `/projects/{project-name}/doc-lint/reports/` (per-document validation results)
- Quality metrics: `/projects/{project-name}/doc-lint/metrics.md` (historical trend data)
- Batch results: `/projects/{project-name}/doc-lint/batch-results-YYYYMMDD.md` (aggregate validation)
- Compliance summary: `/projects/{project-name}/doc-lint/compliance-summary.md` (project status)
- Created/updated by following utility procedures
- Persistent across sessions
- Project-specific

**File Organization:**
```
/projects/{project-name}/
  doc-lint/
    reports/
      lint-report-charter-20251120.md        ← Individual document reports
      lint-report-spec-20251122.md
      lint-report-adr-001-20251123.md
    batch-results-20251125.md                ← Batch validation results
    metrics.md                               ← Historical quality metrics
    compliance-summary.md                    ← Current compliance status
```

**Invocation Pattern Summary:**
1. Caller identifies document(s) requiring validation
2. Caller references cc-util-doc-lint with document path and type
3. Linting rules applied systematically
4. Issues classified by severity with remediation guidance
5. Quality score calculated
6. Linting report generated at standard location
7. Quality metrics updated for trend tracking
8. Compliance status returned to caller
9. Artifact registration proceeds if compliant, blocked if non-compliant
</integration_convention>

<usage_examples>
  <example name="Lint Charter Document">
  **Scenario:** Validating charter document before review phase transition
  
  **Command:**
  ```
  Lint document:
  - Document: /projects/auth-system/charter/charter-v1.0.md
  - Type: Charter
  - Target Score: 70 (minimum for review)
  ```
  
  **Utility Process:**
  1. Load charter document
  2. Apply charter-specific validation rules
  3. Find 2 errors (missing stakeholder section, placeholder in constraints)
  4. Find 3 warnings (section order, code block without language, internal link)
  5. Calculate score: 100 - (2×5) - (3×2) = 84 (Grade B)
  6. Generate linting report with remediation guidance
  
  **Output:**
  ```
  LINTING REPORT - charter-v1.0.md
  ══════════════════════════════════════════════════════════════════════
  Date: 2025-11-20
  Quality Score: 84/100 (Grade: B)
  Compliance Status: Non-compliant (2 errors must be fixed)
  
  SUMMARY:
  Total Issues: 5
  - Errors: 2 (blocking)
  - Warnings: 3 (quality concerns)
  - Info: 0
  
  ERRORS (Must Fix):
  1. [STRUCT-001] Missing required section "Stakeholders"
     Location: Document structure
     Remediation: Add Stakeholders section after Scope section
  
  2. [CONTENT-001] Placeholder text in Constraints section
     Location: Line 45, Constraints section
     Current: "Constraints: [TBD]"
     Expected: Actual constraint content
     Remediation: Replace [TBD] with identified project constraints
  
  WARNINGS (Should Fix):
  1. [STRUCT-002] Section order incorrect
     Current: Scope → Objectives
     Expected: Objectives → Scope
     Remediation: Move Objectives section before Scope
  
  2. [FORMAT-002] Code block missing language specifier
     Location: Line 67
     Remediation: Change ``` to ```yaml
  
  3. [REF-001] Internal link broken
     Location: Line 89
     Link: #success-criteria
     Issue: Section heading is "Success Metrics" not "Success Criteria"
     Remediation: Update link to #success-metrics
  
  RECOMMENDED ACTIONS:
  1. Fix 2 errors (estimated 10 minutes)
  2. Fix 3 warnings (estimated 15 minutes)
  3. Re-lint document
  4. Target score after remediation: 100 (Grade A)
  ```
  </example>

  <example name="Batch Lint All ADRs">
  **Scenario:** Validating all architecture decision records for compliance
  
  **Command:**
  ```
  Batch lint documents:
  - Document Type: ADR (Architecture Decision Records)
  - Path: /projects/auth-system/adrs/*.md
  - Target Score: 80 (high standard for ADRs)
  ```
  
  **Utility Process:**
  1. Identify 5 ADR documents
  2. Lint each ADR individually
  3. Aggregate results
  4. Calculate compliance rate
  5. Generate batch report
  
  **Output:**
  ```
  BATCH LINTING REPORT - Architecture Decision Records
  ══════════════════════════════════════════════════════════════════════
  Date: 2025-11-22
  Documents Linted: 5
  Target Score: 80
  
  AGGREGATE RESULTS:
  Average Quality Score: 88.4 (Grade: B+)
  Compliant Documents: 4 of 5 (80%)
  Total Issues: 12 (Errors: 1, Warnings: 7, Info: 4)
  
  PER-DOCUMENT SCORES:
  1. ADR-001-oauth2.md: 95 (A) ✓ Compliant
  2. ADR-002-database.md: 91 (A-) ✓ Compliant
  3. ADR-003-caching.md: 87 (B+) ✓ Compliant
  4. ADR-004-logging.md: 82 (B) ✓ Compliant
  5. ADR-005-monitoring.md: 67 (D) ❌ Non-compliant
  
  PRIORITY REMEDIATION:
  ADR-005-monitoring.md (Score: 67):
  - 1 Error: Missing "Alternatives Considered" section
  - 4 Warnings: Incomplete rationale, metadata footer missing, 2 broken links
  - Estimated effort to compliance: 30 minutes
  
  COMMON ISSUES ACROSS ADRs:
  1. Metadata footer missing (3 documents) - Add footer per template
  2. External links not validated (2 documents) - Verify URLs active
  
  RECOMMENDATIONS:
  1. Prioritize ADR-005 remediation (only non-compliant document)
  2. Add metadata footers to ADR-002, ADR-003, ADR-004
  3. Update documentation standards training to emphasize metadata completeness
  ```
  </example>

  <example name="Pre-Registration Linting">
  **Scenario:** Validating runbook before artifact registration
  
  **Command:**
  ```
  Lint document for artifact registration:
  - Document: /projects/auth-system/runbooks/deployment-runbook.md
  - Type: Runbook
  - Minimum Score: 70 (artifact registration requirement)
  ```
  
  **Utility Process:**
  1. Lint deployment runbook
  2. Find 0 errors, 1 warning, 2 info
  3. Calculate score: 100 - 0 - (1×2) - (2×0.5) = 97
  4. Compliance: Yes (no errors, score > 70)
  5. Approve for artifact registration
  
  **Output:**
  ```
  LINTING REPORT - deployment-runbook.md
  ══════════════════════════════════════════════════════════════════════
  Quality Score: 97/100 (Grade: A)
  Compliance Status: ✓ Compliant
  Artifact Registration: APPROVED
  
  SUMMARY:
  Total Issues: 3 (all minor)
  - Errors: 0
  - Warnings: 1
  - Info: 2
  
  WARNINGS:
  1. [CONTENT-004] Acronym "TLS" not defined on first use
     Location: Line 23
     Recommendation: Add definition: "TLS (Transport Layer Security)"
  
  INFO:
  1. [FORMAT-003] Mixed list markers (- and *)
     Location: Lines 45-52
     Recommendation: Standardize on single marker type
  
  2. [CONTENT-003] Term variation: "database" vs "DB"
     Recommendation: Use consistent term throughout
  
  ARTIFACT REGISTRATION DECISION:
  ✓ Document meets compliance requirements
  ✓ Quality score exceeds minimum threshold (97 > 70)
  ✓ No blocking errors present
  → APPROVED for artifact registration
  
  Optional Improvements:
  Addressing 1 warning + 2 info items would achieve perfect 100 score
  Estimated effort: 5 minutes
  ```
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Lint Early and Often:** Validate documentation during creation, not just before approval. Early linting catches issues when easy to fix.

2. ⚠️ **Errors Block Progress:** Error-level issues must be fixed before phase transitions or artifact registration. No exceptions.

3. ⚠️ **Quality Score Threshold:** Minimum score of 70 required for compliant status. Non-compliant documents blocked from approval.

4. ⚠️ **Remediation Guidance Essential:** Every linting issue must have specific, actionable remediation guidance. "Fix it" is not sufficient.

5. ⚠️ **Batch Lint Regularly:** Periodic batch linting across all documentation identifies systemic issues and quality trends.

6. ⚠️ **Semantic XML Compliance:** Semantic XML structure is mandatory for all workflow and orchestration commands. XML validation non-negotiable.

7. ⚠️ **Placeholder Text Forbidden:** [TODO], [TBD], {placeholder} text is error-level issue. All placeholders must be replaced.

8. ⚠️ **Metadata Required:** YAML frontmatter and `<metadata>` section mandatory. Missing metadata blocks artifact registration.

9. ⚠️ **Consistent Standards:** Documentation standards apply uniformly across all document types. No special exceptions.

10. ⚠️ **Fix Root Causes:** If same issue appears across multiple documents, update templates or documentation guidelines, not just individual docs.

11. ⚠️ **Quality Metrics Matter:** Tracking quality metrics over time identifies process improvements and training needs.

12. ⚠️ **Automate Where Possible:** Integrate linting into CI/CD pipelines and development workflows for automatic validation.
</critical_reminders>

<validation_checklist>
**Pre-Linting Checklist:**
- [ ] Document path verified and accessible
- [ ] Document type identified (determines applicable rules)
- [ ] Target quality score established (default: 70)
- [ ] Validation mode selected (single or batch)
- [ ] Severity threshold set (Error, Warning, Info)

**Linting Execution Checklist:**
- [ ] Document loaded successfully
- [ ] Structure rules applied
- [ ] Formatting rules applied
- [ ] Semantic XML rules applied
- [ ] Content quality rules applied
- [ ] Metadata rules applied
- [ ] Cross-reference rules applied
- [ ] Naming rules applied
- [ ] Template rules applied
- [ ] Issues classified by severity
- [ ] Quality score calculated
- [ ] Compliance status determined

**Linting Report Checklist:**
- [ ] Report includes summary (score, compliance, issue count)
- [ ] Issues organized by severity (Errors → Warnings → Info)
- [ ] Each issue has: description, location, rule, severity
- [ ] Remediation guidance provided for each issue
- [ ] Examples included (current vs. expected format)
- [ ] Effort estimates provided
- [ ] Report saved to standard location
- [ ] Quality metrics updated

**Batch Linting Checklist:**
- [ ] All target documents identified
- [ ] Each document linted individually
- [ ] Aggregate metrics calculated
- [ ] Per-document results included
- [ ] Priority remediation list generated
- [ ] Common issues across documents identified
- [ ] Batch report saved
- [ ] Compliance rate calculated
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md` - Artifact registration integration
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-quality-gate.md` - Quality gate validation
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Charter documentation standards
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Specification documentation standards
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Documentation standards reference
- `/home/agent0/HX-Infrastructure/standards/utility-development-standards.md` - Semantic XML and formatting standards
</related_documents>

<metadata_footer>
**Version:** 1.2
**Status:** APPROVED - Production Ready
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Updated to v2.1 metadata format with location field)
**Compliance:** 100% semantic XML structure, comprehensive validation rules, automated quality assessment
**Next Steps:** Use this utility before artifact registration and phase transitions to ensure documentation compliance
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
**Validation Coverage:** 30+ validation rules across 9 categories (including infrastructure documentation rules), 5 linting procedures, quality scoring algorithm, trend tracking, HX-Infrastructure deployment philosophy validation
**Infrastructure Philosophy:** Validates systemd service documentation, bare metal installation procedures, manual deployment steps, Ansible Vault credential references, and prohibits Docker production deployment (except dev server)
</metadata_footer>
