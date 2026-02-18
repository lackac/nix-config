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

check-builder builder="192.168.64.6" user="lackac":
  nix build --impure --expr 'let t = builtins.toString builtins.currentTime; in (with import <nixpkgs> { system = "aarch64-linux"; }; runCommand "builder-check-${t}" {} "uname > $out")' --builders "ssh://{{user}}@{{builder}} aarch64-linux"

build-sd-image-oxygen builder="192.168.64.6" user="lackac" jobs="4":
  nix build .#nixosConfigurations.oxygen.config.system.build.sdImage --max-jobs 0 --builders "ssh://{{user}}@{{builder}} aarch64-linux - {{jobs}} 1"
