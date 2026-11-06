#!/usr/bin/env sh
# Managed by the orchestrator-setup skill (layout 2). Do not edit: the skill
# replaces this file wholesale. Reference: references/orchestrators/paseo.md
#
# Paseo adapter. Paseo provides PASEO_WORKTREE_PORT on every worktree process and
# PASEO_PORT on service processes. It names no workspace.

orchestrator_paseo_detected() {
  [ -n "${PASEO_WORKTREE_PATH:-}" ]
}
orchestrator_paseo_path() {
  [ -n "${PASEO_WORKTREE_PATH:-}" ] && printf '%s\n' "$PASEO_WORKTREE_PATH"
}
orchestrator_paseo_name() { return 1; }
orchestrator_paseo_port() {
  if [ -n "${PASEO_WORKTREE_PORT:-}" ]; then
    printf '%s\n' "$PASEO_WORKTREE_PORT"
  elif [ -n "${PASEO_PORT:-}" ]; then
    printf '%s\n' "$PASEO_PORT"
  else
    return 1
  fi
}
orchestrator_paseo_main_checkout() { return 1; }
orchestrator_paseo_in_main_checkout() { return 1; }
orchestrator_paseo_traits() { :; }
