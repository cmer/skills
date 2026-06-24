#!/usr/bin/env sh
# Connects to this workspace's Postgres database with psql.
#
# Resolves the database name the same way config/database.yml does. Managed
# worktrees use myapp_<workspace>_development; other environments use the
# shared myapp_development database.
#
# Usage:
#   bin/orchestrator/psql                                       # interactive shell
#   bin/orchestrator/psql -c "SELECT count(*) FROM users"       # one-shot query
#   bin/orchestrator/psql --csv -c "…" > out.csv                # CSV export
#
# To adapt for your project:
#   1. Replace myapp with your project name (matches workspace_database_name).
#   2. Adjust PG_USER/PG_HOST/PG_PASSWORD defaults for your setup.

DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/env"

db="$(workspace_database_name development)"

PGUSER="${PG_USER:-postgres}" \
PGHOST="${PG_HOST:-localhost}" \
PGPASSWORD="${PG_PASSWORD:-password}" \
  exec psql -d "$db" "$@"
