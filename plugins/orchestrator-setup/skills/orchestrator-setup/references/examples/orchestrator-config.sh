#!/usr/bin/env sh
# Project settings for bin/orchestrator. Sourced by bin/orchestrator/env.
#
# This file is the project's, not the skill's: every project-specific value the
# managed scripts need lives here, so the managed files can be replaced
# wholesale when orchestrators are added or the skill is upgraded.
#
# To adapt for your project:
#   1. Replace myapp / MYAPP with your project name.
#   2. Pick the database scheme that matches config/database.yml.
#   3. List the orchestrators this project supports, in this canonical order
#      (it is the precedence order if two tools' variables are ever set at
#      once): conductor paseo superset superconductor orca t3code
#   4. Name the services at port offsets 0, 1, 2… of a 10-port block.

# Project name: the port-allocation directory and the env-file database prefix.
ORCHESTRATOR_PROJECT=myapp

# The env var config/database.yml reads for the workspace name (env-file
# scheme). Its file override is the same name with _FILE appended.
ORCHESTRATOR_WORKSPACE_ENV=MYAPP_WORKSPACE_NAME

# How config/database.yml isolates worktrees:
#   env-file         reads ORCHESTRATOR_WORKSPACE_ENV, then tmp/WORKSPACE_NAME
#   worktree-folder  derives names from the worktree folder or .git pointer
#   none             no per-worktree database (static sites, non-Rails apps);
#                    ORCHESTRATOR_WORKSPACE_ENV may then be left out
ORCHESTRATOR_DATABASE_SCHEME=env-file

# Enabled orchestrators; each has bin/orchestrator/adapters/<id>.sh.
ORCHESTRATOR_ADAPTERS="conductor paseo superset superconductor orca t3code"

# Port used outside any orchestrator.
ORCHESTRATOR_DEFAULT_PORT=3000

# Services at offsets 0, 1, 2… (comma-separated, no quotes), for the
# .superset/ports.json labels file.
ORCHESTRATOR_PORT_LABELS="Rails,Vite"
