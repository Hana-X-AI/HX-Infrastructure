---
workflow: phase-charter-questions
version: 1.1
date: 2025-11-20
status: APPROVED
type: phase-command
description: Generate comprehensive charter clarifying questions in two phases (initial and post-research) to ensure complete understanding before charter document creation
applies_to: charter_workflow, project_initiation, requirements_gathering
author: HX-Infrastructure Team
last_updated: 2025-11-20
update_notes: Standardized integration convention header, added infrastructure-specific question examples
---

<metadata>
**Workflow:** Charter Questions Generation - Initial and Post-Research Phases
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Standardized integration convention, added infrastructure examples)
**Status:** APPROVED - Production Ready
**Type:** Phase Command
**Purpose:** Generate comprehensive clarifying questions for charter development through systematic analysis of CAIO input and knowledge vault research findings, ensuring complete understanding before charter document creation
</metadata>

<objective>
**Purpose:** Systematically generate clarifying questions that transform CAIO's initial brain dump and knowledge vault research findings into actionable, specific information needed for comprehensive charter document creation. Questions bridge gaps between vision and implementation, ensuring technical feasibility, resource requirements, integration points, and success criteria are fully understood.

**Command Capabilities:**
- Parse CAIO brain dump for implicit requirements and unstated assumptions
- Generate initial clarifying questions organized by category
- Prioritize questions by criticality and dependency order
- Generate post-research questions based on knowledge vault findings
- Identify technical unknowns requiring experimental validation
- Document question responses for charter integration
- Track open questions requiring follow-up
- Validate question completeness before charter generation

**When to Use This Command:**
- During charter workflow Phase 2 (after parsing CAIO input, before knowledge research)
- During charter workflow Phase 6 (after knowledge vault research, before charter generation)
- When CAIO provides additional requirements mid-charter process
- When research findings reveal new areas requiring clarification
- When pivoting charter direction based on technical constraints
- When expanding charter scope with new integration points

**Integration Points:**
- **Called by:** cc-charter-workflow.md (Phase 2 and Phase 6)
- **Inputs:** CAIO brain dump, parsed requirements, knowledge vault research findings
- **Outputs:** Categorized question lists, question responses, open questions tracker
- **Prerequisites:** CAIO initial input documented, repository list identified (for Phase 6)
</objective>

<utility_overview>
**Core Function:**
This phase command generates two distinct sets of clarifying questions during charter development:

**Phase 1: Initial Questions (Pre-Research)**
Generated immediately after parsing CAIO input, these questions:
- Clarify vision, purpose, and business value
- Identify integration points and dependencies
- Establish scope boundaries and constraints
- Surface technical requirements and preferences
- Define success criteria and metrics
- Reveal implicit assumptions requiring validation

**Phase 2: Post-Research Questions (After Knowledge Vault Research)**
Generated after reviewing knowledge repositories, these questions:
- Address gaps between research findings and requirements
- Clarify technical approaches discovered in research
- Resolve conflicts between multiple possible approaches
- Validate assumptions made during research
- Identify experimental validation needs
- Confirm integration patterns and best practices

**Key Principle:** Questions should be specific, actionable, and designed to produce concrete answers that directly inform charter content. Avoid vague or philosophical questions that don't advance charter completeness.

**Question Quality Standards:**
- Each question has clear context explaining why it's being asked
- Questions are answerable with specific, concrete information
- Questions are prioritized by dependency order (foundational questions first)
- Questions avoid duplication across categories
- Questions anticipate follow-up needs
</utility_overview>

<state_management>
**Stateless Component:**
- This phase command file (instructions + templates + question frameworks)
- Question generation methodology and categorization system
- Question quality standards and validation criteria
- Reusable across all charter development projects

**Stateful Artifacts:**
Phase command execution creates project-specific files:

**Initial Questions Phase:**
```
/nodes/{node-name}/charter/
  questions-initial.md           # Generated initial questions
  questions-initial-responses.md # CAIO responses to initial questions
  questions-initial-tracking.md  # Open questions needing follow-up
```

**Post-Research Questions Phase:**
```
/nodes/{node-name}/charter/
  questions-post-research.md              # Generated post-research questions
  questions-post-research-responses.md    # CAIO responses to post-research
  questions-post-research-tracking.md     # Open questions needing follow-up
  questions-consolidated.md               # All Q&A consolidated for charter
```

**File Naming Convention:**
- `questions-{phase}.md` - Generated questions organized by category
- `questions-{phase}-responses.md` - CAIO answers with timestamps
- `questions-{phase}-tracking.md` - Open questions status tracker
- `questions-consolidated.md` - Final consolidated Q&A for charter reference

**File Locations:**
All question artifacts stored in `/nodes/{node-name}/charter/` alongside charter document for easy reference during charter generation and future review.

**State Persistence:**
Question artifacts persist throughout project lifecycle, serving as:
- Historical record of requirements evolution
- Reference for specification and task phases
- Documentation of decisions made during charter
- Training data for future charter processes
</state_management>

<question_generation_framework>
**Question Categories:**

Charter questions are organized into 8 standard categories, each serving specific charter section requirements:

**Category 1: Vision and Purpose**
- What is the fundamental problem this node/service solves?
- Why is this needed now versus later or never?
- What business/development value does this provide?
- How does this fit into the overall HX-Infrastructure vision?
- What happens if we don't build this?

**Category 2: Technical Scope**
- What are the core technical capabilities required?
- What technologies/frameworks are mandatory vs. preferred?
- What are the explicit non-goals or out-of-scope items?
- What scale/performance requirements exist?
- What data handling requirements exist?

**Category 3: Integration and Dependencies**
- What existing HX-Infrastructure nodes does this integrate with?
- What external systems or services does this depend on?
- What authentication/authorization requirements exist?
- What network connectivity requirements exist?
- What data flows into/out of this node?

**Category 4: Infrastructure Requirements**
- What hardware resources are needed (CPU, RAM, disk, GPU)?
- What operating system and base configuration?
- What network zone should this reside in?
- What availability/reliability requirements exist?
- What backup and disaster recovery requirements exist?

**HX-Infrastructure Specific Questions:**
- **Q15: What is the bare metal deployment target for this node?**
  - Context: HX-Infrastructure deploys production services on Ubuntu 24 bare metal servers (not Docker except dev server). This ensures deployment target correctly identified.
  - Priority: P0
  - HX Philosophy: Bare metal first for production/staging, Docker dev-only on hx-dev-server ({DEV_SERVER_IP})

- **Q16: Will this node be managed via systemd service?**
  - Context: All HX-Infrastructure services use systemd for process management. Confirm systemd unit file requirements.
  - Priority: P0
  - HX Philosophy: Systemd service management required for all services

- **Q17: What manual deployment procedures are required?**
  - Context: HX-Infrastructure uses documented manual procedures (not automation). Document step-by-step deployment process.
  - Priority: P1
  - HX Philosophy: Manual procedures only (no Ansible playbooks, no automated deployment)

**Category 5: Security and Compliance**
- What data sensitivity levels are involved?
- What access control requirements exist?
- What audit/logging requirements exist?
- What encryption requirements exist (at rest, in transit)?
- What compliance standards apply?

**HX-Infrastructure Specific Questions:**
- **Q18: What credentials will be stored in Ansible Vault?**
  - Context: All credentials managed via Ansible Vault (no inline secrets, no local user accounts). Identify vault requirements early.
  - Priority: P0
  - HX Philosophy: Ansible Vault only for credentials management, no local users (all in Samba AD)

- **Q19: Are there any Docker container requirements for development?**
  - Context: Docker containers allowed ONLY on hx-dev-server ({DEV_SERVER_IP}) for development/project isolation. Production uses bare metal.
  - Priority: P1
  - HX Philosophy: Docker dev-only, production bare metal

**Category 6: Success Criteria**
- How will we know this node is "done"?
- What are the measurable success criteria?
- What tests must pass for operational promotion?
- What performance benchmarks must be met?
- What documentation must exist?

**Category 7: Risks and Constraints**
- What are the known technical risks?
- What are the resource constraints?
- What are the timeline constraints?
- What dependencies might block progress?
- What assumptions are we making?

**Category 8: Operations and Maintenance**
- Who will operate this node long-term?
- What monitoring and alerting is needed?
- What maintenance activities are anticipated?
- What upgrade/patching strategy is needed?
- What runbooks or procedures are needed?

**Question Priority Levels:**

**P0 (Critical):** Must answer before proceeding with charter
- Foundational scope questions
- Integration dependency questions
- Security/compliance requirements
- Resource feasibility questions

**P1 (High):** Should answer before charter finalization
- Technical approach details
- Performance requirements
- Success criteria specifics
- Operations considerations

**P2 (Medium):** Can defer to specification phase if needed
- Implementation details
- Optimization approaches
- Nice-to-have features
- Long-term enhancement ideas

**P3 (Low):** Future consideration, not charter-blocking
- Enhancement possibilities
- Alternative approaches
- Future integration opportunities
- Research topics for later
</question_generation_framework>

<question_generation_procedures>
  <procedure name="Generate Initial Clarifying Questions">
  **Purpose:** Generate comprehensive initial questions after parsing CAIO brain dump and before knowledge vault research

  **Prerequisites:**
  - CAIO brain dump documented in `/nodes/{node-name}/charter/caio-input.md`
  - Node purpose and high-level requirements identified
  - Repository list identified (but not yet researched)

  **Inputs Required:**
  - CAIO brain dump (natural language input)
  - Parsed requirements (structured extraction from brain dump)
  - Repository list for planned research
  - HX-Infrastructure current state (from inventory)

  **Execution Steps:**

  **STEP 1: Analyze CAIO Input for Gaps**
  Review CAIO brain dump and identify what's stated vs. what's missing:

  **Actions:**
  1. Read `/nodes/{node-name}/charter/caio-input.md` completely
  2. Review `/nodes/{node-name}/charter/parsed-requirements.md` for structured extraction
  3. Create gap analysis document:
     - What is explicitly stated?
     - What is implied but not stated?
     - What is completely missing?
     - What assumptions are being made?

  4. Identify critical unknowns by category:
     - Vision gaps (why, what value, how it fits)
     - Technical gaps (what technologies, what scale, what integrations)
     - Resource gaps (what infrastructure, what skills, what timeline)
     - Success gaps (how measured, what tests, what outcomes)

  **Verification:**
  - [ ] CAIO input fully reviewed and understood
  - [ ] Parsed requirements referenced for structure
  - [ ] Gap analysis covers all 8 question categories
  - [ ] Critical unknowns identified per category

  **STEP 2: Generate Category-Organized Questions**
  Create initial questions organized by the 8 standard categories:

  **Actions:**
  1. For each category, generate 3-7 questions addressing identified gaps
  2. Ensure each question:
     - Is specific and answerable with concrete information
     - Has clear context explaining why it's asked
     - Relates directly to charter section it will inform
     - Avoids duplication with other questions
     - Is appropriately scoped (not too broad or too narrow)

  3. Format questions using template:
     ```markdown
     **Q{number}: {Question text}**
     - **Category:** {Category name}
     - **Context:** {Why this question matters for charter}
     - **Priority:** P0/P1/P2/P3
     - **Charter Section:** {Which charter section this informs}
     ```

  4. Generate questions for all 8 categories:
     - Vision and Purpose (3-5 questions)
     - Technical Scope (5-7 questions)
     - Integration and Dependencies (4-6 questions)
     - Infrastructure Requirements (4-6 questions)
     - Security and Compliance (3-5 questions)
     - Success Criteria (3-5 questions)
     - Risks and Constraints (4-6 questions)
     - Operations and Maintenance (3-5 questions)

  **Verification:**
  - [ ] All 8 categories have questions generated
  - [ ] Total questions: 30-50 (comprehensive but not overwhelming)
  - [ ] Each question follows template format
  - [ ] Questions prioritized P0-P3
  - [ ] No duplicate questions across categories

  **STEP 3: Prioritize Questions by Dependency**
  Order questions by dependency - foundational questions must be answered before dependent questions:

  **Actions:**
  1. Identify foundational questions (no dependencies):
     - Vision and purpose questions (establish "why")
     - Scope boundary questions (establish "what")
     - Integration point identification (establish "with what")

  2. Identify dependent questions (require foundational answers):
     - Technical detail questions (depend on scope)
     - Resource sizing questions (depend on scale)
     - Security approach questions (depend on data sensitivity)

  3. Create dependency-ordered question list:
     - Phase 1: Foundational (answer first)
     - Phase 2: Core technical (answer second)
     - Phase 3: Implementation details (answer third)
     - Phase 4: Operations details (answer fourth)

  4. Mark dependency relationships:
     ```markdown
     **Q5: What scale/performance requirements exist?**
     - **Depends on:** Q2 (scope), Q3 (integration points)
     ```

  **Verification:**
  - [ ] Questions organized by dependency phases
  - [ ] Dependencies explicitly marked
  - [ ] Foundational questions answerable without other answers
  - [ ] Logical progression from high-level to detailed

  **STEP 4: Add Infrastructure Philosophy Context**
  Enhance questions with HX-Infrastructure-specific context to guide CAIO responses:

  **Actions:**
  1. Review `/home/agent0/HX-Infrastructure/constitution.md` for principles
  2. Review `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` for standards
  3. Add philosophy context to relevant questions:
     ```markdown
     **HX-Infrastructure Context:**
     Our infrastructure follows these principles:
     - Quality over speed (accuracy is job #1)
     - Test-driven deployment (100% coverage mandatory)
     - Documentation-first approach
     - Constitution-based governance
     
     Please consider these when answering.
     ```

  4. Add specific guidance for technical questions:
     - Reference layer architecture (7 layers)
     - Reference network zones (Identity, Model, Data, etc.)
     - Reference agent ecosystem (32 agents)
     - Reference existing nodes for integration patterns

  **Verification:**
  - [ ] Constitution principles referenced where relevant
  - [ ] Architecture standards context added
  - [ ] Existing infrastructure referenced for patterns
  - [ ] Philosophy guidance helps CAIO provide better answers

  **STEP 5: Generate Initial Questions Document**
  Create formal questions document for CAIO review:

  **Actions:**
  1. Create `/nodes/{node-name}/charter/questions-initial.md`
  2. Use standard template:
     ```markdown
     # Charter Initial Clarifying Questions
     **Node:** {node-name}
     **Phase:** Initial Questions (Pre-Research)
     **Generated:** {timestamp}
     **Total Questions:** {count}
     **Priority Breakdown:** {P0 count} critical, {P1 count} high, {P2 count} medium, {P3 count} low
     
     ---
     
     ## Purpose
     These questions clarify the charter vision, scope, and requirements before 
     conducting knowledge vault research. Answers will guide both research focus 
     and charter document creation.
     
     ## How to Answer
     - Answer P0 (critical) questions first
     - Be specific and concrete in responses
     - Reference existing infrastructure where applicable
     - Note any questions requiring research or experimentation
     - Flag any questions that reveal scope changes
     
     ---
     
     ## Questions by Category
     
     ### Category 1: Vision and Purpose
     {questions}
     
     ### Category 2: Technical Scope
     {questions}
     
     [Continue for all 8 categories]
     
     ---
     
     ## Question Dependency Map
     {Dependency diagram showing question relationships}
     
     ---
     
     ## Response Tracking
     - [ ] All P0 questions answered
     - [ ] All P1 questions answered
     - [ ] P2/P3 questions answered or deferred
     - [ ] Open questions identified for follow-up
     ```

  3. Review document for:
     - Clarity and readability
     - Logical organization
     - Complete information
     - Professional formatting

  **Verification:**
  - [ ] Document created in correct location
  - [ ] All questions included and organized
  - [ ] Template sections complete
  - [ ] Ready for CAIO review

  **STEP 6: Create Response Tracking Document**
  Set up companion document for tracking CAIO responses:

  **Actions:**
  1. Create `/nodes/{node-name}/charter/questions-initial-responses.md`
  2. Use response template:
     ```markdown
     # Charter Initial Questions - CAIO Responses
     **Node:** {node-name}
     **Response Session:** {timestamp}
     **Questions Answered:** 0 / {total}
     **Status:** In Progress
     
     ---
     
     ## Response Format
     For each question, provide:
     - Direct answer to the question
     - Additional context or rationale
     - Any caveats or open issues
     - References to existing docs/nodes if applicable
     
     ---
     
     ## Category 1: Vision and Purpose
     
     **Q1: {question}**
     **Response:** {CAIO answer here}
     **Answered:** {timestamp}
     **Status:** ✅ Complete | ⏳ Needs Follow-up | ❌ Blocked
     **Follow-up Actions:** {if any}
     
     [Continue for all questions]
     ```

  3. Create `/nodes/{node-name}/charter/questions-initial-tracking.md` for open questions:
     ```markdown
     # Open Questions Tracker - Initial Phase
     **Last Updated:** {timestamp}
     
     ## Critical Open Questions (P0)
     {List of unanswered P0 questions with blocking status}
     
     ## High Priority Open Questions (P1)
     {List of unanswered P1 questions}
     
     ## Deferred Questions (P2/P3)
     {List of questions deferred to later phases}
     
     ## Questions Requiring Research
     {List of questions that need knowledge vault research to answer}
     
     ## Questions Requiring Experimentation
     {List of questions that need POC or testing to answer}
     ```

  **Verification:**
  - [ ] Response document created
  - [ ] Tracking document created
  - [ ] Templates ready for CAIO use
  - [ ] Clear instructions provided

  **Outputs Generated:**
  - `/nodes/{node-name}/charter/questions-initial.md` (30-50 questions)
  - `/nodes/{node-name}/charter/questions-initial-responses.md` (response template)
  - `/nodes/{node-name}/charter/questions-initial-tracking.md` (open questions tracker)

  **Quality Validation:**
  Before presenting to CAIO, verify:
  - [ ] All 8 categories represented
  - [ ] Questions are specific and answerable
  - [ ] Priority levels assigned appropriately
  - [ ] Dependencies identified and ordered
  - [ ] HX-Infrastructure context included
  - [ ] Response documents ready
  </procedure>

  <procedure name="Generate Post-Research Clarifying Questions">
  **Purpose:** Generate targeted questions after knowledge vault research to address findings, gaps, and technical approach decisions

  **Prerequisites:**
  - Initial questions answered by CAIO
  - Knowledge vault research complete (Phase 4 of charter workflow)
  - Research findings documented in `/nodes/{node-name}/charter/reviews/knowledge-vault/*.md`
  - Initial questions responses reviewed

  **Inputs Required:**
  - Initial questions and responses
  - Knowledge vault research findings (all repository reviews)
  - Research confidence levels and gaps
  - Technical approaches discovered during research

  **Execution Steps:**

  **STEP 1: Analyze Research Findings for Gaps**
  Review all knowledge vault research to identify what was learned vs. what remains unclear:

  **Actions:**
  1. Read all research findings in `/nodes/{node-name}/charter/reviews/knowledge-vault/`
  2. For each repository reviewed:
     - What key information was found?
     - What confidence level was assigned?
     - What gaps or unknowns remain?
     - What competing approaches exist?

  3. Create research gap analysis:
     ```markdown
     # Research Gap Analysis
     
     ## High Confidence Areas (from research)
     - {Area}: {Summary of findings}
     - Confidence: High
     - Source: {repository}
     
     ## Medium Confidence Areas (from research)
     - {Area}: {Summary with gaps noted}
     - Confidence: Medium
     - Gaps: {What's still unclear}
     
     ## Low Confidence Areas (from research)
     - {Area}: {Limited findings}
     - Confidence: Low
     - Gaps: {Major unknowns}
     
     ## Competing Approaches Found
     - {Approach A} vs {Approach B}
     - Decision needed: {What CAIO must choose}
     
     ## Integration Patterns Discovered
     - {Pattern}: {Description}
     - Applicability: {How it might apply to this node}
     - Questions: {What needs clarification}
     ```

  4. Compare research findings against initial question responses:
     - Do findings support CAIO's stated preferences?
     - Do findings reveal better approaches than initially considered?
     - Do findings introduce new constraints or requirements?
     - Do findings change scope or integration points?

  **Verification:**
  - [ ] All research findings reviewed thoroughly
  - [ ] Gaps documented by confidence level
  - [ ] Competing approaches identified
  - [ ] Comparison with initial responses complete

  **STEP 2: Generate Technical Approach Questions**
  Create questions addressing technical decisions revealed by research:

  **Actions:**
  1. For each competing approach found in research, generate decision questions:
     ```markdown
     **Q{number}: Which approach should we use: {Approach A} or {Approach B}?**
     - **Category:** Technical Scope
     - **Context:** Research found both approaches viable:
       - {Approach A}: {Pros/cons from research}
       - {Approach B}: {Pros/cons from research}
     - **Decision Criteria:** {What factors matter most}
     - **Priority:** P0 (blocks charter finalization)
     - **Research Source:** {repository name}
     ```

  2. For each medium/low confidence area, generate clarification questions:
     ```markdown
     **Q{number}: How should we handle {uncertain aspect}?**
     - **Category:** {Appropriate category}
     - **Context:** Research provided limited guidance on {aspect}.
       Found: {What research showed}
       Unclear: {What remains unknown}
     - **Options:**
       1. {Option 1 from research}
       2. {Option 2 from research}
       3. {Custom approach}
     - **Priority:** P1
     - **Risk:** {What could go wrong without clarity}
     ```

  3. For integration patterns, generate validation questions:
     ```markdown
     **Q{number}: Should we adopt {integration pattern} for {purpose}?**
     - **Category:** Integration and Dependencies
     - **Context:** Research revealed {pattern} used by {existing nodes}.
       Benefits: {List benefits}
       Tradeoffs: {List costs}
     - **Alternative:** {Other approach if not using pattern}
     - **Priority:** P1
     - **Consistency:** {How this aligns with other nodes}
     ```

  **Verification:**
  - [ ] All competing approaches have decision questions
  - [ ] Medium/low confidence areas addressed
  - [ ] Integration patterns validated
  - [ ] Questions reference research sources

  **STEP 3: Generate Assumption Validation Questions**
  Create questions that validate assumptions made during initial questions or research:

  **Actions:**
  1. Review initial question responses for stated assumptions
  2. Review research findings for implied assumptions
  3. Generate validation questions:
     ```markdown
     **Q{number}: Can we confirm assumption: {assumption statement}?**
     - **Category:** Risks and Constraints
     - **Context:** 
       - Initial response assumed: {assumption}
       - Research suggests: {what research showed}
       - Validation needed: {why we must confirm}
     - **Impact if Wrong:** {Consequences of invalid assumption}
     - **Priority:** P0/P1 (based on impact)
     - **Validation Method:** {How to confirm - test, POC, consultation}
     ```

  4. Prioritize assumption validations by risk:
     - P0: Assumptions that would require major scope changes if wrong
     - P1: Assumptions that would require significant rework if wrong
     - P2: Assumptions that would require minor adjustments if wrong

  **Verification:**
  - [ ] All stated assumptions identified
  - [ ] Implied assumptions from research noted
  - [ ] Validation questions generated
  - [ ] Impact assessment complete

  **STEP 4: Generate Experimental Validation Questions**
  Identify areas requiring POC or testing to confirm feasibility:

  **Actions:**
  1. Review research for areas marked "requires testing" or "experimental"
  2. Generate experimental validation questions:
     ```markdown
     **Q{number}: Should we conduct POC for {capability}?**
     - **Category:** Technical Scope
     - **Context:** Research indicates {capability} is possible but untested in our environment.
       - Theoretical feasibility: {What docs/examples show}
       - Environment specifics: {Our unique constraints}
       - Risk if assumption wrong: {Impact}
     - **POC Scope:** {What to test}
     - **Success Criteria:** {How we know if feasible}
     - **Effort Estimate:** {Time/resources for POC}
     - **Priority:** P1
     - **Decision:** Proceed with POC before charter finalization, or accept risk and validate during implementation?
     ```

  3. For each experimental validation:
     - Define clear success criteria
     - Estimate effort required
     - Assess risk of proceeding without validation
     - Propose decision point (POC now vs. later)

  **Verification:**
  - [ ] All experimental areas identified
  - [ ] POC scopes defined
  - [ ] Success criteria specified
  - [ ] Risk/effort trade-offs documented

  **STEP 5: Generate Scope Refinement Questions**
  Address scope changes suggested by research findings:

  **Actions:**
  1. Identify scope expansions suggested by research:
     - New integration opportunities discovered
     - Additional capabilities that should be included
     - Dependencies that require broader scope

  2. Identify scope reductions suggested by research:
     - Originally planned features that are infeasible
     - Capabilities better provided by existing nodes
     - Dependencies that should be avoided

  3. Generate scope refinement questions:
     ```markdown
     **Q{number}: Should we expand scope to include {new capability}?**
     - **Category:** Technical Scope
     - **Context:** Research revealed {new capability} would be valuable:
       - Benefit: {Why this adds value}
       - Effort: {Additional work required}
       - Dependencies: {What else this requires}
     - **Decision:** Include in initial scope, defer to future enhancement, or exclude entirely?
     - **Priority:** P1
     - **Impact on Timeline:** {How this affects schedule}
     ```

  **Verification:**
  - [ ] Scope expansions identified and questioned
  - [ ] Scope reductions identified and questioned
  - [ ] Impact on timeline/resources assessed
  - [ ] Decision options clear

  **STEP 6: Generate Post-Research Questions Document**
  Create formal post-research questions document:

  **Actions:**
  1. Create `/nodes/{node-name}/charter/questions-post-research.md`
  2. Organize questions by type:
     - Technical Approach Decisions (from competing options)
     - Gap Clarifications (from medium/low confidence areas)
     - Assumption Validations (from stated/implied assumptions)
     - Experimental Validations (from untested capabilities)
     - Scope Refinements (from research-suggested changes)

  3. Use template:
     ```markdown
     # Charter Post-Research Clarifying Questions
     **Node:** {node-name}
     **Phase:** Post-Research Questions
     **Generated:** {timestamp}
     **Total Questions:** {count}
     **Priority Breakdown:** {P0 count} critical, {P1 count} high, {P2 count} medium
     
     ---
     
     ## Purpose
     These questions address findings, gaps, and decisions revealed during knowledge 
     vault research. Answers will finalize technical approach and complete charter.
     
     ## Research Context
     Reviewed {count} repositories:
     - High confidence findings: {summary}
     - Medium confidence findings: {summary}
     - Low confidence findings: {summary}
     - Competing approaches discovered: {count}
     
     ---
     
     ## Questions by Type
     
     ### Technical Approach Decisions
     {Questions addressing competing approaches}
     
     ### Gap Clarifications
     {Questions addressing research gaps}
     
     ### Assumption Validations
     {Questions validating assumptions}
     
     ### Experimental Validations
     {Questions about POCs/testing}
     
     ### Scope Refinements
     {Questions about scope changes}
     
     ---
     
     ## Integration with Initial Questions
     {Reference initial questions that are now informed by research}
     {Note any initial questions that research fully answered}
     {Note any initial questions that research changed}
     ```

  4. Cross-reference initial questions:
     - Which initial questions does research answer?
     - Which initial questions does research change?
     - Which initial questions remain unanswered?

  **Verification:**
  - [ ] Document created in correct location
  - [ ] Questions organized by type
  - [ ] Research findings referenced
  - [ ] Cross-reference to initial questions complete

  **STEP 7: Create Consolidated Q&A Document**
  Merge initial and post-research Q&A into single reference:

  **Actions:**
  1. Create `/nodes/{node-name}/charter/questions-consolidated.md`
  2. Include:
     - All initial questions and responses
     - All post-research questions and responses
     - Research findings summary
     - Decision rationale for key choices
     - Open questions requiring future follow-up

  3. Organize by charter section for easy reference during charter writing:
     ```markdown
     # Consolidated Charter Q&A Reference
     **Node:** {node-name}
     **Last Updated:** {timestamp}
     **Status:** Complete
     
     ---
     
     ## Section 1: Vision and Purpose
     {All Q&A relevant to vision section}
     {Research findings supporting vision}
     
     ## Section 2: Technical Overview
     {All Q&A relevant to technical overview}
     {Key technical decisions from post-research}
     
     [Continue for all charter sections]
     
     ---
     
     ## Open Questions for Future Phases
     {Questions deferred to specification phase}
     {Questions requiring implementation validation}
     
     ## Key Decisions Summary
     {Major technical approach decisions}
     {Scope decisions}
     {Integration approach decisions}
     ```

  **Verification:**
  - [ ] All Q&A consolidated
  - [ ] Organized by charter section
  - [ ] Research findings integrated
  - [ ] Ready for charter writing reference

  **Outputs Generated:**
  - `/nodes/{node-name}/charter/questions-post-research.md` (15-30 questions)
  - `/nodes/{node-name}/charter/questions-post-research-responses.md` (response template)
  - `/nodes/{node-name}/charter/questions-post-research-tracking.md` (open questions)
  - `/nodes/{node-name}/charter/questions-consolidated.md` (complete Q&A reference)

  **Quality Validation:**
  Before presenting to CAIO, verify:
  - [ ] Research findings thoroughly analyzed
  - [ ] All competing approaches have decision questions
  - [ ] All assumptions validated or questioned
  - [ ] Experimental validations identified
  - [ ] Scope refinements addressed
  - [ ] Consolidated reference ready for charter writing
  </procedure>
</question_generation_procedures>

<integration_convention>
**How Commands Invoke This Phase Command:**

This section documents how workflow commands (Set 1) invoke the charter questions phase command. Invocation occurs at two specific points in charter workflow with distinct contexts.

**From Charter Workflow (cc-charter-workflow.md):**
This phase command is called at two specific points:

**Call 1: Phase 2 - Initial Questions Generation**
```bash
# After parsing CAIO input, before knowledge vault research
cd /home/agent0/HX-Infrastructure
cat .claude/commands/phases/cc-phase-charter-questions.md

# Execute: Generate Initial Clarifying Questions
# Inputs: /nodes/{node-name}/charter/caio-input.md
# Outputs: questions-initial.md, questions-initial-responses.md, questions-initial-tracking.md
```

**Call 2: Phase 6 - Post-Research Questions Generation**
```bash
# After knowledge vault research complete, before charter generation
cd /home/agent0/HX-Infrastructure
cat .claude/commands/phases/cc-phase-charter-questions.md

# Execute: Generate Post-Research Clarifying Questions
# Inputs: research findings, initial Q&A, research gaps
# Outputs: questions-post-research.md, questions-consolidated.md
```

**Input Requirements:**

**For Initial Questions:**
- `/nodes/{node-name}/charter/caio-input.md` - CAIO brain dump
- `/nodes/{node-name}/charter/parsed-requirements.md` - Structured requirements
- `/nodes/{node-name}/charter/repository-list.md` - Identified repos for research
- `/home/agent0/HX-Infrastructure/constitution.md` - Infrastructure principles
- `/home/agent0/HX-Infrastructure/inventory/current-state.md` - Existing infrastructure

**For Post-Research Questions:**
- `/nodes/{node-name}/charter/questions-initial-responses.md` - Initial Q&A
- `/nodes/{node-name}/charter/reviews/knowledge-vault/*.md` - All research findings
- `/nodes/{node-name}/charter/research-summary.md` - Consolidated research
- Research confidence levels and gaps identified

**Output Specifications:**

**Initial Questions Document:**
```markdown
Format: Markdown with semantic structure
Location: /nodes/{node-name}/charter/questions-initial.md
Structure:
  - Metadata header (node, phase, timestamp, counts)
  - Purpose statement
  - Instructions for CAIO
  - Questions organized by 8 categories
  - Each question includes: text, category, context, priority, charter section
  - Dependency map
  - Response tracking checklist
Size: Typically 30-50 questions (3-5 per category)
```

**Post-Research Questions Document:**
```markdown
Format: Markdown with semantic structure
Location: /nodes/{node-name}/charter/questions-post-research.md
Structure:
  - Metadata header
  - Research context summary
  - Questions organized by type (not category)
    * Technical approach decisions
    * Gap clarifications
    * Assumption validations
    * Experimental validations
    * Scope refinements
  - Integration with initial questions
  - POC/testing recommendations
Size: Typically 15-30 questions
```

**Consolidated Q&A Document:**
```markdown
Format: Markdown with semantic structure
Location: /nodes/{node-name}/charter/questions-consolidated.md
Structure:
  - All initial Q&A
  - All post-research Q&A
  - Organized by charter section (not by phase)
  - Research findings integrated
  - Key decisions summarized
  - Open questions for future phases
Purpose: Single reference for charter writing
```

**File Organization:**
```
/nodes/{node-name}/charter/
├── caio-input.md
├── parsed-requirements.md
├── repository-list.md
├── questions-initial.md
├── questions-initial-responses.md
├── questions-initial-tracking.md
├── questions-post-research.md
├── questions-post-research-responses.md
├── questions-post-research-tracking.md
├── questions-consolidated.md              # ← Reference for charter writing
└── reviews/
    └── knowledge-vault/
        ├── repo-1-review.md
        └── repo-2-review.md
```

**State Management:**
- Questions documents are stateful artifacts (persist throughout project)
- Question responses are stateful artifacts (historical record)
- Consolidated Q&A is stateful artifact (charter reference)
- This command file is stateless (reusable instructions)

**Error Handling:**

**If CAIO input is incomplete:**
- Generate questions focusing on missing foundational information
- Flag gaps prominently in questions document
- Recommend CAIO provide additional input before proceeding

**If research findings are insufficient:**
- Generate questions identifying specific research gaps
- Recommend additional repositories to review
- Flag areas requiring experimental validation

**If questions reveal major scope changes:**
- Document scope change implications
- Generate questions about timeline/resource impact
- Recommend formal scope change approval before proceeding

**Integration with Other Commands:**

**Used by:** cc-charter-workflow.md (Phase 2 and Phase 6)
**Uses:** None (standalone question generation)
**Outputs used by:**
- Charter generation (Phase 8 of charter workflow)
- Specification phase (reference for technical details)
- Task breakdown (reference for implementation decisions)

**Workflow Context:**
```
Charter Workflow Phase Sequence:
Phase 0: CAIO Input
Phase 1: Parse Requirements
Phase 2: Generate Initial Questions ← This command (Call 1)
Phase 3: CAIO Answers Initial Questions
Phase 4: Knowledge Vault Research
Phase 5: Research Analysis
Phase 6: Generate Post-Research Questions ← This command (Call 2)
Phase 7: CAIO Answers Post-Research Questions
Phase 8: Generate Charter (using consolidated Q&A)
Phase 9: Charter Review and Approval
```
</integration_convention>

<usage_examples>
  <example name="Initial Questions for New MCP Server Node">
  **Scenario:** CAIO wants to deploy new MCP server for specialized tool integration

  **CAIO Input Summary:**
  - Purpose: Provide specialized tools for Claude Code via MCP protocol
  - Tools needed: Custom database queries, report generation, data transformation
  - Integration: Must work with existing Open WebUI and Claude Code instances

  **Initial Questions Generated (Sample):**

  **Category: Vision and Purpose**
  - Q1: What specific problem do users face that this MCP server solves that existing tools don't?
  - Q2: Why can't these tools be added to existing MCP servers?
  - Q3: What's the expected usage frequency - occasional or continuous?

  **Category: Technical Scope**
  - Q4: What programming language should the MCP server be implemented in?
  - Q5: How many total tools are planned (initial + future)?
  - Q6: What's the complexity level of each tool (simple queries vs. complex processing)?
  - Q7: Are there any real-time or streaming requirements?

  **Category: Integration and Dependencies**
  - Q8: Which database instances will the query tools access?
  - Q9: Does this need to integrate with n8n workflows?
  - Q10: What authentication method should be used (service account, user delegation)?

  **Category: Infrastructure Requirements**
  - Q11: Can this run on same host as existing MCP server, or needs dedicated VM?
  - Q12: What's the expected memory footprint per tool execution?
  - Q13: Any GPU requirements for data transformation tools?

  **Category: Security and Compliance**
  - Q14: What's the data sensitivity level of query results?
  - Q15: Should query results be logged/audited?
  - Q16: Any PII or sensitive data handling requirements?

  **Category: Success Criteria**
  - Q17: What's the acceptable response time for tool executions?
  - Q18: What's the acceptable uptime requirement?
  - Q19: How will tool correctness be validated?

  **Total:** 30 initial questions across all categories, with P0 questions (Q1-Q4, Q8, Q10, Q14) marked as critical.

  **CAIO Response Example (Q4):**
  ```markdown
  **Q4: What programming language should the MCP server be implemented in?**
  **Response:** Python, to match existing MCP servers and leverage existing team expertise. 
  We have TypeScript MCP servers too, but Python is preferred for data transformation tools 
  due to pandas/numpy ecosystem.
  **Answered:** 2025-11-20 14:30
  **Status:** ✅ Complete
  ```

  **Post-Research Questions Generated (Sample):**

  After researching MCP protocol documentation and existing server implementations:

  - Q31: Should we use the official MCP Python SDK or implement protocol directly?
    * Research found SDK provides automatic validation and standard error handling
    * Trade-off: SDK adds dependency but reduces custom protocol code
    * **Decision needed:** Use SDK vs custom implementation

  - Q32: Research shows most MCP servers are stateless. Should ours maintain query history/cache?
    * Stateless: Simpler, matches pattern, no persistence needed
    * Stateful: Better performance for repeated queries, requires Redis
    * **Decision needed:** Stateless vs stateful design

  - Q33: Research gap: No examples found of MCP tools accessing multiple databases. How should we handle multiple DB connections?
    * Option 1: Single connection pool, pass DB name as tool parameter
    * Option 2: Separate tools per database
    * Option 3: Dynamic connection based on query context
    * **Decision needed:** Multi-database connection strategy

  **Consolidated Q&A Usage:**
  When generating charter, writer references consolidated Q&A:
  - Section "Technical Overview" uses Q4 response (Python), Q32 decision (stateless)
  - Section "Integration Points" uses Q8-Q10 responses (database access, auth)
  - Section "Success Criteria" uses Q17-Q19 responses (performance, uptime, validation)
  </example>

  <example name="Post-Research Questions Revealing Scope Change">
  **Scenario:** Research reveals initial scope needs expansion for proper integration

  **Initial Scope:** Deploy single-purpose document processing server
  **Research Finding:** Document processing requires preprocessing pipeline not in original scope

  **Post-Research Questions Generated:**

  **Q25: Should we expand scope to include document preprocessing pipeline?**
  - **Category:** Technical Scope
  - **Context:** Research of docling and similar tools revealed successful document processing requires:
    * OCR for scanned documents
    * Format normalization (PDF, DOCX, images → standard format)
    * Text extraction and cleaning
    * Metadata extraction
    Initial scope only included main processing, not preprocessing.
  - **Scope Impact:**
    * Additional components: OCR engine (Tesseract), format converters
    * Additional infrastructure: Image processing requires 2-4GB extra RAM
    * Additional complexity: Pipeline coordination, error handling for each stage
  - **Options:**
    1. Expand scope to include preprocessing (adds ~30% to timeline)
    2. Rely on external preprocessing (requires integration with external service)
    3. Defer preprocessing to Phase 2 (accept limited document format support initially)
  - **Priority:** P0 (blocks charter finalization - impacts architecture decisions)
  - **Decision:** ?

  **CAIO Response:**
  ```markdown
  **Decision:** Option 1 - Expand scope to include preprocessing pipeline

  **Rationale:** 
  - External service integration (Option 2) creates dependency we can't control
  - Limited format support (Option 3) defeats business purpose
  - 30% timeline increase is acceptable given importance of complete solution

  **Implications:**
  - Update infrastructure requirements: 4GB RAM → 8GB RAM
  - Add to charter: OCR engine, format converters, pipeline orchestration
  - Add to success criteria: Support for PDF, DOCX, images, scanned documents
  - Update timeline: 3 weeks → 4 weeks for implementation phase

  **Follow-up Actions:**
  - Update initial Q11 response (infrastructure requirements)
  - Generate additional questions about OCR engine selection
  - Update repository list to include OCR integration research
  ```

  **Result:** Charter scope expanded appropriately, based on research findings, before charter finalization. Avoided discovering scope gap during implementation when change would be more costly.
  </example>

  <example name="Assumption Validation Revealing Risk">
  **Scenario:** Post-research question validates critical assumption, reveals risk

  **Initial Assumption:** Vector database (Qdrant) can handle real-time semantic search at required scale
  **Research Finding:** Examples found are for smaller scale than our requirements

  **Post-Research Question Generated:**

  **Q28: Can we confirm assumption: Qdrant can handle 10K queries/minute with sub-100ms latency?**
  - **Category:** Risks and Constraints
  - **Context:**
    * Initial response (Q18) assumed: "Vector search will be fast enough for real-time"
    * Research revealed: Most examples show 100-1000 queries/minute
    * Our requirement: 10,000 queries/minute during peak
    * Latency requirement: < 100ms p95
  - **Risk if Assumption Wrong:**
    * Architecture inadequate for production load
    * May require horizontal scaling not in initial design
    * May require caching layer not budgeted
    * Timeline impact: 2-3 weeks for redesign
  - **Validation Method:**
    * Load testing POC with production-scale data
    * Requires: 1 week effort, production data sample, load generation tool
  - **Priority:** P0 (architecture decision depends on this)
  - **Decision:** Proceed with POC before charter finalization, or accept risk?

  **CAIO Response:**
  ```markdown
  **Decision:** Proceed with POC before finalizing charter

  **Rationale:**
  - Risk too high to proceed on assumption
  - 1 week delay is acceptable vs 3 week redesign if wrong
  - Load testing infrastructure will be needed anyway for validation

  **POC Scope:**
  - Generate 1M test vectors matching production embedding dimensions
  - Simulate 10K queries/minute for 5 minutes
  - Measure p50, p95, p99 latencies
  - Monitor resource utilization (CPU, RAM, disk I/O)

  **Success Criteria:**
  - p95 latency < 100ms: Proceed with current architecture
  - p95 latency 100-200ms: Add caching layer to design
  - p95 latency > 200ms: Redesign for horizontal scaling

  **Timeline Impact:**
  - Charter finalization delayed 1 week for POC
  - Acceptable trade-off for architecture confidence
  ```

  **Result:** POC conducted, revealed p95 latency of 150ms. Charter updated to include Redis caching layer. Avoided production performance issues discovered too late.
  </example>
</usage_examples>

<critical_reminders>
⚠️ **Question Quality Over Quantity:** Generate 30-50 well-crafted initial questions, not 100 vague ones. Each question should be specific, answerable, and directly inform charter content.

⚠️ **Infrastructure Philosophy Context:** Always include HX-Infrastructure principles context (quality-first, TDD, documentation-first) to guide CAIO responses appropriately.

⚠️ **Dependency-Ordered Questions:** Structure questions by dependency - foundational questions must be answerable without other answers. Mark dependencies explicitly.

⚠️ **Research Integration:** Post-research questions must reference specific research findings. Don't generate generic questions disconnected from what was learned.

⚠️ **Assumption Validation:** Every assumption in initial responses or research must have explicit validation question. Hidden assumptions cause downstream failures.

⚠️ **Competing Approaches:** When research reveals multiple viable approaches, generate clear decision questions with pros/cons from research. Don't let CAIO guess.

⚠️ **Scope Change Visibility:** When questions reveal scope changes, make impact explicit (timeline, resources, dependencies). Don't hide scope creep in subtle questions.

⚠️ **Experimental Validation:** When research shows "theoretically possible but untested," generate explicit POC questions with effort/risk trade-offs. Don't assume it will work.

⚠️ **Consolidated Reference:** The consolidated Q&A document is the single source of truth for charter writing. Keep it organized by charter section, not question generation phase.

⚠️ **Priority Enforcement:** P0 questions must be answered before proceeding. Don't let CAIO skip critical questions or accept "we'll figure it out later" for foundational decisions.

⚠️ **Cross-Phase Utility:** Questions and responses persist throughout project lifecycle. They inform specification, task breakdown, and implementation. Don't treat them as disposable.

⚠️ **Response Tracking:** Maintain open questions tracker continuously. Don't lose track of deferred or partially-answered questions.
</critical_reminders>

<validation_checklists>
  <checklist name="Initial Questions Generation Validation">
  **Before presenting initial questions to CAIO:**

  **Coverage Validation:**
  - [ ] All 8 standard categories have questions (3-7 per category)
  - [ ] Total questions: 30-50 (comprehensive but not overwhelming)
  - [ ] Vision and purpose questions establish "why"
  - [ ] Technical scope questions establish "what"
  - [ ] Integration questions establish "with what"
  - [ ] Infrastructure questions establish resource needs
  - [ ] Security questions establish compliance needs
  - [ ] Success criteria questions establish "done" definition

  **Question Quality Validation:**
  - [ ] Each question is specific and answerable with concrete information
  - [ ] Each question has context explaining why it's being asked
  - [ ] Each question relates to specific charter section it will inform
  - [ ] No duplicate questions across categories
  - [ ] Questions avoid being too broad or too narrow
  - [ ] Questions don't lead CAIO to specific answers

  **Priority and Dependency Validation:**
  - [ ] P0 questions identified (10-15 critical questions)
  - [ ] P1 questions identified (15-20 high priority questions)
  - [ ] P2/P3 questions identified (5-15 medium/low questions)
  - [ ] Foundational questions answerable without other answers
  - [ ] Dependent questions have dependencies marked
  - [ ] Questions ordered by dependency phases

  **Infrastructure Context Validation:**
  - [ ] HX-Infrastructure principles referenced where relevant
  - [ ] Architecture standards context provided
  - [ ] Existing infrastructure referenced for patterns
  - [ ] Philosophy guidance helps CAIO provide better answers
  - [ ] Layer architecture (7 layers) referenced where applicable
  - [ ] Network zones referenced where applicable

  **Document Quality Validation:**
  - [ ] Document created in `/nodes/{node-name}/charter/questions-initial.md`
  - [ ] Template structure complete (metadata, purpose, categories, tracking)
  - [ ] Response document created with clear instructions
  - [ ] Tracking document created for open questions
  - [ ] Professional formatting and clear readability
  - [ ] Ready for CAIO review without additional explanation
  </checklist>

  <checklist name="Post-Research Questions Generation Validation">
  **Before presenting post-research questions to CAIO:**

  **Research Analysis Validation:**
  - [ ] All research findings reviewed thoroughly
  - [ ] Research gaps documented by confidence level (high/medium/low)
  - [ ] Competing approaches identified with pros/cons
  - [ ] Integration patterns discovered and documented
  - [ ] Comparison with initial responses complete
  - [ ] Research sources cited in questions

  **Question Type Coverage:**
  - [ ] Technical approach decision questions (for competing options)
  - [ ] Gap clarification questions (for medium/low confidence areas)
  - [ ] Assumption validation questions (for stated/implied assumptions)
  - [ ] Experimental validation questions (for untested capabilities)
  - [ ] Scope refinement questions (for research-suggested changes)

  **Decision Support Validation:**
  - [ ] Each competing approach has clear pros/cons from research
  - [ ] Each decision question has 2-3 specific options
  - [ ] Decision criteria explained (what factors matter)
  - [ ] Impact of decisions documented (timeline, resources, risk)
  - [ ] POC recommendations include scope, effort, success criteria

  **Assumption Validation Quality:**
  - [ ] All stated assumptions from initial responses identified
  - [ ] All implied assumptions from research identified
  - [ ] Validation questions show "if wrong" impact
  - [ ] Validation methods proposed (POC, testing, consultation)
  - [ ] Priority reflects risk level

  **Scope Change Handling:**
  - [ ] Scope expansions identified with benefits/costs
  - [ ] Scope reductions identified with rationale
  - [ ] Timeline/resource impacts calculated
  - [ ] Decision options clear (include, defer, exclude)
  - [ ] CAIO won't be surprised by scope implications

  **Integration with Initial Questions:**
  - [ ] Cross-references to initial questions that research answered
  - [ ] Cross-references to initial questions that research changed
  - [ ] Open initial questions flagged for continued follow-up
  - [ ] Consolidated Q&A organized by charter section (not phase)
  - [ ] Ready for charter writing reference
  </checklist>

  <checklist name="Consolidated Q&A Validation">
  **Before charter generation begins:**

  **Completeness Validation:**
  - [ ] All initial questions and responses included
  - [ ] All post-research questions and responses included
  - [ ] Research findings summary included
  - [ ] Key decisions documented with rationale
  - [ ] Open questions identified for future phases

  **Organization Validation:**
  - [ ] Q&A organized by charter section (not by question phase)
  - [ ] Each charter section has relevant Q&A grouped together
  - [ ] Research findings integrated with related Q&A
  - [ ] Decision rationale visible for key technical choices
  - [ ] Easy to reference during charter writing

  **Charter Readiness Validation:**
  - [ ] All P0 questions answered
  - [ ] All P1 questions answered or explicitly deferred
  - [ ] Critical assumptions validated or marked as accepted risk
  - [ ] Competing approaches decided with documented rationale
  - [ ] Scope finalized (expansions/reductions decided)
  - [ ] POC requirements completed or explicitly deferred

  **Future Phase Handoff:**
  - [ ] Questions deferred to specification phase documented
  - [ ] Questions requiring implementation validation documented
  - [ ] Experimental validations planned for task phase documented
  - [ ] Clear handoff to next workflow phase
  </checklist>

  <checklist name="Question Response Tracking Validation">
  **Ongoing throughout question/answer process:**

  **Response Status Tracking:**
  - [ ] Each question marked with status (Complete, Needs Follow-up, Blocked)
  - [ ] Answer timestamps recorded
  - [ ] Follow-up actions documented
  - [ ] Blocking issues escalated to CAIO
  - [ ] Progress visible (X of Y questions answered)

  **Open Questions Management:**
  - [ ] Critical open questions (P0) tracked prominently
  - [ ] High priority open questions (P1) tracked
  - [ ] Deferred questions (P2/P3) tracked with reason
  - [ ] Questions requiring research tracked
  - [ ] Questions requiring experimentation tracked

  **Response Quality Validation:**
  - [ ] Responses are specific and concrete (not vague)
  - [ ] Responses address the actual question asked
  - [ ] Responses include rationale/context
  - [ ] Responses note any caveats or open issues
  - [ ] Responses reference existing docs/nodes when applicable

  **Follow-up Tracking:**
  - [ ] Responses requiring clarification flagged
  - [ ] Responses revealing new questions captured
  - [ ] Responses suggesting scope changes documented
  - [ ] Responses invalidating assumptions escalated
  - [ ] Responses requiring POC tracked with status
  </checklist>
</validation_checklists>

<related_documents>
**Workflows:**
- [Charter Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md) - Calls this command in Phase 2 and Phase 6
- [Specification Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md) - Uses consolidated Q&A as input
- [Task Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md) - References decisions from Q&A

**Templates:**
- [Charter Template](/home/agent0/HX-Infrastructure/templates/charter-template.md) - Charter sections informed by questions
- [Charter Questions Template](/home/agent0/HX-Infrastructure/templates/charter-questions-template.md) - Original template (pre-command)
- [Knowledge Vault Research Template](/home/agent0/HX-Infrastructure/templates/knowledge-vault-research-template.md) - Research that informs post-research questions

**Standards:**
- [Documentation Requirements](/home/agent0/HX-Infrastructure/standards/documentation-requirements.md) - Question document formatting
- [Naming Conventions](/home/agent0/HX-Infrastructure/standards/naming-conventions.md) - Question file naming

**Reference:**
- [Constitution](/home/agent0/HX-Infrastructure/constitution.md) - Infrastructure principles to include in questions
- [Architecture Standards](/home/agent0/HX-Infrastructure/standards/architecture-standards.md) - Technical context for questions
- [HX Knowledge Vault Catalog](/home/agent0/HX-Infrastructure/hx-agents/hx-knowledge-vault-catalog.md) - Repositories for research

**Utilities:**
- [Documentation Linting](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-doc-lint.md) - Validate question document quality
- [Artifact Tracking](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md) - Track question documents as artifacts

**Process:**
- [Context Loading Process](/home/agent0/HX-Infrastructure/procedures/context-loading-process.md) - Loading context for question generation
</related_documents>

---

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready
**Compliance:** Gold Standard v1.1 - All 11 required elements present
**Integration:** Ready for charter workflow Phase 2 and Phase 6 execution
**State:** Stateless command generating stateful question artifacts
**Last Review:** 2025-11-20
**Update:** Standardized integration convention header, added infrastructure-specific question examples for HX-Infrastructure deployment philosophy
**Infrastructure Philosophy:** Includes explicit bare metal, systemd, manual procedure, Ansible Vault, Docker dev-only question examples
</metadata_footer>
