set -euo pipefail

if [[ -z "${TMUX:-}" ]]; then
  exit 0
fi

confirmed=false
target_session=""

while (($# > 0)); do
  case "$1" in
  --confirmed)
    confirmed=true
    shift
    ;;
  --session)
    if (($# < 2)); then
      printf 'tmux-session-kill: missing value for --session\n' >&2
      exit 1
    fi
    target_session="$2"
    shift 2
    ;;
  *)
    printf 'tmux-session-kill: unknown argument: %s\n' "$1" >&2
    exit 1
    ;;
  esac
done

if [[ -z "$target_session" ]]; then
  target_session="$(tmux display-message -p '#S' 2>/dev/null || true)"
fi

if [[ -z "$target_session" ]]; then
  exit 0
fi

if ! tmux has-session -t "$target_session" 2>/dev/null; then
  exit 0
fi

declare -A proc_command=()
declare -A proc_children=()
declare -A collected_commands=()

normalize_command() {
  local command="$1"

  command="${command##*/}"
  command="${command#-}"

  printf '%s\n' "$command"
}

is_shell_command() {
  case "$1" in
  bash | fish | ksh | sh | tmux | zsh)
    return 0
    ;;
  esac

  return 1
}

is_safe_command() {
  case "$1" in
  bat | less | man | more | ps | tail | watch | top | btop | htop)
    return 0
    ;;
  esac

  return 1
}

is_risky_command() {
  case "$1" in
  git | nvim | oh-my-openagent | opencode | rsync | scp | ssh | vim)
    return 0
    ;;
  esac

  return 1
}

shell_quote() {
  printf '%q' "$1"
}

load_process_tree() {
  local pid
  local ppid
  local command

  while read -r pid ppid command; do
    command="$(normalize_command "$command")"

    [[ -z "$pid" ]] && continue
    [[ -z "$ppid" ]] && continue
    [[ -z "$command" ]] && continue

    proc_command["$pid"]="$command"
    proc_children["$ppid"]+=" $pid"
  done < <(ps -ax -o pid= -o ppid= -o comm=)
}

collect_process_commands() {
  local pid="$1"
  local command="${proc_command[$pid]-}"
  local child

  if [[ -n "$command" ]] && ! is_shell_command "$command"; then
    collected_commands["$command"]=1
  fi

  for child in ${proc_children[$pid]-}; do
    collect_process_commands "$child"
  done
}

classify_pane() {
  local pid="$1"
  local fallback_command="$2"
  local command
  local representative=""

  collected_commands=()
  collect_process_commands "$pid"

  if ((${#collected_commands[@]} == 0)); then
    if [[ -z "$fallback_command" ]] || is_shell_command "$fallback_command"; then
      printf 'safe\tidle-shell\n'
      return 0
    fi

    if is_safe_command "$fallback_command"; then
      printf 'safe\t%s\n' "$fallback_command"
      return 0
    fi

    printf 'risky\t%s\n' "$fallback_command"
    return 0
  fi

  for command in "${!collected_commands[@]}"; do
    representative="$command"
    if is_risky_command "$command"; then
      printf 'risky\t%s\n' "$command"
      return 0
    fi

    if ! is_safe_command "$command"; then
      printf 'risky\t%s\n' "$command"
      return 0
    fi
  done

  if [[ -z "$representative" ]]; then
    representative="$fallback_command"
  fi

  printf 'safe\t%s\n' "$representative"
}

switch_away_from_session() {
  local session_name="$1"
  local current_session

  tmux switch-client -l 2>/dev/null || true
  current_session="$(tmux display-message -p '#S' 2>/dev/null || true)"
  if [[ "$current_session" == "$session_name" ]] && [[ "$session_name" != "main" ]]; then
    tmux switch-client -t "=main" 2>/dev/null || true
  fi
}

prompt_for_confirmation() {
  local session_name="$1"
  local summary="$2"
  local quoted_session

  quoted_session="$(shell_quote "$session_name")"
  tmux confirm-before -p "Kill session $session_name? $summary" "run-shell \"tmux-session-kill --session $quoted_session --confirmed\""
}

kill_session() {
  local session_name="$1"

  switch_away_from_session "$session_name"
  tmux kill-session -t "$session_name"
}

if [[ "$confirmed" == "true" ]]; then
  kill_session "$target_session"
  exit 0
fi

load_process_tree

risky_details=()

while IFS=$'\t' read -r pane_id pane_label pane_command pane_pid; do
  [[ -z "$pane_id" ]] && continue

  pane_command="$(normalize_command "$pane_command")"
  classification="$(classify_pane "$pane_pid" "$pane_command")"
  level="${classification%%$'\t'*}"
  detail="${classification#*$'\t'}"

  if [[ "$level" == "risky" ]]; then
    risky_details+=("$pane_label:$detail")
  fi
done < <(
  tmux list-panes -t "$target_session" -F '#{pane_id}	#{window_index}.#{pane_index}	#{pane_current_command}	#{pane_pid}'
)

if ((${#risky_details[@]} == 0)); then
  kill_session "$target_session"
  exit 0
fi

summary="risky panes: "
for i in "${!risky_details[@]}"; do
  if ((i > 0)); then
    summary+=", "
  fi

  summary+="${risky_details[$i]}"

  if ((i == 3 && ${#risky_details[@]} > 4)); then
    summary+=", +$((${#risky_details[@]} - 4)) more"
    break
  fi
done

prompt_for_confirmation "$target_session" "$summary"
