# Paseo

- **Website**: https://paseo.sh/
- **Documentation**: https://paseo.sh/docs/
- **Worktree docs**: https://paseo.sh/docs/worktrees
- **GitHub**: https://github.com/getpaseo/paseo

Paseo is an agent orchestrator that manages git worktrees and provides port assignments via environment variables on all processes.

## Environment variables

| Variable | Context | Purpose |
|----------|---------|---------|
| `PASEO_WORKTREE_PATH` | All processes | **Detection var.** Path to the worktree root. Always set inside Paseo. |
| `PASEO_WORKTREE_PORT` | All worktree processes | Port assigned to this worktree. Available on all processes (preferred). |
| `PASEO_PORT` | Service processes only | Port for the specific service. Only available on the process Paseo starts for the service. |

## Config file

**`paseo.json`** at the repo root.

```json
{
  "worktree": {
    "setup": "<setup command>",
    "teardown": "<teardown command>"
  },
  "scripts": {
    "dev": {
      "type": "service",
      "command": "<dev server command>"
    }
  }
}
```

## Port strategy

**Tool provides port via env var on all processes.**

- `$PASEO_WORKTREE_PORT` is available on all worktree processes (preferred).
- `$PASEO_PORT` is available on service processes only (fallback).
- No 10-port block allocation needed.

## Lifecycle

- `worktree.setup` runs when a worktree is created.
- `worktree.teardown` runs when a worktree is removed.
- `scripts.dev` defines the dev server command (type `"service"` means it's a long-running process).

## Custom dev command

The dev server is exposed directly through the `scripts.dev` entry in `paseo.json` (type `"service"`). No separate custom-command mechanism is needed — Paseo runs `scripts.dev` as the long-running dev server.

## Workspace name resolution

Paseo does not provide an explicit workspace name variable. Derive the workspace name from `basename "$PWD"`.

## Notes

- Paseo provides ports on all processes, making it the simplest orchestrator for port resolution — no discovery or allocation needed.
- The `scripts.dev.type: "service"` tells Paseo this is a long-running server, not a one-shot script.
