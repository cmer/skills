#!/usr/bin/env sh
#/ Usage: bin/orchestrator/setup
#/
#/ Set up a workspace after its worktree is created.
#/ Called by orchestrators during their setup lifecycle hook. Must be idempotent.
#/
#/ This file is the project's: add project-specific steps freely. The
#/ orchestrator-specific work (.worktreeinclude copy, workspace name, port
#/ block) is one call into the managed bin/orchestrator/env, so adding an
#/ orchestrator never requires editing this file.
#/
#/ To adapt for your project:
#/   1. Adjust dependency install commands for your project.
#/   2. Adjust database setup commands for your ORM/migration tool.
#/   3. Add any project-specific setup steps (seed data, asset compilation, etc.).

set -e
cd "$(dirname "$0")/../.."
. bin/orchestrator/env

# Copies .worktreeinclude files, exports the workspace name (env-file scheme),
# and reserves the port block — whatever the active orchestrator needs.
workspace_prepare_setup

echo "Installing dependencies..."
bundle install

echo "Setting up databases (${workspace_name:-shared})..."
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare

echo "Workspace setup complete!"
