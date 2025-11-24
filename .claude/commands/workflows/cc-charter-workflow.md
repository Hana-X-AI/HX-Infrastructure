---
document: cc-charter-workflow
version: 1.3
date: 2025-11-24
status: APPROVED
type: workflow-command
description: Charter creation workflow for any node deployment in HX-Infrastructure
applies_to: all_node_deployments
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Charter Creation
**Version:** 1.3 (with CAIO refinements)
**Date:** 2025-11-24
**Status:** APPROVED - Ready for immediate use
**Type:** Workflow Command
</metadata>

<objective>
**Purpose:** Guide Claude Code through systematic charter creation for any node deployment in the HX-Infrastructure ecosystem.

**What This Achieves:**
- Transforms unstructured CAIO input into comprehensive, approved project charter
- Ensures knowledge-first approach through repository research and validation
- Establishes clear scope, success criteria, and quality gates before specification
- Produces validated charter document ready for specification phase

**Key Innovation:** Two-round question pattern (pre-research and post-research) ensures informed technical decisions.
</objective>

<workflow_overview>
**High-Level Flow:**

```
CAIO Input (Natural Language)
  → CC Parses & Identifies Repositories
  → Repository Confirmation Gate ✓
  → Initial Clarifying Questions
  → Knowledge Vault Deep Dive (30-45 min/repo)
  → Post-Research Questions (NEW in v1.2)
  → Charter Generation
  → Review & Refinement Loop
  → Charter Approval ✓
  → Post-Approval Actions (RAIDD, Backlog, Agents)
  → Ready for Specification Phase
```

**Duration:** 2-4 hours (depends on research depth)
**Participants:** CAIO (Chief AI Officer), CC (Claude Code - Agent Zero)
**Output:** Approved charter.md in `/nodes/[node-name]/` directory
</workflow_overview>

<phases>

<phase id="0" name="Natural Input from CAIO" gate="none">
<description>
CAIO provides unstructured brain dump containing project vision, requirements, and context. This is intentionally informal to allow natural expression of ideas.
</description>

<inputs>
CAIO provides unstructured natural language containing:
- Vision & purpose
- Business/development value
- Technical requirements
- Integration points
- Future considerations
- Questions/uncertainties
</inputs>

<cc_actions>
- Receive and acknowledge input
- Prepare for parsing in Phase 1
- No action required yet - just listening
</cc_actions>

<outputs>
- Raw natural language input captured
- Ready for structured parsing
</outputs>

<duration>5-15 minutes</duration>
</phase>

<phase id="1" name="CC Acknowledges & Parses" gate="none">
<description>
Claude Code processes the natural language input and structures it into preliminary charter sections, identifies knowledge vault repositories needed, and prepares initial clarifying questions.
</description>

<cc_actions>
**Parse Input Into:**
- Vision/Purpose
- Business Value
- Technical Requirements
- Integration Points
- In Scope (explicit)
- Out of Scope (inferred)
- Questions/Gaps (areas needing clarification)

**Identify Repositories:**
- Primary repo (core functionality)
- Integration repos (systems to connect with)
- Supporting repos (dependencies)
- Architecture repos (standards, patterns)

**Prepare Questions:**
- Draft 5-8 clarifying questions
- Focus on scope, priorities, success criteria
- Save for Phase 3
</cc_actions>

<outputs>
- Parsed understanding of requirements
- Preliminary charter section drafts
- Repository list (for confirmation in Phase 2)
- Question list (for Phase 3)
</outputs>

<duration>5-10 minutes</duration>
</phase>

<phase id="2" name="Repository Identification & Confirmation" gate="repository_list_approved">
<description>
CC presents identified repositories to CAIO for confirmation. This gate ensures no critical repositories are missed before investing time in research.
</description>

<cc_actions>
**Present Repository List:**

"Based on your input, I've identified these repositories for deep dive research:

**PRIMARY:**
• [primary-repo] - Core functionality

**INTEGRATIONS:**
• [integration-repo-1] - Integration purpose
• [integration-repo-2] - Integration purpose
• [integration-repo-3] - Integration purpose

**SUPPORTING:**
• [supporting-repo-1] - Future reference
• [others as identified]

Have I missed any crucial repositories?"
</cc_actions>

<caio_actions>
- Review proposed repository list
- Add any missing repositories
- Confirm list is complete
- Approve for research
</caio_actions>

<quality_gate>
**Gate:** Repository List Approved

**Criteria:**
- All needed repos identified
- CAIO confirmed list completeness
- No critical gaps remain

**Pass:** Proceed to Phase 3
**Fail:** Add missing repos, re-confirm
</quality_gate>

<outputs>
- Approved repository list
- Gate passed - ready for questions
</outputs>

<duration>5-10 minutes</duration>

<rationale>
Prevents wasted research time on wrong repositories. CAIO has domain knowledge about ecosystem dependencies that CC might miss from input alone.
</rationale>
</phase>

<phase id="3" name="Initial Clarifying Questions" gate="initial_questions_answered">
<description>
CC asks 5-8 focused questions to clarify scope, priorities, integration details, and success criteria before conducting research.
</description>

<cc_actions>
**Ask Focused Questions (5-8 questions):**

**SCOPE QUESTIONS:**
- Q1: [Specific scope boundary question]
- Q2: [Feature priority question]

**INTEGRATION QUESTIONS:**
- Q3: [Integration sequencing]
- Q4: [Component boundaries]

**SUCCESS QUESTIONS:**
- Q5: [Acceptance criteria]
- Q6: [Testing requirements]

**TIMELINE QUESTIONS:**
- Q7: [Deadline/urgency]
- Q8: [Phasing approach]
</cc_actions>

<caio_actions>
- Answer each question clearly
- Provide additional context if needed
- Clarify priorities and constraints
</caio_actions>

<quality_gate>
**Gate:** Initial Questions Answered

**Criteria:**
- Scope boundaries clear
- Priorities defined
- Success criteria understood
- Timeline expectations set

**Pass:** Proceed to Phase 4 (Research)
**Fail:** Ask follow-up questions, clarify ambiguities
</quality_gate>

<outputs>
- Clarified scope, priorities, success criteria
- Timeline expectations documented
- Ready for knowledge vault research
</outputs>

<duration>10-15 minutes</duration>
</phase>

<phase id="4" name="Knowledge Vault Deep Dive" gate="research_complete">
<description>
CC conducts comprehensive research on approved repositories to understand technical capabilities, constraints, integration patterns, and dependencies.
</description>

<cc_actions>
**For Each Repository:**
1. Read comprehensive documentation
2. Understand architecture & patterns
3. Identify technical requirements
4. Note dependencies & constraints
5. Flag integration points
6. Document risks/assumptions

**Create Research Output Document:**
- Technical capabilities confirmed
- Installation requirements
- Configuration options
- Integration patterns
- Constraints & limitations
- Dependencies identified
- New questions/clarifications needed
</cc_actions>

<reference_template>
Use `/home/agent0/HX-Infrastructure/templates/research-findings-template.md` to document findings with confidence levels (High/Medium/Low).
</reference_template>

<quality_gate>
**Gate:** Research Complete

**Criteria:**
- All approved repos researched
- Technical understanding solid (Medium+ confidence)
- Constraints identified
- Integration patterns understood
- New questions documented

**Pass:** Proceed to Phase 4.5 (Post-Research Questions)
**Fail:** Continue research, clarify gaps
</quality_gate>

<outputs>
- Comprehensive research findings document
- Technical understanding with confidence levels
- List of post-research questions
- Updated risks/assumptions/dependencies
</outputs>

<duration>30-45 minutes per major repository</duration>
</phase>

<phase id="4.5" name="Post-Research Clarifying Questions" gate="post_research_questions_answered" new="true">
<description>
CC asks second round of questions based on research findings. These are technical decisions and options discovered during repository research.
</description>

<cc_actions>
**Review Research Findings:**
- Identify gaps in understanding
- Discover new questions from research
- Find conflicts/ambiguities
- Identify CAIO decisions needed on options

**Present Research-Based Questions:**

"Based on my research, I have additional questions:

**TECHNICAL QUESTIONS (from repo dive):**
- Q1: [Specific technical choice needed]
- Q2: [Configuration decision required]

**INTEGRATION QUESTIONS (from cross-repo analysis):**
- Q3: [Integration approach options]
- Q4: [Sequencing dependencies]

**SCOPE REFINEMENT:**
- Q5: [Feature discovered - include?]
- Q6: [Limitation discovered - acceptable?]"
</cc_actions>

<caio_actions>
- Review technical options presented
- Make decisions on configuration/approach
- Confirm scope adjustments if needed
- Approve proceeding to charter generation
</caio_actions>

<quality_gate>
**Gate:** Post-Research Questions Answered

**Criteria:**
- Technical decisions made
- Configuration options selected
- Scope refinements confirmed
- All research gaps filled

**Pass:** Proceed to Phase 5 (Charter Generation)
**Fail:** Conduct additional research if major gaps remain
</quality_gate>

<outputs>
- Technical decisions documented
- Configuration approach confirmed
- Final scope boundaries set
- Ready for charter generation
</outputs>

<duration>10-20 minutes</duration>

<rationale>
Research reveals options and constraints not visible from initial input. CAIO needs to make informed technical decisions before charter is drafted.
</rationale>

<improvement_highlight>
**NEW in v1.2:** This phase was added based on real-world experience. Single question round insufficient when research reveals technical options.
</improvement_highlight>
</phase>

<phase id="5" name="Charter Generation" gate="none">
<description>
CC generates structured charter document using template, populating all sections from CAIO input, clarifying answers, and research findings.
</description>

<cc_actions>
**Generate Charter Using Template:**

Uses `/home/agent0/HX-Infrastructure/templates/charter-template.md` structure:
- Vision & Purpose (from CAIO input)
- Business/Technical Justification (from CAIO)
- Scope - In Scope (from CAIO + research)
- Scope - Out of Scope (from CAIO + research)
- Success Criteria (from CAIO answers)
- Technical Requirements (from research)
- Dependencies (from research)
- Risks & Assumptions (from research)
- Timeline (from CAIO)
- Stakeholders & Roles (from context)

**Pre-fill Charter:**
- Project name, date, type
- All sections populated from research
- `[NEEDS CAIO REVIEW]` tags where input needed
- References to repos researched
</cc_actions>

<outputs>
- `/nodes/[node-name]/charter.md` (DRAFT status)
- All sections populated
- Ready for CAIO review
</outputs>

<duration>15-20 minutes</duration>
</phase>

<phase id="6" name="Charter Review & Refinement" gate="none">
<description>
Iterative review loop where CAIO reviews draft charter and provides feedback until satisfied with content.
</description>

<cc_actions>
**Present Draft Charter:**

"I've generated the charter draft based on your input and my research. Key sections:

**VISION:** [Summary]
**SCOPE:** [In/Out summary]
**SUCCESS CRITERIA:** [Key criteria]
**DEPENDENCIES:** [Critical deps]
**RISKS:** [Top 3-5 risks]

Please review at: `/nodes/[node-name]/charter.md`

What would you like to refine?"

**Process Feedback:**
- Make requested refinements
- Update affected sections
- Maintain consistency across charter
- Re-present for review
</cc_actions>

<caio_actions>
- Review charter thoroughly
- Provide specific feedback on sections
- Request clarifications or additions
- Iterate until satisfied
</caio_actions>

<iteration_pattern>
**Loop Until Satisfied:**
1. CAIO reviews → provides feedback
2. CC refines → updates charter
3. CC re-presents → highlights changes
4. Repeat until CAIO approves

**Typical Iterations:** 1-3 rounds
</iteration_pattern>

<outputs>
- Refined charter (still DRAFT status)
- All CAIO feedback incorporated
- Ready for formal approval
</outputs>

<duration>15-30 minutes (depends on iterations)</duration>
</phase>

<phase id="7" name="Charter Approval" gate="charter_approved">
<description>
CAIO formally approves charter. CC updates status and locks document for specification phase.
</description>

<caio_actions>
**Formal Approval:**
"Charter approved"
</caio_actions>

<cc_actions>
**Update Charter Status:**
- Status: `Draft` → `Approved`
- Add approval date
- Add approval signature
- Lock charter sections (no further edits without formal change process)
</cc_actions>

<quality_gate>
**Gate:** Charter Approved

**Criteria:**
- All sections complete and accurate
- CAIO formally approved
- Status updated to Approved
- Document locked

**Pass:** Proceed to Phase 8 (Post-Approval Actions)
**Fail:** Return to Phase 6 for additional refinement
</quality_gate>

<outputs>
- `/nodes/[node-name]/charter.md` (APPROVED status)
- Locked charter document
- Approval timestamp and signature
- Ready for post-approval actions
</outputs>

<duration>2-5 minutes</duration>
</phase>

<phase id="8" name="Post-Approval Actions" gate="none">
<description>
CC executes standardized post-charter actions to update centralized artifacts and prepare for specification phase.
</description>

<cc_actions>

<action id="1" name="Review and Update RAIDD Log">
**Extract from Charter:**
- Top 3-5 risks from charter
- Top 3-5 assumptions from charter
- All dependencies from charter

**Add to Centralized Log:**
- Create detailed entries in `/home/agent0/HX-Infrastructure/docs/raidd-log.md`
- Reference charter sections
- Tag with project name
- Set initial priority levels
</action>

<action id="2" name="Review and Update Backlog">
**Extract from Charter:**
- All out-of-scope items

**Add to Centralized Backlog:**
- Create entries in `/home/agent0/HX-Infrastructure/docs/backlog.md`
- Reference charter for context
- Categorize as deferred work
- Prioritize against other backlog items
</action>

<action id="3" name="Preview Agent Assignments">
**Based on Technical Requirements:**
- Reference `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md`
- Suggest agent assignments for roles
- Present to CAIO for confirmation
- Document in charter or separate assignment doc
</action>

<action id="4" name="Check Dependencies">
**Verify Prerequisites:**
- Check dependent services operational
- Verify infrastructure prerequisites exist
- Identify any blockers
- Add to RAIDD log if issues found
</action>

<action id="5" name="Generate Knowledge Review Checklist">
**Create Team Checklist:**
- List all repos from deep dive
- Assign review responsibilities to team members
- Create `/nodes/[node-name]/review-checklist.md`
- Ready for team kick-off meeting
</action>

</cc_actions>

<outputs>
- Updated `/home/agent0/HX-Infrastructure/docs/raidd-log.md`
- Updated `/home/agent0/HX-Infrastructure/docs/backlog.md`
- Agent assignments (draft, pending confirmation)
- Knowledge review checklist
- All prerequisites verified
- **Ready for Specification Phase**
</outputs>

<duration>20-30 minutes</duration>
</phase>

</phases>

<quality_gates>
<summary>
**Gate 0:** Repository List Confirmed
- All needed repos identified
- CAIO approved list

**Gate 1:** Initial Questions Answered
- Scope clear, priorities defined
- Success criteria understood

**Gate 2:** Research Complete
- All repos researched
- Technical understanding solid (Medium+ confidence)
- Constraints identified

**Gate 3:** Post-Research Questions Answered
- Technical decisions made
- Options selected, gaps filled

**Gate 4:** Charter Approved
- All sections complete
- CAIO satisfied
- Ready to proceed
</summary>

<validation_flow>
```
Each gate has pass/fail criteria
  ├─ PASS: Proceed to next phase
  └─ FAIL: Address gaps, retry gate

Gates are checkpoints, not barriers
Iterative refinement is expected
Quality over speed
```
</validation_flow>
</quality_gates>

<execution_method>
<approved_method>
**Sequential Execution:**

1. CC Parses CAIO input (Phase 1)
2. CC Identifies repos needed (Phase 1)
3. **✓ GATE:** CAIO confirms repo list (Phase 2)
4. CC Asks initial clarifying questions (Phase 3)
5. CAIO Answers (Phase 3)
6. **✓ GATE:** Questions answered
7. CC Deep dive on approved repos (Phase 4)
8. **✓ GATE:** Research complete
9. CC Asks post-research questions (Phase 4.5) **← NEW in v1.2**
10. CAIO Answers (Phase 4.5)
11. **✓ GATE:** Post-research questions answered
12. CC Generates charter draft (Phase 5)
13. CAIO Reviews (Phase 6)
14. CC Refines (Phase 6 - iterative)
15. **✓ GATE:** Charter Approved (Phase 7)
16. CC Executes post-approval actions (Phase 8)
17. **→ Ready for Specification Phase**
</approved_method>
</execution_method>

<key_improvements>
<improvement id="1" version="1.2">
**Repository Confirmation Gate (Phase 2)**

**Problem:** CC sometimes missed critical repositories, leading to incomplete research
**Solution:** Explicit confirmation gate with CAIO before research begins
**Impact:** Prevents wasted research time, ensures comprehensive knowledge gathering
**Example:** CAIO caught missing n8n-master repo that CC inferred wasn't needed
</improvement>

<improvement id="2" version="1.2">
**Post-Research Questions (Phase 4.5)**

**Problem:** Research reveals technical options and constraints not visible from initial input
**Solution:** Second question round after research, before charter generation
**Impact:** Better technical decisions, more accurate charters, fewer surprises in spec phase
**Example:** "Repo shows 3 deployment options (Docker, systemd, K8s) - which do you prefer?"
</improvement>

<improvement id="3" version="1.2">
**Two Question Rounds Pattern**

**Round 1 (Phase 3):** Based on CAIO input
- Clarify scope and intent
- Understand priorities
- Define success criteria

**Round 2 (Phase 4.5):** Based on research findings
- Technical decisions
- Configuration options
- Integration approaches

**Rationale:** Different information available at different times requires different questions
</improvement>
</key_improvements>

<guiding_principles>
<principle name="Knowledge-First">
Repository list confirmation ensures thorough research before charter finalization. Two question rounds ensure informed decisions at appropriate times.
</principle>

<principle name="Iterative Refinement">
Charter refinement is iterative. Questions can lead to more questions. Research can reveal scope changes. Flexibility is built into the workflow.
</principle>

<principle name="CAIO Control Points">
CAIO maintains control at critical decision points:
- Repository list approval (Phase 2)
- Question answers - Round 1 (Phase 3)
- Question answers - Round 2 (Phase 4.5)
- Charter review & approval (Phases 6-7)
- Agent assignment confirmation (Phase 8)
</principle>

<principle name="Quality Gates">
Gates ensure quality at each stage. Failing a gate means addressing gaps, not abandoning the workflow. Quality over speed.
</principle>
</guiding_principles>

<visual_diagrams>
<workflow_diagram>
```
┌─────────────────────────────────────┐
│ Phase 0: CAIO Brain Dump            │
│ (Natural Language Input)            │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 1: CC Parses & Identifies     │
│ (Structure + Repo List)             │
└─────────────┬───────────────────────┘
              ↓
      ┌───────────────┐
      │ GATE: Repo    │
      │ List Approved │ ← CAIO confirms
      └───────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 3: Initial Questions (5-8)    │
│ (Scope, Priorities, Success)        │
└─────────────┬───────────────────────┘
              ↓ CAIO answers
      ┌───────────────┐
      │ GATE: Initial │
      │ Q's Answered  │
      └───────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 4: Knowledge Vault Deep Dive  │
│ (30-45 min/repo, Research Findings) │
└─────────────┬───────────────────────┘
              ↓
      ┌───────────────┐
      │ GATE: Research│
      │ Complete      │
      └───────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 4.5: Post-Research Questions  │ ← NEW
│ (Technical Decisions)               │
└─────────────┬───────────────────────┘
              ↓ CAIO decides
      ┌───────────────┐
      │ GATE: Tech    │
      │ Decisions Made│
      └───────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 5: Charter Generation         │
│ (Draft charter.md)                  │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 6: Review & Refinement Loop   │
│ (Iterative until satisfied)         │
└─────────────┬───────────────────────┘
              ↓ CAIO approves
      ┌───────────────┐
      │ GATE: Charter │
      │ Approved      │
      └───────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 8: Post-Approval Actions      │
│ (RAIDD, Backlog, Agents, Checklist) │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ ✓ Ready for Specification Phase     │
└─────────────────────────────────────┘
```
</workflow_diagram>

<timeline_estimate>
```
Phase 0:   5-15 min   (CAIO input)
Phase 1:   5-10 min   (CC parsing)
Phase 2:   5-10 min   (Repo confirmation)
Phase 3:   10-15 min  (Initial Q&A)
Phase 4:   30-45 min  (Research per repo)
Phase 4.5: 10-20 min  (Post-research Q&A)
Phase 5:   15-20 min  (Charter generation)
Phase 6:   15-30 min  (Review iterations)
Phase 7:   2-5 min    (Approval)
Phase 8:   20-30 min  (Post-approval)
─────────────────────
TOTAL:     ~2-4 hours (depends on repo count and iterations)
```
</timeline_estimate>
</visual_diagrams>

<related_documents>
**Templates:**
- `/home/agent0/HX-Infrastructure/templates/charter-template.md` - Charter output template
- `/home/agent0/HX-Infrastructure/templates/research-findings-template.md` - Research documentation
- `/home/agent0/HX-Infrastructure/templates/charter-questions-template.md` - Question patterns

**Next Workflows:**
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Specification phase (follows charter)
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Task breakdown (follows spec)

**Standards:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance and principles
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Doc standards

**Reference:**
- `/home/agent0/HX-Infrastructure/.claude/semantic-xml-documentation-guide.md` - Structure guide
</related_documents>

<validation_checklist>
**Before Using This Workflow:**
- [ ] All phases have clear descriptions
- [ ] All quality gates have pass/fail criteria
- [ ] All template references use absolute paths
- [ ] All durations are realistic estimates
- [ ] All CAIO/CC actions are clear
- [ ] Outputs defined for each phase
- [ ] New features marked with `new="true"` attribute
- [ ] XML tags properly nested and closed
</validation_checklist>

<metadata_footer>
**Workflow Version:** 1.3 (with CAIO refinements)
**Status:** APPROVED for immediate use
**Last Updated:** 2025-11-24
**Converted to Semantic XML:** 2025-11-19
**Next Phase:** Specification workflow
</metadata_footer>
