#!/usr/bin/env sh
# Source this file from shell scripts that need workspace isolation details.
#
# This is the single source of truth for workspace detection. All
# workspace-aware scripts under bin/orchestrator/ source this file.
# Do not duplicate orchestrator detection logic elsewhere.
#
# To adapt for your project:
#   1. Replace MYAPP with your project name (env var prefix and db prefix).
#   2. Add or remove orchestrator detection vars to match your configuration.
#   3. Update workspace_database_prefix to use your project's db naming.

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
# Priority: project override > orchestrator-provided names
# Add/remove orchestrator vars as needed.

workspace_env_name() {
  name="${MYAPP_WORKSPACE_NAME:-${CONDUCTOR_WORKSPACE_NAME:-${SUPERCONDUCTOR_WORKSPACE_NAME:-${SUPERSET_WORKSPACE_NAME:-${ORCA_WORKSPACE_NAME:-}}}}}"
  [ -n "$name" ] || return 1
  printf '%s\n' "$name"
}

# --- Orchestrator detection ---
# Returns true if any configured orchestrator is active.
# Each orchestrator has a "detection var" that is always set in its environment.

workspace_detection_present() {
  [ -n "${CONDUCTOR_BIN_DIR:-}" ] ||
    [ -n "${PASEO_WORKTREE_PATH:-}" ] ||
    [ -n "${SUPERSET_WORKSPACE_PATH:-}" ] ||
    [ -n "${SUPERCONDUCTOR_WORKTREE_PATH:-}" ] ||
    [ -n "${ORCA_WORKTREE_ID:-}" ] ||
    [ -n "${ORCA_WORKTREE_PATH:-}" ]
}

# --- Workspace name resolution ---
# Tries (in order): persisted file, env var, detection + basename fallback.

workspace_name() {
  read_persisted_workspace_name ||
    workspace_env_name ||
    { workspace_detection_present && basename "$PWD"; }
}

workspace_managed() {
  workspace_name >/dev/null 2>&1
}

# --- Port allocation ---
# Returns true if the active orchestrator does NOT provide a port,
# meaning the project must allocate its own port block.
# Conductor and Paseo provide ports; Superset, Superconductor, and Orca do not.

workspace_needs_port_allocation() {
  [ -n "${SUPERSET_WORKSPACE_PATH:-}" ] ||
    [ -n "${SUPERCONDUCTOR_WORKTREE_PATH:-}" ] ||
    [ -n "${ORCA_WORKTREE_ID:-}" ] ||
    [ -n "${ORCA_WORKTREE_PATH:-}" ]
}

# --- Workspace path ---
# Prefers orchestrator-provided path, falls back to $PWD.

workspace_path() {
  printf '%s\n' "${SUPERSET_WORKSPACE_PATH:-${SUPERCONDUCTOR_WORKTREE_PATH:-${PASEO_WORKTREE_PATH:-${ORCA_WORKTREE_PATH:-$PWD}}}}"
}

# --- Database naming ---
# Constructs workspace-isolated database names.
# Pattern: <project>_<workspace>_<environment>
# Without workspace: <project>_<environment>

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
  name="$(workspace_name 2>/dev/null || true)"
  [ -n "$name" ] || return 1

  file="$(workspace_name_file)"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$name" > "$file"
  printf '%s\n' "$name"
}
