# T3 Code

- **Website**: https://t3.codes/
- **GitHub**: https://github.com/pingdotgg/t3code
- **Docs**: https://github.com/pingdotgg/t3code/tree/main/docs/user (project settings, thread sidebar, terminal)
- **Config schema**: https://t3.codes/schema/t3.json (source: `packages/contracts/src/t3ProjectFile.ts`)

T3 Code is an agent orchestrator that runs threads either in the project's main checkout ("local") or in a fresh git worktree per thread. By default, worktrees live under `~/.t3/worktrees/<repo>/<t3-xxxxxxxx>/`; **Settings → Worktrees → Worktree location** can move them. T3 Code reads checked-in project configuration from `t3.json` at the repository root.

## Adapter

`bin/orchestrator/adapters/t3code.sh` (managed). Traits: `allocate-ports`, `worktree-include`. It also defines `orchestrator_t3code_in_main_checkout`, because T3 Code sets its terminal and agent variables in the main checkout as well. Enable it by adding `t3code` to `ORCHESTRATOR_ADAPTERS` in `bin/orchestrator/config`.

## Environment variables

T3 Code sets different variables in different contexts. It also strips every inherited `T3CODE_*` variable from terminal environments, so a terminal sees only the ones T3 Code sets for it.

| Variable | Context | Purpose |
|----------|---------|---------|
| `T3CODE_WORKTREE_PATH` | Project actions (including setup) and terminals of a worktree thread | **Detection var (worktrees).** Absolute path to the thread's worktree. Absent in the main checkout. |
| `T3CODE_PROJECT_ROOT` | Project actions and every T3 Code terminal, worktree or not | **Detection var (terminals).** The project's workspace root, which is the main checkout. Use it as the copy source for `.worktreeinclude`. |
| `T3CODE_THREAD_ID` | Agent processes (Claude, Codex) and every command they start | **Detection var (agent shells).** The thread ID. Agent shells get no `T3CODE_WORKTREE_PATH` or `T3CODE_PROJECT_ROOT`; their working directory is the thread's checkout. |

There is no workspace-name variable and no port variable. (`T3CODE_PORT` is T3 Code's own server port. Never use it for the app.)

## Config file

**`t3.json`** at the repository root.

Create or update this project file when T3 Code is selected.

```json
{
  "$schema": "https://t3.codes/schema/t3.json",
  "scripts": [
    {
      "name": "Setup Worktree",
      "command": "<setup command>",
      "icon": "configure",
      "runOnWorktreeCreate": true,
      "async": true
    },
    {
      "name": "Dev Server",
      "command": "<dev server command>",
      "icon": "play"
    },
    {
      "name": "Teardown Worktree",
      "command": "<teardown command>",
      "icon": "configure",
      "runOnSettle": true
    }
  ]
}
```

Script fields:

| Field | Meaning |
|-------|---------|
| `name` | Label in the actions menu. Required. |
| `command` | Shell command, run in a T3 Code terminal at the thread's checkout (the worktree for worktree threads). Required. |
| `icon` | One of `play`, `test`, `lint`, `configure`, `build`, `debug`. Defaults to `play`. |
| `runOnWorktreeCreate` | Runs automatically after T3 Code creates a worktree for a new thread. T3 Code uses only the **first** script with this flag. |
| `async` | For `runOnWorktreeCreate` scripts only. `true` (the default) starts the agent while setup is still running; `false` holds the agent until setup exits. **Use `true`**, so the thread is usable at once instead of waiting on `bundle install` and `db:prepare`. Setup's terminal stays open, so its progress and failures are visible. Set `false` only if the user asks to hold the agent until setup finishes. |
| `runOnSettle` | Runs in the thread's worktree when the thread settles, meaning work on it is done. **Put teardown here**, so a finished thread's databases and port block go away with it. Threads without their own worktree (local mode, the main checkout) skip it, so the shared databases are never touched. If a settled thread is picked up again, run `Setup Worktree` from the actions menu to recreate its databases. |
| `previewUrl` / `autoOpenPreview` | A fixed URL opened in the desktop app's preview when the script runs. It is static and cannot carry a per-worktree port, so leave it out (see Port strategy). |

Order matters. The first script that is neither setup nor settle becomes the primary action, the one-click button. `Teardown Worktree` is a settle script, so `Dev Server` is the button. Keep `Dev Server` listed before teardown anyway, so the button can never drop databases if someone turns the settle flag off.

`t3.json` can also set `defaultThreadEnvMode` (`"worktree"` or `"local"`). Leave it out unless the user asks: it changes where every new thread starts.

### Registering the actions in T3 Code

T3 Code does **not** run `t3.json` scripts on its own. They show up under **From t3.json** in the thread's actions menu and in **Settings → Projects → Actions**, where they must be imported into the project's saved actions. Only imported actions run, including `runOnWorktreeCreate`. Importing copies the script, so later edits to `t3.json` must be imported again.

So that setup works without a trip through the UI:

1. If the T3 Code MCP tools are available (`t3_project_list`, `t3_project_read`, `t3_project_update`), find the project whose workspace root is this repository. Read its saved `scripts`, then call `t3_project_update` with the merged list. Keep every existing action the user made. Replace an existing action only when it has the same name or the same command as a `t3.json` script. Give new actions stable ids such as `setup-worktree`, `dev-server` and `teardown-worktree`. The update fields match `t3.json` (`name`, `command`, `icon`, `runOnWorktreeCreate`, `async`, `runOnSettle`, plus a required `id`). Only one action may have `runOnWorktreeCreate: true`, so turn the flag off on any older setup action you keep.
2. Without those tools, commit `t3.json` and tell the user, in the final summary, to import the three actions once from **From t3.json** in the actions menu. Teammates do the same once per machine.

## Port strategy

**Project allocates a 10-port block.**

- T3 Code assigns no ports. The project allocates a contiguous 10-port block per checkout, using the same `bin/orchestrator/port` store as Superset, super.engineering and Orca (`$SUPERSET_HOME_DIR/port-allocations/<project>/`, keyed by a checksum of the workspace path). That store is a project convention, not a dependency on Superset.
- The adapter's path must resolve to the same string in every T3 Code context: `T3CODE_WORKTREE_PATH` in actions and worktree terminals, and the git top-level for agent shells, which have no path variable. Normalize both with `pwd -P` so a symlinked worktree location doesn't produce two allocations for one checkout.
- Detection includes `T3CODE_PROJECT_ROOT` and `T3CODE_THREAD_ID`, which are also set in the main checkout. A dev server started from a main-checkout terminal or local-mode thread therefore gets its own block too. This matches Orca, and it keeps the main checkout from colliding with worktrees on 3000.
- **No labels file.** T3 Code discovers listening ports itself: its preview panel lists local servers started from its terminals or by its agents, attributed to the thread through the terminal's processes and `T3CODE_THREAD_ID`. Do not write `.superset/ports.json` under T3 Code, and do not set `previewUrl`.
- Teardown on settle releases the block. A worktree removed without settling leaks nothing either: `bin/orchestrator/port allocate` already drops allocations whose workspace path is gone, so its block is reclaimed by the next allocation.

## Lifecycle

| Lifecycle | T3 Code mechanism |
|-----------|-------------------|
| setup | The `runOnWorktreeCreate` action (`async: true`), run in a terminal at the new worktree with `T3CODE_PROJECT_ROOT` and `T3CODE_WORKTREE_PATH` set. Its terminal stays open, so failures are visible. |
| dev | A regular action (`Dev Server`), run from the actions menu or its keybinding. |
| teardown | The `runOnSettle` action (`Teardown Worktree`), run in the thread's worktree when the thread settles. It can also be run by hand from the actions menu. T3 Code runs nothing when it removes a worktree, so databases of a worktree deleted without settling its thread are left behind. |

## `.worktreeinclude`

T3 Code does **not** honor `.worktreeinclude`. New worktrees contain only tracked files, so gitignored essentials such as `.env`, `config/master.key` and `config/credentials/*.key` are missing. The workaround is the managed `bin/orchestrator/worktree-include`. `workspace_prepare_setup` runs it first because the T3 Code adapter has the `worktree-include` trait. It copies every file that matches a `.worktreeinclude` pattern **and** is gitignored, the same rule Claude Code applies, from `T3CODE_PROJECT_ROOT` into the worktree. It never overwrites a file already in the worktree.

Keep it a copy, not a symlink: a worktree must not be able to edit the main checkout's secrets or local config. (T3 Code's own repository symlinks `.env` in its setup script. That suits its single dev token, not a Rails app's per-checkout files.)

## Custom dev command

The dev server is a regular `t3.json` action (`"command": "bin/dev"`, `"icon": "play"`). `bin/dev` calls `bin/orchestrator/dev-port`. Under T3 Code that resolves to the workspace's allocated block, through the `workspace_needs_port_allocation` branch.

## Workspace name resolution

T3 Code names no workspace. The adapter's name function returns `basename "$T3CODE_WORKTREE_PATH"` (for example `t3-1a9dfa6a`), which setup persists to `tmp/WORKSPACE_NAME` for the env/file database scheme. Readers, including agent shells, take the name from that file. The main checkout has no `T3CODE_WORKTREE_PATH`, so it resolves no orchestrator name and stays on the shared database.

## Notes

- Preserve command wrappers from other orchestrator configs in `t3.json` commands too (for example `mise trust && mise exec -- bin/orchestrator/setup`).
- `t3.json` holds no environment variables or secrets. Gitignored values reach worktrees only through `.worktreeinclude`.
- A project-level actions list saved in T3 Code overrides `t3.json` completely. If the project already has saved actions, merge into them as described above instead of assuming `t3.json` is live.
