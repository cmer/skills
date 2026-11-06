#!/usr/bin/env sh
# Managed by the orchestrator-setup skill (layout 2). Do not edit: the skill
# replaces this file wholesale. Reference: references/orchestrators/superconductor.md
#
# super.engineering (formerly Superconductor) adapter. Assigns no ports: the project allocates a 10-port block and
# writes the .superset/ports.json labels file.

orchestrator_superconductor_detected() {
  [ -n "${SUPERCONDUCTOR_WORKTREE_PATH:-}" ]
}
orchestrator_superconductor_path() {
  [ -n "${SUPERCONDUCTOR_WORKTREE_PATH:-}" ] && printf '%s\n' "$SUPERCONDUCTOR_WORKTREE_PATH"
}
orchestrator_superconductor_name() {
  [ -n "${SUPERCONDUCTOR_WORKSPACE_NAME:-}" ] && printf '%s\n' "$SUPERCONDUCTOR_WORKSPACE_NAME"
}
orchestrator_superconductor_port() { return 1; }
orchestrator_superconductor_main_checkout() { return 1; }
orchestrator_superconductor_in_main_checkout() { return 1; }
orchestrator_superconductor_traits() { echo allocate-ports port-labels; }
