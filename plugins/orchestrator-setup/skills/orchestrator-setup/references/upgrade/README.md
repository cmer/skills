# Upgrading a layout 1 project

A **layout 1** project has `bin/orchestrator/` scripts (or legacy `bin/workspace-*` scripts) whose `env` lacks the stamp `Managed by the orchestrator-setup skill`. They were adapted by hand from an older version of this skill, or written from scratch. The goal: move to the managed layout with **no change in behavior** for any orchestrator, proven by the check. Only after that may Phases 1–8 add or remove orchestrators.

Run the upgrade alone. Don't add an orchestrator in the same step: an unrelated diff would hide inside the noise.

## Steps

1. **Record before.** Run `orchestrator-check record PROJECT_DIR --output before.txt` on the untouched project. Add `--stub` for every command setup or teardown calls that the check doesn't stub, until no `setup` row fails on a missing command.

2. **Inventory the old scripts.** Read every file in `bin/orchestrator/` (or `bin/workspace-*`) and sort each piece into one of these:

   | Found in old scripts | Goes to |
   |----------------------|---------|
   | Project name in the allocation path (`port-allocations/<name>`) or the database prefix | `ORCHESTRATOR_PROJECT` |
   | Workspace env var (`<PROJECT>_WORKSPACE_NAME`) | `ORCHESTRATOR_WORKSPACE_ENV` |
   | Setup/teardown with the persist/export/guard block → env-file; with the folder block (`refuse_main_checkout…`) → worktree-folder | `ORCHESTRATOR_DATABASE_SCHEME` |
   | Orchestrator vars checked in `workspace_detection_present` | `ORCHESTRATOR_ADAPTERS` (canonical order) |
   | Labels in `write_labels` | `ORCHESTRATOR_PORT_LABELS` |
   | Default port in `dev-port` | `ORCHESTRATOR_DEFAULT_PORT` |
   | Project steps in setup/teardown (installs, seeds, assets, cleanup) | the new project-owned `setup` / `teardown` |
   | Anything else: extra orchestrator vars, a changed puma pattern, custom port logic, extra functions other scripts call | **stop**: see "Unmapped logic" |

   Settings must match the old values exactly. For example, keep `ORCHESTRATOR_PROJECT` as the old allocation directory name even if it differs from the database prefix. Port blocks of existing worktrees are found by that name.

3. **Write the new files.**
   - `bin/orchestrator/config` from `references/examples/orchestrator-config.sh`, filled from the inventory.
   - `bin/orchestrator/setup` and `teardown`: start from the templates, then carry over every project step from the old files, in the same order relative to the managed calls. For example, steps that ran before port allocation go before `workspace_prepare_setup` only if they don't need the workspace name or the `.worktreeinclude` files.
   - Delete the old managed-role files (`env`, `port`, `dev-port`, `worktree-include`), then run `orchestrator-install PROJECT_DIR`.
   - Legacy `bin/workspace-*` names: move to `bin/orchestrator/` and update every reference (orchestrator configs, `bin/dev`, `Procfile.dev`, docs, CI). The check finds either name.

4. **Record after and compare.**

   ```sh
   orchestrator-check compare before.txt after.txt --accept <file>...
   ```

   Pass `--accept` only for the files below whose conditions the old scripts meet. Anything still `CHANGED` is a migration mistake. Fix the inventory or the project-owned files, and repeat until it prints `No unexpected changes.`

5. **Keep the storage formats.** The upgrade must not touch `~/.superset/port-allocations/`, `tmp/WORKSPACE_NAME`, or `.superset/ports.json`. Worktrees on older branches keep running their old scripts against the same files.

## Documented behavior fixes

Old scripts differ from layout 2 only where layout 2 fixes a bug. Each fix has an accept file that covers exactly its rows:

| Accept file | Applies when the old scripts… | Fix |
|-------------|-------------------------------|-----|
| `accept-conductor-detection-vars.txt` | detect Conductor via `CONDUCTOR_BIN_DIR` (first release, 2026-06-24) | Conductor is detected through `CONDUCTOR_WORKSPACE_PATH` / `CONDUCTOR_ROOT_PATH` |
| `accept-names-resolve-like-database-yml.txt` | have no `workspace_setup_name` (before 2026-08-29) | `workspace_name` reads only what `config/database.yml` reads; the main checkout is no longer named after its folder |
| `accept-worktree-folder-teardown-releases-ports.txt` | use the worktree-folder teardown, which exits before releasing ports | teardown releases the port block and labels file |

The 10080 port-block skip (2026-07-02) shows no row in the check: allocation never reaches 10080 in the sandbox. Mention it to the user if the old `port` lacks `block_is_browser_safe`.

## Unmapped logic

When the old scripts hold logic with no place in the table above, it is the project's own behavior and must survive:

- **An orchestrator the skill ships, detected through other variables**: ask the user which variables their tool really sets. If the skill's adapter is wrong, fix the adapter in the skill (see `../adding-an-orchestrator.md`). Otherwise keep the old variable in a project adapter.
- **An orchestrator the skill doesn't ship**: turn it into a project adapter (`../adding-an-orchestrator.md`, "In a project only").
- **Custom port or naming logic**: show it to the user and ask whether to keep it as a project adapter or drop it. Dropping it shows as `CHANGED` rows in the check, which the user must accept explicitly.

Never quietly simplify old behavior during an upgrade.
