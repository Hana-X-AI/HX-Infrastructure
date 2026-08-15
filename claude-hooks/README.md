# HX-Infrastructure Claude Code Hooks

This package installs the seven approved project hook commands without replacing the rest of `.claude/settings.json`.

## Hooks

1. `SessionStart` — injects current Phase 1 / Phase 2 and registry counts.
2. `PreToolUse` — hard-locks obvious role-specific or persistent server configuration during Phase 3 (Regroup); no registry status releases it.
3. `PostToolUse` — validates `discovery.md` and `SERVER-REGISTRY.md` after Claude writes/edits them.
4. `SubagentStop` — requires the `server-discovery` subagent to leave a valid completed discovery record before it exits.
5. `Notification` — displays a Windows alert when Claude Code is idle or a background agent needs input.

## Apply

Extract this ZIP somewhere convenient.

From PowerShell, run:

```powershell
cd C:\Users\JarvisRichardson\Desktop\HX-Infrastructure
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<extracted-package-path>\apply-hooks.ps1"
```

Or pass the project explicitly:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\apply-hooks.ps1" -ProjectRoot "C:\Users\JarvisRichardson\Desktop\HX-Infrastructure"
```

The installer:

- creates `.claude\hooks`;
- copies the hook scripts;
- creates or merges `.claude\settings.json`;
- preserves unrelated existing settings and hooks;
- removes/replaces prior HX hook entries if the installer is run again;
- creates `.claude\settings.json.bak` before modifying an existing settings file.

## Verify

Start or resume Claude Code in the project and run:

```text
/hooks
```

You should see project hooks for:

```text
SessionStart
PreToolUse
PostToolUse
SubagentStop
Notification
```

## Phase Gate — Phase 3 hard-lock

During Phase 3 (Regroup) the `PreToolUse` guard denies server mutation for **every** registry state. No `Phase 2 Status` value — `READY`, `IN PROGRESS`, `COMPLETE`, `BLOCKED`, missing, or unrecognized — releases it. The registry `Phase 2 Status` column is retained for the session dashboard, but it no longer gates the guard.

The guard blocks obvious package installation/upgrades, service mutations, Netplan apply/try, firewall mutation, storage formatting/partitioning, NVIDIA driver installation, model downloads, vLLM serving/install commands, Ollama mutations, and creation/editing of per-server `configuration.md`.

The authorization record that replaces this hard lock — allowing scoped, owner-authorized mutation in the later implementation phase — is designed in the Transition Stage (P-F1), not here.

The hook is a defense-in-depth guardrail, not a complete sandbox or the source of truth. Claude permission deny rules provide stronger deterministic enforcement where an applicable rule can be defined. `GOALS-AND-OBJECTIVES.md`, `CLAUDE.md`, and the server registry remain authoritative.

## Permission deny rules

`.claude/settings.json` also carries a `permissions.deny` list covering the irreversible storage operations that `INFRASTRUCTURE-CONTRACT.md` section 10.5 requires explicit approval for in **any** phase: `mkfs`, `wipefs`, `sgdisk`, `pvcreate`, `vgcreate`, `lvcreate`, and `mdadm --create`.

These rules are deliberately phase-independent. Like the Phase 3 hard-locked hook, they are never released by a registry status value, because the contract prohibits those operations without explicit approval in any phase.

Permission rules match on a command prefix, so they cannot cover every invocation form. The `PreToolUse` hook remains the broader, registry-aware layer; the deny list is the deterministic backstop for the highest-impact commands. This installer does not write permission rules — `apply-hooks.ps1` merges only the `hooks` section and leaves the rest of `settings.json` untouched.

## Windows

These hooks use Windows PowerShell through `powershell.exe -NoProfile -ExecutionPolicy Bypass`.

The Notification hook is asynchronous so a notification dialog does not block Claude Code.

It deliberately does not fire on `permission_prompt`. The dialog is modal and must be dismissed by hand, and a discovery run issues many commands, so alerting on every permission prompt would stack dialogs faster than they can be cleared.
