#!/usr/bin/env sh
# Managed by the orchestrator-setup skill (layout 2). Do not edit: the skill
# replaces this file wholesale. Reference: references/orchestrators/conductor.md
#
# Conductor adapter. Conductor provides a 10-port range (CONDUCTOR_PORT) and names
# its workspaces. Without a port (some terminals), find a running puma.

orchestrator_conductor_detected() {
  [ -n "${CONDUCTOR_WORKSPACE_PATH:-}" ] || [ -n "${CONDUCTOR_ROOT_PATH:-}" ]
}
orchestrator_conductor_path() {
  [ -n "${CONDUCTOR_WORKSPACE_PATH:-}" ] && printf '%s\n' "$CONDUCTOR_WORKSPACE_PATH"
}
orchestrator_conductor_name() {
  [ -n "${CONDUCTOR_WORKSPACE_NAME:-}" ] && printf '%s\n' "$CONDUCTOR_WORKSPACE_NAME"
}
orchestrator_conductor_port() {
  [ -n "${CONDUCTOR_PORT:-}" ] && printf '%s\n' "$CONDUCTOR_PORT"
}
orchestrator_conductor_main_checkout() { return 1; }
orchestrator_conductor_in_main_checkout() { return 1; }
orchestrator_conductor_traits() { echo discover-port; }
