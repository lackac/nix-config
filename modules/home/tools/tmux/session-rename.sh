set -euo pipefail

if [[ -z "${TMUX:-}" ]]; then
  exit 0
fi

session_name="$(tmux display-message -p '#S' 2>/dev/null || true)"
if [[ -z "$session_name" ]]; then
  exit 0
fi

session_path="$(tmux display-message -p -t "$session_name" '#{session_path}' 2>/dev/null || true)"
if [[ -z "$session_path" ]]; then
  session_path="$PWD"
fi

# A path containing either delimiter cannot be sent as one record.
if [[ "$session_path" == *[$'\t\n']* || "$session_name" == *$'\n'* ]]; then
  exit 0
fi

target_name="$(printf '%s\t%s\n' "$session_path" "$session_name" | terminal-session-name)"

if [[ -z "$target_name" || "$target_name" == "$session_name" ]]; then
  exit 0
fi

if tmux has-session -t "$target_name" 2>/dev/null; then
  exit 0
fi

tmux rename-session -t "$session_name" "$target_name"
