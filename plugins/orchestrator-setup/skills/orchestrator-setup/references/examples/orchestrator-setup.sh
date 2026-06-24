#!/usr/bin/env sh
#/ Usage: bin/orchestrator/setup
#/
#/ Set up a workspace after its worktree is created.
#/ Called by orchestrators during their setup lifecycle hook.
#/
#/ To adapt for your project:
#/   1. Replace MYAPP_WORKSPACE_NAME with your project's env var.
#/   2. Adjust dependency install commands for your project.
#/   3. Adjust database setup commands for your ORM/migration tool.
#/   4. Add any project-specific setup steps (seed data, asset compilation, etc.).

set -e
cd "$(dirname "$0")/../.."
. bin/orchestrator/env

workspace_name="$(persist_workspace_name 2>/dev/null || true)"

if [ -z "$workspace_name" ] && workspace_detection_present; then
  echo "ERROR: running inside an orchestrator but could not resolve the workspace name." >&2
  echo "Refusing to set up the shared database from a managed worktree." >&2
  exit 1
fi

if [ -n "$workspace_name" ]; then
  export MYAPP_WORKSPACE_NAME="$workspace_name"
fi

if workspace_needs_port_allocation; then
  echo "Reserving workspace ports..."
  bin/orchestrator/port allocate >/dev/null
fi

echo "Installing dependencies..."
bundle install

echo "Setting up databases (${workspace_name:-shared})..."
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare

echo "Workspace setup complete!"
