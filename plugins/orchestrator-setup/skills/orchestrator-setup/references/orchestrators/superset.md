# Superset

- **Website**: https://superset.sh/
- **GitHub**: https://github.com/superset-sh/superset

Superset is an agent orchestrator that manages git worktrees. It provides workspace metadata via environment variables but does not assign ports — the project must allocate its own port block.

## Environment variables

| Variable | Context | Purpose |
|----------|---------|---------|
| `SUPERSET_WORKSPACE_PATH` | All processes | **Detection var.** Path to the workspace root. |
| `SUPERSET_WORKSPACE_NAME` | All processes | Workspace name assigned by Superset. |
| `SUPERSET_HOME_DIR` | All processes | Superset's home directory for shared state. Defaults to `~/.superset`. Used as the base path for port allocation storage. |

## Config file

**`.superset/config.json`** in the repo root.

```json
{
  "setup": ["<setup command>"],
  "teardown": ["<teardown command>"],
  "run": ["<dev server command>"]
}
```

Each field is an array of shell commands (run sequentially).

## Port strategy

**Project allocates a 10-port block.**

- Superset does not provide a port. The project must allocate a contiguous block of ports (typically 10) and manage allocation/release.
- Port allocations are stored in `$SUPERSET_HOME_DIR/port-allocations/<project>/` (one file per workspace, keyed by a checksum of the workspace path).
- A labels file at `.superset/ports.json` maps port offsets to service names for Superset's UI.

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

- `setup` runs when a workspace is created (worktree creation).
- `teardown` runs when a workspace is removed.
- `run` starts the dev server.

## Custom dev command

The dev server is exposed directly through the `run` array in `.superset/config.json`. No separate custom-command mechanism is needed — Superset runs `run` as the dev server.

## Workspace name resolution

`$SUPERSET_WORKSPACE_NAME` is provided on all processes.

## Notes

- Port allocation requires file-based locking to handle concurrent workspace creation.
- Allocations should be stored under `$SUPERSET_HOME_DIR` (defaulting to `~/.superset/`) so they survive across shell sessions and are shared across all projects.
- The `.superset/ports.json` labels file is gitignored — it is generated per-workspace, not committed.
