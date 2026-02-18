#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/tofu-env.sh <stack> -- <command> [args...]

Example:
  scripts/tofu-env.sh minio -- tofu -chdir=infra/minio plan
EOF
}

if [ "$#" -lt 3 ]; then
  usage
  exit 1
fi

stack="$1"
shift

if [ "$1" != "--" ]; then
  usage
  exit 1
fi
shift

repo_root="$(git rev-parse --show-toplevel)"

extract_secret() {
  local file=$1
  local expr=$2
  sops decrypt --extract "$expr" "$repo_root/$file"
}

case "$stack" in
  minio)
    export TF_VAR_minio_root_user
    TF_VAR_minio_root_user="$(extract_secret "secrets/boron.yaml" '["minio"]["rootUser"]')"

    export TF_VAR_minio_root_password
    TF_VAR_minio_root_password="$(extract_secret "secrets/boron.yaml" '["minio"]["rootPassword"]')"

    export TF_VAR_tofu_state_access_key
    TF_VAR_tofu_state_access_key="$(extract_secret "secrets/tofu.yaml" '["minio"]["tofuStateAccessKey"]')"

    export TF_VAR_tofu_state_secret_key
    TF_VAR_tofu_state_secret_key="$(extract_secret "secrets/tofu.yaml" '["minio"]["tofuStateSecretKey"]')"

    export TF_VAR_mattermost_access_key
    TF_VAR_mattermost_access_key="$(extract_secret "secrets/carbon.yaml" '["minio"]["mattermostAccessKey"]')"

    export TF_VAR_mattermost_secret_key
    TF_VAR_mattermost_secret_key="$(extract_secret "secrets/carbon.yaml" '["minio"]["mattermostSecretKey"]')"

    export AWS_ACCESS_KEY_ID="$TF_VAR_tofu_state_access_key"
    export AWS_SECRET_ACCESS_KEY="$TF_VAR_tofu_state_secret_key"
    ;;
  *)
    echo "Unsupported stack: $stack" >&2
    exit 1
    ;;
esac

exec "$@"
