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

