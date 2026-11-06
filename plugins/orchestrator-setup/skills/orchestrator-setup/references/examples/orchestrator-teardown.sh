#!/usr/bin/env sh
#/ Usage: bin/orchestrator/teardown
#/
#/ Tear down workspace-specific resources before a worktree is removed.
#/ Called by orchestrators during their teardown/archive lifecycle hook.
#/
#/ This file is the project's: add project-specific cleanup freely. The
#/ guards (never drop the main checkout's databases, never orphan a
#/ workspace's) and the port release live in the managed bin/orchestrator/env.
#/
#/ To adapt for your project:
#/   1. Adjust database drop commands for your setup.
#/   2. Add any project-specific cleanup (temp files, caches, etc.).

set -e
cd "$(dirname "$0")/../.."
. bin/orchestrator/env

drop_database() {
  environment="$1"

  if ! RAILS_ENV="$environment" bin/rails db:drop; then
    echo "Warning: failed to drop $environment database; continuing." >&2
  fi
}

# Returns 1 when there is nothing to drop; exits when dropping is unsafe.
if workspace_begin_teardown; then
  drop_database development
  drop_database test
  echo "Database teardown complete."
fi

workspace_finish_teardown
