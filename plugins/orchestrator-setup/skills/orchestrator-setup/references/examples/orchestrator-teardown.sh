#!/usr/bin/env sh
#/ Usage: bin/orchestrator/teardown
#/
#/ Tear down workspace-specific resources before a worktree is removed.
#/ Called by orchestrators during their teardown/archive lifecycle hook.
#/
#/ To adapt for your project:
#/   1. If config/database.yml already derives names from the git worktree
#/      folder or .git pointer file, remove the MYAPP_WORKSPACE_NAME export and
#/      unresolved-workspace guard below, and keep the main-checkout guard.
#/   2. For the env/file database.yml scheme, replace MYAPP_WORKSPACE_NAME with
#/      your project's env var.
#/   3. Adjust database drop commands for your setup.
#/   4. Add any project-specific cleanup (temp files, caches, etc.).

set -e
cd "$(dirname "$0")/../.."
. bin/orchestrator/env

workspace_name="$(workspace_name 2>/dev/null || true)"

refuse_main_checkout_for_folder_based_database_yml() {
  if [ -d .git ]; then
    echo "ERROR: .git is a directory, so this appears to be the main checkout." >&2
    echo "Refusing to drop the primary development/test databases." >&2
    exit 1
  fi
}

drop_database() {
  environment="$1"

  if ! RAILS_ENV="$environment" bin/rails db:drop; then
    echo "Warning: failed to drop $environment database; continuing." >&2
  fi
}

# Env/file database.yml scheme only. Remove this guard when database.yml
# self-isolates from the git worktree folder or .git pointer file.
if [ -z "$workspace_name" ] && workspace_detection_present; then
  echo "ERROR: running inside an orchestrator but could not resolve the workspace name." >&2
  echo "Refusing to tear down: workspace databases would be left orphaned." >&2
  exit 1
fi

# Folder-derived database.yml scheme only. Uncomment this guard when
# database.yml self-isolates from the git worktree folder or .git pointer file,
# then drop the workspace databases directly because Rails derives their names
# from this checkout:
#
# refuse_main_checkout_for_folder_based_database_yml
#
# echo "Dropping databases for this git worktree..."
# drop_database development
# drop_database test
# echo "Database teardown complete."
# exit 0

if [ -z "$workspace_name" ]; then
  echo "Workspace name not set; skipping database teardown."
else
  # Env/file database.yml scheme only. Remove this export when database.yml
  # self-isolates from the git worktree folder or .git pointer file.
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
