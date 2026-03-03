set -euo pipefail

manifest_path="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/session-name-rules.csv"

if [[ -z "${TMUX:-}" ]]; then
  exit 0
fi

if [[ ! -r "$manifest_path" ]]; then
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

expand_tilde_pattern() {
  local pattern="$1"
  if [[ "$pattern" == "^~$" ]]; then
    printf '^%s$\n' "$HOME"
    return 0
  fi

  if [[ "$pattern" == "^~/"* ]]; then
    printf '^%s/%s\n' "$HOME" "${pattern#^~/}"
    return 0
  fi

  if [[ "$pattern" == "~" ]]; then
    printf '%s\n' "$HOME"
    return 0
  fi

  if [[ "$pattern" == ~/* ]]; then
    printf '%s\n' "$HOME/${pattern#~/}"
    return 0
  fi

  printf '%s\n' "$pattern"
}

apply_first_match() {
  local input="$1"
  local pattern="$2"
  local replacement="$3"

  if [[ "$input" =~ $pattern ]]; then
    local expanded="$replacement"
    local i
    for i in 9 8 7 6 5 4 3 2 1 0; do
      expanded="${expanded//\$$i/${BASH_REMATCH[$i]:-}}"
    done

    local matched="${BASH_REMATCH[0]}"
    local prefix="${input%%"$matched"*}"
    local suffix="${input#*"$matched"}"

    printf '%s\n' "$prefix$expanded$suffix"
    return 0
  fi

  return 1
}

run_pass() {
  local rule_scope="$1"
  local input="$2"
  local candidate="$input"
  local line
  local scope
  local remainder
  local pattern
  local replacement
  local expanded_pattern
  local updated

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue

    scope="${line%%,*}"
    remainder="${line#*,}"
    if [[ "$remainder" == "$line" ]]; then
      continue
    fi

    pattern="${remainder%%,*}"
    replacement="${remainder#*,}"
    if [[ "$replacement" == "$remainder" ]]; then
      continue
    fi

    if [[ "$scope" != "$rule_scope" ]]; then
      continue
    fi

    expanded_pattern="$pattern"
    if [[ "$rule_scope" == "path" ]]; then
      expanded_pattern="$(expand_tilde_pattern "$pattern")"
    fi

    updated="$(apply_first_match "$candidate" "$expanded_pattern" "$replacement")" || continue
    candidate="$updated"
    printf '%s\n' "$candidate"
    return 0
  done < "$manifest_path"

  printf '%s\n' "$candidate"
  return 0
}

path_result="$(run_pass path "$session_path")"

if [[ "$path_result" == "$session_path" ]]; then
  target_name="$session_name"
else
  target_name="$path_result"
fi

target_name="$(run_pass name "$target_name")"

if [[ -z "$target_name" || "$target_name" == "$session_name" ]]; then
  exit 0
fi

if tmux has-session -t "$target_name" 2>/dev/null; then
  exit 0
fi

tmux rename-session -t "$session_name" "$target_name"
