# Superconductor

- **Website**: https://super.engineering/
- **Documentation**: https://super.engineering/docs/

Superconductor is an agent orchestrator that manages git worktrees. It provides workspace metadata via environment variables but does not assign ports — the project must allocate its own port block.

## Environment variables

| Variable | Context | Purpose |
|----------|---------|---------|
| `SUPERCONDUCTOR_WORKTREE_PATH` | All processes | **Detection var.** Path to the worktree root. |
| `SUPERCONDUCTOR_WORKSPACE_NAME` | All processes | Workspace name assigned by Superconductor. |
| `SUPERCONDUCTOR_ROOT_PATH` | All processes | Path to the Superconductor installation root. |

## Config file

**`.superconductor/config.json`** in the repo root.

Create or update this project file when Superconductor is selected. Do not ask the user to configure these lifecycle commands elsewhere.

```json
{
  "setup": ["<setup command>"],
  "run": ["<dev server command>"],
  "teardown": ["<teardown command>"]
}
```

Each field is an array of shell commands (run sequentially).

## Port strategy

**Project allocates a 10-port block.**

- Superconductor does not provide a port. The project must allocate a contiguous block of ports.
- Port allocations are stored under `$SUPERSET_HOME_DIR/port-allocations/<project>/` (shared with Superset's allocation system — they use the same storage path).
- Labels file: `.superset/ports.json` (shared format with Superset).

### Labels file format (`.superset/ports.json`)

```json
{
  "ports": [
    { "port": 10000, "label": "Rails" },
    { "port": 10001, "label": "Vite" }
  ]
}
```

## Lifecycle

- `setup` runs when a worktree is created.
- `run` starts the dev server.
- `teardown` runs when a worktree is removed.

## Custom dev command

The dev server is exposed directly through the `run` array in `.superconductor/config.json`. No separate custom-command mechanism is needed — Superconductor runs `run` as the dev server.

## Workspace name resolution

`$SUPERCONDUCTOR_WORKSPACE_NAME` is provided on all processes.

## Notes

- Preserve existing command wrappers from other project orchestrator configs when present (for example `mise trust && mise exec -- ...`).
- Superconductor shares the port allocation storage path and labels file format with Superset. A project that supports both does not need separate allocation infrastructure.
- The config file schema is nearly identical to Superset's (`setup`, `run`, `teardown` arrays) but lives in `.superconductor/config.json`.
