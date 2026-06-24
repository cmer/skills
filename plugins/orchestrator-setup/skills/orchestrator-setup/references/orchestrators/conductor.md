# Conductor

- **Website**: https://www.conductor.build/

Conductor is an agent orchestrator that manages git worktrees externally. It calls project scripts but does not read a repo-level config file.

## Environment variables

| Variable | Context | Purpose |
|----------|---------|---------|
| `CONDUCTOR_BIN_DIR` | All shells | **Detection var.** Always set when running inside Conductor. |
| `CONDUCTOR_WORKSPACE_NAME` | Dev-server process only | Workspace name. NOT available in regular shells — only on the process Conductor starts for the dev server. |
| `CONDUCTOR_PORT` | Dev-server process only | Port for the dev server. Only available on the dev-server process. |

## Config file

None. Conductor calls project lifecycle scripts externally — it does not read a config file from the repo.

## Port strategy

**Tool provides port on dev-server process; discovery fallback elsewhere.**

- On the dev-server process: `$CONDUCTOR_PORT` is set directly.
- In other shells: port must be discovered (e.g., by scanning running processes for a puma/node server matching the workspace name).
- No 10-port block allocation needed.

## Lifecycle

Conductor invokes `bin/orchestrator/setup` and `bin/dev` (or equivalent) externally. The project only needs those scripts to exist and to detect Conductor via `$CONDUCTOR_BIN_DIR`.

## Custom dev command

Conductor is external — it has no repo config file and no project-scoped custom-command mechanism. The dev server is whatever script Conductor is configured to invoke (e.g., `bin/dev`); there is nothing to add for a custom dev command.

## Workspace name resolution

`$CONDUCTOR_WORKSPACE_NAME` is only available on the dev-server process. For other shells, the workspace name must be derived from the persisted workspace name file or `basename "$PWD"`.

## Notes

- Conductor is unique in that the workspace name and port are only available on the dev-server process, not in all shells. This requires special handling for port discovery in non-dev-server contexts.
- Projects that use Conductor typically also support process-title discovery (scanning `ps` output) as a port fallback.
