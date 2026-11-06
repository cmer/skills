#!/usr/bin/env sh
# Managed by the orchestrator-setup skill (layout 2). Do not edit: the skill
# replaces this file wholesale. Reference: references/orchestrators/orca.md
#
# Orca adapter. Terminals get ORCA_WORKTREE_ID (main checkout included); hooks get
# ORCA_WORKTREE_PATH and ORCA_WORKSPACE_NAME. Assigns no ports: the project
# allocates a 10-port block and writes the .superset/ports.json labels file.

orchestrator_orca_detected() {
  [ -n "${ORCA_WORKTREE_ID:-}" ] || [ -n "${ORCA_WORKTREE_PATH:-}" ]
}
orchestrator_orca_path() {
  [ -n "${ORCA_WORKTREE_PATH:-}" ] && printf '%s\n' "$ORCA_WORKTREE_PATH"
}
orchestrator_orca_name() {
  [ -n "${ORCA_WORKSPACE_NAME:-}" ] && printf '%s\n' "$ORCA_WORKSPACE_NAME"
}
orchestrator_orca_port() { return 1; }
orchestrator_orca_main_checkout() { return 1; }
orchestrator_orca_in_main_checkout() { return 1; }
orchestrator_orca_traits() { echo allocate-ports port-labels; }
