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

log host target="":
  #!/usr/bin/env bash
  set -euo pipefail

  if [[ -z "{{target}}" ]]; then
    ssh -t -- "{{host}}" sudo journalctl -f
  elif [[ "{{target}}" == /* ]]; then
    ssh -t -- "{{host}}" sudo tail -F "{{target}}"
  else
    ssh -t -- "{{host}}" sudo journalctl -fu "{{target}}"
  fi

provision host ip:
  nix run nixpkgs#nixos-anywhere -- --flake .#{{host}} root@{{ip}}

darwin-switch host=`scutil --get LocalHostName 2>/dev/null || hostname -s`:
  sudo darwin-rebuild switch --flake .#{{host}}

darwin-upgrade host=`scutil --get LocalHostName 2>/dev/null || hostname -s`:
  sudo determinate-nixd upgrade
  sudo darwin-rebuild switch --flake .#{{host}}

darwin-check host=`scutil --get LocalHostName 2>/dev/null || hostname -s`:
  sudo darwin-rebuild check --flake .#{{host}}

build-sd-image-oxygen:
  nix build .#nixosConfigurations.oxygen.config.system.build.sdImage
