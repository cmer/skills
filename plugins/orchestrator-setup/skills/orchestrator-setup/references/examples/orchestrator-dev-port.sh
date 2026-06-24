#!/usr/bin/env sh
# Outputs the dev server port for this workspace.
#
# The resolution chain tries orchestrator-provided ports first, then falls
# back to allocation or discovery. The priority order matters — do not
# rearrange without understanding each orchestrator's port strategy.
#
# Resolution chain:
#   1. $CONDUCTOR_PORT         — Conductor provides first port in workspace range
#   2. $PASEO_WORKTREE_PORT    — Paseo provides this on all worktree processes
#   3. $PASEO_PORT             — Paseo provides this on service processes only
#   4. workspace port allocation — for Superset/Superconductor/Orca (10-port block)
#   5. puma process discovery   — fallback when no port env var is available
#   6. $PORT                   — generic env var
#   7. 3000                    — default
#
# To adapt for your project:
#   1. Remove orchestrator checks you don't support.
#   2. Adjust the puma discovery awk pattern if your server uses a different
#      process title format.
#   3. Change the default port (3000) if needed.

DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/env"

discover_puma_port() {
  ws="$(basename "$PWD")"
  ps -Ao args= 2>/dev/null | awk -v ws="$ws" '
    /^puma/ && $0 ~ "\\["ws"\\]" {
      if (match($0, /tcp:[^:]*:[0-9]+/)) {
        p = substr($0, RSTART, RLENGTH)
        sub(/.*:/, "", p)
        print p
        exit
      }
    }'
}

if [ -n "${CONDUCTOR_PORT:-}" ]; then
  echo "$CONDUCTOR_PORT"
elif [ -n "${PASEO_WORKTREE_PORT:-}" ]; then
  echo "$PASEO_WORKTREE_PORT"
elif [ -n "${PASEO_PORT:-}" ]; then
  echo "$PASEO_PORT"
elif workspace_needs_port_allocation; then
  allocated="$(bin/orchestrator/port get 2>/dev/null || true)"
  if [ -n "$allocated" ]; then
    echo "$allocated"
  else
    discovered="$(discover_puma_port)"
    if [ -n "$discovered" ]; then
      bin/orchestrator/port reserve "$discovered"
    else
      bin/orchestrator/port allocate
    fi
  fi
elif [ -n "${CONDUCTOR_WORKSPACE_PATH:-}" ] || [ -n "${CONDUCTOR_ROOT_PATH:-}" ]; then
  discovered="$(discover_puma_port)"
  if [ -n "$discovered" ]; then
    echo "$discovered"
  else
    echo "${PORT:-3000}"
  fi
elif [ -n "${PORT:-}" ]; then
  echo "$PORT"
else
  echo "3000"
fi
