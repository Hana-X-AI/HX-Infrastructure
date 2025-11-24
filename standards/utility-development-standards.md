---
document: utility-development-standards
version: 1.1
date: 2025-11-21
status: APPROVED
type: development-standard
description: Comprehensive standards for utility command development including integration patterns, output formats, state management, error handling, and infrastructure awareness
applies_to: all_utility_commands, set_3_development
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/standards/utility-development-standards.md
last_updated: 2025-11-21
update_notes: Added comprehensive metadata, infrastructure integration, procedure alignment, version history, document maintenance
---

# Utility Development Standards
## Development Standards for HX-Infrastructure Utility Commands (Set 3)

**Document Type:** Standard - Utility Command Development
**Version:** 1.1
**Date:** 2025-11-21
**Status:** ✅ APPROVED - Mandatory for All Utility Commands
**Location:** `/home/agent0/HX-Infrastructure/standards/utility-development-standards.md`
**Previous Version:** 1.0 → 1.1 (comprehensive metadata, infrastructure integration, procedure alignment)

---

## Document Purpose

This document defines mandatory standards for all utility commands in Set 3, ensuring consistent architecture, predictable behavior, and seamless integration with workflow commands (Set 1) and orchestration commands (Set 2).

### Target Audience
- **Agent Zero (CC):** STATEFUL orchestrator developing and using utility commands
- **Utility Command Developers:** Must follow these standards when creating new utilities
- **Workflow Command Developers:** Reference for invoking utilities from workflows
- **All Agents:** Reference for utility usage patterns

### Scope
- Integration patterns and calling conventions
- Output format specifications (human-readable and parseable)
- State management architecture (stateless utilities, stateful artifacts)
- Error handling and remediation patterns
- Infrastructure philosophy awareness
- File naming and location conventions
- Template structure requirements
- Cross-utility consistency guidelines

### Authority
**Mandatory for all utility command development.** All utility commands MUST comply with these standards. Non-compliant utilities will be rejected during review.

---

<metadata>
**Document:** Utility Development Standards
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Mandatory for all utility commands
**Type:** Development Standard
**Purpose:** Establish consistent patterns for utility command development ensuring predictable integration, clear outputs, proper state management, effective error handling, and appropriate infrastructure awareness
</metadata>

<objective>
**Purpose:** Define mandatory standards for all utility commands in Set 3, ensuring consistent architecture, predictable behavior, and seamless integration with workflow commands (Set 1) and orchestration commands (Set 2).

**Standards Scope:**
- Integration patterns and calling conventions
- Output format specifications (human-readable and parseable)
- State management architecture (stateless utilities, stateful artifacts)
- Error handling and remediation patterns
- Infrastructure philosophy awareness
- File naming and location conventions
- Template structure requirements
- Cross-utility consistency guidelines

**Compliance:** All utility commands MUST comply with these standards. Non-compliant utilities will be rejected during review.
</objective>

<utility_architecture>
**Fundamental Architecture:**

Utilities are **stateless instruction sets** (markdown command files) that guide Claude Code agents in creating, validating, or managing **stateful artifacts** (project files).

```
┌─────────────────────────────────────┐
│   Utility Command File              │
│   (Stateless Instructions)          │
│   - Procedures                      │
│   - Templates                       │
│   - Validation Rules                │
└──────────────┬──────────────────────┘
               │ guides
               ▼
┌─────────────────────────────────────┐
│   Project Artifacts                 │
│   (Stateful Data Files)             │
│   - Gate history logs               │
│   - Context documents               │
│   - RAIDD logs                      │
│   - Artifact registries             │
└──────────────┬──────────────────────┘
               │ referenced by
               ▼
┌─────────────────────────────────────┐
│   Future Utility Invocations        │
│   (Read State, Execute, Update)     │
└─────────────────────────────────────┘
```

**Key Principles:**
1. **Utilities = Instructions:** Command files contain procedures, not code
2. **Artifacts = State:** Project files contain persistent data
3. **Separation of Concerns:** Utility logic separate from project data
4. **Reusability:** Same utility used across all projects
5. **Predictability:** Consistent patterns across all utilities
</utility_architecture>

<integration_patterns>
**How Workflow/Orchestration Commands Invoke Utilities:**

Utilities are invoked through **instructional references** in workflow and orchestration commands, not programmatic API calls.

**Standard Invocation Pattern:**

```markdown
In workflow command (example from cc-spec-workflow.md):

<phase_transition>
Before proceeding from Phase 2 to Phase 3:

Use cc-util-quality-gate to validate the spec_draft_gate.
- Procedure: "Validate Single Quality Gate"
- Gate: spec_draft_gate
- Evidence: Specification draft document at [path]
- Expected Output: Validation report with PASS/FAIL status

If validation PASS: Proceed to Phase 3
If validation FAIL: Execute remediation plan, re-validate
</phase_transition>
```

**Invocation Components:**

1. **Utility Reference:**
   - Name utility explicitly: "Use cc-util-quality-gate"
   - Claude Code agent loads utility instruction file

2. **Procedure Selection:**
   - Specify which procedure to follow: "Validate Single Quality Gate"
   - Utilities contain multiple procedures; select appropriate one

3. **Input Specification:**
   - Provide required inputs: gate identifier, evidence location
   - Clear, unambiguous input values

4. **Output Expectation:**
   - State expected output: "Validation report with PASS/FAIL status"
   - Agent knows what to produce

5. **Conditional Logic:**
   - Define what happens based on output: "If PASS... If FAIL..."
   - Workflow behavior depends on utility results

**Anti-Patterns (DO NOT USE):**

❌ **Command-line style:** `cc-util-quality-gate --gate=spec_draft --evidence=/path`
- These are instruction files, not executables

❌ **Vague references:** "Check if the spec is ready"
- Too ambiguous; specify utility and procedure

❌ **Implicit inputs:** "Validate the gate"
- Which gate? What evidence? Be explicit

❌ **No output expectation:** "Run validation"
- Agent doesn't know what to produce

**Utility Invocation Checklist:**
- [ ] Utility name explicitly referenced
- [ ] Specific procedure identified
- [ ] All required inputs provided
- [ ] Expected output described
- [ ] Conditional logic defined (what happens with output)
- [ ] Error handling specified (what if utility fails)
</integration_patterns>

<integration_convention_section>
**Mandatory Section in All Utilities:**

Every utility MUST include an `<integration_convention>` section specifying:

1. **How to Invoke:** Standard invocation pattern for this utility
2. **Common Use Cases:** Typical scenarios where utility invoked
3. **Input Requirements:** What invoking command must provide
4. **Output Format:** What utility produces
5. **State Locations:** Where stateful artifacts stored

**Template:**

```xml
<integration_convention>
**How Commands Invoke This Utility:**

Standard invocation from workflow/orchestration commands:

"Use [utility-name] with procedure '[procedure-name]',
[input1]='[value1]', [input2]='[value2]', [etc.]"

**Common Use Cases:**

1. [Workflow/orchestration phase] → [When utility needed]
   Example: "Spec workflow Phase 2 → Before transition to Phase 3"

2. [Another common scenario]
   Example: "Project status review → Generate gate dashboard"

**Input Requirements:**

Required Inputs:
- [input-name]: [description, format, example]
- [input-name]: [description, format, example]

Optional Inputs:
- [input-name]: [description, default value]

**Output Format:**

Human-Readable Output:
- [Description of formatted report for stakeholders]
- Location: [Where report saved]

Parseable Output:
- [Description of structured data for programmatic reference]
- Format: [Markdown sections with consistent structure]

**State Management:**

Stateless Component: This utility command file
Stateful Component: [Description of artifacts created/managed]
State Location: [Directory pattern for state files]
State Persistence: [How long state maintained]

**Integration Examples:**

[2-3 concrete examples of this utility being invoked by workflows/orchestrations]
</integration_convention>
```

**Example from Quality Gate Utility:**

```xml
<integration_convention>
**How Commands Invoke This Utility:**

"Use cc-util-quality-gate with procedure 'Validate Single Quality Gate',
gate='charter_approval_gate', evidence at /projects/auth-system/charter/"

**Common Use Cases:**

1. Charter Workflow Phase 4 → Before completing charter phase
2. Spec Workflow Phase 2 → Before team formation begins  
3. Project Status Review → Generate gate health dashboard

**Input Requirements:**

Required:
- gate_id: Gate identifier (e.g., "spec_draft_gate")
- workflow: Workflow name (e.g., "Specification Workflow")
- evidence_location: Path to evidence artifacts

Optional:
- validator_name: Who performed validation (default: Agent Zero)

**Output Format:**

Human-Readable: Formatted validation report with ✓/✗ status
Location: /projects/{project}/quality-gates/validation-{date}.md

Parseable: Structured gate history entry
Format: Markdown with consistent sections (GATE, STATUS, CRITERIA, etc.)

**State Management:**

Stateless: cc-util-quality-gate.md instruction file
Stateful: Gate history logs per project
Location: /projects/{project}/quality-gates/history.md
Persistence: Duration of project + 2 years archive

**Integration Examples:**

Charter workflow after Phase 4:
"Use cc-util-quality-gate to validate charter_approval_gate before closeout"

Spec workflow phase transition:
"Use cc-util-quality-gate to validate spec_context_gate before team formation"
</integration_convention>
```
</integration_convention_section>

<output_format_standards>
**Dual-Purpose Output Format:**

All utilities MUST produce outputs serving both:
1. **Human review** (stakeholders reading reports)
2. **Programmatic reference** (other commands parsing data)

**Achieved through:** Well-structured markdown with consistent formatting

**Standard Output Structure:**

```markdown
[UTILITY NAME] OUTPUT - [CONTEXT]
══════════════════════════════════════════════════════════════════════
Date: [YYYY-MM-DD HH:MM]
Utility: [utility-name]
Procedure: [procedure-name]
Status: [SUCCESS/FAIL/WARNING]

SUMMARY:
──────────────────────────────────────────────────────────────────────
[High-level summary for humans - 2-3 sentences]
[Key metrics: X of Y, percentage, counts]

DETAILS:
──────────────────────────────────────────────────────────────────────
[Detailed findings organized in consistent sections]
[Use subsections with clear headers]
[Include both descriptive text and structured data]

ACTIONS REQUIRED (if applicable):
──────────────────────────────────────────────────────────────────────
1. [Specific action with effort estimate]
2. [Specific action with effort estimate]
3. [Specific action with effort estimate]

METADATA:
──────────────────────────────────────────────────────────────────────
Version: [version-number]
Generated By: [agent-name]
Project: [project-name]
Reference: [path to state file]
```

**Human-Readable Elements:**

1. **Visual Status Indicators:**
   - ✓ PASS, ❌ FAIL, ⚠ WARNING symbols
   - Color-friendly text (for terminal rendering)
   - Clear section headers with separator lines

2. **Narrative Text:**
   - Descriptive explanations of findings
   - Contextual information for understanding
   - Natural language recommendations

3. **Formatted Tables:**
   - When comparing multiple items
   - When showing structured data sets
   - ASCII-safe table formatting

**Parseable Elements:**

1. **Consistent Section Headers:**
   - Always use same header text for same content type
   - Example: "QUALITY GATE VALIDATION RESULT:" always starts validation reports
   - Other commands can search for these headers

2. **Structured Data Fields:**
   - Key-value pairs: "Status: PASS"
   - Metrics: "Criteria Met: 5 of 5 (100%)"
   - Timestamps: "Date: YYYY-MM-DD HH:MM"

3. **Predictable Formatting:**
   - Same indentation patterns
   - Same separator characters
   - Same field ordering

**File Naming Convention for Outputs:**

```
[utility-prefix]-[output-type]-[project]-[date].md

Examples:
quality-gate-validation-auth-system-2025-11-20.md
context-package-auth-system-alex-2025-11-20.md
raidd-log-auth-system-2025-11-20.md
status-report-auth-system-weekly-2025-11-20.md
```

**Output Location Convention:**

```
/projects/{project-name}/
├── quality-gates/
│   ├── history.md                    (stateful log)
│   ├── validation-2025-11-20.md     (output report)
│   └── validation-2025-11-21.md     (output report)
├── contexts/
│   ├── alex-context-v1.md           (stateful document)
│   ├── frank-context-v1.md          (stateful document)
│   └── handoff-packages/            (output packages)
├── raidd/
│   └── raidd-log.md                 (stateful log)
├── artifacts/
│   └── artifact-registry.md         (stateful registry)
└── reports/
    ├── status-2025-11-20.md         (output report)
    └── status-2025-11-27.md         (output report)
```
</output_format_standards>

<state_management_standards>
**State Architecture:**

**Utilities = Stateless:**
- Utility command files (.md) contain NO state
- Pure instruction sets, reusable across projects
- No project-specific data in utility files
- Version controlled in command system repository

**Artifacts = Stateful:**
- Project-specific files contain ALL state
- Created by following utility procedures
- Updated across project lifecycle
- Version controlled in project repository

**State File Types:**

1. **Logs (Append-Only):**
   - Gate history logs
   - RAIDD logs
   - Activity logs
   - Pattern: New entries appended, old entries preserved

2. **Registries (Update-In-Place):**
   - Artifact registries
   - Status trackers
   - Pattern: Existing entries updated with new data

3. **Versioned Documents (Snapshot):**
   - Context documents (v1, v2, v3...)
   - Configuration snapshots
   - Pattern: New versions created, old versions retained

4. **Reports (Generated):**
   - Status reports
   - Validation reports
   - Pattern: Generated on-demand, ephemeral or archived

**State Persistence Rules:**

| State Type | Retention | Location | Updates |
|------------|-----------|----------|---------|
| Logs | Project lifetime + 2 years | /projects/{project}/logs/ | Append only |
| Registries | Project lifetime + 2 years | /projects/{project}/registries/ | Update in place |
| Versioned Docs | Project lifetime + 2 years | /projects/{project}/contexts/ | Create new versions |
| Reports | 90 days or archive decision | /projects/{project}/reports/ | Generate new |

**State File Format:**

All state files MUST be:
- Plain text markdown (.md extension)
- ASCII-safe encoding (UTF-8 without BOM)
- Version controlled (Git-friendly)
- Human-readable (no binary formats)
- Machine-parseable (consistent structure)

**State Initialization:**

When utility first invoked for project:
1. Check if state file exists
2. If absent, create with initialized structure
3. If present, validate structure and append/update
4. Document initialization in file header

**State Concurrency:**

Utilities assume single-agent execution:
- No concurrent write protection needed
- Sequential execution in Claude Code sessions
- State files locked by filesystem during write
- Multi-session coordination through handoff documents

**State Backup and Recovery:**

State files version controlled in project repository:
- Git provides backup and history
- Recovery through Git checkout
- No separate backup mechanism needed
- Handoff documents preserve critical state across sessions
</state_management_standards>

<error_handling_standards>
**Error Handling Philosophy:**

Utilities MUST **fail clearly with actionable remediation**, not silently or vaguely.

**Error Handling Pattern:**

```
Detection → Identification → Remediation → Blocking
```

1. **Detection:** Recognize failure condition
2. **Identification:** Clearly state what failed and why
3. **Remediation:** Provide specific actions to resolve
4. **Blocking:** Prevent downstream progression

**Standard Error Report Format:**

```markdown
❌ [UTILITY] FAILURE
══════════════════════════════════════════════════════════════════════
Date: [YYYY-MM-DD HH:MM]
Utility: [utility-name]
Procedure: [procedure-name]
Failure Type: [validation-failure / missing-input / invalid-state]

FAILURE DESCRIPTION:
──────────────────────────────────────────────────────────────────────
[Clear explanation of what failed]
[Specific conditions that caused failure]
[Impact of failure on workflow/orchestration]

FAILED CONDITIONS:
──────────────────────────────────────────────────────────────────────
1. [Specific condition not met]
   Expected: [what was expected]
   Actual: [what was found]
   
2. [Another condition not met]
   Expected: [what was expected]
   Actual: [what was found]

REMEDIATION PLAN:
──────────────────────────────────────────────────────────────────────
1. [Specific action to resolve condition 1]
   Effort: [estimated time/complexity]
   Owner: [who should execute]
   
2. [Specific action to resolve condition 2]
   Effort: [estimated time/complexity]
   Owner: [who should execute]

ESTIMATED TIME TO RESOLVE: [total effort estimate]

BLOCKING STATEMENT:
──────────────────────────────────────────────────────────────────────
[Phase/workflow] SHALL NOT proceed until:
✓ [Condition 1 resolved]
✓ [Condition 2 resolved]
✓ [Utility re-executed with PASS result]

NEXT STEPS:
──────────────────────────────────────────────────────────────────────
1. Execute remediation plan
2. Re-run utility procedure
3. Verify PASS result
4. Resume workflow/orchestration
```

**Error Categories:**

1. **Validation Failures:**
   - Expected conditions not met
   - Quality gates fail
   - Completeness checks fail
   - Pattern: Provide specific unmet conditions

2. **Missing Inputs:**
   - Required inputs not provided by invoking command
   - Referenced files/paths not found
   - Pattern: List missing inputs with examples

3. **Invalid State:**
   - State files corrupted or inconsistent
   - Prerequisites not met
   - Pattern: Describe expected vs. actual state

4. **Constraint Violations:**
   - Standards not followed
   - Policies violated
   - Pattern: Reference violated constraint with correction

**Remediation Quality Standards:**

Remediation guidance MUST be:

1. **Specific:** Not "fix the problem" but "complete section X with Y information"
2. **Actionable:** Clear steps someone can execute
3. **Estimated:** Include time/effort estimates
4. **Owned:** Identify who should execute (even if "Project Team")
5. **Verifiable:** How to know remediation succeeded

**Anti-Patterns:**

❌ "Something went wrong" - Not specific enough
❌ "Try again" - No remediation guidance
❌ "Contact administrator" - No self-service path
❌ "This usually works" - Not helpful
❌ Silent failure - Must report explicitly

**Graceful Degradation:**

When partial success possible:
- Report partial success clearly
- Identify what succeeded vs. failed
- Allow continuation with warnings if appropriate
- Document risks of proceeding with partial success

**Example:**

```markdown
⚠ PARTIAL SUCCESS
Quality Gate Validation: 4 of 5 criteria met (80%)

PASSED CRITERIA:
✓ Requirements documented
✓ Constraints identified
✓ Stakeholders engaged
✓ Reference materials provided

FAILED CRITERIA:
✗ Dependencies mapped - Dependency analysis document missing

RISK ASSESSMENT:
Proceeding without dependency mapping:
- High risk: Downstream integration issues
- Medium risk: Missed prerequisites
- Low risk: Timeline impact

RECOMMENDATION: Block progression until dependencies mapped
OVERRIDE OPTION: Stakeholder approval required for progression
```
</error_handling_standards>

<infrastructure_awareness>
**Infrastructure Philosophy Context:**

HX-Infrastructure operates under specific deployment philosophies:
1. **Bare metal first** - Ubuntu 24 bare metal for production
2. **Docker dev-only** - Containers for development, not production
3. **Manual installation** - No deployment automation currently
4. **Ansible Vault only** - Secrets management, not deployment automation
5. **No local users** - Samba AD for user auth, local service accounts only

**Utility Infrastructure Awareness Matrix:**

| Utility | Infrastructure Awareness | Rationale |
|---------|-------------------------|-----------|
| Quality Gate | Agnostic | Domain-independent validation |
| Context Prep | Aware (William's context) | Infrastructure context for William |
| RAIDD Log | Agnostic | Project management tracking |
| Artifact Tracker | Agnostic | Generic artifact management |
| Status Report | Agnostic | High-level reporting |
| Doc Lint | Agnostic | Documentation standards only |
| Handoff Generation | Aware | Preserves infrastructure context |

**When Utilities ARE Infrastructure-Aware:**

1. **Context Preparation (William's Template):**
   - Includes operational constraints section
   - Documents bare metal requirements
   - Notes manual installation procedures
   - Specifies Ansible Vault for secrets only
   - Reminds: no Docker in production

2. **Handoff Generation:**
   - Preserves infrastructure deployment notes
   - Carries forward operational constraints
   - Documents environment-specific details
   - Ensures session continuity on infrastructure context

**When Utilities ARE NOT Infrastructure-Aware:**

Most utilities focus on process, quality, or documentation:
- Quality validation is domain-agnostic
- RAIDD tracking applies to all project types
- Artifact tracking doesn't care about deployment
- Status reporting is high-level
- Documentation linting checks format/structure only

**Infrastructure Context Sections:**

For infrastructure-aware utilities, include:

```xml
<infrastructure_context>
**HX-Infrastructure Deployment Philosophy:**

This utility operates within HX-Infrastructure's deployment constraints:
- Bare metal Ubuntu 24 for production services
- Docker containers for development environment only
- Manual installation procedures (no automation)
- Ansible Vault for secrets management only
- Samba AD for user authentication (no local users)

**How This Utility Addresses Infrastructure:**

[Specific infrastructure considerations for this utility]

**Infrastructure-Related Outputs:**

[What infrastructure context this utility preserves/generates]
</infrastructure_context>
```

**Example from Context Prep Utility (William's Template):**

```markdown
OPERATIONAL CONSTRAINTS:
──────────────────────────────────────────────────────────────────────
Installation: [Manual installation procedures required (no automation)]
Environment: [Bare metal deployment (no Docker in production)]
Secrets Management: [Ansible Vault for secrets only (no deployment automation)]
Resources: [Hardware, network, storage limitations]
```

**Default Assumption:**

Unless utility explicitly infrastructure-aware:
- Assume infrastructure-agnostic operation
- No infrastructure-specific constraints in procedures
- No references to deployment methods
- Works same way regardless of infrastructure approach
</infrastructure_awareness>

<template_structure_requirements>
**Standard Utility Template Structure:**

All utilities MUST follow this structure:

```xml
---
workflow: [utility-identifier]
version: [semantic-version]
date: [YYYY-MM-DD]
status: APPROVED
type: utility-command
description: [one-line description]
applies_to: [comma-separated contexts]
author: HX-Infrastructure Team
---

<metadata>
[Standard metadata section]
</metadata>

<objective>
[Purpose, capabilities, when to use]
</objective>

<utility_overview>
[Core function, process overview, key principles]
</utility_overview>

<templates>
[If utility provides templates - otherwise omit]
</templates>

<procedures>
[Step-by-step procedures - REQUIRED]
</procedures>

<standards>
[Quality standards, validation rules - if applicable]
</standards>

<integration_convention>
[How to invoke this utility - REQUIRED]
</integration_convention>

<usage_examples>
[Concrete examples - REQUIRED]
</usage_examples>

<critical_reminders>
[Key warnings and principles - REQUIRED]
</critical_reminders>

<validation_checklist>
[Pre/during/post execution checklists - if applicable]
</validation_checklist>

<related_documents>
[Cross-references to workflows, orchestrations, standards]
</related_documents>

<metadata_footer>
[Version, status, compliance, next steps]
</metadata_footer>
```

**Section Requirements:**

**REQUIRED Sections (All Utilities):**
- metadata
- objective  
- utility_overview
- procedures (at least one)
- integration_convention (NEW - per these standards)
- usage_examples (minimum 2)
- critical_reminders (minimum 5)
- related_documents
- metadata_footer

**CONDITIONAL Sections:**
- templates (if utility provides templates)
- standards (if utility enforces quality/validation standards)
- validation_checklist (if utility has verification steps)
- infrastructure_context (if infrastructure-aware)

**Section Content Standards:**

1. **Procedures:**
   - Minimum 1, maximum 5 procedures per utility
   - Each procedure: Purpose, Inputs, Steps, Outputs
   - Steps numbered, clear, actionable
   - Include example outputs

2. **Templates:**
   - Complete, not skeletal
   - Include all required sections
   - Use placeholder format: [DESCRIPTION]
   - Provide usage instructions

3. **Examples:**
   - Minimum 2 concrete examples
   - Show different scenarios
   - Include expected inputs and outputs
   - Demonstrate common use cases

4. **Critical Reminders:**
   - Minimum 5 reminders
   - Start with ⚠️ emoji
   - Each reminder: one key principle/warning
   - Bold important terms

**XML Structure Requirements:**

- Semantic XML tags throughout
- Consistent tag naming (lowercase, hyphens)
- Proper nesting and closure
- No orphaned tags
- Self-documenting tag names
</template_structure_requirements>

<consistency_requirements>
**Cross-Utility Consistency:**

All utilities in Set 3 MUST maintain consistency:

**1. Terminology Consistency:**
- Use same terms for same concepts across utilities
- Example: "quality gate" not "validation checkpoint"
- Example: "orchestration" not "coordination" (unless specific context)
- Maintain terminology glossary

**2. Format Consistency:**
- Same header styles (= bars, - bars)
- Same status indicators (✓, ❌, ⚠)
- Same date formats (YYYY-MM-DD HH:MM)
- Same path notation (/path/to/file)

**3. Procedure Consistency:**
- All procedures follow: Purpose → Inputs → Steps → Outputs
- Step numbering: 1, 2, 3 (not bullets)
- Sub-steps: a, b, c or indented bullets
- Output examples in code blocks

**4. Naming Consistency:**
- Utility file naming: cc-util-[function].md
- State file naming: [utility-prefix]-[type]-[project]-[date].md
- Section tag naming: lowercase with hyphens
- Variable naming: [UPPERCASE_DESCRIPTION]

**5. Integration Consistency:**
- All utilities invoked same way: "Use cc-util-X with procedure 'Y'"
- All utilities produce outputs in standard format
- All utilities follow same error handling pattern
- All utilities document state in same locations

**6. Documentation Consistency:**
- Same metadata structure
- Same footer structure  
- Same critical reminders format
- Same example structure

**Consistency Validation Checklist:**
- [ ] Terminology matches other utilities
- [ ] Format matches standard template
- [ ] Procedure structure consistent
- [ ] Naming conventions followed
- [ ] Integration pattern standard
- [ ] Error handling pattern standard
- [ ] State management pattern standard
- [ ] Documentation structure complete
</consistency_requirements>

<development_workflow>
**Utility Development Process:**

**Phase 1: Design**
1. Define utility purpose and scope
2. Identify procedures needed
3. Design state management approach
4. Map integration points with workflows/orchestrations
5. Review against these standards

**Phase 2: Implementation**
1. Create utility file from standard template
2. Write procedures with examples
3. Define integration convention
4. Document error handling
5. Create usage examples
6. Write critical reminders

**Phase 3: Validation**
1. Verify all REQUIRED sections present
2. Check consistency with existing utilities
3. Validate integration convention clarity
4. Test error handling completeness
5. Verify state management approach
6. Confirm infrastructure awareness appropriate

**Phase 4: Integration**
1. Update workflow/orchestration commands with utility references
2. Create state file location structure
3. Document cross-references
4. Add to utility index/catalog
5. Update related documents

**Phase 5: Approval**
1. Standards compliance review
2. Peer review (if applicable)
3. Mark status: APPROVED
4. Deploy to command system
5. Document in handoff materials

**Quality Gates:**
- Design review: Purpose clear, procedures well-defined
- Implementation review: All required sections present
- Validation review: Consistent with standards
- Integration review: Properly referenced by workflows
- Approval review: Ready for production use
</development_workflow>

<anti_patterns>
**Common Anti-Patterns to Avoid:**

**1. Vague Procedures:**
❌ "Check if everything is ready"
✓ "Validate completeness by checking: [specific items with criteria]"

**2. Missing Integration Convention:**
❌ Utility documented but no guidance on how to invoke
✓ Clear integration_convention section with examples

**3. Unstructured Outputs:**
❌ Free-form text output
✓ Structured markdown with consistent sections

**4. Stateful Utilities:**
❌ Utility file contains project-specific data
✓ Utility file stateless, project data in artifacts

**5. Vague Error Messages:**
❌ "Validation failed"
✓ "Validation failed: 3 of 5 criteria unmet: [list specifics]"

**6. Infrastructure Assumptions:**
❌ Assumes Docker deployment
✓ Infrastructure-agnostic unless explicitly infrastructure-aware

**7. Inconsistent Terminology:**
❌ Using different terms for same concept across utilities
✓ Consistent terminology maintained

**8. Missing Examples:**
❌ Procedures without examples
✓ Every procedure has at least one concrete example

**9. Unclear State Management:**
❌ Unclear where state files stored
✓ Explicit state location conventions documented

**10. No Error Remediation:**
❌ "Failed" with no guidance
✓ "Failed with remediation: [specific actions]"
</anti_patterns>

<standards_compliance_checklist>
**Pre-Approval Compliance Checklist:**

**Structure Compliance:**
- [ ] All REQUIRED sections present
- [ ] Semantic XML structure throughout
- [ ] Standard template followed
- [ ] Section ordering consistent
- [ ] Metadata complete

**Integration Compliance:**
- [ ] integration_convention section present
- [ ] Invocation pattern documented
- [ ] Input requirements specified
- [ ] Output format described
- [ ] Integration examples provided

**Output Compliance:**
- [ ] Dual-purpose format (human + parseable)
- [ ] Standard output structure used
- [ ] File naming convention followed
- [ ] State location convention specified

**State Management Compliance:**
- [ ] Utility stateless (no project data in file)
- [ ] State artifacts documented
- [ ] State locations specified
- [ ] State persistence rules defined

**Error Handling Compliance:**
- [ ] Clear failure identification
- [ ] Specific remediation guidance
- [ ] Effort estimates included
- [ ] Blocking statements clear

**Infrastructure Compliance:**
- [ ] Infrastructure awareness appropriate
- [ ] Infrastructure constraints documented (if aware)
- [ ] Default agnostic assumption (if not aware)

**Consistency Compliance:**
- [ ] Terminology matches other utilities
- [ ] Formatting consistent with Set 3
- [ ] Naming conventions followed
- [ ] Integration pattern standard

**Documentation Compliance:**
- [ ] Minimum 2 usage examples
- [ ] Minimum 5 critical reminders
- [ ] Related documents referenced
- [ ] Metadata footer complete

**Quality Compliance:**
- [ ] Procedures clear and actionable
- [ ] Examples concrete and complete
- [ ] No anti-patterns present
- [ ] Appropriate detail level (not too brief, not excessive)
</standards_compliance_checklist>

<standards_version_control>
**Standards Evolution:**

These standards are version controlled:
- Current Version: 1.1
- Date Established: 2025-11-21
- Review Cycle: After each Set completion
- Update Process: Documented changes with rationale

**When Standards Change:**
- New version published with changelog
- Existing utilities evaluated against new standards
- Migration plan created if updates needed
- Legacy compliance documented

**Change Log:**

```
VERSION 1.0 (2025-11-20)
- Initial standards established
- Covers Set 3 utility development
- Based on lessons from Set 1 & 2 development
- Incorporates architectural questions and answers
```

**Future Considerations:**
- Programmatic API patterns (if automation added)
- Multi-agent concurrent execution (if needed)
- Binary artifact handling (if required)
- Real-time validation (if tools developed)
</standards_version_control>

## Infrastructure Philosophy Integration

Utility development aligns with HX-Infrastructure philosophy:

### Infrastructure-Agnostic Utilities (Default)

**Most utilities are infrastructure-agnostic:**
- Quality gates validate criteria independent of deployment method
- Project context utilities track project information, not infrastructure details
- RAIDD tracking utilities focus on requirements, not deployment
- Artifact registry utilities manage metadata, not infrastructure specifics

**Why Infrastructure-Agnostic:**
- Utilities are reusable across deployment environments (dev, staging, production)
- Infrastructure philosophy (bare metal, systemd, manual procedures) is documented in service specs, not utility commands
- Utilities guide agent behavior, not infrastructure implementation

### Infrastructure-Aware Utilities (Explicit)

**Some utilities MUST be infrastructure-aware:**
- Deployment validation utilities checking systemd service status
- Configuration validation utilities verifying manual procedure execution
- Vault utilities validating Ansible Vault encryption (no Ansible playbooks)
- Node utilities checking bare metal deployment patterns

**When to Make Utilities Infrastructure-Aware:**
- Utility validates infrastructure philosophy compliance
- Utility checks deployment-specific requirements
- Utility interfaces with infrastructure-specific tools (systemd, Ansible Vault)

**Infrastructure Awareness Pattern:**
```xml
<infrastructure_awareness>
**Infrastructure Philosophy Compliance:**

This utility validates HX-Infrastructure deployment philosophy:
- ✅ Bare metal deployment (Ubuntu 24.04 LTS for production/staging)
- ✅ Systemd service management (all services)
- ✅ Manual procedures (no Ansible playbooks)
- ✅ Ansible Vault only (all credentials)

**Validation Checks:**
- Verify systemd unit file present and valid
- Verify manual procedure documentation complete
- Verify Ansible Vault encryption (no playbook references)
- Verify bare metal deployment architecture documented
</infrastructure_awareness>
```

### Procedure Alignment

Utility command development aligns with HX-Infrastructure procedures:

**Utility Usage Across Lifecycle Phases:**

**Phase 1 (Charter Creation):**
- Quality gate utilities validate charter approval
- Project context utilities initialize project metadata

**Phase 2 (Specification Development):**
- Quality gate utilities validate spec draft and context
- Context utilities track specification evolution
- RAIDD utilities log requirements and assumptions

**Phase 3 (Task Breakdown & Testing):**
- Quality gate utilities validate task completeness
- Test plan validation utilities check test coverage
- Artifact registry utilities track task artifacts

**Phase 4 (Task Execution):**
- Deployment validation utilities check infrastructure philosophy compliance
- Test execution utilities track test results
- Quality gate utilities validate execution milestones

**Phase 5 (Project Closeout):**
- Quality gate utilities validate operational readiness
- Project context utilities finalize project metadata
- Archive utilities prepare project artifacts for long-term storage

---

<related_documents>

### Standards
- **`/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`** - Infrastructure philosophy AUTHORITATIVE source
- **`/home/agent0/HX-Infrastructure/standards/documentation-requirements.md`** - Documentation standards for utilities
- **`/home/agent0/HX-Infrastructure/standards/architecture-standards.md`** - Architecture patterns for utilities
- **`/home/agent0/HX-Infrastructure/standards/naming-conventions.md`** - Utility command naming conventions

### Procedures (Lifecycle Integration)
- **`/home/agent0/HX-Infrastructure/procedures/node-deployment-workflow.md`** - Phase 0: Utility usage in project initiation
- **`/home/agent0/HX-Infrastructure/procedures/charter-workflow.md`** - Phase 1: Quality gate and context utilities
- **`/home/agent0/HX-Infrastructure/procedures/spec-workflow.md`** - Phase 2: Specification validation utilities
- **`/home/agent0/HX-Infrastructure/procedures/task-workflow.md`** - Phase 3: Task and test validation utilities
- **`/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md`** - Phase 4: Deployment validation utilities
- **`/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md`** - Phase 5: Closeout and archive utilities

### Command Files
- **`/home/agent0/HX-Infrastructure/.claude/commands/utilities/`** - All utility commands (Set 3)
- **`/home/agent0/HX-Infrastructure/.claude/commands/workflows/`** - Set 1 workflow commands (invoke utilities)
- **`/home/agent0/HX-Infrastructure/.claude/commands/agents/`** - Set 2 orchestration commands (invoke utilities)

### Governance Documents
- **`/home/agent0/HX-Infrastructure/constitution.md`** - Project governance and utility compliance principles

### Agent Profiles
- **Agent Zero (CC):** STATEFUL orchestrator developing and using utility commands across all phases

</related_documents>

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-20 | Initial utility development standards with comprehensive patterns for Set 3 | 1057 lines | HX-Infrastructure Team |
| 1.1 | 2025-11-21 | Added comprehensive metadata, infrastructure philosophy integration (infrastructure-agnostic default, infrastructure-aware explicit), procedure alignment, expanded related documents, version history, document maintenance | +120 lines (est.) | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added comprehensive document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose section with target audience and scope
- Added Infrastructure Philosophy Integration section (infrastructure-agnostic default vs infrastructure-aware explicit)
- Added Infrastructure Awareness Pattern for utilities requiring infrastructure validation
- Added Procedure Alignment section (utility usage across all 5 phases)
- Expanded related documents section with comprehensive standards, procedures, commands, governance, agents
- Added version history table (this table)
- Added document maintenance section
- Maintained 100% backward compatibility with v1.0

**Backward Compatibility:** 100% - All v1.0 utility development requirements unchanged, only infrastructure philosophy explicit documentation and metadata enhancements added

---

## Document Maintenance

### Update Triggers
This document should be updated when:
- New utility command patterns emerge across multiple utilities
- Integration patterns change (workflow-utility invocation)
- Output format standards evolve
- State management architecture changes
- Error handling patterns improve
- Infrastructure philosophy utility requirements change
- New utility Sets developed (Set 4, Set 5, etc.)

### Review Frequency
- **After Each Set Completion:** Review standards effectiveness after completing Set 3, Set 4, etc.
- **Quarterly Review:** Agent Zero reviews utility consistency and compliance
- **Post-Project Review:** After major projects, review utility effectiveness
- **Annual Review:** Comprehensive review of all utility development standards

### Compliance Enforcement
- **Utility Development:** Agent Zero validates new utilities against standards before deployment
- **Integration Review:** Workflow commands reviewed for proper utility invocation patterns
- **Consistency Audit:** Quarterly audit of all utilities for standards compliance
- **Blocking Issue:** Non-compliant utilities REJECTED during review

### Change Control
- Changes to utility structure require template updates
- Changes to integration patterns require workflow command updates
- Changes to output formats require parser/consumer updates
- All changes maintain 100% backward compatibility or include migration procedures for existing utilities
- Version increments: Minor for enhancements, Major for breaking changes (requires justification)

---

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Mandatory for All Utility Development
**Date:** 2025-11-21
**Last Updated:** 2025-11-21 (Comprehensive metadata, infrastructure integration, procedure alignment, version history)
**Compliance:** All Set 3 utilities MUST comply with these standards
**Next Steps:** Apply these standards to remaining utility development, update completed utilities with integration_convention sections
**Review Cycle:** After Set 3 completion, evaluate standards effectiveness
</metadata_footer>