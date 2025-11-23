---
workflow: specification-development
version: 1.3
date: 2025-11-16
status: APPROVED
type: workflow-command
description: Team-based specification development with multi-agent contributions for HX-Infrastructure nodes
applies_to: all_node_types
prerequisites:
  - approved_charter
  - team_assignments_complete
  - research_findings_documented
estimated_duration: 3-5 hours
output_artifact: node-spec.md
---

<metadata>
**Workflow:** Specification Development
**Version:** 1.3
**Date:** 2025-11-16
**Status:** APPROVED - Ready for immediate use
**Type:** Workflow Command
**Prerequisites:** Approved charter.md, team assignments complete, research findings documented
**Estimated Time:** 3-5 hours (includes all team contributions)
**Output:** Approved node-spec.md with comprehensive technical details, node status promoted to PLANNED
</metadata>

<objective>
**Purpose:** Execute team-based specification development with multi-agent contributions for comprehensive technical planning.

**What This Achieves:**
- Transforms approved charter into detailed technical specification through collaborative multi-agent process
- Ensures diverse expertise through role-specific agent contributions (infrastructure, security, integration, etc.)
- Validates technical feasibility and integration requirements before implementation
- Produces approved specification document ready for task execution phase
- Promotes node status from CHARTERED to PLANNED

**Key Innovation:** Stateless agent continuous process pattern - each specialist agent loads context, contributes immediately, and commits in ONE session. Agent Zero orchestrates synthesis and conflict resolution.

**Critical Success Factor:** This is NOT a sequential workflow where agents wait for each other. Each specialist contributes independently based on charter context, then Agent Zero synthesizes all contributions.
</objective>

<workflow_overview>
**High-Level Flow:**
```
Prerequisites Check → Agent Zero Draft → Team Evaluation →
Team Contributions (Parallel) → Synthesis & Conflict Resolution →
Clarifying Questions → CAIO Review → Post-Approval Updates
```

**Duration Breakdown:**
- Phase 0: 5-10 minutes (prerequisites validation)
- Phase 1: 45-60 minutes (initial draft creation)
- Phase 2: 10-15 minutes (team membership evaluation)
- Phase 3: 90-120 minutes (parallel team contributions)
- Phase 4: 30-45 minutes (synthesis and conflict resolution)
- Phase 5: 15-30 minutes (clarifying questions)
- Phase 6: 15-30 minutes (CAIO review)
- Phase 7: 10-15 minutes (post-approval updates)

**Total:** 3-5 hours (varies based on project complexity and team size)

**Key Participants:**
- **Agent Zero:** Workflow orchestrator, draft creator, synthesizer
- **CAIO:** Charter creator, requirement clarifier, final approver
- **Specialist Agents:** Domain experts (infrastructure, security, integration, etc.) providing targeted contributions
</workflow_overview>

<phases>
<phase id="0" name="Prerequisites Check" gate="prerequisites-met">
<description>
Validate all required inputs exist and charter is approved before beginning specification development. This gate prevents starting specification work with incomplete context.
</description>

<inputs>
**Required Documents:**
- `charter.md` (MUST have status: APPROVED)
- Research findings (if charter required research)
- Team assignments (list of specialist agents to involve)

**Required State:**
- Node status: CHARTERED
- Charter approval gate passed
- All charter questions resolved
</inputs>

<actions>
**Agent Zero performs:**

1. **Verify charter.md exists and is approved**
   ```bash
   grep "status: APPROVED" charter.md
   ```

2. **Check research completion** (if applicable)
   - Verify research findings documented in charter
   - Confirm technical feasibility validated

3. **Validate team assignments**
   - Review specialist agents listed in charter
   - Confirm each agent's role and contribution area

4. **Assess specification template requirements**
   - Determine if using standard `node-spec-template.md` or custom template
   - Verify template location: `/home/agent0/HX-Infrastructure/templates/`

**Pass Criteria:**
- Charter.md status = APPROVED
- All charter prerequisites completed
- Team assignments documented
- Specification template identified
</actions>

<outputs>
**Gate Decision:**
- ✅ **PASS:** All prerequisites met → Proceed to Phase 1
- ❌ **FAIL:** Missing prerequisites → Return to charter workflow to complete

**Status Update:**
- No node status change (remains CHARTERED)
- Specification workflow officially initiated
</outputs>

<duration>5-10 minutes</duration>
</phase>

<phase id="1" name="Agent Zero Creates Initial Specification Draft" gate="none">
<description>
Agent Zero creates comprehensive first draft of specification by transforming charter content into detailed technical sections. This draft serves as foundation for specialist agent contributions.
</description>

<inputs>
- Approved charter.md
- Specification template (standard or custom)
- Research findings from charter phase
- Agent Zero's synthesis of charter requirements
</inputs>

<actions>
**Agent Zero performs:**

1. **Copy specification template**
   ```bash
   cp /home/agent0/HX-Infrastructure/templates/node-spec-template.md node-spec.md
   ```

2. **Populate all template sections from charter:**
   - **Executive Summary** - Distill charter vision into technical overview
   - **Technical Requirements** - Expand charter requirements with implementation details
   - **Architecture Overview** - Detail system components and interactions
   - **Security Considerations** - Elaborate security requirements from charter
   - **Integration Points** - Specify APIs, protocols, data flows
   - **Deployment Strategy** - Define deployment process and environments
   - **Testing Strategy** - Outline testing approach and acceptance criteria
   - **Monitoring & Observability** - Specify metrics, logs, alerts
   - **Success Metrics** - Quantify charter success criteria
   - **Timeline & Milestones** - Create phased implementation schedule

3. **Flag sections needing specialist input**
   Use comment markers:
   ```markdown
   <!-- NEEDS: Infrastructure Agent - sizing and resource allocation -->
   <!-- NEEDS: Security Agent - authentication flow details -->
   <!-- NEEDS: Integration Agent - API contract definitions -->
   ```

4. **Document assumptions and open questions**
   Create dedicated section:
   ```markdown
   ## Assumptions & Open Questions

   ### Assumptions
   - [List technical assumptions made]

   ### Open Questions for Specialists
   - [Questions for infrastructure agent]
   - [Questions for security agent]
   ```

5. **Create initial version commit**
   ```bash
   git add node-spec.md
   git commit -m "Initial specification draft from charter

   - Populated all template sections from charter context
   - Flagged sections requiring specialist input
   - Documented assumptions and open questions
   - Ready for team contributions (Phase 3)

   🤖 Generated by Agent Zero
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**Quality Checks:**
- All template sections populated (no empty placeholders)
- Technical details expand on charter (not just copy-paste)
- Clear markers for specialist contributions
- Assumptions documented explicitly
- Git history shows clean initial draft
</actions>

<outputs>
- `node-spec.md` - First complete draft with all sections populated
- Git commit with initial specification
- List of flagged sections for specialist review
- Documented assumptions and open questions

**Status Update:**
- Specification exists and is version-controlled
- Ready for specialist agent evaluation and contributions
</outputs>

<duration>45-60 minutes</duration>
</phase>

<phase id="2" name="Evaluate Team Membership" gate="none">
<description>
Agent Zero reviews charter to determine which specialist agents should contribute to specification. Team composition varies based on node type, complexity, and integration requirements.
</description>

<inputs>
- Approved charter.md (contains team assignments or hints)
- Agent Zero's draft specification (identifies technical domains)
- HX-Infrastructure agent roster (from constitution.md or team directory)
</inputs>

<actions>
**Agent Zero performs:**

1. **Review charter team assignments**
   - Check if charter explicitly lists required specialists
   - Validate agent roles match specification needs

2. **Analyze specification complexity**
   - Identify technical domains requiring expert input:
     - Infrastructure (sizing, resources, deployment)
     - Security (authentication, authorization, encryption)
     - Integration (APIs, protocols, data flows)
     - Data (storage, backup, compliance)
     - Networking (connectivity, DNS, load balancing)
     - Monitoring (observability, alerting)

3. **Select specialist agents**
   Based on analysis:
   ```markdown
   ## Team Composition for [Node Name] Specification

   - **Amanda Chen** (Ansible/Infrastructure) - Deployment automation, resource provisioning
   - **Sarah Williams** (Security) - Authentication flows, compliance requirements
   - **Elena Rodriguez** (Integration) - API design, service mesh integration
   - **Marcus Johnson** (Data/RAG) - If node involves knowledge graphs or vector stores
   - **George Kim** (MCP Gateway) - If node exposes MCP tools
   ```

4. **Document contribution expectations**
   For each specialist:
   ```markdown
   ### [Agent Name] - Expected Contributions
   - **Focus Areas:** [Specific sections of spec]
   - **Key Questions:** [Questions needing their expertise]
   - **Context Required:** [Relevant charter sections, related nodes]
   ```

5. **Create team notification comment**
   Add to node-spec.md:
   ```markdown
   <!-- TEAM CONTRIBUTIONS PHASE

   The following specialists are requested to contribute to this specification:

   1. Amanda Chen - Infrastructure sizing and Ansible playbook requirements
   2. Sarah Williams - Security architecture and compliance validation
   3. Elena Rodriguez - Integration patterns and API contracts

   Each agent: Load context from charter.md and this draft, contribute to your
   assigned sections, and commit changes in ONE continuous session.

   Coordination: Agent Zero will synthesize contributions in Phase 4.
   -->
   ```

**Quality Checks:**
- Team composition matches specification technical domains
- Each specialist has clear focus areas
- No gaps in required expertise
- Contribution expectations documented
</actions>

<outputs>
- Finalized team roster for specification development
- Documented contribution expectations per specialist
- Clear markers in node-spec.md for each agent's focus areas

**Status Update:**
- Team composition approved
- Ready for parallel specialist contributions (Phase 3)
</outputs>

<duration>10-15 minutes</duration>
</phase>

<phase id="3" name="Team Context Loading + Immediate Contribution" gate="none" new="true">
<description>
**CRITICAL STATELESS AGENT PATTERN:** Each specialist agent operates independently in a continuous session:
1. Load context (charter.md + node-spec.md draft)
2. Read assigned sections
3. Make contributions directly to node-spec.md
4. Commit changes immediately
5. Session ends

This is NOT a waiting workflow. Agents do NOT coordinate in real-time. Agent Zero synthesizes all contributions in Phase 4.
</description>

<critical_pattern>
**Continuous Process Pattern:**
```
Specialist Agent Invoked
    ↓
Context Loading (charter + spec draft)
    ↓
Section Analysis (read assigned focus areas)
    ↓
Contribution (edit node-spec.md directly)
    ↓
Commit Changes (one commit per agent)
    ↓
Session Ends (agent does not wait for others)
```

**Key Rules:**
- Each agent works independently
- No inter-agent coordination required
- All context in charter.md and node-spec.md draft
- One commit per agent contribution
- Agent Zero synthesizes later (Phase 4)
</critical_pattern>

<inputs>
**For Each Specialist Agent:**
- charter.md (APPROVED)
- node-spec.md (Agent Zero's draft with flagged sections)
- Assignment comment showing their focus areas
- Relevant HX-Infrastructure context (network topology, existing services)
</inputs>

<actions>
**Each Specialist Agent independently performs:**

1. **Load Context (5-10 min)**
   ```bash
   # Read charter for project vision and requirements
   cat charter.md

   # Read current spec draft to understand existing content
   cat node-spec.md

   # Read assignment to identify focus areas
   grep "NEEDS: [Agent Name]" node-spec.md
   ```

2. **Analyze Assignment (5 min)**
   - Identify sections requiring contribution
   - Review Agent Zero's assumptions and questions
   - Note any conflicts with existing content

3. **Make Contributions (30-60 min)**
   **Example: Amanda Chen (Infrastructure Agent)**
   - Edit "Deployment Strategy" section with Ansible playbook requirements
   - Add "Resource Allocation" details (CPU, memory, disk)
   - Specify infrastructure dependencies (PostgreSQL version, Redis cluster)
   - Document high-availability configuration

   **Example: Sarah Williams (Security Agent)**
   - Edit "Security Considerations" with authentication flow
   - Add compliance requirements (GDPR, SOC2 if applicable)
   - Specify encryption requirements (TLS, data-at-rest)
   - Document security testing requirements

   **Example: Elena Rodriguez (Integration Agent)**
   - Edit "Integration Points" with API contracts
   - Add service mesh configuration
   - Specify protocol requirements (gRPC, REST, WebSocket)
   - Document integration testing scenarios

4. **Commit Contribution (2 min)**
   ```bash
   git add node-spec.md
   git commit -m "[Agent Name] specification contributions

   Added:
   - [Specific section updates]
   - [Technical details contributed]
   - [Requirements clarified]

   Focus areas: [list]

   🤖 Generated by [Agent Name]
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

5. **Session Ends**
   - Agent does NOT wait for other agents
   - Agent does NOT read other agents' commits
   - Synthesis happens in Phase 4 by Agent Zero

**Quality Checks (per agent):**
- Contributions directly address flagged sections
- Technical details are specific and actionable
- No contradictions with charter
- Commit message clearly describes contribution
- Changes committed to git before session ends
</actions>

<outputs>
**Per Specialist Agent:**
- Updated node-spec.md with domain-specific contributions
- Git commit showing their additions/modifications
- Technical details, requirements, or clarifications added

**Collective Output (after all agents complete):**
- node-spec.md with multiple commits from different specialists
- Diverse technical perspectives incorporated
- Ready for Agent Zero synthesis in Phase 4

**Typical Git History After Phase 3:**
```
commit abc123 - Elena Rodriguez contributions (Integration)
commit def456 - Sarah Williams contributions (Security)
commit ghi789 - Amanda Chen contributions (Infrastructure)
commit jkl012 - Agent Zero initial draft
```
</outputs>

<duration>90-120 minutes total (agents work in parallel or sequentially, no coordination)</duration>
</phase>

<phase id="4" name="Agent Zero Synthesis & Conflict Resolution" gate="synthesis-complete">
<description>
Agent Zero reviews all specialist contributions, resolves conflicts, removes redundancy, ensures consistency, and produces unified specification document.
</description>

<inputs>
- node-spec.md with multiple specialist contributions
- Git history showing all commits from Phase 3
- Charter.md as source of truth for requirements
- Agent Zero's understanding of project vision
</inputs>

<actions>
**Agent Zero performs:**

1. **Review All Contributions (10 min)**
   ```bash
   # View complete git history
   git log --oneline node-spec.md

   # Review each specialist's changes
   git show <commit-hash>
   ```

2. **Identify Conflicts and Inconsistencies (15 min)**
   - **Direct Conflicts:** Same section edited with contradictory details
   - **Requirement Conflicts:** Technical choices that contradict each other
   - **Scope Conflicts:** Proposed implementations exceeding charter scope
   - **Style Inconsistencies:** Different formatting, terminology, detail levels

3. **Resolve Conflicts (20-30 min)**
   **Conflict Type 1: Technical Contradictions**
   - Example: Infrastructure agent suggests VM deployment, Integration agent assumes container deployment
   - Resolution: Refer to charter for deployment preference, or choose based on HX-Infrastructure standards

   **Conflict Type 2: Overlapping Sections**
   - Example: Both security and integration agents discuss API authentication
   - Resolution: Consolidate into coherent flow, cross-reference between sections

   **Conflict Type 3: Scope Creep**
   - Example: Specialist adds features not in charter
   - Resolution: Move to "Future Enhancements" section or remove if out of scope

4. **Standardize Format and Style (15 min)**
   - Ensure consistent heading levels
   - Standardize terminology (use charter's language)
   - Align detail levels across sections
   - Fix markdown formatting issues

5. **Fill Any Remaining Gaps (10 min)**
   - Check for sections still marked as "NEEDS: [Agent]"
   - Verify all template sections are complete
   - Ensure traceability to charter requirements

6. **Create Synthesis Commit (5 min)**
   ```bash
   git add node-spec.md
   git commit -m "Synthesize specialist contributions into unified specification

   Resolved conflicts:
   - [Conflict 1 description and resolution]
   - [Conflict 2 description and resolution]

   Standardization:
   - Unified terminology and formatting
   - Consolidated overlapping sections
   - Removed scope creep items to future enhancements

   Verification:
   - All charter requirements addressed
   - All template sections complete
   - Ready for CAIO review (Phase 6)

   🤖 Generated by Agent Zero
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**Quality Checks:**
- No contradictory technical details remain
- All charter requirements traceable in spec
- Consistent formatting and terminology
- No empty or placeholder sections
- Git history shows clear synthesis process
</actions>

<outputs>
- Unified, conflict-free node-spec.md
- Git commit documenting synthesis and resolutions
- Specification ready for CAIO review

**Gate: Synthesis Complete**
Pass Criteria:
- ✅ All specialist contributions integrated
- ✅ No technical contradictions
- ✅ All charter requirements addressed
- ✅ Consistent format and style
- ✅ No placeholder content remains
</outputs>

<duration>30-45 minutes</duration>
</phase>

<phase id="5" name="Clarifying Questions to CAIO" gate="none">
<description>
Agent Zero reviews synthesized specification and identifies any ambiguities, assumptions needing validation, or gaps requiring CAIO input before final review.
</description>

<inputs>
- Unified node-spec.md from Phase 4
- Charter.md as requirements reference
- Any assumptions or questions documented during synthesis
</inputs>

<actions>
**Agent Zero performs:**

1. **Analyze Specification for Ambiguities (10 min)**
   - Review technical decisions made during synthesis
   - Identify areas where multiple valid approaches exist
   - Check for assumptions about CAIO preferences or requirements

2. **Formulate Targeted Questions (10 min)**
   **Question Categories:**
   - **Technical Choices:** "Should authentication use OAuth2 or mTLS certificates?"
   - **Scope Clarifications:** "Charter mentions 'future AI integration' - should we include API hooks now?"
   - **Priority Decisions:** "If budget constrained, prioritize HA setup or monitoring stack?"
   - **Integration Details:** "Which existing service should handle user notifications - existing SMTP relay or new service?"

   **Good Question Format:**
   ```markdown
   ## Clarifying Questions for CAIO

   ### 1. Authentication Method
   **Context:** Specialist agents proposed both OAuth2 and mTLS. Charter mentions "secure authentication" without specifying.
   **Question:** Which authentication method do you prefer for this service?
   **Options:**
   - OAuth2 (easier integration with existing services)
   - mTLS (higher security, more complex setup)
   **Impact:** Affects integration complexity and deployment timeline

   ### 2. [Next question...]
   ```

3. **Present Questions to CAIO (5 min)**
   - Add questions to node-spec.md in dedicated section
   - Commit questions to git
   - Wait for CAIO responses (this may pause workflow)

4. **Receive and Document Answers**
   - CAIO provides answers (via conversation or direct spec edits)
   - Agent Zero updates spec with decisions
   - Remove questions section, integrate answers into relevant sections

5. **Update Specification with CAIO Decisions (10 min)**
   ```bash
   git add node-spec.md
   git commit -m "Integrate CAIO clarifications into specification

   Questions answered:
   - Authentication method: [CAIO decision]
   - Scope for AI integration: [CAIO decision]
   - Priority if constrained: [CAIO decision]

   Updated sections:
   - Security Considerations (authentication details)
   - Future Enhancements (AI integration scope)
   - Timeline & Milestones (priority adjustments)

   🤖 Generated by Agent Zero
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**Quality Checks:**
- Questions are specific and actionable
- Each question includes context and impact
- CAIO can answer decisively (not open-ended discussions)
- Answers integrated into spec sections (not left as Q&A)
</actions>

<outputs>
- Clarifying questions presented to CAIO
- CAIO decisions documented
- Specification updated with clarifications
- Git commit showing CAIO input integration

**Status Update:**
- All ambiguities resolved
- Specification reflects CAIO final decisions
- Ready for formal CAIO review and approval
</outputs>

<duration>15-30 minutes (excludes CAIO response time)</duration>
</phase>

<phase id="6" name="CAIO Review & Approval" gate="specification-approved">
<description>
CAIO performs final review of complete specification, validates alignment with charter vision, and provides formal approval or requests revisions.
</description>

<inputs>
- Complete, unified node-spec.md with all clarifications
- charter.md for alignment verification
- Git history showing all contributions and synthesis
</inputs>

<actions>
**CAIO performs:**

1. **Review Specification Completeness (10 min)**
   - Verify all template sections populated with meaningful content
   - Check technical depth is appropriate for implementation
   - Ensure nothing critical is missing

2. **Validate Charter Alignment (10 min)**
   - Cross-reference spec sections with charter requirements
   - Verify success criteria from charter are measurable in spec
   - Confirm scope hasn't grown beyond charter intent
   - Check that "out of scope" items from charter remain out of scope

3. **Assess Technical Decisions (10 min)**
   - Review specialist contributions for reasonableness
   - Validate technical choices align with HX-Infrastructure standards
   - Ensure integration points are realistic and maintainable

4. **Provide Approval Decision**

   **Option A: APPROVE**
   ```markdown
   ## CAIO Approval

   **Status:** APPROVED
   **Date:** YYYY-MM-DD
   **Comments:** Specification comprehensively addresses charter requirements.
   Technical approach is sound and aligns with infrastructure standards.
   Ready for task execution phase.

   **Approved By:** [CAIO Name]
   ```

   **Option B: REQUEST REVISIONS**
   ```markdown
   ## CAIO Review - Revisions Requested

   **Status:** REVISIONS REQUIRED
   **Date:** YYYY-MM-DD

   ### Required Changes:
   1. **Security Section:** Need more detail on encryption key management
   2. **Timeline:** Milestone 2 seems optimistic, please add buffer
   3. **Integration:** Clarify failover behavior for external API dependency

   ### Optional Suggestions:
   - Consider adding performance benchmarks to success metrics

   **Next Steps:** Agent Zero to address required changes and resubmit
   ```

5. **Update Specification with Approval Status**
   ```bash
   git add node-spec.md
   git commit -m "CAIO approval: Specification APPROVED

   Specification reviewed and approved for implementation.
   Node status promoted: CHARTERED → PLANNED

   Ready for task execution workflow.

   Approved-By: [CAIO Name]
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**Quality Checks:**
- CAIO has reviewed entire specification
- Approval status explicitly documented
- Any revision requests are specific and actionable
- Approval date recorded for audit trail
</actions>

<outputs>
**If APPROVED:**
- node-spec.md with status: APPROVED
- Git commit with CAIO approval
- Node status: PLANNED (promoted from CHARTERED)
- Specification ready for task execution workflow

**If REVISIONS REQUIRED:**
- List of specific changes needed
- Return to Phase 4 (Agent Zero synthesis) to address revisions
- Re-submit for Phase 6 review after updates

**Gate: Specification Approved**
Pass Criteria:
- ✅ CAIO formal approval documented
- ✅ Specification status = APPROVED
- ✅ Node status promoted to PLANNED
- ✅ All revision requests resolved (if any)
</outputs>

<duration>15-30 minutes</duration>
</phase>

<phase id="7" name="Post-Approval Updates" gate="none">
<description>
After approval, Agent Zero performs final administrative updates to complete specification workflow and prepare for task execution phase.
</description>

<inputs>
- Approved node-spec.md
- Charter.md for reference
- HX-Infrastructure node registry/index
</inputs>

<actions>
**Agent Zero performs:**

1. **Update Node Status in Registry (5 min)**
   If HX-Infrastructure maintains a node registry:
   ```bash
   # Update node-index.md or similar tracking document
   # Change status: CHARTERED → PLANNED
   ```

2. **Create Specification Summary (5 min)**
   Add executive summary to top of node-spec.md if not present:
   ```markdown
   ## Executive Summary

   **Node:** [name]
   **Status:** PLANNED (specification approved)
   **Purpose:** [one-sentence purpose]
   **Key Technology:** [main tech stack]
   **Timeline:** [estimated from spec]
   **Next Phase:** Task execution workflow
   ```

3. **Link Specification to Charter (3 min)**
   Update charter.md to reference approved spec:
   ```markdown
   ## Related Documents

   - **Specification:** node-spec.md (APPROVED on YYYY-MM-DD)
   - **Status:** Moved to PLANNED status
   - **Next Workflow:** Task execution
   ```

4. **Document Lessons Learned (Optional, 5 min)**
   If specification process revealed insights:
   ```markdown
   ## Specification Process Notes

   ### Challenges Encountered:
   - [Challenge 1 and how resolved]

   ### Key Decisions:
   - [Important technical decision and rationale]

   ### Team Contributions:
   - [Notable specialist insights]
   ```

5. **Create Workflow Completion Commit (2 min)**
   ```bash
   git add charter.md node-spec.md [any other updated files]
   git commit -m "Complete specification workflow for [node name]

   Workflow phases completed:
   - Prerequisites validated
   - Agent Zero draft created
   - Team contributions synthesized
   - CAIO clarifications integrated
   - Specification approved

   Node status: CHARTERED → PLANNED

   Next: Task execution workflow

   🤖 Generated by Agent Zero
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**Quality Checks:**
- Node status updated in all relevant locations
- Specification and charter cross-referenced
- Git history shows complete workflow
- Ready to transition to task execution
</actions>

<outputs>
- Complete specification package:
  - node-spec.md (APPROVED)
  - charter.md (linked to spec)
  - Git history documenting entire process
  - Node status: PLANNED

- Specification workflow complete
- Ready for task execution workflow

**Next Workflow:** Task Execution Workflow (`cc-task-execution-workflow.md`)
</outputs>

<duration>10-15 minutes</duration>
</phase>
</phases>

<quality_gates>
<gate name="prerequisites-met" phase="0">
**Gate Question:** Are all prerequisites for specification development met?

**Pass Criteria:**
- ✅ charter.md exists with status: APPROVED
- ✅ Research findings documented (if charter required research)
- ✅ Team assignments identified
- ✅ Specification template available

**Fail Actions:**
- Return to charter workflow to complete missing prerequisites
- Do NOT proceed to Phase 1 without approved charter
</gate>

<gate name="synthesis-complete" phase="4">
**Gate Question:** Has Agent Zero successfully synthesized all specialist contributions into unified specification?

**Pass Criteria:**
- ✅ All specialist contributions reviewed
- ✅ Conflicts identified and resolved
- ✅ Consistent formatting and terminology
- ✅ All charter requirements addressed
- ✅ No placeholder or empty sections
- ✅ Git commit documents synthesis process

**Fail Actions:**
- If conflicts unresolvable: Escalate to CAIO for decision
- If gaps remain: Identify missing expertise and bring in additional specialist
- If scope issues: Return to charter for scope clarification
</gate>

<gate name="specification-approved" phase="6">
**Gate Question:** Has CAIO formally approved the specification for implementation?

**Pass Criteria:**
- ✅ CAIO has reviewed complete specification
- ✅ Approval status documented in node-spec.md
- ✅ All revision requests resolved
- ✅ Node status promoted to PLANNED
- ✅ Git commit shows approval

**Fail Actions:**
- If revisions requested: Return to Phase 4, address changes, resubmit
- If scope concerns: May need to return to charter workflow
- If timeline concerns: Adjust milestones and resubmit
</gate>
</quality_gates>

<anti_patterns>
**Common Pitfalls to Avoid:**

<anti_pattern name="Sequential Agent Coordination">
**Problem:** Treating Phase 3 as sequential workflow where agents wait for each other to finish.

**Why It Fails:**
- Creates unnecessary delays
- Agents lose context waiting for others
- Doesn't scale with team size

**Correct Approach:**
Each specialist agent operates in independent, continuous session:
1. Load context (charter + draft spec)
2. Make contribution
3. Commit immediately
4. Session ends

Agent Zero synthesizes ALL contributions later in Phase 4. No real-time coordination needed.
</anti_pattern>

<anti_pattern name="Copy-Paste Charter into Spec">
**Problem:** Agent Zero's Phase 1 draft just copies charter sections verbatim into specification template.

**Why It Fails:**
- Charter is high-level vision; spec needs implementation details
- Doesn't add value beyond charter
- Wastes specialist agents' time reading redundant content

**Correct Approach:**
Agent Zero should EXPAND charter content:
- Charter: "Secure authentication required"
- Spec: "Authentication via OAuth2 with PKCE flow, JWT tokens (15-min expiry), refresh tokens (7-day expiry), integration with existing hx-identity-server.hx.dev.local"
</anti_pattern>

<anti_pattern name="Ignoring Specialist Conflicts">
**Problem:** Agent Zero in Phase 4 doesn't actively resolve contradictions between specialist contributions.

**Why It Fails:**
- Specification contains conflicting technical decisions
- Implementation team gets confused during execution
- Rework required later, wasting time

**Correct Approach:**
Agent Zero must actively identify and resolve:
- **Technical contradictions:** Choose one approach based on charter and standards
- **Overlapping concerns:** Consolidate into coherent narrative
- **Scope creep:** Remove or move to future enhancements
- **Document resolutions in synthesis commit**
</anti_pattern>

<anti_pattern name="Skipping CAIO Clarifications (Phase 5)">
**Problem:** Agent Zero proceeds to Phase 6 (CAIO review) with ambiguities or assumptions still in specification.

**Why It Fails:**
- CAIO review becomes a Q&A session instead of approval decision
- Wastes CAIO's time
- May require multiple review cycles

**Correct Approach:**
Use Phase 5 to proactively ask targeted questions BEFORE formal review:
- Identify technical choices with multiple valid options
- Ask specific, decision-forcing questions
- Integrate answers into spec
- CAIO review (Phase 6) becomes approval, not debugging
</anti_pattern>

<anti_pattern name="Specification Without Measurable Success Criteria">
**Problem:** Specification lists features but doesn't define measurable success metrics aligned with charter.

**Why It Fails:**
- No objective way to determine when implementation is "done"
- Cannot validate charter promises
- Risk of endless refinement without completion

**Correct Approach:**
Specification must include quantified success metrics:
- **Charter:** "Fast response times"
- **Spec:** "95th percentile API response time < 200ms under 1000 req/sec load"
- **Charter:** "High availability"
- **Spec:** "99.9% uptime SLA (max 43 minutes downtime/month)"
</anti_pattern>

<anti_pattern name="Breaking Continuous Process for Stateless Agents">
**Problem:** Team members pause between context load and editing.

**Why It Fails:**
- State loss occurs immediately
- Incomplete contributions
- Shallow input without full context

**Correct Approach:**
Enforce ONE continuous session: context → edit → commit
- No breaks allowed between steps
- 60-90 minute uninterrupted block
- Full context maintained throughout contribution
</anti_pattern>

<anti_pattern name="Generic Boilerplate Content">
**Problem:** Using template text without specifics.

**Why It Fails:**
- Useless spec that doesn't guide implementation
- Forces implementation team to make decisions
- Defeats purpose of specification phase

**Correct Approach:**
Require specific details: commands, ports, IPs, configs
- ✅ "Configure firewall: ufw allow 8080/tcp, ufw allow 5432/tcp from 192.168.10.0/24"
- ❌ "Configure firewall appropriately"
</anti_pattern>
</anti_patterns>

<related_documents>
**Workflow Context:**
- **Previous:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Creates approved charter
- **Next:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md` - Executes specification via tasks

**Procedure Files:**
- `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Detailed process documentation
- `/home/agent0/HX-Infrastructure/procedures/charter-workflow.md` - Previous phase
- `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Next phase after spec
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - How team loads context

**Templates:**
- `/home/agent0/HX-Infrastructure/templates/node-spec-template.md` - Standard specification template
- `/home/agent0/HX-Infrastructure/templates/charter-template.md` - Charter template (for reference)

**Reference Documents:**
- `/home/agent0/HX-Infrastructure/constitution.md` - HX-Infrastructure governance and agent roles
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team structure
- `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` - Agent capabilities
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Technical standards
- `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Deployment standards
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Doc standards
- `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - File naming standards

**Centralized Artifacts:**
- `/home/agent0/HX-Infrastructure/docs/raidd-log.md` - Update in Phase 7
- `/home/agent0/HX-Infrastructure/docs/backlog.md` - Update in Phase 7

**Example Specifications:**
- (When created, link to example node-spec.md files here - use FICTITIOUS examples only per policy)
</related_documents>

<critical_reminders>
**DO:**
- ✅ Use stateless agent continuous process pattern (Phase 3)
- ✅ Have Agent Zero synthesize contributions, not specialists coordinate
- ✅ Expand charter content into implementation details (don't copy-paste)
- ✅ Resolve conflicts proactively in Phase 4
- ✅ Ask clarifying questions BEFORE formal CAIO review (Phase 5)
- ✅ Include measurable success criteria aligned with charter
- ✅ Commit after each major phase completion
- ✅ Update node status to PLANNED after approval

**DON'T:**
- ❌ Make specialist agents wait for each other (they work independently)
- ❌ Let specification contradict charter scope or requirements
- ❌ Skip conflict resolution (hoping CAIO will decide later)
- ❌ Proceed to implementation without APPROVED status
- ❌ Leave placeholder content or "TBD" sections in final spec
- ❌ Add scope beyond charter without CAIO approval
- ❌ Use production system names in examples (fictitious only)
- ❌ Break continuous process for stateless agents (context load → edit → commit = ONE session)

**Stateless Agent Critical Rule:**
Context load → Edit immediately → Commit = ONE CONTINUOUS PROCESS (no breaks!)

**Quality First:**
Detailed specifications prevent rework in task breakdown and execution phases.
</critical_reminders>

<validation_checklist>
**Before submitting specification for CAIO approval (end of Phase 5), verify:**

**Completeness:**
- [ ] All template sections populated with meaningful content
- [ ] No "TBD" or placeholder text remains
- [ ] All charter requirements addressed in specification
- [ ] Success metrics are measurable and quantified

**Technical Quality:**
- [ ] Specialist contributions integrated (git log shows multiple commits)
- [ ] No contradictory technical decisions
- [ ] Architecture diagram present and accurate
- [ ] Integration points clearly specified
- [ ] Security considerations comprehensive
- [ ] Deployment strategy detailed and actionable

**Alignment:**
- [ ] Specification scope matches charter scope (no scope creep)
- [ ] Charter success criteria traceable to spec metrics
- [ ] All "out of scope" items from charter remain out of scope
- [ ] Timeline realistic based on complexity

**Process Quality:**
- [ ] Git history shows clear workflow progression
- [ ] All specialist contributions have individual commits
- [ ] Agent Zero synthesis commit documents conflict resolutions
- [ ] CAIO clarifications integrated into relevant sections

**Documentation:**
- [ ] Executive summary present
- [ ] Related documents cross-referenced
- [ ] Assumptions documented explicitly
- [ ] Future enhancements section captures scope creep items

**Ready for Approval:**
- [ ] Specification reads as unified document (not collection of contributions)
- [ ] No obvious questions or ambiguities remain
- [ ] CAIO can make approve/reject decision without asking questions

**Stateless Agent Pattern Compliance:**
- [ ] All team members completed context → edit → commit in ONE session
- [ ] No evidence of broken continuity in contributions
- [ ] Review documents show comprehensive context loading
</validation_checklist>

<visual_diagram>
**Specification Development Flow:**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 0: Prerequisites Check                                │
│ Verify: charter.md (APPROVED) + team assignments            │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: prerequisites-met gate
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: Agent Zero Creates Initial Draft (45-60 min)       │
│ • Copy spec template                                        │
│ • Populate all sections from charter                        │
│ • Flag sections needing specialist input                    │
│ • Commit initial draft                                      │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: Evaluate Team Membership (10-15 min)               │
│ • Review charter team assignments                           │
│ • Select specialist agents based on domains                 │
│ • Document contribution expectations                        │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: Team Contributions - PARALLEL/INDEPENDENT          │
│                                                             │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│ │ Infrastructure│  │   Security   │  │ Integration  │      │
│ │     Agent    │  │    Agent     │  │    Agent     │      │
│ └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│        │                 │                 │               │
│        │ Each agent:     │                 │               │
│        │ 1. Load context │                 │               │
│        │ 2. Contribute   │                 │               │
│        │ 3. Commit       │                 │               │
│        │ 4. End session  │                 │               │
│        │                 │                 │               │
│        ↓                 ↓                 ↓               │
│     commit           commit           commit              │
└────────────────────┬────────────────────────────────────────┘
                     │ All specialist commits complete
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 4: Agent Zero Synthesis (30-45 min)                   │
│ • Review all specialist contributions                       │
│ • Identify conflicts                                        │
│ • Resolve contradictions                                    │
│ • Standardize format                                        │
│ • Commit unified specification                              │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: synthesis-complete gate
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 5: Clarifying Questions (15-30 min)                   │
│ • Identify ambiguities                                      │
│ • Ask targeted questions to CAIO                            │
│ • Receive answers                                           │
│ • Integrate decisions into spec                             │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 6: CAIO Review & Approval (15-30 min)                 │
│ • Review completeness                                       │
│ • Validate charter alignment                                │
│ • Assess technical decisions                                │
│ • APPROVE or REQUEST REVISIONS                              │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: specification-approved gate
                     ↓                                         │
┌─────────────────────────────────────────────────────────────┐
│ PHASE 7: Post-Approval Updates (10-15 min)                  │
│ • Update node status: CHARTERED → PLANNED                   │
│ • Link spec to charter                                      │
│ • Complete workflow commit                                  │
└────────────────────┬────────────────────────────────────────┘
                     ↓
            ┌────────────────────┐
            │ SPECIFICATION      │
            │ APPROVED           │
            │                    │
            │ Ready for Task     │
            │ Execution Workflow │
            └────────────────────┘
```

**Key: Stateless Agent Pattern (Phase 3)**
```
Each Specialist Agent Session (Independent):
┌─────────────────────────────────────┐
│ 1. LOAD CONTEXT                     │
│    • Read charter.md                │
│    • Read node-spec.md draft        │
│    • Identify focus areas           │
├─────────────────────────────────────┤
│ 2. CONTRIBUTE                       │
│    • Edit assigned sections         │
│    • Add technical details          │
│    • Document assumptions           │
├─────────────────────────────────────┤
│ 3. COMMIT                           │
│    • git add node-spec.md           │
│    • git commit with description    │
├─────────────────────────────────────┤
│ 4. END SESSION                      │
│    • No waiting for other agents    │
│    • No coordination needed         │
└─────────────────────────────────────┘

Agent Zero synthesizes ALL contributions in Phase 4
```
</visual_diagram>

<metadata_footer>
**Document Version:** 1.3
**Last Updated:** 2025-11-16
**Status:** APPROVED - Production Workflow
**Maintained By:** CAIO + Agent Zero
**Related Workflows:** Charter Creation → **Specification Development** → Task Execution → Project Closeout
</metadata_footer>
