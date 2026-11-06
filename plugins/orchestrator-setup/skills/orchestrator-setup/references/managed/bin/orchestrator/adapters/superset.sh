#!/usr/bin/env sh
# Managed by the orchestrator-setup skill (layout 2). Do not edit: the skill
# replaces this file wholesale. Reference: references/orchestrators/superset.md
#
# Superset adapter. Assigns no ports: the project allocates a 10-port block and
# writes the .superset/ports.json labels file.

orchestrator_superset_detected() {
  [ -n "${SUPERSET_WORKSPACE_PATH:-}" ]
}
orchestrator_superset_path() {
  [ -n "${SUPERSET_WORKSPACE_PATH:-}" ] && printf '%s\n' "$SUPERSET_WORKSPACE_PATH"
}
orchestrator_superset_name() {
  [ -n "${SUPERSET_WORKSPACE_NAME:-}" ] && printf '%s\n' "$SUPERSET_WORKSPACE_NAME"
}
orchestrator_superset_port() { return 1; }
orchestrator_superset_main_checkout() { return 1; }
orchestrator_superset_in_main_checkout() { return 1; }
orchestrator_superset_traits() { echo allocate-ports port-labels; }
