# HX Claude Meta-Agent Enforcement Architecture — Diagram Appendix

**Companion to:** HX Claude Meta-Agent Enforcement Architecture
**Status:** Explanatory appendix; does not replace canonical policy
**Prepared for:** Agent Zero / HX-Infrastructure
**Date:** 2026-08-15

This appendix visualizes the approved and recommended control relationships. When a diagram and canonical policy differ, the canonical policy governs.

## A. Authority and delegation topology

```mermaid
flowchart TD
    A["Agent Zero<br/>Final human authority"] -->|"Intent and decisions"| C["Claude<br/>Meta-Agent"]
    C -->|"Governed charter"| M["Max<br/>Sole OmniRoute dispatcher"]
    M <-->|"Domain advice and review"| S["Council of nine stewards"]
    M -->|"Exact allowlisted types"| T["Tier-3 task cells"]
    T -->|"Evidence envelope"| M
    M -->|"Integrated evidence"| C
    C -->|"Decision-ready report"| A
    T -.->|"No Agent or Task tool"| X["Tier 4 prohibited"]
```

The stewards advise and review within their domains. They do not create nine independent dispatch paths. Max remains the sole dispatcher and integration coordinator for OmniRoute.

## B. End-to-end governed task lifecycle

```mermaid
flowchart TD
    I["Owner request"] --> N["Claude normalizes intent"]
    N --> K["Knowledge review and authority check"]
    K --> D{"Authorized and sufficiently grounded?"}
    D -->|"No"| O["Stop and synchronize with owner"]
    D -->|"Yes"| H["Claude creates governed charter"]
    H --> M["Verified launcher starts Max"]
    M --> P["Max creates atomic task packet"]
    P --> E["Tier-3 cell executes in bounded scope"]
    E --> V["Independent review and proof"]
    V --> R{"Evidence contract satisfied?"}
    R -->|"No"| F["Classify failure and apply retry policy"]
    F --> M
    R -->|"Yes"| G["Max integrates accepted result"]
    G --> S["Claude reconciles evidence"]
    S --> O
```

## C. Mandatory Knowledge Base Review gate

```mermaid
stateDiagram-v2
    [*] --> TaskReceived
    TaskReceived --> SourcesIdentified
    SourcesIdentified --> SourcesReviewed
    SourcesReviewed --> ReceiptCreated
    ReceiptCreated --> ReceiptValidation
    ReceiptValidation --> Blocked: Missing, stale, forged, or mismatched
    ReceiptValidation --> PrivilegedToolsAvailable: Valid for task, run, agent, and hashes
    Blocked --> OwnerOrMax: Authority or source correction
    OwnerOrMax --> SourcesIdentified
    PrivilegedToolsAvailable --> TaskExecution
    TaskExecution --> [*]
```

The receipt is evidence of review, not a substitute for review. It must be bound to the current task, run, agent, operations root, source identities and content hashes.

## D. Tool-call enforcement decision

```mermaid
flowchart TD
    T["Proposed tool call"] --> P{"Tool statically available?"}
    P -->|"No"| DN["Deny: capability absent"]
    P -->|"Yes"| R{"Current receipt valid?"}
    R -->|"No"| DN
    R -->|"Yes"| A{"Caller and task mode authorized?"}
    A -->|"No"| DN
    A -->|"Yes"| S{"Target and command within scope?"}
    S -->|"No"| DN
    S -->|"Yes"| C{"Critical action?"}
    C -->|"Yes"| B{"Static or managed backstop present?"}
    B -->|"No"| DN
    B -->|"Yes"| EX["Execute and record evidence"]
    C -->|"No"| EX
```

An ordinary command, HTTP or MCP-tool hook is not the sole critical boundary because hook startup failure, invalid output and timeout are non-blocking. Static permissions, tool deprivation, managed policy, a verified launcher or an Agent SDK callback must carry the critical prohibition.

## E. Failure classification and escalation

```mermaid
sequenceDiagram
    participant Cell as Tier-3 Cell
    participant Max
    participant Claude
    participant Owner as Agent Zero
    Cell->>Max: Result envelope or failure
    Max->>Max: Classify failure
    alt Transient, format, or narrow syntax
        Max->>Cell: One retry with new run ID
        Cell->>Max: Corrected result or second failure
        alt Retry succeeds
            Max->>Claude: Integrated evidence
        else Retry fails
            Max->>Claude: Stop and escalate
            Claude->>Owner: Failure evidence and decision request
        end
    else Knowledge, permission, security, authority, scope, or evidence
        Max->>Claude: Zero retry; stop and escalate
        Claude->>Owner: Classified blocker and required ruling
    end
```

## F. Control-plane protection hierarchy

```mermaid
flowchart TD
    A["Tier A<br/>Managed settings and hooks"] --> B["Strongest non-overridable boundary"]
    C["Tier B<br/>OS-protected user controls"] --> D["Locally enforced after bypass tests"]
    E["Tier C<br/>Repository controls and hashes"] --> F["Pilot-enforced with residual tamper risk"]
    G["Tier D<br/>CLAUDE.md and prompts only"] --> H["Advisory behavior only"]
    B --> J["Permitted claim: ENFORCED"]
    D --> K["Permitted claim: LOCALLY ENFORCED"]
    F --> L["Permitted claim: PILOT-ENFORCED"]
    H --> M["Permitted claim: DESIGNED or ADVISORY"]
```

## G. Max dispatch boundary

```mermaid
flowchart TD
    C["Claude Meta-Agent"] -->|"May launch only Max path"| M["Max main-agent session"]
    M -->|"Allowed"| R["Reconnaissance cell"]
    M -->|"Allowed"| I["Implementation cell"]
    M -->|"Allowed"| V["Review and proof cells"]
    C -.->|"Denied"| R
    C -.->|"Denied"| I
    R -.->|"No recursion"| X["Any child agent"]
    I -.->|"No recursion"| X
    V -.->|"No recursion"| X
```

The actual approved Tier-3 names must come from the validated repository roster. The diagram uses functional cell categories only to show the authorization boundary.

## H. Staged implementation and acceptance

```mermaid
flowchart TD
    P0["1. Read-only preflight"] --> P1["2. Canonical policy and schemas"]
    P1 --> P2["3. Audit-only controls"]
    P2 --> P3["4. Knowledge receipt gate"]
    P3 --> P4["5. Max and Tier-3 constraints"]
    P4 --> P5["6. Static backstops and dynamic gates"]
    P5 --> P6["7. Adversarial tests"]
    P6 --> Q{"Critical negative tests pass?"}
    Q -->|"No"| P1
    Q -->|"Yes"| P7["8. Read-only pilot"]
    P7 --> P8["9. Bounded worktree pilot"]
    P8 --> P9["10. Owner acceptance gate"]
```

No global activation follows automatically from a successful pilot. Agent Zero retains the acceptance and rollout decision.

## Interpretation rule

These diagrams explain the architecture but do not create authority. Canonical governance, machine-readable delegation policy, protected runtime settings, agent definitions, validated hooks, schemas and owner decisions remain controlling.
