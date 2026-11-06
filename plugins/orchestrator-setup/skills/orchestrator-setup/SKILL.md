---
name: orchestrator-setup
description: Configure a Rails project for agent orchestrators (Conductor, Superset, super.engineering, Orca, Paseo, T3 Code) — first-time setup, adding or removing an orchestrator, or upgrading older bin/orchestrator scripts. Handles config files, workspace detection, database isolation, ports, .worktreeinclude, and documentation.
user_invocable: true
---

# Orchestrator Setup

Configure a Rails project so agent orchestrators can run many git worktrees side by side, each with its own databases, ports, and dev server. Built for **Ruby on Rails** conventions: `config/database.yml`, `bin/` scripts, Bundler, Procfile-based dev servers.

Other projects (Node, static sites) use the same layout with `ORCHESTRATOR_DATABASE_SCHEME=none`. Skip the database parts of Phases 0 and 6, and write `setup`, `teardown` and `bin/dev` for the project's own toolchain, keeping the three managed calls and `bin/orchestrator/dev-port`.

The skill must be able to add any orchestrator to any project at any time without changing how the others behave. Two things make that safe, and every phase below leans on them: the **managed** layout, and **the check**.

## Supported orchestrators

Each orchestrator's specification (env vars, config file and schema, port strategy, lifecycle hooks, dev command, quirks) lives in its reference file. **Read the reference file for every orchestrator involved before changing anything**, including ones the project already supports. This table is only an index.

| Orchestrator | Adapter id | Ports | Reference |
|--------------|-----------|-------|-----------|
| **Conductor** | `conductor` | Tool provides | `references/orchestrators/conductor.md` |
| **Paseo** | `paseo` | Tool provides | `references/orchestrators/paseo.md` |
| **Superset** | `superset` | Project allocates | `references/orchestrators/superset.md` |
| **super.engineering** (formerly Superconductor) | `superconductor` | Project allocates | `references/orchestrators/superconductor.md` |
| **Orca** | `orca` | Project allocates | `references/orchestrators/orca.md` |
| **T3 Code** | `t3code` | Project allocates | `references/orchestrators/t3code.md` |

`Superconductor` is the legacy name for super.engineering, not an unknown orchestrator.

## The managed layout (layout 2)

```
bin/
  dev                       project-owned (Rails convention)
  orchestrator/
    config                  project-owned: every project-specific value
    setup                   project-owned: calls workspace_prepare_setup, then project steps
    teardown                project-owned: calls workspace_begin/finish_teardown
    psql                    project-owned, optional
    env                     managed: detection, names, paths, lifecycle steps
    port                    managed: 10-port block allocation
    dev-port                managed: port resolution chain
    worktree-include        managed: .worktreeinclude copy
    adapters/<id>.sh        managed: one per enabled orchestrator
```

**Managed** files come verbatim from `references/managed/bin/orchestrator/`, carry the stamp `Managed by the orchestrator-setup skill (layout 2)`, and are only ever replaced wholesale by `scripts/orchestrator-install PROJECT_DIR`. Never edit a managed file in a project. If behavior must differ, the difference goes in `config`, in `setup` or `teardown`, or in a project adapter (see `references/adding-an-orchestrator.md`).

Each adapter answers the same questions about its own orchestrator: is it active, what's the workspace path, name, and tool-provided port, where's the main checkout, is this the main checkout, and which **traits** apply (`allocate-ports`, `port-labels`, `worktree-include`, `discover-port`). `env` asks the enabled adapters in `ORCHESTRATOR_ADAPTERS` order. That's why adding an adapter can't change another orchestrator's code path. The contract is documented at the top of the managed `env`.

## The check

`scripts/orchestrator-check` records what a project's scripts do in every orchestrator context: setup hook, terminals, agent shells, main checkout, teardown. It runs in a throwaway repo with a real worktree. Stubs stand in for Rails, Bundler, npm and friends; the Rails stub evaluates the project's `config/database.yml`, so each row shows the actual database names. Real databases, ports and secrets are never touched.

```sh
ruby <skill-dir>/scripts/orchestrator-check record PROJECT_DIR --output /tmp/before.txt
# ...change the project...
ruby <skill-dir>/scripts/orchestrator-check record PROJECT_DIR --output /tmp/after.txt
ruby <skill-dir>/scripts/orchestrator-check compare /tmp/before.txt /tmp/after.txt [--allow <adapter-id>]... [--accept FILE]...
```

- Take the **before** recording first, before you edit anything in a project that already has orchestrator scripts. Without it, the check can't prove anything.
- If a recorded `setup` row exits non-zero because the project's setup calls a command the check doesn't stub (`yarn`, `bin/vite`, a rake wrapper), add `--stub <name>` to both recordings until setup runs through. A setup that dies early hides every row after it.
- `--allow <id>` accepts changes in the scenario of each orchestrator you're adding or removing. `--accept FILE` accepts documented fixes (`references/upgrade/`). Every other `CHANGED` row is a regression. Fix it, or stop and show it to the user. Never accept a diff just because it looks harmless.
- `compare` passes only when it prints `No unexpected changes.` Rows marked `ADDED` (functions old scripts lacked) are information, not failures.

## Phase 0 — Detect project state

Confirm it's a Rails app (`Gemfile`, `config/routes.rb`, `config/database.yml`, `bin/rails`), then detect:

- **Layout**, which picks the route through the phases below:
  - **none**: no `bin/orchestrator/` and no legacy `bin/workspace-*` scripts → *fresh setup*.
  - **layout 1**: `bin/orchestrator/` (or legacy `bin/workspace-env`, `bin/workspace-setup`, …) without the managed stamp in `env`. Hand-adapted scripts from an older version of this skill, or written by hand → *upgrade*: follow `references/upgrade/README.md` first, then come back for Phases 1–8.
  - **layout 2**: `bin/orchestrator/env` carries the managed stamp → *change*: Phases 1–8 edit `config` and reinstall.
- **Database adapter**: `adapter:` in `config/database.yml`. PostgreSQL is expected.
- **Database isolation scheme** in `config/database.yml`:
  - `worktree-folder`: ERB derives names from the `.git` pointer file (`gitdir: …/.git/worktrees/<name>`) or the worktree folder.
  - `env-file`: ERB reads a project env var such as `*_WORKSPACE_NAME`, then `tmp/WORKSPACE_NAME`.
  - `fixed`: static stock names, no isolation.
  - `unknown`: too complex to classify. Treat it as user-owned and ask before changing it.
- **Dev server**: `Procfile.dev`, `bin/dev`, Overmind/Foreman. **Frontend bundler**: Vite, esbuild, etc. Extra services need extra ports.
- **Existing orchestrator configs**: `.conductor/settings.toml` (and `.local`), `paseo.json`, `.superset/config.json`, `.superconductor/config.json`, `orca.yaml`, `t3.json`. These tell you which orchestrators the project already supports, and which command wrappers it uses.
- **`.worktreeinclude`**: whether it exists and which gitignored files it lists. If it's missing but a fresh worktree needs gitignored files to boot (`.env`, `config/master.key`), suggest one.

If any orchestrator scripts exist, take the check's **before** recording now. Then give a brief detection summary that names the route.

## Phase 1 — Choose orchestrators

Ask: "Which agent orchestrators do you want to configure?" Multi-select: `Conductor`, `Paseo`, `Superset`, `super.engineering`, `Orca`, `T3 Code`. Pre-select the ones the project already supports. Removing one only happens when the user deselects it.

For an orchestrator not in the table, follow `references/adding-an-orchestrator.md`, then continue here as if it had always been supported.

## Phase 2 — Determine lifecycle commands

| Lifecycle | Purpose | Command |
|-----------|---------|---------|
| **setup** | Prepare a new worktree (deps, databases, local files, ports) | `bin/orchestrator/setup` |
| **teardown** | Clean up a worktree (drop databases, release ports) | `bin/orchestrator/teardown` |
| **dev** | Start the dev server | `bin/dev` |

Keep the project's command wrappers. If existing configs or docs run commands through `mise exec --`, `bundle exec`, `overmind`, or similar, use the same wrapper in every orchestrator config. An orchestrator config that already works is the strongest evidence.

On a fresh setup, ask whether to scaffold `bin/orchestrator/` (recommended) or use raw commands the user provides.

## Phase 3 — Orchestrator config files

For each selected orchestrator, create or update its project config exactly as its reference file says:

| Orchestrator | Project config file | Lifecycle represented |
|--------------|---------------------|-----------------------|
| Conductor | `.conductor/settings.toml` | `scripts.setup`, `scripts.run`, `scripts.archive`, `scripts.run_mode` |
| Paseo | `paseo.json` | `worktree.setup`, `worktree.teardown`, `scripts.dev` |
| Superset | `.superset/config.json` | `setup`, `teardown`, `run` |
| super.engineering | `.superconductor/config.json` | `setup`, `teardown`, `run` |
| Orca | `orca.yaml` | `scripts.setup`, `scripts.archive` |
| T3 Code | `t3.json` | `scripts[]`: setup (`runOnWorktreeCreate`, async), dev, teardown (`runOnSettle`) |

- Write project-scoped config whenever the tool supports it, instead of sending the user to an app UI.
- Lifecycle key names differ between tools (Orca and Conductor use `archive`).
- A tool with no dev command in its config gets its config for the hooks it does support. Handle the dev server as its reference file's "Custom dev command" section says.
- T3 Code has no worktree-removal hook. Its teardown runs when the thread settles (`runOnSettle`), which marks the thread as done.
- A tool that runs config only after it's registered in the app (T3 Code) gets registered through its own API when the session has one (`t3_project_*` MCP tools), merged with what the user already saved.
- Edit other orchestrators' config files only to keep wrappers consistent, and only when the user agrees.

## Phase 4 — .gitignore

Add entries only for files this configuration generates, and only if they're missing:

```gitignore
# Orchestrator-generated files (workspace-specific, not committed)
.superset/ports.json   # only if an enabled adapter has the port-labels trait
tmp/WORKSPACE_NAME     # only for the env-file database scheme
```

## Phase 5 — Install bin/orchestrator

### 5a. `bin/orchestrator/config` (project-owned)

**Template**: `references/examples/orchestrator-config.sh`. Set `ORCHESTRATOR_PROJECT`, `ORCHESTRATOR_WORKSPACE_ENV`, `ORCHESTRATOR_DATABASE_SCHEME` (`env-file`, `worktree-folder`, or `none` for a project with no per-worktree database, from Phase 0), `ORCHESTRATOR_DEFAULT_PORT`, and `ORCHESTRATOR_PORT_LABELS` (services at offsets 0, 1, 2… matching `bin/dev`). Also set `ORCHESTRATOR_ADAPTERS`: the selected adapter ids, in the canonical order `conductor paseo superset superconductor orca t3code`. That order is the precedence if two tools' variables are ever set at once. A `fixed` database scheme becomes `env-file` in 6a.

On the *change* route, the only edit is usually `ORCHESTRATOR_ADAPTERS`.

### 5b. Managed files

```sh
sh <skill-dir>/scripts/orchestrator-install PROJECT_DIR
```

It copies `env`, `port`, `dev-port`, `worktree-include` and the listed adapters, removes managed adapters that are no longer listed, keeps project adapters, and refuses to overwrite any file without the managed stamp. Don't copy managed files by hand.

### 5c. `bin/orchestrator/setup` and `teardown` (project-owned)

**Templates**: `references/examples/orchestrator-setup.sh` and `orchestrator-teardown.sh`. They hold only project steps around three managed calls:

- `workspace_prepare_setup`: copies `.worktreeinclude` files when an adapter has the `worktree-include` trait, resolves, persists and exports the workspace name (env-file scheme), and allocates the port block (`allocate-ports`).
- `workspace_begin_teardown`: returns 0 when there are databases to drop (env var exported), 1 when there's nothing to drop. It exits instead of dropping the main checkout's databases (worktree-folder) or orphaning a workspace's (env-file).
- `workspace_finish_teardown`: releases the port block.

Keep project-specific steps (JS installs, seeds, assets, extra cleanup) in these files. On an existing project, they already hold the project's steps. Don't touch them on the *change* route.

## Phase 6 — Database, dev server, ports

### 6a. `config/database.yml`

Treat it as a decision, not a rewrite target. An existing per-worktree scheme (`worktree-folder` or `env-file`) is kept as is. All supported orchestrators create git worktrees, so folder derivation isolates them all without env bridging. Only a `fixed` file gets the env-file ERB from `references/examples/database.yml`:

```yaml
<%
workspace_name_file = File.expand_path("tmp/WORKSPACE_NAME", ENV.fetch("PWD"))
workspace_name = ENV["MYAPP_WORKSPACE_NAME"]
workspace_name = File.read(workspace_name_file).strip if workspace_name.to_s.empty? && File.file?(workspace_name_file)
workspace_name = nil if workspace_name&.empty?
workspace = ["myapp", workspace_name].compact.join("_")
%>
```

That gives `myapp_<workspace>_development` in a workspace and `myapp_development` outside one. The env var name must equal `ORCHESTRATOR_WORKSPACE_ENV`. Readers in shell (`workspace_name`) use the same two sources in the same order, so shell and Rails never disagree.

### 6b. `bin/dev` and `Procfile.dev` (project-owned)

**Templates**: `references/examples/dev.sh` and `Procfile.dev`. `bin/dev` gets its base port from `bin/orchestrator/dev-port`, derives `VITE_PORT=$((PORT + 1))` and the other ports to match `ORCHESTRATOR_PORT_LABELS`, then starts Overmind (or Foreman). The resolution chain itself is managed: tool port, then allocated block, then puma discovery, then `$PORT`, then the default. See the header of the managed `dev-port`.

### 6c. `bin/orchestrator/psql` (project-owned, optional)

**Template**: `references/examples/orchestrator-psql.sh`. It asks `config/database.yml` for the database name instead of rebuilding it in shell.

## Phase 7 — Documentation

Update `CLAUDE.md` and/or `AGENTS.md` (create a section in `CLAUDE.md` if neither exists):

1. Supported orchestrators and their detection variables.
2. The database scheme and how databases are named.
3. Dev server startup and port resolution per orchestrator.
4. Quirks from the reference files (Orca: manual dev server; T3 Code: teardown runs on settle, actions must be imported).
5. That `bin/orchestrator/` managed files are replaced by the orchestrator-setup skill and never edited by hand, and that project settings live in `bin/orchestrator/config`.
6. If any adapter has the `worktree-include` trait: `.worktreeinclude` is the one list of gitignored files new worktrees get.

## Phase 8 — Verification

1. Syntax: `sh -n` on every file in `bin/orchestrator/` and `bin/orchestrator/adapters/`. Parse each orchestrator config as JSON, YAML or TOML. Render `config/database.yml` with `ruby -rerb -e "ERB.new(File.read('config/database.yml')).result"`.
2. **The check**: record after, then compare against the before recording, with `--allow` for each orchestrator added or removed and `--accept` only for the files the upgrade guide names. It must print `No unexpected changes.`
3. On a fresh setup (no before recording), record once and read the rows for each selected orchestrator: setup creates `<project>_<workspace>_*` (or folder-derived) databases, `dev-port` returns the tool port or an allocated block, teardown drops what setup created, and the main-checkout rows keep the shared databases.

## Checklist

- [ ] Layout and route detected; before recording taken if scripts existed; reference file read for every orchestrator involved
- [ ] Orchestrator configs written per reference file, wrappers preserved, app registration done where needed (T3 Code) or the manual step named in the summary
- [ ] `.gitignore` covers only generated files this configuration creates
- [ ] `bin/orchestrator/config` filled in; `ORCHESTRATOR_ADAPTERS` lists the selected ids in canonical order
- [ ] Managed files installed by `orchestrator-install`, none edited by hand
- [ ] `setup` / `teardown` call the managed steps and keep every project-specific step
- [ ] `config/database.yml` kept, or made env-file isolated if it was fixed
- [ ] `bin/dev` port offsets match `ORCHESTRATOR_PORT_LABELS`
- [ ] `CLAUDE.md` / `AGENTS.md` updated
- [ ] Syntax checks pass; the check prints `No unexpected changes.` (or, on a fresh setup, its rows were reviewed)
