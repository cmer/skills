---
name: orchestrator-setup
description: Configure a Rails project for agent orchestrators (Conductor, Superset, super.engineering, Orca, Paseo). Handles config files, workspace detection, database isolation, port management, and documentation.
user_invocable: true
---

# Orchestrator Setup

Configure a Rails project to work with one or more agent orchestrators. These orchestrators manage git worktrees so developers can work on multiple branches simultaneously with isolated databases, ports, and dev servers.

This skill is designed for **Ruby on Rails applications**. It understands Rails conventions (`config/database.yml`, `bin/` scripts, `Gemfile`, `bundle exec`, Procfile-based dev servers) and generates integration code accordingly.

## Supported orchestrators

Each orchestrator's full specification — env vars, config file path and schema, port strategy, lifecycle hook names, custom dev command, and quirks — lives in its reference file under `references/orchestrators/`. **Read the reference file for every orchestrator the user selects before making any changes.** Do not rely on this table for config details; it is only a navigation index.

| Orchestrator | Project allocates ports? | Reference |
|--------------|--------------------------|-----------|
| **Conductor** | No (tool provides) | `references/orchestrators/conductor.md` |
| **Paseo** | No (tool provides) | `references/orchestrators/paseo.md` |
| **Superset** | Yes (10-port block) | `references/orchestrators/superset.md` |
| **super.engineering** | Yes (10-port block) | `references/orchestrators/superconductor.md` |
| **Orca** | Yes (10-port block) | `references/orchestrators/orca.md` |

## Phase 0 — Detect project state

Before asking questions, inspect the project:

### Rails project detection

Confirm this is a Rails application by checking for `Gemfile`, `config/routes.rb`, `config/database.yml`, and `bin/rails`.

Detect:

- **Database adapter** — check `config/database.yml` for `adapter:` (postgresql, mysql2, sqlite3). PostgreSQL is expected for workspace isolation.
- **Database isolation scheme** — inspect `config/database.yml` for existing workspace/worktree-aware database names. Report one of:
  - `git-worktree-folder`: ERB reads the `.git` pointer file (`gitdir: .../.git/worktrees/<name>`), current worktree folder, or related path/basename data to derive distinct database names per worktree.
  - `workspace-env-file`: ERB reads a project env var such as `*_WORKSPACE_NAME`, `tmp/WORKSPACE_NAME`, or both.
  - `fixed`: database names are static, stock Rails names and are not isolated per worktree.
  - `unknown`: ERB is complex enough that you cannot confidently classify it; treat it as user-owned and ask before changing it.
- **Dev server command** — look for `Procfile.dev`, `bin/dev`, or a Foreman/Overmind setup.
- **Frontend bundler** — Vite (`vite.config.*`), Webpacker, esbuild, or Propshaft. Determines whether additional ports are needed (e.g., Vite dev server).
- **Setup/teardown scripts** — look for `bin/setup`, `bin/orchestrator/setup`, `bin/orchestrator/teardown` (or legacy `bin/workspace-setup`, `bin/workspace-teardown`).
- **Existing orchestrator configs** — check if any of the supported config files already exist (including `.conductor/settings.toml` / `.conductor/settings.local.toml` for Conductor).
- **Existing workspace infrastructure** — look for `bin/orchestrator/` directory, or legacy `bin/workspace-env`, `bin/workspace-setup`, etc.

State a brief detection summary before continuing.

## Phase 1 — Choose orchestrators

Ask the user which orchestrator(s) to configure:

- Question: "Which agent orchestrators do you want to configure?"
- Options (multi-select): `Conductor`, `Paseo`, `Superset`, `super.engineering`, `Orca`
- If the user names an orchestrator not in the list, proceed to Phase 1b.

Treat `Superconductor` as the legacy name for `super.engineering`, not as an unknown orchestrator. Its reference file remains `references/orchestrators/superconductor.md` because local paths and developer-facing names still use `superconductor`.

For each selected orchestrator, read its reference file at `references/orchestrators/<name>.md` or the mapped reference file named in the supported-orchestrators table.

### Phase 1b — New orchestrator (not in the supported list)

If the user names an unknown orchestrator, add it as a first-class supported orchestrator rather than bodging one-off branches into the scripts. Gather (use WebFetch/WebSearch on the tool's docs if needed):

1. **Tool name**
2. **Environment variables** — detection var, workspace name var (optional), port var (optional), home dir var (optional).
3. **Config file format** — path and schema.
4. **Port strategy** — tool provides port, or project allocates a block.
5. **Lifecycle hook names** — setup / teardown (or equivalents).
6. **Labels file** — does the tool read a port labels file? Format?

Then integrate it cleanly:

1. Create `references/orchestrators/<name>.md` following the format of the existing reference files (env vars, config file, port strategy, lifecycle, custom dev command, workspace name resolution, notes).
2. Add a row to the summary table above.
3. Add the orchestrator's detection var(s) to the relevant functions in `bin/orchestrator/env` (`workspace_detection_present`, `workspace_env_name`, `workspace_path`, and `workspace_needs_port_allocation` if it requires project-managed ports) and to the resolution chain in `bin/orchestrator/dev-port`.
4. Proceed through Phases 2–8 exactly as if the orchestrator had always been supported.

This is the same path described in "Adding support for a new orchestrator" at the end of this file — a runtime request and a design-time extension converge on one clean flow.

## Phase 2 — Determine lifecycle commands

Resolve the three lifecycle commands for this project:

| Lifecycle | Purpose | Example |
|-----------|---------|---------|
| **setup** | Prepare a new worktree (install deps, create database, seed data) | `bin/orchestrator/setup` |
| **teardown** | Clean up a worktree (drop database, release ports) | `bin/orchestrator/teardown` |
| **dev** | Start the dev server | `bin/dev` |

### If workspace scripts already exist

Use them directly.

Preserve existing project command wrappers when they are already part of the project's workflow. For example, if existing orchestrator configs or project docs run scripts through `mise exec --`, `bundle exec`, `bin/rails`, `overmind`, or another local tool wrapper, use that same wrapper in every orchestrator config instead of writing a bare command. If one selected orchestrator already has a working config, treat its commands as strong evidence for the other orchestrator configs.

### If workspace scripts don't exist

Ask the user:

- Question: "Should I scaffold workspace management scripts for this project?"
- Options:
  - `Yes, create bin/orchestrator/ scripts (Recommended)` — scaffold the scripts.
  - `No, I'll provide the commands` — ask for raw commands to put in config files.

When scaffolding, create scripts under `bin/orchestrator/`. `bin/dev` stays at the top level since it's a standard Rails convention. See Phase 5 for details.

## Phase 3 — Create orchestrator config files

For each selected orchestrator, create or update its config file exactly as documented in its reference file at `references/orchestrators/<name>.md`. The config path, schema, lifecycle key names, custom dev command, and any quirks all live there — read it before writing the file. Fill in the resolved lifecycle commands from Phase 2.

Project config files to create or update:

| Orchestrator | Project config file | Lifecycle commands represented |
|--------------|---------------------|--------------------------------|
| Conductor | `.conductor/settings.toml` | `scripts.setup`, `scripts.run`, `scripts.archive`, `scripts.run_mode` |
| Paseo | `paseo.json` | `worktree.setup`, `worktree.teardown`, `scripts.dev` |
| Superset | `.superset/config.json` | `setup`, `teardown`, `run` |
| super.engineering | `.superconductor/config.json` | `setup`, `teardown`, `run` |
| Orca | `orca.yaml` | `scripts.setup`, `scripts.archive` |

Things the reference files spell out and you must honor:

- Agents must write project-scoped config files when the orchestrator supports them. Do not tell the user to finish setup in an app UI when a repository config file can express the same lifecycle commands.
- Lifecycle key names differ between tools (e.g. Orca uses `archive` rather than `teardown`).
- Some tools have no `run`/`dev` in their project config. Still create or update the project config file for the lifecycle hooks it does support, then handle the dev command as described in the orchestrator's "Custom dev command" section.

## Phase 4 — Update .gitignore

Add gitignore entries for generated files that should not be committed:

```gitignore
# Orchestrator-generated files (workspace-specific, not committed)
.superset/ports.json

# Only for the env/file database scheme
tmp/WORKSPACE_NAME
```

Only add entries for generated files the chosen configuration will actually create. Add `tmp/WORKSPACE_NAME` only when using the env/file database scheme; a preserved git-worktree-folder `database.yml` does not need that file. Check if the entries already exist before adding.

## Phase 5 — Scaffold workspace detection and lifecycle scripts

If the project lacks workspace management scripts and the user opted to scaffold them, create the infrastructure under `bin/orchestrator/`. This is the core value: enabling multiple worktrees with isolated databases, ports, and dev servers.

All orchestrator scripts live in `bin/orchestrator/` to keep them cleanly namespaced. The only exception is `bin/dev`, which stays at the top level as a standard Rails convention.

```
bin/
  dev                     # top-level (Rails convention)
  orchestrator/
    env                   # workspace detection (sourced by other scripts)
    setup                 # worktree setup lifecycle
    teardown              # worktree teardown lifecycle
    dev-port              # port resolution
    port                  # port block allocation
    psql                  # database connection helper (optional)
```

Complete working examples of every file are in `references/examples/`. Read each example before creating the corresponding file — they contain detailed adaptation instructions in their header comments. The examples use `MYAPP` / `myapp` as placeholders; replace these with the actual project name.

This phase builds the detection foundation and lifecycle hooks: `env`, `setup`, `teardown`. Phase 6 wires up ports, database isolation, and the dev server.

### 5a. Workspace environment script — `bin/orchestrator/env`

**Example**: `references/examples/orchestrator-env.sh`

This is the single source of truth for workspace detection. Every other script in `bin/orchestrator/` sources this file. **Never duplicate orchestrator detection logic outside this file.**

The script provides these shell functions:

| Function | Purpose |
|----------|---------|
| `workspace_name` | Resolves the workspace name (file → env → detection + basename) |
| `workspace_managed` | Returns true if running inside any orchestrator |
| `workspace_detection_present` | Returns true if any orchestrator detection var is set |
| `workspace_needs_port_allocation` | Returns true if the active orchestrator requires project-managed ports |
| `workspace_path` | Returns the workspace root path |
| `workspace_database_prefix` | Optional: returns `<project>_<workspace>` or just `<project>` for the env/file database scheme |
| `workspace_database_name ENV` | Optional: returns full database name like `<project>_<workspace>_development` for the env/file database scheme |
| `persist_workspace_name` | Optional for the env/file database scheme: writes workspace name to `tmp/WORKSPACE_NAME` |

Key design principles:

- **Workspace name resolution order**: persisted file (`tmp/WORKSPACE_NAME`) → orchestrator env vars → `basename "$PWD"` when an orchestrator is detected. The persisted file takes priority because orchestrator env vars may not be present in every shell context or after scripts are run outside an orchestrator-provided environment.
- **Database config isolation**: if `config/database.yml` already derives names per worktree, preserve it and do not add shell database-name helpers that reimplement a different naming rule. If the project has stock fixed names, use the env/file pattern where `config/database.yml` reads a single project-level env var (e.g., `MYAPP_WORKSPACE_NAME`) and `tmp/WORKSPACE_NAME`; `bin/orchestrator/setup` bridges the gap by exporting the project env var after resolving the orchestrator-specific one.
- **Port allocation policy**: `workspace_needs_port_allocation` returns true only for orchestrators that don't provide ports (Superset, super.engineering, Orca). Conductor and Paseo provide ports directly.

Only include detection checks for orchestrators the project actually supports. Remove the others.

### 5b. Workspace setup script — `bin/orchestrator/setup`

**Example**: `references/examples/orchestrator-setup.sh`

Called by orchestrators during their setup lifecycle hook. Must be idempotent. Steps:

1. Sources `bin/orchestrator/env`
2. For the env/file database scheme: calls `persist_workspace_name` to write `tmp/WORKSPACE_NAME`, refuses to continue inside a detected orchestrator if the workspace name cannot be resolved, and exports `<PROJECT>_WORKSPACE_NAME` so Rails reads it in `config/database.yml`
3. For an existing git-worktree-folder database scheme: skip the workspace-name export and unresolved-name guard; `bin/rails db:prepare` already targets the database for the current worktree
4. Allocates a port block if `workspace_needs_port_allocation` returns true
5. Installs dependencies (`bundle install`, plus JS bundler if present)
6. Prepares databases: `bin/rails db:prepare` for development, `RAILS_ENV=test bin/rails db:prepare` for test

### 5c. Workspace teardown script — `bin/orchestrator/teardown`

**Example**: `references/examples/orchestrator-teardown.sh`

Called by orchestrators during their teardown/archive lifecycle hook. Steps:

1. Sources `bin/orchestrator/env`
2. For the env/file database scheme: resolves workspace name and exports `<PROJECT>_WORKSPACE_NAME`
3. For an existing git-worktree-folder database scheme: do not require a workspace name; instead refuse to run in the main checkout where `.git` is a directory, because that checkout owns the primary dev/test databases
4. Drops each workspace database (development, test) with error recovery — individual drop failures should warn, not abort
5. Releases the port block if `workspace_needs_port_allocation` returns true

## Phase 6 — Configure ports, database, and dev server

This phase wires up port resolution and allocation, database isolation, and the dev server: `dev-port`, `port`, `config/database.yml`, `bin/dev`, `Procfile.dev`, and the optional `psql` helper. Skip the port-allocation pieces (`port`, and the allocation branch of `dev-port`) if no configured orchestrator requires project-managed ports.

### 6a. Dev port resolution — `bin/orchestrator/dev-port`

**Example**: `references/examples/orchestrator-dev-port.sh`

Outputs a single port number to stdout. Used by `bin/dev` and any script that needs to know the dev server port.

Resolution priority chain (order matters):

1. `$CONDUCTOR_PORT` — Conductor provides the first port in a 10-port workspace range
2. `$PASEO_WORKTREE_PORT` — Paseo provides this on all worktree processes
3. `$PASEO_PORT` — Paseo provides this on service processes only (fallback)
4. `bin/orchestrator/port get` or `allocate` — for Superset/super.engineering/Orca
5. Puma process discovery — fallback for shells where a tool-provided port is unavailable (scans `ps` output for puma with workspace name in title)
6. `$PORT` — generic env var
7. `3000` — default

The puma discovery pattern matches process titles like `puma <ver> (tcp://0.0.0.0:<port>) [<workspace>]`. Adjust the awk pattern if using a different server.

### 6b. Port allocation — `bin/orchestrator/port`

**Example**: `references/examples/orchestrator-port.sh`

Only needed if any configured orchestrator requires project-managed port allocation (Superset, super.engineering, Orca). Manages 10-port blocks.

Subcommands: `get`, `allocate`, `reserve PORT`, `release`.

Key implementation details:

- **Storage**: Allocations stored in `$SUPERSET_HOME_DIR/port-allocations/<project>/` (defaults to `~/.superset/port-allocations/<project>/`). Each workspace gets a file keyed by `cksum` of the workspace path. The file contains two lines: the base port and the workspace path.
- **Locking**: Uses `mkdir` for atomic lock acquisition with PID-based stale lock detection. Timeout after 10 seconds (100 × 0.1s).
- **Allocation range**: 10000–59990 in steps of 10. Checks both that the block doesn't overlap existing allocations and that all 10 ports are not in use (`lsof` check).
- **Stale cleanup**: On `allocate`, removes allocation files whose workspace path no longer exists on disk.
- **Labels file**: Writes `.superset/ports.json` mapping base port offsets to service names (e.g., Rails, Vite). Update the labels in `write_labels()` to match the project's services.

### 6c. Database isolation — `config/database.yml`

**Example**: `references/examples/database.yml`

Treat `config/database.yml` as a decision, not a rewrite target.

If Phase 0 found an existing scheme that yields distinct development/test database names per worktree, preserve it. This includes either:

- a git-worktree-folder scheme that derives the database suffix from the current worktree, commonly by reading the `.git` pointer file (`gitdir: <repo>/.git/worktrees/<wt>`) or current folder name, or
- an env/file scheme that already reads `*_WORKSPACE_NAME`, `tmp/WORKSPACE_NAME`, or equivalent workspace state.

All selected orchestrators in this skill create git worktrees, so folder-based derivation already isolates their databases. It needs no env var bridging, no `tmp/WORKSPACE_NAME`, and no setup-hook ordering to make Rails commands pick the right database. That is simpler and less fragile when every workspace is a git worktree.

Only apply the example ERB pattern when `database.yml` is fixed/static and does not already isolate per worktree. The blank-slate pattern makes `config/database.yml` construct workspace-isolated database names without knowing about any specific orchestrator:

```yaml
<%
workspace_name_file = File.expand_path("tmp/WORKSPACE_NAME", ENV.fetch("PWD"))
workspace_name = ENV["MYAPP_WORKSPACE_NAME"]
workspace_name = File.read(workspace_name_file).strip if workspace_name.to_s.empty? && File.file?(workspace_name_file)
workspace_name = nil if workspace_name&.empty?
workspace = ["myapp", workspace_name].compact.join("_")
%>
```

This produces database names like:

- With workspace `feature-login`: `myapp_feature-login_development`
- Without workspace: `myapp_development`

The ERB block reads from two sources in order:
1. `ENV["MYAPP_WORKSPACE_NAME"]` — set by `bin/orchestrator/setup` before Rails boots
2. `tmp/WORKSPACE_NAME` — persisted file, used when the env var isn't available (e.g., running `rails console` directly)

All database entries (`development`, `test`) use `<%= workspace %>_<environment>` for their database name. Production/staging entries use `DATABASE_URL` and are unaffected.

Strategy comparison:

- **Git-worktree-folder derivation**: database names come from the worktree path/folder or `.git` pointer. Prefer preserving this when already present. It works for Conductor, super.engineering, Superset, Orca, Paseo, and any other git-worktree-based tool without setup env bridging.
- **`WORKSPACE_NAME` env/file derivation**: database names come from a project env var plus optional `tmp/WORKSPACE_NAME`. Use this for stock Rails templates or for orchestrators that do not expose a stable worktree folder. It requires setup/teardown scripts and shell helpers to export the same project env var before Rails commands that depend on it.

### 6d. Dev server script — `bin/dev`

**Example**: `references/examples/dev.sh`

Starts the dev server with workspace-aware port assignment. Steps:

1. Calls `bin/orchestrator/dev-port` to get the base port
2. Derives additional ports: `VITE_PORT=$((PORT + 1))`, etc.
3. Exports all port env vars
4. Starts the process manager (Overmind preferred, Foreman fallback) with `Procfile.dev`

### 6e. Procfile — `Procfile.dev`

**Example**: `references/examples/Procfile.dev`

Each service reads its port from the env vars exported by `bin/dev`:

```
web: bin/rails s -p $PORT -b 0.0.0.0
vite: npx vite --port $VITE_PORT
```

### 6f. Database helper — `bin/orchestrator/psql` (optional)

**Example**: `references/examples/orchestrator-psql.sh`

Convenience script that connects to the correct workspace database without needing to remember the name. Do not re-derive the database name in shell unless the project uses the matching env/file naming scheme. Prefer asking Rails/database.yml for the authoritative name, as shown in `references/examples/orchestrator-psql.sh`; this works for both preserved worktree-aware configs and the blank-slate env/file template.

## Phase 7 — Update documentation

Update `CLAUDE.md` and/or `AGENTS.md` with orchestrator information:

1. List which orchestrators are supported and their detection env vars.
2. Document the workspace database naming convention and whether the project uses git-worktree-folder or `WORKSPACE_NAME` env/file derivation.
3. Document dev server startup and port discovery for each orchestrator.
4. Document any orchestrator-specific quirks (e.g., Orca needs manual dev server start).

If neither `CLAUDE.md` nor `AGENTS.md` exists, create a section in `CLAUDE.md`.

## Phase 8 — Verification

Run checks after making changes:

```sh
# Verify shell scripts parse (for each created/modified script)
sh -n bin/orchestrator/env
sh -n bin/orchestrator/setup
sh -n bin/orchestrator/teardown
sh -n bin/orchestrator/dev-port
sh -n bin/orchestrator/port

# Verify database.yml parses (needs Rails env)
ruby -e "require 'erb'; ERB.new(File.read('config/database.yml')).result"

# Verify JSON config files parse
ruby -e "require 'json'; JSON.parse(File.read('<config-file>'))"

# Verify YAML config files parse
ruby -e "require 'yaml'; YAML.load_file('<config-file>')"

# Verify TOML config files parse
python3 -c "import pathlib, tomllib; tomllib.loads(pathlib.Path('<config-file>').read_text())"
```

## Checklist

Run through every item before reporting done:

- [ ] (Phases 0–1) Project type detected, lifecycle commands resolved, and orchestrator reference files read for all selected orchestrators
- [ ] (Phase 3) Project config files created or updated for each selected orchestrator, per its reference file
- [ ] (Phase 4) `.gitignore` updated for generated workspace files
- [ ] (Phase 5) Detection and lifecycle scripts created or confirmed existing (if user opted in)
  - [ ] `bin/orchestrator/env` — detection vars, workspace name resolution, port allocation policy
  - [ ] `bin/orchestrator/setup` — dependency install, database creation, port allocation
  - [ ] `bin/orchestrator/teardown` — database drop, port release
- [ ] (Phase 6) Ports, database, and dev server configured
  - [ ] `bin/orchestrator/dev-port` — port resolution chain for all configured orchestrators
  - [ ] `bin/orchestrator/port` — port block allocation (if any orchestrator requires it)
  - [ ] `config/database.yml` made workspace-aware OR confirmed an existing per-worktree scheme and left it intact
  - [ ] `bin/orchestrator/setup`, `bin/orchestrator/teardown`, and `bin/orchestrator/psql` match the chosen database isolation scheme
  - [ ] `bin/dev` — port resolution, env var export, process manager startup
  - [ ] `Procfile.dev` — services read ports from env vars
  - [ ] `bin/orchestrator/psql` — optional database helper
- [ ] All `MYAPP`/`myapp` placeholders replaced with actual project name
- [ ] (Phase 7) `CLAUDE.md` / `AGENTS.md` updated with orchestrator documentation
- [ ] (Phase 8) Shell scripts pass `sh -n` syntax check; config files parse as valid JSON/YAML
- [ ] Custom dev command handled per each orchestrator's reference file

## Adding support for a new orchestrator

All orchestrator-specific detail lives in `references/orchestrators/<name>.md`, so extending the skill is mostly authoring one reference file. This is the same flow as Phase 1b — the only difference is that here you do it ahead of time rather than in response to a user request.

1. Create `references/orchestrators/<name>.md` following the format of existing reference files. Document:
   - Environment variables (detection var, workspace name var, port var, home dir var)
   - Config file path and schema
   - Port strategy
   - Lifecycle hook names
   - Custom dev command (how the dev server is started)
   - Labels file format (if any)
   - Any quirks or special behavior
2. Add the orchestrator to the summary table at the top of this file.
3. Add the orchestrator's detection var(s) to `bin/orchestrator/env` (`workspace_detection_present`, `workspace_env_name`, `workspace_path`, and `workspace_needs_port_allocation` if it needs project-managed ports) and to the resolution chain in `bin/orchestrator/dev-port`.

Phase 3 needs no per-orchestrator edit — it reads each orchestrator's config schema straight from the reference file.
