#!/usr/bin/env sh
# Connects to this workspace's Postgres database with psql.
#
# Resolves the database name by evaluating config/database.yml, so this helper
# stays correct whether the project uses the env/file scheme or derives database
# names from the git worktree folder / .git pointer file.
#
# Usage:
#   bin/orchestrator/psql                                       # interactive shell
#   bin/orchestrator/psql -c "SELECT count(*) FROM users"       # one-shot query
#   bin/orchestrator/psql --csv -c "…" > out.csv                # CSV export
#
# To adapt for your project:
#   1. Adjust PG_USER/PG_HOST/PG_PASSWORD defaults for your setup.
#   2. If your database.yml needs Rails constants, replace the Ruby one-liner
#      with `bin/rails runner` or another project-authoritative lookup.

cd "$(dirname "$0")/../.."

db="$(
  ruby -ryaml -rerb -e 'print YAML.safe_load(ERB.new(File.read("config/database.yml")).result, aliases: true).fetch("development").fetch("database")'
)"

PGUSER="${PG_USER:-postgres}" \
PGHOST="${PG_HOST:-localhost}" \
PGPASSWORD="${PG_PASSWORD:-password}" \
  exec psql -d "$db" "$@"
