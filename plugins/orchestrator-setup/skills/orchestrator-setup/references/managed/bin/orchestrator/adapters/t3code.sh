#!/usr/bin/env sh
# Managed by the orchestrator-setup skill (layout 2). Do not edit: the skill
# replaces this file wholesale. Reference: references/orchestrators/t3code.md
#
# T3 Code adapter. Actions and worktree terminals get T3CODE_WORKTREE_PATH, every
# T3 terminal gets T3CODE_PROJECT_ROOT (the main checkout, also set there),
# and agent shells get only T3CODE_THREAD_ID. Assigns no ports and shows no
# labels file (it discovers listeners itself). Ignores .worktreeinclude.

orchestrator_t3code_detected() {
  [ -n "${T3CODE_WORKTREE_PATH:-}" ] ||
    [ -n "${T3CODE_PROJECT_ROOT:-}" ] ||
    [ -n "${T3CODE_THREAD_ID:-}" ]
}
# Agent shells have no path var, so fall back to the git top-level. Both forms
# go through `pwd -P` so a symlinked worktree location yields one allocation.
orchestrator_t3code_path() {
  orchestrator_t3code_detected || return 1
  path="${T3CODE_WORKTREE_PATH:-$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")}"
  (cd "$path" 2>/dev/null && pwd -P) || printf '%s\n' "$path"
}
# T3 Code names no workspace; its worktree folder (t3-xxxxxxxx) is the name.
orchestrator_t3code_name() {
  [ -n "${T3CODE_WORKTREE_PATH:-}" ] && basename "$T3CODE_WORKTREE_PATH"
}
orchestrator_t3code_port() { return 1; }
orchestrator_t3code_main_checkout() {
  [ -n "${T3CODE_PROJECT_ROOT:-}" ] && printf '%s\n' "$T3CODE_PROJECT_ROOT"
}
# Terminal and agent vars are also set in the main checkout. A worktree has a
# .git file; the main checkout has a .git directory.
orchestrator_t3code_in_main_checkout() {
  [ -z "${T3CODE_WORKTREE_PATH:-}" ] && [ -d .git ]
}
orchestrator_t3code_traits() { echo allocate-ports worktree-include; }
