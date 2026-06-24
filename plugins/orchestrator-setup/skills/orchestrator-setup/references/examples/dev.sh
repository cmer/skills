#!/usr/bin/env sh
# Start the dev server with workspace-aware port assignment.
#
# Resolves the base port via bin/orchestrator/dev-port, then derives additional ports
# for frontend bundlers and other services by offsetting from the base.
#
# Port layout (10-port block):
#   PORT        = base        (Rails / main server)
#   VITE_PORT   = base + 1    (Vite dev server, if applicable)
#   extra ports = base + 2..9 (webhooks, sidekiq web, etc.)
#
# To adapt for your project:
#   1. Adjust derived ports for your services (remove VITE_PORT if no Vite,
#      add SIDEKIQ_PORT, etc.)
#   2. Change the Procfile name/path if different.
#   3. Replace bundle with your dependency manager if not using Bundler.

PORT=$(bin/orchestrator/dev-port)
export PORT

VITE_PORT=$((PORT + 1))
export VITE_PORT

if [ -f Procfile.dev.local ]; then
  PROCFILE=Procfile.dev.local
else
  PROCFILE=Procfile.dev
fi

echo "Installing dependencies..."
bundle check || bundle install

echo ""
echo "Loading $PROCFILE on port $PORT..."
echo ""
if command -v overmind > /dev/null 2>&1; then
  if [ -S ./.overmind.sock ]; then
    if ! overmind status > /dev/null 2>&1; then
      rm -f ./.overmind.sock
    fi
  fi
  exec overmind start -f "$PROCFILE" "$@"
else
  exec foreman start -f "$PROCFILE" "$@"
fi
