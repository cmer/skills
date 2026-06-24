# Orca

- **Website**: https://www.onorca.dev/
- **Documentation**: https://www.onorca.dev/docs
- **GitHub**: https://github.com/stablyai/orca

Orca is an agent orchestrator that manages git worktrees. It provides different environment variables depending on context (terminal shells vs. lifecycle hooks).

## Environment variables

| Variable | Context | Purpose |
|----------|---------|---------|
| `ORCA_WORKTREE_ID` | Terminal shells | **Detection var (terminals).** Unique ID for the worktree. Present in Orca-managed terminal sessions. |
| `ORCA_WORKTREE_PATH` | Setup/archive hooks | **Detection var (hooks).** Path to the worktree root. Present during lifecycle hook execution. |
| `ORCA_WORKSPACE_NAME` | Setup/archive hooks | Workspace name. Only available during lifecycle hooks, not in terminal shells. |

## Config file

**`orca.yaml`** at the repo root.

Create or update this project file when Orca is selected. Do not ask the user to configure setup/archive elsewhere.

```yaml
scripts:
  setup: |
    <setup command>
  archive: |
    <teardown command>
```

## Port strategy

**Project allocates a 10-port block.**

- Orca does not provide a port. The project must allocate a contiguous block of ports.
- Port allocations are stored under `$SUPERSET_HOME_DIR/port-allocations/<project>/` (shared with Superset's allocation system).
- Labels file: `.superset/ports.json` (shared format with Superset).

## Lifecycle

- `scripts.setup` runs when a worktree is created.
- `scripts.archive` runs when a worktree is archived/removed.
- Orca does **not** have a built-in `run`/`dev` command in `orca.yaml`. Still write `orca.yaml` for setup/archive. If repo-scoped Quick Commands are available in a project file, update that file too; otherwise document the dev command in project docs rather than presenting setup/archive as a user task.

### Quick Commands (local Orca settings)

Orca supports repo-scoped Quick Commands stored in local Orca settings (not in `orca.yaml`). To add a "Start Dev Server" quick command:

```json
{
  "action": "terminal-command",
  "command": "<dev server command>",
  "appendEnter": true
}
```

This is configured in Orca's local settings as a `terminalQuickCommands` entry scoped to the repo.

## Workspace name resolution

- In setup/archive hooks: `$ORCA_WORKSPACE_NAME` is available.
- In terminal shells: workspace name must be derived from `basename "$PWD"` or a persisted workspace name file.

## Notes

- Preserve existing command wrappers from other project orchestrator configs when present (for example `mise trust && mise exec -- ...`).
- Orca's split detection context (terminals use `ORCA_WORKTREE_ID`, hooks use `ORCA_WORKTREE_PATH`) means detection logic must check for either variable.
- The dev server is not managed by `orca.yaml` — it must be started via a repo-scoped Quick Command if available, project docs, or a terminal command. This is different from other orchestrators that have explicit `run`/`dev` lifecycle hooks.
- `orca.yaml` uses `archive` instead of `teardown` for the cleanup lifecycle hook.
