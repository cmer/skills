#!/usr/bin/env sh
#/ Usage: bin/orchestrator/port [get|allocate|reserve PORT|release]
#/
#/ Manage 10-port block allocation for workspace isolation.
#/ Required when orchestrators don't provide ports (Superset, Superconductor, Orca).
#/
#/ Subcommands:
#/   get       — Print allocated port if one exists, or exit 1.
#/   allocate  — Allocate a new 10-port block (or return existing). Default.
#/   reserve PORT — Reserve a specific port block (e.g., discovered from a running process).
#/   release   — Release the port block and delete the labels file.
#/
#/ Port blocks are stored in $SUPERSET_HOME_DIR/port-allocations/<project>/
#/ (defaults to ~/.superset/port-allocations/<project>/). Each workspace gets
#/ a file keyed by a checksum of the workspace path.
#/
#/ Note: the ~/.superset/port-allocations path and the .superset/ports.json
#/ labels file are a deliberately SHARED allocation convention reused by
#/ Superset, Superconductor, and Orca — not a dependency on Superset itself.
#/ A project supporting any of those uses this one allocation store.
#/
#/ To adapt for your project:
#/   1. Replace "myapp" in the allocations_dir path with your project name.
#/   2. Update write_labels to list your project's services and port offsets.
#/   3. Adjust the port range (10000–59990) if needed.

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/env"

action="${1:-allocate}"
port_home="${SUPERSET_HOME_DIR:-${HOME}/.superset}"
allocations_dir="$port_home/port-allocations/myapp"
lock_dir="$allocations_dir/.lock"
workspace_path="$(workspace_path)"
workspace_id="$(printf '%s' "$workspace_path" | cksum | awk '{print $1}')"
allocation_file="$allocations_dir/$workspace_id"

mkdir -p "$allocations_dir"

# --- File-based locking for concurrent allocation safety ---

lock() {
  attempts=0
  until mkdir "$lock_dir" 2>/dev/null; do
    lock_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -rf "$lock_dir"
      continue
    fi
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 100 ]; then
      echo "Timed out waiting for workspace port allocation lock." >&2
      exit 1
    fi
    sleep 0.1
  done
  echo "$$" > "$lock_dir/pid"
  trap 'rm -rf "$lock_dir"' EXIT
  trap 'exit 130' INT TERM
}

# --- Labels file ---
# Written to .superset/ports.json so orchestrator UIs can display service names.
# Update the labels to match your project's services.

write_labels() {
  port="$1"
  mkdir -p .superset
  cat > .superset/ports.json <<EOF
{
  "ports": [
    { "port": $port, "label": "Rails" },
    { "port": $((port + 1)), "label": "Vite" }
  ]
}
EOF
}

read_port() {
  [ -f "$allocation_file" ] || return 1
  sed -n '1p' "$allocation_file"
}

save_allocation() {
  port="$1"
  temporary_file="$allocation_file.$$"
  printf '%s\n%s\n' "$port" "$workspace_path" > "$temporary_file"
  mv "$temporary_file" "$allocation_file"
}

port_is_available() {
  base="$1"
  offset=0
  while [ "$offset" -lt 10 ]; do
    candidate=$((base + offset))
    if lsof -nP -iTCP:"$candidate" -sTCP:LISTEN >/dev/null 2>&1; then
      return 1
    fi
    offset=$((offset + 1))
  done
}

block_is_unallocated() {
  candidate_start="$1"
  candidate_end=$((candidate_start + 9))

  for file in "$allocations_dir"/*; do
    [ -f "$file" ] || continue
    allocated_start="$(sed -n '1p' "$file")"
    case "$allocated_start" in
      *[!0-9]*|"") continue ;;
    esac
    allocated_end=$((allocated_start + 9))
    if [ "$candidate_start" -le "$allocated_end" ] && [ "$allocated_start" -le "$candidate_end" ]; then
      return 1
    fi
  done
}

case "$action" in
  get)
    read_port
    ;;
  allocate)
    if port="$(read_port)"; then
      write_labels "$port"
      echo "$port"
      exit
    fi

    lock
    if port="$(read_port)"; then
      write_labels "$port"
      echo "$port"
      exit
    fi

    # Clean up stale allocations for removed worktrees
    for file in "$allocations_dir"/*; do
      [ -f "$file" ] || continue
      allocated_path="$(sed -n '2p' "$file")"
      [ -d "$allocated_path" ] || rm -f "$file"
    done

    port=10000
    while [ "$port" -le 59990 ]; do
      if block_is_unallocated "$port" && port_is_available "$port"; then
        save_allocation "$port"
        write_labels "$port"
        echo "$port"
        exit
      fi
      port=$((port + 10))
    done

    echo "No free workspace port block available." >&2
    exit 1
    ;;
  reserve)
    port="${2:?Usage: bin/orchestrator/port reserve PORT}"
    case "$port" in
      *[!0-9]*|"")
        echo "Port must be an integer." >&2
        exit 1
        ;;
    esac
    if [ "$port" -lt 1 ] || [ "$port" -gt 65526 ]; then
      echo "Port block must start between 1 and 65526." >&2
      exit 1
    fi
    if existing="$(read_port)"; then
      write_labels "$existing"
      echo "$existing"
      exit
    fi

    lock
    if ! block_is_unallocated "$port"; then
      echo "Port block $port is already allocated to another workspace." >&2
      exit 1
    fi
    save_allocation "$port"
    write_labels "$port"
    echo "$port"
    ;;
  release)
    lock
    rm -f "$allocation_file" .superset/ports.json
    ;;
  *)
    echo "Usage: bin/orchestrator/port [get|allocate|reserve PORT|release]" >&2
    exit 1
    ;;
esac
