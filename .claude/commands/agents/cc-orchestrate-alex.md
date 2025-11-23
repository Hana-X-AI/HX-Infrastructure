---
workflow: orchestrate-alex
version: 1.0
date: 2025-11-20
status: APPROVED
type: workflow-command
description: Orchestration patterns for coordinating development and architecture work with Alex (Platform Architect)
applies_to: development_tasks, architectural_decisions, multi_layer_changes
author: HX-Infrastructure Team
---

<metadata>
**Workflow:** Alex Orchestration - Development & Architecture Coordination
**Version:** 1.0
**Date:** 2025-11-20
**Status:** APPROVED - Ready for use
**Type:** Agent Orchestration Command
**Agent:** Alex Rivera (Platform Architect)
**Purpose:** Define how agent0 coordinates WITH Alex for development and architectural work
</metadata>

<objective>
**Purpose:** Provide systematic orchestration patterns for agent0 to coordinate development and architecture work with Alex (Platform Architect), ensuring proper context preparation, effective handoffs, quality validation, and integration of architectural guidance.

**What This Achieves:**
- Clear decision criteria for when to invoke Alex vs. work autonomously
- Systematic context preparation that enables Alex to provide quality architectural guidance
- Structured handoff protocols that maximize Alex's effectiveness
- Quality validation patterns for architectural decisions and implementations
- Integration workflows that incorporate Alex's guidance into broader project work
- Conflict resolution and escalation paths when architectural issues arise

**When to Use This Command:**
- Making changes that affect multiple architecture layers (Identity & Trust, Model & Inference, Data Plane, Agentic & Toolchain, Application, Integration & Governance)
- Adding new infrastructure components or services to the platform
- Resolving architectural conflicts between services or agents
- Validating designs against agentic patterns and governance standards
- Creating Architecture Decision Records (ADRs)
- Planning major platform evolution or capability additions
- Coordinating multi-agent deployments with architectural implications

**When NOT to Use:**
- Simple single-service changes with no cross-layer impact
- Routine operational tasks within established patterns
- Documentation updates that don't change architecture
- Bug fixes that don't affect architectural decisions
</objective>

<workflow_overview>
**High-Level Orchestration Flow:**

```
Decision Point: Do we need Alex?
  → YES: Context Preparation
  → Alex Invocation & Handoff
  → Alex Works Independently (agent0 monitors)
  → Output Validation
  → Integration & Documentation
  → Follow-up Actions
  → NO: Agent0 proceeds autonomously (document decision)
```

**Duration:** 30 minutes - 3 hours (depends on complexity)
**Participants:** Agent0 (orchestrator), Alex (platform architect), CAIO (approvals)
**Primary Output:** Architectural guidance integrated into project work
**Secondary Outputs:** ADRs, updated architecture documentation, implementation plans
</workflow_overview>

<phases>

<phase id="0" name="Decision Point - Do We Need Alex?" gate="alex_invocation_decision">
<description>
Agent0 evaluates whether the current task requires Alex's architectural expertise or can be handled autonomously. This gate prevents unnecessary handoffs while ensuring complex architectural decisions receive proper expert review.
</description>

<inputs>
- Current task description
- Scope of changes
- Affected systems and layers
- Known architectural constraints
- Previous similar decisions
</inputs>

<actions>
**Evaluate Against Invocation Criteria:**

**MUST Invoke Alex When:**
- Changes affect 2+ architecture layers
- New services/components being added to platform
- Security zone boundaries are involved
- Multi-agent coordination required
- Architectural patterns are unclear
- Cross-service integration needs design
- Network topology changes
- ADR creation needed for significant decision
- Conflicts with existing architecture suspected
- Performance/scalability implications

**MAY Invoke Alex When:**
- Implementation approach has multiple valid options
- Governance alignment needs verification
- Pattern selection is uncertain
- Proactive architectural review would add value
- Learning opportunity for agent0

**DO NOT Invoke Alex When:**
- Simple single-service change within established patterns
- Routine operational tasks
- Documentation-only updates
- Bug fixes with no architectural impact
- Following existing ADRs with clear guidance
- Trivial configuration changes

**Decision Framework:**
1. Does this change affect multiple layers? → YES = Invoke Alex
2. Are we adding new platform components? → YES = Invoke Alex
3. Is architectural pattern unclear? → YES = Invoke Alex
4. Is this within established patterns? → YES = Consider autonomous work
5. Would architectural review prevent future issues? → YES = Consider invoking Alex
</actions>

<outputs>
- **Decision:** Invoke Alex OR Proceed Autonomously
- **Rationale:** Brief explanation of decision
- **Documentation:** If autonomous, document why Alex not needed
</outputs>

<quality_gate>
**Gate:** Alex Invocation Decision Made
**Criteria:**
- Decision made using framework above
- Rationale documented
- If autonomous: Confidence level is high
- If invoking Alex: Scope clearly defined

**Pass:** Proceed to Phase 1 (if invoking) or autonomous work (if not)
**Fail:** Gather more information, clarify scope, consult CAIO if uncertain
</quality_gate>

<duration>5-10 minutes</duration>

<example>
**Scenario 1: New Qdrant Vector Database Deployment**
- Evaluation: New Data Plane component, security zone assignment needed, integration with multiple services
- Decision: INVOKE ALEX
- Rationale: Multi-layer impact, new platform component, security zone decision

**Scenario 2: Update Ollama Model Configuration**
- Evaluation: Single service change, established pattern, no architectural impact
- Decision: PROCEED AUTONOMOUSLY
- Rationale: Routine configuration within existing architecture

**Scenario 3: API Gateway Authentication Middleware**
- Evaluation: Security implications, cross-service impact, integration pattern needed
- Decision: INVOKE ALEX (proactive review)
- Rationale: Security-sensitive change affecting multiple services
</example>
</phase>

<phase id="1" name="Context Preparation" gate="context_complete">
<description>
Agent0 prepares comprehensive context for Alex to enable effective architectural guidance. Quality context preparation directly impacts the quality and speed of Alex's recommendations.
</description>

<inputs>
- Task requirements
- Affected systems
- Current architecture state
- Related repositories
- Known constraints
</inputs>

<actions>
**Gather Context Documents:**

**Architecture Documents (Load from project knowledge):**
- `/home/agent0/HX-Infrastructure/docs/architecture/0.3-architecture.md` - Current architecture overview
- `/home/agent0/HX-Infrastructure/docs/architecture/0.3.1-network-topology.md` - Network topology and security zones
- `/home/agent0/HX-Infrastructure/docs/architecture/0.5-traceability-matrix.md` - Cross-dependencies

**Governance Standards:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance principles
- `/home/agent0/HX-Infrastructure/docs/governance/0.4-deployment-methodology.md` - Deployment phases

**Related Infrastructure:**
- Identify affected nodes from `/home/agent0/HX-Infrastructure/docs/architecture/0.2-platform-nodes.md`
- Review existing services and their configurations
- Check credential management requirements

**Knowledge Vault Research:**
- Load relevant repositories from `/srv/knowledge/vault/agentic-design-patterns-docs-main/`
- Research similar patterns or implementations
- Identify potential integration points

**Prepare Structured Context Brief:**
```markdown
**Architectural Context for Alex**

**Task:** [One-line summary]

**Scope:**
- Primary objective
- Affected layers: [List]
- Affected services: [List with FQDNs]
- Security zones involved: [List]

**Current State:**
- Existing architecture relevant to this task
- Current network topology
- Existing patterns in use

**Requirements:**
- Functional requirements
- Non-functional requirements (performance, security, etc.)
- Integration requirements
- Compliance/governance constraints

**Constraints:**
- Technical constraints
- Timeline constraints
- Resource constraints

**Questions for Alex:**
1. [Specific architectural question]
2. [Integration pattern question]
3. [Validation approach question]

**Desired Outputs:**
- Architectural recommendation
- Implementation approach
- Integration plan
- Validation criteria
- [ADR if significant decision]
```
</actions>

<outputs>
- Comprehensive context brief for Alex
- Loaded architecture and governance documents
- Specific questions for Alex
- Clear scope of architectural decision needed
</outputs>

<quality_gate>
**Gate:** Context Complete
**Criteria:**
- All required architecture documents loaded
- Affected systems clearly identified
- Specific questions formulated
- Constraints documented
- Context brief is complete and clear

**Pass:** Context is comprehensive and clear - ready for Alex
**Fail:** Gather missing information, clarify scope, refine questions
</quality_gate>

<duration>15-30 minutes</duration>

<rationale>
Alex's effectiveness depends on having complete context. Incomplete context leads to generic advice, missed constraints, or recommendations that don't fit HX-Infrastructure reality. Time invested in context preparation pays dividends in quality guidance.
</rationale>
</phase>

<phase id="2" name="Alex Invocation & Handoff" gate="handoff_complete">
<description>
Agent0 invokes Alex using structured handoff that provides all necessary context and clearly defines the architectural guidance needed. The handoff structure determines Alex's response quality.
</description>

<actions>
**Invoke Alex with Structured Request:**

```
@agent-alex

I need architectural guidance for [task name].

**CONTEXT:**
[Paste context brief from Phase 1]

**ARCHITECTURE LAYERS AFFECTED:**
- [Layer 1]: [Impact description]
- [Layer 2]: [Impact description]

**SPECIFIC QUESTIONS:**
1. [Question 1]
2. [Question 2]
3. [Question 3]

**DESIRED OUTPUTS:**
- Architectural recommendation with pattern references
- Integration approach with specific FQDNs/IPs
- Implementation sequence per Deployment Methodology
- Validation criteria
- Documentation updates needed
[- ADR for significant decision]

**CONSTRAINTS:**
- [Constraint 1]
- [Constraint 2]

Please consult your knowledge sources (/srv/knowledge/vault/agentic-design-patterns-docs-main and /srv/cc/Governance/) and provide architecture-grounded recommendations.
```

**Monitor Handoff:**
- Confirm Alex acknowledges request
- Verify Alex indicates knowledge source consultation
- Note if Alex requests clarification (provide immediately)
</actions>

<outputs>
- Alex invoked with complete context
- Handoff acknowledged
- Alex begins architectural analysis
</outputs>

<quality_gate>
**Gate:** Handoff Complete
**Criteria:**
- Alex invoked successfully
- Context provided comprehensively
- Questions clearly stated
- Desired outputs specified
- Alex acknowledged and began work

**Pass:** Alex working on architectural guidance
**Fail:** Clarify request, provide missing context, re-invoke if needed
</quality_gate>

<duration>5-10 minutes</duration>
</phase>

<phase id="3" name="Alex Works Independently" gate="none">
<description>
Alex conducts architectural analysis, consults knowledge sources, evaluates patterns, and prepares recommendations. Agent0 monitors but does not interrupt this phase.
</description>

<actions>
**Agent0 Monitoring (Non-Intrusive):**
- Observe Alex's analysis approach
- Note knowledge sources Alex references
- Watch for requests for additional context
- Prepare to answer follow-up questions
- DO NOT interrupt Alex's work

**If Alex Requests Additional Context:**
- Provide immediately and clearly
- Ensure additional context is complete
- Confirm Alex has what's needed

**Learning Opportunity:**
- Observe Alex's architectural reasoning
- Note patterns Alex applies
- Understand governance alignment checks
- Build agent0 architectural knowledge
</actions>

<outputs>
- Alex completes architectural analysis
- Alex prepares recommendation
- (Agent0 gains architectural knowledge)
</outputs>

<duration>15-45 minutes (variable based on complexity)</duration>

<note type="best_practice">
**Do Not Rush Alex:** Quality architectural guidance requires time for Alex to:
- Review multiple knowledge sources
- Evaluate pattern options
- Consider cross-layer impacts
- Validate governance alignment
- Prepare comprehensive recommendations

Rushing this phase produces superficial guidance that may cause issues later.
</note>
</phase>

<phase id="4" name="Output Validation" gate="architectural_guidance_validated">
<description>
Agent0 validates Alex's architectural guidance for completeness, clarity, applicability, and alignment with project needs. This gate ensures agent0 understands and can act on Alex's recommendations.
</description>

<inputs>
- Alex's architectural recommendation
- Expected outputs from Phase 2
- Project requirements
- Constraints and criteria
</inputs>

<actions>
**Validate Against Expected Outputs:**

**Check for Completeness:**
- [ ] Architectural recommendation present with pattern references
- [ ] Integration approach specified with FQDNs/IPs
- [ ] Implementation sequence defined per Deployment Methodology phases
- [ ] Validation criteria clear and testable
- [ ] Documentation updates identified
- [ ] ADR provided (if significant decision)

**Check for Clarity:**
- [ ] Recommendation is specific (not generic)
- [ ] Rationale explains WHY this approach
- [ ] Examples reference actual HX-Infrastructure context
- [ ] Integration points clearly identified
- [ ] Coordination requirements specified

**Check for Applicability:**
- [ ] Addresses all questions from Phase 2
- [ ] Fits within stated constraints
- [ ] Aligns with HX-Infrastructure capabilities
- [ ] Respects security zone boundaries
- [ ] Considers existing architecture

**Check for Governance Alignment:**
- [ ] Constitution principles referenced
- [ ] Deployment methodology phases followed
- [ ] Architecture layer separation maintained
- [ ] Credential management standards followed
- [ ] Documentation standards met

**If Validation Issues Found:**
1. Ask Alex for clarification on specific points
2. Request additional detail where needed
3. Confirm understanding of complex recommendations
4. Resolve any ambiguities before proceeding
</actions>

<outputs>
- Validated architectural guidance
- Confirmed understanding
- Any clarifications obtained
- Ready for integration
</outputs>

<quality_gate>
**Gate:** Architectural Guidance Validated
**Criteria:**
- All expected outputs received
- Recommendations are clear and specific
- Agent0 understands how to implement
- Guidance is applicable to HX-Infrastructure
- Governance alignment confirmed

**Pass:** Proceed to Phase 5 (Integration)
**Fail:** Request clarification from Alex, resolve gaps, validate again
</quality_gate>

<duration>10-20 minutes</duration>

<rationale>
Validation prevents misunderstanding or misapplication of architectural guidance. Agent0 must fully understand recommendations before acting on them. Better to clarify now than discover problems during implementation.
</rationale>
</phase>

<phase id="5" name="Integration & Documentation" gate="guidance_integrated">
<description>
Agent0 integrates Alex's architectural guidance into the project workflow, updates relevant documentation, and ensures guidance is captured for future reference and team coordination.
</description>

<actions>
**Integrate Guidance into Project Work:**

**Update Project Artifacts:**
- Update charter with architectural decisions (if charter phase)
- Update specification with implementation approach (if spec phase)
- Update task breakdown with architecture-based sequencing (if task phase)
- Update RAIDD log with architectural risks/assumptions

**Create or Update ADR (if significant decision):**
```markdown
**File:** `/home/agent0/HX-Infrastructure/docs/architecture/adr/[sequence]-[title].md`

**Content:**
- Title: [Decision Title]
- Status: Proposed | Accepted | Superseded
- Date: [Date]
- Deciders: Alex Rivera (Platform Architect), CAIO
- Context: [Why this decision was needed]
- Decision: [What was decided]
- Rationale: [Why this approach]
- Consequences: [Positive and negative outcomes]
- Alternatives Considered: [Other options]
- References: [Pattern sources, governance docs]
```

**Update Architecture Documentation:**
- `/home/agent0/HX-Infrastructure/docs/architecture/0.3-architecture.md` - If overall architecture affected
- `/home/agent0/HX-Infrastructure/docs/architecture/0.3.1-network-topology.md` - If network/zones changed
- `/home/agent0/HX-Infrastructure/docs/architecture/0.5-traceability-matrix.md` - Add new dependencies

**Document Integration Points:**
- Identify which other agents need this guidance (Frank for security, William for infrastructure, etc.)
- Prepare handoff context for subsequent agents
- Note coordination requirements

**Capture Lessons Learned:**
- What worked well in this orchestration?
- What could improve next time?
- New patterns or approaches discovered?
- Add to agent0's architectural knowledge
</actions>

<outputs>
- Architectural guidance integrated into project artifacts
- ADR created (if applicable)
- Architecture documentation updated
- Integration points identified for other agents
- Lessons learned captured
</outputs>

<quality_gate>
**Gate:** Guidance Integrated
**Criteria:**
- Project artifacts reflect architectural decisions
- Documentation updated appropriately
- ADR created if significant decision
- Coordination requirements clear
- Future reference captured

**Pass:** Guidance fully integrated - ready for implementation
**Fail:** Complete missing documentation, clarify integration points
</quality_gate>

<duration>20-40 minutes</duration>
</phase>

<phase id="6" name="Follow-up Actions" gate="orchestration_complete">
<description>
Agent0 executes follow-up actions based on Alex's guidance, including coordinating with other agents, validating implementations, and ensuring architectural coherence throughout execution.
</description>

<actions>
**Coordinate with Other Agents (as needed):**

**If Security Implications → Invoke Frank:**
- Provide Alex's guidance on security zones
- Request certificate/DNS/identity implementation
- Ensure security validation criteria from Alex are met

**If Infrastructure Changes → Invoke William:**
- Provide Alex's implementation sequence
- Execute manual deployment procedures (no Ansible playbooks)
- Enforce Docker dev-only (not for production/staging)
- Ensure operational standards from Alex are met

**If Testing Required → Invoke Julia:**
- Provide Alex's validation criteria
- Request test plan covering architectural integration points
- Ensure quality gates from Alex are tested

**Monitor Implementation Against Architecture:**
- Verify implementation follows Alex's guidance
- Catch deviations early
- Consult Alex again if significant changes needed
- Ensure architectural coherence maintained

**Validate Architectural Outcomes:**
- Confirm integration points work as designed
- Verify performance meets expectations
- Validate security zone boundaries respected
- Test cross-layer communication

**Update CAIO:**
- Summarize architectural decisions made
- Highlight any significant implications
- Request approval for major architectural changes
- Document CAIO decisions in RAIDD log
</actions>

<outputs>
- Other agents coordinated (if needed)
- Implementation monitored for architectural alignment
- Validation completed
- CAIO updated and approvals obtained
- Orchestration cycle complete
</outputs>

<quality_gate>
**Gate:** Orchestration Complete
**Criteria:**
- All follow-up actions executed
- Other agents coordinated successfully
- Implementation aligns with architecture
- Validation confirms architectural goals met
- CAIO approvals obtained (if required)

**Pass:** Alex orchestration complete - continue project work
**Fail:** Address gaps, re-coordinate agents, validate again
</quality_gate>

<duration>20-60 minutes (variable based on coordination needs)</duration>
</phase>

</phases>

<quality_gates>
<gate name="alex_invocation_decision" phase="0">
**Pass Criteria:**
- Decision made using invocation framework
- Rationale for decision documented
- If autonomous: Confidence level is high
- If invoking Alex: Scope clearly defined
- Decision is defensible to CAIO

**Fail Actions:**
- Gather more information about scope
- Clarify architectural impact
- Consult CAIO if uncertain
- Return to Phase 0 with additional context
</gate>

<gate name="context_complete" phase="1">
**Pass Criteria:**
- All required architecture documents loaded
- Affected systems clearly identified with FQDNs
- Specific questions for Alex formulated
- Constraints and requirements documented
- Context brief is comprehensive and clear
- Integration points identified

**Fail Actions:**
- Gather missing architecture documentation
- Clarify scope and affected systems
- Refine questions to be more specific
- Document additional constraints
- Return to Phase 1 context gathering
</gate>

<gate name="handoff_complete" phase="2">
**Pass Criteria:**
- Alex invoked with structured request
- Complete context brief provided
- Questions clearly stated
- Desired outputs specified
- Alex acknowledged request and began work
- Knowledge sources specified for Alex to consult

**Fail Actions:**
- Clarify request structure
- Provide missing context elements
- Re-specify expected outputs
- Re-invoke Alex with complete information
</gate>

<gate name="architectural_guidance_validated" phase="4">
**Pass Criteria:**
- All expected outputs received from Alex
- Recommendations are clear and specific
- Agent0 understands how to implement
- Guidance is applicable to HX-Infrastructure
- Governance alignment confirmed
- Integration approach is actionable
- Validation criteria are testable

**Fail Actions:**
- Request clarification from Alex on unclear points
- Ask for additional detail on implementation
- Confirm understanding of complex recommendations
- Resolve ambiguities before proceeding
- Return to Phase 4 validation with clarifications
</gate>

<gate name="guidance_integrated" phase="5">
**Pass Criteria:**
- Project artifacts updated with architectural decisions
- ADR created if significant decision made
- Architecture documentation updated appropriately
- Coordination requirements clear for other agents
- Future reference materials captured
- Lessons learned documented

**Fail Actions:**
- Complete missing documentation updates
- Create ADR for significant decisions
- Clarify integration points with other agents
- Document coordination requirements
- Return to Phase 5 to complete integration
</gate>

<gate name="orchestration_complete" phase="6">
**Pass Criteria:**
- All follow-up actions executed
- Other agents coordinated successfully (if needed)
- Implementation aligns with Alex's architecture
- Validation confirms architectural goals met
- CAIO approvals obtained (if required)
- Project can proceed with confidence

**Fail Actions:**
- Address coordination gaps with other agents
- Re-validate implementation alignment
- Obtain missing CAIO approvals
- Complete outstanding follow-up actions
- Return to Phase 6 to resolve issues
</gate>
</quality_gates>

<autonomous_work_patterns>
**When Agent0 Can Work Without Alex:**

<pattern name="Established Pattern Implementation">
**Scenario:** Implementing a feature using well-documented, proven patterns

**Criteria:**
- Pattern exists in knowledge vault with clear examples
- ADR already exists for similar implementation
- No cross-layer impacts
- Governance alignment is clear
- Previous similar implementations succeeded

**Agent0 Actions:**
- Document which pattern is being followed
- Reference existing ADR
- Note any deviations (and why)
- Implement according to pattern
- Consult Alex only if deviations needed
</pattern>

<pattern name="Routine Configuration Changes">
**Scenario:** Changing configurations within established boundaries

**Criteria:**
- Configuration parameter is documented
- Change does not affect architecture
- No security zone implications
- No multi-service impact
- Rollback is straightforward

**Agent0 Actions:**
- Document configuration change
- Validate against operational standards
- Test in development environment
- Implement with rollback plan ready
- Consult Alex only if unexpected issues arise
</pattern>

<pattern name="Documentation Updates">
**Scenario:** Updating documentation without architectural changes

**Criteria:**
- Architecture itself is not changing
- Documentation is correcting errors or adding clarity
- No new decisions being made
- Standards and formats are clear

**Agent0 Actions:**
- Follow documentation standards
- Update relevant documents
- Maintain consistency
- Consult Alex only if architectural implications discovered
</pattern>

<pattern name="Learning from Alex">
**Scenario:** Building agent0's architectural knowledge over time

**Goal:** Reduce Alex invocations for routine decisions while maintaining quality

**Approach:**
- Study Alex's recommendations and rationales
- Understand patterns Alex frequently applies
- Learn governance alignment reasoning
- Build confidence in standard scenarios
- Always defer to Alex for novel or complex decisions
- When uncertain, consult Alex (better safe than sorry)
</pattern>
</autonomous_work_patterns>

<conflict_resolution>
**Handling Architectural Conflicts:**

<scenario name="Alex's Recommendation vs. Other Agent's Approach">
**Situation:** Alex recommends approach A, but Frank (security) or William (infrastructure) suggests approach B

**Resolution Protocol:**
1. **Understand Both Perspectives:**
   - Document Alex's architectural rationale
   - Document other agent's domain-specific rationale
   - Identify the core conflict

2. **Attempt Synthesis:**
   - Can both concerns be addressed?
   - Is there a hybrid approach?
   - Are there alternative solutions?

3. **Escalate to CAIO if Needed:**
   - Present both positions clearly
   - Explain tradeoffs
   - Recommend approach (if possible)
   - Request CAIO decision

4. **Document Decision:**
   - Create ADR documenting conflict and resolution
   - Explain rationale for chosen approach
   - Note dissenting opinions if any
   - Reference in future similar decisions
</scenario>

<scenario name="Alex's Recommendation vs. Project Constraints">
**Situation:** Alex recommends ideal architecture, but project constraints (timeline, resources, complexity) make it impractical

**Resolution Protocol:**
1. **Clarify Constraints to Alex:**
   - Provide specific constraint details
   - Ask for pragmatic alternative
   - Request phased approach (ideal future state + practical current state)

2. **Technical Debt Documentation:**
   - Document ideal architecture as target
   - Document implemented approach as interim
   - Create backlog item for eventual convergence
   - Add to RAIDD log as assumption/risk

3. **CAIO Approval:**
   - Present tradeoff clearly
   - Explain technical debt implications
   - Request approval for pragmatic approach
   - Document decision
</scenario>

<scenario name="Architectural Guidance Unclear or Incomplete">
**Situation:** Alex's guidance doesn't fully address the question or creates ambiguity

**Resolution Protocol:**
1. **Request Clarification from Alex:**
   - Be specific about what's unclear
   - Provide example scenarios if helpful
   - Ask for additional detail

2. **If Still Unclear:**
   - Consult CAIO for interpretation
   - Document ambiguity in RAIDD log
   - Request Alex revisit guidance
   - Do not implement until clarity achieved
</scenario>
</conflict_resolution>

<escalation_protocols>
**When to Escalate Beyond Alex:**

<escalation level="1" target="Alex">
**Scenarios:**
- Architectural decision needed
- Pattern selection unclear
- Cross-layer integration design
- Governance alignment verification
- Multi-agent coordination with architectural implications

**Process:** Follow this workflow (Phases 0-6)
</escalation>

<escalation level="2" target="CAIO">
**Scenarios:**
- Major architectural pivot affecting multiple projects
- Alex unavailable and urgent decision needed
- Conflict between agents (Alex vs. Frank/William/Julia)
- Constitutional governance question
- Resource allocation for architectural work
- Strategic direction decision

**Process:**
1. Document issue clearly
2. Present options with tradeoffs
3. Provide recommendation (if possible)
4. Request CAIO decision
5. Document decision in RAIDD log
6. Create ADR if significant
</escalation>

<escalation level="3" target="Architecture Review Board">
**Scenarios:**
- Architectural decision with ecosystem-wide implications
- Novel patterns not covered by existing knowledge
- Cross-project architectural conflicts
- Platform evolution decisions

**Process:**
1. Prepare comprehensive architectural proposal
2. Convene review with Alex, affected agents, CAIO
3. Present analysis and options
4. Facilitate discussion
5. Reach consensus or escalate to CAIO for decision
6. Document extensively (ADR + meeting notes)
</escalation>
</escalation_protocols>

<guiding_principles>
<principle name="Context is King">
Quality architectural guidance requires quality context. Time invested in Phase 1 (Context Preparation) pays exponential dividends in Phase 4 (Output Quality). Never rush context preparation.
</principle>

<principle name="Specific Over Generic">
Alex's value comes from HX-Infrastructure-specific guidance grounded in knowledge sources. Generic architectural advice can come from anywhere. Ensure Alex consults `/srv/knowledge/vault/agentic-design-patterns-docs-main/` and `/srv/cc/Governance/` for every recommendation.
</principle>

<principle name="Validate Understanding">
Agent0 must fully understand Alex's guidance before acting on it. Validation (Phase 4) is not optional. Misunderstood architecture is worse than no architecture.
</principle>

<principle name="Document Decisions">
Every significant architectural decision becomes precedent for future work. ADRs and updated architecture docs ensure consistency and prevent re-litigating solved problems.
</principle>

<principle name="Coordinate with Domain Experts">
Architecture affects security (Frank), infrastructure (William), and testing (Julia). Follow-up coordination (Phase 6) ensures architectural vision is implemented coherently across domains.
</principle>

<principle name="Learn and Evolve">
Agent0 should build architectural knowledge over time by studying Alex's recommendations, understanding patterns, and recognizing when autonomous work is appropriate. Goal is intelligent delegation, not blind handoff.
</principle>

<principle name="Escalate Wisely">
Know when to involve CAIO. Architecture is agent0's responsibility to orchestrate, but strategic decisions, conflicts, and major changes require CAIO oversight.
</principle>
</guiding_principles>

<visual_diagrams>
<workflow_diagram>
```
┌─────────────────────────────────────────┐
│ Phase 0: Decision Point                 │
│ Do We Need Alex?                        │
└─────────┬───────────────────────────────┘
          │
     ┌────┴────┐
     │  NEED   │
     │  ALEX?  │
     └─┬─────┬─┘
       │     │
   YES │     │ NO
       │     │
       │     └──────────────────────────────┐
       │                                    │
       ↓                                    ↓
┌─────────────────────────────────────┐   ┌────────────────────────────┐
│ Phase 1: Context Preparation        │   │ Agent0 Works Autonomously  │
│ (Load docs, prepare brief)          │   │ (Document decision)        │
└─────────────┬───────────────────────┘   └────────────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Context│
       │   Complete   │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 2: Alex Invocation & Handoff │
│ (Structured request + context)     │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Handoff│
       │   Complete   │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 3: Alex Works Independently   │
│ (Agent0 monitors, does not interrupt)│
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 4: Output Validation          │
│ (Validate completeness, clarity)    │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Guidance│
       │   Validated  │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 5: Integration & Documentation│
│ (ADR, update docs, capture lessons) │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Guidance│
       │  Integrated  │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 6: Follow-up Actions          │
│ (Coordinate agents, validate, CAIO) │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Complete│
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ ✓ Continue Project Work             │
│ (Architecture aligned)               │
└─────────────────────────────────────┘
```
</workflow_diagram>

<decision_tree>
```
NEED ALEX? Decision Tree
========================

Does change affect 2+ architecture layers?
├─ YES → INVOKE ALEX
└─ NO → Continue...

Is this a new platform component/service?
├─ YES → INVOKE ALEX
└─ NO → Continue...

Are security zones involved?
├─ YES → INVOKE ALEX
└─ NO → Continue...

Is architectural pattern unclear?
├─ YES → INVOKE ALEX
└─ NO → Continue...

Does this require multi-agent coordination?
├─ YES → INVOKE ALEX
└─ NO → Continue...

Is there potential architecture conflict?
├─ YES → INVOKE ALEX
└─ NO → Continue...

Is this following an established pattern with clear ADR?
├─ YES → WORK AUTONOMOUSLY
└─ NO → Continue...

Would proactive review prevent future issues?
├─ YES → INVOKE ALEX
└─ NO → WORK AUTONOMOUSLY (document decision)

When in doubt → INVOKE ALEX
(Better safe than architectural debt)
```
</decision_tree>

<timeline_estimate>
```
Phase 0:   5-10 min   (Decision point)
Phase 1:   15-30 min  (Context preparation)
Phase 2:   5-10 min   (Alex invocation)
Phase 3:   15-45 min  (Alex works)
Phase 4:   10-20 min  (Output validation)
Phase 5:   20-40 min  (Integration & docs)
Phase 6:   20-60 min  (Follow-up coordination)
──────────────────────
TOTAL:     ~30 min - 3 hours

Simple decisions: 30-60 min
Medium complexity: 1-2 hours
Complex/multi-layer: 2-3 hours
```
</timeline_estimate>
</visual_diagrams>

<notes>
<note type="agent_persona">
**About Alex Rivera:**

Alex is the Platform Architect for HX-Infrastructure, responsible for:
- All architectural decisions across 6 layers
- System design and integration patterns
- Governance alignment and ADR creation
- Multi-agent coordination (architectural perspective)
- Network topology and security zone management

**Alex's Knowledge Sources:**
- `/srv/knowledge/vault/agentic-design-patterns-docs-main/` - Design patterns library
- `/srv/cc/Governance/` - Architecture, standards, governance documents

**Alex's Response Structure:**
- Architectural Analysis (with pattern references)
- Recommended Approach (HX-Infrastructure specific)
- Integration Points (with FQDNs/IPs)
- Implementation Sequence (per Deployment Methodology)
- Coordination Required (other agents involved)
- Validation Criteria (how to verify)
- Documentation Updates (which docs need changing)

Agent0 should expect this structure and validate against it.
</note>

<note type="orchestration_philosophy">
**Why Orchestration vs. Impersonation:**

Agent0 does not "act as Alex" because:
1. Alex has domain expertise and knowledge sources agent0 lacks
2. Alex's system prompt encodes years of architectural thinking
3. Architecture requires deep pattern knowledge, not surface mimicry
4. Quality architecture comes from expert consultation, not role-play

Agent0's role is to:
- Recognize when Alex's expertise is needed
- Prepare context that enables Alex to excel
- Validate and integrate Alex's guidance
- Coordinate Alex's work with other agents
- Learn from Alex to improve autonomous capability over time

This is how real organizations work - specialists consult with each other.
</note>

<note type="learning_pattern">
**Agent0's Architectural Growth:**

Over time, agent0 should:
- Recognize patterns Alex frequently recommends
- Understand common governance alignment issues
- Build confidence in routine architectural decisions
- Reduce Alex invocations for well-understood scenarios
- Develop architectural intuition

**But Always:**
- Defer to Alex for novel/complex decisions
- Consult Alex when uncertain
- Value quality over speed
- Document when working autonomously

**Growth Metrics:**
- Can agent0 identify when to invoke Alex correctly? (Phase 0 decision quality)
- Does agent0 prepare complete context? (Phase 1 validation pass rate)
- Can agent0 validate Alex's guidance effectively? (Phase 4 quality)
- Does agent0 integrate guidance thoroughly? (Phase 5 completeness)

Improvement in these areas indicates agent0 is learning architecture.
</note>
</notes>

<related_documents>
**Alex's Agent File:**
- `/home/agent0/HX-Infrastructure/.claude/agents/platform-architect-alex.md` - Alex's system prompt and configuration

**Architecture Documentation:**
- `/home/agent0/HX-Infrastructure/docs/architecture/0.3-architecture.md` - Current architecture
- `/home/agent0/HX-Infrastructure/docs/architecture/0.3.1-network-topology.md` - Network topology
- `/home/agent0/HX-Infrastructure/docs/architecture/0.2-platform-nodes.md` - Node inventory
- `/home/agent0/HX-Infrastructure/docs/architecture/0.5-traceability-matrix.md` - Dependencies
- `/home/agent0/HX-Infrastructure/docs/architecture/adr/` - Architecture Decision Records

**Governance Standards:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance principles
- `/home/agent0/HX-Infrastructure/docs/governance/0.4-deployment-methodology.md` - Deployment phases

**Knowledge Sources (Alex uses these):**
- `/srv/knowledge/vault/agentic-design-patterns-docs-main/` - Pattern library
- `/srv/cc/Governance/` - Governance repository

**Other Orchestration Commands:**
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Security coordination
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - Infrastructure coordination
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Testing coordination

**Core Workflows:**
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Charter creation (where architecture gets defined)
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Specification (where architecture gets detailed)
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Task breakdown (where architecture gets implemented)

**Templates:**
- `/home/agent0/HX-Infrastructure/templates/adr-template.md` - Architecture Decision Record template
</related_documents>

<critical_reminders>
**⚠️ NEVER Skip Context Preparation:**
Quality architectural guidance depends on quality context. Rushing Phase 1 produces generic advice that doesn't fit HX-Infrastructure reality. Time invested in context preparation pays exponential dividends in guidance quality.

**⚠️ ALWAYS Validate Understanding:**
Agent0 must fully understand Alex's guidance before acting on it. Phase 4 validation is not optional. Misunderstood architecture is worse than no architecture. Better to clarify now than discover problems during implementation.

**⚠️ DO NOT Interrupt Alex During Phase 3:**
Alex needs uninterrupted time to review knowledge sources, evaluate patterns, consider cross-layer impacts, and validate governance alignment. Quality architectural work requires deep thinking time. Monitor but do not rush.

**⚠️ ALWAYS Document Architectural Decisions:**
Every significant architectural decision becomes precedent for future work. Create ADRs, update architecture documentation, and capture lessons learned. Undocumented architecture leads to inconsistency and re-litigation of solved problems.

**⚠️ COORDINATE With Domain Expert Agents:**
Architecture affects security (Frank), infrastructure (William), and testing (Julia). Phase 6 follow-up coordination ensures architectural vision is implemented coherently across all domains. Never skip coordination.

**⚠️ WHEN IN DOUBT, Invoke Alex:**
Better safe than architectural debt. If uncertain whether Alex's expertise is needed, err on the side of consultation. The cost of fixing architectural problems after implementation far exceeds the time investment in proactive consultation.

**⚠️ DO NOT Work Autonomously on Multi-Layer Changes:**
Changes affecting 2+ architecture layers MUST have Alex's review. Cross-layer integration requires architectural expertise to ensure coherence, prevent conflicts, and maintain governance alignment.

**⚠️ ALWAYS Use Absolute Paths in Context:**
When providing context to Alex, use absolute paths for all file references. Alex needs complete paths to access architecture documents, ADRs, and knowledge sources.
</critical_reminders>

<validation_checklist>
**Before Using This Orchestration Command:**
- [ ] All phases have clear descriptions and actions
- [ ] Quality gates have explicit pass/fail criteria
- [ ] Decision framework (Phase 0) is comprehensive
- [ ] Context preparation checklist (Phase 1) is complete
- [ ] Validation criteria (Phase 4) cover all aspects
- [ ] Integration requirements (Phase 5) are thorough
- [ ] Follow-up coordination (Phase 6) addresses all agents
- [ ] Autonomous work patterns are clearly defined
- [ ] Conflict resolution protocols are actionable
- [ ] Escalation paths are clear
- [ ] All template references use absolute paths
- [ ] Visual diagrams accurately represent workflow
- [ ] Guiding principles reflect HX-Infrastructure values
- [ ] Related documents are comprehensive
- [ ] XML tags properly nested and closed
- [ ] No markdown headings used (XML tags only)
</validation_checklist>

<metadata_footer>
**Workflow Version:** 1.0
**Status:** APPROVED - Ready for immediate use
**Created:** 2025-11-19
**Last Updated:** 2025-11-20
**Purpose:** Establish systematic orchestration patterns for agent0 to coordinate with Alex (Platform Architect)
**Key Innovation:** Separates orchestration (agent0's role) from execution (Alex's role) - proper separation of concerns
**Compliance:** Fully compliant with semantic XML documentation standards
**Next Steps:** Apply learnings to other agent orchestration commands (Frank, William, Julia)
**Related Commands:** cc-orchestrate-frank.md, cc-orchestrate-william.md, cc-orchestrate-julia.md (to be created)
</metadata_footer>
