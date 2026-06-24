#!/usr/bin/env sh
#/ Usage: bin/orchestrator/teardown
#/
#/ Tear down workspace-specific resources before a worktree is removed.
#/ Called by orchestrators during their teardown/archive lifecycle hook.
#/
#/ To adapt for your project:
#/   1. Replace MYAPP_WORKSPACE_NAME with your project's env var.
#/   2. Adjust database drop commands for your setup.
#/   3. Add any project-specific cleanup (temp files, caches, etc.).

set -e
cd "$(dirname "$0")/../.."
. bin/orchestrator/env

workspace_name="$(workspace_name 2>/dev/null || true)"

drop_database() {
  environment="$1"

  if ! RAILS_ENV="$environment" bin/rails db:drop; then
    echo "Warning: failed to drop $environment database; continuing." >&2
  fi
}

if [ -z "$workspace_name" ] && workspace_detection_present; then
  echo "ERROR: running inside an orchestrator but could not resolve the workspace name." >&2
  echo "Refusing to tear down: workspace databases would be left orphaned." >&2
  exit 1
fi

if [ -z "$workspace_name" ]; then
  echo "Workspace name not set; skipping database teardown."
else
  export MYAPP_WORKSPACE_NAME="$workspace_name"
  echo "Dropping databases for workspace: $workspace_name"

  drop_database development
  drop_database test
  echo "Database teardown complete."
fi

if workspace_needs_port_allocation; then
  echo "Releasing workspace ports..."
  if ! bin/orchestrator/port release; then
    echo "Warning: failed to release workspace ports; continuing." >&2
  fi
fi
