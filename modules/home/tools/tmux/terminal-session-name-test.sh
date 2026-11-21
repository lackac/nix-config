#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
evaluator=("$BASH" "$script_dir/terminal-session-name.sh")
if [[ $# == 1 ]]; then
  evaluator=("$1")
fi

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home.[test]"
export XDG_CONFIG_HOME="$tmp/config"
mkdir -p "$HOME/.config/tmux" "$XDG_CONFIG_HOME/tmux"
manifest="$XDG_CONFIG_HOME/session-name-rules.csv"
printf '%s\n' 'path,^~$,Legacy' |
  tee "$XDG_CONFIG_HOME/tmux/session-name-rules.csv" \
    "$HOME/.config/tmux/session-name-rules.csv" > /dev/null

check() {
  printf '%s\n' "$1" > "$tmp/expected"
  shift
  printf '%s\t%s\n' "$@" | "${evaluator[@]}" > "$tmp/actual" 2> "$tmp/stderr"
  diff -u "$tmp/expected" "$tmp/actual"
  [[ ! -s "$tmp/stderr" ]]
}

check $' keep spaces \nkeep\\slashes\tand tabs' \
  '/missing' ' keep spaces ' '/other' $'keep\\slashes\tand tabs'
check 'Original' "$HOME" Original
XDG_CONFIG_HOME= check 'Original' "$HOME" Original
printf '%s\n' 'name,^Default$,Must not read' > "$manifest"
chmod a-r "$manifest"
if [[ ! -r "$manifest" ]]; then
  check 'Default' '/unreadable' 'Default'
fi
chmod u+r "$manifest"

cat > "$manifest" <<'EOF'
# A fictitious manifest.

name,^(alpha|beta)$,[$1],team
path,^~/work/(.+)$,$1
path,^~/work/(.+)$,ignored
name,^\[alpha\],ignored
path,^~$,Home
path,^/same$,$0
name,^Same$,Used default
name,^fixture-,Prefix:
path,^/erase$,
name,^Gone$,
path,~/(other)$,$1
path,(,invalid regex
path,~,$(echo inert)
name,.*
other,.*,ignored
EOF
printf '%s\r\n' 'name,^dos$,CRLF' >> "$manifest"
printf '%s' 'path,^/capture-(.)(.)(.)(.)(.)(.)(.)(.)(.+)$,$9/$8$7$6$5$4$3$2$1/$0' >> "$manifest"

check $'[alpha],team\n[beta],team\nHome\nUsed default\nPrefix:tail\nGone\nother\nCRLF\n&$1/87654321//capture-12345678&$1\n$(echo inert)/folder\nOriginal\nNo rule' \
  "$HOME/work/alpha" Original "$HOME/work/beta" Original "$HOME" Original \
  '/same' Same '/unknown' fixture-tail '/erase' Gone "$HOME/other" Original \
  '/unknown' dos '/capture-12345678&$1' Original \
  "$HOME/folder" Original "$tmp/homext/folder" Original \
  '/missing' 'No rule'

mv "$manifest" "$HOME/.config/session-name-rules.csv"
check 'Original' "$HOME" Original
XDG_CONFIG_HOME= check 'Home' "$HOME" Original
(
  unset XDG_CONFIG_HOME
  check 'Home' "$HOME" Original
)
