# Install HX Phase 1 Claude Skills and Hooks

Copy the `.claude` directory from this package into:

```text
C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\
```

The result should be:

```text
HX-Infrastructure/
└── .claude/
    ├── settings.json
    ├── hooks/
    │   ├── hx-common.ps1
    │   ├── hx-phase1-guard.ps1
    │   ├── hx-validate-discovery.ps1
    │   ├── hx-validate-subagent.ps1
    │   ├── hx-session-state.ps1
    │   └── hx-notify.ps1
    ├── skills/
    │   ├── discover-server/
    │   │   ├── SKILL.md
    │   │   └── scripts/
    │   │       └── collect-server-facts.sh
    │   ├── audit-discovery/
    │   │   └── SKILL.md
    │   ├── sync-registry/
    │   │   └── SKILL.md
    │   └── phase1-gate/
    │       └── SKILL.md
    └── agents/
        └── server-discovery.md
```

For hook installation details, see:

```text
claude-hooks/README.md
```

Restart Claude Code after copying because the package adds a project subagent and hooks.

Verify hooks are active:

```text
/hooks
```

Suggested commands:

```text
/discover-server
/audit-discovery
/sync-registry
/phase1-gate
```

Role assignment remains manual. These skills do not assign roles, select workloads/models, or perform Phase 2 configuration.
