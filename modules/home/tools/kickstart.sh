set -euo pipefail

usage() {
  printf 'usage: kickstart <template> [project] [-- generator-args...]\n' >&2
  printf '       kickstart sync-nixpkgs\n' >&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 64
fi

template_flake="${KICKSTART_FLAKE:-@templateFlake@}"

root_nixpkgs_rev() {
  nix flake metadata "$template_flake" --json \
    | jq -r '.locks.nodes[.locks.nodes[.locks.root].inputs.nixpkgs].locked.rev'
}

sync_nixpkgs() {
  local rev

  if [[ ! -e flake.nix ]]; then
    printf 'kickstart: flake.nix does not exist\n' >&2
    exit 1
  fi

  rev="$(root_nixpkgs_rev)"
  if [[ -z "$rev" || "$rev" == "null" ]]; then
    printf 'kickstart: could not determine nix-config nixpkgs revision\n' >&2
    exit 1
  fi

  nix flake lock --override-input nixpkgs "github:nixos/nixpkgs/${rev}"
}

shell_quote() {
  local value="$1"

  if [[ "$value" =~ ^[A-Za-z0-9_./:=+-]+$ ]]; then
    printf '%s' "$value"
    return 0
  fi

  value="${value//\'/\'\\\'\'}"
  printf "'%s'" "$value"
}

generator_command() {
  case "$template" in
  elixir)
    printf 'mix new .'
    ;;
  phoenix)
    printf 'mix phx.new .'
    ;;
  *)
    printf 'kickstart: no generator configured for template: %s\n' "$template" >&2
    exit 1
    ;;
  esac

  for arg in "$@"; do
    printf ' '
    shell_quote "$arg"
  done

  printf '\n'
}

run_generator() {
  case "$template" in
  elixir)
    nix develop --command mix new . "$@"
    ;;
  phoenix)
    nix develop --command mix phx.new . "$@"
    ;;
  *)
    printf 'kickstart: no generator configured for template: %s\n' "$template" >&2
    exit 1
    ;;
  esac
}

if [[ "$1" == "sync-nixpkgs" ]]; then
  if [[ $# -ne 1 ]]; then
    usage
    exit 64
  fi

  sync_nixpkgs
  exit 0
fi

generator_args=()
template_args=()
generator_requested=false

while (($# > 0)); do
  case "$1" in
  --)
    generator_requested=true
    shift
    generator_args=("$@")
    break
    ;;
  *)
    template_args+=("$1")
    shift
    ;;
  esac
done

if [[ ${#template_args[@]} -lt 1 || ${#template_args[@]} -gt 2 ]]; then
  usage
  exit 64
fi

template="${template_args[0]}"
project="${template_args[1]:-}"

if [[ -n "$project" ]]; then
  mkdir "$project"
  cd "$project"
fi

if [[ -e flake.nix ]]; then
  printf 'kickstart: flake.nix already exists\n' >&2
  exit 1
fi

if [[ ! -d .git ]]; then
  git init
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git commit --allow-empty -m "chore: inception"
fi

nix flake init -t "${template_flake}#${template}"
git reset -q -- .envrc 2>/dev/null || true
sync_nixpkgs
git add .
git reset -q -- .envrc 2>/dev/null || true
git commit -m "chore(env): bootstrap nix flake"

if [[ "$generator_requested" == "true" ]]; then
  generator_command_text="$(generator_command "${generator_args[@]}")"
  run_generator "${generator_args[@]}"
  git add .
  git reset -q -- .envrc 2>/dev/null || true
  git commit \
    -m "chore: run project generator" \
    -m "$(printf 'Generator command:\n\n    %s' "$generator_command_text")"
fi
