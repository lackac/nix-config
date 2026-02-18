default:
  @just --list

fmt:
  nix fmt

check:
  nix flake check

up:
  nix flake update

upp input:
  nix flake update {{input}}

deploy host:
  colmena apply --on {{host}} --build-on-target

deploy-dry host:
  colmena apply dry-activate --on {{host}} --build-on-target

deploy-all:
  colmena apply --build-on-target

build host:
  colmena apply build --on {{host}} --build-on-target

provision host ip:
  nix run nixpkgs#nixos-anywhere -- --flake .#{{host}} root@{{ip}}

tofu-init stack:
  ./scripts/tofu-env.sh {{stack}} -- tofu -chdir=infra/{{stack}} init -reconfigure

tofu-plan stack:
  ./scripts/tofu-env.sh {{stack}} -- tofu -chdir=infra/{{stack}} plan

tofu-apply stack:
  ./scripts/tofu-env.sh {{stack}} -- tofu -chdir=infra/{{stack}} apply
