---
workflow: agent-zero-synthesis
version: 1.1
date: 2025-11-20
status: APPROVED
type: workflow-command
description: Multi-agent coordination synthesis patterns for Agent Zero's orchestration of complex work requiring multiple specialist agents
applies_to: multi_agent_coordination, cross_domain_tasks, complex_projects, specialist_synthesis, meta_orchestration
author: HX-Infrastructure Team
last_updated: 2025-11-20
update_notes: Infrastructure philosophy integration (bare metal first, Docker dev-only, Ansible Vault only)
---

<metadata>
**Workflow:** Agent Zero Synthesis - Multi-Agent Coordination
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Infrastructure philosophy integration)
**Status:** APPROVED - Production Ready
**Type:** Meta-Orchestration Command
**Agent:** Agent Zero (Chief AI Officer)
**Purpose:** Define how Agent Zero coordinates complex work requiring multiple specialist agents (Alex, Frank, William, Julia) simultaneously or sequentially
</metadata>

<objective>
**Purpose:** Provide systematic patterns for Agent Zero to coordinate complex work requiring multiple specialist agents, ensuring proper multi-agent context preparation, effective cross-domain handoffs, synthesis of diverse expertise, and integration of multi-agent outputs into cohesive project deliverables.

**Achievements This Workflow Enables:**
- Effective multi-agent coordination across architecture, security, infrastructure, and testing domains
- Strategic agent selection based on task complexity and domain requirements
- Proper context preparation spanning multiple specialist domains
- Clear handoff protocols managing multiple concurrent agent invocations
- Synthesis of diverse specialist outputs into unified project guidance
- Documented precedents capturing multi-agent coordination patterns

**When to Use This Workflow:**
- When tasks require expertise from multiple domains (architecture + security + infrastructure + testing)
- When specialist outputs must be integrated and synthesized
- When conflicts between specialist recommendations need resolution
- When cross-domain dependencies require multi-agent coordination
- When learning from multi-agent interactions to improve future orchestration
- When deciding which agents to involve and in what sequence
</objective>

<workflow_overview>
**High-Level Flow:**
This meta-orchestration follows a 7-phase pattern specifically adapted for multi-agent coordination. Each phase includes cross-domain checkpoints, specialist synthesis validation, and integration quality controls.

**Phase Sequence:**
1. **Analysis Phase** - Determine which agents needed and in what sequence
2. **Strategy Phase** - Plan multi-agent coordination approach and context flow
3. **Coordination Phase** - Execute agent handoffs sequentially or in parallel
4. **Synthesis Phase** - Integrate and reconcile outputs from multiple agents
5. **Validation Phase** - Confirm cross-domain correctness and consistency
6. **Integration Phase** - Merge multi-agent guidance into unified deliverables
7. **Learning Phase** - Document multi-agent patterns and improve coordination

**Key Principle:** Agent Zero orchestrates specialists strategically, recognizing when single-agent coordination suffices versus when multi-agent synthesis is essential.
</workflow_overview>

<phases>
  <phase id="1" name="Analysis Phase - Which Agents and What Sequence?" gate="analysis_gate">
    <description>
    Determine which specialist agents are needed and in what order to coordinate them. This phase evaluates task complexity across domains (architecture, security, infrastructure, testing) to make informed multi-agent coordination decisions.
    
    **Analysis Dimensions:**
    - **Domain Complexity:** Which specialist domains are implicated?
    - **Cross-Domain Dependencies:** What are the relationships between domains?
    - **Coordination Sequence:** Sequential (one after another) or parallel (concurrent)?
    - **Integration Complexity:** How difficult to synthesize outputs?
    - **Conflict Potential:** Likelihood of contradictory recommendations?
    
    **Outcome:** Clear multi-agent coordination plan with sequencing strategy and integration approach.
    </description>
    
    <inputs>
    - Current task description and requirements
    - Complexity assessment across specialist domains
    - Cross-domain dependency analysis
    - Previous multi-agent coordination precedents
    - Available specialist agent capabilities
    - Project constraints and timeline
    </inputs>
    
    <actions>
    1. **Map task to domains** - Identify which specialist domains (architecture, security, infrastructure, testing) are involved
    2. **Assess domain complexity** - Evaluate complexity within each domain
    3. **Analyze cross-domain dependencies** - Understand how domains interact and depend on each other
    4. **Determine coordination sequence** - Decide sequential (A→B→C) vs. parallel (A+B+C simultaneously) coordination
    5. **Evaluate integration difficulty** - Consider how hard it will be to synthesize outputs
    6. **Identify conflict potential** - Recognize where specialist recommendations might contradict
    7. **Select coordination strategy** - Choose optimal multi-agent approach
    8. **Document coordination plan** - Record which agents, what sequence, why
    </actions>
    
    <outputs>
    - **Multi-Agent Coordination Plan** - Which agents needed, in what sequence, for what purposes
    - **Domain Analysis** - Complexity assessment per specialist domain
    - **Dependency Map** - Cross-domain relationships and prerequisites
    - **Coordination Strategy** - Sequential vs. parallel approach with rationale
    - **Integration Approach** - How specialist outputs will be synthesized
    - **Risk Assessment** - Potential conflicts and mitigation strategies
    </outputs>
    
    <quality_gate name="analysis_gate">
    **Pass Criteria:**
    - All relevant specialist domains identified
    - Domain complexity honestly assessed
    - Cross-domain dependencies mapped
    - Coordination sequence justified
    - Integration approach defined
    - Conflict potential recognized
    - Multi-agent coordination plan complete
    
    **Fail Actions:**
    - Missing domains → Re-analyze task for additional specialist needs
    - Unclear dependencies → Map cross-domain relationships
    - Unjustified sequence → Clarify coordination rationale
    - Undefined integration → Plan synthesis approach
    - Unrecognized conflicts → Assess contradiction potential
    </quality_gate>
    
    <duration>15-30 minutes (multi-agent analysis and planning)</duration>
    
    <example>
    **Task:** "Deploy new authentication system with role-based access control"
    **Analysis:**
    - **Domains:** Security (Frank), Architecture (Alex), Infrastructure (William), Testing (Julia)
    - **Sequence:** Frank → Alex → William → Julia (sequential due to dependencies)
    - **Rationale:** 
      * Security requirements must be defined first (Frank)
      * Architecture must accommodate security model (Alex needs Frank's output)
      * Infrastructure must implement secure architecture (William needs both)
      * Testing must validate all layers (Julia needs all outputs)
    - **Integration:** Synthesize into unified deployment plan with security, architecture, infrastructure, and testing components
    </example>
    
    <example>
    **Task:** "Create comprehensive project documentation"
    **Analysis:**
    - **Domains:** Architecture (Alex), Security (Frank), Infrastructure (William), Testing (Julia)
    - **Sequence:** Parallel (all can work simultaneously on their domain sections)
    - **Rationale:** Documentation sections independent, can be created concurrently
    - **Integration:** Compile sections into unified documentation structure
    </example>
    
    <note type="coordination_principle">
    Not every task requires multi-agent coordination. Use single-agent orchestration (cc-orchestrate-alex, cc-orchestrate-frank, etc.) when task is clearly within one domain. Use multi-agent synthesis when task genuinely spans multiple domains or when specialist outputs must be reconciled.
    </note>
  </phase>

  <phase id="2" name="Strategy Phase - Plan Multi-Agent Coordination" gate="strategy_gate">
    <description>
    Develop comprehensive strategy for multi-agent coordination. This phase plans context preparation, handoff protocols, synthesis approach, and conflict resolution mechanisms before engaging specialists.
    
    **Strategy Components:**
    - **Context Preparation:** What each agent needs to know, including other agents' contexts
    - **Handoff Protocol:** How to transfer work between agents (sequential) or coordinate simultaneously (parallel)
    - **Synthesis Approach:** How to integrate outputs from multiple specialists
    - **Conflict Resolution:** How to handle contradictory recommendations
    - **Quality Validation:** How to verify cross-domain correctness
    - **Timeline Coordination:** How to manage multiple agent schedules
    
    **Quality Principle:** Comprehensive strategy prevents multi-agent chaos. Poor planning = specialist confusion, contradictory outputs, and failed synthesis.
    </description>
    
    <inputs>
    - Multi-agent coordination plan from Phase 1
    - Task requirements and constraints
    - Specialist agent capabilities and knowledge sources
    - Available coordination time and timeline constraints
    - Previous multi-agent coordination precedents
    - Cross-domain quality standards
    </inputs>
    
    <actions>
    1. **Plan context preparation** - Define what each agent needs including cross-domain context
    2. **Design handoff protocol** - Establish how work flows between agents
    3. **Define synthesis approach** - Plan how to integrate multiple specialist outputs
    4. **Establish conflict resolution** - Prepare mechanisms for handling contradictions
    5. **Plan quality validation** - Define cross-domain correctness verification
    6. **Coordinate timelines** - Align multiple agent schedules
    7. **Prepare integration framework** - Structure for combining outputs
    8. **Document coordination strategy** - Record complete multi-agent plan
    9. **Identify coordination risks** - Recognize potential multi-agent issues
    10. **Establish checkpoints** - Define milestone validations during coordination
    </actions>
    
    <outputs>
    - **Context Preparation Plan** - What each agent receives including cross-domain information
    - **Handoff Protocol** - Process for agent-to-agent work transfer
    - **Synthesis Strategy** - Method for integrating specialist outputs
    - **Conflict Resolution Protocol** - Process for handling contradictory recommendations
    - **Quality Validation Plan** - Cross-domain verification approach
    - **Timeline Coordination** - Schedule for multiple agent invocations
    - **Integration Framework** - Structure for unified deliverable
    - **Risk Mitigation** - Plans for addressing coordination challenges
    </outputs>
    
    <quality_gate name="strategy_gate">
    **Pass Criteria:**
    - Context preparation planned for each agent
    - Handoff protocol clearly defined
    - Synthesis approach established
    - Conflict resolution mechanisms ready
    - Quality validation planned
    - Timeline coordinated across agents
    - Integration framework structured
    - Coordination risks identified and mitigated
    
    **Fail Actions:**
    - Incomplete context plans → Define what each agent needs
    - Unclear handoff protocol → Establish work transfer process
    - Undefined synthesis → Plan output integration approach
    - Missing conflict resolution → Prepare contradiction handling
    - No validation plan → Define cross-domain verification
    - Uncoordinated timelines → Align agent schedules
    </quality_gate>
    
    <duration>30-60 minutes (comprehensive multi-agent strategy development)</duration>
    
    <rationale>
    Multi-agent coordination strategy determines success or failure. Specialists working without coordination create contradictory outputs requiring expensive rework. Time invested in strategy yields coherent multi-agent synthesis and prevents specialist conflicts.
    </rationale>
    
    <note type="strategy_philosophy">
    "Failing to plan is planning to fail" applies doubly to multi-agent coordination. Each specialist operates optimally within their domain but may propose solutions contradicting other domains. Strategy phase prevents this by establishing cross-domain context awareness and conflict resolution before engaging specialists.
    </note>
  </phase>

  <phase id="3" name="Coordination Phase - Execute Multi-Agent Handoffs" gate="coordination_gate">
    <description>
    Execute planned multi-agent coordination by engaging specialists according to strategy. This phase manages sequential handoffs or parallel invocations while maintaining cross-domain context awareness.
    
    **Coordination Modes:**
    - **Sequential Coordination:** Agents invoked one after another, each building on previous outputs
    - **Parallel Coordination:** Agents invoked simultaneously with shared base context
    - **Hybrid Coordination:** Some parallel, some sequential based on dependencies
    
    **Agent Zero's Role:**
    - Prepare specialist-specific context including cross-domain information
    - Execute handoffs maintaining context continuity
    - Monitor multiple concurrent specialists (parallel mode)
    - Coordinate agent-to-agent information flow (sequential mode)
    - Remain available for cross-domain clarifications
    - Do NOT attempt to do specialist work; only coordinate
    </description>
    
    <inputs>
    - Multi-agent coordination strategy from Phase 2
    - Prepared context for each specialist agent
    - Handoff protocol and sequencing plan
    - Task requirements and constraints
    - Timeline coordination schedule
    - Cross-domain quality standards
    </inputs>
    
    <actions>
    1. **Sequential Coordination:**
       - Invoke first agent with prepared context
       - Monitor first agent's work to completion
       - Extract output from first agent
       - Prepare context for second agent including first agent's output
       - Invoke second agent with enhanced context
       - Repeat for each subsequent agent in sequence
       - Maintain cross-domain context continuity throughout
    
    2. **Parallel Coordination:**
       - Prepare base context shared by all agents
       - Prepare specialist-specific context for each agent
       - Invoke all agents simultaneously with appropriate contexts
       - Monitor multiple concurrent agent workflows
       - Remain available for cross-domain clarification requests
       - Do NOT interfere with specialist autonomous work
    
    3. **Agent Zero's Support:**
       - Answer cross-domain questions if agents request
       - Provide additional context if specialists need more information
       - Clarify task requirements if confusion arises
       - **Do NOT** critique specialist approaches during work
       - **Do NOT** suggest specialist implementation details
       - **Do NOT** micromanage specialist workflows
    </actions>
    
    <outputs>
    - **Specialist Outputs** - Architecture guidance (Alex), security guidance (Frank), infrastructure guidance (William), testing guidance (Julia)
    - **Cross-Domain Context** - Information flow between specialists captured
    - **Coordination Record** - Documentation of handoff sequence and timing
    - **Clarification Log** - Questions asked and answers provided during coordination
    - **Progress Tracking** - Status updates from multiple concurrent agents
    </outputs>
    
    <quality_gate name="coordination_gate">
    **Pass Criteria:**
    - All planned agents successfully invoked
    - Context properly prepared for each specialist
    - Handoff protocol executed as planned
    - Cross-domain information flow maintained
    - All specialists completed their work
    - Specialist outputs captured for synthesis
    - No coordination breakdowns or failures
    
    **Fail Actions:**
    - Failed agent invocation → Troubleshoot and retry with corrected context
    - Insufficient context → Supplement with additional information
    - Broken handoff protocol → Re-establish coordination sequence
    - Lost cross-domain information → Reconstruct context flow
    - Incomplete specialist work → Investigate blockers and resolve
    </quality_gate>
    
    <duration>Variable (depends on number of agents and coordination mode - typically 2-8 hours total for all specialists)</duration>
    
    <note type="coordination_complexity">
    Multi-agent coordination is significantly more complex than single-agent orchestration. Managing multiple specialists simultaneously or sequentially requires careful attention to context continuity, cross-domain information flow, and specialist autonomy. Trust the coordination strategy developed in Phase 2.
    </note>
  </phase>

  <phase id="4" name="Synthesis Phase - Integrate Multi-Agent Outputs" gate="synthesis_gate">
    <description>
    Synthesize outputs from multiple specialist agents into coherent, unified guidance. This phase reconciles differences, resolves conflicts, identifies synergies, and creates integrated recommendations spanning all domains.
    
    **Synthesis Activities:**
    - **Output Compilation:** Gather all specialist recommendations
    - **Consistency Analysis:** Identify agreements and contradictions
    - **Conflict Resolution:** Reconcile contradictory recommendations
    - **Synergy Identification:** Find opportunities where specialists reinforce each other
    - **Gap Analysis:** Detect missing cross-domain considerations
    - **Integration:** Combine specialist outputs into unified guidance
    
    **What Agent Zero Does NOT Do:**
    - Override specialist expertise based on personal preference
    - Cherry-pick recommendations ignoring specialist rationale
    - Force artificial consistency when legitimate tradeoffs exist
    - Eliminate specialist nuance in pursuit of simplification
    </description>
    
    <inputs>
    - Architecture guidance from Alex
    - Security guidance from Frank
    - Infrastructure guidance from William
    - Testing guidance from Julia
    - Original task requirements and constraints
    - Cross-domain quality standards
    - Coordination strategy from Phase 2
    </inputs>
    
    <actions>
    1. **Compile specialist outputs** - Gather all recommendations systematically
    2. **Analyze for consistency** - Identify where specialists agree and disagree
    3. **Identify conflicts** - Recognize contradictory recommendations requiring resolution
    4. **Understand conflict rationale** - Comprehend why specialists disagree (legitimate domain tradeoffs vs. miscommunication)
    5. **Resolve conflicts appropriately:**
       - For miscommunication → Clarify and re-engage specialists
       - For legitimate tradeoffs → Document tradeoffs and make informed decision (potentially escalate to user)
       - For minor inconsistencies → Harmonize with minimal specialist impact
    6. **Find synergies** - Identify where specialists reinforce each other
    7. **Check for gaps** - Detect missing cross-domain considerations
    8. **Integrate outputs** - Combine specialist guidance into unified recommendations
    9. **Document synthesis rationale** - Record how outputs were integrated and conflicts resolved
    10. **Prepare unified deliverable** - Structure integrated guidance for project use
    </actions>
    
    <outputs>
    - **Integrated Guidance** - Unified recommendations spanning architecture, security, infrastructure, testing
    - **Consistency Analysis** - Documentation of specialist agreements and disagreements
    - **Conflict Resolution Record** - How contradictions were reconciled with rationale
    - **Synergy Documentation** - Where specialists reinforce each other
    - **Gap Identification** - Missing cross-domain considerations noted
    - **Synthesis Rationale** - Explanation of integration decisions
    - **Unified Deliverable** - Cohesive project guidance from multi-agent synthesis
    </outputs>
    
    <quality_gate name="synthesis_gate">
    **Pass Criteria:**
    - All specialist outputs properly compiled
    - Consistency analyzed across domains
    - Conflicts identified and appropriately resolved
    - Synergies recognized and documented
    - Gaps detected and addressed
    - Integration complete and coherent
    - Synthesis rationale clearly documented
    - Unified deliverable production-ready
    
    **Fail Actions:**
    - Incomplete compilation → Gather missing specialist outputs
    - Unanalyzed consistency → Compare specialist recommendations
    - Unresolved conflicts → Address contradictions appropriately
    - Missed synergies → Identify specialist reinforcement opportunities
    - Undetected gaps → Analyze for missing cross-domain considerations
    - Incoherent integration → Restructure for unified guidance
    </quality_gate>
    
    <duration>45-90 minutes (synthesis complexity varies with number of agents and conflict level)</duration>
    
    <rationale>
    Synthesis is where multi-agent coordination proves valuable or fails. Simply compiling specialist outputs without integration creates confused, contradictory guidance. True synthesis reconciles differences, finds synergies, and produces unified recommendations greater than sum of parts.
    </rationale>
    
    <note type="synthesis_skill">
    Synthesis requires understanding all specialist domains without claiming expertise in any. Agent Zero's role is integration architect, not domain expert. Respect specialist expertise while creating cross-domain coherence. When conflicts involve legitimate tradeoffs, document them honestly rather than forcing false consistency.
    </note>
  </phase>

  <phase id="5" name="Validation Phase - Verify Cross-Domain Correctness" gate="validation_gate">
    <description>
    Validate integrated guidance against original requirements and cross-domain quality standards. This phase ensures synthesis correctly addresses task needs, respects all domain constraints, and maintains specialist expertise integrity.
    
    **Validation Dimensions:**
    - **Requirements Coverage:** Does integrated guidance address all task requirements?
    - **Domain Correctness:** Does synthesis respect each specialist domain's constraints?
    - **Cross-Domain Consistency:** Are recommendations coherent across domains?
    - **Conflict Resolution Quality:** Were contradictions appropriately handled?
    - **Synergy Realization:** Are specialist reinforcements leveraged?
    - **Completeness:** Are all necessary domains and considerations covered?
    
    **What Agent Zero Does NOT Validate:**
    - Individual specialist expertise (trusted implicitly)
    - Domain-specific implementation details (specialists' decisions)
    - Specialist reasoning within their domain (not Agent Zero's to judge)
    </description>
    
    <inputs>
    - Integrated guidance from Phase 4 synthesis
    - Original task requirements and constraints
    - Individual specialist outputs (Alex, Frank, William, Julia)
    - Cross-domain quality standards
    - Synthesis rationale and conflict resolution record
    - Multi-agent coordination plan from Phase 1
    </inputs>
    
    <actions>
    1. **Validate requirements coverage** - Confirm all task requirements addressed in integrated guidance
    2. **Check domain correctness** - Verify synthesis respects architecture, security, infrastructure, testing constraints
    3. **Assess cross-domain consistency** - Ensure recommendations coherent across specialist domains
    4. **Review conflict resolution** - Confirm contradictions appropriately handled
    5. **Verify synergy realization** - Check that specialist reinforcements leveraged
    6. **Evaluate completeness** - Assess if all necessary domains and considerations covered
    7. **Identify integration gaps** (if any) - Note missing cross-domain elements
    8. **Prepare validation feedback** - Document confirmation or gaps requiring revision
    9. **Consult specialists if needed** - Seek clarification on domain-specific concerns
    10. **Communicate validation results** - Share assessment for final confirmation
    </actions>
    
    <outputs>
    - **Validation Report** - Assessment of integrated guidance against requirements and standards
    - **Requirements Coverage Confirmation** - All task requirements addressed
    - **Domain Correctness Verification** - Synthesis respects specialist constraints
    - **Consistency Assessment** - Cross-domain coherence confirmed
    - **Conflict Resolution Review** - Contradiction handling validated
    - **Completeness Check** - All domains and considerations covered
    - **Gap Identification** (if needed) - Missing elements documented
    - **Validation Approval** or **Revision Request** - Acceptance or specific improvements needed
    </outputs>
    
    <quality_gate name="validation_gate">
    **Pass Criteria:**
    - All task requirements addressed in integrated guidance
    - Synthesis respects architecture constraints (Alex's domain)
    - Synthesis respects security constraints (Frank's domain)
    - Synthesis respects infrastructure constraints (William's domain)
    - Synthesis respects testing constraints (Julia's domain)
    - Cross-domain recommendations coherent and consistent
    - Conflicts appropriately resolved with documented rationale
    - Synergies between specialists leveraged
    - All necessary domains covered completely
    - Integrated guidance production-ready
    
    **Fail Actions:**
    - Missing requirements → Add missing task requirements to integrated guidance
    - Domain constraint violations → Revise synthesis to respect specialist constraints
    - Cross-domain inconsistencies → Harmonize recommendations across domains
    - Poor conflict resolution → Re-address contradictions appropriately
    - Missed synergies → Identify and leverage specialist reinforcements
    - Incomplete coverage → Address missing domains or considerations
    </quality_gate>
    
    <duration>30-60 minutes (multi-agent validation and cross-domain verification)</duration>
    
    <rationale>
    Validation ensures multi-agent coordination produced value. Agent Zero validates integration quality and cross-domain correctness, NOT individual specialist expertise. Focus is on synthesis success: requirements met, domains respected, conflicts resolved, synergies leveraged.
    </rationale>
    
    <note type="validation_focus">
    Agent Zero validates WHAT was integrated (requirements, consistency, completeness) not HOW specialists approached their domains (implementation, architecture, security design, infrastructure patterns, test strategies). Trust specialist expertise while ensuring synthesis quality.
    </note>
  </phase>

  <phase id="6" name="Integration Phase - Merge Into Project Deliverables" gate="integration_gate">
    <description>
    Integrate validated multi-agent guidance into project deliverables. This phase ensures specialist recommendations properly incorporated across architecture, security, infrastructure, and testing documentation, with cross-domain decisions documented for future reference.
    
    **Integration Activities:**
    - Incorporate architecture guidance into system design documents
    - Add security guidance to security architecture and policies
    - Merge infrastructure guidance into deployment and operations docs
    - Integrate testing guidance into quality assurance plans
    - Document multi-agent coordination decisions for precedent
    - Ensure cross-domain context preserved for maintenance
    
    **Integration Principle:** Multi-agent guidance enriches project comprehensively—preserve cross-domain context and coordination patterns for long-term value.
    </description>
    
    <inputs>
    - Validated integrated guidance from Phase 5
    - Individual specialist outputs (Alex, Frank, William, Julia)
    - Multi-agent synthesis rationale and conflict resolutions
    - Project deliverables requiring multi-domain integration
    - Cross-domain decisions and coordination patterns
    - Original task requirements and constraints
    </inputs>
    
    <actions>
    1. **Incorporate architecture guidance** - Merge Alex's recommendations into system design
    2. **Add security guidance** - Integrate Frank's recommendations into security architecture
    3. **Merge infrastructure guidance** - Incorporate William's recommendations into deployment docs
    4. **Integrate testing guidance** - Add Julia's recommendations into quality assurance plans
    5. **Document multi-agent decisions** - Capture cross-domain coordination patterns for precedent
    6. **Preserve cross-domain context** - Ensure specialist relationships and dependencies documented
    7. **Update project documentation** - Reflect multi-domain guidance throughout deliverables
    8. **Create coordination summary** - Document multi-agent synthesis outcomes
    9. **Validate integration completeness** - Confirm all specialist guidance incorporated
    10. **Prepare handoff documentation** - Ensure future work can leverage multi-agent patterns
    </actions>
    
    <outputs>
    - **Integrated Project Deliverables** - Documents reflecting architecture, security, infrastructure, testing guidance
    - **Architecture Integration** - Alex's guidance merged into system design
    - **Security Integration** - Frank's guidance incorporated into security architecture
    - **Infrastructure Integration** - William's guidance added to deployment documentation
    - **Testing Integration** - Julia's guidance integrated into quality assurance plans
    - **Multi-Agent Decision Log** - Cross-domain coordination patterns documented
    - **Cross-Domain Context Preservation** - Specialist relationships and dependencies captured
    - **Coordination Summary** - What multi-agent work occurred and why documented
    </outputs>
    
    <quality_gate name="integration_gate">
    **Pass Criteria:**
    - Architecture guidance incorporated into project deliverables
    - Security guidance integrated into security documentation
    - Infrastructure guidance merged into deployment docs
    - Testing guidance added to quality assurance plans
    - Multi-agent coordination decisions documented
    - Cross-domain context preserved for maintenance
    - Integration complete across all specialist domains
    - Multi-agent changes traceable and documented
    
    **Fail Actions:**
    - Incomplete architecture integration → Merge remaining Alex guidance
    - Missing security integration → Add Frank's recommendations to security docs
    - Incomplete infrastructure integration → Incorporate William's guidance into deployment
    - Missing testing integration → Add Julia's recommendations to QA plans
    - Undocumented multi-agent decisions → Capture cross-domain coordination patterns
    - Lost cross-domain context → Preserve specialist relationships and dependencies
    </quality_gate>
    
    <duration>60-90 minutes (comprehensive multi-domain integration and documentation)</duration>
    
    <note type="integration_value">
    Multi-agent integration is not just about adding specialist outputs—it's about capturing cross-domain coordination expertise that benefits future work. Document WHY specialists were coordinated, HOW their outputs were synthesized, WHAT conflicts were resolved, and WHICH patterns emerged. This multi-agent knowledge is valuable beyond immediate task.
    </note>
  </phase>

  <phase id="7" name="Learning Phase - Document Multi-Agent Patterns" gate="learning_gate">
    <description>
    Complete multi-agent coordination cycle by documenting outcomes, tracking cross-domain action items, and capturing coordination lessons. This phase ensures multi-agent work properly closed, coordination knowledge preserved, and Agent Zero learns to improve future multi-agent orchestration.
    
    **Learning Components:**
    - **Coordination Summary:** What multi-agent work was done, which specialists involved, what was synthesized
    - **Cross-Domain Lessons:** Multi-agent coordination insights, synthesis patterns learned, integration improvements identified
    - **Action Items:** Follow-up tasks across multiple domains
    - **Knowledge Capture:** Multi-agent precedents, coordination patterns, conflict resolution strategies for future reference
    - **Efficiency Analysis:** What could improve multi-agent coordination next time
    
    **Learning Goal:** Improve multi-agent coordination efficiency and effectiveness over time through documented patterns and coordination lessons.
    </description>
    
    <inputs>
    - Integrated project deliverables with multi-agent guidance
    - Individual specialist outputs and rationales
    - Multi-agent synthesis and conflict resolutions
    - Validation results and integration outcomes
    - Original multi-agent coordination plan
    - Coordination process observations and cross-domain insights
    </inputs>
    
    <actions>
    1. **Document coordination outcomes** - Summarize multi-agent work done, specialists involved, guidance synthesized
    2. **Capture cross-domain lessons** - Record multi-agent coordination insights and synthesis patterns learned
    3. **Identify action items** - List follow-up tasks across architecture, security, infrastructure, testing domains
    4. **Extract multi-agent precedents** - Document coordination patterns, conflict resolution strategies for future reference
    5. **Assess coordination efficiency** - Evaluate what could improve multi-agent orchestration next time
    6. **Update coordination knowledge** - Internalize multi-agent patterns to improve future synthesis
    7. **Thank specialists** - Acknowledge contributions from Alex, Frank, William, Julia
    8. **Archive coordination record** - Save complete multi-agent orchestration documentation
    9. **Update cross-domain inventory** - Record coordination patterns and synthesis strategies
    10. **Prepare coordination handoff** - Document multi-agent patterns for future use
    </actions>
    
    <outputs>
    - **Coordination Summary** - Multi-agent work completed, specialists involved, guidance synthesized
    - **Cross-Domain Lessons** - Multi-agent coordination insights and synthesis patterns learned
    - **Action Items** - Follow-up tasks across multiple specialist domains
    - **Precedent Documentation** - Coordination patterns, conflict resolution strategies for future reference
    - **Efficiency Analysis** - Multi-agent coordination improvement opportunities identified
    - **Knowledge Update** - Coordination principles internalized for future multi-agent work
    - **Specialist Acknowledgment** - Recognition of contributions from all involved agents
    - **Coordination Archive** - Complete multi-agent orchestration record preserved
    </outputs>
    
    <quality_gate name="learning_gate">
    **Pass Criteria:**
    - Coordination outcomes documented comprehensively
    - Cross-domain lessons captured clearly
    - Action items identified across all domains
    - Multi-agent precedents extracted for future reference
    - Coordination efficiency assessed honestly
    - Coordination knowledge updated in Agent Zero's understanding
    - All specialists acknowledged for contributions
    - Complete multi-agent coordination record archived
    
    **Fail Actions:**
    - Incomplete coordination documentation → Add multi-agent outcomes and synthesis details
    - Missing cross-domain lessons → Capture coordination insights and patterns
    - Untracked action items → List follow-up tasks across domains
    - Lost multi-agent precedents → Document coordination patterns and conflict resolutions
    - No efficiency analysis → Evaluate multi-agent coordination improvements
    </quality_gate>
    
    <duration>30-45 minutes (comprehensive multi-agent learning capture)</duration>
    
    <rationale>
    Learning phase is Agent Zero's competitive advantage. Each multi-agent coordination teaches about cross-domain patterns, synthesis strategies, and conflict resolution. Documenting these lessons improves future coordination efficiency and effectiveness. Multi-agent coordination knowledge compounds over time.
    </rationale>
    
    <note type="learning_evolution">
    Agent Zero's multi-agent coordination capability evolves through experience. Early coordinations require comprehensive strategy planning. Mature coordinations leverage documented patterns for faster, more effective synthesis. Goal is not reducing specialist invocations but improving coordination efficiency and synthesis quality when multiple agents are genuinely needed.
    </note>
  </phase>
</phases>

<quality_gates>
  <gate name="analysis_gate" phase="1">
    **Purpose:** Ensure proper multi-agent coordination need assessment
    
    **Pass Criteria:**
    - All relevant specialist domains identified
    - Domain complexity honestly assessed across architecture, security, infrastructure, testing
    - Cross-domain dependencies mapped clearly
    - Coordination sequence justified (sequential vs. parallel)
    - Integration approach defined
    - Conflict potential recognized and planned for
    - Multi-agent coordination plan complete and rational
    
    **Fail Actions:**
    - Missing specialist domains → Re-analyze task for additional domain requirements
    - Unclear cross-domain dependencies → Map relationships between specialists
    - Unjustified coordination sequence → Clarify why sequential or parallel
    - Undefined integration approach → Plan how to synthesize outputs
    - Unrecognized conflict potential → Assess where contradictions likely
    </gate>

  <gate name="strategy_gate" phase="2">
    **Purpose:** Validate multi-agent coordination strategy completeness
    
    **Pass Criteria:**
    - Context preparation planned for each specialist agent
    - Handoff protocol clearly defined for multi-agent coordination
    - Synthesis approach established for integrating outputs
    - Conflict resolution mechanisms ready for contradictions
    - Quality validation planned for cross-domain verification
    - Timeline coordinated across multiple specialists
    - Integration framework structured for unified deliverable
    - Coordination risks identified and mitigated
    
    **Fail Actions:**
    - Incomplete context plans → Define what each specialist needs
    - Unclear handoff protocol → Establish multi-agent work transfer process
    - Undefined synthesis approach → Plan output integration method
    - Missing conflict resolution → Prepare contradiction handling mechanisms
    - No cross-domain validation plan → Define verification approach
    - Uncoordinated timelines → Align specialist schedules
    </gate>

  <gate name="coordination_gate" phase="3">
    **Purpose:** Confirm successful multi-agent coordination execution
    
    **Pass Criteria:**
    - All planned specialist agents successfully invoked
    - Context properly prepared for each specialist
    - Handoff protocol executed as planned (sequential or parallel)
    - Cross-domain information flow maintained throughout
    - All specialists completed their work autonomously
    - Specialist outputs captured for synthesis
    - No coordination breakdowns or failures
    
    **Fail Actions:**
    - Failed specialist invocation → Troubleshoot context and retry
    - Insufficient context provided → Supplement with additional information
    - Broken handoff protocol → Re-establish coordination sequence
    - Lost cross-domain information → Reconstruct context flow
    - Incomplete specialist work → Investigate blockers and resolve
    </gate>

  <gate name="synthesis_gate" phase="4">
    **Purpose:** Ensure quality multi-agent output integration
    
    **Pass Criteria:**
    - All specialist outputs properly compiled
    - Consistency analyzed across architecture, security, infrastructure, testing domains
    - Conflicts identified and appropriately resolved
    - Synergies recognized and documented
    - Gaps detected and addressed
    - Integration complete and coherent across all domains
    - Synthesis rationale clearly documented
    - Unified deliverable production-ready
    
    **Fail Actions:**
    - Incomplete compilation → Gather missing specialist outputs
    - Unanalyzed consistency → Compare recommendations across domains
    - Unresolved conflicts → Address contradictions appropriately
    - Missed synergies → Identify specialist reinforcement opportunities
    - Undetected gaps → Analyze for missing cross-domain considerations
    - Incoherent integration → Restructure for unified guidance
    </gate>

  <gate name="validation_gate" phase="5">
    **Purpose:** Verify cross-domain correctness of integrated guidance
    
    **Pass Criteria:**
    - All task requirements addressed in integrated guidance
    - Synthesis respects architecture constraints (Alex's domain)
    - Synthesis respects security constraints (Frank's domain)
    - Synthesis respects infrastructure constraints (William's domain)
    - Synthesis respects testing constraints (Julia's domain)
    - Cross-domain recommendations coherent and consistent
    - Conflicts appropriately resolved with documented rationale
    - Synergies between specialists leveraged effectively
    - All necessary domains covered completely
    - Integrated guidance production-ready
    
    **Fail Actions:**
    - Missing requirements → Add task requirements to integrated guidance
    - Domain constraint violations → Revise synthesis to respect specialist limits
    - Cross-domain inconsistencies → Harmonize recommendations
    - Poor conflict resolution → Re-address contradictions appropriately
    - Missed synergies → Identify and leverage specialist reinforcements
    - Incomplete domain coverage → Address missing considerations
    </gate>

  <gate name="integration_gate" phase="6">
    **Purpose:** Validate complete multi-domain integration into project
    
    **Pass Criteria:**
    - Architecture guidance incorporated into project deliverables
    - Security guidance integrated into security documentation
    - Infrastructure guidance merged into deployment docs
    - Testing guidance added to quality assurance plans
    - Multi-agent coordination decisions documented for precedent
    - Cross-domain context preserved for maintenance
    - Integration complete across all specialist domains
    - Multi-agent changes traceable and well-documented
    
    **Fail Actions:**
    - Incomplete architecture integration → Merge remaining Alex guidance
    - Missing security integration → Add Frank's recommendations
    - Incomplete infrastructure integration → Incorporate William's guidance
    - Missing testing integration → Add Julia's recommendations
    - Undocumented multi-agent decisions → Capture coordination patterns
    - Lost cross-domain context → Preserve specialist relationships
    </gate>

  <gate name="learning_gate" phase="7">
    **Purpose:** Ensure proper multi-agent learning capture
    
    **Pass Criteria:**
    - Coordination outcomes documented comprehensively
    - Cross-domain lessons captured clearly
    - Action items identified across all specialist domains
    - Multi-agent precedents extracted for future reference
    - Coordination efficiency assessed honestly
    - Coordination knowledge updated in Agent Zero's understanding
    - All specialists acknowledged for contributions
    - Complete multi-agent coordination record archived
    
    **Fail Actions:**
    - Incomplete coordination documentation → Add multi-agent outcomes
    - Missing cross-domain lessons → Capture coordination insights
    - Untracked action items → List follow-up tasks across domains
    - Lost multi-agent precedents → Document patterns and resolutions
    - No efficiency analysis → Evaluate coordination improvements
    </gate>
</quality_gates>

<coordination_patterns>
  <pattern name="Sequential Coordination with Context Flow">
  **Scenario:** Task has clear domain dependencies requiring specialists in sequence
  
  **Pattern:**
  1. Identify dependency chain (e.g., Security → Architecture → Infrastructure → Testing)
  2. Invoke first specialist (Frank) with base context
  3. Capture Frank's output completely
  4. Prepare context for second specialist (Alex) including Frank's output
  5. Invoke Alex with enhanced context
  6. Repeat for remaining specialists (William, Julia)
  7. Synthesize all outputs maintaining dependency chain
  
  **Example:** Authentication system deployment
  - Frank defines security requirements first
  - Alex designs architecture accommodating security
  - William implements infrastructure supporting architecture
  - Julia validates all layers working together
  
  **Advantages:** Clear context flow, specialists build on each other
  **Challenges:** Longer timeline, serial dependencies
  </pattern>

  <pattern name="Parallel Coordination with Shared Context">
  **Scenario:** Task has independent domain concerns allowing concurrent work
  
  **Pattern:**
  1. Prepare comprehensive base context shared by all specialists
  2. Prepare specialist-specific context for each agent
  3. Invoke all specialists simultaneously (Alex + Frank + William + Julia)
  4. Monitor concurrent work without interference
  5. Collect outputs from all specialists
  6. Synthesize outputs addressing any cross-domain overlaps
  
  **Example:** Comprehensive documentation project
  - All specialists can write their domain sections concurrently
  - Each works independently on architecture, security, infrastructure, testing docs
  - Agent Zero synthesizes into unified documentation structure
  
  **Advantages:** Faster timeline, concurrent progress
  **Challenges:** Potential overlaps, post-coordination synthesis effort
  </pattern>

  <pattern name="Hybrid Coordination">
  **Scenario:** Task has both dependencies and independent concerns
  
  **Pattern:**
  1. Identify which specialists can work in parallel
  2. Identify which specialists must be sequential
  3. Start parallel specialists first (e.g., Alex + Frank simultaneously)
  4. Synthesize parallel outputs
  5. Invoke sequential specialist with synthesized context (William needs Alex + Frank)
  6. Complete with final specialist (Julia needs all)
  
  **Example:** New service deployment
  - Alex and Frank work in parallel (architecture and security independently)
  - Synthesize architecture + security
  - William implements infrastructure supporting both
  - Julia validates integrated system
  
  **Advantages:** Balances speed with dependencies
  **Challenges:** Complex coordination requiring careful planning
  </pattern>

  <pattern name="Iterative Refinement">
  **Scenario:** Task requires multiple coordination rounds for convergence
  
  **Pattern:**
  1. First round: All specialists provide initial guidance
  2. Synthesize outputs, identify conflicts and gaps
  3. Second round: Specialists address conflicts and gaps
  4. Synthesize refined outputs
  5. Repeat if necessary until convergence
  
  **Example:** Complex system architecture with tight constraints
  - Round 1: Specialists propose solutions
  - Synthesis reveals conflicts (security vs. performance, infrastructure vs. cost)
  - Round 2: Specialists refine proposals addressing conflicts
  - Final synthesis achieves balanced solution
  
  **Advantages:** Handles complex tradeoffs, achieves optimal solutions
  **Challenges:** Time-intensive, requires multiple specialist invocations
  </pattern>

  <pattern name="Conflict-Driven Coordination">
  **Scenario:** Known high conflict potential between domains
  
  **Pattern:**
  1. Invoke specialists independently
  2. Expect contradictions (e.g., security vs. usability, quality vs. speed)
  3. Document conflicts comprehensively
  4. Facilitate specialist discussion of tradeoffs
  5. Escalate legitimate tradeoffs to user for decision
  6. Synthesize based on resolution
  
  **Example:** User experience vs. security tradeoff
  - Frank proposes strict security controls
  - Alex proposes user-friendly architecture
  - Conflict: Security adds friction, architecture prioritizes ease
  - Resolution: User decides acceptable security/usability balance
  - Synthesis: Integrated design reflecting chosen tradeoff
  
  **Advantages:** Explicit tradeoff management, informed decisions
  **Challenges:** Requires user involvement, conflict resolution expertise
  </pattern>
</coordination_patterns>

<conflict_resolution>
  <scenario name="Legitimate Domain Tradeoffs">
  **Situation:** Specialists recommend contradictory approaches due to legitimate domain priorities
  
  **Example:** Frank (Security) wants encryption overhead, William (Infrastructure) concerned about performance impact
  
  **Resolution Protocol:**
  1. **Recognize legitimate tradeoff** - Both specialists correct within their domains
  2. **Document tradeoff clearly:**
     - Security benefit of Frank's approach
     - Performance cost per William's analysis
     - Implications of choosing either direction
  3. **Escalate to user** - Tradeoff requires user decision on priorities
  4. **Implement chosen direction** - Respect user's priority decision
  5. **Document decision rationale** - Record why chosen for future reference
  
  **Guiding Principle:** Agent Zero doesn't override specialist expertise. Legitimate tradeoffs escalate to user who owns priority decisions.
  </scenario>

  <scenario name="Miscommunication Between Specialists">
  **Situation:** Specialists appear to contradict but actually addressing different aspects
  
  **Example:** Alex (Architecture) says "use microservices," William (Infrastructure) says "keep it simple"
  
  **Resolution Protocol:**
  1. **Investigate apparent contradiction** - Are specialists actually disagreeing or talking past each other?
  2. **Clarify specialist contexts:**
     - What problem is Alex solving? (Scalability architecture)
     - What problem is William solving? (Operational complexity)
  3. **Discover alignment** - Both can be right addressing different concerns
  4. **Synthesize coherently** - "Use microservices architecture (Alex) with simple deployment (William): containerize services but deploy as monolith initially, refactor to distributed later"
  5. **Confirm with specialists** - Verify synthesized approach acceptable
  
  **Guiding Principle:** Apparent contradictions often reflect miscommunication or different concern layers. Agent Zero's synthesis role includes discovering hidden alignment.
  </scenario>

  <scenario name="Scope Disagreement">
  **Situation:** Specialists have different understanding of task scope
  
  **Example:** Alex designs elaborate architecture, William assumes minimal viable infrastructure
  
  **Resolution Protocol:**
  1. **Recognize scope mismatch** - Specialists operating on different assumptions
  2. **Clarify actual task scope** - What is user really asking for?
  3. **Re-engage specialists with aligned scope:**
     - "Alex, scope is MVP not full system—adjust architecture accordingly"
     - "William, architecture complexity requires more infrastructure—adjust plan"
  4. **Synthesize with consistent scope** - Ensure all recommendations match reality
  5. **Document scope for future** - Prevent recurrence
  
  **Guiding Principle:** Scope mismatches are Agent Zero's responsibility. Provide clear, consistent scope to all specialists.
  </scenario>

  <scenario name="Priority Conflicts">
  **Situation:** Specialists prioritize different aspects creating tension
  
  **Example:** Julia (Testing) wants comprehensive test coverage delaying timeline, user wants fast delivery
  
  **Resolution Protocol:**
  1. **Acknowledge competing priorities** - Quality vs. speed is legitimate tension
  2. **Consult with specialist on options:**
     - Julia, what's minimum viable test coverage for acceptable quality?
     - What testing can be done incrementally post-launch?
  3. **Present options to user with tradeoffs:**
     - Option A: Full testing, delayed launch, high confidence
     - Option B: Core testing now, comprehensive testing post-launch, medium confidence, faster
  4. **Implement user decision** - Respect priority choice
  5. **Document decision and risks** - Record chosen path and accepted tradeoffs
  
  **Guiding Principle:** Quality vs. speed decisions belong to user. Agent Zero facilitates informed choice by presenting options with tradeoffs.
  </scenario>

  <scenario name="Infrastructure Philosophy Constraints">
  **Situation:** Architecture specialist proposes approach conflicting with infrastructure philosophy

  **Example:** Alex (Architecture) designs containerized microservices architecture, but William (Infrastructure) operates bare metal first shop where production/staging use native packages + systemd (Docker dev-only)

  **Resolution Protocol:**
  1. **Recognize infrastructure philosophy constraint** - HX-Infrastructure is bare metal first for production/staging
  2. **Understand architectural intent** - What problem is Alex solving with containerization?
  3. **Explore alternatives with Alex:**
     - Can architecture goals be achieved with bare metal deployment?
     - Is this genuinely Docker-required or can native packages work?
     - Is this dev environment (Docker allowed) or production (bare metal required)?
  4. **Document tradeoff if genuine conflict:**
     - Architectural benefit of containerization
     - Infrastructure philosophy constraint (bare metal first)
     - Implications of choosing either direction
  5. **Escalate to user if necessary** - Deployment philosophy decisions are CAIO authority
  6. **Synthesize chosen direction** - Respect decision and coordinate both specialists accordingly

  **Guiding Principle:** HX-Infrastructure's bare metal first philosophy is strategic decision by CAIO. Agent Zero respects this constraint during multi-agent coordination. If architectural needs genuinely require Docker in production, escalate to user (CAIO) for strategic decision.
  </scenario>
</conflict_resolution>

<agent_selection_framework>
  <decision_tree>
  ```
  AGENT SELECTION DECISION TREE
  ══════════════════════════════════════════════════════════════════════════
  
  Start: New task requires specialist expertise?
    │
    ├─ ARCHITECTURE CONCERNS?
    │   ├─ System design, patterns, ADRs? → YES: Invoke Alex
    │   ├─ Component relationships, interfaces? → YES: Invoke Alex
    │   ├─ Technology selection, architecture docs? → YES: Invoke Alex
    │   └─ No architecture complexity → Continue evaluation
    │
    ├─ SECURITY CONCERNS?
    │   ├─ Identity, authentication, authorization? → YES: Invoke Frank
    │   ├─ DNS, certificates, trust infrastructure? → YES: Invoke Frank
    │   ├─ Security policies, zones, access control? → YES: Invoke Frank
    │   └─ No security complexity → Continue evaluation
    │
    ├─ INFRASTRUCTURE CONCERNS?
    │   ├─ OS configuration, system services? → YES: Invoke William
    │   ├─ Deployment procedures, operations? → YES: Invoke William
    │   ├─ System monitoring, health checks? → YES: Invoke William
    │   └─ No infrastructure complexity → Continue evaluation
    │
    ├─ TESTING/QUALITY CONCERNS?
    │   ├─ Test planning, test cases, validation? → YES: Invoke Julia
    │   ├─ Quality gates, acceptance criteria? → YES: Invoke Julia
    │   ├─ Test execution, defect management? → YES: Invoke Julia
    │   └─ No testing complexity → Continue evaluation
    │
    └─ RESULT:
        ├─ One domain → Single-agent orchestration (cc-orchestrate-[agent])
        ├─ Multiple domains → Multi-agent synthesis (cc-agent-zero-synthesis)
        └─ No specialist domains → Agent Zero proceeds independently
  
  COORDINATION MODE SELECTION:
  ══════════════════════════════════════════════════════════════════════════
  
  If multiple agents needed, determine coordination mode:
  
  ┌─ Are there dependencies between specialist domains?
  │
  ├─ YES → Sequential Coordination
  │   └─ Order specialists by dependency chain
  │       Example: Security → Architecture → Infrastructure → Testing
  │
  ├─ NO → Parallel Coordination
  │   └─ Invoke all specialists simultaneously
  │       Example: Independent documentation sections
  │
  └─ MIXED → Hybrid Coordination
      └─ Some parallel, some sequential
          Example: (Architecture + Security) → Infrastructure → Testing
  ```
  </decision_tree>

  <selection_matrix>
  ```
  TASK COMPLEXITY vs. COORDINATION APPROACH
  ══════════════════════════════════════════════════════════════════════════
  
  Task Complexity          | Single Agent | Multi-Agent | User Direct
  ─────────────────────────┼──────────────┼─────────────┼─────────────
  Simple (1 domain)        |      ✓       |             |      ✓
  Moderate (1-2 domains)   |      ✓       |      ✓      |
  Complex (2-3 domains)    |              |      ✓      |
  Very Complex (3+ domains)|              |      ✓      |
  ─────────────────────────┴──────────────┴─────────────┴─────────────
  
  Examples by Category:
  
  Simple → Direct or Single Agent:
    • Update documentation (Agent Zero directly)
    • Review code for patterns (Alex only)
    • Check security policy (Frank only)
  
  Moderate → Single or Multi-Agent:
    • New API endpoint (Alex for design + Julia for tests)
    • Security policy update (Frank + maybe William for implementation)
  
  Complex → Multi-Agent Required:
    • New authentication system (Frank → Alex → William → Julia)
    • Service deployment (Alex + Frank → William → Julia)
  
  Very Complex → Multi-Agent with Multiple Rounds:
    • Infrastructure migration (All agents, iterative refinement)
    • Major architecture redesign (All agents, conflict-driven)
  ```
  </selection_matrix>
</agent_selection_framework>

<guiding_principles>
  <principle name="Strategic Agent Selection">
  Not every task requires multi-agent coordination. Use single-agent orchestration for clear domain-specific work. Reserve multi-agent synthesis for tasks genuinely spanning domains or requiring specialist reconciliation.
  </principle>

  <principle name="Respect Specialist Autonomy">
  Each specialist (Alex, Frank, William, Julia) operates autonomously within their domain. Agent Zero coordinates, doesn't override. Trust specialist expertise even when synthesizing across domains.
  </principle>

  <principle name="Context Continuity">
  Multi-agent coordination requires careful context management. Each specialist needs domain-specific context PLUS cross-domain awareness. Maintain context flow throughout coordination.
  </principle>

  <principle name="Synthesis Over Compilation">
  Multi-agent value comes from synthesis, not just compilation. Reconcile conflicts, find synergies, create unified guidance greater than sum of parts. Simple compilation fails to leverage multi-agent potential.
  </principle>

  <principle name="Explicit Conflict Resolution">
  Specialist contradictions are natural when domains have different priorities. Resolve conflicts explicitly: clarify miscommunications, document legitimate tradeoffs, escalate priority decisions to user.
  </principle>

  <principle name="Document Coordination Patterns">
  Multi-agent coordination generates reusable patterns. Document what worked, what conflicts arose, how synthesis succeeded. These patterns improve future coordination efficiency.
  </principle>

  <principle name="Quality Over Speed in Coordination">
  Multi-agent coordination takes time. Never rush synthesis to meet timeline at quality's expense. Poor synthesis negates specialist value and creates rework.
  </principle>

  <principle name="Learn and Evolve">
  Every multi-agent coordination teaches about cross-domain patterns, synthesis strategies, conflict resolution. Capture lessons to improve future coordination. Agent Zero's meta-orchestration capability evolves through experience.
  </principle>

  <principle name="Respect Infrastructure Philosophy">
  When coordinating multi-agent work involving William (Infrastructure), Agent Zero must respect HX-Infrastructure's bare metal first philosophy. Production/staging deployments use native OS packages with systemd (no Docker). Docker is ONLY used on dev server for project isolation. Ansible Vault is used for credential management; Ansible playbooks are NOT used. When Alex (Architecture) proposes containerization or automation and William must implement, recognize this as potential legitimate domain tradeoff requiring synthesis and possibly user decision on deployment approach.
  </principle>
</guiding_principles>

<visual_diagrams>
  <workflow_diagram>
  ```
  MULTI-AGENT COORDINATION WORKFLOW
  ══════════════════════════════════════════════════════════════════════════
  
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 1: ANALYSIS - Which Agents and What Sequence?                 │
  │ Duration: 15-30 min                                                  │
  ├──────────────────────────────────────────────────────────────────────┤
  │ • Map task to specialist domains                                     │
  │ • Assess domain complexity                                           │
  │ • Analyze cross-domain dependencies                                  │
  │ • Determine coordination sequence                                    │
  │ • Evaluate integration difficulty                                    │
  │ • Identify conflict potential                                        │
  │ • Select coordination strategy                                       │
  │                                                                      │
  │ Gate: analysis_gate                                                  │
  │ ✓ Multi-agent coordination plan complete                             │
  │ ✓ Domain dependencies mapped                                         │
  │ ✓ Coordination strategy selected                                     │
  └──────────────┬───────────────────────────────────────────────────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 2: STRATEGY - Plan Multi-Agent Coordination                   │
  │ Duration: 30-60 min                                                  │
  ├──────────────────────────────────────────────────────────────────────┤
  │ • Plan context preparation for each agent                            │
  │ • Design handoff protocol                                            │
  │ • Define synthesis approach                                          │
  │ • Establish conflict resolution                                      │
  │ • Plan quality validation                                            │
  │ • Coordinate timelines                                               │
  │ • Prepare integration framework                                      │
  │ • Document coordination strategy                                     │
  │                                                                      │
  │ Gate: strategy_gate                                                  │
  │ ✓ Comprehensive coordination strategy                                │
  │ ✓ Handoff protocol defined                                           │
  │ ✓ Synthesis approach established                                     │
  └──────────────┬───────────────────────────────────────────────────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 3: COORDINATION - Execute Multi-Agent Handoffs                │
  │ Duration: Variable (2-8 hours for all specialists)                   │
  ├──────────────────────────────────────────────────────────────────────┤
  │ SEQUENTIAL MODE:                                                     │
  │ • Invoke Agent 1 → Capture output                                    │
  │ • Invoke Agent 2 with Agent 1 context → Capture output              │
  │ • Invoke Agent 3 with Agents 1+2 context → Capture output           │
  │ • Continue chain maintaining context flow                            │
  │                                                                      │
  │ PARALLEL MODE:                                                       │
  │ • Invoke all agents simultaneously                                   │
  │ • Monitor concurrent work                                            │
  │ • Collect all outputs                                                │
  │                                                                      │
  │ Gate: coordination_gate                                              │
  │ ✓ All specialists completed work                                     │
  │ ✓ Outputs captured for synthesis                                     │
  │ ✓ Context continuity maintained                                      │
  └──────────────┬───────────────────────────────────────────────────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 4: SYNTHESIS - Integrate Multi-Agent Outputs                  │
  │ Duration: 45-90 min                                                  │
  ├──────────────────────────────────────────────────────────────────────┤
  │ • Compile specialist outputs                                         │
  │ • Analyze for consistency                                            │
  │ • Identify conflicts                                                 │
  │ • Understand conflict rationale                                      │
  │ • Resolve conflicts appropriately                                    │
  │ • Find synergies between specialists                                 │
  │ • Check for gaps                                                     │
  │ • Integrate outputs into unified guidance                            │
  │                                                                      │
  │ Gate: synthesis_gate                                                 │
  │ ✓ Conflicts resolved appropriately                                   │
  │ ✓ Synergies leveraged                                                │
  │ ✓ Unified deliverable created                                        │
  └──────────────┬───────────────────────────────────────────────────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 5: VALIDATION - Verify Cross-Domain Correctness               │
  │ Duration: 30-60 min                                                  │
  ├──────────────────────────────────────────────────────────────────────┤
  │ • Validate requirements coverage                                     │
  │ • Check domain correctness (all specialists)                         │
  │ • Assess cross-domain consistency                                    │
  │ • Review conflict resolution quality                                 │
  │ • Verify synergy realization                                         │
  │ • Evaluate completeness across domains                               │
  │                                                                      │
  │ Gate: validation_gate                                                │
  │ ✓ All requirements addressed                                         │
  │ ✓ All domains respected                                              │
  │ ✓ Cross-domain consistency confirmed                                 │
  └──────────────┬───────────────────────────────────────────────────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 6: INTEGRATION - Merge Into Project Deliverables              │
  │ Duration: 60-90 min                                                  │
  ├──────────────────────────────────────────────────────────────────────┤
  │ • Incorporate architecture guidance (Alex)                           │
  │ • Add security guidance (Frank)                                      │
  │ • Merge infrastructure guidance (William)                            │
  │ • Integrate testing guidance (Julia)                                 │
  │ • Document multi-agent decisions                                     │
  │ • Preserve cross-domain context                                      │
  │                                                                      │
  │ Gate: integration_gate                                               │
  │ ✓ All domains integrated                                             │
  │ ✓ Multi-agent decisions documented                                   │
  │ ✓ Cross-domain context preserved                                     │
  └──────────────┬───────────────────────────────────────────────────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │ PHASE 7: LEARNING - Document Multi-Agent Patterns                   │
  │ Duration: 30-45 min                                                  │
  ├──────────────────────────────────────────────────────────────────────┤
  │ • Document coordination outcomes                                     │
  │ • Capture cross-domain lessons                                       │
  │ • Identify action items across domains                               │
  │ • Extract multi-agent precedents                                     │
  │ • Assess coordination efficiency                                     │
  │ • Update coordination knowledge                                      │
  │                                                                      │
  │ Gate: learning_gate                                                  │
  │ ✓ Multi-agent patterns documented                                    │
  │ ✓ Cross-domain lessons captured                                      │
  │ ✓ Coordination knowledge updated                                     │
  └──────────────────────────────────────────────────────────────────────┘
  
  TOTAL ESTIMATED DURATION: 5-12 hours (varies by complexity and agent count)
  ```
  </workflow_diagram>

  <coordination_modes>
  ```
  MULTI-AGENT COORDINATION MODES
  ══════════════════════════════════════════════════════════════════════════
  
  SEQUENTIAL COORDINATION (Dependency Chain):
  ────────────────────────────────────────────────────────────────────────
  
  Agent 1 (Frank)  ──→  Output A  ──┐
                                     ├──→  Agent 2 (Alex)  ──→  Output B  ──┐
                                     │                                       │
  Context Flow                      ─┘                                       ├──→  Agent 3 (William)  ──→  Output C  ──┐
                                                                             │                                           │
                                                                             └───────────────────────────────────────────┤
                                                                                                                         ├──→  Agent 4 (Julia)  ──→  Final
                                                                                                                         │
                                                                                Context Flow                            ─┘
  
  Timeline: ████ Agent 1 ████ Agent 2 ████ Agent 3 ████ Agent 4 ████
  Duration: Long (serial execution)
  Best For: Tasks with clear dependencies
  
  
  PARALLEL COORDINATION (Independent Work):
  ────────────────────────────────────────────────────────────────────────
  
                    ┌──→  Agent 1 (Alex)    ──→  Output A  ──┐
                    │                                         │
  Shared Context  ──┼──→  Agent 2 (Frank)   ──→  Output B  ──┼──→  Synthesis
                    │                                         │
                    ├──→  Agent 3 (William) ──→  Output C  ──┤
                    │                                         │
                    └──→  Agent 4 (Julia)   ──→  Output D  ──┘
  
  Timeline: ████████████████████████████
            ║ Agent 1 ║ Agent 2 ║ Agent 3 ║ Agent 4 ║ (concurrent)
  Duration: Short (parallel execution)
  Best For: Tasks with independent domains
  
  
  HYBRID COORDINATION (Mixed Dependencies):
  ────────────────────────────────────────────────────────────────────────
  
                    ┌──→  Agent 1 (Alex)  ──→  Output A  ──┐
                    │                                       ├──→  Synthesize A+B
  Base Context  ────┤                                       │         │
                    └──→  Agent 2 (Frank) ──→  Output B  ──┘         │
                                                                      ├──→  Agent 3 (William) ──→  Output C  ──┐
                                                                      │                                         │
                                                          Context Flow ┘                                         ├──→  Agent 4 (Julia)  ──→  Final
                                                                                                                 │
                                                                                                 Context Flow  ──┘
  
  Timeline: ████ (Agents 1+2 parallel) ████ Agent 3 ████ Agent 4 ████
  Duration: Medium (mixed execution)
  Best For: Tasks with partial dependencies
  ```
  </coordination_modes>
</visual_diagrams>

<notes>
  <note type="meta_orchestration">
  **Agent Zero's Unique Role**
  
  Agent Zero is Chief AI Officer with meta-orchestration responsibility. Unlike specialist agents (Alex, Frank, William, Julia) who operate within specific domains, Agent Zero operates ACROSS domains:
  
  **Agent Zero's Capabilities:**
  - Strategic agent selection and coordination planning
  - Multi-agent context management and handoff execution
  - Cross-domain synthesis and conflict resolution
  - Integration of diverse specialist outputs
  - Meta-learning about coordination patterns
  
  **Agent Zero's Limitations:**
  - Does NOT possess specialist domain expertise
  - Cannot replace architecture specialist (Alex)
  - Cannot replace security specialist (Frank)
  - Cannot replace infrastructure specialist (William)
  - Cannot replace testing specialist (Julia)
  
  **Agent Zero's Value:**
  - Recognizes when specialist expertise needed
  - Coordinates specialists effectively
  - Synthesizes specialist outputs coherently
  - Resolves cross-domain conflicts appropriately
  - Learns and improves coordination over time
  
  Agent Zero is orchestration expert, not domain expert. Value comes from strategic coordination, not technical implementation.
  </note>

  <note type="synthesis_vs_compilation">
  **Synthesis is Not Compilation**
  
  Multi-agent coordination creates value through synthesis, not just compilation:
  
  **Compilation (Insufficient):**
  - Gather specialist outputs
  - Put them in same document
  - Call it "integrated"
  - Result: Contradictory, disconnected guidance
  
  **Synthesis (Required):**
  - Gather specialist outputs
  - Analyze for consistency and conflicts
  - Reconcile contradictions appropriately
  - Find synergies between specialists
  - Identify gaps in cross-domain coverage
  - Create unified guidance greater than sum of parts
  - Result: Coherent, integrated recommendations
  
  **Synthesis Techniques:**
  - **Conflict Resolution:** Address contradictions explicitly (clarify, tradeoff, escalate)
  - **Synergy Identification:** Find where specialists reinforce each other
  - **Gap Detection:** Recognize missing cross-domain considerations
  - **Context Integration:** Weave specialist outputs into coherent narrative
  - **Tradeoff Documentation:** Explicitly document chosen paths when domains conflict
  
  Synthesis is Agent Zero's core skill in multi-agent coordination.
  </note>

  <note type="learning_evolution">
  **Multi-Agent Coordination Learning Curve**
  
  Agent Zero's multi-agent coordination capability evolves through experience:
  
  **Early Coordinations (Learning Phase):**
  - Comprehensive strategy planning required
  - Careful attention to coordination sequence
  - Detailed conflict resolution preparation
  - Thorough synthesis with extensive documentation
  - Learn from each multi-agent interaction
  
  **Middle Coordinations (Pattern Recognition):**
  - Recognize common coordination patterns
  - Faster strategy development leveraging precedents
  - More efficient context preparation
  - Quicker conflict identification and resolution
  - Improved synthesis quality
  
  **Mature Coordinations (Expertise):**
  - Rapid multi-agent coordination planning
  - Efficient execution using documented patterns
  - Anticipate conflicts before they emerge
  - Smooth synthesis with minimal rework
  - Teach coordination patterns to others
  
  **Continuous Improvement:**
  - Every multi-agent coordination generates lessons
  - Document patterns that work
  - Refine approaches that struggled
  - Build coordination knowledge library
  - Share learnings with specialist agents
  
  Goal: Not reducing specialist invocations but improving coordination efficiency and synthesis quality when multiple agents genuinely needed.
  </note>

  <note type="infrastructure_philosophy">
  **HX-Infrastructure Deployment Philosophy**

  When coordinating multi-agent work involving William (Infrastructure), Agent Zero must respect HX-Infrastructure's strategic deployment philosophy:

  **Bare Metal First for Production/Staging:**
  - Native OS packages (apt/dpkg) with systemd services
  - Traditional configuration files and operational procedures
  - NO Docker containerization (requires CAIO approval)
  - Comprehensive operational runbooks and bash scripts

  **Docker for Dev Server Only:**
  - Docker is ONLY used on hx-dev-server for project isolation
  - Python, React, Next.js development environments use Docker
  - Dev Docker does NOT require CAIO approval (established pattern)
  - Production/staging Docker DOES require CAIO approval (strategic decision)

  **Ansible Vault Only:**
  - Ansible Vault used for centralized credential management
  - Ansible playbooks are NOT used (not on roadmap)
  - Manual operations with documented procedures are current state

  **Multi-Agent Coordination Implications:**

  When Alex (Architecture) + William (Infrastructure) work together:
  - Alex may propose modern containerized architectures
  - William implements using bare metal infrastructure patterns
  - Agent Zero must synthesize: Can architecture goals be achieved with bare metal? If Docker genuinely required for production, escalate to CAIO for strategic decision

  **Example Synthesis:**
  - Alex designs microservices architecture
  - William implements as systemd services (bare metal microservices)
  - Agent Zero validates: Architecture goals met + Infrastructure philosophy respected
  - Result: Modern architecture deployed using infrastructure philosophy

  Infrastructure philosophy is strategic constraint, not technical limitation. Agent Zero respects this during multi-agent coordination and escalates conflicts appropriately.
  </note>
</notes>

<related_documents>
- `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` - All specialist agent details and capabilities
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Alex (Architecture) single-agent orchestration
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Frank (Security) single-agent orchestration
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - William (Infrastructure) single-agent orchestration
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Julia (Testing) single-agent orchestration
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Task breakdown workflow (may involve multiple agents)
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md` - Execution workflow (coordinates specialists as needed)
- `/home/agent0/HX-Infrastructure/constitution.md` - Project governance including multi-agent coordination principles
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Architecture standards (Alex's domain)
- `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Deployment standards (William's domain)
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - Testing standards (Julia's domain)
</related_documents>

<critical_reminders>
1. ⚠️ **Strategic Agent Selection:** Not every task requires multi-agent coordination. Use single-agent orchestration (cc-orchestrate-[agent]) for domain-specific work. Reserve multi-agent synthesis for genuinely cross-domain tasks.

2. ⚠️ **Synthesis Not Compilation:** Multi-agent value comes from synthesis—reconciling conflicts, finding synergies, creating unified guidance. Simple compilation of specialist outputs fails to leverage multi-agent potential.

3. ⚠️ **Respect All Specialist Expertise:** Agent Zero coordinates across domains but doesn't override specialist expertise. Trust Alex (architecture), Frank (security), William (infrastructure), Julia (testing) within their domains.

4. ⚠️ **Context Continuity Critical:** Multi-agent coordination requires careful context management. Each specialist needs domain context PLUS cross-domain awareness. Maintain context flow throughout coordination.

5. ⚠️ **Explicit Conflict Resolution:** Specialist contradictions are natural. Resolve conflicts explicitly: clarify miscommunications, document legitimate tradeoffs, escalate priority decisions to user when appropriate.

6. ⚠️ **Quality Over Speed in Synthesis:** Multi-agent coordination takes time. Never rush synthesis to meet timeline at quality's expense. Poor synthesis negates specialist value and creates expensive rework.

7. ⚠️ **Document Coordination Patterns:** Every multi-agent coordination generates reusable patterns. Document what worked, what conflicts arose, how synthesis succeeded. These patterns improve future efficiency.

8. ⚠️ **Learn and Evolve Continuously:** Multi-agent coordination capability evolves through experience. Capture lessons from each coordination to improve future multi-agent orchestration effectiveness.

9. ⚠️ **Respect Infrastructure Philosophy:** HX-Infrastructure is bare metal first for production/staging. When coordinating Alex (Architecture) + William (Infrastructure), recognize that containerization proposals may conflict with bare metal philosophy. Synthesize appropriately: explore bare metal alternatives first, escalate Docker production use to CAIO for strategic decision. Docker is ONLY used on dev server for project isolation (established pattern).
</critical_reminders>

<validation_checklist>
**Pre-Coordination Validation:**
- [ ] Multi-agent need clearly justified (task spans multiple domains)
- [ ] All relevant specialist domains identified (architecture, security, infrastructure, testing)
- [ ] Cross-domain dependencies mapped
- [ ] Coordination sequence determined (sequential, parallel, hybrid)
- [ ] Integration approach defined

**Strategy Validation:**
- [ ] Context preparation planned for each specialist
- [ ] Handoff protocol clearly defined
- [ ] Synthesis approach established
- [ ] Conflict resolution mechanisms ready
- [ ] Quality validation planned
- [ ] Timeline coordinated across specialists

**Coordination Execution Validation:**
- [ ] All planned specialists successfully invoked
- [ ] Context properly prepared for each specialist
- [ ] Handoff protocol executed as planned
- [ ] Cross-domain information flow maintained
- [ ] All specialists completed work autonomously
- [ ] Specialist outputs captured for synthesis

**Synthesis Validation:**
- [ ] All specialist outputs compiled
- [ ] Consistency analyzed across domains
- [ ] Conflicts identified and appropriately resolved
- [ ] Synergies recognized and documented
- [ ] Gaps detected and addressed
- [ ] Integration complete and coherent
- [ ] Synthesis rationale documented

**Cross-Domain Validation:**
- [ ] All requirements addressed in integrated guidance
- [ ] Architecture constraints respected (Alex's domain)
- [ ] Security constraints respected (Frank's domain)
- [ ] Infrastructure constraints respected (William's domain)
- [ ] Infrastructure philosophy respected (bare metal first for production/staging, Docker dev-only)
- [ ] Testing constraints respected (Julia's domain)
- [ ] Cross-domain consistency confirmed

**Integration Validation:**
- [ ] Architecture guidance incorporated into project deliverables
- [ ] Security guidance integrated into documentation
- [ ] Infrastructure guidance merged into deployment docs
- [ ] Testing guidance added to quality assurance plans
- [ ] Multi-agent decisions documented
- [ ] Cross-domain context preserved

**Learning Validation:**
- [ ] Coordination outcomes documented
- [ ] Cross-domain lessons captured
- [ ] Action items identified across domains
- [ ] Multi-agent precedents extracted
- [ ] Coordination efficiency assessed
- [ ] All specialists acknowledged
</validation_checklist>

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready with Infrastructure Philosophy Integration
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Infrastructure philosophy enhancements)
**Compliance:** 100% semantic XML structure, standardized quality gates, comprehensive multi-agent coordination guidance, HX-Infrastructure philosophy alignment
**Next Steps:** Use this workflow when coordinating complex work requiring multiple specialist agents (Alex, Frank, William, Julia) simultaneously or sequentially
**Semantic XML Compliance:** All phases use standardized `<actions>` tags, quality gates have dedicated wrapper section with pass/fail criteria, critical reminders included with ⚠️ markers
**Infrastructure Philosophy:** Bare metal first for production/staging, Docker dev-only, Ansible Vault only, manual operations current state - respected during multi-agent coordination synthesis
</metadata_footer>