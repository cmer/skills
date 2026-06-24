# Conductor

- **Website**: https://www.conductor.build/
- **Documentation**: https://www.conductor.build/docs/

Conductor is an agent orchestrator that manages git worktrees. It reads shared repository settings from `.conductor/settings.toml`; agents configuring a project must create or update that file instead of asking the user to set lifecycle commands in the Conductor UI.

## Environment variables

| Variable | Context | Purpose |
|----------|---------|---------|
| `CONDUCTOR_WORKSPACE_PATH` | Terminals and scripts | **Detection var.** Path to the workspace root. |
| `CONDUCTOR_WORKSPACE_NAME` | Terminals and scripts | Workspace name. |
| `CONDUCTOR_ROOT_PATH` | Terminals and scripts | Path to the repository root directory. |
| `CONDUCTOR_DEFAULT_BRANCH` | Terminals and scripts | Default branch name, usually `main`. |
| `CONDUCTOR_PORT` | Terminals and scripts | First port in a range of 10 ports assigned to the workspace. |
| `CONDUCTOR_IS_LOCAL` | Terminals and scripts | `1` in local workspaces, `0` in cloud workspaces. |

## Config file

**`.conductor/settings.toml`** in the repo root.

```toml
"$schema" = "https://conductor.build/schemas/settings.repo.schema.json"

[scripts]
setup = "<setup command>"
run = "<dev server command>"
archive = "<teardown command>"
run_mode = "concurrent"
```

Use `archive`, not `teardown`, for cleanup. `run_mode` is usually `concurrent` for workspace-isolated projects; use `nonconcurrent` only when the project still depends on one shared fixed resource.

Preserve project command wrappers when detected. For example, if the project uses `mise`, a valid config is:

```toml
"$schema" = "https://conductor.build/schemas/settings.repo.schema.json"

[scripts]
setup = "mise trust && mise exec -- bin/orchestrator/setup"
run = "mise exec -- bin/dev"
archive = "mise exec -- bin/orchestrator/teardown"
run_mode = "concurrent"
```

Conductor also supports `.conductor/settings.local.toml` for machine-local overrides. Prefer the committed `.conductor/settings.toml` for this skill because the goal is to configure the project for teammates and future agents.

## Port strategy

**Tool provides a 10-port range.**

- `$CONDUCTOR_PORT` is the first port in the workspace's assigned range.
- Additional services can use offsets from that value (for example Rails on `$CONDUCTOR_PORT`, Vite on `$CONDUCTOR_PORT + 1`).
- No project-managed port allocation is needed.

## Lifecycle

- `scripts.setup` runs after Conductor creates a workspace.
- `scripts.run` runs from Conductor's Run button.
- `scripts.archive` runs before Conductor archives a workspace.
- Scripts run from the workspace directory.

## Custom dev command

The dev server is exposed through `scripts.run` in `.conductor/settings.toml`. For this skill's default Rails scaffold, use:

```toml
[scripts]
run = "bin/dev"
```

`bin/dev` should call `bin/orchestrator/dev-port`, which reads `$CONDUCTOR_PORT` and exports service-specific port variables before starting the process manager.

## Workspace name resolution

`$CONDUCTOR_WORKSPACE_NAME` is available to terminals and scripts. Keep the persisted workspace name file in the shared implementation anyway so Rails commands launched outside an orchestrator-provided shell can still find the correct database name.

## Notes

- Do not ask the user to configure setup/run/archive manually in Conductor's UI. Create or update `.conductor/settings.toml` with the resolved lifecycle commands.
- Repository settings can also define shared environment variables under `[environment_variables]`, but do not commit secrets. Use `.conductor/settings.local.toml` only for machine-local secret values or overrides.
- This config file is the same role as `.superset/config.json`, `.superconductor/config.json`, `paseo.json`, and `orca.yaml`: checked-in project lifecycle configuration.
