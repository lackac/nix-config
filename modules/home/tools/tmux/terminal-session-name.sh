set -euo pipefail

# Rules are scope,regex,replacement; only the first two commas delimit fields.
manifest_path="${XDG_CONFIG_HOME:-$HOME/.config}/session-name-rules.csv"
rules=()

load_rules() {
  local line scope fields pattern
  local home_pattern='' char i
  # Treat the home directory as literal text in a path regex.
  for ((i = 0; i < ${#HOME}; i++)); do
    char="${HOME:i:1}"
    case "$char" in
      \\|.|'['|'('|')'|'^'|'$'|'*'|'+'|'?'|'{'|'}'|'|') home_pattern+="\\" ;;
    esac
    home_pattern+="$char"
  done

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    case "$line" in
      path,*,*|name,*,*) ;;
      *) continue ;;
    esac

    scope="${line%%,*}"
    fields="${line#*,}"
    pattern="${fields%%,*}"
    if [[ "$scope" == path ]]; then
      case "$pattern" in
        '^~$') pattern="^$home_pattern\$" ;;
        '^~/'*) pattern="^$home_pattern/${pattern:3}" ;;
        \~) pattern="$home_pattern" ;;
        \~/*) pattern="$home_pattern/${pattern:2}" ;;
      esac
    fi
    # Bash returns 2 for an invalid regex.
    # shellcheck disable=SC2319
    [[ '' =~ $pattern ]] || [[ $? != 2 ]] || continue
    rules+=("$scope" "$pattern" "${fields#*,}")
  done
}

if [[ -f "$manifest_path" && -r "$manifest_path" ]]; then
  load_rules 2>/dev/null < "$manifest_path" || rules=()
fi

# Set result to the first substitution in this scope, or leave the input unchanged.
run_pass() {
  local scope="$1" input="$2"
  local i pattern matched template expanded literal digit
  result="$input"

  for ((i = 0; i < ${#rules[@]}; i += 3)); do
    [[ "${rules[i]}" == "$scope" ]] || continue
    pattern="${rules[i+1]}"
    [[ "$input" =~ $pattern ]] || continue

    matched="${BASH_REMATCH[0]}"
    template="${rules[i+2]}"
    expanded=''
    # Expand placeholders in the template only, never those in captured text.
    while [[ "$template" == *\$[0-9]* ]]; do
      literal="${template%%\$[0-9]*}"
      template="${template#"$literal"}"
      digit="${template:1:1}"
      expanded+="$literal${BASH_REMATCH[$digit]:-}"
      template="${template:2}"
    done
    result="${input%%"$matched"*}$expanded$template${input#*"$matched"}"
    return
  done
}

# Read absolute-path<TAB>default-label records and emit one label per record.
while IFS= read -r record; do
  [[ "$record" == /*$'\t'?* ]] || continue
  path="${record%%$'\t'*}"
  default_label="${record#*$'\t'}"

  run_pass path "$path"
  if [[ "$result" == "$path" ]]; then
    result="$default_label"
  fi
  run_pass name "$result"
  printf '%s\n' "${result:-$default_label}"
done
