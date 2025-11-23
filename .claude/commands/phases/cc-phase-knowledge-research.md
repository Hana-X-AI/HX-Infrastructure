---
workflow: phase-knowledge-research
version: 1.1
date: 2025-11-20
status: APPROVED
type: phase-command
description: Systematic knowledge vault repository research to gather technical understanding, identify integration patterns, and document findings with confidence levels for charter development
applies_to: charter_workflow, technical_research, knowledge_discovery
author: HX-Infrastructure Team
last_updated: 2025-11-20
update_notes: Standardized integration convention header, infrastructure philosophy alignment
---

<metadata>
**Workflow:** Knowledge Vault Research - Systematic Repository Review
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Standardized integration convention, infrastructure philosophy)
**Status:** APPROVED - Production Ready
**Type:** Phase Command
**Purpose:** Conduct systematic deep-dive research of knowledge vault repositories to gather comprehensive technical understanding, identify integration patterns, document dependencies and constraints, and assess confidence levels for charter development
</metadata>

<objective>
**Purpose:** Systematically research knowledge vault repositories to transform CAIO's initial vision into concrete technical understanding. Research provides the factual foundation for charter creation by discovering actual capabilities, limitations, integration patterns, and implementation requirements from authoritative sources.

**Command Capabilities:**
- Identify relevant knowledge repositories from catalog
- Conduct systematic repository reviews with time-boxed focus
- Document technical capabilities and architectures
- Identify installation and deployment requirements
- Discover integration patterns and protocols
- Assess confidence levels (High/Medium/Low) based on documentation quality
- Track research gaps and unknowns
- Generate findings that inform post-research questions
- Create consolidated research summary for charter

**When to Use This Command:**
- During charter workflow Phase 4 (after initial questions answered, before post-research questions)
- When technical understanding needed for any node/service deployment
- When evaluating competing technical approaches
- When validating feasibility of proposed solutions
- When identifying integration requirements with existing infrastructure
- When assessing risks and constraints for new deployments

**Integration Points:**
- **Called by:** cc-charter-workflow.md (Phase 4)
- **Inputs:** Repository list, initial Q&A responses, CAIO requirements
- **Outputs:** Repository research findings, consolidated research summary, confidence assessments
- **Feeds into:** cc-phase-charter-questions.md (Phase 6 - post-research questions)
</objective>

<utility_overview>
**Core Function:**
This phase command executes systematic knowledge vault research through three research tiers:

**Tier 1: Primary Repository (30-45 minutes)**
Deep dive into the main technology/service being deployed:
- Architecture and design patterns
- Core capabilities and features
- Installation and deployment procedures
- Configuration requirements
- Integration specifications
- Operational characteristics
- Constraints and limitations
- Documentation quality assessment

**Tier 2: Integration Repositories (15-30 minutes each)**
Research each integration point identified in requirements:
- Service functionality and APIs
- Integration patterns and protocols
- Authentication and authorization requirements
- Current deployment status
- Configuration needs
- Version compatibility

**Tier 3: Supporting Repositories (10-15 minutes each)**
Reference materials for standards, protocols, best practices:
- Protocol specifications
- Integration patterns
- Best practices and anti-patterns
- Common pitfalls
- Future considerations

**Key Principle:** Research is time-boxed but thorough. Spend allocated time systematically reviewing each repository, document what's found, assess confidence level, and flag gaps. Perfect understanding isn't required - knowing what's unknown is equally valuable.

**Confidence Assessment Framework:**
- **High Confidence:** Complete documentation, working examples, clear patterns, no significant gaps
- **Medium Confidence:** Good documentation with some gaps, patterns require inference, minor unknowns
- **Low Confidence:** Sparse documentation, significant unknowns, experimental features, major gaps
</utility_overview>

<state_management>
**Stateless Component:**
- This phase command file (instructions + research framework + assessment criteria)
- Research methodology and confidence level definitions
- Repository analysis templates and checklists
- Reusable across all charter development projects

**Stateful Artifacts:**
Phase command execution creates project-specific files:

**Repository Research Files:**
```
/nodes/{node-name}/charter/reviews/knowledge-vault/
  {repo-1-name}-research.md        # Primary repository findings
  {repo-2-name}-research.md        # Integration repository 1 findings
  {repo-3-name}-research.md        # Integration repository 2 findings
  {repo-n-name}-research.md        # Supporting repository findings
  research-summary.md              # Consolidated findings across all repos
  research-gaps.md                 # Documented unknowns and gaps
```

**File Naming Convention:**
- `{repository-name}-research.md` - Individual repository findings
- `research-summary.md` - Consolidated cross-repository analysis
- `research-gaps.md` - Known unknowns and areas requiring clarification
- Use lowercase with hyphens, match repository names from catalog

**File Locations:**
All research artifacts stored in `/nodes/{node-name}/charter/reviews/knowledge-vault/` alongside charter documents for integrated reference during charter generation and post-research question development.

**State Persistence:**
Research artifacts persist throughout project lifecycle, serving as:
- Historical record of technical discovery
- Reference for specification and implementation phases
- Documentation of decisions made based on research
- Knowledge base for future similar projects
- Training data for research methodology refinement
</state_management>

<research_framework>
**Repository Categories:**

Knowledge vault repositories fall into three categories requiring different research depths:

**Category 1: Primary Technology Repository**
The main technology/service being deployed (e.g., Docling, MCP Server SDK, Ollama)

**Research Scope:**
- Architecture and design (30% of time)
- Capabilities and features (25% of time)
- Installation and deployment (20% of time)
- Integration specifications (15% of time)
- Operational aspects (10% of time)

**Time Allocation:** 30-45 minutes
**Output Detail:** Comprehensive findings document (300-500 lines)

**Category 2: Integration Repository**
Services/systems this node will integrate with (e.g., PostgreSQL, Redis, existing MCP servers)

**Research Scope:**
- Service functionality (30% of time)
- Integration patterns (30% of time)
- Current deployment status (20% of time)
- Configuration requirements (20% of time)

**Time Allocation:** 15-30 minutes each
**Output Detail:** Focused findings document (150-300 lines)

**Category 3: Supporting Repository**
Standards, protocols, reference implementations (e.g., MCP Protocol Spec, OAuth standards)

**Research Scope:**
- Protocol/standard specifications (40% of time)
- Integration patterns and examples (30% of time)
- Best practices and pitfalls (20% of time)
- Applicability to current project (10% of time)

**Time Allocation:** 10-15 minutes each
**Output Detail:** Reference findings document (100-200 lines)

**Confidence Level Criteria:**

**High Confidence (Documentation Quality: 8-10/10):**
- Complete, comprehensive documentation
- Tested examples with working code samples
- Clear integration patterns documented
- Active community or official support
- No significant gaps in understanding
- Can proceed to implementation with confidence

**Medium Confidence (Documentation Quality: 5-7/10):**
- Good documentation with some gaps
- Patterns require inference or experimentation
- Some ambiguity in configuration/deployment
- Limited examples, need to extrapolate
- Minor unknowns that can be resolved
- May need POC to validate approach

**Low Confidence (Documentation Quality: 1-4/10):**
- Sparse or incomplete documentation
- Significant unknowns or assumptions required
- Experimental or alpha-quality features
- Complex integration with unclear patterns
- Major gaps requiring research or testing
- Definitely need POC or expert consultation

**Research Documentation Standards:**

Each repository research document must include:
1. Repository metadata (name, location, version, documentation quality)
2. Executive summary (2-3 sentences on key findings)
3. Technical findings organized by category
4. Integration patterns discovered
5. Dependencies and constraints identified
6. Confidence level with justification
7. Questions raised by research
8. Recommendations for next steps
</research_framework>

<research_procedures>
  <procedure name="Research Primary Technology Repository">
  **Purpose:** Conduct comprehensive deep-dive research of primary technology repository to understand architecture, capabilities, deployment requirements, and integration patterns

  **Prerequisites:**
  - Repository list confirmed by CAIO
  - Initial questions answered (basic requirements understood)
  - Knowledge vault catalog reviewed for repository locations

  **Inputs Required:**
  - Primary repository name and location
  - Initial question responses (requirements context)
  - CAIO's stated preferences and constraints
  - HX-Infrastructure current state (for integration context)

  **Time Allocation:** 30-45 minutes (do not exceed)

  **Execution Steps:**

  **STEP 1: Repository Access and Context (5 minutes)**
  Locate and access the primary repository:

  **Actions:**
  1. Navigate to `/home/agent0/HX-Infrastructure/hx-knowledge/repos/{primary-repo}/`
  2. Review repository structure:
     - List main directories
     - Identify documentation files (README, docs/, wiki/)
     - Locate examples directory
     - Find configuration samples
  3. Note repository metadata:
     - Last updated date
     - Version/release information
     - Documentation completeness (initial assessment)
  4. Review initial Q&A responses to focus research

  **Verification:**
  - [ ] Repository located and accessible
  - [ ] Structure understood
  - [ ] Documentation paths identified
  - [ ] Research focus clear from requirements

  **STEP 2: Architecture and Design Research (10-12 minutes)**
  Understand the technical architecture and design patterns:

  **Actions:**
  1. Read architecture overview documentation:
     - System architecture diagram/description
     - Component structure and relationships
     - Design patterns employed
     - Protocol implementations
     - Communication methods (HTTP, gRPC, WebSocket, etc.)

  2. Document findings:
     ```markdown
     ## Architecture & Design
     
     **Overall Architecture:**
     - Type: [client-server | standalone | distributed | microservices]
     - Components: [list major components]
     - Communication: [protocols and methods]
     
     **Component Structure:**
     - [Component 1]: [purpose and relationships]
     - [Component 2]: [purpose and relationships]
     
     **Design Patterns:**
     - [Pattern 1]: [how it's used]
     - [Pattern 2]: [how it's used]
     
     **Protocol Implementations:**
     - [Protocol 1]: [implementation details]
     ```

  3. Assess architecture alignment with requirements:
     - Does architecture support CAIO's use case?
     - Any architectural constraints to flag?
     - Scale and performance implications?

  **Verification:**
  - [ ] Architecture documented
  - [ ] Component relationships understood
  - [ ] Design patterns identified
  - [ ] Alignment with requirements assessed

  **STEP 3: Capabilities and Features Research (8-10 minutes)**
  Document what the technology can and cannot do:

  **Actions:**
  1. Review capabilities documentation:
     - Core functionality list
     - Feature matrix
     - Processing capabilities
     - API endpoints and methods
     - Extension/plugin support
     - Known limitations

  2. Document findings:
     ```markdown
     ## Capabilities & Features
     
     **Core Functionality:**
     - [Capability 1]: [description]
     - [Capability 2]: [description]
     
     **API/Interface:**
     - Endpoints: [list or reference]
     - Methods: [key methods available]
     - Data formats: [supported formats]
     
     **Extension Support:**
     - Plugin system: [Yes/No, details]
     - Customization: [options available]
     
     **Limitations:**
     - [Limitation 1]: [impact]
     - [Limitation 2]: [impact]
     ```

  3. Map capabilities to requirements:
     - Which requirements does this satisfy?
     - Which requirements may need workarounds?
     - Any capability gaps identified?

  **Verification:**
  - [ ] Core capabilities documented
  - [ ] API/interface understood
  - [ ] Limitations identified
  - [ ] Requirements mapping complete

  **STEP 4: Installation and Deployment Research (6-8 minutes)**
  Understand how to deploy and configure this technology:

  **Actions:**
  1. Review installation documentation:
     - OS requirements (version, kernel)
     - Runtime requirements (language version, etc.)
     - Package dependencies
     - System dependencies (libraries, tools)
     - Installation methods (package manager, source, binary)
     - Configuration files needed
     - Environment variables required

  2. Document findings:
     ```markdown
     ## Installation & Deployment
     
     **System Requirements:**
     - OS: [supported operating systems]
     - Runtime: [language/framework versions]
     - Resources: [CPU, RAM, disk requirements]
     
     **Dependencies:**
     - Package: [list package dependencies]
     - System: [list system libraries/tools]
     
     **Installation Methods:**
     - [Method 1]: [steps/commands]
     - [Method 2]: [steps/commands]
     
     **Configuration:**
     - Config files: [list required configs]
     - Environment vars: [list required env vars]
     - Defaults: [note default settings]
     ```

  3. Assess deployment complexity:
     - Straightforward or complex installation?
     - Compatible with HX-Infrastructure environment?
     - Any deployment blockers?

  **Verification:**
  - [ ] System requirements documented
  - [ ] Dependencies identified
  - [ ] Installation methods understood
  - [ ] Configuration requirements clear

  **STEP 5: Integration Specifications Research (5-7 minutes)**
  Understand how this integrates with other systems:

  **Actions:**
  1. Review integration documentation:
     - Integration patterns supported
     - API specifications
     - Authentication/authorization methods
     - Request/response formats
     - Error handling patterns
     - Connection management

  2. Document findings:
     ```markdown
     ## Integration Specifications
     
     **Integration Patterns:**
     - [Pattern 1]: [description]
     - [Pattern 2]: [description]
     
     **API Specification:**
     - Protocol: [HTTP/gRPC/WebSocket/etc.]
     - Authentication: [method]
     - Request format: [JSON/XML/etc.]
     - Response format: [JSON/XML/etc.]
     
     **Connection Management:**
     - [Connection details]
     - [Timeout/retry policies]
     
     **Error Handling:**
     - [Error types and codes]
     - [Recovery patterns]
     ```

  3. Identify integration requirements for HX-Infrastructure:
     - How will this connect to identified integration points?
     - Any authentication complexity?
     - Network configuration needs?

  **Verification:**
  - [ ] Integration patterns documented
  - [ ] API specifications understood
  - [ ] Authentication requirements clear
  - [ ] Error handling patterns identified

  **STEP 6: Operational Aspects and Constraints (4-6 minutes)**
  Understand operational characteristics and limitations:

  **Actions:**
  1. Review operational documentation:
     - Service management (systemd, supervisor, etc.)
     - Logging configuration
     - Monitoring endpoints (health checks, metrics)
     - Performance characteristics
     - Resource requirements
     - Scaling considerations
     - Backup/recovery procedures
     - Security considerations
     - License requirements

  2. Document findings:
     ```markdown
     ## Operational Aspects
     
     **Service Management:**
     - Method: [systemd/supervisor/docker/etc.]
     - Start/stop: [commands]
     
     **Monitoring:**
     - Health check: [endpoint/method]
     - Metrics: [available metrics]
     - Logging: [log location and format]
     
     **Performance:**
     - Throughput: [capacity]
     - Latency: [typical response times]
     - Resource usage: [CPU/RAM patterns]
     
     **Scaling:**
     - Horizontal: [Yes/No, details]
     - Vertical: [considerations]
     
     **Security:**
     - [Security features]
     - [Security considerations]
     
     **License:**
     - Type: [license type]
     - Restrictions: [any usage restrictions]
     ```

  **Verification:**
  - [ ] Service management understood
  - [ ] Monitoring capabilities identified
  - [ ] Performance characteristics documented
  - [ ] Scaling considerations noted
  - [ ] Security and licensing clear

  **STEP 7: Confidence Assessment and Gap Analysis (3-5 minutes)**
  Assess confidence level and identify research gaps:

  **Actions:**
  1. Evaluate documentation quality:
     - Completeness (0-10 scale)
     - Clarity (0-10 scale)
     - Examples quality (0-10 scale)
     - Currency (how recent/maintained)

  2. Assign confidence level:
     ```markdown
     ## Confidence Assessment
     
     **Overall Confidence:** [High | Medium | Low]
     
     **Justification:**
     - Documentation quality: [score/10]
     - Example availability: [score/10]
     - Clarity of patterns: [score/10]
     - Gap assessment: [number of unknowns]
     
     **High Confidence Areas:**
     - [Area 1]: [why confident]
     - [Area 2]: [why confident]
     
     **Medium Confidence Areas:**
     - [Area 1]: [what's unclear]
     - [Area 2]: [what's unclear]
     
     **Low Confidence Areas:**
     - [Area 1]: [what's unknown]
     - [Area 2]: [what's unknown]
     ```

  3. Document research gaps:
     ```markdown
     ## Research Gaps & Questions
     
     **Technical Unknowns:**
     - [Unknown 1]: [what we need to learn]
     - [Unknown 2]: [what we need to learn]
     
     **Integration Uncertainties:**
     - [Uncertainty 1]: [what needs clarification]
     - [Uncertainty 2]: [what needs clarification]
     
     **Questions for Post-Research Phase:**
     - Q1: [Question to ask CAIO]
     - Q2: [Question to ask CAIO]
     
     **Recommended Next Steps:**
     - [Step 1]: [recommended action]
     - [Step 2]: [recommended action]
     ```

  **Verification:**
  - [ ] Confidence level assigned with justification
  - [ ] High confidence areas documented
  - [ ] Medium/low confidence areas identified
  - [ ] Research gaps explicitly stated
  - [ ] Questions for CAIO prepared

  **STEP 8: Create Research Findings Document (2-3 minutes)**
  Formalize findings into structured document:

  **Actions:**
  1. Create `/nodes/{node-name}/charter/reviews/knowledge-vault/{repo-name}-research.md`
  2. Use comprehensive template:
     ```markdown
     # {Repository Name} - Research Findings
     
     **Repository:** {repo-name}
     **Location:** /home/agent0/HX-Infrastructure/hx-knowledge/repos/{repo-name}/
     **Research Date:** {timestamp}
     **Researcher:** Agent Zero
     **Time Invested:** {actual minutes}
     **Documentation Quality:** {score}/10
     
     ---
     
     ## Executive Summary
     
     [2-3 sentence summary of key findings and overall assessment]
     
     ---
     
     ## Architecture & Design
     [All findings from Step 2]
     
     ## Capabilities & Features
     [All findings from Step 3]
     
     ## Installation & Deployment
     [All findings from Step 4]
     
     ## Integration Specifications
     [All findings from Step 5]
     
     ## Operational Aspects
     [All findings from Step 6]
     
     ## Confidence Assessment
     [All assessment from Step 7]
     
     ## Research Gaps & Questions
     [All gaps from Step 7]
     
     ---
     
     ## Recommendations
     
     **For Charter Development:**
     - [Recommendation 1]
     - [Recommendation 2]
     
     **For Post-Research Questions:**
     - [Area 1 needs clarification]
     - [Area 2 needs decision]
     
     **For Implementation Planning:**
     - [Consideration 1]
     - [Consideration 2]
     ```

  **Verification:**
  - [ ] Document created in correct location
  - [ ] All sections complete
  - [ ] Executive summary clear
  - [ ] Recommendations actionable
  - [ ] Ready for charter reference

  **Outputs Generated:**
  - `/nodes/{node-name}/charter/reviews/knowledge-vault/{primary-repo}-research.md` (300-500 lines)

  **Quality Validation:**
  Before moving to next repository, verify:
  - [ ] All 7 research areas covered
  - [ ] Confidence level justified
  - [ ] Gaps explicitly identified
  - [ ] Questions prepared for CAIO
  - [ ] Time limit respected (30-45 minutes)
  - [ ] Findings directly address initial requirements
  </procedure>

  <procedure name="Research Integration Repository">
  **Purpose:** Research integration point repositories to understand service functionality, integration patterns, and current deployment status

  **Prerequisites:**
  - Primary repository research complete
  - Integration points identified in requirements
  - Integration repository confirmed from catalog

  **Inputs Required:**
  - Integration repository name and location
  - Integration requirements from initial Q&A
  - Primary repository findings (for integration context)

  **Time Allocation:** 15-30 minutes per integration repository

  **Execution Steps:**

  **STEP 1: Service Functionality Research (5-8 minutes)**
  Understand what this integration service provides:

  **Actions:**
  1. Review service documentation:
     - Core functionality provided
     - API endpoints exposed
     - Processing pipeline/workflow
     - Input/output formats
     - Data handling capabilities

  2. Document findings:
     ```markdown
     ## Service Functionality
     
     **Purpose:**
     [What this service does]
     
     **Core Capabilities:**
     - [Capability 1]
     - [Capability 2]
     
     **API Surface:**
     - Endpoints: [key endpoints]
     - Methods: [available methods]
     - Data formats: [supported I/O formats]
     
     **Processing:**
     - Workflow: [processing flow]
     - Transformations: [what it does to data]
     ```

  **Verification:**
  - [ ] Service purpose clear
  - [ ] Core capabilities documented
  - [ ] API surface understood
  - [ ] Processing flow mapped

  **STEP 2: Integration Pattern Research (5-8 minutes)**
  Understand how to integrate with this service:

  **Actions:**
  1. Review integration documentation:
     - Recommended integration patterns
     - API specification details
     - Authentication requirements
     - Request/response formats
     - Connection management
     - Error handling

  2. Document findings:
     ```markdown
     ## Integration Patterns
     
     **Recommended Approach:**
     [Pattern description]
     
     **API Details:**
     - Protocol: [HTTP/gRPC/etc.]
     - Authentication: [method and credentials]
     - Base URL: [if applicable]
     - Headers: [required headers]
     
     **Request Format:**
     ```json
     {example request}
     ```
     
     **Response Format:**
     ```json
     {example response}
     ```
     
     **Error Handling:**
     - Error codes: [list common codes]
     - Retry logic: [recommended approach]
     ```

  3. Assess integration complexity:
     - Straightforward or complex integration?
     - Any special considerations?
     - Integration risks?

  **Verification:**
  - [ ] Integration pattern identified
  - [ ] API details documented
  - [ ] Authentication understood
  - [ ] Error handling clear

  **STEP 3: Current Deployment Status Research (3-5 minutes)**
  Determine if service is operational or needs deployment:

  **Actions:**
  1. Check HX-Infrastructure inventory:
     - Is this service currently deployed?
     - What version is running?
     - What's the current configuration?
     - Any known issues?
     - Network accessibility?

  2. Document findings:
     ```markdown
     ## Current Deployment Status
     
     **Status:** [Operational | Planned | Not Deployed]
     
     **If Operational:**
     - Version: [version number]
     - Host: [hostname/IP]
     - Port: [port number]
     - Configuration: [key config settings]
     - Known issues: [any problems]
     
     **If Not Operational:**
     - Deployment needed: [Yes/No]
     - Dependencies: [what's required first]
     - Timeline: [when available]
     
     **Network Access:**
     - Zone: [network zone]
     - Accessibility: [how to reach]
     - Firewall rules: [any needed]
     ```

  **Verification:**
  - [ ] Deployment status confirmed
  - [ ] Version information documented (if operational)
  - [ ] Network access understood
  - [ ] Dependencies identified (if not operational)

  **STEP 4: Configuration Requirements Research (2-4 minutes)**
  Understand configuration needed for integration:

  **Actions:**
  1. Review configuration documentation:
     - Configuration changes needed
     - Environment-specific settings
     - Performance tuning options
     - Security configurations

  2. Document findings:
     ```markdown
     ## Configuration Requirements
     
     **For Integration:**
     - [Config 1]: [value/setting needed]
     - [Config 2]: [value/setting needed]
     
     **Performance Tuning:**
     - [Setting 1]: [recommended value]
     - [Setting 2]: [recommended value]
     
     **Security:**
     - [Security config 1]
     - [Security config 2]
     
     **Changes Required:**
     - [ ] [Change 1 description]
     - [ ] [Change 2 description]
     ```

  **Verification:**
  - [ ] Configuration requirements identified
  - [ ] Performance settings noted
  - [ ] Security configurations understood
  - [ ] Required changes listed

  **STEP 5: Create Integration Research Document (2-3 minutes)**
  Consolidate findings into structured document:

  **Actions:**
  1. Create `/nodes/{node-name}/charter/reviews/knowledge-vault/{integration-repo}-research.md`
  2. Use focused template:
     ```markdown
     # {Integration Service Name} - Integration Research
     
     **Repository:** {repo-name}
     **Integration Type:** [Database | API | Message Queue | etc.]
     **Research Date:** {timestamp}
     **Time Invested:** {actual minutes}
     
     ---
     
     ## Executive Summary
     
     [2-3 sentences on service purpose and integration approach]
     
     ---
     
     ## Service Functionality
     [From Step 1]
     
     ## Integration Patterns
     [From Step 2]
     
     ## Current Deployment Status
     [From Step 3]
     
     ## Configuration Requirements
     [From Step 4]
     
     ---
     
     ## Confidence Assessment
     
     **Overall Confidence:** [High | Medium | Low]
     
     **Justification:**
     [Why this confidence level]
     
     **Integration Risks:**
     - [Risk 1]
     - [Risk 2]
     
     **Questions for Post-Research:**
     - Q1: [Question]
     - Q2: [Question]
     
     ---
     
     ## Recommendations
     
     **Integration Approach:**
     [Recommended integration method]
     
     **Configuration Changes:**
     [Required changes summary]
     
     **Testing Requirements:**
     [What to test during implementation]
     ```

  **Verification:**
  - [ ] Document created in correct location
  - [ ] All sections complete
  - [ ] Confidence level assigned
  - [ ] Recommendations actionable
  - [ ] Ready for charter reference

  **Outputs Generated:**
  - `/nodes/{node-name}/charter/reviews/knowledge-vault/{integration-repo}-research.md` (150-300 lines)

  **Quality Validation:**
  - [ ] Service functionality clear
  - [ ] Integration pattern documented
  - [ ] Deployment status confirmed
  - [ ] Configuration requirements identified
  - [ ] Time limit respected (15-30 minutes)
  - [ ] Questions prepared for CAIO
  </procedure>

  <procedure name="Consolidate Research Findings">
  **Purpose:** Synthesize all repository research into consolidated summary and gap analysis for charter development

  **Prerequisites:**
  - All repository research complete (primary + integrations + supporting)
  - Individual research documents created
  - Confidence levels assessed for each repository

  **Inputs Required:**
  - All individual research documents
  - Initial Q&A responses
  - CAIO's requirements and constraints

  **Time Allocation:** 15-20 minutes

  **Execution Steps:**

  **STEP 1: Create Cross-Repository Analysis (8-10 minutes)**
  Synthesize findings across all researched repositories:

  **Actions:**
  1. Review all research documents
  2. Identify common patterns and themes
  3. Map integration flows
  4. Consolidate confidence assessments

  5. Create `/nodes/{node-name}/charter/reviews/knowledge-vault/research-summary.md`:
     ```markdown
     # Knowledge Vault Research Summary
     
     **Node:** {node-name}
     **Research Date:** {timestamp}
     **Repositories Researched:** {count}
     **Total Research Time:** {total minutes}
     
     ---
     
     ## Executive Summary
     
     [3-5 sentences summarizing overall research findings, key discoveries, and overall confidence level]
     
     ---
     
     ## Repositories Researched
     
     ### Primary Technology: {repo-name}
     - **Purpose:** [what it provides]
     - **Confidence:** [High/Medium/Low]
     - **Key Finding:** [most important discovery]
     - **Documentation:** [link to research doc]
     
     ### Integration: {repo-name-1}
     - **Purpose:** [integration role]
     - **Confidence:** [High/Medium/Low]
     - **Status:** [Operational/Planned]
     - **Documentation:** [link to research doc]
     
     [Repeat for each repository]
     
     ---
     
     ## Cross-Repository Analysis
     
     ### Integration Flow
     ```
     [Diagram or description of how components integrate]
     Primary -> Integration-1 -> Integration-2
     ```
     
     ### Technical Dependencies
     - [Dependency 1]: [description]
     - [Dependency 2]: [description]
     
     ### Deployment Sequence
     1. [Component 1]: [deployment order rationale]
     2. [Component 2]: [deployment order rationale]
     
     ### Configuration Coordination
     - [Config aspect 1]: [how it affects multiple components]
     - [Config aspect 2]: [how it affects multiple components]
     
     ---
     
     ## Consolidated Confidence Assessment
     
     **Overall Project Confidence:** [High | Medium | Low]
     
     **High Confidence Areas (Ready to Proceed):**
     - [Area 1]: [why confident]
     - [Area 2]: [why confident]
     
     **Medium Confidence Areas (May Need POC):**
     - [Area 1]: [what's uncertain]
     - [Area 2]: [what's uncertain]
     
     **Low Confidence Areas (Definitely Need POC/Testing):**
     - [Area 1]: [what's unknown]
     - [Area 2]: [what's unknown]
     
     **Documentation Quality Distribution:**
     - High quality: {count} repos
     - Medium quality: {count} repos
     - Low quality: {count} repos
     
     ---
     
     ## Key Technical Findings
     
     ### Architecture
     [Overall architecture from research]
     
     ### Integration Patterns
     [Patterns discovered across repos]
     
     ### Deployment Requirements
     [Consolidated deployment needs]
     
     ### Performance Characteristics
     [Performance expectations from research]
     
     ### Security Considerations
     [Security findings across components]
     
     ---
     
     ## Recommendations for Charter
     
     **Technical Approach:**
     [Recommended approach based on research]
     
     **Integration Strategy:**
     [How components should integrate]
     
     **Deployment Approach:**
     [Recommended deployment sequence]
     
     **Resource Requirements:**
     [Infrastructure needs from research]
     
     **Timeline Considerations:**
     [Factors affecting schedule]
     ```

  **Verification:**
  - [ ] All repositories summarized
  - [ ] Integration flows documented
  - [ ] Cross-repository patterns identified
  - [ ] Overall confidence assessed
  - [ ] Recommendations clear

  **STEP 2: Document Research Gaps (5-7 minutes)**
  Consolidate all research gaps and unknowns:

  **Actions:**
  1. Review all individual research documents for identified gaps
  2. Consolidate and categorize unknowns
  3. Prioritize gaps by impact

  4. Create `/nodes/{node-name}/charter/reviews/knowledge-vault/research-gaps.md`:
     ```markdown
     # Research Gaps & Unknowns
     
     **Node:** {node-name}
     **Date:** {timestamp}
     **Total Gaps Identified:** {count}
     
     ---
     
     ## Critical Gaps (P0)
     
     ### Gap 1: {Description}
     - **Source:** {which repository}
     - **Impact:** [how this affects project]
     - **Resolution:** [how to resolve - POC/testing/CAIO decision]
     - **Question for CAIO:** [specific question to ask]
     
     [Repeat for each P0 gap]
     
     ---
     
     ## Important Gaps (P1)
     
     [Same structure as P0, but medium priority gaps]
     
     ---
     
     ## Minor Gaps (P2)
     
     [Same structure, but lower priority gaps]
     
     ---
     
     ## Questions for Post-Research Phase
     
     ### Technical Decisions Needed
     - Q1: [Question about competing approaches]
     - Q2: [Question about configuration choices]
     
     ### Integration Clarifications
     - Q3: [Question about integration approach]
     - Q4: [Question about authentication method]
     
     ### Deployment Decisions
     - Q5: [Question about deployment sequence]
     - Q6: [Question about resource allocation]
     
     ### Risk Validations
     - Q7: [Question about assumption validation]
     - Q8: [Question about POC need]
     
     ---
     
     ## Recommended Actions
     
     **Before Charter Finalization:**
     - [ ] [Action 1]
     - [ ] [Action 2]
     
     **POC/Testing Recommended:**
     - [ ] [POC 1]: [what to test]
     - [ ] [POC 2]: [what to test]
     
     **Expert Consultation Needed:**
     - [ ] [Area 1]: [who to consult]
     - [ ] [Area 2]: [who to consult]
     ```

  **Verification:**
  - [ ] All gaps documented
  - [ ] Gaps categorized by priority
  - [ ] Resolution methods identified
  - [ ] Questions prepared for CAIO
  - [ ] Actions recommended

  **STEP 3: Quality Check All Research Documents (2-3 minutes)**
  Verify research documentation completeness:

  **Actions:**
  1. Review checklist:
     - [ ] All identified repositories researched
     - [ ] Each repository has research document
     - [ ] Confidence levels assigned with justification
     - [ ] Integration flows mapped
     - [ ] Research summary created
     - [ ] Research gaps documented
     - [ ] Questions prepared for post-research phase
     - [ ] Time limits respected for each repository

  2. Address any gaps before proceeding to post-research questions

  **Verification:**
  - [ ] All research documents present
  - [ ] Quality standards met
  - [ ] Ready for post-research question generation

  **Outputs Generated:**
  - `/nodes/{node-name}/charter/reviews/knowledge-vault/research-summary.md` (400-600 lines)
  - `/nodes/{node-name}/charter/reviews/knowledge-vault/research-gaps.md` (200-400 lines)

  **Quality Validation:**
  - [ ] Cross-repository synthesis complete
  - [ ] Integration flows clearly documented
  - [ ] Confidence assessment justified
  - [ ] Gaps explicitly identified with priority
  - [ ] Questions ready for CAIO
  - [ ] Recommendations actionable for charter
  </procedure>
</research_procedures>

<integration_convention>
**How Commands Invoke This Phase Command:**

This section documents how workflow commands (Set 1) invoke the knowledge vault research phase command. Invocation occurs during charter workflow Phase 4 for systematic repository research.

**From Charter Workflow (cc-charter-workflow.md):**
This phase command is called during Phase 4:

**Call: Phase 4 - Knowledge Vault Research**
```bash
# After initial questions answered, before post-research questions
cd /home/agent0/HX-Infrastructure
cat .claude/commands/phases/cc-phase-knowledge-research.md

# Execute: Systematic Repository Research
# Inputs: repository-list.md, questions-initial-responses.md
# Outputs: Individual research docs, research-summary.md, research-gaps.md
```

**Input Requirements:**

**Repository Identification:**
- `/nodes/{node-name}/charter/repository-list.md` - CAIO-confirmed list of repos to research
- `/home/agent0/HX-Infrastructure/hx-agents/hx-knowledge-vault-catalog.md` - Catalog for repo locations

**Requirements Context:**
- `/nodes/{node-name}/charter/questions-initial-responses.md` - Initial Q&A for context
- `/nodes/{node-name}/charter/parsed-requirements.md` - Structured requirements
- `/home/agent0/HX-Infrastructure/constitution.md` - Infrastructure principles
- `/home/agent0/HX-Infrastructure/inventory/current-state.md` - Existing infrastructure

**Output Specifications:**

**Individual Repository Research:**
```markdown
Format: Markdown with semantic structure
Location: /nodes/{node-name}/charter/reviews/knowledge-vault/{repo-name}-research.md
Structure:
  - Repository metadata (name, location, documentation quality)
  - Executive summary (2-3 sentences)
  - Technical findings (7 categories for primary, 4 for integration)
  - Confidence assessment with justification
  - Research gaps identified
  - Questions for post-research phase
  - Recommendations
Size: 
  - Primary repo: 300-500 lines
  - Integration repo: 150-300 lines
  - Supporting repo: 100-200 lines
```

**Consolidated Research Summary:**
```markdown
Format: Markdown with semantic structure
Location: /nodes/{node-name}/charter/reviews/knowledge-vault/research-summary.md
Structure:
  - Executive summary across all repos
  - Repository summaries
  - Cross-repository analysis (integration flows, dependencies, deployment sequence)
  - Consolidated confidence assessment
  - Key technical findings
  - Recommendations for charter
Size: 400-600 lines
```

**Research Gaps Document:**
```markdown
Format: Markdown with semantic structure
Location: /nodes/{node-name}/charter/reviews/knowledge-vault/research-gaps.md
Structure:
  - Critical gaps (P0) with impact and resolution
  - Important gaps (P1)
  - Minor gaps (P2)
  - Questions categorized by type (technical, integration, deployment, risk)
  - Recommended actions
Size: 200-400 lines
```

**File Organization:**
```
/nodes/{node-name}/charter/
├── caio-input.md
├── parsed-requirements.md
├── repository-list.md
├── questions-initial-responses.md
└── reviews/
    └── knowledge-vault/
        ├── {primary-repo}-research.md
        ├── {integration-1-repo}-research.md
        ├── {integration-2-repo}-research.md
        ├── {supporting-repo}-research.md
        ├── research-summary.md              # ← Consolidated findings
        └── research-gaps.md                 # ← Known unknowns
```

**State Management:**
- Research documents are stateful artifacts (persist throughout project)
- Research findings inform post-research questions and charter
- Research gap analysis drives post-research question generation
- This command file is stateless (reusable research methodology)

**Error Handling:**

**If repository not found:**
- Document repository as inaccessible
- Flag in research gaps as critical issue
- Recommend alternative repositories or approaches
- Do not block research of other repositories

**If documentation is severely lacking:**
- Assign Low confidence level
- Document specific gaps extensively
- Flag for POC or expert consultation
- Recommend additional research sources

**If time allocation exceeded:**
- Stop research at time limit
- Document what was covered
- Flag remaining areas in research gaps
- Prioritize time-boxed research over perfect understanding

**Integration with Other Commands:**

**Used by:** cc-charter-workflow.md (Phase 4)
**Uses:** None (standalone research execution)
**Outputs used by:**
- cc-phase-charter-questions.md (Phase 6 - generates post-research questions)
- Charter generation (Phase 8 - technical details inform charter)
- Specification phase (detailed technical understanding)

**Workflow Context:**
```
Charter Workflow Phase Sequence:
Phase 0: CAIO Input
Phase 1: Parse Requirements
Phase 2: Generate Initial Questions
Phase 3: CAIO Answers Initial Questions
Phase 4: Knowledge Vault Research ← This command
Phase 5: Research Analysis (part of this command)
Phase 6: Generate Post-Research Questions (uses research findings)
Phase 7: CAIO Answers Post-Research Questions
Phase 8: Generate Charter (uses research findings)
Phase 9: Charter Review and Approval
```

**Time Management:**
```
Total Research Time Budget: 1.5 - 3 hours typical
- Primary repository: 30-45 min
- Integration repos (2-4 repos): 15-30 min each
- Supporting repos (1-3 repos): 10-15 min each
- Consolidation: 15-20 min
- Buffer for unexpected findings: 15-30 min

Always respect time limits - time-boxed research with explicit gaps 
is better than attempting perfect understanding.
```
</integration_convention>

<usage_examples>
  <example name="Primary Repository Research - MCP Server SDK">
  **Scenario:** Researching MCP Python SDK for building custom MCP server

  **Research Execution:**

  **Step 1-2: Architecture (12 minutes)**
  Findings documented:
  ```markdown
  ## Architecture & Design
  
  **Overall Architecture:**
  - Type: Library/SDK for building MCP servers
  - Components: Protocol layer, Server framework, Tool definitions
  - Communication: JSON-RPC over stdio
  
  **Component Structure:**
  - Protocol handler: Manages MCP protocol compliance
  - Server class: Base class for MCP server implementations
  - Tool decorators: Register Python functions as MCP tools
  - Schema validator: Ensures tool schemas are valid
  
  **Design Patterns:**
  - Decorator pattern: Tools registered via @mcp.tool decorator
  - Factory pattern: Server instantiation with configuration
  - Async/await: Supports async tool execution
  ```

  **Step 3: Capabilities (10 minutes)**
  Findings documented:
  ```markdown
  ## Capabilities & Features
  
  **Core Functionality:**
  - Tool definition and registration
  - Automatic schema generation from Python type hints
  - Request/response handling
  - Error handling and validation
  
  **API/Interface:**
  - @mcp.tool decorator for tool registration
  - Server.run() for server startup
  - Built-in health check endpoint
  
  **Limitations:**
  - Python 3.9+ required
  - stdio transport only (no HTTP/WebSocket)
  - Single-threaded execution model
  ```

  **Step 4-6: Installation, Integration, Operations (18 minutes)**
  Comprehensive deployment and operational findings documented

  **Step 7: Confidence Assessment**
  ```markdown
  ## Confidence Assessment
  
  **Overall Confidence:** High
  
  **Justification:**
  - Documentation quality: 9/10 (comprehensive, clear examples)
  - Example availability: 10/10 (multiple working examples)
  - Clarity of patterns: 9/10 (decorator pattern very clear)
  - Gap assessment: 2 minor unknowns only
  
  **High Confidence Areas:**
  - Tool definition: Excellent documentation and examples
  - Server setup: Clear step-by-step guide
  - Error handling: Well-documented patterns
  
  **Medium Confidence Areas:**
  - Performance at scale: Limited performance testing documentation
  - State management: Unclear if tools can maintain state
  
  **Research Gaps:**
  - Q1: Can MCP tools maintain state between calls?
  - Q2: What's the maximum reasonable number of tools per server?
  ```

  **Result:** 470-line research document, High confidence, 2 questions for CAIO
  </example>

  <example name="Integration Repository Research - PostgreSQL">
  **Scenario:** Researching PostgreSQL integration for data persistence

  **Research Execution:**

  **Step 1: Service Functionality (7 minutes)**
  ```markdown
  ## Service Functionality
  
  **Purpose:**
  PostgreSQL provides relational database for structured data storage
  
  **Core Capabilities:**
  - SQL queries (SELECT, INSERT, UPDATE, DELETE)
  - ACID transactions
  - JSON/JSONB support for semi-structured data
  - Full-text search
  - Stored procedures and triggers
  
  **API Surface:**
  - SQL protocol over TCP
  - Multiple client libraries (psycopg2, asyncpg)
  - Connection pooling supported
  ```

  **Step 2: Integration Pattern (8 minutes)**
  ```markdown
  ## Integration Patterns
  
  **Recommended Approach:**
  Use asyncpg library for async Python integration
  
  **API Details:**
  - Protocol: PostgreSQL wire protocol (TCP)
  - Authentication: Password (SCRAM-SHA-256)
  - Connection string format: postgresql://user:pass@host:port/db
  
  **Request Format:**
  SQL queries via prepared statements
  
  **Response Format:**
  Row objects with typed columns
  
  **Error Handling:**
  - Connection errors: Retry with exponential backoff
  - Query errors: Check error code and type
  - Transaction errors: Rollback and retry logic
  ```

  **Step 3: Current Deployment Status (4 minutes)**
  ```markdown
  ## Current Deployment Status
  
  **Status:** Operational
  
  **Details:**
  - Version: PostgreSQL 16.1
  - Host: hx-postgresql-server.internal
  - Port: 5432
  - Configuration: Standard configuration with 4GB shared buffers
  - Known issues: None
  
  **Network Access:**
  - Zone: Data Plane
  - Accessibility: Internal network only
  - Firewall rules: Port 5432 open to Application zone
  ```

  **Step 4: Configuration Requirements (3 minutes)**
  ```markdown
  ## Configuration Requirements
  
  **For Integration:**
  - Database: Create new database for this service
  - User: Create service account with appropriate permissions
  - Connection pool: Configure pool size (10-20 connections typical)
  
  **Security:**
  - Use service account (not admin)
  - Store credentials in Ansible Vault
  - Enable SSL/TLS for connections
  
  **Changes Required:**
  - [ ] Create database: mcp_tools_db
  - [ ] Create user: mcp_tools_user
  - [ ] Grant permissions: CONNECT, SELECT, INSERT, UPDATE, DELETE
  ```

  **Result:** 220-line research document, High confidence, integration straightforward
  </example>

  <example name="Consolidated Research with Gap Analysis">
  **Scenario:** After researching 4 repositories, consolidating findings

  **Research Summary Created:**
  ```markdown
  # Knowledge Vault Research Summary
  
  ## Executive Summary
  
  Researched 4 repositories for MCP Tools Server deployment: MCP SDK (primary), 
  PostgreSQL (integration), Redis (integration), MCP Protocol Spec (supporting). 
  Overall confidence: High for deployment, Medium for scaling approach. Primary 
  technology well-documented, integrations straightforward, one scaling question 
  remains for post-research clarification.
  
  ## Cross-Repository Analysis
  
  ### Integration Flow
  ```
  MCP Tools Server (Python SDK)
      ↓ (async queries)
  PostgreSQL (persistent storage)
      ↓ (caching layer)
  Redis (query result cache)
  ```
  
  ### Deployment Sequence
  1. PostgreSQL: Already operational, just need database creation
  2. Redis: Already operational, just need key namespace
  3. MCP Tools Server: Deploy last, depends on both backends
  
  ## Consolidated Confidence Assessment
  
  **Overall Project Confidence:** High
  
  **High Confidence Areas:**
  - Tool definition and registration: Excellent SDK documentation
  - PostgreSQL integration: Standard patterns, service operational
  - Redis caching: Well-understood pattern
  
  **Medium Confidence Areas:**
  - Scaling beyond 50 tools: No examples found at this scale
  - State management in tools: Documentation unclear on best practices
  
  **Documentation Quality Distribution:**
  - High quality: 3 repos (MCP SDK, PostgreSQL client, Redis client)
  - Medium quality: 1 repo (MCP Protocol Spec - very technical)
  ```

  **Research Gaps Created:**
  ```markdown
  # Research Gaps & Unknowns
  
  ## Critical Gaps (P0)
  
  ### Gap 1: State Management in MCP Tools
  - **Source:** MCP SDK documentation
  - **Impact:** Affects tool design - stateless vs stateful
  - **Resolution:** CAIO decision needed
  - **Question for CAIO:** Should MCP tools maintain state between calls, 
    or should each call be stateless? If stateful, use Redis for state storage?
  
  ## Important Gaps (P1)
  
  ### Gap 2: Scaling Approach
  - **Source:** No scaling documentation in MCP SDK
  - **Impact:** May affect architecture if high tool count expected
  - **Resolution:** POC recommended if >50 tools planned
  - **Question for CAIO:** How many tools are planned (initial + future)? 
    If >50, should we plan for horizontal scaling or is vertical sufficient?
  
  ## Questions for Post-Research Phase
  
  ### Technical Decisions Needed
  - Q1: Stateless vs stateful tools - which design pattern?
  - Q2: Caching strategy - cache all query results or selective caching?
  
  ### Deployment Decisions
  - Q3: Deploy on existing MCP server host or dedicated VM?
  - Q4: What's the acceptable response time for tool executions?
  ```

  **Result:** Research complete with clear gaps, ready for post-research questions
  </example>
</usage_examples>

<critical_reminders>
⚠️ **Time-Boxed Research:** Respect time limits strictly. Research with documented gaps is better than delayed research seeking perfection. Time limits: Primary (30-45min), Integration (15-30min), Supporting (10-15min).

⚠️ **Confidence Honesty:** Don't overstate confidence. Low confidence with explicit gaps is more valuable than false high confidence. Document what you don't know as clearly as what you do know.

⚠️ **Gap Documentation:** Every research gap must be explicitly documented with impact assessment and resolution method. Hidden unknowns cause downstream failures.

⚠️ **Integration Focus:** Research integration patterns as thoroughly as core functionality. Integration complexity often exceeds technology complexity itself.

⚠️ **Current State Awareness:** Always check HX-Infrastructure inventory for current deployment status. Assuming something needs deployment when it's already operational wastes time.

⚠️ **Question Preparation:** Research should generate specific, answerable questions for post-research phase. Vague questions like "how should we approach this?" are not helpful.

⚠️ **Cross-Repository Synthesis:** Don't research repositories in isolation. Map integration flows, identify dependencies, understand deployment sequences across all repositories.

⚠️ **Evidence-Based Confidence:** Confidence levels must be justified with concrete evidence (documentation quality scores, example availability, clarity of patterns). "It seems fine" is not justification.

⚠️ **Architecture Understanding:** Always understand and document architecture before diving into details. Without architectural context, feature details lack meaning.

⚠️ **Repository Categories:** Apply appropriate research depth for repository category. Don't spend 45 minutes on supporting repository or 10 minutes on primary repository.

⚠️ **Operational Constraints:** Security, licensing, and operational aspects are not optional "nice to have" research. They're mandatory for deployment decisions.

⚠️ **Consolidation Discipline:** Consolidation is not copy-paste of individual findings. It's synthesis, pattern identification, and cross-repository insight generation.
</critical_reminders>

<validation_checklists>
  <checklist name="Primary Repository Research Validation">
  **Before proceeding to next repository:**

  **Coverage Validation:**
  - [ ] Architecture and design documented
  - [ ] Capabilities and features documented
  - [ ] Installation and deployment requirements clear
  - [ ] Integration specifications documented
  - [ ] Operational aspects understood
  - [ ] Constraints and limitations identified
  - [ ] Confidence level assigned with justification

  **Quality Validation:**
  - [ ] Executive summary clear (2-3 sentences)
  - [ ] Technical findings organized by category
  - [ ] Examples referenced where available
  - [ ] Documentation quality scored (0-10)
  - [ ] Research gaps explicitly identified
  - [ ] Questions prepared for post-research phase

  **Time Management:**
  - [ ] Research completed in 30-45 minutes
  - [ ] Time limit respected even if incomplete
  - [ ] Gaps documented for incomplete areas

  **Requirements Alignment:**
  - [ ] Research addresses initial requirements
  - [ ] CAIO's stated preferences considered
  - [ ] Integration points from requirements covered
  - [ ] Recommendations directly address needs
  </checklist>

  <checklist name="Integration Repository Research Validation">
  **Before proceeding to next repository:**

  **Coverage Validation:**
  - [ ] Service functionality understood
  - [ ] Integration patterns documented
  - [ ] Current deployment status confirmed
  - [ ] Configuration requirements identified
  - [ ] Confidence level assigned

  **Integration Specifics:**
  - [ ] API details documented (protocol, authentication, formats)
  - [ ] Error handling patterns identified
  - [ ] Performance characteristics noted
  - [ ] Network access requirements clear

  **Current State Verification:**
  - [ ] Checked HX-Infrastructure inventory
  - [ ] Deployment status confirmed (operational/planned/not deployed)
  - [ ] Version information documented (if operational)
  - [ ] Known issues noted

  **Time Management:**
  - [ ] Research completed in 15-30 minutes
  - [ ] Focused on integration aspects
  - [ ] Not excessive detail on service internals
  </checklist>

  <checklist name="Research Consolidation Validation">
  **Before proceeding to post-research questions:**

  **Completeness Validation:**
  - [ ] All identified repositories researched
  - [ ] Each repository has research document
  - [ ] Research summary created
  - [ ] Research gaps document created
  - [ ] Total research time within budget (1.5-3 hours)

  **Synthesis Quality:**
  - [ ] Cross-repository patterns identified
  - [ ] Integration flows mapped and documented
  - [ ] Deployment sequence determined
  - [ ] Configuration coordination understood
  - [ ] Overall confidence level justified

  **Gap Analysis Quality:**
  - [ ] All gaps categorized by priority (P0/P1/P2)
  - [ ] Impact assessment for each gap
  - [ ] Resolution methods proposed
  - [ ] Questions prepared by category
  - [ ] Recommended actions clear

  **Charter Readiness:**
  - [ ] Sufficient technical understanding for charter
  - [ ] Integration approach clear
  - [ ] Deployment approach defined
  - [ ] Resource requirements estimated
  - [ ] Risks and constraints identified
  - [ ] Ready to generate post-research questions
  </checklist>

  <checklist name="Documentation Quality Validation">
  **For each research document created:**

  **Structure Validation:**
  - [ ] Repository metadata complete
  - [ ] Executive summary present (2-3 sentences)
  - [ ] Technical findings organized by category
  - [ ] Confidence assessment with justification
  - [ ] Research gaps explicitly stated
  - [ ] Recommendations provided

  **Content Quality:**
  - [ ] Findings are specific and concrete
  - [ ] Examples referenced where available
  - [ ] Integration patterns clearly described
  - [ ] Gaps honestly documented
  - [ ] Recommendations actionable
  - [ ] Ready for charter team reference

  **Formatting Standards:**
  - [ ] Markdown formatting correct
  - [ ] Code blocks properly formatted
  - [ ] Headers hierarchically organized
  - [ ] Links functional (if any)
  - [ ] Professional appearance
  - [ ] Easy to scan and reference
  </checklist>
</validation_checklists>

<related_documents>
**Workflows:**
- [Charter Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md) - Calls this command in Phase 4
- [Specification Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md) - Uses research findings for technical details

**Phase Commands:**
- [Charter Questions](/home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-charter-questions.md) - Uses research findings to generate post-research questions

**Templates:**
- [Knowledge Vault Research Template](/home/agent0/HX-Infrastructure/templates/knowledge-vault-research-template.md) - Original template (pre-command)
- [Charter Template](/home/agent0/HX-Infrastructure/templates/charter-template.md) - Research informs charter sections

**Reference:**
- [HX Knowledge Vault Catalog](/home/agent0/HX-Infrastructure/hx-agents/hx-knowledge-vault-catalog.md) - Repository locations and purposes
- [Constitution](/home/agent0/HX-Infrastructure/constitution.md) - Infrastructure principles
- [Architecture Standards](/home/agent0/HX-Infrastructure/standards/architecture-standards.md) - Integration patterns context

**Standards:**
- [Documentation Requirements](/home/agent0/HX-Infrastructure/standards/documentation-requirements.md) - Research document formatting
- [Naming Conventions](/home/agent0/HX-Infrastructure/standards/naming-conventions.md) - File naming for research docs

**Utilities:**
- [Documentation Linting](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-doc-lint.md) - Validate research document quality
- [Artifact Tracking](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md) - Track research documents as artifacts
</related_documents>

---

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready
**Compliance:** Gold Standard v1.1 - All 11 required elements present
**Integration:** Ready for charter workflow Phase 4 execution
**State:** Stateless command generating stateful research artifacts
**Last Review:** 2025-11-20
**Update:** Standardized integration convention header for consistency with utilities and other phase commands
**Infrastructure Philosophy:** Appropriately infrastructure-agnostic - research methodology applies regardless of deployment model
</metadata_footer>
