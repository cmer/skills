#!/usr/bin/env sh
# Source this file from shell scripts that need workspace isolation details.
#
# This is the single source of truth for workspace detection. All
# workspace-aware scripts under bin/orchestrator/ source this file.
# Do not duplicate orchestrator detection logic elsewhere.
#
# `workspace_name` reads exactly what config/database.yml reads, in the same
# order — MYAPP_WORKSPACE_NAME, then tmp/WORKSPACE_NAME — so a shell script and
# Rails can never resolve different databases. The sources Rails can't see (the
# orchestrator's own name var, the directory name) belong to
# `workspace_setup_name`, and reach Rails only by being persisted to the file.
#
# To adapt for your project:
#   1. Replace MYAPP with your project name (env var prefix and db prefix).
#   2. Add or remove orchestrator detection vars to match your configuration.
#   3. If config/database.yml already derives names from the git worktree
#      folder or .git pointer file, omit the database-name helpers below or
#      replace them with an authoritative Rails/database.yml lookup.
#   4. For the env/file database.yml scheme, update workspace_database_prefix
#      to use your project's db naming.
#   5. Keep `workspace_name` reading only what config/database.yml reads. New
#      orchestrator name vars go in `workspace_orchestrator_name`.

# --- Workspace name file ---

workspace_name_file() {
  printf '%s\n' "${MYAPP_WORKSPACE_NAME_FILE:-tmp/WORKSPACE_NAME}"
}

read_persisted_workspace_name() {
  file="$(workspace_name_file)"
  [ -f "$file" ] || return 1

  name="$(sed -n '1p' "$file")"
  [ -n "$name" ] || return 1
  printf '%s\n' "$name"
}

# --- Workspace name from environment ---
# The project's own var, and only it: config/database.yml reads this same var,
# and the two must not drift.

workspace_env_name() {
  [ -n "${MYAPP_WORKSPACE_NAME:-}" ] || return 1
  printf '%s\n' "$MYAPP_WORKSPACE_NAME"
}

# --- Workspace name from the orchestrator ---
# The name the tool gives its own workspace. Add/remove orchestrator vars as
# needed. Setup-time input only — Rails never sees these.

workspace_orchestrator_name() {
  name="${CONDUCTOR_WORKSPACE_NAME:-${SUPERCONDUCTOR_WORKSPACE_NAME:-${SUPERSET_WORKSPACE_NAME:-${ORCA_WORKSPACE_NAME:-}}}}"
  [ -n "$name" ] || return 1
  printf '%s\n' "$name"
}

# --- Orchestrator detection ---
# Returns true if any configured orchestrator is active.
# Each orchestrator has a "detection var" that is always set in its environment.

workspace_detection_present() {
  [ -n "${CONDUCTOR_WORKSPACE_PATH:-}" ] ||
    [ -n "${CONDUCTOR_ROOT_PATH:-}" ] ||
    [ -n "${PASEO_WORKTREE_PATH:-}" ] ||
    [ -n "${SUPERSET_WORKSPACE_PATH:-}" ] ||
    [ -n "${SUPERCONDUCTOR_WORKTREE_PATH:-}" ] ||
    [ -n "${ORCA_WORKTREE_ID:-}" ] ||
    [ -n "${ORCA_WORKTREE_PATH:-}" ]
}

# --- Workspace name resolution ---
# What every reader uses: the project env var, then the persisted file. Same
# two sources, same order, as config/database.yml.

workspace_name() {
  workspace_env_name || read_persisted_workspace_name
}

# --- Workspace name for setup ---
# What bin/orchestrator/setup and bin/orchestrator/teardown use, and nothing
# else. Adds the orchestrator's name for the workspace, then the directory name
# for tools that name no workspace at all. Both outrank the persisted file: at
# setup time the orchestrator's vars are the fresh truth, and the file may be a
# leftover from an earlier or aborted workspace.
#
# Keep this fallback chain out of `workspace_name`. A checkout the orchestrator
# merely detects — the main repo opened in the tool, say — is not a workspace
# until setup names it, and until then it belongs on the shared database, which
# is what config/database.yml will resolve for it either way.

workspace_setup_name() {
  workspace_env_name ||
    workspace_orchestrator_name ||
    read_persisted_workspace_name ||
    { workspace_detection_present && basename "$PWD"; }
}

workspace_managed() {
  workspace_name >/dev/null 2>&1
}

# --- Port allocation ---
# Returns true if the active orchestrator does NOT provide a port,
# meaning the project must allocate its own port block.
# Conductor and Paseo provide ports; Superset, super.engineering, and Orca do not.

workspace_needs_port_allocation() {
  [ -n "${SUPERSET_WORKSPACE_PATH:-}" ] ||
    [ -n "${SUPERCONDUCTOR_WORKTREE_PATH:-}" ] ||
    [ -n "${ORCA_WORKTREE_ID:-}" ] ||
    [ -n "${ORCA_WORKTREE_PATH:-}" ]
}

# --- Workspace path ---
# Prefers orchestrator-provided path, falls back to $PWD.

workspace_path() {
  printf '%s\n' "${CONDUCTOR_WORKSPACE_PATH:-${SUPERSET_WORKSPACE_PATH:-${SUPERCONDUCTOR_WORKTREE_PATH:-${PASEO_WORKTREE_PATH:-${ORCA_WORKTREE_PATH:-$PWD}}}}}"
}

# --- Database naming ---
# Constructs workspace-isolated database names.
# Pattern: <project>_<workspace>_<environment>
# Without workspace: <project>_<environment>
#
# Keep these helpers only when config/database.yml uses the matching env/file
# naming scheme. Some Rails templates derive names from the git worktree folder
# and may use a different order, such as <project>_<environment>_<worktree>.
# In that case, do not reimplement the name in shell; ask Rails/database.yml for
# the final value in any script that needs it.

workspace_database_prefix() {
  if name="$(workspace_name 2>/dev/null)"; then
    printf 'myapp_%s\n' "$name"
  else
    printf 'myapp\n'
  fi
}

workspace_database_name() {
  environment="${1:?Usage: workspace_database_name ENVIRONMENT}"
  printf '%s_%s\n' "$(workspace_database_prefix)" "$environment"
}

# --- Persistence ---
# Writes workspace name to tmp/WORKSPACE_NAME so it survives across shell
# sessions where orchestrator env vars may not be present.
#
# Always (re)writes the freshly resolved name. The file is a cache, not a
# source of truth: during the setup hook the orchestrator env vars are fresh,
# so an existing file left over from a previous/aborted workspace must be
# overwritten rather than trusted (otherwise databases get created under a
# stale workspace name).

persist_workspace_name() {
  name="$(workspace_setup_name 2>/dev/null || true)"
  [ -n "$name" ] || return 1

  file="$(workspace_name_file)"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$name" > "$file"
  printf '%s\n' "$name"
}
