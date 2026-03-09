set -euo pipefail

min_port=47000
max_port=48999
range_size=$((max_port - min_port + 1))

print_only=false
opencode_args=()

while (($# > 0)); do
  case "$1" in
  --print-port)
    print_only=true
    shift
    ;;
  --)
    shift
    opencode_args+=("$@")
    break
    ;;
  *)
    opencode_args+=("$1")
    shift
    ;;
  esac
done

project_root() {
  git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd
}

base_port_for_root() {
  local root="$1"
  local hash_output
  local hash

  hash_output="$(printf '%s' "$root" | cksum)"
  hash="${hash_output%% *}"

  printf '%s\n' "$((min_port + (hash % range_size)))"
}

port_is_listening() {
  local candidate="$1"
  lsof -nP -iTCP:"$candidate" -sTCP:LISTEN >/dev/null 2>&1
}

choose_port() {
  local root="$1"
  local base
  local normalized_base
  local offset
  local candidate

  base="$(base_port_for_root "$root")"
  normalized_base=$((base - min_port))

  for ((offset = 0; offset < range_size; offset++)); do
    candidate=$((min_port + ((normalized_base + offset) % range_size)))
    if ! port_is_listening "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

port="$(choose_port "$(project_root)")" || {
  printf 'opencode-session: unable to find a free port in %s-%s\n' "$min_port" "$max_port" >&2
  exit 1
}

if [[ "$print_only" == "true" ]]; then
  printf '%s\n' "$port"
  exit 0
fi

export OPENCODE_PORT="$port"

if [[ -n "${TMUX:-}" ]]; then
  session_name="$(tmux display-message -p '#S' 2>/dev/null || true)"
  if [[ -n "$session_name" ]]; then
    tmux set-environment -t "$session_name" OPENCODE_PORT "$OPENCODE_PORT"
  fi
fi

exec oh-my-openagent --port "$OPENCODE_PORT" "${opencode_args[@]}"
